import SwiftUI

struct OverviewView: View {
    @EnvironmentObject private var engine: DNAEngine
    var report: AnalysisReport { engine.report! }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                DisclaimerBanner()
                header
                stats
                
                if !report.pharmacogenomics.guidelines.isEmpty {
                    pgxResearchBanner
                }
                
                compoundsSection
                pathwayShortcuts
                polygenicHighlights
                priorityInsights
            }
            .padding(22)
        }
        .background(Theme.bgDeep)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(report.genome.fileName)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Theme.textHi)
                    Text("OFFLINE ANALYSIS")
                        .font(.system(size: 9, weight: .heavy, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .foregroundStyle(Theme.teal)
                        .background(Theme.teal.opacity(0.12), in: Capsule())
                }
                Text("\(report.genome.vendor) · \(report.genome.buildHint) · \(report.genome.inferredSex)")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textMed)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 8) {
                    Button { engine.selected = .qc } label: {
                        HStack(spacing: 4) {
                            Text("QC")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundStyle(Theme.textLow)
                            QCBadge(grade: report.qc.worstGrade)
                        }
                    }
                    .buttonStyle(.plain)
                    LimitsLink()
                }
                Text("CATALOG COVERAGE")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.textLow)
                Text("\(report.catalogCoverage.matched)/\(report.catalogCoverage.total) orientation-safe markers")
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.teal)
                Text("not analyzed: \(report.catalogCoverage.noCall) no-call · \(report.catalogCoverage.missing) not on chip · \(report.catalogCoverage.strandAmbiguous) strand-unresolved")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Theme.warning)
            }
        }
    }

    private var stats: some View {
        HStack(spacing: 12) {
            StatChip(label: "Variants Ingested", value: report.genome.snpCount.formatted(), sublabel: "\(report.genome.calledCount.formatted()) called", icon: "circle.hexagongrid.fill")
            StatChip(label: "Autosomal Heterozygosity", value: "\(Int(report.genome.autosomalHet * 100))%", sublabel: "Standard genomic baseline", icon: "waveform.path.ecg")
            StatChip(label: "PGx Research Cards", value: "\(report.pharmacogenomics.guidelines.count)", sublabel: "Array observations with limits", icon: "cross.case.fill")
            StatChip(label: "Ancestry AIMs", value: "\(report.ancestry.usedMarkers)", sublabel: "7-Pop Bayesian model", icon: "globe.americas.fill")
        }
    }

    private var pgxResearchBanner: some View {
        HStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundStyle(Theme.gold)
            VStack(alignment: .leading, spacing: 4) {
                Text("Pharmacogenomic research observations available")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.gold)
                Text("Review observed loci, missing coverage, phasing/CNV limits, and source guidelines. These cards are not clinical phenotype calls or medication advice.")
                    .font(.caption)
                    .foregroundStyle(Theme.textMed)
            }
            Spacer()
            Button("Review PGx Evidence") {
                engine.selected = .pharmacogenomics
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.gold.opacity(0.8))
        }
        .dnaCard()
    }

    private var compoundsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Multi-SNP Research Patterns")
                    .font(.headline)
                    .foregroundStyle(Theme.textHi)
                Spacer()
                Text("\(report.compounds.count) Catalog Rules")
                    .font(.caption.monospaced())
                    .foregroundStyle(Theme.textLow)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 12)], spacing: 12) {
                ForEach(report.compounds.prefix(8)) { c in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(c.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.textHi)
                            Spacer()
                            Text("\(c.rsids.count) loci")
                                .font(.caption.monospaced())
                                .foregroundStyle(Theme.textLow)
                        }
                        Text("Referenced loci: \(c.rsids.joined(separator: ", "))")
                            .font(.caption.monospaced())
                            .foregroundStyle(Theme.teal)
                        Text("Outcome label withheld. Unphased array calls, strand orientation, assay coverage, ancestry transferability, and non-genetic context limit this rule.")
                            .font(.callout)
                            .foregroundStyle(Theme.textMed)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .dnaCard()
                }
            }
        }
    }

    private var pathwayShortcuts: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Biochemical Pathway Observations")
                    .font(.headline)
                    .foregroundStyle(Theme.textHi)
                Spacer()
                Button("Open Pathways Engine") {
                    engine.selected = .pathways
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.teal)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 12)], spacing: 12) {
                ForEach(report.pathwayGraphs) { graph in
                    Button {
                        engine.selectedPathway = graph.pathway
                        engine.selected = .pathways
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: "arrow.triangle.branch")
                                    .foregroundStyle(Theme.teal)
                                Text(graph.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Theme.textHi)
                            }
                            Text(graph.subtitle)
                                .font(.caption2)
                                .foregroundStyle(Theme.textMed)
                                .lineLimit(2)
                            
                            HStack {
                                Text("\(graph.nodes.count) Research Nodes")
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundStyle(Theme.textLow)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundStyle(Theme.textLow)
                            }
                            .padding(.top, 4)
                        }
                        .dnaCard()
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var polygenicHighlights: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Calibrated Polygenic Tendency Panels")
                    .font(.headline)
                    .foregroundStyle(Theme.textHi)
                Spacer()
                Button("View All 15 Panels") {
                    engine.selected = .polygenic
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.teal)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 12)], spacing: 12) {
                ForEach(report.calibratedScores.prefix(4)) { score in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(score.title)
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text(score.insufficientCoverage ? "no %ile" : "\(score.percentile)th %ile")
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundStyle(score.insufficientCoverage ? Theme.warning : score.impact.color)
                        }

                        if !score.insufficientCoverage {
                            GaussianPercentileCurve(percentile: score.percentile, zScore: score.zScore, riskColor: score.impact.color)
                        }

                        Text(score.riskCategory)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(score.impact.color)
                        Text("Research tendency only — not a personalized intervention or clinical risk score.")
                            .font(.caption)
                            .foregroundStyle(Theme.textMed)
                            .lineLimit(3)
                    }
                    .dnaCard()
                }
            }
        }
    }

    private var priorityInsights: some View {
        let headlines = HeadlineBuilder.build(report: report)
        return VStack(alignment: .leading, spacing: 12) {
            Text("Findings, Tiered Honestly")
                .font(.headline)
                .foregroundStyle(Theme.textHi)

            HeadlineTierGroup(
                title: "Discuss with a clinician",
                subtitle: "Bring these to a professional — they are conversation topics, not verdicts.",
                color: Theme.danger,
                findings: headlines.filter { $0.tier == 1 },
                expandedByDefault: true
            )
            HeadlineTierGroup(
                title: "Research and lifestyle topics",
                subtitle: "Neutral observations to explore alongside established health guidance.",
                color: Theme.gold,
                findings: headlines.filter { $0.tier == 2 },
                expandedByDefault: false
            )
            HeadlineTierGroup(
                title: "Good news & typical",
                subtitle: "Favorable findings, and the honest headline that most results are simply normal.",
                color: Theme.success,
                findings: headlines.filter { $0.tier == 3 },
                expandedByDefault: false
            )
        }
    }
}

