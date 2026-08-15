import SwiftUI

struct CompareView: View {
    @EnvironmentObject private var engine: DNAEngine

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let comparison = engine.comparisonReport {
                    comparisonDashboard(comparison)
                } else {
                    emptyState
                }
            }
            .padding(22)
        }
        .background(Theme.bgDeep)
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 48))
                .foregroundStyle(Theme.teal)

            Text("Two-File Genotype Concordance")
                .font(.title2.weight(.bold))
                .foregroundStyle(Theme.textHi)

            Text("Compare the raw called autosomal rsIDs in two local files. DNA Engine reports exact-genotype concordance and allele overlap only; it does not estimate kinship, IBD, or a relationship.")
                .font(.callout)
                .foregroundStyle(Theme.textMed)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 560)

            Button {
                engine.importSecondaryForComparison()
            } label: {
                Label("Import Second File to Compare", systemImage: "square.and.arrow.down")
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.teal)
            .padding(.top, 8)

            VStack(alignment: .leading, spacing: 5) {
                Label("Research similarity only", systemImage: "info.circle.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.gold)
                Text("Chip version, genome build, missingness, strand coding, and laboratory error can all change raw concordance. Relationship analysis requires a separately validated method.")
                    .font(.caption)
                    .foregroundStyle(Theme.textMed)
            }
            .frame(maxWidth: 560, alignment: .leading)
            .dnaCard()
        }
        .frame(maxWidth: .infinity, minHeight: 400)
    }

    private func comparisonDashboard(_ comparison: GenomeComparison) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("Raw Genotype Concordance")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Theme.textHi)
                        Text("LOCAL RESEARCH")
                            .font(.system(size: 9, weight: .heavy, design: .monospaced))
                            .foregroundStyle(Theme.teal)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.teal.opacity(0.12), in: Capsule())
                    }
                    Text("Comparing **\(comparison.profileNameA)** and **\(comparison.profileNameB)**")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textMed)
                }
                Spacer()
                Button("Compare Another File") {
                    engine.importSecondaryForComparison()
                }
                .buttonStyle(.bordered)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("NO RELATIONSHIP INFERENCE")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.gold)
                Text(comparison.researchSimilaritySummary)
                    .font(.callout)
                    .foregroundStyle(Theme.textHi)
                Text("Counts are direct raw-file comparisons with no allele-frequency model, LD pruning, or validated cross-vendor orientation manifest.")
                    .font(.caption)
                    .foregroundStyle(Theme.textMed)
            }
            .dnaCard()

            HStack(spacing: 12) {
                StatChip(
                    label: "Shared Called rsIDs",
                    value: comparison.totalComparedSNPs.formatted(),
                    sublabel: "Autosomal overlap",
                    icon: "circle.hexagongrid.fill"
                )
                StatChip(
                    label: "Exact Genotype",
                    value: String(format: "%.1f%%", comparison.exactGenotypeConcordance * 100),
                    sublabel: "\(comparison.exactGenotypeMatchCount.formatted()) calls",
                    icon: "equal.circle.fill"
                )
                StatChip(
                    label: "One Allele Overlap",
                    value: String(format: "%.1f%%", comparison.oneAlleleOverlapFraction * 100),
                    sublabel: "\(comparison.oneAlleleOverlapCount.formatted()) calls",
                    icon: "circle.lefthalf.filled"
                )
                StatChip(
                    label: "No Allele Overlap",
                    value: String(format: "%.1f%%", comparison.noAlleleOverlapFraction * 100),
                    sublabel: "\(comparison.noAlleleOverlapCount.formatted()) calls",
                    icon: "xmark.circle.fill"
                )
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("How to read this")
                    .font(.headline)
                    .foregroundStyle(Theme.textHi)
                Text("Exact genotype agreement is a technical concordance measure. A low value can reflect incompatible files as readily as biological difference. A high value does not establish identity or a family relationship.")
                    .font(.callout)
                    .foregroundStyle(Theme.textMed)
            }
            .dnaCard()
        }
    }
}
