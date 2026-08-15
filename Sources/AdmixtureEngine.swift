import Darwin
import Foundation

/// Fine-scale ancestry (2.1): supervised maximum-likelihood admixture of the
/// user's genotypes against the bundled reference panel's population
/// allele frequencies. UI-free by contract — compiled into the check harness.
///
/// Model (staging PANEL_REPORT.md consumption notes 1–6):
///   * Per marker, count ALT-allele dosage g ∈ {0,1,2} after orienting the
///     observed genotype against the panel's forward-strand ref/alt —
///     direct match first, then complement flip (MarkerMatcher convention).
///     Palindromic A/T–C/G sites are DROPPED, never guessed, and the drop is
///     disclosed.
///   * Genotype AF is modeled as the mixture p_i = Σ_k w_k · p_ik over the
///     reference set; the binomial log-likelihood is maximized on the simplex
///     with a fixed-iteration EM (deterministic: fixed init, fixed order,
///     no early exit) — supervised-ADMIXTURE style.
///   * Two tiers: (1) continental AFR/EUR/EAS/SAS/AMR + MID; (2) within-EUR
///     NWE/TSI/IBS/FIN/ASJ on the within-EUR informative subset, holding the
///     non-EUR components FIXED at their tier-1 estimates so Southern-European
///     ancestry cannot masquerade as Ashkenazi (or vice versa) — the ASJ
///     component is fitted jointly with TSI/IBS, exactly as the panel
///     validation demands.
///   * 95% confidence intervals via seeded marker bootstrap (deterministic
///     under the harness). Sub-continental intervals are honest, therefore
///     wide.
///
/// Every number ships with a "markers used: N of 2,621" disclosure and the
/// not-a-passport framing. Educational, never diagnostic.
enum AdmixtureEngine {

    // MARK: - Model constants (mirrored EXACTLY by the harness's independent
    // Python recomputation in Tools/run_checks.sh — change both together).

    static let afClamp = 1e-3          // consumption note 2: avoid -inf on fixed alleles
    static let emIterations = 300      // main fit — fixed count, no early exit
    static let bootstrapIterations = 40  // replicates warm-start at the main fit
    static let bootstrapReplicates = 200
    static let bootstrapSeed: UInt64 = 0xA11CE5EED
    static let minTier1Markers = 200
    static let minTier2Markers = 80
    static let minASJMarkers = 100
    static let tier2MinEuropeanShare = 0.12

    static let continentalPops = ["AFR", "EUR", "EAS", "SAS", "AMR", "MID"]
    static let continentalTitles: [String: String] = [
        "AFR": "African",
        "EUR": "European",
        "EAS": "East Asian",
        "SAS": "South Asian",
        "AMR": "Americas (admixed reference)",
        "MID": "Middle Eastern",
    ]
    static let eurPops = ["NWE", "TSI", "IBS", "FIN", "ASJ"]
    static let eurTitles: [String: String] = [
        "NWE": "Northwest European (CEU/GBR-like)",
        "TSI": "Southern European — Tuscan-like (TSI)",
        "IBS": "Southern European — Iberian-like (IBS)",
        "FIN": "Finnish (FIN)",
        "ASJ": "Ashkenazi Jewish (gnomAD ASJ)",
    ]
    /// Non-EUR components held fixed during the tier-2 fit (tier-1 order).
    static let tier2FixedPops = ["AFR", "EAS", "SAS", "AMR", "MID"]

    static let asjFraming =
        "This measures genetic similarity to gnomAD's Ashkenazi Jewish reference sample — an ancestry signal only. "
        + "It says nothing about identity, religion, or community membership, and it is not a determination of who anyone is."

    // MARK: - Orientation

    /// ALT-allele dosage for a call against a panel ref/alt pair, reusing the
    /// MarkerMatcher conventions: direct match, then complement flip, else nil.
    /// Palindromic pairs return nil via the caller's explicit pre-check.
    static func altDosage(call: SNPCall, ref: Character, alt: Character) -> Int? {
        guard !call.isNoCall else { return nil }
        let pair: Set<Character> = [ref, alt]
        let alleles = [call.allele1, call.allele2]
        if alleles.allSatisfy({ pair.contains($0) }) {
            return alleles.filter { $0 == alt }.count
        }
        let flipped = alleles.map { Strand.complement($0) }
        if flipped.allSatisfy({ pair.contains($0) }) {
            return flipped.filter { $0 == alt }.count
        }
        return nil
    }

    static func isPalindromic(ref: Character, alt: Character) -> Bool {
        let pair: Set<Character> = [ref, alt]
        return pair == Set("AT") || pair == Set("CG")
    }

    // MARK: - EM core (flat arrays; deterministic iteration order)

