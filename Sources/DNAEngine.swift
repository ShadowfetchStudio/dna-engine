import AppKit
import Combine
import Foundation
import SwiftUI
import UniformTypeIdentifiers

extension AppPaths {
    /// AppKit lives here (not in Paths.swift) so the engine files stay
    /// compilable into the UI-free check harness.
    static func reveal(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}

enum GenomeWorkspaceMode: String, CaseIterable, Identifiable {
    case encryptedWorkspace
    case privateSession
    case syntheticDemo

    var id: String { rawValue }

    var title: String {
        switch self {
        case .encryptedWorkspace: return "Encrypted Workspace"
        case .privateSession: return "Private Session"
        case .syntheticDemo: return "Synthetic Demo"
        }
    }

    var detail: String {
        switch self {
        case .encryptedWorkspace:
            return "AES-256-GCM encrypted at rest; the key stays in this Mac's Keychain."
        case .privateSession:
            return "Analyzed in memory and discarded when the app closes or the workspace is cleared."
        case .syntheticDemo:
            return "Deterministic fictional data; never written into your encrypted workspace."
        }
    }
}

private struct PreparedGenome {
    let parsed: ParsedGenome
    let report: AnalysisReport
    let sourcePayload: Data
    let sourceName: String
}

@MainActor
final class DNAEngine: ObservableObject {
    static let shared = DNAEngine()

    @Published var selected: NavItem = .overview
    @Published var search = ""
    @Published var selectedChromosomeFilter = "ALL"
    @Published var status = "Private and offline. DNA never leaves this Mac."
    @Published private(set) var isWorking = false
    @Published private(set) var progress: Double = 0
    @Published private(set) var report: AnalysisReport?
    @Published private(set) var parsedGenome: ParsedGenome?
    @Published var errorMessage: String?
    @Published var selectedHit: MarkerHit?
    @Published var selectedPathway: BiochemicalPathway = .methylation
    @Published private(set) var importReceipt: GenomeImportReceipt?
    @Published private(set) var workspaceMode: GenomeWorkspaceMode?
    @Published private(set) var genomeSearchResults: [SNPCall] = []

    @Published private(set) var secondaryGenome: ParsedGenome?
    @Published private(set) var secondaryFileName: String?
    @Published private(set) var comparisonReport: GenomeComparison?

    private let workspaceStore = PrivateWorkspaceStore()
    private var didBoot = false
    private var operationSequence: UInt64 = 0
    private var operationGeneration = UUID()
    private var comparisonGeneration = UUID()
    private var exportGeneration = UUID()
    private var operationTask: Task<Void, Never>?
    private var comparisonTask: Task<Void, Never>?
    private var genomeSearchTask: Task<Void, Never>?
    private var pdfRenderer: OfflinePDFRenderer?

    func boot() {
        guard !didBoot else { return }
        didBoot = true

        if FileManager.default.fileExists(atPath: AppPaths.privateVault.path) {
            restoreEncryptedWorkspace()
        } else if FileManager.default.fileExists(atPath: AppPaths.genomeCopy.path) {
            migrateLegacyWorkspace()
        } else {
            status = "Choose an encrypted workspace, a memory-only private session, or the synthetic demo."
        }
    }

    func importGenome(mode: GenomeWorkspaceMode = .encryptedWorkspace) {
        guard mode == .encryptedWorkspace || mode == .privateSession else { return }
        guard !isWorking else { return }

        let panel = NSOpenPanel()
        panel.title = mode == .encryptedWorkspace
            ? "Import into Encrypted Workspace"
            : "Open a Memory-Only Private Session"
        panel.allowedContentTypes = [.plainText, .dnaText, .commaSeparatedText, .tabSeparatedText, .gzip, .zip]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.message = "Choose a raw DNA text, CSV, VCF, gzip, or single-file ZIP. Parsing and analysis stay on this Mac."
        guard panel.runModal() == .OK, let url = panel.url else { return }
        startPrimaryImport(url: url, mode: mode)
    }

