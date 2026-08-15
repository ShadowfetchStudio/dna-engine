import SwiftUI

// 2.0 view layer: QC dashboard (f6), ROH section (f7), Limits panel (f8),
// euro-bias banner (f8), filter rail (f9), Privacy Center (f11).

// MARK: - Shared euro-bias / transferability banner (feature 8)

struct EuroBiasBanner: View {
    var report: AnalysisReport
    var extraLine: String? = nil

    var body: some View {
        if let text = HonestyEngine.euroBiasBanner(report: report) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "globe")
                    .foregroundStyle(Theme.warning)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ancestry transferability note")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Theme.warning)
                    Text(text)
                        .font(.caption)
                        .foregroundStyle(Theme.textMed)
                        .fixedSize(horizontal: false, vertical: true)
                    if let extraLine {
                        Text(extraLine)
                            .font(.caption2)
                            .foregroundStyle(Theme.textLow)
                    }
                }
            }
            .padding(10)
            .background(Theme.warning.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.warning.opacity(0.35), lineWidth: 1))
        }
    }
}

// MARK: - "Limits of this analysis →" header link (feature 8)

struct LimitsLink: View {
    @EnvironmentObject private var engine: DNAEngine

    var body: some View {
        Button {
            engine.selected = .limits
        } label: {
            Label("Limits of this analysis", systemImage: "eye.slash")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.warning)
        }
        .buttonStyle(.plain)
        .help("What this file and this app cannot tell you")
    }
}

// MARK: - Filter rail (feature 9) — shared pill row

struct FilterRail: View {
    @Binding var evidence: EvidenceLevel?
    @Binding var tier: String?
    @Binding var coverage: MarkerHit.Coverage?

    private let tiers = ["well-replicated", "replicated", "tendency"]
    private let coverages: [(MarkerHit.Coverage, String)] = [
        (.matched, "Matched"), (.noCall, "No-Call"), (.missing, "Not On Chip"),
        (.strandAmbiguous, "Strand Unresolved"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text("EVIDENCE:")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.textLow)
                FilterChip(title: "All", isSelected: evidence == nil && tier == nil) {
                    evidence = nil; tier = nil
                }
                ForEach(EvidenceLevel.allCases, id: \.self) { ev in
                    FilterChip(title: ev.label, isSelected: evidence == ev) {
                        evidence = (evidence == ev) ? nil : ev
                    }
                }
                ForEach(tiers, id: \.self) { t in
                    FilterChip(title: t.capitalized, isSelected: tier == t) {
                        tier = (tier == t) ? nil : t
                    }
                }
                Spacer()
            }
            HStack(spacing: 8) {
                Text("COVERAGE:")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.textLow)
                FilterChip(title: "All", isSelected: coverage == nil) { coverage = nil }
                ForEach(coverages, id: \.0) { cov, label in
                    FilterChip(title: label, isSelected: coverage == cov) {
                        coverage = (coverage == cov) ? nil : cov
                    }
                }
                Spacer()
            }
        }
    }
}

// MARK: - ROH section (feature 7)

struct ROHSectionView: View {
    var roh: ROHReport

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Autozygosity (Runs of Homozygosity)")
                    .font(.headline)
                    .foregroundStyle(Theme.textHi)
                Spacer()
                Text("\(roh.regions.count) runs ≥3 Mb")
                    .font(.caption.monospaced())
                    .foregroundStyle(Theme.gold)
            }

            Text("Array-based estimate of autozygosity, not a clinical consanguinity determination. Founder-population background can mimic elevated F, chip density limits short-run detection, and none of this speaks to any specific recessive condition.")
                .font(.caption)
                .foregroundStyle(Theme.textMed)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                StatChip(label: "F_ROH", value: String(format: "%.4f", roh.fROH),
                         sublabel: String(format: "over %.0f Mb observed span", roh.autosomalCoveredMb), icon: "function")
                StatChip(label: "Longest Run", value: String(format: "%.1f Mb", roh.longestMb),
                         sublabel: roh.longestMb > 16 ? "long class (>16 Mb)" : (roh.longestMb > 8 ? "medium class" : "short class"),
                         icon: "ruler")
                StatChip(label: "Class Totals", value: String(format: "%.0f/%.0f/%.0f Mb", roh.classShortMb, roh.classMediumMb, roh.classLongMb),
                         sublabel: "short 3–8 · medium 8–16 · long >16", icon: "square.stack.3d.up")
            }

            Text(roh.interpretation)
                .font(.callout)
                .foregroundStyle(Theme.textHi)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(roh.regions.prefix(12)) { r in
                HStack {
                    Text("chr\(r.chromosome)")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.gold)
                    Text("\(r.start.formatted())–\(r.end.formatted())")
                        .font(.caption.monospaced())
                        .foregroundStyle(Theme.textMed)
                    Spacer()
                    Text(r.lengthClass.rawValue.uppercased())
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(r.lengthClass == .long ? Theme.warning : Theme.textLow)
                    Text(String(format: "%.2f Mb", r.lengthMb))
                        .font(.caption.weight(.bold).monospaced())
                        .foregroundStyle(Theme.teal)
                    Text("(\(r.snpCount) SNPs)")
                        .font(.caption2.monospaced())
                        .foregroundStyle(Theme.textLow)
                }
                .padding(.vertical, 2)
            }
        }
        .dnaCard()
    }
}

