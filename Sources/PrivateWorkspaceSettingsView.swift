import SwiftUI

struct PrivateWorkspaceSettingsView: View {
    @EnvironmentObject private var engine: DNAEngine
    @AppStorage("workspace.autoClearMinutes") private var autoClearMinutes = 15

    private let timeoutOptions = [0, 5, 15, 30, 60]

    var body: some View {
        Form {
            Section("Private workspace") {
                LabeledContent("Product", value: "DNA Engine \(ProductMetadata.displayVersion)")
                LabeledContent("Current mode", value: engine.workspaceMode?.title ?? "No genome in memory")
                LabeledContent("Saved format", value: "AES-256-GCM + This-Device-Only Keychain key")

                Picker("Clear genome from memory after inactivity", selection: $autoClearMinutes) {
                    ForEach(timeoutOptions, id: \.self) { minutes in
                        Text(minutes == 0 ? "Never" : "\(minutes) minutes").tag(minutes)
                    }
                }

                Text("Auto-clear removes parsed variants and reports from this process. It does not delete the encrypted workspace, so you can reopen it later.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Session controls") {
                HStack {
                    Button("Clear Session from Memory") {
                        engine.clearSessionFromMemory()
                    }
                    .disabled(engine.report == nil || engine.isWorking)

                    Button("Reload Encrypted Workspace") {
                        engine.reloadEncryptedWorkspace()
                    }
                    .disabled(engine.report != nil || engine.isWorking || !FileManager.default.fileExists(atPath: AppPaths.privateVault.path))
                }
            }

            Section("Product boundary") {
                Text("Private local product. No cloud account, telemetry, updater, or public repository is required. Scientific panels are research observations, not diagnoses, dosing instructions, or validated kinship calls.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 560, height: 390)
        .padding(12)
    }
}