    /// Fixed-iteration EM for mixture weights on the simplex.
    /// `af` is row-major [marker][component], already clamped to [ε, 1-ε].
    /// The first `freeCount` components are re-estimated; any remaining
    /// components keep the weights given in `initial` (tier-2 constraint).
    /// The free block is renormalized to `freeBudget` every step.
    static func emFit(
        dosages: [Double], af: [Double], components: Int, freeCount: Int,
        freeBudget: Double, initial: [Double], iterations: Int
    ) -> [Double] {
        let n = dosages.count
        var w = initial
        guard n > 0, freeBudget > 0 else { return w }
        var acc = [Double](repeating: 0, count: components)

        for _ in 0..<iterations {
            for j in 0..<freeCount { acc[j] = 0 }
            for i in 0..<n {
                let g = dosages[i]
                let base = i * components
                var p = 0.0
                for j in 0..<components { p += w[j] * af[base + j] }
                let q = 1.0 - p
                for j in 0..<freeCount {
                    let pj = af[base + j]
                    let altResp = w[j] * pj / p
                    let refResp = w[j] * (1.0 - pj) / q
                    acc[j] += g * altResp + (2.0 - g) * refResp
                }
            }
            var sumFree = 0.0
            for j in 0..<freeCount { sumFree += acc[j] }
            if sumFree <= 0 { break }
            for j in 0..<freeCount { w[j] = freeBudget * acc[j] / sumFree }
        }
        return w
    }

    /// Seeded marker bootstrap: 95% percentile intervals per component.
    /// Deterministic — SplitMix64 stream, fixed replicate count, fixed order.
    /// Replicates WARM-START at the main fit (`initial`) so the resampling
    /// distribution scatters around the point estimate instead of dragging
    /// toward the uniform init at reduced iteration counts.
    static func bootstrapCI(
        dosages: [Double], af: [Double], components: Int, freeCount: Int,
        freeBudget: Double, initial: [Double], rng: inout SplitMix64
    ) -> [(low: Double, high: Double)] {
        let n = dosages.count
        let b = bootstrapReplicates
        var reps = [[Double]](repeating: [], count: components)
        for j in 0..<components { reps[j].reserveCapacity(b) }
        var rd = [Double](repeating: 0, count: n)
        var raf = [Double](repeating: 0, count: n * components)

        for _ in 0..<b {
            for i in 0..<n {
                let idx = Int(rng.next() % UInt64(n))
                rd[i] = dosages[idx]
                let src = idx * components, dst = i * components
                for j in 0..<components { raf[dst + j] = af[src + j] }
            }
            let w = emFit(
                dosages: rd, af: raf, components: components, freeCount: freeCount,
                freeBudget: freeBudget, initial: initial, iterations: bootstrapIterations
            )
            for j in 0..<components { reps[j].append(w[j]) }
        }

        let loIdx = Int((0.025 * Double(b)).rounded(.down))
        let hiIdx = min(b - 1, Int((0.975 * Double(b)).rounded(.down)))
        return (0..<components).map { j in
            let sorted = reps[j].sorted()
            return (sorted[loIdx], sorted[hiIdx])
        }
    }

    // MARK: - Analysis

