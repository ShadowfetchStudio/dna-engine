import Foundation
import zlib

// DNA Engine deterministic check harness (feature 2).
// Compiled by Tools/run_checks.sh together with every UI-free engine file.
// Modes:
//   report            parse the demo persona, run the full analysis, emit
//                     canonical sorted JSON on stdout
//   demo-text         emit the raw demo genome text (byte-stability check)
//   decode <path>     decode a KnowledgeFile JSON (backward-compat check)
//   erase-test        sandboxed AppPaths override; plants every known file
//                     type; verifies eraseAll leaves nothing behind
//   fixture <path>    parse a genome fixture and emit its QC summary
//   parser-checks <path> validate safe archives, VCF selection, and receipts

@main
struct CheckMain {
    static func main() {
        let args = CommandLine.arguments
        let mode = args.count > 1 ? args[1] : "report"
        switch mode {
        case "report":
            runReport()
        case "demo-text":
            print(DemoGenome.makeText(), terminator: "")
        case "decode":
            guard args.count > 2 else { fail("decode needs a path") }
            runDecode(path: args[2])
        case "erase-test":
            runEraseTest()
        case "fixture":
            guard args.count > 2 else { fail("fixture needs a path") }
            runFixture(path: args[2])
        case "parser-checks":
            guard args.count > 2 else { fail("parser-checks needs the multisample VCF fixture path") }
            runParserChecks(fixturePath: args[2])
        case "clinician-sheet":
            runClinicianSheet()
        case "report-md":
            // Full markdown export of the demo analysis — for eyeballing the
            // report surface (the harness asserts its key lines via reportChecks).
            runReportMarkdown()
        case "pgx-of":
            // Full-pipeline phenotype readout for an arbitrary genome file:
            // used by the harness to prove a corrupted demo genotype CHANGES
            // the analysis (silent-corruption canary).
            guard args.count > 2 else { fail("pgx-of needs a path") }
            runPgxOf(path: args[2])
        default:
            fail("unknown mode \(mode)")
        }
    }

    static func fail(_ msg: String) -> Never {
        FileHandle.standardError.write(("CHECK FAIL: " + msg + "\n").data(using: .utf8)!)
        exit(1)
    }

    static func emitJSON(_ obj: Any) {
        guard JSONSerialization.isValidJSONObject(obj),
              let data = try? JSONSerialization.data(withJSONObject: obj, options: [.sortedKeys, .prettyPrinted]) else {
            fail("could not serialize check output")
        }
        FileHandle.standardOutput.write(data)
        FileHandle.standardOutput.write("\n".data(using: .utf8)!)
    }

    // MARK: - decode

    static func runDecode(path: String) {
        let url = URL(fileURLWithPath: path)
        guard let data = try? Data(contentsOf: url) else { fail("cannot read \(path)") }
        do {
            let file = try JSONDecoder().decode(KnowledgeFile.self, from: data)
            var out: [String: Any] = [:]
            out["markers"] = file.markers.count
            out["aims"] = file.aims.count
            out["scores"] = file.scores.count
            out["compounds"] = file.compounds?.count ?? -1
            out["pgxGenes"] = file.pgx?.count ?? -1
            out["limitations"] = file.limitations?.count ?? -1
            out["demoRows"] = file.demo?.count ?? -1
            out["markersWithCitations"] = file.markers.filter { !($0.citations ?? []).isEmpty }.count
            out["markersWithTier"] = file.markers.filter { $0.tier != nil }.count
            out["markersWithChips"] = file.markers.filter { !($0.chips ?? []).isEmpty }.count
            let locMarkers = file.markers.filter { $0.gene.uppercased().hasPrefix("LOC") }.count
            let locAims = file.aims.filter { $0.gene.uppercased().hasPrefix("LOC") }.count
            out["locGenes"] = locMarkers + locAims
            emitJSON(out)
        } catch {
            fail("decode failed for \(path): \(error)")
        }
    }

    // MARK: - report

