import Darwin
import Foundation

enum LocalPathSafetyError: LocalizedError {
    case unsafePath

    var errorDescription: String? {
        "The local workspace path is a symbolic link or is not a regular local directory."
    }
}

enum LocalPathSafety {
    static func requireDirectory(
        _ url: URL,
        createIfMissing: Bool,
        permissions: Int = 0o700
    ) throws -> URL {
        guard url.isFileURL, !url.lastPathComponent.isEmpty else {
            throw LocalPathSafetyError.unsafePath
        }

        let directory = url.standardizedFileURL
        switch try nodeKind(at: directory) {
        case .directory:
            break
        case .missing where createIfMissing:
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true,
                attributes: [.posixPermissions: permissions]
            )
            guard try nodeKind(at: directory) == .directory else {
                throw LocalPathSafetyError.unsafePath
            }
        case .missing, .regularFile, .other:
            throw LocalPathSafetyError.unsafePath
        }

        try FileManager.default.setAttributes(
            [.posixPermissions: permissions],
            ofItemAtPath: directory.path
        )
        guard try nodeKind(at: directory) == .directory else {
            throw LocalPathSafetyError.unsafePath
        }
        return directory
    }

    static func requireRegularFile(_ url: URL) throws {
        guard url.isFileURL, try nodeKind(at: url.standardizedFileURL) == .regularFile else {
            throw LocalPathSafetyError.unsafePath
        }
    }

    static func exists(_ url: URL) throws -> Bool {
        try nodeKind(at: url.standardizedFileURL) != .missing
    }

    private enum NodeKind: Equatable {
        case missing
        case directory
        case regularFile
        case other
    }

    private static func nodeKind(at url: URL) throws -> NodeKind {
        var info = stat()
        let result = url.path.withCString { Darwin.lstat($0, &info) }
        if result == 0 {
            switch info.st_mode & S_IFMT {
            case S_IFDIR: return .directory
            case S_IFREG: return .regularFile
            default: return .other
            }
        }
        if errno == ENOENT { return .missing }
        throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno))
    }
}

enum AppPaths {
    /// Test harness override: when set, all app files live under this directory.
    /// The check CLI points this at a scratch sandbox to regression-test erase.
    nonisolated(unsafe) static var overrideSupport: URL?

    /// A child of a character device can never be created or traversed as a
    /// directory. Non-throwing display paths use this only after validation
    /// has failed, so legacy callers fail closed instead of following an
    /// unsafe configured symlink.
    private static let inaccessibleFallback = URL(
        fileURLWithPath: "/dev/null/DNAEngine-unsafe-workspace",
        isDirectory: true
    )

    static var support: URL {
        (try? requireSafeSupportDirectory()) ?? inaccessibleFallback
    }

    static func requireSafeSupportDirectory(createIfMissing: Bool = true) throws -> URL {
        try LocalPathSafety.requireDirectory(configuredSupport, createIfMissing: createIfMissing)
    }

    private static var configuredSupport: URL {
        if let overrideSupport { return overrideSupport }
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("DNAEngine", isDirectory: true)
    }

    static var privateVault: URL { support.appendingPathComponent("workspace.dnavault") }
    /// Read only by the one-time encrypted migration path. New imports never
    /// write plaintext here.
    static var genomeCopy: URL { support.appendingPathComponent("imported_genome.txt") }
    static var secondaryGenomeCopy: URL { support.appendingPathComponent("secondary_genome.txt") }
    static var meta: URL { support.appendingPathComponent("genome_meta.json") }
    static var demoGenome: URL { support.appendingPathComponent("demo_genome.txt") }

    static var profiles: URL {
        guard let root = try? requireSafeSupportDirectory() else {
            return inaccessibleFallback.appendingPathComponent("Profiles", isDirectory: true)
        }
        let dir = root.appendingPathComponent("Profiles", isDirectory: true)
        return (try? LocalPathSafety.requireDirectory(dir, createIfMissing: true))
            ?? inaccessibleFallback.appendingPathComponent("Profiles", isDirectory: true)
    }

    static var reports: URL {
        guard let root = try? requireSafeSupportDirectory() else {
            return inaccessibleFallback.appendingPathComponent("Reports", isDirectory: true)
        }
        let dir = root.appendingPathComponent("Reports", isDirectory: true)
        return (try? LocalPathSafety.requireDirectory(dir, createIfMissing: true))
            ?? inaccessibleFallback.appendingPathComponent("Reports", isDirectory: true)
    }
}

