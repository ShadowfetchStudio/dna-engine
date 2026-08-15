import Foundation

enum Vendor: String {
    case ancestry = "AncestryDNA"
    case twentyThree = "23andMe"
    case myHeritage = "MyHeritage"
    case ftdna = "FamilyTreeDNA"
    case livingDNA = "LivingDNA"
    case nebula = "Nebula Genomics / VCF"
    case generic = "Generic raw DNA"
}

struct ParsedGenome {
    var vendor: Vendor
    var buildHint: String
    var calls: [String: SNPCall]
    var ordered: [SNPCall]
    var chromosomeIndex: [String: [SNPCall]]
    let receipt: GenomeImportReceipt
}

enum GenomeParser {
    static func parse(url: URL, progress: ((Double, String) -> Void)? = nil) throws -> ParsedGenome {
        try parse(request: GenomeImportRequest(sourceURL: url), progress: progress)
    }

    static func parse(
        url: URL,
        options: GenomeImportOptions,
        progress: ((Double, String) -> Void)? = nil
    ) throws -> ParsedGenome {
        try parse(request: GenomeImportRequest(sourceURL: url, options: options), progress: progress)
    }

    static func parse(
        request: GenomeImportRequest,
        progress: ((Double, String) -> Void)? = nil
    ) throws -> ParsedGenome {
        progress?(0.05, "Reading and validating input…")
        let decoded = try GenomeSourceDecoder.decode(request: request)
        if let archive = decoded.archiveReceipt {
            progress?(0.12, "Validated \(archive.container.rawValue) archive…")
        }
        return try parseContent(
            text: decoded.text,
            source: decoded.descriptor,
            archive: decoded.archiveReceipt,
            options: request.options,
            initialNotices: decoded.notices,
            progress: progress
        )
    }

    static func parse(
        data: Data,
        sourceName: String,
        options: GenomeImportOptions = .standard,
        progress: ((Double, String) -> Void)? = nil
    ) throws -> ParsedGenome {
        progress?(0.05, "Validating in-memory input…")
        let decoded = try GenomeSourceDecoder.decode(
            data: data,
            displayName: sourceName,
            options: options
        )
        if let archive = decoded.archiveReceipt {
            progress?(0.12, "Validated in-memory \(archive.container.rawValue) archive…")
        }
        return try parseContent(
            text: decoded.text,
            source: decoded.descriptor,
            archive: decoded.archiveReceipt,
            options: options,
            initialNotices: decoded.notices,
            progress: progress
        )
    }

    static func parse(text: String, progress: ((Double, String) -> Void)? = nil) throws -> ParsedGenome {
        try parse(text: text, options: .standard, progress: progress)
    }

    static func parse(
        text: String,
        options: GenomeImportOptions,
        sourceName: String = "In-memory genome text",
        progress: ((Double, String) -> Void)? = nil
    ) throws -> ParsedGenome {
        let byteCount = text.lengthOfBytes(using: .utf8)
        guard byteCount <= options.limits.maximumInputBytes else {
            throw GenomeImportError.inputLimitExceeded(
                actual: byteCount,
                limit: options.limits.maximumInputBytes
            )
        }
        guard byteCount <= options.limits.maximumExpandedBytes else {
            throw GenomeImportError.expandedLimitExceeded(
                actual: byteCount,
                limit: options.limits.maximumExpandedBytes
            )
        }
        let source = GenomeSourceDescriptor(
            displayName: sourceName,
            originalExtension: nil,
            declaredContainer: nil,
            detectedContainer: .plainText,
            inputByteCount: byteCount,
            expandedByteCount: byteCount,
            archiveMemberName: nil
        )
        return try parseContent(
            text: text,
            source: source,
            archive: nil,
            options: options,
            initialNotices: [],
            progress: progress
        )
    }