    func importSecondaryForComparison() {
        guard parsedGenome != nil, !isWorking else { return }
        let panel = NSOpenPanel()
        panel.title = "Open a Second File for Raw Genotype Concordance"
        panel.allowedContentTypes = [.plainText, .dnaText, .commaSeparatedText, .tabSeparatedText, .gzip, .zip]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.message = "The second file is held in memory only. DNA Engine does not infer kinship or a relationship degree."
        guard panel.runModal() == .OK, let url = panel.url else { return }

        comparisonTask?.cancel()
        let generation = UUID()
        comparisonGeneration = generation
        isWorking = true
        errorMessage = nil
        status = "Validating the second file for raw concordance…"
        let hasScopedAccess = url.startAccessingSecurityScopedResource()

        comparisonTask = Task { [weak self] in
            defer {
                if hasScopedAccess { url.stopAccessingSecurityScopedResource() }
            }
            guard let self else { return }
            do {
                let parsed = try await Task.detached(priority: .userInitiated) {
                    try GenomeParser.parse(url: url)
                }.value
                guard self.comparisonGeneration == generation, !Task.isCancelled,
                      let primary = self.parsedGenome, let primaryReport = self.report else { return }

                self.secondaryGenome = parsed
                self.secondaryFileName = url.lastPathComponent
                let comparison = ComparisonEngine.compare(
                    genomeA: primary,
                    nameA: primaryReport.genome.fileName,
                    genomeB: parsed,
                    nameB: url.lastPathComponent
                )
                self.comparisonReport = comparison
                self.selected = .compare
                self.status = "Raw concordance complete across \(comparison.totalComparedSNPs.formatted()) shared called autosomal rsIDs."
                self.isWorking = false
            } catch is CancellationError {
                if self.comparisonGeneration == generation { self.isWorking = false }
            } catch {
                guard self.comparisonGeneration == generation else { return }
                self.isWorking = false
                self.errorMessage = error.localizedDescription
                self.status = "The second file could not be validated."
            }
        }
    }

    func loadDemo() {
        guard !isWorking else { return }
        beginPrimaryOperation(status: "Building the deterministic synthetic genome…") { [weak self] generation in
            guard let self else { return }
            do {
                let prepared = try await self.prepareGenome(
                    data: Data(DemoGenome.makeText().utf8),
                    sourceName: "Synthetic Demo Genome",
                    sourcePath: "synthetic-demo://local",
                    generation: generation
                )
                guard self.isCurrent(generation) else { return }
                self.publish(prepared, mode: .syntheticDemo)
                self.status = "Synthetic demo ready · nothing was saved to the encrypted workspace."
            } catch {
                self.finishFailure(error, generation: generation, message: "The synthetic demo could not be prepared.")
            }
        }
    }

    func clearSessionFromMemory() {
        cancelInFlightWork()
        clearSensitiveMemory()
        status = FileManager.default.fileExists(atPath: AppPaths.privateVault.path)
            ? "Workspace cleared from memory. Reload the encrypted workspace when ready."
            : "Session cleared from memory. No encrypted workspace is stored."
    }

    func reloadEncryptedWorkspace() {
        guard !isWorking, FileManager.default.fileExists(atPath: AppPaths.privateVault.path) else { return }
        restoreEncryptedWorkspace()
    }

    func eraseLocal() {
        selected = .privacy
        status = "Review the live inventory before permanently erasing the local workspace."
    }

    func performVerifiedErase() async -> WorkspaceEraseOutcome {
        cancelInFlightWork()
        clearSensitiveMemory()
        isWorking = true
        status = "Erasing and verifying the private workspace…"

        let outcome = await workspaceStore.eraseEverything()
        isWorking = false
        if outcome.verifiedEmpty {
            status = "Verified: the workspace files are gone and the Keychain key was removed."
        } else {
            let issueCount = outcome.fileResult.survivors.count
                + outcome.fileResult.failures.count
                + (outcome.keyDeletionFailure == nil ? 0 : 1)
            status = "Erase incomplete — \(issueCount) issue(s) require attention in Privacy Center."
        }
        return outcome
    }

    // MARK: - Offline report exports

    func exportReportMarkdown() {
        guard let report else { return }
        writeTextExport(
            ReportExport.markdown(report),
            prefix: "DNA-Engine-Research-Report",
            extension: "md",
            label: "Markdown research report"
        )
    }