    static func runReport() {
        let text = DemoGenome.makeText()
        guard let parsed = try? GenomeParser.parse(text: text) else { fail("demo parse failed") }
        let meta = GenomeStats.summarize(parsed: parsed, sourcePath: "demo", fileName: "demo")
        let report = AnalysisEngine.analyze(parsed: parsed, meta: meta)

        var out: [String: Any] = [:]

        out["coverage"] = [
            "matched": report.catalogCoverage.matched,
            "noCall": report.catalogCoverage.noCall,
            "missing": report.catalogCoverage.missing,
            "strandAmbiguous": report.catalogCoverage.strandAmbiguous,
        ]
        out["strandAmbiguous"] = report.hits.filter { $0.coverage == .strandAmbiguous }.map(\.rsid).sorted()

        var compounds: [String: Any] = [:]
        for c in report.compounds {
            compounds[c.id] = ["value": c.value, "impact": c.impact.rawValue]
        }
        out["compounds"] = compounds

        var pgx: [String: Any] = [:]
        for observation in report.pharmacogenomics.geneObservations {
            pgx[observation.gene] = [
                "observed": observation.observedCount,
                "total": observation.loci.count,
                "unresolved": observation.unresolvedCount,
                "loci": observation.loci.map {
                    ["rsid": $0.rsid, "genotype": $0.observedGenotype, "status": $0.status.rawValue]
                },
            ]
        }
        out["pgxObservations"] = pgx

        var panels: [String: Any] = [:]
        for s in report.calibratedScores {
            var p: [String: Any] = [
                "used": s.usedSNPs,
                "total": s.totalSNPs,
                "category": s.riskCategory,
                "referencePopulation": s.referencePopulation,
                "insufficient": s.insufficientCoverage,
            ]
            if s.insufficientCoverage {
                p["percentile"] = NSNull()
            } else {
                p["percentile"] = s.percentile
                p["percentileByPopulation"] = s.percentileByPopulation
            }
            panels[s.id] = p
        }
        out["panels"] = panels

        // Full-panel Swift-side calibration for the independent Python HWE cross-check.
        var calibDebug: [String: Any] = [:]
        for panel in KnowledgeBase.shared.scores {
            var pops: [String: Any] = [:]
            for pop in KnowledgeBase.shared.populations {
                let cal = AnalysisEngine.hweCalibration(panel: panel, population: pop, onlyRsids: nil)
                pops[pop] = ["mean": cal.mean, "sd": cal.sd]
            }
            calibDebug[panel.id] = pops
        }
        out["calibDebug"] = calibDebug

        var ancestryOut: [String: Any] = [:]
        ancestryOut["top"] = report.ancestry.shares.max(by: { $0.value < $1.value })?.key ?? "none"
        let euroShare = report.ancestry.shares["european"] ?? 0
        ancestryOut["europeanShare4"] = Double(Int((euroShare * 10000).rounded())) / 10000
        ancestryOut["used"] = report.ancestry.usedMarkers
        out["ancestry"] = ancestryOut
        out["sex"] = report.genome.inferredSex

        // 2.1 fine-scale ancestry: deterministic admixture snapshot (4 dp).
        func r4(_ v: Double) -> Double { Double(Int((v * 10000).rounded())) / 10000 }
        var admixOut: [String: Any] = [:]
        if let adm = report.admixture {
            var cont: [String: Any] = [:]
            for c in adm.continental {
                cont[c.id] = ["share": r4(c.share), "lo": r4(c.ciLow), "hi": r4(c.ciHigh)]
            }
            admixOut["continental"] = cont
            admixOut["markersUsed"] = adm.markersUsed
            admixOut["markersTotal"] = adm.markersTotal
            admixOut["palindromicDropped"] = adm.palindromicDropped
            admixOut["mismatchDropped"] = adm.mismatchDropped
            admixOut["insufficient"] = adm.insufficient
            admixOut["tier2Applicable"] = adm.withinEuropeanApplicable
            admixOut["tier2Used"] = adm.tier2MarkersUsed
            admixOut["tier2Total"] = adm.tier2MarkersTotal
            var eur: [String: Any] = [:]
            for c in adm.withinEuropean {
                eur[c.id] = ["share": r4(c.share), "lo": r4(c.ciLow), "hi": r4(c.ciHigh)]
            }
            admixOut["withinEuropean"] = eur
            if let asj = adm.asj {
                admixOut["asj"] = [
                    "band": asj.band,
                    "sharePct4": r4(asj.sharePercent),
                    "loPct4": r4(asj.ciLowPercent),
                    "hiPct4": r4(asj.ciHighPercent),
                    "llr4": r4(asj.logLikelihoodRatio),
                    "used": asj.markersUsed,
                    "total": asj.markersTotal,
                ]
            }
        } else {
            admixOut["panelMissing"] = true
        }
        out["admixture"] = admixOut

        var rohOut: [String: Any] = [:]
        rohOut["fROH"] = Double(Int((report.roh.fROH * 10000).rounded())) / 10000
        rohOut["longestMb"] = Double(Int((report.roh.longestMb * 10).rounded())) / 10
        rohOut["longCount"] = report.roh.regions.filter { $0.lengthClass == .long }.count
        rohOut["interpretation"] = report.roh.interpretation
        rohOut["plantedDetected"] = report.roh.regions.contains { region in
            let startOK = abs(region.start - DemoGenome.rohStart) < 1_000_000
            let endOK = abs(region.end - DemoGenome.rohEnd) < 1_000_000
            return region.chromosome == DemoGenome.rohChromosome && startOK && endOK
        }
        out["roh"] = rohOut

        let qc = QCEngine.assess(parsed: parsed, meta: meta)
        var qcOut: [String: Any] = [:]
        for check in qc.checks {
            qcOut[check.id] = check.grade.rawValue
        }
        out["qc"] = qcOut
        out["buildDetected"] = qc.buildCall
        out["noCallClusterFlagged"] = qc.checks.first { $0.id == "clustering" }?.grade == .warn
            && qc.details(for: "clustering").contains { $0.contains("chr\(DemoGenome.noCallChromosome)") }
        out["palindromicMatched"] = qc.palindromicMatched
        out["strandAmbiguousCount"] = report.hits.filter { $0.coverage == .strandAmbiguous }.count

        let honesty = HonestyEngine.build(report: report, qc: qc)
        out["honesty"] = [
            "computedCount": honesty.computed.count,
            "missingMarkerCount": honesty.missingMarkerCount,
            "strandAmbiguousMarkerCount": honesty.strandAmbiguousMarkerCount,
            "underCoveredPanels": honesty.underCoveredPanels.sorted(),
            "euroBiasBannerFires": honesty.euroBiasBannerFires,
            "staticCount": honesty.staticEntries.count,
        ]

        let headlines = HeadlineBuilder.build(report: report)
        var headOut: [String: Any] = [:]
        headOut["tier1"] = headlines.filter { $0.tier == 1 }.count
        headOut["tier2"] = headlines.filter { $0.tier == 2 }.count
        headOut["tier3"] = headlines.filter { $0.tier == 3 }.count
        headOut["compoundFindings"] = headlines.filter { $0.source == .compound }.count
        let tier1Ids: [String] = headlines.filter { $0.tier == 1 }.map(\.id).sorted()
        headOut["tier1Ids"] = tier1Ids
        let emptyCaveats = headlines.filter { $0.caveat.trimmingCharacters(in: .whitespaces).isEmpty }
        headOut["emptyCaveats"] = emptyCaveats.count
        headOut["filterRailProbe"] = HeadlineBuilder.filterProbe(report: report)
        out["headlines"] = headOut

        // Feature 10: deterministic report-surface checks on the markdown + clinician sheet.
        let md = ReportExport.fullReport(report, format: .markdown)
        let clin = ReportExport.pgxClinicalBriefHTML(report)
        let allCitations = ReportExport.dedupedCitations(report)
        var reportChecks: [String: Any] = [:]
        reportChecks["limitsHeadingPresent"] = md.contains("## Appendix B — What This Report Is Not")
        reportChecks["citationAppendixCount"] = allCitations.count
        reportChecks["citationHeadingPresent"] = md.contains("## Appendix A — Citations")
        reportChecks["pgxResearchBannerPresent"] = clin.contains("No star allele, diplotype, phenotype, medication response, or clinical action is inferred")
        let cyp2c19 = report.pharmacogenomics.geneObservations.first { $0.gene == "CYP2C19" }
        let defining = Set((PharmacogenomicsEngine.gene(named: "CYP2C19")?.alleles ?? []).map(\.rsid))
        let emitted = Set(cyp2c19?.loci.map(\.rsid) ?? [])
        reportChecks["cyp2c19CompleteDefiningLoci"] = !defining.isEmpty && defining == emitted
        reportChecks["pgxNoPhenotypeCalls"] = report.pharmacogenomics.assessedGenes.values.allSatisfy { $0 == .indeterminate }
        reportChecks["pgxNoAlerts"] = report.pharmacogenomics.highRiskDrugCount == 0
        reportChecks["coverageBucketsExplicit"] = md.contains("strand-unresolved")
            && md.contains("not on this chip")
            && md.contains("no-call")
        reportChecks["markerDetailsNonDirective"] = report.hits
            .filter { $0.coverage == .matched }
            .allSatisfy { $0.detail == MarkerMatcher.researchDetail }
        let activityProbeIDs = ["rs1801133", "rs7501331"]
        let activityProbes = activityProbeIDs.compactMap { id in
            report.hits.first { $0.rsid == id }
        }
        reportChecks["demoActivityMarkersRetained"] = activityProbes.count == activityProbeIDs.count
            && activityProbes.allSatisfy { $0.coverage == .matched && !($0.citations ?? []).isEmpty }
            && Dictionary(uniqueKeysWithValues: activityProbes.map { ($0.rsid, $0.observed) }) == [
                "rs1801133": "T/T",
                "rs7501331": "C/T",
            ]
        reportChecks["demoActivityClaimsWithheld"] = activityProbes.allSatisfy {
            $0.label == MarkerMatcher.researchLabel
                && $0.summary == MarkerMatcher.researchSummary
                && $0.mechanism == MarkerMatcher.researchMechanism
                && $0.detail == MarkerMatcher.researchDetail
                && $0.impact == .typical
                && $0.effect == nil
                && $0.actions.isEmpty
        }
        reportChecks["allSingleMarkerOutcomesWithheld"] = report.hits.allSatisfy { hit in
            hit.mechanism == MarkerMatcher.researchMechanism
                && hit.detail == MarkerMatcher.researchDetail
                && hit.effect == nil
                && hit.actions.isEmpty
                && (hit.coverage != .matched || (
                    hit.label == MarkerMatcher.researchLabel
                        && hit.summary == MarkerMatcher.researchSummary
                        && hit.impact == .typical
                ))
        }
        let leakedActivityPhrases = [
            "enzyme activity drops", "residual activity", "reduction in beta-carotene",
            "acetaldehyde clearance velocity", "tyrosinase activity ~", "retain ~30% activity",
        ]
        reportChecks["demoActivityReportReceiptsOnly"] = activityProbeIDs.allSatisfy {
            md.contains("Locus: `\($0)`")
        } && leakedActivityPhrases.allSatisfy { !md.lowercased().contains($0.lowercased()) }
        // 2.1: the ancestry section must ship with its marker-count disclosure
        // and the not-a-passport framing, in every export, unconditionally.
        reportChecks["ancestryAdmixturePresent"] = md.contains("### Continental composition")
        reportChecks["ancestryDisclosurePresent"] = md.contains("of 2,621 panel markers")
        reportChecks["ancestryNotPassportPresent"] = md.contains("not a passport")
        out["reportChecks"] = reportChecks

        emitJSON(out)
    }

