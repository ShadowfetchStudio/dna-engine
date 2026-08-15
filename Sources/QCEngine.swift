import Foundation

/// Genome file QC (feature 6). Pure file forensics — zero phenotype claims.
/// UI-free by contract: compiled into the check harness.
enum QCEngine {
    static func assess(parsed: ParsedGenome, meta: GenomeFile) -> QCReport {
        var checks: [QCCheck] = []

        // 1. Call rate — overall and per chromosome.
        let callRate = meta.snpCount > 0 ? Double(meta.calledCount) / Double(meta.snpCount) : 0
        var callDetails: [String] = [String(format: "Overall call rate %.2f%% (%d of %d rows)", callRate * 100, meta.calledCount, meta.snpCount)]
        var worstChromRate = 1.0
        var worstChrom = ""
        for (chrom, snps) in parsed.chromosomeIndex where !snps.isEmpty {
            let called = snps.filter { !$0.isNoCall }.count
            let rate = Double(called) / Double(snps.count)
            if snps.count >= 50 && rate < worstChromRate {
                worstChromRate = rate
                worstChrom = chrom
            }
        }
        if !worstChrom.isEmpty {
            callDetails.append(String(format: "Lowest per-chromosome call rate: chr%@ at %.2f%%", worstChrom, worstChromRate * 100))
        }
        let callGrade: QCGrade = callRate >= 0.97 ? .pass : (callRate >= 0.90 ? .warn : .fail)
        checks.append(QCCheck(
            id: "callRate", title: "Call Rate",
            grade: callGrade,
            summary: callGrade == .pass
                ? "Call rate is healthy (≥97%)."
                : "Call rate is below 97% — interpretation confidence drops with it; a re-export or re-test may be worthwhile.",
            details: callDetails
        ))

        // 2. No-call clustering — 10 Mb windows per chromosome, flag windows
        //    exceeding 5× the median windowed no-call count.
        var windowCounts: [(chrom: String, window: Int, count: Int)] = []
        for (chrom, snps) in parsed.chromosomeIndex where GenomeStats.isAutosome(chrom) {
            var byWindow: [Int: (noCalls: Int, total: Int)] = [:]
            for snp in snps {
                let w = snp.position / 10_000_000
                var entry = byWindow[w] ?? (0, 0)
                entry.total += 1
                if snp.isNoCall { entry.noCalls += 1 }
                byWindow[w] = entry
            }
            for (w, entry) in byWindow where entry.total >= 20 {
                windowCounts.append((chrom, w, entry.noCalls))
            }
        }
        let sortedCounts = windowCounts.map(\.count).sorted()
        let median = sortedCounts.isEmpty ? 0 : sortedCounts[sortedCounts.count / 2]
        let threshold = max(5, median * 5)
        let flagged = windowCounts
            .filter { $0.count > threshold }
            .sorted { ($0.chrom, $0.window) < ($1.chrom, $1.window) }
        let clusterGrade: QCGrade = flagged.isEmpty ? .pass : .warn
        checks.append(QCCheck(
            id: "clustering", title: "No-Call Clustering",
            grade: clusterGrade,
            summary: flagged.isEmpty
                ? "No-calls are scattered, not clustered — no regional assay failure."
                : "Localized no-call cluster(s) detected — a regional assay artifact; markers in those windows are unreliable.",
            details: flagged.map { "chr\($0.chrom) window \($0.window * 10)-\(($0.window + 1) * 10) Mb: \($0.count) no-calls (median window \(median))" }
        ))

        // 3. Genome-build inference from hand-verified sentinel positions.
        //    The header's buildHint is demoted to a prior.
        var b37Hits = 0, b38Hits = 0, sentinelsSeen = 0
        for marker in KnowledgeBase.shared.markers {
            guard let p38 = marker.position38, marker.position > 0,
                  let call = parsed.calls[marker.rsid] else { continue }
            sentinelsSeen += 1
            if call.position == marker.position { b37Hits += 1 }
            if call.position == p38 { b38Hits += 1 }
        }
        let buildCall: String
        let buildGrade: QCGrade
        if sentinelsSeen == 0 {
            buildCall = "unknown (no sentinel markers present)"
            buildGrade = .warn
        } else if b37Hits > 0 && b38Hits == 0 {
            buildCall = "GRCh37/hg19"
            buildGrade = .pass
        } else if b38Hits > 0 && b37Hits == 0 {
            buildCall = "GRCh38/hg38"
            buildGrade = .pass
        } else if b37Hits == 0 && b38Hits == 0 {
            buildCall = "unrecognized coordinates (neither b37 nor b38 sentinels matched)"
            buildGrade = .warn
        } else {
            buildCall = "mixed/uncertain"
            buildGrade = .warn
        }
        checks.append(QCCheck(
            id: "build", title: "Genome Build",
            grade: buildGrade,
            summary: "Detected \(buildCall) from \(sentinelsSeen) sentinel positions (header said: \(meta.buildHint)). rsID matching keeps interpretation stable either way.",
            details: ["b37 sentinel matches: \(b37Hits)", "b38 sentinel matches: \(b38Hits)"]
        ))

        // 4. Chip fingerprint: vendor sentinels + i-prefix + total-SNP bands.
        let iCount = parsed.ordered.prefix(50_000).filter { $0.rsid.hasPrefix("i") }.count
        let total = parsed.ordered.count
        let fingerprint: String
        if total < 100_000 {
            fingerprint = "small/synthetic file (~\(total.formatted()) rows) — not a full consumer array export"
        } else if iCount > 1_000 {
            fingerprint = total > 900_000
                ? "looks like an older 23andMe/AncestryDNA chip (~\(total / 1000)k rows, internal i-IDs present)"
                : "looks like a 23andMe chip (~\(total / 1000)k rows, internal i-IDs present)"
        } else if total > 850_000 {
            fingerprint = "looks like a high-density array (~\(total / 1000)k rows) — MyHeritage/FTDNA GSA class"
        } else {
            fingerprint = "looks like a ~\(total / 1000)k-row consumer array (23andMe v5 / Ancestry v2 class)"
        }
        let expected = expectedCoverage(parsed: parsed)
        checks.append(QCCheck(
            id: "chip", title: "Chip Fingerprint",
            grade: .pass,
            summary: fingerprint,
            details: expected
        ))

        // 5. Strand sanity: complement-flipped matches + palindromic catalog sites.
        var flipped = 0
        var palindromicMatched = 0
        var ambiguous = 0
        for marker in KnowledgeBase.shared.markers {
            guard let call = parsed.calls[marker.rsid], !call.isNoCall else { continue }
            let expectedSet = Set([marker.alleleA.uppercased(), marker.alleleB.uppercased()])
            let pair = expectedSet
            let isPalindromic = pair == Set(["A", "T"]) || pair == Set(["C", "G"])
            let raw = Set(call.genotypeKey.uppercased().map(String.init))
            if raw.isSubset(of: expectedSet) {
                if isPalindromic { palindromicMatched += 1 }
                continue
            }
            let flippedKey = Strand.complementGenotype(call.genotypeKey.uppercased())
            if Set(flippedKey.map(String.init)).isSubset(of: expectedSet) {
                flipped += 1
            } else {
                ambiguous += 1
            }
        }
        let strandGrade: QCGrade = ambiguous > 10 ? .warn : .pass
        checks.append(QCCheck(
            id: "strand", title: "Strand Sanity",
            grade: strandGrade,
            summary: "\(flipped) markers matched via complement flip; \(ambiguous) unresolvable; \(palindromicMatched) palindromic (A/T, C/G) sites matched — palindromic sites can never be strand-verified from array data.",
            details: [
                "Complement-flipped matches: \(flipped)",
                "Strand-ambiguous (unresolvable) markers: \(ambiguous)",
                "Palindromic catalog sites matched: \(palindromicMatched)",
            ]
        ))

        // 6. Sex consistency + autosomal heterozygosity band.
        let hetOK = meta.autosomalHet >= 0.25 && meta.autosomalHet <= 0.35
        checks.append(QCCheck(
            id: "het", title: "Autosomal Heterozygosity",
            grade: hetOK ? .pass : .warn,
            summary: String(format: "Autosomal heterozygosity %.1f%% (expected band 25–35%%).", meta.autosomalHet * 100)
                + (hetOK ? "" : " Out-of-band values suggest sample quality issues, unusual ancestry mix relative to the chip, or extensive autozygosity."),
            details: []
        ))
        let sexGrade: QCGrade = meta.inferredSex.contains("Uncertain") ? .warn : .pass
        checks.append(QCCheck(
            id: "sex", title: "Sex Chromosome Consistency",
            grade: sexGrade,
            summary: meta.inferredSex,
            details: []
        ))

        return QCReport(
            checks: checks,
            buildCall: buildCall,
            chipFingerprint: fingerprint,
            palindromicMatched: palindromicMatched,
            complementFlippedMatches: flipped
        )
    }

    /// Per-chip expected catalog coverage from the feature-1 `chips` field.
    private static func expectedCoverage(parsed: ParsedGenome) -> [String] {
        let markers = KnowledgeBase.shared.markers
        var out: [String] = []
        for chip in ["ancestry_v2", "23andme_v5", "myheritage"] {
            let expected = markers.filter { ($0.chips ?? []).contains(chip) }
            let present = expected.filter { parsed.calls[$0.rsid] != nil }.count
            out.append("If this were \(chip): \(present)/\(expected.count) expected catalog markers present")
        }
        return out
    }
}