// MARK: - QC dashboard (feature 6)

struct QCView: View {
    @EnvironmentObject private var engine: DNAEngine
    var report: AnalysisReport { engine.report! }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Genome Quality Control")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Theme.textHi)
                        Text("Pure file forensics — how trustworthy is this raw file, before any interpretation. Zero phenotype claims on this page.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textMed)
                    }
                    Spacer()
                    LimitsLink()
                    QCBadge(grade: report.qc.worstGrade)
                }

                HStack(spacing: 12) {
                    StatChip(label: "Build Detected", value: report.qc.buildCall, sublabel: "from sentinel positions", icon: "map")
                    StatChip(label: "Complement Flips", value: "\(report.qc.complementFlippedMatches)", sublabel: "markers matched on opposite strand", icon: "arrow.left.arrow.right")
                    StatChip(label: "Palindromic Sites", value: "\(report.qc.palindromicMatched)", sublabel: "A/T & C/G — never strand-verifiable", icon: "exclamationmark.arrow.circlepath")
                }

                if let receipt = engine.importReceipt {
                    ImportReceiptView(receipt: receipt, mode: engine.workspaceMode)
                }

                Text(report.qc.chipFingerprint)
                    .font(.callout.monospaced())
                    .foregroundStyle(Theme.teal)
                    .dnaCard()

                // Catalog reach BEFORE interpretation (feature 6): per-section
                // matched / no-call / not-on-chip breakdown.
                VStack(alignment: .leading, spacing: 8) {
                    Text("CATALOG REACH — what this file can and cannot answer")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.teal)
                    Text("Disclosed before interpretation: per-domain coverage of the \(report.catalogCoverage.total)-marker catalog on this specific file.")
                        .font(.caption)
                        .foregroundStyle(Theme.textMed)
                    ForEach(ReportExport.domainSections, id: \.self) { nav in
                        let slice = AnalysisEngine.hits(in: report, matching: nav)
                        let matched = slice.filter { $0.coverage == .matched }.count
                        let noCall = slice.filter { $0.coverage == .noCall }.count
                        let missing = slice.filter { $0.coverage == .missing }.count
                        let strandAmbiguous = slice.filter { $0.coverage == .strandAmbiguous }.count
                        HStack {
                            Label(nav.title, systemImage: nav.systemImage)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Theme.textHi)
                            Spacer()
                            Text("\(matched) matched")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(Theme.success)
                            Text("· \(noCall) no-call")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(Theme.warning)
                            Text("· \(missing) not on chip")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(Theme.textLow)
                            Text("· \(strandAmbiguous) strand-unresolved")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(Theme.warning)
                        }
                        .padding(.vertical, 1)
                    }
                }
                .dnaCard()

                ForEach(report.qc.checks) { check in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(check.title)
                                .font(.headline)
                                .foregroundStyle(Theme.textHi)
                            Spacer()
                            QCBadge(grade: check.grade)
                        }
                        Text(check.summary)
                            .font(.callout)
                            .foregroundStyle(Theme.textMed)
                            .fixedSize(horizontal: false, vertical: true)
                        ForEach(check.details, id: \.self) { d in
                            HStack(alignment: .top, spacing: 6) {
                                Text("·").foregroundStyle(Theme.textLow)
                                Text(d).font(.caption.monospaced()).foregroundStyle(Theme.textLow)
                            }
                        }
                    }
                    .dnaCard()
                }

                DisclaimerBanner()
            }
            .padding(22)
        }
        .background(Theme.bgDeep)
    }
}

