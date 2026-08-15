import Foundation

enum KnowledgeBase {
    static let shared: KnowledgeFile = load()

    private static func load() -> KnowledgeFile {
        let urls: [URL] = [
            Bundle.main.url(forResource: "knowledge", withExtension: "json"),
            URL(fileURLWithPath: "Resources/knowledge.json"),
            URL(fileURLWithPath: AppPaths.support.path).appendingPathComponent("knowledge.json")
        ].compactMap { $0 }

        let fm = FileManager.default
        let extras = (try? fm.contentsOfDirectory(atPath: Bundle.main.resourcePath ?? "")) ?? []
        var candidates = urls
        if let resourcePath = Bundle.main.resourcePath {
            candidates.append(URL(fileURLWithPath: resourcePath).appendingPathComponent("knowledge.json"))
        }
        _ = extras

        for url in candidates {
            if let data = try? Data(contentsOf: url),
               let file = try? JSONDecoder().decode(KnowledgeFile.self, from: data) {
                return file
            }
        }

        // swiftc bundles put resources next to the executable's ../Resources
        if let exe = Bundle.main.executableURL {
            let bundled = exe.deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Resources/knowledge.json")
            if let data = try? Data(contentsOf: bundled),
               let file = try? JSONDecoder().decode(KnowledgeFile.self, from: data) {
                return file
            }
        }

        fatalError("knowledge.json is missing from the app bundle. Rebuild with build.sh.")
    }

    static func marker(rsid: String) -> MarkerDef? {
        index[rsid]
    }

    private static let index: [String: MarkerDef] = {
        Dictionary(uniqueKeysWithValues: shared.markers.map { ($0.rsid, $0) })
    }()
}

enum Strand {
    static func complement(_ c: Character) -> Character {
        switch c {
        case "A": return "T"
        case "T": return "A"
        case "C": return "G"
        case "G": return "C"
        default: return c
        }
    }

    static func complementGenotype(_ key: String) -> String {
        String(key.map { complement($0) }).sortedKey
    }

    static func isPalindromic(alleleA: String, alleleB: String) -> Bool {
        let pair = Set([alleleA.uppercased(), alleleB.uppercased()])
        return pair == Set(["A", "T"]) || pair == Set(["C", "G"])
    }
}

extension String {
    var sortedKey: String {
        guard count >= 2 else { return self }
        let chars = Array(self)
        let a = String(chars[0]), b = String(chars[1])
        return a <= b ? a + b : b + a
    }
}

enum MarkerMatcher {
    static let researchMechanism = "Published marker context only. DNA Engine does not translate this consumer-array genotype into enzyme activity, biological function, phenotype, diagnosis, risk, or a personal outcome."
    static let researchLabel = "Research locus observed"
    static let researchSummary = "Raw genotype recorded at this catalog locus. No genotype-to-outcome label or quantitative biological effect is inferred."
    static let researchDetail = "Identifiers, coverage, evidence tier, transferability, and citations are provided for independent research; the genotype is not a personalized interpretation."

    static func hit(marker: MarkerDef, call: SNPCall?) -> MarkerHit {
        guard let call else {
            return unmatched(marker, observed: "not on this chip", coverage: .missing)
        }
        if call.isNoCall {
            return unmatched(marker, observed: "no-call", coverage: .noCall)
        }

        // A/T and C/G definitions look identical after strand complementation.
        // Without a separately validated orientation manifest, even a direct
        // allele fit is not evidence of orientation. Fail closed before any
        // genotype or downstream compound interpretation can consume it.
        if Strand.isPalindromic(alleleA: marker.alleleA, alleleB: marker.alleleB) {
            return unmatched(marker, observed: call.display, coverage: .strandAmbiguous)
        }

        let expected = Set([marker.alleleA.uppercased(), marker.alleleB.uppercased()])
        let rawKey = call.genotypeKey.uppercased()
        if let matched = matchKey(rawKey, marker: marker, expected: expected) {
            return filled(marker, call: call, key: matched, coverage: .matched)
        }

        let flipped = Strand.complementGenotype(rawKey)
        if let matched = matchKey(flipped, marker: marker, expected: expected) {
            return filled(marker, call: call, key: matched, coverage: .matched)
        }

        return unmatched(marker, observed: call.display, coverage: .strandAmbiguous)
    }

    private static func matchKey(_ key: String, marker: MarkerDef, expected: Set<String>) -> String? {
        let chars = Array(key)
        guard chars.count >= 2 else { return nil }
        let obs = Set([String(chars[0]), String(chars[1])])
        guard obs.isSubset(of: expected) else { return nil }
        let sorted = key.sortedKey
        if marker.genotypes[sorted] != nil { return sorted }
        if marker.genotypes[key] != nil { return key }
        return sorted
    }

    private static func filled(_ marker: MarkerDef, call: SNPCall, key: String, coverage: MarkerHit.Coverage) -> MarkerHit {
        return MarkerHit(
            rsid: marker.rsid,
            gene: marker.gene,
            title: marker.title,
            chromosome: marker.chromosome,
            categories: marker.categories,
            mechanism: researchMechanism,
            evidence: marker.evidence,
            observed: call.display,
            genotypeKey: key,
            label: researchLabel,
            impact: .typical,
            summary: researchSummary,
            detail: researchDetail,
            // Catalog action strings are not surfaced as personalized plans.
            // Observed associations feed neutral research prompts instead.
            actions: [:],
            notes: "",
            coverage: coverage,
            tier: marker.tier,
            effect: nil,
            transferability: marker.transferability,
            citations: marker.citations
        )
    }

    private static func unmatched(_ marker: MarkerDef, observed: String, coverage: MarkerHit.Coverage) -> MarkerHit {
        let label: String
        let summary: String
        switch coverage {
        case .missing:
            label = "Not typed on this file"
            summary = "This SNP is not in the imported raw file. Consumer chips differ by version."
        case .noCall:
            label = "No call"
            summary = "The lab did not call this SNP with confidence."
        case .strandAmbiguous:
            label = "Strand unresolved"
            summary = "This observation is withheld because its strand orientation cannot be validated from this file."
        case .matched:
            label = "Not interpreted"
            summary = "This observation was not interpreted."
        }
        return MarkerHit(
            rsid: marker.rsid,
            gene: marker.gene,
            title: marker.title,
            chromosome: marker.chromosome,
            categories: marker.categories,
            mechanism: researchMechanism,
            evidence: marker.evidence,
            observed: observed,
            genotypeKey: "--",
            label: label,
            impact: .typical,
            summary: summary,
            detail: researchDetail,
            actions: [:],
            notes: "",
            coverage: coverage,
            tier: marker.tier,
            effect: nil,
            transferability: marker.transferability,
            citations: marker.citations
        )
    }
}
