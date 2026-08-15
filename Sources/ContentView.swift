import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var engine: DNAEngine

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 240, ideal: 270, max: 320)
        } detail: {
            detail
                .background(Theme.bgDeep)
        }
        .background(Theme.bgDeep)
        .toolbar { toolbar }
        .alert("Notice", isPresented: Binding(
            get: { engine.errorMessage != nil },
            set: { if !$0 { engine.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { engine.errorMessage = nil }
        } message: {
            Text(engine.errorMessage ?? "")
        }
    }

    private var sidebar: some View {
        List(selection: $engine.selected) {
            Section("Workstation") {
                nav(.overview)
                nav(.protocolDay)
                nav(.pharmacogenomics)
                nav(.pathways)
                nav(.polygenic)
                nav(.ancestry)
            }
            
            Section("Systems Biology") {
                nav(.methylation)
                nav(.cardio)
                nav(.sleep)
                nav(.mind)
                nav(.move)
                nav(.metabolism)
                nav(.vitamins)
                nav(.immunity)
                nav(.histamine)
                nav(.longevity)
                nav(.traits)
            }
            
            Section("Genomics Tools") {
                nav(.genome)
                nav(.qc)
                nav(.search)
                nav(.compare)
                nav(.privacy)
            }

            Section("Honesty") {
                nav(.limits)
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Circle().fill(Theme.teal).frame(width: 7, height: 7)
                    Text("PRIVATE LOCAL WORKBENCH")
                        .font(.system(size: 9, weight: .heavy, design: .monospaced))
                        .foregroundStyle(Theme.teal)
                }
                Text("No telemetry or cloud account. Encrypted workspace available.")
                    .font(.caption2)
                    .foregroundStyle(Theme.textLow)
            }
            .padding(12)
            .background(Theme.bgRaised)
        }
    }

    private func nav(_ item: NavItem) -> some View {
        NavigationLink(value: item) {
            Label(item.title, systemImage: item.systemImage)
        }
    }

    @ViewBuilder
    private var detail: some View {
        if engine.report == nil && !engine.isWorking {
            ImportView()
        } else if engine.isWorking && engine.report == nil {
            VStack(spacing: 18) {
                HelixView()
                    .frame(width: 96, height: 96)
                ProgressView(value: engine.progress)
                    .frame(maxWidth: 380)
                Text(engine.status)
                    .foregroundStyle(Theme.textMed)
                    .font(.callout.monospaced())
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            switch engine.selected {
            case .overview: OverviewView()
            case .protocolDay: ProtocolView()
            case .pharmacogenomics: PharmacogenomicsView()
            case .pathways: PathwaysView()
            case .polygenic: PolygenicView()
            case .ancestry: AncestryView()
            case .compare: CompareView()
            case .genome: GenomeView()
            case .qc: QCView()
            case .privacy: PrivacyView()
            case .limits: LimitsView()
            case .search: MarkerBrowserView(title: "Search Catalog SNPs", showSearch: true)
            default: MarkerBrowserView(title: engine.selected.title, showSearch: true)
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            HStack(spacing: 8) {
                Image(systemName: "circle.hexagongrid.fill")
                    .foregroundStyle(Theme.teal)
                Text("DNA Engine")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Theme.textHi)
            }
        }

        ToolbarItem(placement: .principal) {
            Text(engine.status)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(Theme.textMed)
                .lineLimit(1)
        }

        ToolbarItemGroup(placement: .primaryAction) {
            Button {
                engine.importGenome(mode: .encryptedWorkspace)
            } label: {
                Label("Encrypted Import", systemImage: "lock.doc")
            }
            .help("Validate and import raw DNA into the encrypted local workspace")
            .keyboardShortcut("i", modifiers: [.command])
            .disabled(engine.isWorking)

            Menu {
                Button {
                    engine.exportReportHTML()
                } label: {
                    Label("Export Executive HTML Summary", systemImage: "doc.richtext")
                }
                
                Button {
                    engine.exportPGxResearchBrief()
                } label: {
                    Label("Export Pharmacogenomics Research Brief", systemImage: "doc.text.magnifyingglass")
                }
                
                Button {
                    engine.exportReportMarkdown()
                } label: {
                    Label("Export Full Markdown Report", systemImage: "doc.text")
                }
                
                Button {
                    engine.exportReportJSON()
                } label: {
                    Label("Export Raw JSON Data", systemImage: "curlybraces")
                }
            } label: {
                Label("Export", systemImage: "square.and.arrow.up")
            }
            .disabled(engine.report == nil || engine.isWorking)
            .help("Export comprehensive reports")
            .keyboardShortcut("e", modifiers: [.command])
        }
    }
}
