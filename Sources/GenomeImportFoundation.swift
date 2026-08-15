import Foundation
import zlib

// UI-free, immutable import inputs and receipts. These types intentionally carry
// no app state: callers can retain a receipt without retaining the source bytes.

enum GenomeContainerKind: String, Codable, Equatable {
    case plainText
    case gzip
    case zip
}

struct GenomeImportLimits: Equatable {
    static let standard = GenomeImportLimits()

    let maximumInputBytes: Int
    let maximumExpandedBytes: Int
    let maximumCompressionRatio: Int
    let maximumDiagnosticExamples: Int

    init(
        maximumInputBytes: Int = 256 * 1_024 * 1_024,
        maximumExpandedBytes: Int = 768 * 1_024 * 1_024,
        maximumCompressionRatio: Int = 200,
        maximumDiagnosticExamples: Int = 25
    ) {
        precondition(maximumInputBytes > 0)
        precondition(maximumExpandedBytes > 0)
        precondition(maximumCompressionRatio > 0)
        precondition(maximumDiagnosticExamples >= 0)
        self.maximumInputBytes = maximumInputBytes
        self.maximumExpandedBytes = maximumExpandedBytes
        self.maximumCompressionRatio = maximumCompressionRatio
        self.maximumDiagnosticExamples = maximumDiagnosticExamples
    }
}

struct GenomeImportOptions: Equatable {
    static let standard = GenomeImportOptions()

    let selectedVCFSample: String?
    let minimumAcceptedRecords: Int
    let limits: GenomeImportLimits

    init(
        selectedVCFSample: String? = nil,
        minimumAcceptedRecords: Int = 500,
        limits: GenomeImportLimits = .standard
    ) {
        precondition(minimumAcceptedRecords >= 0)
        self.selectedVCFSample = selectedVCFSample
        self.minimumAcceptedRecords = minimumAcceptedRecords
        self.limits = limits
    }
}

struct GenomeImportRequest: Equatable {
    let sourceURL: URL
    let options: GenomeImportOptions

    init(sourceURL: URL, options: GenomeImportOptions = .standard) {
        self.sourceURL = sourceURL
        self.options = options
    }
}

enum GenomeImportNoticeCode: String, Codable, Equatable {
    case contentSignatureUsed
    case extensionMismatch
    case vcfSampleDefaulted
    case implicitVCFSampleColumn
}

struct GenomeImportNotice: Codable, Equatable {
    let code: GenomeImportNoticeCode
    let message: String
}

struct GenomeSourceDescriptor: Codable, Equatable {
    let displayName: String
    let originalExtension: String?
    let declaredContainer: GenomeContainerKind?
    let detectedContainer: GenomeContainerKind
    let inputByteCount: Int
    let expandedByteCount: Int
    let archiveMemberName: String?
}

enum GenomeArchiveValidationStatus: String, Codable, Equatable {
    case validated
}

struct GenomeArchiveReceipt: Codable, Equatable {
    let container: GenomeContainerKind
    let status: GenomeArchiveValidationStatus
    let memberName: String?
    let compressedByteCount: Int
    let expandedByteCount: Int
    let checksumValidated: Bool
}

enum VCFSampleSelectionMode: String, Codable, Equatable {
    case onlySample
    case explicitlySelected
    case defaultedToFirst
    case implicitFirstColumn
}

struct VCFSampleSelectionReceipt: Codable, Equatable {
    let availableSamples: [String]
    let selectedSample: String
    let selectedColumn: Int
    let mode: VCFSampleSelectionMode
}

enum GenomeRecordDiagnosticCode: String, Codable, Equatable {
    case malformed
    case unsupported
    case filtered
    case duplicate
    case conflict
}

struct GenomeRecordDiagnostic: Codable, Equatable {
    let lineNumber: Int
    let code: GenomeRecordDiagnosticCode
    let message: String
}

struct GenomeParseDiagnostics: Codable, Equatable {
    let totalRecords: Int
    let acceptedRecords: Int
    let skippedRecords: Int
    let duplicateRecords: Int
    let conflictRecords: Int
    let malformedRecords: Int
    let unsupportedRecords: Int
    /// A subset of unsupportedRecords, retained separately for VCF auditability.
    let filteredRecords: Int
    /// A subset of acceptedRecords; no-calls remain available to QC analysis.
    let noCallRecords: Int
    let examples: [GenomeRecordDiagnostic]

