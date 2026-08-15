import CryptoKit
import Foundation

@main
enum VaultCheckMain {
    static func main() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("dnaengine-vault-check-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let keyA = FixedPrivateVaultKeyProvider(key: SymmetricKey(size: .bits256))
        let keyB = FixedPrivateVaultKeyProvider(key: SymmetricKey(size: .bits256))
        let payload = Data("rs12345\t1\t100\tA\tG\nrs67890\t2\t200\tC\tC\n".utf8)
        let envelope = PrivateGenomeEnvelope(
            originalFileName: "private-sample.txt",
            originalFileExtension: "txt",
            sourceSHA256: PrivateGenomeVault.sha256Hex(payload),
            importedAt: Date(timeIntervalSince1970: 1_700_000_000),
            vendor: "Fixture",
            genomeBuildHint: "GRCh37",
            parserVersion: "3",
            catalogVersion: "fixture",
            acceptedCallCount: 2,
            skippedRecordCount: 0,
            sourcePayload: payload
        )

        let first = try PrivateGenomeVault.sealedData(for: envelope, keyProvider: keyA)
        let second = try PrivateGenomeVault.sealedData(for: envelope, keyProvider: keyA)
        expect(first != second, "AES-GCM ciphertext must use a fresh nonce")
        let opened = try PrivateGenomeVault.open(first, keyProvider: keyA)
        expect(opened == envelope, "vault round-trip")
        expect(!first.contains(Data("rs12345".utf8)), "ciphertext must not expose rsids")
        expect(!first.contains(payload), "ciphertext must not expose the raw payload")

        var tampered = first
        tampered[tampered.count - 1] ^= 0x01
        expectThrows("tampered ciphertext must fail authentication") {
            _ = try PrivateGenomeVault.open(tampered, keyProvider: keyA)
        }
        expectThrows("wrong key must fail authentication") {
            _ = try PrivateGenomeVault.open(first, keyProvider: keyB)
        }
        let missing = MissingPrivateVaultKeyProvider()
        expectThrows("opening a vault must not create a replacement for a missing key") {
            _ = try PrivateGenomeVault.open(first, keyProvider: missing)
        }
        expect(missing.creationAttempts == 0, "vault open must use load-only key access")

        let vaultURL = root.appendingPathComponent("Private Workspace/workspace.dnavault")
        try PrivateGenomeVault.writeVerified(envelope, to: vaultURL, keyProvider: keyA)
        let loaded = try PrivateGenomeVault.load(from: vaultURL, keyProvider: keyA)
        expect(loaded == envelope, "verified file round-trip")
        let dirMode = try mode(of: vaultURL.deletingLastPathComponent())
        let fileMode = try mode(of: vaultURL)
        expect(dirMode == 0o700, "vault directory mode must be 0700, got \(String(dirMode, radix: 8))")
        expect(fileMode == 0o600, "vault file mode must be 0600, got \(String(fileMode, radix: 8))")

        let replacementPayload = Data("rs99999\t3\t300\tT\tT\n".utf8)
        let replacement = PrivateGenomeEnvelope(
            originalFileName: "replacement.txt",
            originalFileExtension: "txt",
            sourceSHA256: PrivateGenomeVault.sha256Hex(replacementPayload),
            importedAt: Date(timeIntervalSince1970: 1_700_000_001),
            vendor: "Fixture",
            genomeBuildHint: "GRCh37",
            parserVersion: "3",
            catalogVersion: "fixture",
            acceptedCallCount: 1,
            skippedRecordCount: 0,
            sourcePayload: replacementPayload
        )
        let priorCiphertext = try Data(contentsOf: vaultURL)
        for fault in [
            PrivateGenomeVault.WriteVerificationFault.afterReplacement,
            .afterPermissions,
            .afterRead,
            .afterOpen,
            .afterEquality,
        ] {
            var observedCompleteState = true
            PrivateGenomeVault.writeVerificationHook = { point in
                guard point == fault else { return }
                guard let bytes = try? Data(contentsOf: vaultURL) else {
                    observedCompleteState = false
                    return
                }
                observedCompleteState = bytes == priorCiphertext
                    || (try? PrivateGenomeVault.open(bytes, keyProvider: keyA)) == replacement
            }
            PrivateGenomeVault.writeVerificationFault = fault
            expectThrows("injected post-swap fault must fail: \(fault)") {
                try PrivateGenomeVault.writeVerified(replacement, to: vaultURL, keyProvider: keyA)
            }
            PrivateGenomeVault.writeVerificationFault = nil
            PrivateGenomeVault.writeVerificationHook = nil
            expect(observedCompleteState, "atomic swap exposed no absent or partial state: \(fault)")
            let restoredBytes = try Data(contentsOf: vaultURL)
            let restoredMode = try mode(of: vaultURL)
            let artifacts = try hiddenArtifacts(in: vaultURL.deletingLastPathComponent())
            expect(restoredBytes == priorCiphertext, "fault restored exact prior ciphertext: \(fault)")
            expect(restoredMode == 0o600, "fault restored restrictive prior mode: \(fault)")
            expect(artifacts.isEmpty, "fault left no temp or backup: \(fault)")
        }

        let missingForWrite = MissingPrivateVaultKeyProvider()
        let beforeMissingKeyWrite = try Data(contentsOf: vaultURL)
        expectThrows("existing vault with a missing key must not be overwritten") {
            try PrivateGenomeVault.writeVerified(replacement, to: vaultURL, keyProvider: missingForWrite)
        }
        expect(missingForWrite.creationAttempts == 0, "existing vault replacement must not create a key")
        let afterMissingKeyWrite = try Data(contentsOf: vaultURL)
        let missingKeyArtifacts = try hiddenArtifacts(in: vaultURL.deletingLastPathComponent())
        expect(afterMissingKeyWrite == beforeMissingKeyWrite, "missing-key write preserves exact ciphertext")
        expect(missingKeyArtifacts.isEmpty, "missing-key write leaves no artifacts")

        let beforeWrongKeyWrite = try Data(contentsOf: vaultURL)
        expectThrows("existing vault with a wrong key must not be overwritten") {
            try PrivateGenomeVault.writeVerified(replacement, to: vaultURL, keyProvider: keyB)
        }
        let afterWrongKeyWrite = try Data(contentsOf: vaultURL)
        expect(afterWrongKeyWrite == beforeWrongKeyWrite, "wrong-key write preserves exact ciphertext")
        let wrongKeyArtifacts = try hiddenArtifacts(in: vaultURL.deletingLastPathComponent())
        expect(wrongKeyArtifacts.isEmpty, "wrong-key write leaves no artifacts")

        let corruptedVault = root.appendingPathComponent("corrupted/workspace.dnavault")
        try FileManager.default.createDirectory(at: corruptedVault.deletingLastPathComponent(), withIntermediateDirectories: true)
        var corruptedBytes = priorCiphertext
        corruptedBytes[corruptedBytes.count - 1] ^= 0x01
        try corruptedBytes.write(to: corruptedVault)
        expectThrows("corrupted existing ciphertext must not be overwritten") {
            try PrivateGenomeVault.writeVerified(replacement, to: corruptedVault, keyProvider: keyA)
        }
        let afterCorruptedWrite = try Data(contentsOf: corruptedVault)
        expect(afterCorruptedWrite == corruptedBytes, "corrupted ciphertext remains exact on rejected replacement")
        let corruptedArtifacts = try hiddenArtifacts(in: corruptedVault.deletingLastPathComponent())
        expect(corruptedArtifacts.isEmpty, "corrupted-vault rejection leaves no artifacts")

        let newKeyProvider = CountingPrivateVaultKeyProvider()
        let newVault = root.appendingPathComponent("brand-new/workspace.dnavault")
        try PrivateGenomeVault.writeVerified(envelope, to: newVault, keyProvider: newKeyProvider)
        expect(newKeyProvider.creationAttempts == 1, "brand-new vault creates exactly one key")
        let openedNewVault = try PrivateGenomeVault.load(from: newVault, keyProvider: newKeyProvider)
        expect(openedNewVault == envelope, "new key decrypts brand-new vault")

        let legacy = root.appendingPathComponent("legacy.txt")
        try payload.write(to: legacy)
        let blockedDestination = root.appendingPathComponent("blocked", isDirectory: true)
        try FileManager.default.createDirectory(at: blockedDestination, withIntermediateDirectories: true)
        expectThrows("failed migration must not remove plaintext source") {
            _ = try PrivateGenomeVault.migrateLegacy(
                from: legacy,
                to: blockedDestination,
                originalFileName: "legacy.txt",
                originalFileExtension: "txt",
                vendor: "Fixture",
                genomeBuildHint: "GRCh37",
                parserVersion: "3",
                catalogVersion: "fixture",
                acceptedCallCount: 2,
                skippedRecordCount: 0,
                keyProvider: keyA
            )
        }
        expect(FileManager.default.fileExists(atPath: legacy.path), "failed migration preserves legacy source")

        let migratedURL = root.appendingPathComponent("migrated/workspace.dnavault")
        let migrated = try PrivateGenomeVault.migrateLegacy(
            from: legacy,
            to: migratedURL,
            originalFileName: "legacy.txt",
            originalFileExtension: "txt",
            vendor: "Fixture",
            genomeBuildHint: "GRCh37",
            parserVersion: "3",
            catalogVersion: "fixture",
            acceptedCallCount: 2,
            skippedRecordCount: 0,
            keyProvider: keyA
        )
        expect(!FileManager.default.fileExists(atPath: legacy.path), "successful migration removes legacy source")
        expect(migrated.sourcePayload == payload, "successful migration preserves exact bytes")

        let workspaceRoot = root.appendingPathComponent("generation-guard", isDirectory: true)
        AppPaths.overrideSupport = workspaceRoot

        let symlinkTarget = root.appendingPathComponent("symlink-target", isDirectory: true)
        try FileManager.default.createDirectory(at: symlinkTarget, withIntermediateDirectories: true)
        let sentinel = symlinkTarget.appendingPathComponent("keep-me.txt")
        let sentinelBytes = Data("must survive".utf8)
        try sentinelBytes.write(to: sentinel)
        let symlinkRoot = root.appendingPathComponent("symlink-support", isDirectory: true)
        try FileManager.default.createSymbolicLink(at: symlinkRoot, withDestinationURL: symlinkTarget)
        AppPaths.overrideSupport = symlinkRoot
        expectThrows("symlinked support root must reject inventory") {
            _ = try LocalEraser.inventory()
        }
        let symlinkErase = LocalEraser.eraseAllVerified()
        expect(!symlinkErase.verifiedEmpty, "symlinked support root must reject erase")
        expect(FileManager.default.fileExists(atPath: sentinel.path), "erase must not follow support symlink")
        let sentinelAfterErase = try Data(contentsOf: sentinel)
        expect(sentinelAfterErase == sentinelBytes, "support symlink target sentinel remains exact")
        expect(AppPaths.support.path.hasPrefix("/dev/null/"), "non-throwing support path fails closed")
        expect(AppPaths.reports.path.hasPrefix("/dev/null/"), "report path fails closed")
        expect(AppPaths.profiles.path.hasPrefix("/dev/null/"), "profile path fails closed")
        expectThrows("vault write through symlinked support must fail") {
            try PrivateGenomeVault.writeVerified(envelope, to: symlinkRoot.appendingPathComponent("workspace.dnavault"), keyProvider: keyA)
        }
        expect(FileManager.default.fileExists(atPath: sentinel.path), "failed vault write must not touch symlink target")
        let linkedVault = root.appendingPathComponent("linked-workspace.dnavault")
        try FileManager.default.createSymbolicLink(at: linkedVault, withDestinationURL: sentinel)
        expectThrows("symbolic-link vault destination must fail") {
            try PrivateGenomeVault.writeVerified(envelope, to: linkedVault, keyProvider: keyA)
        }
        let sentinelAfterVaultLink = try Data(contentsOf: sentinel)
        expect(sentinelAfterVaultLink == sentinelBytes, "vault destination symlink target remains exact")
        AppPaths.overrideSupport = workspaceRoot
        defer { AppPaths.overrideSupport = nil }
        let store = PrivateWorkspaceStore(keyProvider: keyA)
        let stale = UUID()
        let current = UUID()
        let firstActivation = await store.activate(stale, sequence: 1)
        let sameGenerationReplay = await store.activate(stale, sequence: 1)
        let currentActivation = await store.activate(current, sequence: 2)
        let equalSequenceReplay = await store.activate(UUID(), sequence: 2)
        let staleReactivation = await store.activate(stale, sequence: 1)
        expect(firstActivation, "first generation activates")
        expect(!sameGenerationReplay, "same generation cannot replay an equal sequence")
        expect(currentActivation, "newer generation activates")
        expect(!equalSequenceReplay, "equal sequence cannot replay with a new generation")
        expect(!staleReactivation, "stale generation cannot supersede newer work")
        await expectThrowsAsync("stale generation cannot write a vault") {
            try await store.save(envelope, generation: stale)
        }
        expect(!FileManager.default.fileExists(atPath: AppPaths.privateVault.path), "stale write created no vault")
        try await store.save(envelope, generation: current)
        expect(FileManager.default.fileExists(atPath: AppPaths.privateVault.path), "current generation writes vault")
        let beforeCancelledSave = try Data(contentsOf: AppPaths.privateVault)
        PrivateGenomeVault.writeVerificationHook = { point in
            if point == .afterReplacement {
                withUnsafeCurrentTask { task in task?.cancel() }
            }
        }
        let cancelledSave = Task {
            try await store.save(replacement, generation: current)
        }
        await expectThrowsAsync("cancellation during replacement rolls back") {
            try await cancelledSave.value
        }
        PrivateGenomeVault.writeVerificationHook = nil
        let afterCancelledSave = try Data(contentsOf: AppPaths.privateVault)
        expect(afterCancelledSave == beforeCancelledSave, "cancelled save restores exact prior ciphertext")
        let cancelledArtifacts = try hiddenArtifacts(in: AppPaths.privateVault.deletingLastPathComponent())
        expect(cancelledArtifacts.isEmpty, "cancelled save leaves no rollback artifact")
        let erased = await store.eraseEverything()
        expect(erased.verifiedEmpty, "workspace erase verifies empty")
        await expectThrowsAsync("pre-erase generation cannot recreate the vault") {
            try await store.save(envelope, generation: current)
        }
        expect(!FileManager.default.fileExists(atPath: AppPaths.privateVault.path), "post-erase stale write created no vault")

        let unreadableInventoryRoot = root.appendingPathComponent("not-a-directory")
        try Data("fixture".utf8).write(to: unreadableInventoryRoot)
        AppPaths.overrideSupport = unreadableInventoryRoot
        expectThrows("inventory failure must not be represented as an empty directory") {
            _ = try LocalEraser.inventory()
        }
        AppPaths.overrideSupport = workspaceRoot

        let clock = MutableTestClock(Date(timeIntervalSince1970: 1_700_000_000))
        let monitor = await MainActor.run {
            WorkspaceActivityMonitor(now: { clock.current }, observeEvents: false)
        }
        let initiallyExpired = await MainActor.run { monitor.hasExceeded(minutes: 5) }
        expect(!initiallyExpired, "new activity monitor is not expired")
        clock.current.addTimeInterval(301)
        let expired = await MainActor.run { monitor.hasExceeded(minutes: 5) }
        expect(expired, "activity monitor expires after the configured interval")
        await MainActor.run { monitor.recordActivity() }
        let resetExpired = await MainActor.run { monitor.hasExceeded(minutes: 5) }
        expect(!resetExpired, "recordActivity resets the private-session timer")

        print("vault-check: PASS")
    }

