import SwiftUI

struct PharmacogenomicsView: View {
    @EnvironmentObject private var engine: DNAEngine
    var report: AnalysisReport { engine.report! }

    @State private var search = ""
    @State private var showOnlyUnresolved = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                headerBanner
                observationList
            }
            .padding(22)
        }
        .background(Theme.bgDeep)
    }

    private var headerBanner: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("PGx Research Observations")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Theme.textHi)
                        Text("NO PHENOTYPE CALL")
                            .font(.system(size: 9, weight: .heavy, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .foregroundStyle(Theme.gold)
                            .background(Theme.gold.opacity(0.15), in: Capsule())
                    }
                    Text("Observed array loci and published drug-gene source references. DNA Engine does not infer star alleles, diplotypes, phenotypes, medication response, or clinical action.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textMed)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                LimitsLink()
                Button {
                    engine.exportPGxResearchBrief()
                } label: {
                    Label("Export Research Sheet", systemImage: "doc.text.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.teal)
                .help("Exports every defining array locus, coverage status, and assay limitation")
            }

            HStack(spacing: 12) {
                let observations = report.pharmacogenomics.geneObservations
                let loci = observations.flatMap(\.loci)
                StatChip(label: "Genes Listed", value: "\(observations.count)", sublabel: "Research catalog entries", icon: "atom")
                StatChip(label: "Loci Observed", value: "\(loci.filter { $0.status == .observed }.count)", sublabel: "Strand-resolved array calls", icon: "checkmark.circle.fill")
                StatChip(label: "Loci Unresolved", value: "\(loci.filter { $0.status != .observed }.count)", sublabel: "Missing, no-call, or ambiguous", icon: "questionmark.circle.fill")
            }

            HStack(spacing: 10) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Theme.textLow)
                    TextField("Search gene or published drug-gene reference", text: $search)
                        .textFieldStyle(.plain)
                    if !search.isEmpty {
                        Button("Clear") { search = "" }
                            .font(.caption)
                            .foregroundStyle(Theme.textMed)
                    }
                }
                .padding(10)
                .background(Theme.bgInset, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.stroke, lineWidth: 1))

                Toggle("Unresolved only", isOn: $showOnlyUnresolved)
                    .toggleStyle(.button)
                    .font(.caption.weight(.semibold))
                    .tint(Theme.gold.opacity(0.2))
            }
        }
    }

    private var filteredObservations: [PGxGeneObservation] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return report.pharmacogenomics.geneObservations.filter { observation in
            let matchesQuery = query.isEmpty
                || observation.gene.lowercased().contains(query)
                || observation.drugReferences.contains {
                    $0.name.lowercased().contains(query)
                        || $0.brands.lowercased().contains(query)
                }
            let matchesStatus = !showOnlyUnresolved || observation.unresolvedCount > 0
            return matchesQuery && matchesStatus
        }
    }

    private var observationList: some View {
        VStack(alignment: .leading, spacing: 14) {
            if filteredObservations.isEmpty {
                ContentUnavailableView(
                    "No Research Observations Found",
                    systemImage: "text.magnifyingglass",
                    description: Text("No gene or source reference matched the current filters.")
                )
                .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                ForEach(filteredObservations) { observation in
                    PGxGeneObservationCard(observation: observation)
                }
            }
        }
    }
}

/// Shared compact filter control used by PGx, evidence, and pathway views.
struct FilterChip: View {
    var title: String
    var systemImage: String? = nil
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.caption2)
                }
                Text(title)
                    .font(.caption.weight(.medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Theme.teal.opacity(0.18) : Theme.bgCard, in: Capsule())
            .overlay(Capsule().stroke(isSelected ? Theme.teal : Theme.stroke, lineWidth: 1))
            .foregroundStyle(isSelected ? Theme.teal : Theme.textMed)
        }
        .buttonStyle(.plain)
    }
}

struct PGxGeneObservationCard: View {
    var observation: PGxGeneObservation

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(observation.gene)
                        .font(.title3.weight(.bold).monospaced())
                        .foregroundStyle(Theme.textHi)
                    Text("\(observation.observedCount)/\(observation.loci.count) defining array loci strand-resolved")
                        .font(.caption)
                        .foregroundStyle(Theme.textMed)
                }
                Spacer()
                Text(observation.unresolvedCount == 0 ? "ARRAY LOCI OBSERVED" : "INCOMPLETE / UNRESOLVED")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(observation.unresolvedCount == 0 ? Theme.teal : Theme.gold)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("DEFINING LOCI")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.textLow)
                ForEach(observation.loci) { locus in
                    HStack(spacing: 8) {
                        Text(locus.rsid)
                            .font(.caption.weight(.bold).monospaced())
                            .foregroundStyle(Theme.teal)
                            .frame(width: 92, alignment: .leading)
                        Text(locus.alleleName)
                            .font(.caption)
                            .foregroundStyle(Theme.textMed)
                            .frame(width: 110, alignment: .leading)
                        Text("Expected \(locus.expectedAlleles)")
                            .font(.caption2.monospaced())
                            .foregroundStyle(Theme.textLow)
                        Spacer()
                        Text(locus.observedGenotype)
                            .font(.caption.weight(.semibold).monospaced())
                            .foregroundStyle(Theme.textHi)
                        Text(locus.status.rawValue.uppercased())
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundStyle(color(for: locus.status))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(color(for: locus.status).opacity(0.12), in: Capsule())
                    }
                    .padding(7)
                    .background(Theme.bgInset, in: RoundedRectangle(cornerRadius: 7))
                }
            }

            if !observation.drugReferences.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("PUBLISHED SOURCE PAIRS — CONTEXT ONLY")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.textLow)
                    ForEach(observation.drugReferences) { reference in
                        Text("\(reference.name) (\(reference.brands)) · \(reference.sourceLevel)")
                            .font(.caption)
                            .foregroundStyle(Theme.textMed)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 5) {
                Label("Assay limits", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.gold)
                Text(observation.chipLimitations)
                    .font(.caption)
                    .foregroundStyle(Theme.textMed)
                if !observation.undetectable.isEmpty {
                    Text("Not represented: \(observation.undetectable.joined(separator: "; ")).")
                        .font(.caption)
                        .foregroundStyle(Theme.textMed)
                }
            }
            .padding(8)
            .background(Theme.gold.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
        }
        .dnaCard()
    }

    private func color(for status: PGxLocusStatus) -> Color {
        status == .observed ? Theme.teal : Theme.gold
    }
}