    var reconciles: Bool {
        totalRecords == acceptedRecords + skippedRecords
            && skippedRecords == duplicateRecords + conflictRecords + malformedRecords + unsupportedRecords
            && noCallRecords <= acceptedRecords
            && filteredRecords <= unsupportedRecords
    }
}

enum GenomeTextFormat: String, Codable, Equatable {
    case ancestryAlleles
    case genotype
    case vcf
    case unknown
}

struct GenomeImportReceipt: Codable, Equatable {
    let source: GenomeSourceDescriptor
    let archive: GenomeArchiveReceipt?
    let requestedVCFSample: String?
    let selectedVCFSample: VCFSampleSelectionReceipt?
    let detectedFormat: GenomeTextFormat
    let diagnostics: GenomeParseDiagnostics
    let notices: [GenomeImportNotice]
}

enum GenomeImportError: LocalizedError, Equatable {
    case sourceIsNotRegularFile
    case cannotReadSource(String)
    case inputLimitExceeded(actual: Int, limit: Int)
    case expandedLimitExceeded(actual: Int?, limit: Int)
    case compressionRatioExceeded(input: Int, output: Int, limit: Int)
    case corruptArchive(String)
    case archiveMemberCount(Int)
    case unsafeArchiveMember(String)
    case unsupportedArchiveFeature(String)
    case archiveChecksumMismatch
    case trailingArchiveData
    case textDecodingFailed

    var errorDescription: String? {
        switch self {
        case .sourceIsNotRegularFile:
            return "The selected genome source is not a regular file."
        case .cannotReadSource(let message):
            return "Could not read the genome source: \(message)"
        case .inputLimitExceeded(let actual, let limit):
            return "The source is \(actual) bytes, above the \(limit)-byte import limit."
        case .expandedLimitExceeded(let actual, let limit):
            if let actual {
                return "The expanded archive is \(actual) bytes, above the \(limit)-byte import limit."
            }
            return "The archive expanded beyond the \(limit)-byte import limit."
        case .compressionRatioExceeded(let input, let output, let limit):
            return "The archive expansion ratio is unsafe (\(output) bytes from \(input); limit \(limit)x)."
        case .corruptArchive(let message):
            return "The archive is corrupt or incomplete: \(message)"
        case .archiveMemberCount(let count):
            return "ZIP imports must contain exactly one regular genome file; this archive declares \(count) entries."
        case .unsafeArchiveMember(let name):
            return "The ZIP member is not a safe regular file: \(name)"
        case .unsupportedArchiveFeature(let feature):
            return "The archive uses an unsupported feature: \(feature)"
        case .archiveChecksumMismatch:
            return "The archive checksum does not match its expanded contents."
        case .trailingArchiveData:
            return "The archive contains trailing or concatenated data."
        case .textDecodingFailed:
            return "The expanded genome data is not supported text."
        }
    }
}

struct DecodedGenomeSource {
    let text: String
    let descriptor: GenomeSourceDescriptor
    let archiveReceipt: GenomeArchiveReceipt?
    let notices: [GenomeImportNotice]
}

enum GenomeSourceDecoder {
    static func decode(request: GenomeImportRequest) throws -> DecodedGenomeSource {
        let url = request.sourceURL
        let limits = request.options.limits
        let values: URLResourceValues
        do {
            values = try url.resourceValues(forKeys: [.isRegularFileKey])
        } catch {
            throw GenomeImportError.cannotReadSource(error.localizedDescription)
        }
        guard values.isRegularFile == true else {
            throw GenomeImportError.sourceIsNotRegularFile
        }

        let data = try readBounded(url: url, limit: limits.maximumInputBytes)
        return try decode(data: data, displayName: url.lastPathComponent, options: request.options)
    }