    private static func parseContent(
        text: String,
        source: GenomeSourceDescriptor,
        archive: GenomeArchiveReceipt?,
        options: GenomeImportOptions,
        initialNotices: [GenomeImportNotice],
        progress: ((Double, String) -> Void)?
    ) throws -> ParsedGenome {
        let lines = text.split(omittingEmptySubsequences: false, whereSeparator: { $0.isNewline })
        var vendor = Vendor.generic
        var buildHint = "GRCh37 / hg19 (typical consumer arrays)"
        var headerSeen = false
        var format = GenomeTextFormat.unknown
        var calls = [String: SNPCall](minimumCapacity: 800_000)
        var ordered = [SNPCall]()
        ordered.reserveCapacity(800_000)
        var diagnostics = DiagnosticsBuilder(exampleLimit: options.limits.maximumDiagnosticExamples)
        var notices = initialNotices
        var sampleSelection: VCFSampleSelectionReceipt?
        var implicitSampleNoticeAdded = false

        let total = max(lines.count, 1)
        var processed = 0

        for lineSub in lines {
            processed += 1
            if processed.isMultiple(of: 50_000) {
                let frac = Double(processed) / Double(total)
                progress?(0.20 + frac * 0.70, "Indexing variants… \(calls.count.formatted())")
            }
            let line = String(lineSub).trimmingCharacters(in: CharacterSet.whitespaces)
            if line.isEmpty { continue }
            let lower = line.lowercased()

            if lower.hasPrefix("#chrom") {
                headerSeen = true
                format = .vcf
                vendor = .nebula
                sampleSelection = try selectVCFSample(
                    headerColumns: splitCols(line),
                    requested: options.selectedVCFSample
                )
                if let selection = sampleSelection, selection.mode == .defaultedToFirst {
                    notices.append(GenomeImportNotice(
                        code: .vcfSampleDefaulted,
                        message: "No VCF sample was requested; defaulted to the first of \(selection.availableSamples.count) samples (\(selection.selectedSample))."
                    ))
                }
                continue
            }

            if line.hasPrefix("#") || line.hasPrefix("[") {
                if lower.contains("ancestrydna") { vendor = .ancestry }
                else if lower.contains("23andme") { vendor = .twentyThree }
                else if lower.contains("myheritage") { vendor = .myHeritage }
                else if lower.contains("ftdna") || lower.contains("family tree dna") { vendor = .ftdna }
                else if lower.contains("livingdna") || lower.contains("living dna") { vendor = .livingDNA }
                else if lower.contains("fileformat=vcf") || lower.contains("nebula") { vendor = .nebula; format = .vcf }
                
                if lower.contains("grch38") || lower.contains("hg38") { buildHint = "GRCh38 / hg38" }
                if lower.contains("grch37") || lower.contains("hg19") { buildHint = "GRCh37 / hg19" }
                continue
            }

            if !headerSeen && isHeader(line) {
                headerSeen = true
                format = detectFormat(line)
                continue
            }

            let cols = splitCols(line)
            if format == .unknown && looksLikeVCFRecord(cols) {
                format = .vcf
                vendor = .nebula
            }

            diagnostics.totalRecords += 1
            let disposition: RecordDisposition
            if format == .vcf {
                if sampleSelection == nil {
                    if let requested = options.selectedVCFSample {
                        throw ParseError.vcfHeaderRequiredForSample(requested)
                    }
                    sampleSelection = VCFSampleSelectionReceipt(
                        availableSamples: [],
                        selectedSample: "first sample column",
                        selectedColumn: 9,
                        mode: .implicitFirstColumn
                    )
                    if !implicitSampleNoticeAdded {
                        notices.append(GenomeImportNotice(
                            code: .implicitVCFSampleColumn,
                            message: "The VCF has no #CHROM sample header; used the first sample column and recorded that fallback."
                        ))
                        implicitSampleNoticeAdded = true
                    }
                }
                disposition = makeVCFCall(cols: cols, sampleColumn: sampleSelection!.selectedColumn)
            } else {
                disposition = makeArrayCall(cols: cols, format: format)
            }

            switch disposition {
            case .malformed(let message):
                diagnostics.recordSkipped(.malformed, line: processed, message: message)
            case .unsupported(let message):
                diagnostics.recordSkipped(.unsupported, line: processed, message: message)
            case .filtered(let message):
                diagnostics.filteredRecords += 1
                diagnostics.recordSkipped(.filtered, line: processed, message: message)
            case .accepted(let call):
                if let existing = calls[call.rsid] {
                    if existing == call {
                        diagnostics.recordSkipped(.duplicate, line: processed, message: "Duplicate \(call.rsid) repeats the accepted call.")
                    } else {
                        diagnostics.recordSkipped(.conflict, line: processed, message: "Conflicting duplicate \(call.rsid) was not substituted.")
                    }
                    continue
                }
                calls[call.rsid] = call
                ordered.append(call)
                diagnostics.acceptedRecords += 1
                if call.isNoCall { diagnostics.noCallRecords += 1 }
            }
        }

        if calls.count < options.minimumAcceptedRecords {
            throw ParseError.tooFewSNPs(calls.count)
        }
        if options.selectedVCFSample != nil, format != .vcf {
            throw ParseError.sampleSelectionRequiresVCF
        }
        if vendor == .generic {
            vendor = inferVendor(format: format, sample: ordered.prefix(30).map(\.rsid))
        }

        var chromIndex = [String: [SNPCall]]()
        for call in ordered {
            chromIndex[call.chromosome, default: []].append(call)
        }

        progress?(1.0, "Indexed \(calls.count.formatted()) variants across \(chromIndex.keys.count) chromosomes")
        let finalDiagnostics = diagnostics.makeDiagnostics()
        guard finalDiagnostics.reconciles else { throw ParseError.diagnosticsDidNotReconcile }
        let receipt = GenomeImportReceipt(
            source: source,
            archive: archive,
            requestedVCFSample: options.selectedVCFSample,
            selectedVCFSample: sampleSelection,
            detectedFormat: format,
            diagnostics: finalDiagnostics,
            notices: notices
        )
        return ParsedGenome(
            vendor: vendor,
            buildHint: buildHint,
            calls: calls,
            ordered: ordered,
            chromosomeIndex: chromIndex,
            receipt: receipt
        )
    }

