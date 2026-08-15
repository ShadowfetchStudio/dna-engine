import SwiftUI

struct MarkerBrowserView: View {
    @EnvironmentObject private var engine: DNAEngine
    var title: String
    var showSearch: Bool

    @State private var selectedEvidenceFilter: EvidenceLevel? = nil
    @State private var selectedTierFilter: String? = nil
    @State private var selectedCoverageFilter: MarkerHit.Coverage? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            VStack(spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Theme.textHi)
                        Text(coverageLine)
                            .font(.caption2.monospaced())
                            .foregroundStyle(Theme.textLow)
                    }
                    Spacer()
                    LimitsLink()
                    if showSearch {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(Theme.textLow)
                            TextField("Gene, rsID, or keyword", text: $engine.search)
                                .textFieldStyle(.plain)
                            if !engine.search.isEmpty {
                                Button("Clear") { engine.search = "" }
                                    .font(.caption)
                                    .foregroundStyle(Theme.textMed)
                            }
                        }
                        .padding(8)
                        .frame(maxWidth: 280)
                        .background(Theme.bgInset, in: RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.stroke, lineWidth: 1))
                    }
                }

                // Filter rail (feature 9): impact + evidence + tier + coverage
                FilterRail(
                    evidence: $selectedEvidenceFilter,
                    tier: $selectedTierFilter,
                    coverage: $selectedCoverageFilter
                )

                if let report = engine.report {
                    EuroBiasBanner(report: report)
                }
            }
            .padding(16)
            .background(Theme.bgRaised)

            Divider()

            // List of Markers
            if filteredHits.isEmpty {
                ContentUnavailableView("No Markers Found", systemImage: "magnifyingglass", description: Text("No catalog loci in this slice matched your search or filters."))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(filteredHits) { hit in
                            MarkerRow(hit: hit)
                                .onTapGesture { engine.selectedHit = hit }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .background(Theme.bgDeep)
        .sheet(item: $engine.selectedHit) { hit in
            MarkerDetailView(hit: hit)
                .frame(minWidth: 680, minHeight: 540)
        }
    }

    private var filteredHits: [MarkerHit] {
        // The exact predicate the harness probes (HeadlineBuilder.filteredHits).
        HeadlineBuilder.filteredHits(
            engine.hitsForSelection(),
            impact: nil,
            evidence: selectedEvidenceFilter,
            tier: selectedTierFilter,
            coverage: selectedCoverageFilter
        )
    }

    private var coverageLine: String {
        let slice = engine.hitsForSelection()
        let matched = slice.filter { $0.coverage == .matched }.count
        return "your file covers \(matched)/\(slice.count) markers in this slice · \(filteredHits.count) shown"
    }
}

struct MarkerRow: View {
    var hit: MarkerHit

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(hit.gene)
                    .font(.system(size: 14, weight: .heavy, design: .monospaced))
                    .foregroundStyle(Theme.teal)
                Text(hit.rsid)
                    .font(.caption.monospaced())
                    .foregroundStyle(Theme.textLow)
                Text("· chr\(hit.chromosome)")
                    .font(.caption2.monospaced())
                    .foregroundStyle(Theme.textLow)
                Spacer()
                Text(hit.observed)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.textHi)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Theme.bgInset, in: RoundedRectangle(cornerRadius: 6))
                Text("RAW CALL")
                    .font(.system(size: 9, weight: .heavy, design: .monospaced))
                    .foregroundStyle(Theme.teal)
            }

            Text(hit.title)
                .font(.headline)
                .foregroundStyle(Theme.textHi)

            Text(hit.summary)
                .font(.callout)
                .foregroundStyle(Theme.textMed)

            HStack {
                Text(hit.label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.teal)
                Text("·")
                Text(hit.evidence.label)
                if let tier = hit.tier {
                    Text("·")
                    Text(tier.capitalized)
                }
                Text("·")
                Text(hit.coverage.rawValue.capitalized)
                if let transfer = hit.transferability {
                    TransferabilityBadge(raw: transfer)
                }
                Spacer()
                Text(hit.categories.map { $0.capitalized }.joined(separator: " · "))
            }
            .font(.caption2)
            .foregroundStyle(Theme.textLow)
        }
        .dnaCard()
    }
}

