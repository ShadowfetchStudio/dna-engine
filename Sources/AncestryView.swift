import SwiftUI

/// Fine-scale ancestry (2.1): continental donut → expandable within-European
/// breakdown with confidence-interval bars → Ashkenazi founder-signal card →
/// lineage/haplogroup honesty section (2.0's estimator retained) → the
/// what-this-can-and-cannot-say panel → per-population source footnotes → ROH.
struct AncestryView: View {
    @EnvironmentObject private var engine: DNAEngine
    var report: AnalysisReport { engine.report! }

    @State private var withinEuropeExpanded = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                DisclaimerBanner()

                if let adm = report.admixture {
                    if adm.insufficient {
                        insufficientCard(adm)
                    } else {
                        continentalCard(adm)
                        withinEuropeCard(adm)
                        if let asj = adm.asj {
                            asjCard(asj)
                        }
                    }
                    honestyCard(adm)
                } else {
                    panelMissingCard
                }

                lineageCard
                legacySketchCard

                if let adm = report.admixture {
                    footnotesCard(adm)
                }

                // Runs of Homozygosity + F_ROH (feature 7)
                ROHSectionView(roh: report.roh)
            }
            .padding(22)
        }
        .background(Theme.bgDeep)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Ancestry — Fine-Scale Admixture")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Theme.textHi)
                Spacer()
                Text(report.admixture == nil ? "LEGACY SKETCH" : "SUPERVISED ADMIXTURE")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.teal)
            }
            Text(report.admixture?.disclosure ?? report.ancestry.confidence)
                .font(.subheadline)
                .foregroundStyle(Theme.textMed)
        }
    }

    // MARK: - Continental donut

    private static let continentalColors: [String: Color] = [
        "AFR": Theme.gold, "EUR": Theme.blue, "EAS": Theme.magenta,
        "SAS": Theme.teal, "AMR": Theme.success, "MID": Theme.warning,
    ]
    private static let eurColors: [String: Color] = [
        "NWE": Theme.blue, "TSI": Theme.warning, "IBS": Theme.gold,
        "FIN": Theme.teal, "ASJ": Theme.purple,
    ]

    private func continentalCard(_ adm: AdmixtureReport) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Continental Composition")
                .font(.headline)
                .foregroundStyle(Theme.textHi)

            HStack(alignment: .center, spacing: 24) {
                DonutChart(segments: adm.continental.map {
                    (Self.continentalColors[$0.id] ?? Theme.textMed, $0.share)
                })
                .frame(width: 168, height: 168)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(adm.continental) { c in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Self.continentalColors[c.id] ?? Theme.textMed)
                                .frame(width: 9, height: 9)
                            Text(c.title)
                                .font(.callout)
                                .foregroundStyle(Theme.textHi)
                            Spacer()
                            Text(c.percentText)
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundStyle(Theme.textHi)
                            Text(c.ciText)
                                .font(.caption.monospaced())
                                .foregroundStyle(Theme.textLow)
                        }
                    }
                }
            }
            Text("Maximum-likelihood mixture of your genotypes against reference allele frequencies; intervals are seeded-bootstrap 95% ranges. Continental estimates are the robust tier of this model.")
                .font(.caption)
                .foregroundStyle(Theme.textMed)
        }
        .dnaCard()
    }

    private func insufficientCard(_ adm: AdmixtureReport) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Admixture Withheld — Chip Intersection Too Small")
                .font(.headline)
                .foregroundStyle(Theme.warning)
            Text(adm.disclosure)
                .font(.callout)
                .foregroundStyle(Theme.textMed)
            Text("Percentages are only shown when enough reference-panel markers are typed in the file; below the floor they would be guesses dressed as numbers.")
                .font(.caption)
                .foregroundStyle(Theme.textLow)
        }
        .dnaCard()
    }

    private var panelMissingCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Reference Panel Unavailable")
                .font(.headline)
                .foregroundStyle(Theme.warning)
            Text("This build carries no bundled ancestry reference panel, so only the legacy 36-AIM continental sketch below is shown. Rebuild with build.sh to package the panel.")
                .font(.callout)
                .foregroundStyle(Theme.textMed)
        }
        .dnaCard()
    }

    // MARK: - Within-Europe breakdown

    private func withinEuropeCard(_ adm: AdmixtureReport) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            DisclosureGroup(isExpanded: $withinEuropeExpanded) {
                VStack(alignment: .leading, spacing: 14) {
                    if adm.withinEuropeanApplicable {
                        let scale = max(adm.withinEuropean.map(\.ciHigh).max() ?? 0.05, 0.05)
                        ForEach(adm.withinEuropean) { c in
                            CIBarRow(
                                title: c.title,
                                share: c.share,
                                ciLow: c.ciLow,
                                ciHigh: c.ciHigh,
                                scale: scale,
                                color: Self.eurColors[c.id] ?? Theme.textMed
                            )
                        }
                        Text("Markers used for this tier: \(adm.tier2MarkersUsed) of \(adm.tier2MarkersTotal) within-European informative sites.")
                            .font(.caption.monospaced())
                            .foregroundStyle(Theme.textLow)
                    }
                    Text(adm.withinEuropeanNote)
                        .font(.caption)
                        .foregroundStyle(Theme.textMed)
                }
                .padding(.top, 10)
            } label: {
                HStack {
                    Text("Within-European Breakdown")
                        .font(.headline)
                        .foregroundStyle(Theme.textHi)
                    Spacer()
                    Text(adm.withinEuropeanApplicable ? "±10–15 pp RESOLUTION" : "NOT COMPUTED")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.warning)
                }
            }
            .tint(Theme.textMed)
        }
        .dnaCard()
    }

    // MARK: - ASJ founder signal

    private func asjBandColor(_ band: String) -> Color {
        switch band {
        case "none-detected": return Theme.textMed
        case "possible": return Theme.blue
        case "likely": return Theme.teal
        case "strong": return Theme.purple
        default: return Theme.textLow
        }
    }

    private func asjCard(_ asj: ASJSignal) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Ashkenazi Founder Signal")
                    .font(.headline)
                    .foregroundStyle(Theme.textHi)
                Spacer()
                Text(asj.bandLabel.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(asjBandColor(asj.band))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(asjBandColor(asj.band).opacity(0.14)))
            }

            if asj.band != "not-assessed" && asj.band != "insufficient-markers" {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(String(format: "%.1f%%", asj.sharePercent))
                        .font(.system(size: 26, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.textHi)
                    Text(String(format: "95%% CI %.1f–%.1f%%", asj.ciLowPercent, asj.ciHighPercent))
                        .font(.caption.monospaced())
                        .foregroundStyle(Theme.textLow)
                }
                Text("Estimated Ashkenazi-like share of the whole genome, from the joint within-European fit — the Ashkenazi reference is fitted together with the Southern-European references so the two cannot masquerade as each other.")
                    .font(.caption)
                    .foregroundStyle(Theme.textMed)
                Text(String(format: "Founder-subset likelihood ratio vs NW-European reference: %.1f over %d of %d informative markers (positive favors ASJ-like).", asj.logLikelihoodRatio, asj.markersUsed, asj.markersTotal))
                    .font(.caption.monospaced())
                    .foregroundStyle(Theme.textLow)
            } else {
                Text("\(asj.markersUsed) of \(asj.markersTotal) founder-signal markers usable on this file.")
                    .font(.caption.monospaced())
                    .foregroundStyle(Theme.textLow)
            }

            Text(asj.framing)
                .font(.caption)
                .foregroundStyle(Theme.warning)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 8).fill(Theme.bgInset))
        }
        .dnaCard()
    }

    // MARK: - Lineage / haplogroups (honest: 2.1 calls none)

    private var lineageCard: some View {
        let mtCount = report.genome.chromosomeCounts["MT", default: 0]
        let yCount = report.genome.chromosomeCounts["Y", default: 0]
        return VStack(alignment: .leading, spacing: 8) {
            Text("Maternal & Paternal Lineages (Haplogroups)")
                .font(.headline)
                .foregroundStyle(Theme.textHi)
            Text("This file carries \(mtCount) mitochondrial and \(yCount) Y-chromosome rows. DNA Engine does not call haplogroups: consumer arrays carry thin or absent MT/Y probes, and an honest haplogroup assignment needs dedicated phylogeny typing this offline module does not ship. The admixture percentages above are autosomal — they describe overall genome composition, not single maternal or paternal lines.")
                .font(.callout)
                .foregroundStyle(Theme.textMed)
        }
        .dnaCard()
    }

    // MARK: - Legacy 2.0 estimator (kept)

    private var legacySketchCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Continental Sketch — 2.0 Estimator (36 AIMs)")
                    .font(.headline)
                    .foregroundStyle(Theme.textHi)
                Spacer()
                Text("LEGACY MODEL · NOT REAL PCA")
                    .font(.caption.monospaced())
                    .foregroundStyle(Theme.warning)
            }

            PCAScatterPlotView(report: report.ancestryPCA)
            Text("Honesty note: your point is a weighted blend of fixed population centroids driven by the likelihood shares below — a visual aid, not a principal-component analysis of your genotypes. Real PCA requires individual-level reference genotype panels this offline app does not ship.")
                .font(.caption)
                .foregroundStyle(Theme.textMed)

            ForEach(sortedLegacyShares, id: \.key) { pop, share in
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(AncestryEstimator.populationTitles[pop] ?? pop)
                            .font(.subheadline)
                            .foregroundStyle(Theme.textHi)
                        Spacer()
                        Text(String(format: "%.1f%%", share * 100))
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundStyle(Theme.teal)
                    }
                    GeometryReader { geo in
                        Capsule().fill(Theme.bgInset)
                        Capsule()
                            .fill(Theme.tealDim)
                            .frame(width: max(4, geo.size.width * share))
                    }
                    .frame(height: 8)
                }
            }

            ForEach(report.ancestry.notes, id: \.self) { note in
                HStack(alignment: .top, spacing: 6) {
                    Text("•").foregroundStyle(Theme.teal)
                    Text(note).foregroundStyle(Theme.textMed).font(.caption)
                }
            }
            Text("Evaluated \(report.ancestry.usedMarkers) published Ancestry Informative Markers (AIMs); \(report.ancestry.missingMarkers) missing on this chip.")
                .foregroundStyle(Theme.textLow)
                .font(.caption.monospaced())
        }
        .dnaCard()
    }

    private var sortedLegacyShares: [(key: String, value: Double)] {
        report.ancestry.shares.sorted { $0.value > $1.value }.filter { $0.value >= 0.01 }
    }

    // MARK: - Honesty panel

    private func honestyCard(_ adm: AdmixtureReport) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What This Can and Cannot Say")
                .font(.headline)
                .foregroundStyle(Theme.textHi)

            bullet("Markers actually used: \(adm.markersUsed.formatted()) of \(adm.markersTotal.formatted()) panel markers — \(adm.palindromicDropped) palindromic (A/T, C/G) sites were dropped because strand orientation can never be verified from array data, and \(adm.mismatchDropped) allele mismatches were dropped rather than guessed.")
            bullet("Continental percentages are robust. Within-European percentages are approximate at best — treat them as ±10–15 percentage points. Intra-European genetic differentiation is tiny (Fst ≈ 0.001–0.01); no marker set this size can call countries.")
            bullet("Recent admixture blurs everything: a parent or grandparent from a different region shifts every component in ways a frequency-mixture model cannot fully separate.")
            bullet("Reference panels are samples, not censuses: 1000 Genomes populations and gnomAD groups stand in for regions they only partially represent. The MID reference is small (supporting evidence only), and the AMR reference is itself recently admixed.")
            bullet("These are ancestry signals — not a passport, nationality, ethnicity, religion, or identity. Nothing here says what anyone 'is'.")
            bullet("Educational, never diagnostic: no result on this screen is medical information or a basis for any clinical decision.")

            ForEach(adm.notes, id: \.self) { note in
                HStack(alignment: .top, spacing: 6) {
                    Text("·").foregroundStyle(Theme.textLow)
                    Text(note).foregroundStyle(Theme.textLow).font(.caption)
                }
            }
        }
        .dnaCard()
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•").foregroundStyle(Theme.teal)
            Text(text).foregroundStyle(Theme.textMed).font(.callout)
        }
    }

    // MARK: - Footnotes

    private func footnotesCard(_ adm: AdmixtureReport) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Reference Sources (per population)")
                .font(.headline)
                .foregroundStyle(Theme.textHi)
            ForEach(adm.sourceFootnotes, id: \.self) { f in
                Text(f)
                    .font(.caption.monospaced())
                    .foregroundStyle(Theme.textLow)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text("All computation happens on this Mac. The panel above is bundled data; the app performs zero network access.")
                .font(.caption)
                .foregroundStyle(Theme.textMed)
                .padding(.top, 4)
        }
        .dnaCard()
    }
}