    /// Decodes original source bytes entirely in memory. This is the vault
    /// restore path: encrypted bytes can be opened and parsed without ever
    /// writing a plaintext intermediate file.
    static func decode(
        data: Data,
        displayName: String,
        options: GenomeImportOptions = .standard
    ) throws -> DecodedGenomeSource {
        let limits = options.limits
        guard data.count <= limits.maximumInputBytes else {
            throw GenomeImportError.inputLimitExceeded(actual: data.count, limit: limits.maximumInputBytes)
        }
        let detected = detectContainer(data)
        let originalExtension = normalizedExtension((displayName as NSString).pathExtension)
        let declared = declaredContainer(for: originalExtension)
        var notices: [GenomeImportNotice] = []

        if detected != .plainText, declared != detected {
            notices.append(GenomeImportNotice(
                code: .contentSignatureUsed,
                message: "Detected \(detected.rawValue) from file contents; the original extension was preserved only as metadata."
            ))
        }
        if let declared, declared != detected {
            notices.append(GenomeImportNotice(
                code: .extensionMismatch,
                message: "The .\(originalExtension ?? "") extension declares \(declared.rawValue), but the content is \(detected.rawValue)."
            ))
        }

        let expanded: Data
        let archive: GenomeArchiveReceipt?
        switch detected {
        case .plainText:
            guard data.count <= limits.maximumExpandedBytes else {
                throw GenomeImportError.expandedLimitExceeded(actual: data.count, limit: limits.maximumExpandedBytes)
            }
            expanded = data
            archive = nil
        case .gzip:
            expanded = try ZlibDecoder.inflate(
                data,
                wrapper: .gzip,
                expectedSize: nil,
                limits: limits
            )
            archive = GenomeArchiveReceipt(
                container: .gzip,
                status: .validated,
                memberName: nil,
                compressedByteCount: data.count,
                expandedByteCount: expanded.count,
                checksumValidated: true
            )
        case .zip:
            let decoded = try StrictZipDecoder.decode(data, limits: limits)
            expanded = decoded.data
            archive = GenomeArchiveReceipt(
                container: .zip,
                status: .validated,
                memberName: decoded.memberName,
                compressedByteCount: decoded.compressedByteCount,
                expandedByteCount: decoded.data.count,
                checksumValidated: true
            )
        }

        let text = try decodeText(expanded)
        let descriptor = GenomeSourceDescriptor(
            displayName: displayName,
            originalExtension: originalExtension,
            declaredContainer: declared,
            detectedContainer: detected,
            inputByteCount: data.count,
            expandedByteCount: expanded.count,
            archiveMemberName: archive?.memberName
        )
        return DecodedGenomeSource(text: text, descriptor: descriptor, archiveReceipt: archive, notices: notices)
    }

    static func decodeText(_ data: Data) throws -> String {
        // NULs are not meaningful in supported raw-DNA text and accepting them
        // through Latin-1 would turn arbitrary binary input into plausible text.
        guard !data.contains(0) else { throw GenomeImportError.textDecodingFailed }
        guard let text = String(data: data, encoding: .utf8)
                ?? String(data: data, encoding: .isoLatin1)
                ?? String(data: data, encoding: .ascii) else {
            throw GenomeImportError.textDecodingFailed
        }
        return text
    }

    static func detectContainer(_ data: Data) -> GenomeContainerKind {
        if data.count >= 2, data[0] == 0x1f, data[1] == 0x8b { return .gzip }
        if data.count >= 4, data[0] == 0x50, data[1] == 0x4b {
            let signature = (data[2], data[3])
            if signature == (0x03, 0x04) || signature == (0x05, 0x06) || signature == (0x07, 0x08) {
                return .zip
            }
        }
        return .plainText
    }

    private static func readBounded(url: URL, limit: Int) throws -> Data {
        do {
            let handle = try FileHandle(forReadingFrom: url)
            defer { try? handle.close() }
            let data = try handle.read(upToCount: limit + 1) ?? Data()
            guard data.count <= limit else {
                throw GenomeImportError.inputLimitExceeded(actual: data.count, limit: limit)
            }
            return data
        } catch let error as GenomeImportError {
            throw error
        } catch {
            throw GenomeImportError.cannotReadSource(error.localizedDescription)
        }
    }

    private static func normalizedExtension(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func declaredContainer(for ext: String?) -> GenomeContainerKind? {
        switch ext {
        case "gz", "gzip": return .gzip
        case "zip": return .zip
        case "txt", "csv", "tsv", "vcf": return .plainText
        default: return nil
        }
    }
}

private enum ZlibWrapper {
    case gzip
    case rawDeflate

