import SwiftUI

struct ImportView: View {
    @EnvironmentObject private var engine: DNAEngine

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            HStack(alignment: .center, spacing: 48) {
                HelixView()
                    .frame(width: 140, height: 260)
                
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 8) {
                        Text("DNA ENGINE")
                            .font(.caption.weight(.bold).monospaced())
                            .foregroundStyle(Theme.teal)
                        Text("PRIVATE GENOMICS WORKBENCH")
                            .font(.system(size: 9, weight: .heavy, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .foregroundStyle(Theme.gold)
                            .background(Theme.gold.opacity(0.15), in: Capsule())
                    }

                    Text("Encrypted, On-Device\nGenomics Research")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(Theme.textHi)

                    Text("Validate raw DNA from common consumer exports or standard VCF files (.txt, .csv, .vcf, .gz, .zip). Choose an AES-GCM encrypted workspace or a memory-only private session. Research observations are coverage-aware, orientation-safe, provenance-labeled, and explicit about what an array cannot establish.")
                        .foregroundStyle(Theme.textMed)
                        .font(.callout)
                        .frame(maxWidth: 540, alignment: .leading)

                    HStack(spacing: 12) {
                        Button {
                            engine.importGenome(mode: .encryptedWorkspace)
                        } label: {
                            Label("Encrypted Workspace", systemImage: "lock.doc.fill")
                                .padding(.horizontal, 8)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.teal)

                        Button {
                            engine.importGenome(mode: .privateSession)
                        } label: {
                            Label("Private Session", systemImage: "memorychip")
                        }
                        .buttonStyle(.bordered)

                        Button {
                            engine.loadDemo()
                        } label: {
                            Label("Synthetic Demo", systemImage: "sparkles")
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.top, 4)
                    .disabled(engine.isWorking)

                    HStack(spacing: 16) {
                        Label("Bounded Gzip / ZIP / VCF", systemImage: "doc.zipper")
                        Label("AES-256-GCM + Keychain", systemImage: "lock.shield.fill")
                        Label("No Cloud Account", systemImage: "icloud.slash")
                    }
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(Theme.textLow)
                }
            }
            .padding(40)
            Spacer()
            DisclaimerBanner()
                .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bgDeep)
    }
}
