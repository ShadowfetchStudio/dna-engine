import SwiftUI

struct GenomeView: View {
    @EnvironmentObject private var engine: DNAEngine
    var report: AnalysisReport { engine.report! }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                metricsGrid
                
                // 23-Chromosome Ideogram with ROH regions painted (feature 7)
                ChromosomeKaryotypeView(
                    chromosomeCounts: report.genome.chromosomeCounts,
                    selectedChrom: engine.selectedChromosomeFilter,
                    onSelectChrom: { chrom in
                        engine.selectedChromosomeFilter = (engine.selectedChromosomeFilter == chrom) ? "ALL" : chrom
                    },
                    rohRegions: report.roh.regions
                )

                ROHSectionView(roh: report.roh)

                // Whole Genome SNP Browser
                wholeGenomeBrowser
                
                privacyCard
            }
            .padding(22)
        }
        .background(Theme.bgDeep)
        .onChange(of: engine.search) { _, _ in engine.scheduleGenomeSearch() }
        .onChange(of: engine.selectedChromosomeFilter) { _, _ in engine.scheduleGenomeSearch() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Whole-Genome File & Karyotype Browser")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Theme.textHi)
                Spacer()
                Text(report.genome.vendor.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.teal)
            }
            Text("Ingested file: \(report.genome.fileName) · \(report.genome.buildHint)")
                .font(.subheadline)
                .foregroundStyle(Theme.textMed)
        }
    }

    private var metricsGrid: some View {
        HStack(spacing: 12) {
            StatChip(label: "Total Variants", value: report.genome.snpCount.formatted(), sublabel: "Indexed in memory", icon: "circle.hexagongrid.fill")
            StatChip(label: "Sex Chromosome Call", value: report.genome.inferredSex, sublabel: "X Het & Y Count Analysis", icon: "person.crop.circle")
            StatChip(label: "No-Call Rate", value: "\(report.genome.noCallCount.formatted()) (\(String(format: "%.2f%%", Double(report.genome.noCallCount) / Double(max(report.genome.snpCount, 1)) * 100)))", sublabel: "Uncalled by microarray lab", icon: "exclamationmark.circle")
        }
    }

    private var wholeGenomeBrowser: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Raw Variant Explorer (\(engine.selectedChromosomeFilter == "ALL" ? "All Chromosomes" : "chr\(engine.selectedChromosomeFilter)"))")
                    .font(.headline)
                    .foregroundStyle(Theme.textHi)
                Spacer()
                if engine.selectedChromosomeFilter != "ALL" {
                    Button("Show All Chromosomes") {
                        engine.selectedChromosomeFilter = "ALL"
                    }
                    .font(.caption)
                    .foregroundStyle(Theme.teal)
                }
            }

            // Search box
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Theme.textLow)
                TextField("Search any rsID or base position across whole file (e.g. rs429358, 45411941)", text: $engine.search)
                    .textFieldStyle(.plain)
                if !engine.search.isEmpty {
                    Button("Clear") { engine.search = "" }
                        .font(.caption)
                        .foregroundStyle(Theme.textMed)
                }
            }
            .padding(10)
            .background(Theme.bgInset, in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.stroke, lineWidth: 1))

            // SNP Table
            let calls = engine.fullGenomeFilteredSNPs()
            if calls.isEmpty {
                ContentUnavailableView("No Variants Found", systemImage: "magnifyingglass", description: Text("No variants matched your search or chromosome filter."))
                    .frame(maxWidth: .infinity, minHeight: 180)
            } else {
                VStack(spacing: 0) {
                    // Table Header
                    HStack {
                        Text("rsID").frame(width: 140, alignment: .leading)
                        Text("Chr").frame(width: 50, alignment: .leading)
                        Text("Position").frame(width: 110, alignment: .leading)
                        Text("Alleles").frame(width: 80, alignment: .leading)
                        Spacer()
                        Text("Status").frame(width: 90, alignment: .trailing)
                    }
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.textLow)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Theme.bgInset)

                    Divider()

                    // Rows
                    ForEach(calls) { call in
                        HStack {
                            Text(call.rsid)
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundStyle(Theme.teal)
                                .frame(width: 140, alignment: .leading)
                            Text("chr\(call.chromosome)")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(Theme.textMed)
                                .frame(width: 50, alignment: .leading)
                            Text(call.position.formatted())
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(Theme.textMed)
                                .frame(width: 110, alignment: .leading)
                            Text(call.display)
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundStyle(Theme.textHi)
                                .frame(width: 80, alignment: .leading)
                            Spacer()
                            Text(call.isNoCall ? "No-Call" : (call.isHeterozygous ? "Heterozygous" : "Homozygous"))
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(call.isNoCall ? Theme.textLow : (call.isHeterozygous ? Theme.gold : Theme.success))
                                .frame(width: 90, alignment: .trailing)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        Divider()
                    }
                }
                .background(Theme.bgCard, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.stroke, lineWidth: 1))
            }
        }
    }

    private var privacyCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Data Security & Local Privacy")
                .font(.headline)
                .foregroundStyle(Theme.textHi)
            Text("DNA Engine is a local product with no account, telemetry, or cloud analysis. A persistent genome is stored as AES-256-GCM ciphertext in `~/Library/Application Support/DNAEngine/workspace.dnavault`; Private Session data is not saved.")
                .font(.callout)
                .foregroundStyle(Theme.textMed)
            HStack(spacing: 12) {
                Button("Reveal in Finder") {
                    AppPaths.reveal(AppPaths.support)
                }
                Button("Erase Local Genome", role: .destructive) {
                    engine.eraseLocal()
                }
            }
            .padding(.top, 4)
        }
        .dnaCard()
    }
}