    var windowBits: Int32 {
        switch self {
        case .gzip: return Int32(MAX_WBITS + 16)
        case .rawDeflate: return -Int32(MAX_WBITS)
        }
    }
}

private enum ZlibDecoder {
    static func inflate(
        _ input: Data,
        wrapper: ZlibWrapper,
        expectedSize: Int?,
        limits: GenomeImportLimits
    ) throws -> Data {
        guard !input.isEmpty else { throw GenomeImportError.corruptArchive("empty compressed stream") }
        guard input.count <= Int(uInt.max) else {
            throw GenomeImportError.inputLimitExceeded(actual: input.count, limit: Int(uInt.max))
        }
        if let expectedSize {
            try validateExpansion(input: input.count, output: expectedSize, limits: limits)
        }

        var stream = z_stream()
        let initialized = inflateInit2_(
            &stream,
            wrapper.windowBits,
            ZLIB_VERSION,
            Int32(MemoryLayout<z_stream>.size)
        )
        guard initialized == Z_OK else {
            throw GenomeImportError.corruptArchive("zlib initialization failed (\(initialized))")
        }
        defer { inflateEnd(&stream) }

        var output = Data()
        if let expectedSize { output.reserveCapacity(min(expectedSize, limits.maximumExpandedBytes)) }
        var finalStatus: Int32 = Z_OK

        try input.withUnsafeBytes { rawInput in
            guard let inputBase = rawInput.bindMemory(to: Bytef.self).baseAddress else {
                throw GenomeImportError.corruptArchive("missing compressed bytes")
            }
            stream.next_in = UnsafeMutablePointer(mutating: inputBase)
            stream.avail_in = uInt(input.count)

            let chunkSize = 64 * 1_024
            var chunk = [UInt8](repeating: 0, count: chunkSize)
            while true {
                let beforeIn = stream.avail_in
                let beforeOut = output.count
                finalStatus = chunk.withUnsafeMutableBytes { rawOutput in
                    stream.next_out = rawOutput.bindMemory(to: Bytef.self).baseAddress
                    stream.avail_out = uInt(chunkSize)
                    return zlib.inflate(&stream, Z_NO_FLUSH)
                }
                let produced = chunkSize - Int(stream.avail_out)
                if produced > 0 {
                    let prospective = output.count + produced
                    try validateExpansion(input: input.count, output: prospective, limits: limits)
                    output.append(contentsOf: chunk.prefix(produced))
                }

                if finalStatus == Z_STREAM_END { break }
                guard finalStatus == Z_OK else {
                    let message = stream.msg.map { String(cString: $0) } ?? "zlib status \(finalStatus)"
                    throw GenomeImportError.corruptArchive(message)
                }
                if beforeIn == stream.avail_in && beforeOut == output.count {
                    throw GenomeImportError.corruptArchive("compressed stream made no progress")
                }
                if stream.avail_in == 0 && produced == 0 {
                    throw GenomeImportError.corruptArchive("compressed stream ended before its trailer")
                }
            }
        }

        guard finalStatus == Z_STREAM_END else {
            throw GenomeImportError.corruptArchive("compressed stream did not terminate")
        }
        guard stream.avail_in == 0 else {
            throw GenomeImportError.trailingArchiveData
        }
        if let expectedSize, output.count != expectedSize {
            throw GenomeImportError.corruptArchive(
                "expanded size \(output.count) does not match declared size \(expectedSize)"
            )
        }
        return output
    }

    private static func validateExpansion(input: Int, output: Int, limits: GenomeImportLimits) throws {
        guard output <= limits.maximumExpandedBytes else {
            throw GenomeImportError.expandedLimitExceeded(actual: output, limit: limits.maximumExpandedBytes)
        }
        let ratioLimit: Int
        if input > Int.max / limits.maximumCompressionRatio {
            ratioLimit = Int.max
        } else {
            ratioLimit = input * limits.maximumCompressionRatio
        }
        guard output <= ratioLimit else {
            throw GenomeImportError.compressionRatioExceeded(
                input: input,
                output: output,
                limit: limits.maximumCompressionRatio
            )
        }
    }
}

private enum StrictZipDecoder {
    struct Result {
        let data: Data
        let memberName: String
        let compressedByteCount: Int
    }

