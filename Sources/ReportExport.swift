import Foundation

/// Private research report generator. UI-free by contract (PDF rendering lives
/// in DNAEngine.swift where WebKit is allowed).
///
/// Structure: per-domain sections driven by AnalysisEngine.hits(in:matching:),
/// then PGx, panels, compounds, ancestry; Appendix A = deduped citations from
/// the catalog's honesty schema; Appendix B = the HonestyEngine limits section,
/// emitted UNCONDITIONALLY — no toggle exists on purpose.
enum ReportExport {
    enum Format { case markdown, html }

    static let domainSections: [NavItem] = [
        .methylation, .cardio, .sleep, .mind, .move, .metabolism,
        .vitamins, .immunity, .histamine, .longevity, .traits,
    ]

    // MARK: - Deduped citations

    static func dedupedCitations(_ report: AnalysisReport) -> [CitationDef] {
        var seen = Set<String>()
        var out: [CitationDef] = []
        func take(_ cits: [CitationDef]?) {
            for c in cits ?? [] {
                let key = c.pmid + "|" + c.note
                if seen.insert(key).inserted { out.append(c) }
            }
        }
        for hit in report.hits { take(hit.citations) }
        for def in KnowledgeBase.shared.compounds ?? [] { take(def.citations) }
        return out.sorted { $0.pmid == $1.pmid ? $0.note < $1.note : $0.pmid < $1.pmid }
    }

    // MARK: - Full report

    static func fullReport(_ report: AnalysisReport, format: Format) -> String {
        let md = fullReportMarkdown(report)
        switch format {
        case .markdown: return md
        case .html: return htmlWrap(markdown: md, title: "DNA Engine Report — \(report.genome.fileName)")
        }
    }

