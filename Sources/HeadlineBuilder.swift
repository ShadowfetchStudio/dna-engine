import Foundation

/// Tiered headline findings for the Overview (feature 9). UI-free by contract.
///
/// Deterministic tier rules over existing analysis data:
///   tier 1 "Discuss with a clinician" — elevated research panel observations
///   tier 2 "Research and lifestyle topics" — notable observations with neutral context
///   tier 3 "Good news & typical"      — advantageous findings + coverage summary
/// Every finding carries a MANDATORY caveat; the harness fails on any empty one.
enum HeadlineBuilder {
    static func build(report: AnalysisReport) -> [HeadlineFinding] {
        var out: [HeadlineFinding] = []

        // --- Tier 1: elevated-tendency panels ---
        for s in report.calibratedScores where s.impact == .caution && !s.insufficientCoverage {
            out.append(HeadlineFinding(
                id: "score-\(s.id)",
                tier: 1,
                title: "\(s.title): \(s.riskCategory)",
                body: "A research tendency to discuss in the context of conventional screening, family history, and environment.",
                evidence: "\(s.percentile)th percentile vs \(s.referencePopulation) reference · \(s.usedSNPs)/\(s.totalSNPs) SNPs",
                caveat: "Percentile vs \(s.referencePopulation) reference allele frequencies under Hardy-Weinberg — a tendency estimate from \(s.usedSNPs) SNPs, not a clinical polygenic risk score (those use thousands to millions of variants).",
                source: .score,
                navTarget: NavItem.polygenic.rawValue,
                rsids: []
            ))
        }

        // --- Tier 3: non-interpretive marker coverage receipt ---
        out.append(HeadlineFinding(
            id: "coverage-observed",
            tier: 3,
            title: "\(report.catalogCoverage.matched) orientation-safe marker observations",
            body: "Raw calls were matched to catalog loci for research lookup. No single-marker genotype is translated into an enzyme/activity value, phenotype, diagnosis, risk, or personal outcome.",
            evidence: "\(report.catalogCoverage.matched) matched · \(report.catalogCoverage.noCall) no-call · \(report.catalogCoverage.missing) not on chip · \(report.catalogCoverage.strandAmbiguous) strand-unresolved",
            caveat: "Coverage does not establish interpretation; rare variants, repeats, phase, structural variation, and unmeasured context remain outside this array.",
            source: .marker,
            navTarget: NavItem.limits.rawValue,
            rsids: []
        ))

        return out
    }

    /// One deterministic probe of the marker-browser filter predicate:
    /// counts matched, strong-evidence locus receipts without an outcome filter.
    static func filterProbe(report: AnalysisReport) -> Int {
        filteredHits(report.hits, impact: nil, evidence: .strong, tier: nil, coverage: .matched).count
    }

    /// The single filter predicate shared by the FilterRail UI and the harness.
    static func filteredHits(_ hits: [MarkerHit], impact: Impact?, evidence: EvidenceLevel?, tier: String?, coverage: MarkerHit.Coverage?) -> [MarkerHit] {
        hits.filter { hit in
            (impact == nil || hit.impact == impact)
                && (evidence == nil || hit.evidence == evidence)
                && (tier == nil || hit.tier == tier)
                && (coverage == nil || hit.coverage == coverage)
        }
    }

    // MARK: - Caveats (mandatory, per source kind)

}