    enum ParseError: LocalizedError {
        case unreadable
        case tooFewSNPs(Int)
        case decompressionFailed(String)
        case malformedVCFHeader(String)
        case vcfSampleNotFound(requested: String, available: [String])
        case vcfHeaderRequiredForSample(String)
        case sampleSelectionRequiresVCF
        case diagnosticsDidNotReconcile
        
        var errorDescription: String? {
            switch self {
            case .unreadable: return "Could not read file contents as text."
            case .tooFewSNPs(let n):
                return "Only found \(n) valid SNP calls. DNA raw data files typically contain 500,000–1,000,000+ rows."
            case .decompressionFailed(let msg):
                return "Failed to decompress archive: \(msg)"
            case .malformedVCFHeader(let message):
                return "The VCF sample header is malformed: \(message)"
            case .vcfSampleNotFound(let requested, let available):
                return "VCF sample \(requested) was not found. Available samples: \(available.joined(separator: ", "))."
            case .vcfHeaderRequiredForSample(let requested):
                return "VCF sample \(requested) cannot be selected because the file has no #CHROM sample header."
            case .sampleSelectionRequiresVCF:
                return "A VCF sample was requested, but the input is not VCF data."
            case .diagnosticsDidNotReconcile:
                return "Internal import accounting did not reconcile; no result was returned."
            }
        }
    }

    private enum RecordDisposition {
        case accepted(SNPCall)
        case malformed(String)
        case unsupported(String)
        case filtered(String)
    }

    private struct DiagnosticsBuilder {
        var totalRecords = 0
        var acceptedRecords = 0
        var duplicateRecords = 0
        var conflictRecords = 0
        var malformedRecords = 0
        var unsupportedRecords = 0
        var filteredRecords = 0
        var noCallRecords = 0
        var examples: [GenomeRecordDiagnostic] = []
        let exampleLimit: Int