    static func analyze(calls: [String: SNPCall]) -> AdmixtureReport? {
        guard let panel = ReferencePanel.shared else { return nil }

        let clamp: (Double) -> Double = { min(max($0, afClamp), 1.0 - afClamp) }

        // Single deterministic pass in panel-array order (packaging sorts by rsid).
        var t1Dos: [Double] = []
        var t1AF: [Double] = []
        var t2Dos: [Double] = []
        var t2AF: [Double] = []
        var asjDos: [Double] = []
        var asjPA: [Double] = []
        var asjPN: [Double] = []
        var palindromicDropped = 0
        var mismatchDropped = 0
        var tier2Total = 0
        var asjTotal = 0
        let tier2Cols = eurPops + tier2FixedPops   // 5 free + 5 fixed

        for m in panel.markers {
            if m.eur == true { tier2Total += 1 }
            if m.asj == true { asjTotal += 1 }
            guard let call = calls[m.rsid], !call.isNoCall else { continue }
            guard let ref = m.ref.uppercased().first, let alt = m.alt.uppercased().first else { continue }
            if isPalindromic(ref: ref, alt: alt) {
                palindromicDropped += 1
                continue
            }
            guard let dosage = altDosage(call: call, ref: ref, alt: alt) else {
                mismatchDropped += 1
                continue
            }
            let g = Double(dosage)

            if continentalPops.allSatisfy({ m.af[$0] != nil }) {
                t1Dos.append(g)
                for pop in continentalPops { t1AF.append(clamp(m.af[pop]!)) }
            }
            if m.eur == true, tier2Cols.allSatisfy({ m.af[$0] != nil }) {
                t2Dos.append(g)
                for pop in tier2Cols { t2AF.append(clamp(m.af[pop]!)) }
            }
            if m.asj == true, let pa = m.af["ASJ"], let pn = m.af["NFE"] {
                asjDos.append(g)
                asjPA.append(clamp(pa))
                asjPN.append(clamp(pn))
            }
        }

        let markersUsed = t1Dos.count
        let markersTotal = panel.markerCount
        let disclosure = "Markers used: \(markersUsed.formatted()) of \(markersTotal.formatted()) panel markers "
            + "(\(palindromicDropped) palindromic sites dropped — never strand-resolvable; "
            + "\(mismatchDropped) allele mismatches dropped; the rest are not on this chip or did not genotype)."

        var notes: [String] = [
            "Supervised admixture: your genotypes are modeled as a mixture of published reference allele frequencies and the mixing weights are maximum-likelihood estimates (fixed-iteration EM, deterministic). Intervals are seeded marker-bootstrap 95% ranges.",
            "Continental estimates are the robust tier. Sub-continental (within-European) estimates are approximate at best — treat them as ±10–15 percentage points, and recent admixture (a parent or grandparent from a different region) blurs them further.",
            "These are ancestry signals measured against specific reference samples — not a passport, nationality, ethnicity, or identity label.",
            "MID (gnomAD Middle Eastern) rests on a modest reference sample — treat the MID share as supporting evidence, not a primary call. AMR (1000G Americas) references are themselves recently admixed, so the AMR share jointly captures Indigenous-American and post-colonial admixture.",
        ]
        var footnotes: [String] = []
        for pop in continentalPops + eurPops + ["NFE"] {
            if let src = panel.popSources[pop] {
                footnotes.append("\(pop): \(src)")
            }
        }
        footnotes.append(contentsOf: panel.provenance.sourceSummary ?? [])

        // ---- Tier 1: continental --------------------------------------------
        let k1 = continentalPops.count
        var rng = SplitMix64(seed: bootstrapSeed)

        guard markersUsed >= minTier1Markers else {
            notes.insert("Too few panel markers usable on this file for an admixture estimate — the chip intersection is below the \(minTier1Markers)-marker floor, so no percentages are shown (they would be guesses).", at: 0)
            return AdmixtureReport(
                continental: [], markersUsed: markersUsed, markersTotal: markersTotal,
                palindromicDropped: palindromicDropped, mismatchDropped: mismatchDropped,
                insufficient: true,
                withinEuropean: [], withinEuropeanApplicable: false,
                withinEuropeanNote: "Not computed — continental tier is below its marker floor.",
                tier2MarkersUsed: t2Dos.count, tier2MarkersTotal: tier2Total,
                asj: ASJSignal(
                    band: "insufficient-markers", sharePercent: 0, ciLowPercent: 0, ciHighPercent: 0,
                    logLikelihoodRatio: 0, markersUsed: asjDos.count, markersTotal: asjTotal,
                    framing: asjFraming
                ),
                disclosure: disclosure, notes: notes, sourceFootnotes: footnotes
            )
        }

        let init1 = [Double](repeating: 1.0 / Double(k1), count: k1)
        let w1 = emFit(
            dosages: t1Dos, af: t1AF, components: k1, freeCount: k1,
            freeBudget: 1.0, initial: init1, iterations: emIterations
        )
        let ci1 = bootstrapCI(
            dosages: t1Dos, af: t1AF, components: k1, freeCount: k1,
            freeBudget: 1.0, initial: w1, rng: &rng
        )
        var continental: [AdmixtureComponent] = []
        for (j, pop) in continentalPops.enumerated() {
            // Percentile intervals are approximations; a shipped interval must
            // never exclude its own point estimate, so widen minimally if needed.
            continental.append(AdmixtureComponent(
                id: pop, title: continentalTitles[pop] ?? pop,
                share: w1[j], ciLow: min(ci1[j].low, w1[j]), ciHigh: max(ci1[j].high, w1[j])
            ))
        }
        continental.sort { $0.share == $1.share ? $0.id < $1.id : $0.share > $1.share }

        let eurShare = w1[continentalPops.firstIndex(of: "EUR")!]

        // ---- Tier 2: within-European (joint, non-EUR held fixed) -------------
        var withinEuropean: [AdmixtureComponent] = []
        var tier2Applicable = false
        var tier2Note: String
        var asjSignal: ASJSignal?

        let fixedWeights = tier2FixedPops.map { w1[continentalPops.firstIndex(of: $0)!] }
        let freeBudget = max(0.0, 1.0 - fixedWeights.reduce(0, +))   // == tier-1 EUR share

        if eurShare < tier2MinEuropeanShare {
            tier2Note = "Within-European breakdown not computed: the estimated European component ("
                + String(format: "%.1f%%", eurShare * 100)
                + ") is below the \(Int(tier2MinEuropeanShare * 100))% floor — decomposing a component that small would be noise dressed as insight."
            asjSignal = ASJSignal(
                band: "not-assessed", sharePercent: 0, ciLowPercent: 0, ciHighPercent: 0,
                logLikelihoodRatio: 0, markersUsed: asjDos.count, markersTotal: asjTotal,
                framing: asjFraming + " Not assessed here because the Ashkenazi component is only estimated inside a European component, and this file's European component is too small to decompose."
            )
        } else if t2Dos.count < minTier2Markers {
            tier2Note = "Within-European breakdown not computed: only \(t2Dos.count) of the \(tier2Total) within-EUR informative markers are usable on this chip (floor: \(minTier2Markers))."
            asjSignal = ASJSignal(
                band: "insufficient-markers", sharePercent: 0, ciLowPercent: 0, ciHighPercent: 0,
                logLikelihoodRatio: 0, markersUsed: asjDos.count, markersTotal: asjTotal,
                framing: asjFraming
            )
        } else {
            tier2Applicable = true
            let k2 = tier2Cols.count
            let free2 = eurPops.count
            var init2 = [Double](repeating: freeBudget / Double(free2), count: free2)
            init2.append(contentsOf: fixedWeights)
            let w2 = emFit(
                dosages: t2Dos, af: t2AF, components: k2, freeCount: free2,
                freeBudget: freeBudget, initial: init2, iterations: emIterations
            )
            // Bootstrap continues the SAME seeded stream (tier-1 reps, then tier-2).
            let ci2 = bootstrapCI(
                dosages: t2Dos, af: t2AF, components: k2, freeCount: free2,
                freeBudget: freeBudget, initial: w2, rng: &rng
            )
            for (j, pop) in eurPops.enumerated() {
                withinEuropean.append(AdmixtureComponent(
                    id: pop, title: eurTitles[pop] ?? pop,
                    share: w2[j], ciLow: min(ci2[j].low, w2[j]), ciHigh: max(ci2[j].high, w2[j])
                ))
            }
            withinEuropean.sort { $0.share == $1.share ? $0.id < $1.id : $0.share > $1.share }
            tier2Note = "Within-European components are shares of your WHOLE genome (they sum to the European component, "
                + String(format: "%.1f%%", freeBudget * 100)
                + "). Non-European components were held fixed at their continental estimates during this fit, and the Ashkenazi reference is fitted jointly with the Southern-European references so one cannot masquerade as the other. Resolution here is genuinely coarse: expect ±10–15 percentage points."

            // ---- ASJ founder signal ------------------------------------------
            var llr = 0.0
            for i in 0..<asjDos.count {
                let g = asjDos[i]
                llr += g * Darwin.log(asjPA[i] / asjPN[i]) + (2.0 - g) * Darwin.log((1.0 - asjPA[i]) / (1.0 - asjPN[i]))
            }
            let asjIdx = eurPops.firstIndex(of: "ASJ")!
            let p = w2[asjIdx]
            let lo = min(ci2[asjIdx].low, p)
            let hi = max(ci2[asjIdx].high, p)
            let band: String
            if asjDos.count < minASJMarkers {
                band = "insufficient-markers"
            } else if p < 0.02 || hi < 0.05 {
                band = "none-detected"
            } else if p >= 0.45 && lo >= 0.20 {
                band = "strong"
            } else if p >= 0.15 && lo >= 0.05 {
                band = "likely"
            } else {
                band = "possible"
            }
            asjSignal = ASJSignal(
                band: band,
                sharePercent: p * 100, ciLowPercent: lo * 100, ciHighPercent: hi * 100,
                logLikelihoodRatio: llr,
                markersUsed: asjDos.count, markersTotal: asjTotal,
                framing: asjFraming
            )
        }

        return AdmixtureReport(
            continental: continental,
            markersUsed: markersUsed, markersTotal: markersTotal,
            palindromicDropped: palindromicDropped, mismatchDropped: mismatchDropped,
            insufficient: false,
            withinEuropean: withinEuropean,
            withinEuropeanApplicable: tier2Applicable,
            withinEuropeanNote: tier2Note,
            tier2MarkersUsed: t2Dos.count, tier2MarkersTotal: tier2Total,
            asj: asjSignal,
            disclosure: disclosure,
            notes: notes,
            sourceFootnotes: footnotes
        )
    }
}
