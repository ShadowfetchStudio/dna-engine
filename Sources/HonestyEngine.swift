import Foundation

/// "What This Can't Tell You" (feature 8): merges the curated static
/// limitations from knowledge.json with COMPUTED, file-specific limits.
/// UI-free by contract — compiled into the check harness.
enum HonestyEngine {
    static func build(report: AnalysisReport, qc: QCReport) -> HonestyReport {
        let kb = KnowledgeBase.shared

        let staticEntries: [HonestyItem] = (kb.limitations ?? []).map {
            HonestyItem(
                id: $0.id,
                category: $0.category,
                title: $0.title,
                explanation: $0.explanation,
                pmidNote: $0.pmidNote,
                navHint: nil
            )
        }

        var computed: [HonestyItem] = []

        // 1. Catalog markers this chip simply doesn't carry.
        let missingHits = report.hits.filter { $0.coverage == .missing }
        let missingRsids = missingHits.map(\.rsid).sorted()
        if !missingRsids.isEmpty {
            let preview = missingRsids.prefix(24).joined(separator: ", ")
            computed.append(HonestyItem(
                id: "file-missing-markers",
                category: "this-file",
                title: "\(missingRsids.count) of \(report.hits.count) catalog markers are not on this chip",
                explanation: "These curated markers cannot be assessed from this file at all: \(preview)\(missingRsids.count > 24 ? ", …" : ""). Their absence is a property of the chip version, not of your genome.",
                pmidNote: "Chip-version manifests differ; see the QC tab's fingerprint",
                navHint: nil
            ))
        }

        // 2. Calls present in the file but withheld because strand orientation
        // cannot be validated are distinct from loci absent from the chip.
        let strandAmbiguousRsids = report.hits
            .filter { $0.coverage == .strandAmbiguous }
            .map(\.rsid)
            .sorted()
        if !strandAmbiguousRsids.isEmpty {
            let preview = strandAmbiguousRsids.prefix(24).joined(separator: ", ")
            computed.append(HonestyItem(
                id: "file-strand-unresolved",
                category: "this-file",
                title: "\(strandAmbiguousRsids.count) catalog observations are strand-unresolved",
                explanation: "Calls are present for these loci, but their orientation cannot be validated from this file and the shipped catalog alone: \(preview)\(strandAmbiguousRsids.count > 24 ? ", …" : ""). They are withheld rather than counted as matched or not on this chip.",
                pmidNote: "A/T and C/G loci require a separately validated orientation manifest",
                navHint: nil
            ))
        }

        // 3. No-calls on catalog markers.
        let noCallCount = report.hits.filter { $0.coverage == .noCall }.count
        if noCallCount > 0 {
            computed.append(HonestyItem(
                id: "file-nocalls",
                category: "this-file",
                title: "\(noCallCount) catalog markers failed to genotype (no-calls)",
                explanation: "The lab could not read these positions confidently. They are reported as 'no call', never guessed.",
                pmidNote: "See QC → No-Call Clustering for whether they cluster",
                navHint: nil
            ))
        }

        // 4. Panels running under the 60% coverage floor.
        let under = report.calibratedScores.filter { $0.insufficientCoverage }
        for panel in under {
            computed.append(HonestyItem(
                id: "panel-undercovered-\(panel.id)",
                category: "this-file",
                title: "Panel '\(panel.title)' below the 60% coverage floor",
                explanation: "Only \(panel.usedSNPs) of \(panel.totalSNPs) panel SNPs are typed in this file — no percentile is shown because it would be a guess.",
                pmidNote: "Coverage floor: \(Int(AnalysisEngine.minimumCoverageFraction * 100))% of panel SNPs",
                navHint: "polygenic"
            ))
        }

        // 5. QC warnings gate interpretation visibly.
        let qcWarnings = qc.checks.filter { $0.grade != .pass }
        for check in qcWarnings {
            computed.append(HonestyItem(
                id: "qc-\(check.id)",
                category: "this-file",
                title: "QC \(check.grade == .warn ? "warning" : "failure"): \(check.title)",
                explanation: check.summary,
                pmidNote: "See the Genome Quality Control tab",
                navHint: "qc"
            ))
        }

        // 6. Mitochondrial/Y probe absence on this vendor's export.
        let mtCount = report.genome.chromosomeCounts["MT", default: 0]
        let yCount = report.genome.chromosomeCounts["Y", default: 0]
        if mtCount == 0 {
            computed.append(HonestyItem(
                id: "file-no-mt",
                category: "this-file",
                title: "No mitochondrial probes in this file",
                explanation: "This export contains zero MT rows — maternal-line haplogroup and mitochondrial variants are entirely out of reach for this file.",
                pmidNote: "Vendor chip property",
                navHint: nil
            ))
        }
        if yCount == 0 {
            computed.append(HonestyItem(
                id: "file-no-y",
                category: "this-file",
                title: "No Y-chromosome rows in this file",
                explanation: "Either the sample is XX or the vendor omitted Y probes; paternal-line analysis is not possible from this file.",
                pmidNote: "Vendor chip property / inferred sex: \(report.genome.inferredSex)",
                navHint: nil
            ))
        }

        // 7. Euro-bias banner condition (feature 8b): fires when the user's
        //    estimated European share is under 50% — most catalog content and
        //    all percentiles lean on European-ancestry discovery cohorts.
        //    2.1: the reference-panel admixture EUR estimate is the better
        //    number when available; the 36-AIM sketch remains the fallback.
        let euroShare = admixtureEuropeanShare(report) ?? report.ancestry.shares["european"] ?? 0
        let hasEstimate = !report.ancestry.shares.isEmpty || admixtureEuropeanShare(report) != nil
        let bannerFires = hasEstimate && euroShare < 0.5
        if bannerFires {
            computed.append(HonestyItem(
                id: "ancestry-transfer",
                category: "statistical",
                title: "Your estimated ancestry mix reduces predictive value here",
                explanation: "Most variants and all percentiles in this app were discovered in European-ancestry cohorts; your estimated ancestry (\(report.ancestry.confidence)) is majority non-European, so effect sizes and percentiles transfer imperfectly. Cards tagged multi-ancestry or with matching derived-ancestry tags are the most reliable for you.",
                pmidNote: "Martin 2019 (PMID 30926966) — PRS transferability",
                navHint: "polygenic"
            ))
        }

        return HonestyReport(
            staticEntries: staticEntries,
            computed: computed,
            missingMarkerCount: missingRsids.count,
            missingMarkerRsids: missingRsids,
            strandAmbiguousMarkerCount: strandAmbiguousRsids.count,
            strandAmbiguousMarkerRsids: strandAmbiguousRsids,
            underCoveredPanels: under.map(\.id),
            qcWarnings: qcWarnings.map(\.id),
            euroBiasBannerFires: bannerFires
        )
    }

