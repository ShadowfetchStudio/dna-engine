import Foundation

enum AnalysisEngine {
    static func analyze(parsed: ParsedGenome, meta: GenomeFile) -> AnalysisReport {
        let kb = KnowledgeBase.shared
        var hits: [MarkerHit] = []
        hits.reserveCapacity(kb.markers.count)
        var matched = 0, noCall = 0, missing = 0, strandAmbiguous = 0

        for marker in kb.markers {
            let hit = MarkerMatcher.hit(marker: marker, call: parsed.calls[marker.rsid])
            switch hit.coverage {
            case .matched: matched += 1
            case .noCall: noCall += 1
            case .missing: missing += 1
            case .strandAmbiguous: strandAmbiguous += 1
            }
            hits.append(hit)
        }

        let compounds = CompoundTraits.build(hits: hits, calls: parsed.calls)
        let ancestry = AncestryEstimator.estimate(calls: parsed.calls, aims: kb.aims)
        let ancestryPCA = AncestryEstimator.estimatePCA(shares: ancestry.shares)
        let admixture = AdmixtureEngine.analyze(calls: parsed.calls)
        let roh = ROHScanner.scan(ordered: parsed.ordered)
        let qc = QCEngine.assess(parsed: parsed, meta: meta)

        let pgx = PharmacogenomicsEngine.analyze(calls: parsed.calls)
        let pathways = PathwaysEngine.buildGraphs(calls: parsed.calls, hits: hits)
        let chrono = LifestyleEngine.buildChronoSchedule(hits: hits, compounds: compounds)
        let supplementMatrix = LifestyleEngine.buildSupplementMatrix(hits: hits, compounds: compounds)

        let calibratedScores = computeCalibratedScores(calls: parsed.calls, panels: kb.scores, ancestry: ancestry)
        let insights = LifestyleEngine.insights(hits: hits, compounds: compounds)
        let protocolItems = LifestyleEngine.protocolItems(hits: hits, compounds: compounds)

        return AnalysisReport(
            genome: meta,
            hits: hits,
            insights: insights,
            protocolItems: protocolItems,
            chronoSchedule: chrono,
            supplementMatrix: supplementMatrix,
            pharmacogenomics: pgx,
            pathwayGraphs: pathways,
            calibratedScores: calibratedScores,
            ancestry: ancestry,
            ancestryPCA: ancestryPCA,
            admixture: admixture,
            compounds: compounds,
            roh: roh,
            catalogCoverage: CatalogCoverage(
                matched: matched,
                noCall: noCall,
                missing: missing,
                strandAmbiguous: strandAmbiguous
            ),
            qc: qc
        )
    }

    static func hits(in report: AnalysisReport, matching nav: NavItem) -> [MarkerHit] {
        let cats = nav.catalogCategories
        guard !cats.isEmpty else { return report.hits }
        return report.hits.filter { hit in
            Set(hit.categories).isDisjoint(with: cats) == false
        }
    }

    // MARK: - Honest polygenic calibration (feature 4)
    //
    // The 1.x decorative percentile (fixed fake mean/SD constants) is dead.
    // Every panel now carries per-SNP published risk-allele frequencies; the
    // reference distribution is derived under Hardy-Weinberg over ONLY the
    // SNPs actually typed in this file, so chip coverage cannot bias z:
    //     mean = Σ 2·p·w        sd = sqrt(Σ 2·p·(1−p)·w²)

    struct HWECal {
        var mean: Double
        var sd: Double
    }

    /// HWE mean/sd for a panel in one population. `onlyRsids == nil` uses the
    /// full panel (must equal the generator's baked `calibration` values —
    /// run_checks.sh cross-checks this against an independent Python
    /// recomputation to 1e-9).
    static func hweCalibration(panel: ScorePanel, population: String, onlyRsids: Set<String>?) -> HWECal {
        var mean = 0.0
        var variance = 0.0
        for snp in panel.snps {
            if let onlyRsids, !onlyRsids.contains(snp.rsid) { continue }
            guard let rawP = snp.freq?[population] else { continue }
            let p = min(max(rawP, 1e-4), 1 - 1e-4)
            mean += 2.0 * p * snp.weight
            variance += 2.0 * p * (1.0 - p) * snp.weight * snp.weight
        }
        return HWECal(mean: mean, sd: variance.squareRoot())
    }

    static func riskAlleleCount(call: SNPCall, risk: String) -> Int {
        let riskChar = risk.uppercased().first ?? " "
        var n = [call.allele1, call.allele2].filter { $0 == riskChar }.count
        if n == 0 {
            let flip = Strand.complement(riskChar)
            let alleles = [call.allele1, call.allele2]
            // Only complement-flip when the observed alleles don't include the
            // risk letter at all AND do include its complement.
            if alleles.contains(flip) {
                n = alleles.filter { $0 == flip }.count
            }
        }
        return n
    }

    static let minimumCoverageFraction = 0.6