    static func runPgxOf(path: String) {
        guard let text = try? String(contentsOfFile: path, encoding: .utf8),
              let parsed = try? GenomeParser.parse(text: text) else { fail("cannot parse \(path)") }
        let pgxReport = PharmacogenomicsEngine.analyze(calls: parsed.calls)
        guard let cyp2c19 = pgxReport.geneObservations.first(where: { $0.gene == "CYP2C19" }) else {
            fail("CYP2C19 observation missing")
        }
        emitJSON(Dictionary(uniqueKeysWithValues: cyp2c19.loci.map {
            ($0.rsid, ["genotype": $0.observedGenotype, "status": $0.status.rawValue])
        }))
    }

    static func runReportMarkdown() {
        let text = DemoGenome.makeText()
        guard let parsed = try? GenomeParser.parse(text: text) else { fail("demo parse failed") }
        let meta = GenomeStats.summarize(parsed: parsed, sourcePath: "demo", fileName: "demo")
        let report = AnalysisEngine.analyze(parsed: parsed, meta: meta)
        print(ReportExport.fullReport(report, format: .markdown))
    }

    // MARK: - clinician sheet (for the dosing-verb grep)

    static func runClinicianSheet() {
        let text = DemoGenome.makeText()
        guard let parsed = try? GenomeParser.parse(text: text) else { fail("demo parse failed") }
        let meta = GenomeStats.summarize(parsed: parsed, sourcePath: "demo", fileName: "demo")
        let report = AnalysisEngine.analyze(parsed: parsed, meta: meta)
        print(ReportExport.pgxClinicalBriefHTML(report))
    }

