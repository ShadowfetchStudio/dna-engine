import SwiftUI

struct PolygenicView: View {
    @EnvironmentObject private var engine: DNAEngine
    var report: AnalysisReport { engine.report! }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                scoresGrid
            }
            .padding(22)
        }
        .background(Theme.bgDeep)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Calibrated Polygenic Tendency Panels")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Theme.textHi)
                Spacer()
                Text("15 MULTI-SNP PANELS")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.gold)
            }
            Text("Panels are calibrated against published per-population risk-allele frequencies under Hardy-Weinberg, recomputed over only the SNPs your file actually types. Educational tendencies, highly modifiable through lifestyle.")
                .font(.subheadline)
                .foregroundStyle(Theme.textMed)
            EuroBiasBanner(report: report)
            HStack { Spacer(); LimitsLink() }
        }
    }

    private var scoresGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 340), spacing: 14)], spacing: 14) {
            ForEach(report.calibratedScores) { score in
                PolygenicScoreCard(score: score)
            }
        }
    }
}

struct PolygenicScoreCard: View {
    var score: CalibratedPolygenicScore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(score.title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Theme.textHi)
                    Text("\(score.usedSNPs)/\(score.totalSNPs) typed SNPs · ref: \(score.referencePopulation)\(score.referencePopulationIsFallback ? " (fallback)" : "")")
                        .font(.caption2.monospaced())
                        .foregroundStyle(Theme.textLow)
                }
                Spacer()
                if score.insufficientCoverage {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("—")
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundStyle(Theme.textLow)
                        Text("NO PERCENTILE")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundStyle(Theme.warning)
                    }
                } else {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(score.percentile)th")
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundStyle(score.impact.color)
                        Text("PERCENTILE")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundStyle(Theme.textLow)
                    }
                }
            }

            if score.insufficientCoverage {
                Text("Insufficient chip coverage: fewer than 60% of this panel's SNPs are typed in this file, so no percentile is shown — it would be a guess.")
                    .font(.callout)
                    .foregroundStyle(Theme.warning)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                GaussianPercentileCurve(percentile: score.percentile, zScore: score.zScore, riskColor: score.impact.color)
                PopulationSpreadStrip(score: score)
            }

            if let mismatch = mismatchNote {
                Text(mismatch)
                    .font(.caption2)
                    .foregroundStyle(Theme.warning)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack {
                Text(score.riskCategory)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(score.impact.color)
                Spacer()
                if !score.topContributingGenes.isEmpty {
                    Text("Genes: \(score.topContributingGenes.joined(separator: ", "))")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Theme.teal)
                }
            }

            Text(score.description)
                .font(.caption)
                .foregroundStyle(Theme.textMed)

            if !score.insufficientCoverage {
                Text("Percentile vs. \(score.referencePopulation) reference allele frequencies under HWE — a tendency estimate, not a clinical PRS (those use thousands to millions of variants).")
                    .font(.caption2)
                    .foregroundStyle(Theme.textLow)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("RESEARCH CONTEXT & LIMITS")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.gold)
                Text("This small array panel is descriptive research context, not a personalized intervention plan. Conventional history, measurements, environment, and validated clinical tools carry more weight than this percentile.")
                    .font(.caption)
                    .foregroundStyle(Theme.textHi)
            }
            .padding(8)
            .background(Theme.bgInset, in: RoundedRectangle(cornerRadius: 8))
        }
        .dnaCard()
    }

    @EnvironmentObject private var engine: DNAEngine

    private var mismatchNote: String? {
        guard let report = engine.report else { return nil }
        return HonestyEngine.referenceMismatchBanner(score: score, report: report)
    }
}

/// Feature 4: the 7-tick per-population percentile spread strip.
struct PopulationSpreadStrip: View {
    var score: CalibratedPolygenicScore

    var body: some View {
        let entries = score.percentileByPopulation.sorted { $0.key < $1.key }
        VStack(alignment: .leading, spacing: 3) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.bgInset).frame(height: 4).offset(y: 6)
                    ForEach(entries, id: \.key) { pop, pct in
                        let x = geo.size.width * CGFloat(pct) / 100.0
                        Rectangle()
                            .fill(pop == score.referencePopulation ? Theme.teal : Theme.textLow.opacity(0.6))
                            .frame(width: pop == score.referencePopulation ? 3 : 1.5, height: 16)
                            .offset(x: max(0, min(geo.size.width - 2, x)))
                            .help("\(pop): \(pct)th percentile")
                    }
                }
            }
            .frame(height: 16)
            Text("Tick per reference population (\(entries.count)); teal = \(score.referencePopulation). Spread across ticks = how much the 'percentile' depends on whose allele frequencies you assume.")
                .font(.system(size: 9))
                .foregroundStyle(Theme.textLow)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