struct ImportReceiptView: View {
    let receipt: GenomeImportReceipt
    let mode: GenomeWorkspaceMode?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("VERIFIED IMPORT RECEIPT")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.teal)
                    Text(receipt.source.displayName)
                        .font(.headline)
                        .foregroundStyle(Theme.textHi)
                }
                Spacer()
                Text(mode?.title.uppercased() ?? "LOCAL SESSION")
                    .font(.system(size: 9, weight: .heavy, design: .monospaced))
                    .foregroundStyle(Theme.gold)
            }

            HStack(spacing: 12) {
                receiptMetric("Container", receipt.source.detectedContainer.rawValue)
                receiptMetric("Format", receipt.detectedFormat.rawValue)
                receiptMetric("Accepted", receipt.diagnostics.acceptedRecords.formatted())
                receiptMetric("Skipped", receipt.diagnostics.skippedRecords.formatted())
                receiptMetric("No-call", receipt.diagnostics.noCallRecords.formatted())
            }

            Text("\(ByteCountFormatter.string(fromByteCount: Int64(receipt.source.inputByteCount), countStyle: .file)) input · \(ByteCountFormatter.string(fromByteCount: Int64(receipt.source.expandedByteCount), countStyle: .file)) validated content")
                .font(.caption.monospaced())
                .foregroundStyle(Theme.textMed)

            if let archive = receipt.archive {
                Label(
                    "\(archive.container.rawValue.uppercased()) checksum validated · exactly one safe regular member\(archive.memberName.map { ": \($0)" } ?? "")",
                    systemImage: "checkmark.seal.fill"
                )
                .font(.caption)
                .foregroundStyle(Theme.success)
            }

            if let selection = receipt.selectedVCFSample {
                Text("VCF sample: \(selection.selectedSample) · \(selection.mode.rawValue) · \(selection.availableSamples.count) available")
                    .font(.caption.monospaced())
                    .foregroundStyle(Theme.textMed)
            }

            ForEach(Array(receipt.notices.enumerated()), id: \.offset) { _, notice in
                Label(notice.message, systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(Theme.warning)
            }

            if receipt.diagnostics.skippedRecords > 0 {
                Text("Rejected records: \(receipt.diagnostics.malformedRecords) malformed · \(receipt.diagnostics.unsupportedRecords) unsupported · \(receipt.diagnostics.duplicateRecords) duplicate · \(receipt.diagnostics.conflictRecords) conflicting")
                    .font(.caption.monospaced())
                    .foregroundStyle(Theme.textLow)
            }
        }
        .dnaCard()
    }

    private func receiptMetric(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.textLow)
            Text(value)
                .font(.caption.weight(.semibold).monospaced())
                .foregroundStyle(Theme.textHi)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct QCBadge: View {
    var grade: QCGrade

    private var color: Color {
        switch grade {
        case .pass: return Theme.success
        case .warn: return Theme.warning
        case .fail: return Theme.danger
        }
    }

    var body: some View {
        Text(grade.rawValue.uppercased())
            .font(.system(size: 10, weight: .heavy, design: .monospaced))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .foregroundStyle(color)
            .background(color.opacity(0.14), in: Capsule())
            .overlay(Capsule().stroke(color.opacity(0.4), lineWidth: 0.8))
    }
}

// MARK: - Limits panel (feature 8)

struct LimitsView: View {
    @EnvironmentObject private var engine: DNAEngine
    var report: AnalysisReport { engine.report! }
    @State private var categoryFilter: String? = nil

    private var honesty: HonestyReport {
        HonestyEngine.build(report: report, qc: report.qc)
    }

    private let categories = ["this-file", "structural", "resolution", "statistical"]

    var body: some View {
        let h = honesty
        return ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("What This Can't Tell You")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Theme.textHi)
                    Text("The most important page in this app. Consumer arrays are narrow instruments; every claim elsewhere stands on the limits listed here. This section is also appended, unconditionally, to every exported report.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textMed)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 8) {
                    FilterChip(title: "All", isSelected: categoryFilter == nil) { categoryFilter = nil }
                    ForEach(categories, id: \.self) { cat in
                        FilterChip(title: cat == "this-file" ? "This File" : cat.capitalized, isSelected: categoryFilter == cat) {
                            categoryFilter = (categoryFilter == cat) ? nil : cat
                        }
                    }
                }

                EuroBiasBanner(report: report)

                ForEach(h.all.filter { categoryFilter == nil || $0.category == categoryFilter }) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(item.title)
                                .font(.headline)
                                .foregroundStyle(Theme.textHi)
                            Spacer()
                            Text(item.category.uppercased())
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(item.category == "this-file" ? Theme.teal : Theme.textLow)
                        }
                        Text(item.explanation)
                            .font(.callout)
                            .foregroundStyle(Theme.textMed)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(item.pmidNote)
                            .font(.caption.monospaced())
                            .foregroundStyle(Theme.textLow)
                            .textSelection(.enabled)
                    }
                    .dnaCard()
                }
            }
            .padding(22)
        }
        .background(Theme.bgDeep)
    }
}

// MARK: - Privacy Center (feature 11)