/// UI-free erase engine (feature 11) — compiled into the check harness so the
/// "no leftover files" guarantee is regression-tested, not asserted.
///
/// MARK: PRIVACY CONTRACT — any NEW persisted file added to this app MUST be
/// added BOTH to `knownFiles`/`knownDirectories` here AND to the Privacy
/// Center enumeration table, or the "Verified: 0 files remain" claim becomes
/// a lie. (Future features: annotations/favorites land here first.)
enum LocalEraser {
    static var knownFiles: [URL] {
        [AppPaths.privateVault, AppPaths.genomeCopy, AppPaths.secondaryGenomeCopy, AppPaths.meta, AppPaths.demoGenome]
    }

    static var knownDirectories: [URL] {
        [AppPaths.reports, AppPaths.profiles]
    }

    struct Entry: Identifiable, Hashable {
        var id: String { path }
        var path: String
        var name: String
        var bytes: Int64
        var modified: Date?
        var explanation: String
    }

    struct Failure: Identifiable, Hashable {
        var id: String { "\(operation):\(path):\(message)" }
        var operation: String
        var path: String
        var message: String
    }

    struct EraseResult: Hashable {
        var survivors: [Entry]
        var failures: [Failure]
        var verifiedEmpty: Bool { survivors.isEmpty && failures.isEmpty }
    }

    static func explanation(for name: String) -> String {
        switch name {
        case "workspace.dnavault": return "AES-GCM encrypted private genome workspace"
        case "imported_genome.txt": return "Legacy plaintext genome awaiting encrypted migration"
        case "secondary_genome.txt": return "Legacy second-genome file; new comparisons are memory-only"
        case "genome_meta.json": return "Legacy plaintext import metadata"
        case "demo_genome.txt": return "Legacy demo file; the current synthetic demo is memory-only"
        case "Reports": return "Exported reports still inside the app folder"
        case "Profiles": return "Saved profile data"
        default: return "Application Support file"
        }
    }

    /// Everything currently on disk under the app's support directory.
    static func inventory() throws -> [Entry] {
        let fm = FileManager.default
        let root = try AppPaths.requireSafeSupportDirectory()
        let items = try fm.contentsOfDirectory(at: root, includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey, .isDirectoryKey])
        var out: [Entry] = []
        for url in items.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            let vals = try? url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey, .isDirectoryKey])
            var bytes = Int64(vals?.fileSize ?? 0)
            if vals?.isDirectory == true {
                bytes = directorySize(url)
            }
            out.append(Entry(
                path: url.path,
                name: url.lastPathComponent,
                bytes: bytes,
                modified: vals?.contentModificationDate,
                explanation: explanation(for: url.lastPathComponent)
            ))
        }
        return out
    }

    /// Compatibility accessor for non-critical display code. Privacy-sensitive
    /// erase verification must use `inventory()` or `eraseAllVerified()` so an
    /// I/O error cannot be confused with an empty directory.
    static func enumerate() -> [Entry] {
        (try? inventory()) ?? []
    }

    private static func directorySize(_ url: URL) -> Int64 {
        let fm = FileManager.default
        guard let en = fm.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
        var total: Int64 = 0
        for case let f as URL in en {
            total += Int64((try? f.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0)
        }
        return total
    }

    /// Deletes every known file AND every other file found in the support
    /// directory (including the previously-leaked Reports directory), then
    /// re-enumerates. Returns the surviving entries — empty means verified.
    @discardableResult
    static func eraseAllVerified() -> EraseResult {
        let fm = FileManager.default
        let root: URL
        var failures: [Failure] = []
        do {
            root = try AppPaths.requireSafeSupportDirectory()
        } catch {
            let path = AppPaths.overrideSupport?.path ?? "Application Support/DNAEngine"
            return EraseResult(
                survivors: [],
                failures: [Failure(operation: "validate-support-root", path: path, message: error.localizedDescription)]
            )
        }
        let candidates: [URL]
        do {
            candidates = try fm.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)
        } catch {
            return EraseResult(
                survivors: [],
                failures: [Failure(operation: "enumerate-before-erase", path: root.path, message: error.localizedDescription)]
            )
        }
        for url in candidates {
            do {
                try fm.removeItem(at: url)
            } catch {
                failures.append(Failure(operation: "delete", path: url.path, message: error.localizedDescription))
            }
        }
        do {
            return EraseResult(survivors: try inventory(), failures: failures)
        } catch {
            failures.append(Failure(operation: "verify", path: root.path, message: error.localizedDescription))
            return EraseResult(survivors: [], failures: failures)
        }
    }

    /// Kept for the pre-3.0 deterministic fixture while callers migrate to the
    /// explicit result. A failure is represented by a synthetic survivor so it
    /// can never be mistaken for verified-empty.
    @discardableResult
    static func eraseAll() -> [Entry] {
        let result = eraseAllVerified()
        guard result.failures.isEmpty else {
            return result.survivors + result.failures.map {
                Entry(path: $0.path, name: "Erase error", bytes: 0, modified: nil, explanation: $0.message)
            }
        }
        return result.survivors
    }
}
