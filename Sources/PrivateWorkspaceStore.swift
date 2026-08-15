import Foundation

struct WorkspaceEraseOutcome {
    var fileResult: LocalEraser.EraseResult
    var keyDeletionFailure: String?

    var verifiedEmpty: Bool {
        fileResult.verifiedEmpty && keyDeletionFailure == nil
    }
}

/// Serializes every mutation of the encrypted workspace. The generation guard
/// makes a cancelled import incapable of recreating a vault after an erase.
actor PrivateWorkspaceStore {
    private var activeGeneration: UUID?
    private var latestSequence: UInt64 = 0
    private let keyProvider: PrivateVaultKeyProviding

    init(keyProvider: PrivateVaultKeyProviding = KeychainPrivateVaultKeyProvider()) {
        self.keyProvider = keyProvider
    }

    @discardableResult
    func activate(_ generation: UUID, sequence: UInt64) -> Bool {
        guard sequence > latestSequence else { return false }
        latestSequence = sequence
        activeGeneration = generation
        return true
    }

    func deactivate(_ generation: UUID) {
        if activeGeneration == generation {
            activeGeneration = nil
        }
    }

    func load(generation: UUID) throws -> PrivateGenomeEnvelope {
        try Task.checkCancellation()
        try requireActive(generation)
        let envelope = try PrivateGenomeVault.load(from: AppPaths.privateVault, keyProvider: keyProvider)
        try Task.checkCancellation()
        try requireActive(generation)
        return envelope
    }

    func save(_ envelope: PrivateGenomeEnvelope, generation: UUID) throws {
        try Task.checkCancellation()
        try requireActive(generation)
        try PrivateGenomeVault.writeVerified(envelope, to: AppPaths.privateVault, keyProvider: keyProvider)
        try Task.checkCancellation()
        try requireActive(generation)
    }

    func migrateLegacy(
        envelope: PrivateGenomeEnvelope,
        legacySource: URL,
        generation: UUID
    ) throws {
        try Task.checkCancellation()
        try requireActive(generation)
        try PrivateGenomeVault.writeVerified(envelope, to: AppPaths.privateVault, keyProvider: keyProvider)
        let verified = try PrivateGenomeVault.load(from: AppPaths.privateVault, keyProvider: keyProvider)
        guard verified.sourceSHA256 == envelope.sourceSHA256 else {
            throw PrivateVaultError.verificationFailed
        }
        try Task.checkCancellation()
        try requireActive(generation)
        do {
            try LocalPathSafety.requireRegularFile(legacySource)
        } catch {
            throw PrivateVaultError.unsafeDestination
        }
        let currentLegacy = try Data(contentsOf: legacySource, options: [.mappedIfSafe])
        guard PrivateGenomeVault.sha256Hex(currentLegacy) == envelope.sourceSHA256 else {
            throw PrivateVaultError.verificationFailed
        }
        try Task.checkCancellation()
        try requireActive(generation)
        try FileManager.default.removeItem(at: legacySource)
    }

    func eraseEverything() -> WorkspaceEraseOutcome {
        latestSequence &+= 1
        activeGeneration = nil
        let result = LocalEraser.eraseAllVerified()
        var keyFailure: String?
        if result.verifiedEmpty {
            do {
                try keyProvider.deleteKey()
            } catch {
                keyFailure = error.localizedDescription
            }
        }
        return WorkspaceEraseOutcome(fileResult: result, keyDeletionFailure: keyFailure)
    }

    private func requireActive(_ generation: UUID) throws {
        guard activeGeneration == generation else { throw CancellationError() }
    }
}