    static func fullReportMarkdown(_ report: AnalysisReport) -> String {
        var md: [String] = []
        let honesty = HonestyEngine.build(report: report, qc: report.qc)

        md.append("# DNA Engine 3.0 — Private Genomics Research Report")
        md.append("")
        md.append("File: `\(report.genome.fileName)` · Platform: `\(report.genome.vendor)` · Build detected: `\(report.qc.buildCall)`")
        md.append("Total rows: **\(report.genome.snpCount.formatted())** · Called: **\(report.genome.calledCount.formatted())** · No-calls: **\(report.genome.noCallCount.formatted())** · Inferred sex: **\(report.genome.inferredSex)**")
        md.append("Catalog: **\(report.catalogCoverage.matched)** matched · **\(report.catalogCoverage.noCall)** no-call · **\(report.catalogCoverage.missing)** not on this chip · **\(report.catalogCoverage.strandAmbiguous)** strand-unresolved — every domain section below reports these buckets separately.")
        md.append("")
        md.append("> **Educational, never diagnostic.** Computed 100% offline on this Mac from peer-reviewed literature. Not medical advice, not a diagnosis, never a reason to change any medication. Pharmacogenomic notes are conversation material for a physician or pharmacist.")
        md.append("")

        // --- Per-domain sections ---
        for nav in domainSections {
            let hits = AnalysisEngine.hits(in: report, matching: nav)
            guard !hits.isEmpty else { continue }
            let matched = hits.filter { $0.coverage == .matched }
            let noCallCount = hits.filter { $0.coverage == .noCall }.count
            let missingCount = hits.filter { $0.coverage == .missing }.count
            let strandAmbiguousCount = hits.filter { $0.coverage == .strandAmbiguous }.count

            md.append("## \(nav.title)")
            md.append("")
            md.append("_\(matched.count)/\(hits.count) markers assessed · \(noCallCount) no-call · \(missingCount) not on this chip · \(strandAmbiguousCount) strand-unresolved._")
            md.append("")
            md.append("Observed genotypes are coverage receipts only. No single-marker genotype-to-outcome label or quantitative biological effect is produced.")
            md.append("")
            for hit in matched.sorted(by: { $0.rsid < $1.rsid }) {
                let cites = (hit.citations ?? []).map { "[\($0.pmid)]" }.joined(separator: " ")
                md.append("### \(hit.gene) — \(hit.title)")
                md.append("- Locus: `\(hit.rsid)` · Raw call: `\(hit.observed)` · \(hit.evidence.label)\(hit.tier.map { " · \($0)" } ?? "")\(hit.transferability.map { " · \($0)" } ?? "")")
                md.append("- \(MarkerMatcher.researchSummary)")
                if !cites.isEmpty { md.append("- References: \(cites)") }
                md.append("")
            }
            md.append("")
        }

        // --- PGx research observations ---
        md.append("## PGx Research Observations")
        md.append("")
        md.append("Observed consumer-array loci and published source pairs only. This unphased, CNV-limited file does not establish a star allele, diplotype, phenotype, medication response, or clinical action.")
        md.append("")
        for observation in report.pharmacogenomics.geneObservations {
            md.append("### \(observation.gene) — \(observation.observedCount)/\(observation.loci.count) defining loci observed")
            for locus in observation.loci {
                md.append("- `\(locus.rsid)` \(locus.alleleName) · expected `\(locus.expectedAlleles)` · observed `\(locus.observedGenotype)` · **\(locus.status.rawValue)**")
            }
            if !observation.drugReferences.isEmpty {
                let sources = observation.drugReferences
                    .map { "\($0.name) (\($0.brands)) — \($0.sourceLevel)" }
                    .joined(separator: "; ")
                md.append("- Published source pairs (context only): \(sources)")
            }
            md.append("- _\(observation.chipLimitations)_")
            if !observation.undetectable.isEmpty {
                md.append("- Not represented: \(observation.undetectable.joined(separator: "; ")).")
            }
            md.append("")
        }

        // --- Polygenic panels ---
        md.append("## Polygenic Tendency Panels")
        md.append("")
        md.append("Percentiles are computed against per-population reference allele frequencies under Hardy-Weinberg — tendency estimates, not clinical PRS (those use thousands to millions of variants).")
        md.append("")
        for s in report.calibratedScores {
            if s.insufficientCoverage {
                md.append("### \(s.title) — Insufficient chip coverage")
                md.append("- Only \(s.usedSNPs)/\(s.totalSNPs) panel SNPs typed; no percentile shown.")
            } else {
                md.append("### \(s.title) — \(s.percentile)th percentile (\(s.riskCategory))")
                md.append("- Reference population: **\(s.referencePopulation)**\(s.referencePopulationIsFallback ? " (fallback — no calibration for your estimated majority ancestry)" : "") · \(s.usedSNPs)/\(s.totalSNPs) SNPs typed")
                let spread = s.percentileByPopulation.sorted { $0.key < $1.key }
                    .map { "\($0.key) \($0.value)" }.joined(separator: " · ")
                if !spread.isEmpty { md.append("- Percentile by reference population: \(spread)") }
                md.append("- Research context only; not a personalized intervention or clinical risk score.")
            }
            md.append("")
        }

        // --- Multi-locus research rule coverage ---
        md.append("## Multi-Locus Research Rule Coverage")
        md.append("")
        for c in report.compounds {
            md.append("### \(c.title)")
            md.append("This catalog rule references \(c.rsids.count) loci. Its outcome label is withheld from the general export; phase, strand orientation, assay coverage, ancestry transferability, and non-genetic context can change interpretation.")
            md.append("Referenced loci: `\(c.rsids.joined(separator: ", "))`")
            md.append("")
        }

        // --- Ancestry & ROH ---
        md.append("## Ancestry & Autozygosity")
        md.append("")
        if let adm = report.admixture {
            md.append("_\(adm.disclosure)_")
            md.append("")
            if adm.insufficient {
                md.append("Too few reference-panel markers are usable on this file — admixture percentages are withheld rather than guessed.")
                md.append("")
            } else {
                md.append("### Continental composition (reference-panel admixture)")
                md.append("")
                for c in adm.continental where c.share >= 0.005 || c.ciHigh >= 0.02 {
                    md.append("- **\(c.title)**: \(c.percentText) (\(c.ciText))")
                }
                md.append("")
                md.append("### Within-European breakdown")
                md.append("")
                if adm.withinEuropeanApplicable {
                    for c in adm.withinEuropean {
                        md.append("- **\(c.title)**: \(c.percentText) of the whole genome (\(c.ciText))")
                    }
                }
                md.append("_\(adm.withinEuropeanNote)_")
                md.append("")
                if let asj = adm.asj {
                    md.append("### Ashkenazi founder signal: \(asj.bandLabel)")
                    md.append("")
                    if asj.band != "not-assessed" && asj.band != "insufficient-markers" {
                        md.append("- Estimated Ashkenazi-like component: \(String(format: "%.1f%%", asj.sharePercent)) (95% CI \(String(format: "%.1f–%.1f%%", asj.ciLowPercent, asj.ciHighPercent))) from the joint within-European fit")
                        md.append("- Founder-subset likelihood ratio (vs NW-European reference): \(String(format: "%.1f", asj.logLikelihoodRatio)) over \(asj.markersUsed) of \(asj.markersTotal) informative markers")
                    } else {
                        md.append("- \(asj.markersUsed) of \(asj.markersTotal) founder-signal markers usable on this file.")
                    }
                    md.append("- _\(asj.framing)_")
                    md.append("")
                }
            }
            md.append("These estimates are an ancestry signal against specific reference panels — not a passport, nationality, ethnicity, or identity label. Sub-continental resolution is ±10–15 percentage points at best.")
            md.append("")
            md.append("Reference sources:")
            for f in adm.sourceFootnotes {
                md.append("- \(f)")
            }
            md.append("")
        } else {
            md.append("_Reference panel unavailable in this build — only the legacy 36-AIM continental sketch below. These estimates are an ancestry signal, not a passport label._")
            md.append("")
        }
        md.append("### Legacy continental sketch (36 AIMs, 2.0 estimator)")
        md.append("")
        md.append(report.ancestry.confidence)
        for (pop, share) in report.ancestry.shares.sorted(by: { $0.value > $1.value }) where share >= 0.015 {
            md.append("- **\(AncestryEstimator.populationTitles[pop] ?? pop)**: \(Int((share * 100).rounded()))%")
        }
        md.append("")
        md.append("F_ROH = \(String(format: "%.4f", report.roh.fROH)) over \(String(format: "%.0f", report.roh.autosomalCoveredMb)) Mb observed span · longest run \(String(format: "%.1f", report.roh.longestMb)) Mb")
        md.append(report.roh.interpretation)
        md.append("")

        // --- Appendix A: citations ---
        let citations = dedupedCitations(report)
        md.append("## Appendix A — Citations (\(citations.count))")
        md.append("")
        md.append("Numeric IDs are PMIDs (search at pubmed.gov on your own device); named tags are curated registries (PharmGKB, GWAS Catalog, ClinVar, CPIC). This report was generated with zero network access.")
        md.append("")
        for c in citations {
            md.append("- `\(c.pmid)` — \(c.note)")
        }
        md.append("")

        // --- Appendix B: limits (unconditional) ---
        md.append("## Appendix B — What This Report Is Not")
        md.append("")
        md.append("This appendix is part of every export, always. It leads with what the report cannot do, because that is the honest frame for everything above.")
        md.append("")
        for item in honesty.computed {
            md.append("### \(item.title)")
            md.append(item.explanation)
            md.append("_\(item.pmidNote)_")
            md.append("")
        }
        for item in honesty.staticEntries {
            md.append("### \(item.title) (\(item.category))")
            md.append(item.explanation)
            md.append("_\(item.pmidNote)_")
            md.append("")
        }

        return md.joined(separator: "\n")
    }

