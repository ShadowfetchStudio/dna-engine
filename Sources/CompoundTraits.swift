import Foundation

/// Data-driven compound/diplotype interpreter (feature 3).
///
/// The 715 lines of hardcoded per-compound Swift logic moved into
/// knowledge.json (`compounds`, authored in Tools/knowledge_sections/compounds.py).
/// This engine evaluates those rules; run_checks.sh holds a byte-parity
/// snapshot of the 20 migrated compounds against the pre-migration Swift
/// output on the demo persona (Tools/fixtures/parity_pre_migration.json).
///
/// Semantics (must mirror compounds.py's documented contract):
///   gt(rsid)      sorted genotype key of a .matched hit, else "--"
///   requireTyped  any listed rsid untyped -> emit the partial outcome
///   rules         first rule whose every condition holds wins
///   kind "count"  sum matching alleles over countSnps, pick the band
///   fallback      when nothing matches
enum CompoundTraits {
    static let researchValue = "Research rule coverage only"
    static let researchDetail = "Referenced loci are retained for research provenance. No genotype-derived activity, phenotype, diagnosis, risk, sensitivity, or personal outcome is inferred."

    static func build(hits: [MarkerHit], calls: [String: SNPCall]) -> [CompoundTrait] {
        guard let defs = KnowledgeBase.shared.compounds, !defs.isEmpty else { return [] }
        let by = Dictionary(uniqueKeysWithValues: hits.map { ($0.rsid, $0) })
        return defs.map { evaluate(def: $0, by: by) }
    }

    private static func gt(_ by: [String: MarkerHit], _ rsid: String) -> String {
        guard let h = by[rsid], h.coverage == .matched else { return "--" }
        return h.genotypeKey
    }

    private static func evaluate(def: CompoundDef, by: [String: MarkerHit]) -> CompoundTrait {
        // Refuse-to-call path: never guess a diplotype from a partial set.
        if let required = def.requireTyped, def.partial != nil {
            let untyped = required.filter { gt(by, $0) == "--" }
            if !untyped.isEmpty {
                let typedCount = required.count - untyped.count
                return CompoundTrait(
                    id: def.id,
                    title: def.title,
                    value: researchValue,
                    detail: researchDetail + " Coverage: \(typedCount)/\(required.count) required loci present.",
                    impact: .typical,
                    rsids: def.rsids
                )
            }
        }

        if def.kind == "count", let snps = def.countSnps, let bands = def.bands {
            let anyTyped = snps.contains { gt(by, $0.rsid) != "--" }
            guard anyTyped else {
                return out(def, def.fallback)
            }
            var total = 0
            for s in snps {
                let key = gt(by, s.rsid)
                guard key != "--", let allele = s.allele.uppercased().first else { continue }
                total += key.uppercased().filter { $0 == allele }.count
            }
            if bands.contains(where: { total >= $0.min && total <= $0.max }) {
                return CompoundTrait(id: def.id, title: def.title, value: researchValue,
                                     detail: researchDetail, impact: .typical, rsids: def.rsids)
            }
            return out(def, def.fallback)
        }

        for rule in def.rules ?? [] {
            if rule.when.allSatisfy({ holds($0, by: by) }) {
                return CompoundTrait(id: def.id, title: def.title, value: researchValue,
                                     detail: researchDetail, impact: .typical, rsids: def.rsids)
            }
        }
        return out(def, def.fallback)
    }

    private static func out(_ def: CompoundDef, _ o: CompoundOutcome) -> CompoundTrait {
        CompoundTrait(id: def.id, title: def.title, value: researchValue,
                      detail: researchDetail, impact: .typical, rsids: def.rsids)
    }

    private static func holds(_ cond: CompoundCond, by: [String: MarkerHit]) -> Bool {
        guard let rsid = cond.rsid else { return false }
        let key = gt(by, rsid)

        if let exact = cond.gt {
            return key == exact
        }
        if let members = cond.gtIn {
            return members.contains(key)
        }
        if let allele = cond.hasAllele, let c = allele.uppercased().first {
            return key != "--" && key.uppercased().contains(c)
        }
        if let allele = cond.countAllele, let c = allele.uppercased().first {
            let n = key == "--" ? 0 : key.uppercased().filter { $0 == c }.count
            let lo = cond.min ?? 0
            let hi = cond.max ?? 2
            return n >= lo && n <= hi
        }
        return false
    }
}