    // MARK: - erase test

    static func runEraseTest() {
        let sandbox = FileManager.default.temporaryDirectory
            .appendingPathComponent("dnaengine-erase-test-\(ProcessInfo.processInfo.processIdentifier)")
        try? FileManager.default.removeItem(at: sandbox)
        AppPaths.overrideSupport = sandbox

        // Plant every known persisted artifact, including the once-leaked ones.
        try? "g".write(to: AppPaths.genomeCopy, atomically: true, encoding: .utf8)
        try? "s".write(to: AppPaths.secondaryGenomeCopy, atomically: true, encoding: .utf8)
        try? "{}".write(to: AppPaths.meta, atomically: true, encoding: .utf8)
        try? "d".write(to: AppPaths.demoGenome, atomically: true, encoding: .utf8)
        try? "r".write(to: AppPaths.reports.appendingPathComponent("x.md"), atomically: true, encoding: .utf8)
        try? "p".write(to: AppPaths.profiles.appendingPathComponent("p.json"), atomically: true, encoding: .utf8)
        try? "stray".write(to: AppPaths.support.appendingPathComponent("stray_file.tmp"), atomically: true, encoding: .utf8)

        let before = LocalEraser.enumerate()
        guard before.count >= 6 else { fail("erase-test setup expected >=6 entries, saw \(before.count)") }

        let survivors = LocalEraser.eraseAll()
        try? FileManager.default.removeItem(at: sandbox)
        if survivors.isEmpty {
            emitJSON(["erase": "verified-empty", "planted": before.count])
        } else {
            fail("erase left survivors: \(survivors.map(\.path))")
        }
    }

    // MARK: - fixture

    static func runFixture(path: String) {
        guard let text = try? String(contentsOfFile: path, encoding: .utf8) else { fail("cannot read fixture") }
        guard let parsed = try? GenomeParser.parse(text: text) else { fail("fixture parse failed") }
        let meta = GenomeStats.summarize(parsed: parsed, sourcePath: path, fileName: (path as NSString).lastPathComponent)
        let qc = QCEngine.assess(parsed: parsed, meta: meta)
        let roh = ROHScanner.scan(ordered: parsed.ordered)
        var qcOut: [String: Any] = [:]
        for check in qc.checks { qcOut[check.id] = check.grade.rawValue }
        emitJSON([
            "qc": qcOut,
            "callRateGrade": qc.checks.first { $0.id == "callRate" }?.grade.rawValue ?? "?",
            "fROH": Double(Int((roh.fROH * 10000).rounded())) / 10000,
            "rohRegions": roh.regions.count,
            "rohInterpretation": roh.interpretation,
        ])
    }

