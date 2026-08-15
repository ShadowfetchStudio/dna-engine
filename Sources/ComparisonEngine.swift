import Foundation

/// Raw-array concordance only.
///
/// This engine intentionally does not estimate kinship, IBD, or a relationship
/// degree. Those analyses require allele-frequency-aware, LD-pruned, build- and
/// ancestry-aware methods plus validated orientation handling. Here we report
/// only what the two imported files directly support: shared autosomal calls and
/// raw genotype/allele overlap.
enum ComparisonEngine {
    static func compare(genomeA: ParsedGenome, nameA: String, genomeB: ParsedGenome, nameB: String) -> GenomeComparison {
        var shared = 0
        var exact = 0
        var oneAllele = 0
        var noAllele = 0

        for (rsid, callA) in genomeA.calls {
            guard !callA.isNoCall, GenomeStats.isAutosome(callA.chromosome) else { continue }
            guard let callB = genomeB.calls[rsid], !callB.isNoCall,
                  GenomeStats.isAutosome(callB.chromosome) else { continue }

            shared += 1
            switch rawOverlap(callA: callA, callB: callB) {
            case .exact: exact += 1
            case .oneAllele: oneAllele += 1
            case .none: noAllele += 1
            }
        }

        let denominator = Double(max(shared, 1))
        let concordance = Double(exact) / denominator
        let oneAlleleFraction = Double(oneAllele) / denominator
        let noAlleleFraction = Double(noAllele) / denominator
        let summary: String
        if shared == 0 {
            summary = "No comparable called autosomal rsIDs were found."
        } else {
            summary = String(
                format: "Raw exact-genotype concordance is %.1f%% across %@ shared called autosomal rsIDs. This research similarity measure does not infer kinship or a biological relationship.",
                concordance * 100,
                shared.formatted()
            )
        }

        return GenomeComparison(
            profileNameA: nameA,
            profileNameB: nameB,
            totalComparedSNPs: shared,
            exactGenotypeMatchCount: exact,
            oneAlleleOverlapCount: oneAllele,
            noAlleleOverlapCount: noAllele,
            exactGenotypeConcordance: concordance,
            oneAlleleOverlapFraction: oneAlleleFraction,
            noAlleleOverlapFraction: noAlleleFraction,
            researchSimilaritySummary: summary,
            estimatedRelationship: .notInferred,
            comparedTraits: []
        )
    }

    private enum RawOverlap {
        case exact, oneAllele, none
    }

    private static func rawOverlap(callA: SNPCall, callB: SNPCall) -> RawOverlap {
        if callA.genotypeKey == callB.genotypeKey { return .exact }
        let allelesA = Set([callA.allele1, callA.allele2])
        let allelesB = Set([callB.allele1, callB.allele2])
        return allelesA.isDisjoint(with: allelesB) ? .none : .oneAllele
    }
}