    private static func computeCalibratedScores(calls: [String: SNPCall], panels: [ScorePanel], ancestry: AncestryResult) -> [CalibratedPolygenicScore] {
        let kb = KnowledgeBase.shared
        let markerIndex = Dictionary(uniqueKeysWithValues: kb.markers.map { ($0.rsid, $0) })
        let topShare = ancestry.shares.max(by: { $0.value < $1.value })?.key

        return panels.map { panel in
            var userScore = 0.0
            var usedCount = 0
            var typedRsids = Set<String>()
            var topGenes: [String] = []

            for snp in panel.snps {
                guard let call = calls[snp.rsid], !call.isNoCall else { continue }
                // Score files do not currently carry a separately validated
                // strand-orientation manifest. A/T and C/G loci therefore fail
                // closed instead of being assigned an effect-allele dosage.
                guard let marker = markerIndex[snp.rsid],
                      !Strand.isPalindromic(alleleA: marker.alleleA, alleleB: marker.alleleB) else { continue }
                usedCount += 1
                typedRsids.insert(snp.rsid)
                let n = riskAlleleCount(call: call, risk: snp.risk)
                userScore += Double(n) * snp.weight
                if n > 0, !topGenes.contains(marker.gene) {
                    topGenes.append(marker.gene)
                }
            }

            let total = panel.snps.count
            let coverage = total > 0 ? Double(usedCount) / Double(total) : 0
            let insufficient = coverage < minimumCoverageFraction

            // Reference population: the user's own estimated majority ancestry
            // when calibration data exists for it; otherwise 'european' with an
            // explicit fallback flag surfaced in the UI.
            let populations = kb.populations
            var referencePopulation = "european"
            var isFallback = true
            if let top = topShare, panel.calibration?[top] != nil || panel.snps.allSatisfy({ $0.freq?[top] != nil }) {
                referencePopulation = top
                isFallback = false
            }

            let cal = hweCalibration(panel: panel, population: referencePopulation, onlyRsids: typedRsids)
            let z = cal.sd > 0 ? (userScore - cal.mean) / cal.sd : 0
            let percentile = Int(min(max(normalCDF(z) * 100.0, 1.0), 99.0))

            var percentileByPopulation: [String: Int] = [:]
            if !insufficient {
                for pop in populations {
                    let popCal = hweCalibration(panel: panel, population: pop, onlyRsids: typedRsids)
                    guard popCal.sd > 0 else { continue }
                    let popZ = (userScore - popCal.mean) / popCal.sd
                    percentileByPopulation[pop] = Int(min(max(normalCDF(popZ) * 100.0, 1.0), 99.0))
                }
            }

            let (category, impact, mitigation) = interpret(panel: panel, percentile: percentile, insufficient: insufficient)

            return CalibratedPolygenicScore(
                id: panel.id,
                title: panel.title,
                description: panel.description,
                percentile: insufficient ? 0 : percentile,
                zScore: insufficient ? 0 : z,
                riskCategory: category,
                impact: impact,
                usedSNPs: usedCount,
                totalSNPs: total,
                lifestyleMitigation: mitigation,
                topContributingGenes: Array(topGenes.prefix(4)),
                referencePopulation: referencePopulation,
                referencePopulationIsFallback: isFallback,
                percentileByPopulation: percentileByPopulation,
                insufficientCoverage: insufficient
            )
        }
    }

    private static let higherIsBetter: Set<String> = ["longevity", "vo2max", "power", "cognitive_reserve"]

    private static func interpret(panel: ScorePanel, percentile: Int, insufficient: Bool) -> (String, Impact, String) {
        if insufficient {
            return (
                "Insufficient chip coverage",
                .typical,
                "Fewer than \(Int(minimumCoverageFraction * 100))% of this panel's SNPs are typed in this file — no percentile is shown because it would be a guess."
            )
        }
        if higherIsBetter.contains(panel.id) {
            if percentile >= 75 {
                return ("Favorable Tendency (Advantageous)", .advantageous,
                        "Favorable baseline genetic potential. Maintain healthy lifestyle practices to fully express this biological advantage.")
            } else if percentile <= 30 {
                return ("Below Average Genetic Buffer", .notable,
                        "Targeted lifestyle interventions (zone-2 aerobic conditioning, sleep, nutrient density) provide effective compensatory stimulus.")
            }
            return ("Typical Population Baseline", .typical, "Standard balanced training and nutrition protocols.")
        }
        if percentile >= 75 {
            return ("Elevated Tendency", .caution,
                    "Genetic tendency is strongly modifiable through targeted nutrition, structured physical exercise, and routine clinical check-ins.")
        } else if percentile <= 30 {
            return ("Lower Than Average Tendency", .advantageous,
                    "Favorable low genetic baseline. Continue balanced health habits.")
        }
        return ("Typical Population Baseline", .typical, "Standard preventive health and lifestyle maintenance.")
    }

    static func normalCDF(_ z: Double) -> Double {
        // Abramowitz & Stegun approximation
        let b1 = 0.319381530
        let b2 = -0.356563782
        let b3 = 1.781477937
        let b4 = -1.821255978
        let b5 = 1.330274429
        let p = 0.2316419
        let c = 0.39894228

        let x = abs(z)
        let t = 1.0 / (1.0 + p * x)
        let poly = ((((b5 * t + b4) * t + b3) * t + b2) * t + b1) * t
        let phi = 1.0 - c * exp(-x * x / 2.0) * poly

        return z >= 0 ? phi : (1.0 - phi)
    }
}