    private static func mode(of url: URL) throws -> Int {
        let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
        guard let permissions = attrs[.posixPermissions] as? NSNumber else {
            throw CocoaError(.fileReadUnknown)
        }
        return permissions.intValue & 0o777
    }

    private static func hiddenArtifacts(in directory: URL) throws -> [URL] {
        try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            .filter { $0.lastPathComponent.hasPrefix(".workspace.dnavault.") }
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        guard condition() else {
            FileHandle.standardError.write(Data("vault-check FAIL: \(message)\n".utf8))
            Foundation.exit(1)
        }
    }

    private static func expectThrows(_ message: String, operation: () throws -> Void) {
        do {
            try operation()
            expect(false, message)
        } catch {
            // Expected: only the fact of failure is asserted; no sensitive error data is printed.
        }
    }

    private static func expectThrowsAsync(
        _ message: String,
        operation: () async throws -> Void
    ) async {
        do {
            try await operation()
            expect(false, message)
        } catch {
            // Expected.
        }
    }
}

private final class MutableTestClock: @unchecked Sendable {
    var current: Date
    init(_ current: Date) { self.current = current }
}

private final class MissingPrivateVaultKeyProvider: PrivateVaultKeyProviding {
    private(set) var creationAttempts = 0

    func loadKey() throws -> SymmetricKey {
        throw PrivateVaultError.missingKey
    }

    func loadOrCreateKey() throws -> SymmetricKey {
        creationAttempts += 1
        return SymmetricKey(size: .bits256)
    }

    func deleteKey() throws {}
}

private final class CountingPrivateVaultKeyProvider: PrivateVaultKeyProviding {
    private var key: SymmetricKey?
    private(set) var creationAttempts = 0

    func loadKey() throws -> SymmetricKey {
        guard let key else { throw PrivateVaultError.missingKey }
        return key
    }

    func loadOrCreateKey() throws -> SymmetricKey {
        if let key { return key }
        creationAttempts += 1
        let created = SymmetricKey(size: .bits256)
        key = created
        return created
    }

    func deleteKey() throws { key = nil }
}