    static func decode(_ archive: Data, limits: GenomeImportLimits) throws -> Result {
        guard archive.count >= 22 else { throw GenomeImportError.corruptArchive("missing ZIP end record") }
        guard let eocd = findEndOfCentralDirectory(archive) else {
            throw GenomeImportError.corruptArchive("missing ZIP end record")
        }
        guard let disk = le16(archive, eocd + 4),
              let centralDisk = le16(archive, eocd + 6),
              let diskEntries = le16(archive, eocd + 8),
              let totalEntries = le16(archive, eocd + 10),
              let centralSize32 = le32(archive, eocd + 12),
              let centralOffset32 = le32(archive, eocd + 16),
              let commentLength = le16(archive, eocd + 20) else {
            throw GenomeImportError.corruptArchive("truncated ZIP end record")
        }
        guard eocd + 22 + Int(commentLength) == archive.count else {
            throw GenomeImportError.trailingArchiveData
        }
        guard disk == 0, centralDisk == 0, diskEntries == totalEntries else {
            throw GenomeImportError.unsupportedArchiveFeature("multi-disk ZIP")
        }
        guard totalEntries != UInt16.max,
              centralSize32 != UInt32.max,
              centralOffset32 != UInt32.max else {
            throw GenomeImportError.unsupportedArchiveFeature("ZIP64")
        }
        guard totalEntries == 1 else {
            throw GenomeImportError.archiveMemberCount(Int(totalEntries))
        }

        let centralOffset = Int(centralOffset32)
        let centralSize = Int(centralSize32)
        guard centralOffset >= 0,
              centralSize >= 46,
              centralOffset <= archive.count - centralSize,
              centralOffset + centralSize == eocd else {
            throw GenomeImportError.corruptArchive("invalid central-directory bounds")
        }
        guard le32(archive, centralOffset) == 0x02014b50 else {
            throw GenomeImportError.corruptArchive("invalid central-directory signature")
        }

        guard let versionMadeBy = le16(archive, centralOffset + 4),
              let flags = le16(archive, centralOffset + 8),
              let method = le16(archive, centralOffset + 10),
              let checksum = le32(archive, centralOffset + 16),
              let compressed32 = le32(archive, centralOffset + 20),
              let expanded32 = le32(archive, centralOffset + 24),
              let nameLength = le16(archive, centralOffset + 28),
              let extraLength = le16(archive, centralOffset + 30),
              let entryCommentLength = le16(archive, centralOffset + 32),
              let startDisk = le16(archive, centralOffset + 34),
              let externalAttributes = le32(archive, centralOffset + 38),
              let localOffset32 = le32(archive, centralOffset + 42) else {
            throw GenomeImportError.corruptArchive("truncated central-directory entry")
        }
        guard compressed32 != UInt32.max, expanded32 != UInt32.max, localOffset32 != UInt32.max else {
            throw GenomeImportError.unsupportedArchiveFeature("ZIP64 member")
        }
        guard startDisk == 0 else { throw GenomeImportError.unsupportedArchiveFeature("multi-disk member") }
        try validateFlags(flags, method: method)
        guard method == 0 || method == 8 else {
            throw GenomeImportError.unsupportedArchiveFeature("ZIP compression method \(method)")
        }

        let centralRecordSize = 46 + Int(nameLength) + Int(extraLength) + Int(entryCommentLength)
        guard centralRecordSize == centralSize else {
            throw GenomeImportError.corruptArchive("central directory declares hidden or extra records")
        }
        let centralNameStart = centralOffset + 46
        let centralNameEnd = centralNameStart + Int(nameLength)
        let centralExtraEnd = centralNameEnd + Int(extraLength)
        guard centralExtraEnd <= centralOffset + centralSize else {
            throw GenomeImportError.corruptArchive("truncated central filename or extra fields")
        }
        let centralNameData = archive.subdata(in: centralNameStart..<centralNameEnd)
        let centralExtra = archive.subdata(in: centralNameEnd..<centralExtraEnd)
        try validateExtraFields(centralExtra)
        guard let memberName = decodeZipName(centralNameData, utf8: flags & 0x0800 != 0) else {
            throw GenomeImportError.unsafeArchiveMember("undecodable filename")
        }
        try validateSafeRegularMember(
            memberName,
            versionMadeBy: versionMadeBy,
            externalAttributes: externalAttributes
        )

        let localOffset = Int(localOffset32)
        guard localOffset == 0 else {
            throw GenomeImportError.corruptArchive("unexpected bytes precede the ZIP member")
        }
        guard le32(archive, localOffset) == 0x04034b50,
              let localFlags = le16(archive, localOffset + 6),
              let localMethod = le16(archive, localOffset + 8),
              let localChecksum = le32(archive, localOffset + 14),
              let localCompressed = le32(archive, localOffset + 18),
              let localExpanded = le32(archive, localOffset + 22),
              let localNameLength = le16(archive, localOffset + 26),
              let localExtraLength = le16(archive, localOffset + 28) else {
            throw GenomeImportError.corruptArchive("truncated local ZIP header")
        }
        guard localFlags == flags, localMethod == method else {
            throw GenomeImportError.corruptArchive("local and central ZIP headers disagree")
        }
        let localNameStart = localOffset + 30
        let localNameEnd = localNameStart + Int(localNameLength)
        let localExtraEnd = localNameEnd + Int(localExtraLength)
        guard localExtraEnd <= centralOffset,
              archive.subdata(in: localNameStart..<localNameEnd) == centralNameData else {
            throw GenomeImportError.corruptArchive("local and central ZIP filenames disagree")
        }
        try validateExtraFields(archive.subdata(in: localNameEnd..<localExtraEnd))

        let compressedSize = Int(compressed32)
        let expandedSize = Int(expanded32)
        guard compressedSize <= limits.maximumInputBytes else {
            throw GenomeImportError.inputLimitExceeded(actual: compressedSize, limit: limits.maximumInputBytes)
        }
        try validateDeclaredExpansion(input: compressedSize, output: expandedSize, limits: limits)
        let payloadEnd = localExtraEnd + compressedSize
        guard payloadEnd <= centralOffset else {
            throw GenomeImportError.corruptArchive("ZIP payload exceeds its declared bounds")
        }

        let usesDescriptor = flags & 0x0008 != 0
        if usesDescriptor {
            try validateDataDescriptor(
                archive,
                start: payloadEnd,
                end: centralOffset,
                checksum: checksum,
                compressed: compressed32,
                expanded: expanded32
            )
        } else {
            guard payloadEnd == centralOffset else { throw GenomeImportError.trailingArchiveData }
            guard localChecksum == checksum,
                  localCompressed == compressed32,
                  localExpanded == expanded32 else {
                throw GenomeImportError.corruptArchive("local ZIP sizes or checksum disagree")
            }
        }

        let compressed = archive.subdata(in: localExtraEnd..<payloadEnd)
        let expanded: Data
        if method == 0 {
            guard compressedSize == expandedSize else {
                throw GenomeImportError.corruptArchive("stored ZIP member has unequal sizes")
            }
            expanded = compressed
        } else {
            expanded = try ZlibDecoder.inflate(
                compressed,
                wrapper: .rawDeflate,
                expectedSize: expandedSize,
                limits: limits
            )
        }

        guard checksumOf(expanded) == checksum else {
            throw GenomeImportError.archiveChecksumMismatch
        }
        return Result(data: expanded, memberName: memberName, compressedByteCount: compressedSize)
    }