    func exportReportHTML() {
        guard let report else { return }
        writeTextExport(
            ReportExport.htmlReport(report),
            prefix: "DNA-Engine-Research-Summary",
            extension: "html",
            label: "HTML research summary"
        )
    }

    func exportPGxResearchBrief() {
        guard let report else { return }
        writeTextExport(
            ReportExport.pgxClinicalBriefHTML(report),
            prefix: "DNA-Engine-Pharmacogenomics-Research-Brief",
            extension: "html",
            label: "pharmacogenomics research brief"
        )
    }

    func exportReportPDF() {
        guard let report, !isWorking else { return }
        let generation = UUID()
        exportGeneration = generation
        let renderer = OfflinePDFRenderer()
        pdfRenderer?.cancel()
        pdfRenderer = renderer
        status = "Rendering a non-persistent PDF offline…"
        renderer.render(html: ReportExport.fullReport(report, format: .html)) { [weak self] result in
            guard let self, self.exportGeneration == generation else { return }
            self.pdfRenderer = nil
            switch result {
            case .success(let data):
                self.writeDataExport(data, prefix: "DNA-Engine-Research-Report", extension: "pdf", label: "PDF research report")
            case .failure(let error):
                self.errorMessage = "PDF rendering failed: \(error.localizedDescription)"
                self.status = "PDF export failed."
            }
        }
    }

    func exportReportJSON() {
        guard let report else { return }
        writeTextExport(
            ReportExport.rawJSON(report),
            prefix: "DNA-Engine-Research-Data",
            extension: "json",
            label: "JSON research data"
        )
    }

    // MARK: - Query and filter helpers

    func hitsForSelection() -> [MarkerHit] {
        guard let report else { return [] }
        var list = AnalysisEngine.hits(in: report, matching: selected)
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if selected == .search || !query.isEmpty {
            list = report.hits.filter { hit in
                query.isEmpty
                    || hit.rsid.lowercased().contains(query)
                    || hit.gene.lowercased().contains(query)
                    || hit.title.lowercased().contains(query)
                    || hit.summary.lowercased().contains(query)
                    || hit.categories.contains(where: { $0.lowercased().contains(query) })
            }
        }
        return list
    }

    func fullGenomeFilteredSNPs() -> [SNPCall] {
        genomeSearchResults
    }

