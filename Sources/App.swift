import SwiftUI
import AppKit
import Combine

@main
struct DNAEngineApp: App {
    @StateObject private var engine = DNAEngine.shared
    @StateObject private var activityMonitor = WorkspaceActivityMonitor()
    @AppStorage("workspace.autoClearMinutes") private var autoClearMinutes = 15
    private let inactivityTimer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    init() {
        NSApplication.shared.appearance = NSAppearance(named: .darkAqua)
    }

    var body: some Scene {
        WindowGroup("DNA Engine") {
            ContentView()
                .environmentObject(engine)
                .environmentObject(activityMonitor)
                .preferredColorScheme(.dark)
                .frame(minWidth: 1220, minHeight: 780)
                .onAppear { engine.boot() }
                .onChange(of: engine.report != nil) { _, hasReport in
                    if hasReport { activityMonitor.recordActivity() }
                }
                .onReceive(inactivityTimer) { date in
                    guard engine.report != nil, !engine.isWorking,
                          activityMonitor.hasExceeded(minutes: autoClearMinutes, at: date) else { return }
                    engine.clearSessionFromMemory()
                }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Import into Encrypted Workspace…") {
                    engine.importGenome(mode: .encryptedWorkspace)
                }
                .keyboardShortcut("i", modifiers: [.command])
                .disabled(engine.isWorking)

                Button("Open Memory-Only Private Session…") {
                    engine.importGenome(mode: .privateSession)
                }
                .keyboardShortcut("i", modifiers: [.command, .shift])
                .disabled(engine.isWorking)

                Button("Open Second File for Raw Concordance…") {
                    engine.importSecondaryForComparison()
                }
                .keyboardShortcut("k", modifiers: [.command, .shift])
                .disabled(engine.report == nil || engine.isWorking)

                Button("Load Synthetic Demo Genome") {
                    engine.loadDemo()
                }
                .keyboardShortcut("d", modifiers: [.command])
                .disabled(engine.isWorking)

                Divider()

                Menu("Export Reports") {
                    Button("Export Full PDF Report…") {
                        engine.exportReportPDF()
                    }
                    Button("Executive HTML Summary…") {
                        engine.exportReportHTML()
                    }
                    Button("Pharmacogenomics Research Brief…") {
                        engine.exportPGxResearchBrief()
                    }
                    Button("Full Markdown Research Report…") {
                        engine.exportReportMarkdown()
                    }
                    Button("Raw JSON Dataset…") {
                        engine.exportReportJSON()
                    }
                }
                .disabled(engine.report == nil || engine.isWorking)

                Button("Clear Current Session from Memory") {
                    engine.clearSessionFromMemory()
                }
                .disabled(engine.report == nil || engine.isWorking)

                Button("Reload Encrypted Workspace") {
                    engine.reloadEncryptedWorkspace()
                }
                .disabled(engine.report != nil || engine.isWorking || !FileManager.default.fileExists(atPath: AppPaths.privateVault.path))

                Button("Reveal Local Database in Finder") {
                    AppPaths.reveal(AppPaths.support)
                }

                Divider()

                Button("Erase Local DNA Data", role: .destructive) {
                    engine.eraseLocal()
                }
            }
        }

        Settings {
            PrivateWorkspaceSettingsView()
                .environmentObject(engine)
                .preferredColorScheme(.dark)
        }
    }
}