struct TransferabilityBadge: View {
    var raw: String

    private var short: String {
        switch raw {
        case "euro-biased": return "EUR-BIASED"
        case "multi-ancestry": return "MULTI-ANC"
        case "east-asian-derived": return "EAS-DERIVED"
        case "african-derived": return "AFR-DERIVED"
        default: return raw.uppercased()
        }
    }

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "globe")
                .font(.system(size: 8))
            Text(short)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .foregroundStyle(raw == "multi-ancestry" ? Theme.success : Theme.warning)
        .background((raw == "multi-ancestry" ? Theme.success : Theme.warning).opacity(0.12), in: Capsule())
        .help(Transferability.explainer(raw) ?? raw)
    }
}

struct MarkerDetailView: View {
    var hit: MarkerHit
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(hit.gene).font(.caption.monospaced().weight(.bold)).foregroundStyle(Theme.teal)
                        Text(hit.title).font(.title2.weight(.bold)).foregroundStyle(Theme.textHi)
                        Text("\(hit.rsid) · chr\(hit.chromosome) · Observed: \(hit.observed) (Key: \(hit.genotypeKey)) · \(hit.evidence.label)")
                            .font(.caption.monospaced())
                            .foregroundStyle(Theme.textLow)
                    }
                    Spacer()
                    Text("NO OUTCOME CALL")
                        .font(.system(size: 9, weight: .heavy, design: .monospaced))
                        .foregroundStyle(Theme.teal)
                    Button("Close") { dismiss() }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("ARRAY OBSERVATION")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.teal)
                    Text(hit.label).font(.headline)
                    Text(hit.summary).foregroundStyle(Theme.textHi).font(.callout)
                }
                .dnaCard()

                VStack(alignment: .leading, spacing: 6) {
                    Text("BIOLOGICAL MECHANISM")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.gold)
                    Text(hit.mechanism).foregroundStyle(Theme.textMed).font(.callout)
                }
                .dnaCard()

                if !hit.detail.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("RESEARCH CONTEXT & LIMITS")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(Theme.textLow)
                        Text(hit.detail).foregroundStyle(Theme.textMed).font(.callout)
                    }
                    .dnaCard()
                }

                // Evidence & Citations (2.0 honesty schema)
                VStack(alignment: .leading, spacing: 8) {
                    Text("EVIDENCE & CITATIONS")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.teal)

                    HStack(spacing: 8) {
                        if let tier = hit.tier {
                            Text(tier.uppercased())
                                .font(.system(size: 9, weight: .heavy, design: .monospaced))
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .foregroundStyle(Theme.gold)
                                .background(Theme.gold.opacity(0.12), in: Capsule())
                        }
                        if let transfer = hit.transferability {
                            TransferabilityBadge(raw: transfer)
                        }
                    }

                    if let explainer = Transferability.explainer(hit.transferability) {
                        Text(explainer)
                            .font(.caption)
                            .foregroundStyle(Theme.textMed)
                    }

                    if let citations = hit.citations, !citations.isEmpty {
                        ForEach(citations, id: \.self) { cit in
                            HStack(alignment: .top, spacing: 8) {
                                Text(cit.pmid)
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundStyle(Theme.teal)
                                    .textSelection(.enabled)
                                Text(cit.note)
                                    .font(.caption)
                                    .foregroundStyle(Theme.textMed)
                                    .textSelection(.enabled)
                            }
                        }
                        Text("Numeric IDs are PMIDs — search them at pubmed.gov on your own device. Named tags (PharmGKB, GWAS Catalog, ClinVar, CPIC) are curated registries you can search the rsID in. This app never opens a network connection.")
                            .font(.caption2)
                            .foregroundStyle(Theme.textLow)
                    } else {
                        Text("No citation recorded — treat this marker's interpretation with extra skepticism.")
                            .font(.caption2)
                            .foregroundStyle(Theme.warning)
                    }
                }
                .dnaCard()

                DisclaimerBanner()
            }
            .padding(22)
        }
        .background(Theme.bgDeep)
    }
}
