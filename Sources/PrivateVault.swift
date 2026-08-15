import CryptoKit
import Darwin
import Foundation
import Security

/// A versioned, authenticated container for the one private genome workspace.
/// Every field lives inside AES-GCM ciphertext; the file header contains only a
/// magic value and the container-format version.
struct PrivateGenomeEnvelope: Codable, Equatable {
    static let currentSchemaVersion = 1

    var schemaVersion: Int = currentSchemaVersion
    var originalFileName: String
    var originalFileExtension: String
    var sourceSHA256: String
    var importedAt: Date
    var vendor: String
    var genomeBuildHint: String
    var parserVersion: String
    var catalogVersion: String
    var acceptedCallCount: Int
    var skippedRecordCount: Int
    var sourcePayload: Data

    init(
        originalFileName: String,
        originalFileExtension: String,
        sourceSHA256: String,
        importedAt: Date,
        vendor: String,
        genomeBuildHint: String,
        parserVersion: String,
        catalogVersion: String,
        acceptedCallCount: Int,
        skippedRecordCount: Int,
        sourcePayload: Data
    ) {
        self.originalFileName = originalFileName
        self.originalFileExtension = originalFileExtension
        self.sourceSHA256 = sourceSHA256
        self.importedAt = importedAt
        self.vendor = vendor
        self.genomeBuildHint = genomeBuildHint
        self.parserVersion = parserVersion
        self.catalogVersion = catalogVersion
        self.acceptedCallCount = acceptedCallCount
        self.skippedRecordCount = skippedRecordCount
        self.sourcePayload = sourcePayload
    }
}

protocol PrivateVaultKeyProviding {
    func loadKey() throws -> SymmetricKey
    func loadOrCreateKey() throws -> SymmetricKey
    func deleteKey() throws
}

enum PrivateVaultError: LocalizedError, Equatable {
    case invalidContainer
    case unsupportedContainerVersion(UInt8)
    case unsupportedEnvelopeVersion(Int)
    case keychain(OSStatus)
    case invalidKey
    case missingKey
    case verificationFailed
    case unsafeDestination

    var errorDescription: String? {
        switch self {
        case .invalidContainer:
            return "The private workspace is damaged or is not a DNA Engine vault."
        case .unsupportedContainerVersion(let version):
            return "This private workspace uses unsupported container version \(version)."
        case .unsupportedEnvelopeVersion(let version):
            return "This private workspace uses unsupported schema version \(version)."
        case .keychain(let status):
            return "The private workspace key could not be accessed (Keychain status \(status))."
        case .invalidKey:
            return "The private workspace key is invalid."
        case .missingKey:
            return "The private workspace key is missing from this Mac's Keychain. The encrypted file was not changed."
        case .verificationFailed:
            return "The encrypted workspace could not be verified after writing."
        case .unsafeDestination:
            return "The encrypted workspace destination is not a regular local file path."
        }
    }
}

struct KeychainPrivateVaultKeyProvider: PrivateVaultKeyProviding {
    static let service = "ai.shadowfetch.dnaengine.private-vault"
    static let account = "workspace-master-key-v1"

    func loadKey() throws -> SymmetricKey {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let lookup = SecItemCopyMatching(query as CFDictionary, &item)
        if lookup == errSecSuccess {
            guard let data = item as? Data, data.count == 32 else {
                throw PrivateVaultError.invalidKey
            }
            return SymmetricKey(data: data)
        }
        guard lookup != errSecItemNotFound else { throw PrivateVaultError.missingKey }
        throw PrivateVaultError.keychain(lookup)
    }

    func loadOrCreateKey() throws -> SymmetricKey {
        do {
            return try loadKey()
        } catch PrivateVaultError.missingKey {
            // Creation is allowed only when sealing a new or replacement vault.
        }

        let key = SymmetricKey(size: .bits256)
        let keyData = key.withUnsafeBytes { Data($0) }
        var add = baseQuery
        add[kSecValueData as String] = keyData
        add[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        add[kSecAttrSynchronizable as String] = false
        let added = SecItemAdd(add as CFDictionary, nil)
        if added == errSecSuccess { return key }
        if added == errSecDuplicateItem {
            return try loadKey()
        }
        throw PrivateVaultError.keychain(added)
    }

    func deleteKey() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw PrivateVaultError.keychain(status)
        }
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: Self.account,
            kSecAttrSynchronizable as String: false,
        ]
    }
}

struct FixedPrivateVaultKeyProvider: PrivateVaultKeyProviding {
    let key: SymmetricKey
    func loadKey() throws -> SymmetricKey { key }
    func loadOrCreateKey() throws -> SymmetricKey { key }
    func deleteKey() throws {}
}

enum PrivateGenomeVault {
    private static let magic = Data([0x44, 0x4E, 0x41, 0x56]) // DNAV
    private static let containerVersion: UInt8 = 1
    private static let headerSize = 5

    enum WriteVerificationFault: Error, Equatable {
        case afterReplacement
        case afterPermissions
        case afterRead
        case afterOpen
        case afterEquality
    }