    // MARK: - safe parser/import foundation

    static func runParserChecks(fixturePath: String) {
        do {
            let fixture = try String(contentsOfFile: fixturePath, encoding: .utf8)
            let testOptions = GenomeImportOptions(minimumAcceptedRecords: 1)

            let defaulted = try GenomeParser.parse(text: fixture, options: testOptions)
            let d = defaulted.receipt.diagnostics
            parserRequire(d.reconciles, "VCF diagnostics do not reconcile")
            parserRequire(d.totalRecords == 10, "expected 10 VCF records, saw \(d.totalRecords)")
            parserRequire(d.acceptedRecords == 3 && d.skippedRecords == 7, "unexpected accepted/skipped counts")
            parserRequire(d.duplicateRecords == 1 && d.conflictRecords == 1, "duplicate/conflict counts drifted")
            parserRequire(d.malformedRecords == 1, "malformed count drifted")
            parserRequire(d.unsupportedRecords == 4 && d.filteredRecords == 1, "unsupported/filter counts drifted")
            parserRequire(d.noCallRecords == 1, "no-call count drifted")
            parserRequire(defaulted.calls["rs1001"]?.genotypeKey == "AG", "GT was not read from its FORMAT index")
            parserRequire(defaulted.calls["rs1002"]?.genotypeKey == "CT", "phased diploid GT was not accepted")
            parserRequire(defaulted.calls["rs1008"]?.isNoCall == true, "diploid no-call was not retained for QC")
            parserRequire(defaulted.calls["rs1003"] == nil, "haploid GT was silently accepted")
            parserRequire(defaulted.calls["rs1004"] == nil, "multiallelic record was silently accepted")
            parserRequire(defaulted.calls["rs1005"] == nil, "indel was silently truncated to one base")
            parserRequire(defaulted.calls["rs1006"] == nil, "filtered record was silently accepted")
            parserRequire(
                defaulted.receipt.selectedVCFSample?.mode == .defaultedToFirst
                    && defaulted.receipt.selectedVCFSample?.selectedSample == "Alpha",
                "multisample default was not disclosed"
            )
            parserRequire(
                defaulted.receipt.notices.contains { $0.code == .vcfSampleDefaulted },
                "defaulted VCF sample notice missing"
            )
            let messages = d.examples.map(\.message).joined(separator: " ").lowercased()
            for expected in ["diploid", "multiallelic", "indels", "filter", "position"] {
                parserRequire(messages.contains(expected), "diagnostic example missing \(expected)")
            }

            let betaOptions = GenomeImportOptions(selectedVCFSample: "Beta", minimumAcceptedRecords: 1)
            let beta = try GenomeParser.parse(text: fixture, options: betaOptions)
            parserRequire(beta.receipt.selectedVCFSample?.mode == .explicitlySelected, "explicit sample mode missing")
            parserRequire(beta.receipt.selectedVCFSample?.selectedSample == "Beta", "Beta was not selected")
            parserRequire(beta.calls["rs1001"]?.genotypeKey == "GG", "selected sample genotype is incorrect")
            parserRequire(beta.calls["rs1003"]?.genotypeKey == "AG", "selected Beta sample did not use its GT")

            do {
                _ = try GenomeParser.parse(
                    text: fixture,
                    options: GenomeImportOptions(selectedVCFSample: "Missing", minimumAcceptedRecords: 1)
                )
                fail("unknown VCF sample was accepted")
            } catch GenomeParser.ParseError.vcfSampleNotFound(let requested, let available) {
                parserRequire(requested == "Missing" && available == ["Alpha", "Beta"], "sample error lacks choices")
            }

            let rawText = "# synthetic raw DNA\nrs2001\t1\t2001\tAG\nrs2002\t1\t2002\tCC\n"
            let raw = Data(rawText.utf8)
            let gzip = try makeGzip(raw)
            // Normal ZIP tools use raw DEFLATE (method 8); stored ZIPs remain
            // covered by the hostile/multi-entry/corruption paths below.
            let zip = try makeDeflatedZip(TestZipEntry(name: "genome.txt", data: raw))
            let sandbox = FileManager.default.temporaryDirectory
                .appendingPathComponent("dnaengine-parser-checks-\(ProcessInfo.processInfo.processIdentifier)")
            try? FileManager.default.removeItem(at: sandbox)
            try FileManager.default.createDirectory(at: sandbox, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: sandbox) }

            let gzipURL = sandbox.appendingPathComponent("renamed-as-text.txt")
            let zipURL = sandbox.appendingPathComponent("archive-without-extension.raw")
            try gzip.write(to: gzipURL, options: .atomic)
            try zip.write(to: zipURL, options: .atomic)

            let parsedGzip = try GenomeParser.parse(url: gzipURL, options: testOptions)
            parserRequire(parsedGzip.calls.count == 2, "gzip payload did not parse")
            parserRequire(parsedGzip.receipt.source.originalExtension == "txt", "original extension was not preserved")
            parserRequire(parsedGzip.receipt.source.detectedContainer == .gzip, "gzip magic was not detected")
            parserRequire(parsedGzip.receipt.archive?.status == .validated, "gzip validation receipt missing")
            parserRequire(parsedGzip.receipt.archive?.checksumValidated == true, "gzip checksum status missing")
            parserRequire(
                parsedGzip.receipt.notices.contains { $0.code == .extensionMismatch },
                "renamed gzip mismatch was not disclosed"
            )

            let parsedZip = try GenomeParser.parse(url: zipURL, options: testOptions)
            parserRequire(parsedZip.calls.count == 2, "ZIP payload did not parse")
            parserRequire(parsedZip.receipt.source.detectedContainer == .zip, "ZIP magic was not detected")
            parserRequire(parsedZip.receipt.archive?.memberName == "genome.txt", "ZIP member receipt missing")
            parserRequire(parsedZip.receipt.archive?.status == .validated, "ZIP validation receipt missing")

            // Vault restore must keep original compressed bytes in memory and
            // never require a plaintext temporary file.
            let memoryGzip = try GenomeParser.parse(
                data: gzip,
                sourceName: "vault-original.dat",
                options: testOptions
            )
            let memoryZip = try GenomeParser.parse(
                data: zip,
                sourceName: "vault-original.dat",
                options: testOptions
            )
            parserRequire(
                memoryGzip.calls.count == 2 && memoryGzip.receipt.source.detectedContainer == .gzip,
                "in-memory gzip restore failed"
            )
            parserRequire(
                memoryZip.calls.count == 2
                    && memoryZip.receipt.source.detectedContainer == .zip
                    && memoryZip.receipt.archive?.memberName == "genome.txt",
                "in-memory ZIP restore failed"
            )

            let hostileURL = sandbox.appendingPathComponent("hostile.bin")
            try makeStoredZip([TestZipEntry(name: "../genome.txt", data: raw)]).write(to: hostileURL)
            parserExpectImportError("path traversal ZIP", operation: {
                _ = try GenomeParser.parse(url: hostileURL, options: testOptions)
            }, matches: {
                if case .unsafeArchiveMember = $0 { return true }
                return false
            })

            let multiURL = sandbox.appendingPathComponent("multiple.bin")
            try makeStoredZip([
                TestZipEntry(name: "one.txt", data: raw),
                TestZipEntry(name: "two.txt", data: raw),
            ]).write(to: multiURL)
            parserExpectImportError("multi-entry ZIP", operation: {
                _ = try GenomeParser.parse(url: multiURL, options: testOptions)
            }, matches: {
                if case .archiveMemberCount(2) = $0 { return true }
                return false
            })

            let corruptZipURL = sandbox.appendingPathComponent("bad-crc.bin")
            try makeStoredZip(
                [TestZipEntry(name: "genome.txt", data: raw)],
                checksumXor: 0x00000001
            ).write(to: corruptZipURL)
            parserExpectImportError("corrupt ZIP", operation: {
                _ = try GenomeParser.parse(url: corruptZipURL, options: testOptions)
            }, matches: { $0 == .archiveChecksumMismatch })

            var corruptGzip = gzip
            corruptGzip[corruptGzip.count - 1] ^= 0xff
            let corruptGzipURL = sandbox.appendingPathComponent("bad-gzip.bin")
            try corruptGzip.write(to: corruptGzipURL)
            parserExpectImportError("corrupt gzip", operation: {
                _ = try GenomeParser.parse(url: corruptGzipURL, options: testOptions)
            }, matches: {
                if case .corruptArchive = $0 { return true }
                return false
            })

            var concatenatedGzip = gzip
            concatenatedGzip.append(gzip)
            let concatenatedURL = sandbox.appendingPathComponent("concatenated-gzip.bin")
            try concatenatedGzip.write(to: concatenatedURL)
            parserExpectImportError("concatenated gzip", operation: {
                _ = try GenomeParser.parse(url: concatenatedURL, options: testOptions)
            }, matches: { $0 == .trailingArchiveData })

            let oversizeLimits = GenomeImportLimits(
                maximumInputBytes: 1_024 * 1_024,
                maximumExpandedBytes: raw.count - 1,
                maximumCompressionRatio: 1_000
            )
            parserExpectImportError("expanded output cap", operation: {
                _ = try GenomeParser.parse(
                    url: zipURL,
                    options: GenomeImportOptions(minimumAcceptedRecords: 1, limits: oversizeLimits)
                )
            }, matches: {
                if case .expandedLimitExceeded = $0 { return true }
                return false
            })

            let inputCapLimits = GenomeImportLimits(
                maximumInputBytes: zip.count - 1,
                maximumExpandedBytes: 1_024 * 1_024,
                maximumCompressionRatio: 1_000
            )
            parserExpectImportError("input cap", operation: {
                _ = try GenomeParser.parse(
                    url: zipURL,
                    options: GenomeImportOptions(minimumAcceptedRecords: 1, limits: inputCapLimits)
                )
            }, matches: {
                if case .inputLimitExceeded = $0 { return true }
                return false
            })

            emitJSON([
                "vcf": [
                    "total": d.totalRecords,
                    "accepted": d.acceptedRecords,
                    "skipped": d.skippedRecords,
                    "duplicate": d.duplicateRecords,
                    "conflict": d.conflictRecords,
                    "malformed": d.malformedRecords,
                    "unsupported": d.unsupportedRecords,
                    "filtered": d.filteredRecords,
                    "noCall": d.noCallRecords,
                    "reconciles": d.reconciles,
                    "defaultSample": defaulted.receipt.selectedVCFSample?.selectedSample ?? "",
                    "explicitSample": beta.receipt.selectedVCFSample?.selectedSample ?? "",
                ],
                "archives": [
                    "gzip": parsedGzip.receipt.archive?.status.rawValue ?? "",
                    "zip": parsedZip.receipt.archive?.status.rawValue ?? "",
                    "signatureDetection": true,
                    "inMemoryGzip": memoryGzip.calls.count == 2,
                    "inMemoryZip": memoryZip.calls.count == 2,
                    "singleMember": parsedZip.receipt.archive?.memberName ?? "",
                ],
                "rejections": [
                    "hostile": true,
                    "multiEntry": true,
                    "oversize": true,
                    "corruptGzip": true,
                    "corruptZip": true,
                    "concatenated": true,
                ],
            ])
        } catch {
            fail("parser checks failed: \(error.localizedDescription)")
        }
    }

    static func parserRequire(_ condition: @autoclosure () -> Bool, _ message: String) {
        if !condition() { fail(message) }
    }

    static func parserExpectImportError(
        _ label: String,
        operation: () throws -> Void,
        matches: (GenomeImportError) -> Bool
    ) {
        do {
            try operation()
            fail("\(label) was accepted")
        } catch let error as GenomeImportError {
            parserRequire(matches(error), "\(label) returned the wrong error: \(error)")
        } catch {
            fail("\(label) returned a non-import error: \(error)")
        }
    }

    struct TestZipEntry {
        let name: String
        let data: Data
    }

    static func makeDeflatedZip(_ entry: TestZipEntry) throws -> Data {
        let name = Data(entry.name.utf8)
        let compressed = try makeRawDeflate(entry.data)
        let checksum = parserCRC32(entry.data)
        var archive = Data()

        appendLE32(0x04034b50, to: &archive)
        appendLE16(20, to: &archive)
        appendLE16(0x0800, to: &archive)
        appendLE16(8, to: &archive)
        appendLE16(0, to: &archive)
        appendLE16(0, to: &archive)
        appendLE32(checksum, to: &archive)
        appendLE32(UInt32(compressed.count), to: &archive)
        appendLE32(UInt32(entry.data.count), to: &archive)
        appendLE16(UInt16(name.count), to: &archive)
        appendLE16(0, to: &archive)
        archive.append(name)
        archive.append(compressed)

        let centralOffset = UInt32(archive.count)
        appendLE32(0x02014b50, to: &archive)
        appendLE16(0x0314, to: &archive)
        appendLE16(20, to: &archive)
        appendLE16(0x0800, to: &archive)
        appendLE16(8, to: &archive)
        appendLE16(0, to: &archive)
        appendLE16(0, to: &archive)
        appendLE32(checksum, to: &archive)
        appendLE32(UInt32(compressed.count), to: &archive)
        appendLE32(UInt32(entry.data.count), to: &archive)
        appendLE16(UInt16(name.count), to: &archive)
        appendLE16(0, to: &archive)
        appendLE16(0, to: &archive)
        appendLE16(0, to: &archive)
        appendLE16(0, to: &archive)
        appendLE32(UInt32(0x81a4) << 16, to: &archive)
        appendLE32(0, to: &archive)
        archive.append(name)

        let centralSize = UInt32(archive.count) - centralOffset
        appendLE32(0x06054b50, to: &archive)
        appendLE16(0, to: &archive)
        appendLE16(0, to: &archive)
        appendLE16(1, to: &archive)
        appendLE16(1, to: &archive)
        appendLE32(centralSize, to: &archive)
        appendLE32(centralOffset, to: &archive)
        appendLE16(0, to: &archive)
        return archive
    }

    static func makeStoredZip(_ entries: [TestZipEntry], checksumXor: UInt32 = 0) -> Data {
        struct PreparedEntry {
            let name: Data
            let data: Data
            let checksum: UInt32
            let localOffset: UInt32
        }

        var archive = Data()
        var prepared: [PreparedEntry] = []
        for entry in entries {
            let name = Data(entry.name.utf8)
            let checksum = parserCRC32(entry.data) ^ checksumXor
            let offset = UInt32(archive.count)
            appendLE32(0x04034b50, to: &archive)
            appendLE16(20, to: &archive)
            appendLE16(0x0800, to: &archive)
            appendLE16(0, to: &archive)
            appendLE16(0, to: &archive)
            appendLE16(0, to: &archive)
            appendLE32(checksum, to: &archive)
            appendLE32(UInt32(entry.data.count), to: &archive)
            appendLE32(UInt32(entry.data.count), to: &archive)
            appendLE16(UInt16(name.count), to: &archive)
            appendLE16(0, to: &archive)
            archive.append(name)
            archive.append(entry.data)
            prepared.append(PreparedEntry(name: name, data: entry.data, checksum: checksum, localOffset: offset))
        }

        let centralOffset = UInt32(archive.count)
        for entry in prepared {
            appendLE32(0x02014b50, to: &archive)
            appendLE16(0x0314, to: &archive)
            appendLE16(20, to: &archive)
            appendLE16(0x0800, to: &archive)
            appendLE16(0, to: &archive)
            appendLE16(0, to: &archive)
            appendLE16(0, to: &archive)
            appendLE32(entry.checksum, to: &archive)
            appendLE32(UInt32(entry.data.count), to: &archive)
            appendLE32(UInt32(entry.data.count), to: &archive)
            appendLE16(UInt16(entry.name.count), to: &archive)
            appendLE16(0, to: &archive)
            appendLE16(0, to: &archive)
            appendLE16(0, to: &archive)
            appendLE16(0, to: &archive)
            appendLE32(UInt32(0x81a4) << 16, to: &archive)
            appendLE32(entry.localOffset, to: &archive)
            archive.append(entry.name)
        }
        let centralSize = UInt32(archive.count) - centralOffset
        appendLE32(0x06054b50, to: &archive)
        appendLE16(0, to: &archive)
        appendLE16(0, to: &archive)
        appendLE16(UInt16(entries.count), to: &archive)
        appendLE16(UInt16(entries.count), to: &archive)
        appendLE32(centralSize, to: &archive)
        appendLE32(centralOffset, to: &archive)
        appendLE16(0, to: &archive)
        return archive
    }

    static func makeGzip(_ input: Data) throws -> Data {
        try makeDeflateStream(input, windowBits: Int32(MAX_WBITS + 16))
    }

    static func makeRawDeflate(_ input: Data) throws -> Data {
        try makeDeflateStream(input, windowBits: -Int32(MAX_WBITS))
    }

    static func makeDeflateStream(_ input: Data, windowBits: Int32) throws -> Data {
        var stream = z_stream()
        let status = deflateInit2_(
            &stream,
            Z_DEFAULT_COMPRESSION,
            Z_DEFLATED,
            windowBits,
            8,
            Z_DEFAULT_STRATEGY,
            ZLIB_VERSION,
            Int32(MemoryLayout<z_stream>.size)
        )
        guard status == Z_OK else { throw GenomeImportError.corruptArchive("test deflate init failed") }
        defer { deflateEnd(&stream) }
        var output = Data()
        try input.withUnsafeBytes { rawInput in
            stream.next_in = UnsafeMutablePointer(mutating: rawInput.bindMemory(to: Bytef.self).baseAddress)
            stream.avail_in = uInt(input.count)
            let chunkSize = 4_096
            var chunk = [UInt8](repeating: 0, count: chunkSize)
            while true {
                let result = chunk.withUnsafeMutableBytes { rawOutput -> Int32 in
                    stream.next_out = rawOutput.bindMemory(to: Bytef.self).baseAddress
                    stream.avail_out = uInt(chunkSize)
                    return zlib.deflate(&stream, Z_FINISH)
                }
                let produced = chunkSize - Int(stream.avail_out)
                output.append(contentsOf: chunk.prefix(produced))
                if result == Z_STREAM_END { break }
                guard result == Z_OK else {
                    throw GenomeImportError.corruptArchive("test deflate status \(result)")
                }
            }
        }
        return output
    }

    static func parserCRC32(_ data: Data) -> UInt32 {
        data.withUnsafeBytes { raw in
            UInt32(crc32(0, raw.bindMemory(to: Bytef.self).baseAddress, uInt(data.count)))
        }
    }

    static func appendLE16(_ value: UInt16, to data: inout Data) {
        data.append(UInt8(value & 0xff))
        data.append(UInt8((value >> 8) & 0xff))
    }

    static func appendLE32(_ value: UInt32, to data: inout Data) {
        data.append(UInt8(value & 0xff))
        data.append(UInt8((value >> 8) & 0xff))
        data.append(UInt8((value >> 16) & 0xff))
        data.append(UInt8((value >> 24) & 0xff))
    }
}