        mutating func recordSkipped(
            _ code: GenomeRecordDiagnosticCode,
            line: Int,
            message: String
        ) {
            switch code {
            case .malformed: malformedRecords += 1
            case .unsupported, .filtered: unsupportedRecords += 1
            case .duplicate: duplicateRecords += 1
            case .conflict: conflictRecords += 1
            }
            if examples.count < exampleLimit {
                examples.append(GenomeRecordDiagnostic(lineNumber: line, code: code, message: message))
            }
        }

        func makeDiagnostics() -> GenomeParseDiagnostics {
            let skipped = duplicateRecords + conflictRecords + malformedRecords + unsupportedRecords
            return GenomeParseDiagnostics(
                totalRecords: totalRecords,
                acceptedRecords: acceptedRecords,
                skippedRecords: skipped,
                duplicateRecords: duplicateRecords,
                conflictRecords: conflictRecords,
                malformedRecords: malformedRecords,
                unsupportedRecords: unsupportedRecords,
                filteredRecords: filteredRecords,
                noCallRecords: noCallRecords,
                examples: examples
            )
        }
    }

    private static func isHeader(_ line: String) -> Bool {
        let lower = line.lowercased()
        if lower.hasPrefix("#chrom") || lower.contains("chrom\tpos\tid") { return true }
        return lower.contains("rsid") && (lower.contains("allele") || lower.contains("genotype") || lower.contains("chromosome"))
    }

    private static func detectFormat(_ line: String) -> GenomeTextFormat {
        let lower = line.lowercased()
        if lower.contains("#chrom") || lower.contains("ref\talt") { return .vcf }
        if lower.contains("allele1") { return .ancestryAlleles }
        if lower.contains("genotype") { return .genotype }
        return .unknown
    }

    private static func splitCols(_ line: String) -> [String] {
        if line.contains("\t") { return line.split(separator: "\t", omittingEmptySubsequences: false).map(String.init) }
        if line.contains(",") { return line.split(separator: ",", omittingEmptySubsequences: false).map(String.init) }
        return line.split(whereSeparator: { $0.isWhitespace }).map(String.init)
    }

    private static func makeArrayCall(cols: [String], format: GenomeTextFormat) -> RecordDisposition {
        guard cols.count >= 4 else { return .malformed("Expected at least four columns.") }
        let rsid = cols[0].trimmingCharacters(in: .whitespaces)
        guard supportedIdentifier(rsid) else { return .unsupported("The row has no supported variant identifier.") }
        let chrom = normalizeChrom(cols[1])
        guard !chrom.isEmpty else { return .malformed("Chromosome is empty.") }
        guard let pos = Int(cols[2].trimmingCharacters(in: .whitespaces)), pos > 0 else {
            return .malformed("Position is not a positive integer.")
        }

        let a1: Character
        let a2: Character
        switch format {
        case .ancestryAlleles:
            guard cols.count >= 5 else { return .malformed("Ancestry allele rows require five columns.") }
            guard let left = parseArrayAllele(cols[3]), let right = parseArrayAllele(cols[4]) else {
                return .unsupported("Alleles must be single A/C/G/T bases or explicit no-calls.")
            }
            a1 = left
            a2 = right
        case .genotype, .unknown:
            if cols.count >= 5,
               let left = parseArrayAllele(cols[3]),
               let right = parseArrayAllele(cols[4]) {
                a1 = left
                a2 = right
            } else {
                let gt = cols[3].replacingOccurrences(of: "\"", with: "").trimmingCharacters(in: .whitespaces)
                guard gt.count == 2,
                      let left = parseArrayAllele(String(gt.prefix(1))),
                      let right = parseArrayAllele(String(gt.suffix(1))) else {
                    return .unsupported("Genotype must contain exactly two supported alleles.")
                }
                a1 = left
                a2 = right
            }
        case .vcf:
            return .malformed("VCF row reached the array parser.")
        }
        return .accepted(SNPCall(rsid: rsid, chromosome: chrom, position: pos, allele1: a1, allele2: a2))
    }