    #if DNAENGINE_VAULT_TESTING
    nonisolated(unsafe) static var writeVerificationFault: WriteVerificationFault?
    nonisolated(unsafe) static var writeVerificationHook: ((WriteVerificationFault) -> Void)?
    #endif

    static func sha256Hex(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    static func sealedData(
        for envelope: PrivateGenomeEnvelope,
        keyProvider: PrivateVaultKeyProviding
    ) throws -> Data {
        let key = try keyProvider.loadOrCreateKey()
        return try sealedData(for: envelope, key: key)
    }

    private static func sealedData(
        for envelope: PrivateGenomeEnvelope,
        key: SymmetricKey
    ) throws -> Data {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        let cleartext = try encoder.encode(envelope)
        let sealed = try AES.GCM.seal(cleartext, using: key)
        guard let combined = sealed.combined else { throw PrivateVaultError.invalidContainer }
        return magic + Data([containerVersion]) + combined
    }

    static func open(
        _ container: Data,
        keyProvider: PrivateVaultKeyProviding
    ) throws -> PrivateGenomeEnvelope {
        try open(container, key: keyProvider.loadKey())
    }

    private static func open(
        _ container: Data,
        key: SymmetricKey
    ) throws -> PrivateGenomeEnvelope {
        guard container.count > headerSize,
              container.prefix(magic.count) == magic else {
            throw PrivateVaultError.invalidContainer
        }
        let version = container[magic.count]
        guard version == containerVersion else {
            throw PrivateVaultError.unsupportedContainerVersion(version)
        }
        let box = try AES.GCM.SealedBox(combined: container.dropFirst(headerSize))
        let cleartext = try AES.GCM.open(box, using: key)
        let decoder = PropertyListDecoder()
        let envelope = try decoder.decode(PrivateGenomeEnvelope.self, from: cleartext)
        guard envelope.schemaVersion == PrivateGenomeEnvelope.currentSchemaVersion else {
            throw PrivateVaultError.unsupportedEnvelopeVersion(envelope.schemaVersion)
        }
        guard envelope.sourceSHA256 == sha256Hex(envelope.sourcePayload) else {
            throw PrivateVaultError.verificationFailed
        }
        return envelope
    }

    /// Writes to a same-directory temporary file, synchronizes it, atomically
    /// replaces the destination, enforces restrictive modes, and round-trips
    /// the final ciphertext before reporting success.
    static func writeVerified(
        _ envelope: PrivateGenomeEnvelope,
        to destination: URL,
        keyProvider: PrivateVaultKeyProviding
    ) throws {
        guard destination.isFileURL, !destination.lastPathComponent.isEmpty else {
            throw PrivateVaultError.unsafeDestination
        }
        let fileManager = FileManager.default
        let directory = try LocalPathSafety.requireDirectory(
            destination.deletingLastPathComponent(),
            createIfMissing: true
        )
        let destinationExists = try LocalPathSafety.exists(destination)
        if destinationExists {
            do {
                try LocalPathSafety.requireRegularFile(destination)
            } catch {
                throw PrivateVaultError.unsafeDestination
            }
        }

        // Never create a replacement key when ciphertext already exists, and
        // never overwrite ciphertext that the loaded key cannot authenticate.
        let key: SymmetricKey
        if destinationExists {
            key = try keyProvider.loadKey()
            let existingContainer = try Data(contentsOf: destination, options: [.mappedIfSafe])
            _ = try open(existingContainer, key: key)
        } else {
            key = try keyProvider.loadOrCreateKey()
        }
        let container = try sealedData(for: envelope, key: key)
        let temporary = directory.appendingPathComponent(".\(destination.lastPathComponent).\(UUID().uuidString).tmp")
        guard fileManager.createFile(atPath: temporary.path, contents: nil, attributes: [.posixPermissions: 0o600]) else {
            throw CocoaError(.fileWriteUnknown)
        }
        var destinationContainsCandidate = false
        var temporaryContainsPrior = false
        do {
            let handle = try FileHandle(forWritingTo: temporary)
            do {
                try handle.write(contentsOf: container)
                try handle.synchronize()
                try handle.close()
            } catch {
                try? handle.close()
                throw error
            }
            try fileManager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: temporary.path)
            try Task.checkCancellation()

            if destinationExists {
                // RENAME_SWAP is one same-volume atomic namespace operation:
                // readers always see the complete prior or candidate file, and
                // the temporary path becomes the exact rollback ciphertext.
                try atomicSwap(temporary, destination)
                temporaryContainsPrior = true
            } else {
                try fileManager.moveItem(at: temporary, to: destination)
            }
            destinationContainsCandidate = true
            try injectWriteVerificationFault(.afterReplacement)
            try Task.checkCancellation()
            try fileManager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: destination.path)
            try injectWriteVerificationFault(.afterPermissions)
            try Task.checkCancellation()

            let verifiedContainer = try Data(contentsOf: destination, options: [.mappedIfSafe])
            try injectWriteVerificationFault(.afterRead)
            try Task.checkCancellation()
            let verified = try open(verifiedContainer, key: key)
            try injectWriteVerificationFault(.afterOpen)
            try Task.checkCancellation()
            guard verified == envelope else { throw PrivateVaultError.verificationFailed }
            try injectWriteVerificationFault(.afterEquality)
            try Task.checkCancellation()
            try synchronizeDirectory(directory)
            try Task.checkCancellation()
            if temporaryContainsPrior {
                try fileManager.removeItem(at: temporary)
                temporaryContainsPrior = false
            }
            // The committed name was synchronized while the rollback copy was
            // still present. Cleanup synchronization is best-effort because no
            // failure can be reported after the prior ciphertext is removed.
            try? synchronizeDirectory(directory)
        } catch {
            let reportedError = error
            if destinationContainsCandidate {
                if temporaryContainsPrior {
                    do {
                        try atomicSwap(temporary, destination)
                        temporaryContainsPrior = false
                        destinationContainsCandidate = false
                    } catch {
                        // Do not delete the only copy of the prior ciphertext.
                        throw PrivateVaultError.verificationFailed
                    }
                } else if !destinationExists {
                    do {
                        try fileManager.removeItem(at: destination)
                        destinationContainsCandidate = false
                    } catch {
                        throw PrivateVaultError.verificationFailed
                    }
                }
            }
            if try LocalPathSafety.exists(temporary) {
                try fileManager.removeItem(at: temporary)
            }
            try? synchronizeDirectory(directory)
            throw reportedError
        }
    }

    #if DNAENGINE_VAULT_TESTING
    private static func injectWriteVerificationFault(_ point: WriteVerificationFault) throws {
        writeVerificationHook?(point)
        if writeVerificationFault == point { throw point }
    }
    #else
    private static func injectWriteVerificationFault(_ point: WriteVerificationFault) throws {}
    #endif

    private static func atomicSwap(_ first: URL, _ second: URL) throws {
        let result = first.path.withCString { firstPath in
            second.path.withCString { secondPath in
                renamex_np(firstPath, secondPath, UInt32(RENAME_SWAP))
            }
        }
        guard result == 0 else {
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno))
        }
    }

    private static func synchronizeDirectory(_ directory: URL) throws {
        let descriptor = Darwin.open(directory.path, O_RDONLY | O_DIRECTORY)
        guard descriptor >= 0 else {
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno))
        }
        defer { Darwin.close(descriptor) }
        guard Darwin.fsync(descriptor) == 0 else {
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno))
        }
    }

    static func load(
        from source: URL,
        keyProvider: PrivateVaultKeyProviding
    ) throws -> PrivateGenomeEnvelope {
        do {
            try LocalPathSafety.requireRegularFile(source)
        } catch {
            throw PrivateVaultError.unsafeDestination
        }
        return try open(Data(contentsOf: source, options: [.mappedIfSafe]), keyProvider: keyProvider)
    }

    /// The plaintext legacy file is removed only after encrypted write and
    /// authenticated round-trip both succeed. A failed migration is therefore
    /// recoverable and leaves the original untouched.
    static func migrateLegacy(
        from legacySource: URL,
        to destination: URL,
        originalFileName: String,
        originalFileExtension: String,
        vendor: String,
        genomeBuildHint: String,
        parserVersion: String,
        catalogVersion: String,
        acceptedCallCount: Int,
        skippedRecordCount: Int,
        keyProvider: PrivateVaultKeyProviding
    ) throws -> PrivateGenomeEnvelope {
        do {
            try LocalPathSafety.requireRegularFile(legacySource)
        } catch {
            throw PrivateVaultError.unsafeDestination
        }
        let payload = try Data(contentsOf: legacySource, options: [.mappedIfSafe])
        let envelope = PrivateGenomeEnvelope(
            originalFileName: originalFileName,
            originalFileExtension: originalFileExtension,
            sourceSHA256: sha256Hex(payload),
            importedAt: Date(),
            vendor: vendor,
            genomeBuildHint: genomeBuildHint,
            parserVersion: parserVersion,
            catalogVersion: catalogVersion,
            acceptedCallCount: acceptedCallCount,
            skippedRecordCount: skippedRecordCount,
            sourcePayload: payload
        )
        try writeVerified(envelope, to: destination, keyProvider: keyProvider)
        let roundTrip = try load(from: destination, keyProvider: keyProvider)
        guard roundTrip.sourceSHA256 == envelope.sourceSHA256 else {
            throw PrivateVaultError.verificationFailed
        }
        try LocalPathSafety.requireRegularFile(legacySource)
        let currentLegacy = try Data(contentsOf: legacySource, options: [.mappedIfSafe])
        guard sha256Hex(currentLegacy) == envelope.sourceSHA256 else {
            throw PrivateVaultError.verificationFailed
        }
        try FileManager.default.removeItem(at: legacySource)
        return roundTrip
    }
}