    /// 2.1: European share from the reference-panel admixture when computed.
    static func admixtureEuropeanShare(_ report: AnalysisReport) -> Double? {
        guard let adm = report.admixture, !adm.insufficient else { return nil }
        return adm.continental.first { $0.id == "EUR" }?.share
    }

    /// Per-view banner text (feature 8a). Returns nil when the banner should
    /// not fire for this user.
    static func euroBiasBanner(report: AnalysisReport) -> String? {
        let sketchShare = report.ancestry.shares["european"]
        let euroShare = admixtureEuropeanShare(report) ?? sketchShare ?? 0
        guard admixtureEuropeanShare(report) != nil || sketchShare != nil, euroShare < 0.5 else { return nil }
        if let adm = report.admixture, !adm.insufficient {
            return "Most variants and all percentiles here were discovered in European-ancestry cohorts; predictive value for your estimated ancestry mix is reduced. The estimate itself is approximate (\(adm.markersUsed) reference-panel markers)."
        }
        return "Most variants and all percentiles here were discovered in European-ancestry cohorts; predictive value for your estimated ancestry mix is reduced. The estimate itself is approximate (\(report.ancestry.usedMarkers) ancestry-informative markers)."
    }

    /// Feature 4 pairing: fires when a panel's reference population disagrees
    /// with the user's own majority ancestry estimate.
    static func referenceMismatchBanner(score: CalibratedPolygenicScore, report: AnalysisReport) -> String? {
        guard let top = report.ancestry.shares.max(by: { $0.value < $1.value })?.key else { return nil }
        guard score.referencePopulation != top else { return nil }
        return "Percentile computed against \(score.referencePopulation) reference frequencies, which is not your estimated majority ancestry (\(top)) — treat the number as a rougher sketch."
    }
}