    private static func findEndOfCentralDirectory(_ data: Data) -> Int? {
        let lowerBound = max(0, data.count - (65_535 + 22))
        var offset = data.count - 22
        while offset >= lowerBound {
            if le32(data, offset) == 0x06054b50 { return offset }
            if offset == lowerBound { break }
            offset -= 1
        }
        return nil
    }

    private static func validateFlags(_ flags: UInt16, method: UInt16) throws {
        if flags & 0x0001 != 0 { throw GenomeImportError.unsupportedArchiveFeature("encrypted ZIP") }
        if flags & 0x0020 != 0 { throw GenomeImportError.unsupportedArchiveFeature("patched ZIP data") }
        if flags & 0x0040 != 0 { throw GenomeImportError.unsupportedArchiveFeature("strong ZIP encryption") }
        if flags & 0x2000 != 0 { throw GenomeImportError.unsupportedArchiveFeature("masked ZIP headers") }
        var allowed: UInt16 = 0x0008 | 0x0800
        if method == 8 { allowed |= 0x0002 | 0x0004 }
        guard flags & ~allowed == 0 else {
            throw GenomeImportError.unsupportedArchiveFeature("ZIP flags 0x\(String(flags, radix: 16))")
        }
    }

    private static func validateSafeRegularMember(
        _ name: String,
        versionMadeBy: UInt16,
        externalAttributes: UInt32
    ) throws {
        guard !name.isEmpty,
              !name.hasPrefix("/"),
              !name.hasSuffix("/"),
              !name.contains("\\"),
              !name.contains("\0") else {
            throw GenomeImportError.unsafeArchiveMember(name)
        }
        let components = name.split(separator: "/", omittingEmptySubsequences: false)
        guard components.allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." }),
              components.first?.contains(":") != true else {
            throw GenomeImportError.unsafeArchiveMember(name)
        }
        guard externalAttributes & 0x10 == 0 else {
            throw GenomeImportError.unsafeArchiveMember(name)
        }
        let host = UInt8(versionMadeBy >> 8)
        if host == 3 || host == 19 {
            let mode = UInt16((externalAttributes >> 16) & 0xffff)
            let fileType = mode & 0xf000
            guard fileType == 0 || fileType == 0x8000 else {
                throw GenomeImportError.unsafeArchiveMember(name)
            }
        }
    }