struct HeadlineTierGroup: View {
    var title: String
    var subtitle: String
    var color: Color
    var findings: [HeadlineFinding]
    var expandedByDefault: Bool

    @EnvironmentObject private var engine: DNAEngine
    @State private var expanded: Bool = false

    var body: some View {
        DisclosureGroup(isExpanded: $expanded) {
            VStack(alignment: .leading, spacing: 10) {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Theme.textMed)
                ForEach(findings) { f in
                    Button {
                        route(f)
                    } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text(f.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Theme.textHi)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundStyle(Theme.textLow)
                            }
                            Text(f.body)
                                .font(.callout)
                                .foregroundStyle(Theme.textMed)
                                .fixedSize(horizontal: false, vertical: true)
                                .multilineTextAlignment(.leading)
                            Text(f.evidence)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(Theme.teal)
                            Text("Caveat: \(f.caveat)")
                                .font(.caption2)
                                .foregroundStyle(Theme.textLow)
                                .fixedSize(horizontal: false, vertical: true)
                                .multilineTextAlignment(.leading)
                        }
                        .dnaCard(padding: 12)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 8)
        } label: {
            HStack(spacing: 10) {
                Circle().fill(color).frame(width: 9, height: 9)
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.textHi)
                Text("\(findings.count)")
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .foregroundStyle(color)
                    .background(color.opacity(0.14), in: Capsule())
            }
        }
        .padding(12)
        .background(Theme.bgCard, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.stroke, lineWidth: 1))
        .onAppear { expanded = expandedByDefault }
    }

    private func route(_ f: HeadlineFinding) {
        if f.source == .marker, let hit = engine.report?.hits.first(where: { $0.rsid == f.rsids.first }) {
            engine.selectedHit = hit
        }
        if let nav = NavItem(rawValue: f.navTarget) {
            engine.selected = nav
        }
    }
}