    private static func makeVCFCall(cols: [String], sampleColumn: Int) -> RecordDisposition {
        // VCF format: CHROM POS ID REF ALT QUAL FILTER INFO FORMAT SAMPLE
        guard cols.count >= 9, sampleColumn >= 9, cols.count > sampleColumn else {
            return .malformed("VCF record does not contain the selected sample column.")
        }
        let chrom = normalizeChrom(cols[0])
        guard !chrom.isEmpty else { return .malformed("VCF chromosome is empty.") }
        guard let pos = Int(cols[1].trimmingCharacters(in: .whitespaces)), pos > 0 else {
            return .malformed("VCF position is not a positive integer.")
        }
        let ids = cols[2].split(separator: ";").map(String.init)
        guard let rsid = ids.first(where: supportedIdentifier) else {
            return .unsupported("VCF record has no supported variant identifier.")
        }
        let ref = cols[3].trimmingCharacters(in: .whitespaces).uppercased()
        let alt = cols[4].trimmingCharacters(in: .whitespaces).uppercased()
        if alt.contains(",") { return .unsupported("Multiallelic VCF records are not imported.") }
        guard isSingleBase(ref), isSingleBase(alt) else {
            return .unsupported("Indels and symbolic/non-SNP alleles are not imported.")
        }
        let filter = cols[6].trimmingCharacters(in: .whitespaces)
        guard filter == "PASS" || filter == "." else {
            return .filtered("VCF FILTER is \(filter), not PASS or '.'.")
        }

        let formatFields = cols[8].split(separator: ":", omittingEmptySubsequences: false).map(String.init)
        guard let gtIndex = formatFields.firstIndex(of: "GT") else {
            return .malformed("VCF FORMAT does not declare GT.")
        }
        let sampleFields = cols[sampleColumn]
            .trimmingCharacters(in: .whitespaces)
            .split(separator: ":", omittingEmptySubsequences: false)
            .map(String.init)
        guard gtIndex < sampleFields.count, !sampleFields[gtIndex].isEmpty else {
            return .malformed("Selected VCF sample has no GT value at the FORMAT index.")
        }
        let genotype = sampleFields[gtIndex]
        let separatorCount = genotype.reduce(into: 0) { count, character in
            if character == "/" || character == "|" { count += 1 }
        }
        guard separatorCount == 1 else {
            return .unsupported("Only diploid VCF genotypes are supported.")
        }
        let alleleCodes = genotype.split(
            omittingEmptySubsequences: false,
            whereSeparator: { $0 == "/" || $0 == "|" }
        ).map(String.init)
        guard alleleCodes.count == 2, alleleCodes.allSatisfy({ !$0.isEmpty }) else {
            return .malformed("VCF GT is not a complete diploid genotype.")
        }
        guard let refBase = ref.first, let altBase = alt.first else {
            return .unsupported("VCF alleles are not supported SNP bases.")
        }
        func resolve(_ code: String) -> Character? {
            switch code {
            case "0": return refBase
            case "1": return altBase
            case ".": return "-"
            default: return nil
            }
        }
        guard let a1 = resolve(alleleCodes[0]), let a2 = resolve(alleleCodes[1]) else {
            return .unsupported("VCF GT references an unsupported allele index.")
        }
        return .accepted(SNPCall(rsid: rsid, chromosome: chrom, position: pos, allele1: a1, allele2: a2))
    }