    func scheduleGenomeSearch() {
        genomeSearchTask?.cancel()
        guard let parsed = parsedGenome else {
            genomeSearchResults = []
            return
        }
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let source = selectedChromosomeFilter == "ALL"
            ? parsed.ordered
            : parsed.chromosomeIndex[selectedChromosomeFilter] ?? []
        if query.isEmpty {
            genomeSearchResults = Array(source.prefix(500))
            return
        }

        genomeSearchTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(160))
            guard !Task.isCancelled else { return }
            let matches = await Task.detached(priority: .userInitiated) {
                Array(source.lazy.filter { call in
                    call.rsid.lowercased().contains(query) || String(call.position).contains(query)
                }.prefix(500))
            }.value
            guard !Task.isCancelled else { return }
            self?.genomeSearchResults = matches
        }
    }

    // MARK: - Import lifecycle

    private func startPrimaryImport(url: URL, mode: GenomeWorkspaceMode) {
        let hasScopedAccess = url.startAccessingSecurityScopedResource()
        beginPrimaryOperation(status: "Reading and validating \(url.lastPathComponent)…") { [weak self] generation in
            defer {
                if hasScopedAccess { url.stopAccessingSecurityScopedResource() }
            }
            guard let self else { return }
            do {
                let data = try await Task.detached(priority: .userInitiated) {
                    try Self.readSourceData(url)
                }.value
                let sourcePath = mode == .encryptedWorkspace
                    ? "encrypted-workspace://current"
                    : "private-session://memory"
                let prepared = try await self.prepareGenome(
                    data: data,
                    sourceName: url.lastPathComponent,
                    sourcePath: sourcePath,
                    generation: generation
                )
                guard self.isCurrent(generation) else { return }

                if mode == .encryptedWorkspace {
                    let envelope = Self.makeEnvelope(from: prepared)
                    try await self.workspaceStore.save(envelope, generation: generation)
                    guard self.isCurrent(generation) else { return }
                }
                self.publish(prepared, mode: mode)
            } catch {
                self.finishFailure(error, generation: generation, message: "Import failed without changing the previous workspace.")
            }
        }
    }

    private func restoreEncryptedWorkspace() {
        beginPrimaryOperation(status: "Opening the encrypted private workspace…") { [weak self] generation in
            guard let self else { return }
            do {
                let envelope = try await self.workspaceStore.load(generation: generation)
                let prepared = try await self.prepareGenome(
                    data: envelope.sourcePayload,
                    sourceName: envelope.originalFileName,
                    sourcePath: "encrypted-workspace://current",
                    generation: generation
                )
                guard self.isCurrent(generation) else { return }
                self.publish(prepared, mode: .encryptedWorkspace)
            } catch {
                self.finishFailure(error, generation: generation, message: "The encrypted workspace could not be opened.")
            }
        }
    }

    private func migrateLegacyWorkspace() {
        let legacyURL = AppPaths.genomeCopy
        beginPrimaryOperation(status: "Validating the legacy genome before encrypted migration…") { [weak self] generation in
            guard let self else { return }
            do {
                let data = try await Task.detached(priority: .userInitiated) {
                    try Self.readSourceData(legacyURL)
                }.value
                let prepared = try await self.prepareGenome(
                    data: data,
                    sourceName: "Migrated Local Genome.txt",
                    sourcePath: "encrypted-workspace://current",
                    generation: generation
                )
                guard self.isCurrent(generation) else { return }
                let envelope = Self.makeEnvelope(from: prepared)
                try await self.workspaceStore.migrateLegacy(
                    envelope: envelope,
                    legacySource: legacyURL,
                    generation: generation
                )
                guard self.isCurrent(generation) else { return }
                self.publish(prepared, mode: .encryptedWorkspace)
                self.status = "Legacy genome migrated into the verified encrypted workspace."
            } catch {
                self.finishFailure(
                    error,
                    generation: generation,
                    message: "Encrypted migration failed. The legacy file was preserved unchanged."
                )
            }
        }
    }

    private func beginPrimaryOperation(
        status: String,
        body: @escaping (UUID) async -> Void
    ) {
        cancelInFlightWork()
        clearComparison()
        let generation = UUID()
        operationSequence &+= 1
        let sequence = operationSequence
        operationGeneration = generation
        isWorking = true
        errorMessage = nil
        progress = 0.01
        self.status = status
        operationTask = Task { [weak self] in
            guard let self else { return }
            let activated = await self.workspaceStore.activate(generation, sequence: sequence)
            guard activated, self.isCurrent(generation) else {
                await self.workspaceStore.deactivate(generation)
                return
            }
            await body(generation)
            await self.workspaceStore.deactivate(generation)
        }
    }

    private func prepareGenome(
        data: Data,
        sourceName: String,
        sourcePath: String,
        generation: UUID
    ) async throws -> PreparedGenome {
        try await Task.detached(priority: .userInitiated) { [weak self] in
            let parsed = try GenomeParser.parse(data: data, sourceName: sourceName) { fraction, message in
                Task { @MainActor [weak self] in
                    guard let self, self.isCurrent(generation) else { return }
                    self.progress = 0.05 + fraction * 0.58
                    self.status = message
                }
            }
            try Task.checkCancellation()
            Task { @MainActor [weak self] in
                guard let self, self.isCurrent(generation) else { return }
                self.progress = 0.72
                self.status = "Computing local research observations with coverage and orientation safeguards…"
            }
            let metadata = GenomeStats.summarize(parsed: parsed, sourcePath: sourcePath, fileName: sourceName)
            let report = AnalysisEngine.analyze(parsed: parsed, meta: metadata)
            try Task.checkCancellation()
            return PreparedGenome(parsed: parsed, report: report, sourcePayload: data, sourceName: sourceName)
        }.value
    }

    private func publish(_ prepared: PreparedGenome, mode: GenomeWorkspaceMode) {
        parsedGenome = prepared.parsed
        report = prepared.report
        importReceipt = prepared.parsed.receipt
        workspaceMode = mode
        selected = .overview
        progress = 1
        isWorking = false
        status = "\(prepared.report.genome.calledCount.formatted()) called variants · \(prepared.report.catalogCoverage.matched) orientation-safe catalog observations · \(mode.title)"
        scheduleGenomeSearch()
    }

    private func finishFailure(_ error: Error, generation: UUID, message: String) {
        guard isCurrent(generation) else { return }
        isWorking = false
        if !(error is CancellationError) {
            errorMessage = "\(message)\n\n\(error.localizedDescription)"
            status = message
        }
    }

    private func isCurrent(_ generation: UUID) -> Bool {
        operationGeneration == generation && !Task.isCancelled
    }

    private func cancelInFlightWork() {
        operationTask?.cancel()
        comparisonTask?.cancel()
        genomeSearchTask?.cancel()
        operationTask = nil
        comparisonTask = nil
        genomeSearchTask = nil
        operationGeneration = UUID()
        comparisonGeneration = UUID()
        exportGeneration = UUID()
        pdfRenderer?.cancel()
        pdfRenderer = nil
    }

    private func clearSensitiveMemory() {
        report = nil
        parsedGenome = nil
        importReceipt = nil
        workspaceMode = nil
        selectedHit = nil
        clearComparison()
        search = ""
        selectedChromosomeFilter = "ALL"
        genomeSearchResults = []
        progress = 0
        isWorking = false
    }

    private func clearComparison() {
        secondaryGenome = nil
        secondaryFileName = nil
        comparisonReport = nil
    }

    private nonisolated static func readSourceData(_ url: URL) throws -> Data {
        let values = try url.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey, .fileSizeKey])
        guard values.isRegularFile == true, values.isSymbolicLink != true else {
            throw GenomeImportError.sourceIsNotRegularFile
        }
        let limit = GenomeImportLimits.standard.maximumInputBytes
        if let size = values.fileSize, size > limit {
            throw GenomeImportError.inputLimitExceeded(actual: size, limit: limit)
        }
        let data = try Data(contentsOf: url, options: [.mappedIfSafe])
        guard data.count <= limit else {
            throw GenomeImportError.inputLimitExceeded(actual: data.count, limit: limit)
        }
        return data
    }

    private nonisolated static func makeEnvelope(from prepared: PreparedGenome) -> PrivateGenomeEnvelope {
        let receipt = prepared.parsed.receipt
        return PrivateGenomeEnvelope(
            originalFileName: prepared.sourceName,
            originalFileExtension: receipt.source.originalExtension ?? "",
            sourceSHA256: PrivateGenomeVault.sha256Hex(prepared.sourcePayload),
            importedAt: prepared.report.genome.importedAt,
            vendor: prepared.parsed.vendor.rawValue,
            genomeBuildHint: prepared.parsed.buildHint,
            parserVersion: ProductMetadata.parserVersion,
            catalogVersion: ProductMetadata.knowledgeVersion,
            acceptedCallCount: receipt.diagnostics.acceptedRecords,
            skippedRecordCount: receipt.diagnostics.skippedRecords,
            sourcePayload: prepared.sourcePayload
        )
    }

    // MARK: - Secure export helpers

    private func writeTextExport(_ text: String, prefix: String, extension ext: String, label: String) {
        guard let data = text.data(using: .utf8) else { return }
        writeDataExport(data, prefix: prefix, extension: ext, label: label)
    }

    private func writeDataExport(_ data: Data, prefix: String, extension ext: String, label: String) {
        let url = uniqueReportURL(prefix: prefix, extension: ext)
        do {
            try data.write(to: url, options: [.atomic])
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
            AppPaths.reveal(url)
            status = "Wrote \(label): \(url.lastPathComponent)"
        } catch {
            errorMessage = error.localizedDescription
            status = "Export failed."
        }
    }

    private func uniqueReportURL(prefix: String, extension ext: String) -> URL {
        let milliseconds = Int64((Date().timeIntervalSince1970 * 1_000).rounded())
        let suffix = UUID().uuidString.prefix(8)
        return AppPaths.reports.appendingPathComponent("\(prefix)-\(milliseconds)-\(suffix).\(ext)")
    }
}

extension UTType {
    static var dnaText: UTType { UTType(filenameExtension: "txt") ?? .plainText }
}