    // MARK: - PGx research observation sheet (monochrome style)

    static func pgxClinicalBriefHTML(_ report: AnalysisReport) -> String {
        var body: [String] = []
        body.append("<h1>PGx Research Observation Sheet</h1>")
        body.append("<p><strong>File:</strong> \(escape(report.genome.fileName)) · <strong>Platform:</strong> \(escape(report.genome.vendor)) · <strong>Build detected:</strong> \(escape(report.qc.buildCall))</p>")
        body.append("<p class='banner'><strong>Consumer-array research observations only. No star allele, diplotype, phenotype, medication response, or clinical action is inferred.</strong></p>")

        for observation in report.pharmacogenomics.geneObservations {
            body.append("<h2>\(escape(observation.gene))</h2>")
            body.append("<table><thead><tr><th>Defining locus</th><th>Expected alleles</th><th>Observed</th><th>Status</th></tr></thead><tbody>")
            for locus in observation.loci {
                body.append("<tr><td>\(escape(locus.rsid)) · \(escape(locus.alleleName))</td><td>\(escape(locus.expectedAlleles))</td><td>\(escape(locus.observedGenotype))</td><td><strong>\(escape(locus.status.rawValue))</strong></td></tr>")
            }
            body.append("</tbody></table>")
            body.append("<p><strong>Coverage:</strong> \(observation.observedCount) of \(observation.loci.count) defining array loci strand-resolved.</p>")
            if !observation.drugReferences.isEmpty {
                let refs = observation.drugReferences.map {
                    "\(escape($0.name)) (\(escape($0.brands))) — \(escape($0.sourceLevel))"
                }.joined(separator: "<br>")
                body.append("<p><strong>Published source pairs (context only):</strong><br>\(refs)</p>")
            }
            body.append("<p class='limits'><strong>Assay limits:</strong> \(escape(observation.chipLimitations))<br><strong>Not represented:</strong> \(escape(observation.undetectable.joined(separator: "; "))).</p>")
            body.append("<p class='discuss'><em>Neutral question:</em> If this gene is relevant to my medication history, would validated testing add useful information?</p>")
        }

        body.append("<p class='footer'>Generated 100% offline by DNA Engine. Research context only; no medication action is inferred.</p>")

        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
        <meta charset="UTF-8">
        <meta http-equiv="Content-Security-Policy" content="default-src 'none'">
        <title>PGx Research Observation Sheet</title>
        <style>
            body { font-family: "Helvetica Neue", Helvetica, Arial, sans-serif; color: #111; max-width: 800px; margin: 0 auto; padding: 32px; line-height: 1.45; }
            h1 { font-size: 20px; border-bottom: 2px solid #111; padding-bottom: 6px; }
            h2 { font-size: 15px; margin-top: 22px; border-bottom: 1px solid #999; page-break-after: avoid; }
            table { width: 100%; border-collapse: collapse; font-size: 12px; margin: 8px 0; }
            th, td { border: 1px solid #666; padding: 6px 8px; text-align: left; vertical-align: top; }
            p { font-size: 12px; }
            .banner { border: 2px solid #111; padding: 10px; font-size: 12px; }
            .limits { background: #f2f2f2; padding: 8px; }
            .discuss { border-left: 3px solid #111; padding-left: 10px; }
            .footer { margin-top: 24px; border-top: 1px solid #999; padding-top: 8px; color: #444; }
            @media print { body { padding: 0; } h2 { page-break-before: auto; } }
        </style>
        </head>
        <body>
        \(body.joined(separator: "\n"))
        </body>
        </html>
        """
    }

    // MARK: - Legacy entry points (kept for the export menu)

    static func markdown(_ report: AnalysisReport) -> String {
        fullReport(report, format: .markdown)
    }

    static func htmlReport(_ report: AnalysisReport) -> String {
        fullReport(report, format: .html)
    }

    static func rawJSON(_ report: AnalysisReport) -> String {
        var admixture: [String: Any] = [:]
        if let adm = report.admixture {
            admixture["disclosure"] = adm.disclosure
            admixture["insufficient"] = adm.insufficient
            admixture["markersUsed"] = adm.markersUsed
            admixture["markersTotal"] = adm.markersTotal
            admixture["continental"] = adm.continental.map {
                ["id": $0.id, "title": $0.title, "share": $0.share, "ciLow": $0.ciLow, "ciHigh": $0.ciHigh]
            }
            admixture["withinEuropean"] = adm.withinEuropean.map {
                ["id": $0.id, "title": $0.title, "share": $0.share, "ciLow": $0.ciLow, "ciHigh": $0.ciHigh]
            }
            admixture["withinEuropeanNote"] = adm.withinEuropeanNote
            if let asj = adm.asj {
                admixture["asjFounderSignal"] = [
                    "band": asj.band,
                    "sharePercent": asj.sharePercent,
                    "ciLowPercent": asj.ciLowPercent,
                    "ciHighPercent": asj.ciHighPercent,
                    "markersUsed": asj.markersUsed,
                    "markersTotal": asj.markersTotal,
                    "framing": asj.framing,
                ]
            }
            admixture["sourceFootnotes"] = adm.sourceFootnotes
        } else {
            admixture["panelMissing"] = true
        }
        let payload: [String: Any] = [
            "genome": [
                "fileName": report.genome.fileName,
                "vendor": report.genome.vendor,
                "calledCount": report.genome.calledCount,
                "inferredSex": report.genome.inferredSex,
                "autosomalHet": report.genome.autosomalHet,
            ],
            "catalogMatched": report.catalogCoverage.matched,
            "catalogNoCall": report.catalogCoverage.noCall,
            "catalogMissing": report.catalogCoverage.missing,
            "catalogStrandAmbiguous": report.catalogCoverage.strandAmbiguous,
            "multiLocusResearchRules": report.compounds.map {
                ["id": $0.id, "title": $0.title, "referencedLoci": $0.rsids]
            },
            "pgxResearchObservations": report.pharmacogenomics.geneObservations.map { observation in
                [
                    "gene": observation.gene,
                    "observedCount": observation.observedCount,
                    "totalDefiningLoci": observation.loci.count,
                    "loci": observation.loci.map {
                        [
                            "rsid": $0.rsid,
                            "alleleName": $0.alleleName,
                            "expectedAlleles": $0.expectedAlleles,
                            "observedGenotype": $0.observedGenotype,
                            "status": $0.status.rawValue,
                        ]
                    },
                    "limitations": observation.chipLimitations,
                    "notRepresented": observation.undetectable,
                ] as [String: Any]
            },
            "ancestryShares": report.ancestry.shares,
            "admixture": admixture,
            "fROH": report.roh.fROH,
            "scores": report.calibratedScores.map {
                [
                    "id": $0.id,
                    "title": $0.title,
                    "percentile": $0.insufficientCoverage ? NSNull() : $0.percentile as Any,
                    "referencePopulation": $0.referencePopulation,
                    "insufficientCoverage": $0.insufficientCoverage,
                ]
            },
        ]
        if let data = try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys]) {
            return String(data: data, encoding: .utf8) ?? "{}"
        }
        return "{}"
    }

    // MARK: - Markdown → printable HTML (self-contained, no external assets)

    static func htmlWrap(markdown: String, title: String) -> String {
        var html: [String] = []
        var inList = false
        for rawLine in markdown.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = String(rawLine)
            func closeList() { if inList { html.append("</ul>"); inList = false } }
            if line.hasPrefix("### ") {
                closeList(); html.append("<h3>\(inline(String(line.dropFirst(4))))</h3>")
            } else if line.hasPrefix("## ") {
                closeList(); html.append("<h2 class='section'>\(inline(String(line.dropFirst(3))))</h2>")
            } else if line.hasPrefix("# ") {
                closeList(); html.append("<h1>\(inline(String(line.dropFirst(2))))</h1>")
            } else if line.hasPrefix("- ") {
                if !inList { html.append("<ul>"); inList = true }
                html.append("<li>\(inline(String(line.dropFirst(2))))</li>")
            } else if line.hasPrefix("> ") {
                closeList(); html.append("<blockquote>\(inline(String(line.dropFirst(2))))</blockquote>")
            } else if line.trimmingCharacters(in: .whitespaces).isEmpty {
                closeList()
            } else {
                closeList(); html.append("<p>\(inline(line))</p>")
            }
        }
        if inList { html.append("</ul>") }

        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
        <meta charset="UTF-8">
        <meta http-equiv="Content-Security-Policy" content="default-src 'none'">
        <title>\(escape(title))</title>
        <style>
            body { font-family: -apple-system, Helvetica, Arial, sans-serif; color: #111; background: #fff; max-width: 860px; margin: 0 auto; padding: 36px; line-height: 1.5; }
            h1 { font-size: 24px; border-bottom: 3px solid #111; padding-bottom: 8px; }
            h2 { font-size: 18px; margin-top: 28px; border-bottom: 1px solid #888; padding-bottom: 4px; }
            h3 { font-size: 14px; margin-bottom: 4px; }
            p, li, blockquote { font-size: 12.5px; }
            blockquote { border-left: 3px solid #111; margin: 10px 0; padding: 6px 12px; background: #f5f5f5; }
            code { font-family: ui-monospace, Menlo, monospace; background: #f0f0f0; padding: 0 3px; }
            em { color: #333; }
            @media print {
                body { padding: 0; background: #fff; }
                h2.section { page-break-before: always; }
                h1 + h2.section, h2.section:first-of-type { page-break-before: avoid; }
            }
        </style>
        </head>
        <body>
        \(html.joined(separator: "\n"))
        </body>
        </html>
        """
    }

    private static func inline(_ s: String) -> String {
        var out = escape(s)
        // **bold**
        while let r1 = out.range(of: "**"), let r2 = out.range(of: "**", range: r1.upperBound..<out.endIndex) {
            let content = String(out[r1.upperBound..<r2.lowerBound])
            out.replaceSubrange(r1.lowerBound..<r2.upperBound, with: "<strong>\(content)</strong>")
        }
        // `code`
        while let r1 = out.range(of: "`"), let r2 = out.range(of: "`", range: r1.upperBound..<out.endIndex) {
            let content = String(out[r1.upperBound..<r2.lowerBound])
            out.replaceSubrange(r1.lowerBound..<r2.upperBound, with: "<code>\(content)</code>")
        }
        // _italics_ (whole-line style used above)
        if out.hasPrefix("_") && out.hasSuffix("_") && out.count > 2 {
            out = "<em>" + String(out.dropFirst().dropLast()) + "</em>"
        }
        return out
    }

    private static func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

}