// MARK: - Donut chart (pure SwiftUI, no dependencies)

struct DonutChart: View {
    /// (color, fraction) — fractions are absolute (0...1); a faint track fills the rest.
    var segments: [(Color, Double)]

    private var cumulative: [(color: Color, from: Double, to: Double)] {
        var acc = 0.0
        var out: [(Color, Double, Double)] = []
        for (color, f) in segments {
            let clamped = max(0, min(f, 1 - acc))
            out.append((color, acc, acc + clamped))
            acc += clamped
        }
        return out.map { (color: $0.0, from: $0.1, to: $0.2) }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.bgInset, lineWidth: 26)
            ForEach(Array(cumulative.enumerated()), id: \.offset) { _, seg in
                Circle()
                    .trim(from: seg.from, to: seg.to)
                    .stroke(seg.color, style: StrokeStyle(lineWidth: 26, lineCap: .butt))
                    .rotationEffect(.degrees(-90))
            }
        }
        .padding(14)
    }
}

// MARK: - Confidence-interval bar row

struct CIBarRow: View {
    var title: String
    var share: Double
    var ciLow: Double
    var ciHigh: Double
    var scale: Double        // right edge of the bar's domain
    var color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textHi)
                Spacer()
                Text(String(format: "%.1f%% of whole genome", share * 100))
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.textHi)
                Text(String(format: "95%% CI %.1f–%.1f%%", ciLow * 100, ciHigh * 100))
                    .font(.caption.monospaced())
                    .foregroundStyle(Theme.textLow)
            }
            GeometryReader { geo in
                let w = geo.size.width
                let x = { (v: Double) in CGFloat(min(max(v / scale, 0), 1)) * w }
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.bgInset)
                    Capsule()
                        .fill(color.opacity(0.85))
                        .frame(width: max(3, x(share)))
                    // CI whisker band
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color.opacity(0.28))
                        .frame(width: max(2, x(ciHigh) - x(ciLow)), height: 4)
                        .offset(x: x(ciLow))
                }
            }
            .frame(height: 10)
        }
    }
}