struct PrivacyView: View {
    @EnvironmentObject private var engine: DNAEngine
    @State private var entries: [LocalEraser.Entry] = []
    @State private var confirmErase = false
    @State private var verdict: String? = nil
    @State private var inventoryFailure: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Privacy Center")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Theme.textHi)
                    Text("Exactly what exists on disk, and a verified way to remove it.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textMed)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("THE ACTUAL GUARANTEES")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.teal)
                    bullet("DNA Engine has no account, analytics SDK, telemetry, update checker, web-service client, or socket client. The private release checks scan both source and product for forbidden networking surfaces.")
                    bullet("A saved genome is stored as authenticated AES-256-GCM ciphertext in workspace.dnavault. Its 256-bit key is a This-Device-Only Keychain item available only while the Mac user session is unlocked.")
                    bullet("A Private Session and the Synthetic Demo are memory-only. They never replace or write the encrypted workspace.")
                    bullet("Offline report rendering uses a non-persistent WebKit data store with JavaScript disabled and rejects external navigation.")
                    bullet("The live table enumerates DNA Engine's Application Support directory. An inventory error is shown as an error, never as an empty directory.")
                    bullet("Honest limit: reports you exported and MOVED elsewhere (Desktop, email, AirDrop) are outside this app's reach — deleting those is up to you.")
                }
                .dnaCard()

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Files on disk right now")
                            .font(.headline)
                            .foregroundStyle(Theme.textHi)
                        Spacer()
                        Button {
                            refreshInventory()
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                        Button("Reveal in Finder") { AppPaths.reveal(AppPaths.support) }
                    }

                    if let inventoryFailure {
                        Text("Inventory failed: \(inventoryFailure)")
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(Theme.danger)
                    } else if entries.isEmpty {
                        Text("No files found — the support directory is empty.")
                            .font(.callout)
                            .foregroundStyle(Theme.success)
                    } else {
                        ForEach(entries) { e in
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(e.name)
                                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                        .foregroundStyle(Theme.textHi)
                                    Text(e.explanation)
                                        .font(.caption)
                                        .foregroundStyle(Theme.textMed)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(ByteCountFormatter.string(fromByteCount: e.bytes, countStyle: .file))
                                        .font(.caption.monospaced())
                                        .foregroundStyle(Theme.teal)
                                    if let m = e.modified {
                                        Text(m.formatted(date: .abbreviated, time: .shortened))
                                            .font(.caption2.monospaced())
                                            .foregroundStyle(Theme.textLow)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                            Divider()
                        }
                    }
                }
                .dnaCard()

                VStack(alignment: .leading, spacing: 10) {
                    Text("Erase Everything")
                        .font(.headline)
                        .foregroundStyle(Theme.danger)
                    Text("Cancels active import and PDF work, clears genomic state from memory, deletes the encrypted workspace and local reports, removes the workspace Keychain key, then independently re-enumerates the directory.")
                        .font(.callout)
                        .foregroundStyle(Theme.textMed)
                    if let verdict {
                        Text(verdict)
                            .font(.callout.weight(.bold).monospaced())
                            .foregroundStyle(verdict.hasPrefix("Verified") ? Theme.success : Theme.danger)
                    }
                    Button(role: .destructive) {
                        refreshInventory()
                        if inventoryFailure == nil { confirmErase = true }
                    } label: {
                        Label("Erase Everything…", systemImage: "trash.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.danger.opacity(0.85))
                    .disabled(engine.isWorking || inventoryFailure != nil)
                }
                .dnaCard()
            }
            .padding(22)
        }
        .background(Theme.bgDeep)
        .onAppear { refreshInventory() }
        .confirmationDialog(
            "Erase all local DNA data?",
            isPresented: $confirmErase,
            titleVisibility: .visible
        ) {
            Button("Erase \(entries.count) item(s) permanently", role: .destructive) {
                Task {
                    let outcome = await engine.performVerifiedErase()
                    entries = outcome.fileResult.survivors
                    if outcome.verifiedEmpty {
                        inventoryFailure = nil
                        verdict = "Verified: workspace files are gone and the Keychain key was removed."
                    } else {
                        let fileIssues = outcome.fileResult.failures.map { "\($0.operation): \($0.message)" }
                        let survivors = outcome.fileResult.survivors.map { "survived: \($0.name)" }
                        let keyIssue = outcome.keyDeletionFailure.map { ["Keychain: \($0)"] } ?? []
                        verdict = "WARNING — " + (fileIssues + survivors + keyIssue).joined(separator: " · ")
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Will delete: \(entries.map(\.name).joined(separator: ", ")). Exported reports you moved outside the app folder are not affected.")
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•").foregroundStyle(Theme.teal)
            Text(text)
                .font(.callout)
                .foregroundStyle(Theme.textMed)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func refreshInventory() {
        do {
            entries = try LocalEraser.inventory()
            inventoryFailure = nil
        } catch {
            entries = []
            inventoryFailure = error.localizedDescription
        }
    }
}