    private static func validateExtraFields(_ extra: Data) throws {
        var cursor = 0
        while cursor < extra.count {
            guard cursor + 4 <= extra.count,
                  let identifier = le16(extra, cursor),
                  let size = le16(extra, cursor + 2),
                  cursor + 4 + Int(size) <= extra.count else {
                throw GenomeImportError.corruptArchive("malformed ZIP extra field")
            }
            if identifier == 0x0001 { throw GenomeImportError.unsupportedArchiveFeature("ZIP64 extra field") }
            if identifier == 0x9901 { throw GenomeImportError.unsupportedArchiveFeature("AES-encrypted ZIP") }
            cursor += 4 + Int(size)
        }
    }

    private static func validateDataDescriptor(
        _ archive: Data,
        start: Int,
        end: Int,
        checksum: UInt32,
        compressed: UInt32,
        expanded: UInt32
    ) throws {
        let hasSignature = end - start == 16 && le32(archive, start) == 0x08074b50
        let fieldsStart = hasSignature ? start + 4 : start
        guard end - fieldsStart == 12,
              le32(archive, fieldsStart) == checksum,
              le32(archive, fieldsStart + 4) == compressed,
              le32(archive, fieldsStart + 8) == expanded else {
            throw GenomeImportError.corruptArchive("invalid ZIP data descriptor")
        }
    }

    private static func validateDeclaredExpansion(
        input: Int,
        output: Int,
        limits: GenomeImportLimits
    ) throws {
        guard output <= limits.maximumExpandedBytes else {
            throw GenomeImportError.expandedLimitExceeded(actual: output, limit: limits.maximumExpandedBytes)
        }
        let ratioLimit = input > Int.max / limits.maximumCompressionRatio
            ? Int.max
            : input * limits.maximumCompressionRatio
        guard output <= ratioLimit else {
            throw GenomeImportError.compressionRatioExceeded(
                input: input,
                output: output,
                limit: limits.maximumCompressionRatio
            )
        }
    }

    private static func decodeZipName(_ data: Data, utf8: Bool) -> String? {
        if utf8 { return String(data: data, encoding: .utf8) }
        return String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1)
    }

    private static func checksumOf(_ data: Data) -> UInt32 {
        data.withUnsafeBytes { raw in
            let bytes = raw.bindMemory(to: Bytef.self).baseAddress
            return UInt32(crc32(0, bytes, uInt(data.count)))
        }
    }

    private static func le16(_ data: Data, _ offset: Int) -> UInt16? {
        guard offset >= 0, offset <= data.count - 2 else { return nil }
        return UInt16(data[offset]) | (UInt16(data[offset + 1]) << 8)
    }

    private static func le32(_ data: Data, _ offset: Int) -> UInt32? {
        guard offset >= 0, offset <= data.count - 4 else { return nil }
        return UInt32(data[offset])
            | (UInt32(data[offset + 1]) << 8)
            | (UInt32(data[offset + 2]) << 16)
            | (UInt32(data[offset + 3]) << 24)
    }
}