    private static func parseArrayAllele(_ raw: String) -> Character? {
        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\"", with: "").uppercased()
        guard t.count == 1, let base = t.first, "ACGT0-DI".contains(base) else { return nil }
        return base
    }

    private static func isSingleBase(_ raw: String) -> Bool {
        raw.count == 1 && raw.allSatisfy { "ACGT".contains($0) }
    }

    private static func supportedIdentifier(_ value: String) -> Bool {
        value.hasPrefix("rs") || value.hasPrefix("i") || value.hasPrefix("vg")
    }

    private static func looksLikeVCFRecord(_ cols: [String]) -> Bool {
        cols.count >= 10
            && Int(cols[1].trimmingCharacters(in: .whitespaces)) != nil
            && cols[8].split(separator: ":", omittingEmptySubsequences: false).contains("GT")
    }

    private static func selectVCFSample(
        headerColumns: [String],
        requested: String?
    ) throws -> VCFSampleSelectionReceipt {
        guard headerColumns.count >= 10,
              headerColumns[0].lowercased() == "#chrom",
              headerColumns[8] == "FORMAT" else {
            throw ParseError.malformedVCFHeader("Expected #CHROM through FORMAT and at least one sample name.")
        }
        let samples = Array(headerColumns.dropFirst(9))
        guard samples.allSatisfy({ !$0.isEmpty }), Set(samples).count == samples.count else {
            throw ParseError.malformedVCFHeader("Sample names must be nonempty and unique.")
        }
        if let requested {
            guard let sampleOffset = samples.firstIndex(of: requested) else {
                throw ParseError.vcfSampleNotFound(requested: requested, available: samples)
            }
            return VCFSampleSelectionReceipt(
                availableSamples: samples,
                selectedSample: requested,
                selectedColumn: sampleOffset + 9,
                mode: .explicitlySelected
            )
        }
        let mode: VCFSampleSelectionMode = samples.count == 1 ? .onlySample : .defaultedToFirst
        return VCFSampleSelectionReceipt(
            availableSamples: samples,
            selectedSample: samples[0],
            selectedColumn: 9,
            mode: mode
        )
    }

    private static func normalizeChrom(_ raw: String) -> String {
        var c = raw.trimmingCharacters(in: .whitespaces).uppercased()
        if c.hasPrefix("CHR") { c.removeFirst(3) }
        if c == "23" { return "X" }
        if c == "24" { return "Y" }
        if c == "25" || c == "26" || c == "M" || c == "MTDNA" { return "MT" }
        if c == "XY" { return "X" }
        return c
    }

    private static func inferVendor(format: GenomeTextFormat, sample: [String]) -> Vendor {
        if format == .ancestryAlleles { return .ancestry }
        if format == .vcf { return .nebula }
        if sample.contains(where: { $0.hasPrefix("i") }) { return .ancestry }
        return .generic
    }
}

enum GenomeStats {
    static func summarize(parsed: ParsedGenome, sourcePath: String, fileName: String) -> GenomeFile {
        var chromCounts: [String: Int] = [:]
        var called = 0
        var noCall = 0
        var autoHet = 0
        var autoCalled = 0
        var xHet = 0
        var xCalled = 0

        for call in parsed.ordered {
            chromCounts[call.chromosome, default: 0] += 1
            if call.isNoCall {
                noCall += 1
                continue
            }
            called += 1
            if isAutosome(call.chromosome) {
                autoCalled += 1
                if call.isHeterozygous { autoHet += 1 }
            } else if call.chromosome == "X" {
                xCalled += 1
                if call.isHeterozygous { xHet += 1 }
            }
        }

        let het = autoCalled > 0 ? Double(autoHet) / Double(autoCalled) : 0
        let xHetRate = xCalled > 0 ? Double(xHet) / Double(xCalled) : 0
        let yCount = chromCounts["Y", default: 0]
        let sex: String
        if yCount > 200 && xHetRate < 0.08 {
            sex = "Likely XY (Male)"
        } else if xHetRate >= 0.12 {
            sex = "Likely XX (Female)"
        } else if yCount > 50 {
            sex = "Likely XY (Male - low Y coverage)"
        } else {
            sex = "Sex-chromosome signal inconclusive"
        }

        return GenomeFile(
            sourcePath: sourcePath,
            fileName: fileName,
            vendor: parsed.vendor.rawValue,
            importedAt: Date(),
            snpCount: parsed.ordered.count,
            calledCount: called,
            noCallCount: noCall,
            autosomalHet: het,
            inferredSex: sex,
            chromosomeCounts: chromCounts,
            buildHint: parsed.buildHint
        )
    }

    static func isAutosome(_ chrom: String) -> Bool {
        if let n = Int(chrom), (1...22).contains(n) { return true }
        return false
    }
}
