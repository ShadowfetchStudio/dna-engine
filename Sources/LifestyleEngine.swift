import Foundation

/// Produces neutral research prompts, never genotype-directed plans.
///
/// Common array markers generally explain only a small part of lifestyle or
/// nutrient response. DNA Engine therefore does not select a supplement,
/// amount, schedule, food restriction, training plan, or treatment from them.
enum LifestyleEngine {
    static func buildChronoSchedule(hits: [MarkerHit], compounds: [CompoundTrait]) -> [ChronoProtocolItem] {
        let byRsid = Dictionary(uniqueKeysWithValues: hits.map { ($0.rsid, $0) })

        func context(_ rsids: [String], question: String) -> String {
            let resolved = rsids.filter { byRsid[$0]?.coverage == .matched }
            let coverage = resolved.isEmpty
                ? "No strand-resolved catalog marker is available for this topic."
                : "Strand-resolved observations are present at \(resolved.joined(separator: ", "))."
            return "\(coverage) \(question) A common marker association does not establish a personal schedule or response."
        }

        return [
            ChronoProtocolItem(
                id: "research-circadian",
                slot: .morning,
                title: "Circadian preference research question",
                rationale: context(
                    ["rs1801260"],
                    question: "Do your own sleep logs show a stable timing preference across workdays and free days?"
                ),
                pillar: .sleep,
                priority: 50,
                rsids: ["rs1801260"]
            ),
            ChronoProtocolItem(
                id: "research-caffeine",
                slot: .midday,
                title: "Caffeine response research question",
                rationale: context(
                    ["rs762551", "rs5751876"],
                    question: "Do timing, amount, tolerance, sleep debt, and self-observed effects explain your experience better than these loci?"
                ),
                pillar: .substances,
                priority: 45,
                rsids: ["rs762551", "rs5751876"]
            ),
            ChronoProtocolItem(
                id: "research-exercise",
                slot: .afternoon,
                title: "Exercise response research question",
                rationale: context(
                    ["rs1815739", "rs8192678"],
                    question: "Which activities are sustainable, enjoyable, and supported by measured training response?"
                ),
                pillar: .move,
                priority: 40,
                rsids: ["rs1815739", "rs8192678"]
            ),
            ChronoProtocolItem(
                id: "research-meal-timing",
                slot: .evening,
                title: "Meal-timing research question",
                rationale: context(
                    ["rs10830963", "rs7903146"],
                    question: "What do your schedule, symptoms, and clinician-reviewed metabolic measurements show?"
                ),
                pillar: .eat,
                priority: 35,
                rsids: ["rs10830963", "rs7903146"]
            ),
            ChronoProtocolItem(
                id: "research-sleep-context",
                slot: .bedtime,
                title: "Sleep context research question",
                rationale: "Sleep regularity, light exposure, environment, health conditions, and medication effects are not determined by a small array panel. Which factors are supported by your own repeated observations?",
                pillar: .sleep,
                priority: 30,
                rsids: ["rs57875986"]
            ),
        ]
    }

    static func buildSupplementMatrix(hits: [MarkerHit], compounds: [CompoundTrait]) -> SupplementMatrix {
        let byRsid = Dictionary(uniqueKeysWithValues: hits.map { ($0.rsid, $0) })

        func topic(
            id: String,
            name: String,
            rsids: [String],
            evidence: EvidenceLevel,
            question: String
        ) -> SupplementRecommendation? {
            let observed = rsids.filter { byRsid[$0]?.coverage == .matched }
            guard !observed.isEmpty else { return nil }
            return SupplementRecommendation(
                id: id,
                nutrientName: name,
                preferredForm: "No product or formulation inferred from genotype",
                reason: "Observed research loci: \(observed.joined(separator: ", ")). These associations do not establish deficiency, benefit, safety, or need.",
                dosageContext: question,
                evidence: evidence,
                rsids: rsids,
                timing: "No schedule inferred"
            )
        }

        let topics = [
            topic(
                id: "topic-folate",
                name: "Folate and riboflavin evidence topic",
                rsids: ["rs1801133", "rs1801131"],
                evidence: .strong,
                question: "Research question: are diet, medications, symptoms, or clinician-ordered laboratory measurements more relevant than these common variants?"
            ),
            topic(
                id: "topic-vitamin-d",
                name: "Vitamin D status evidence topic",
                rsids: ["rs2282679", "rs10741657"],
                evidence: .strong,
                question: "Research question: would a clinician-interpreted 25-hydroxyvitamin D measurement be more informative than an array association?"
            ),
            topic(
                id: "topic-lipid-nutrients",
                name: "Dietary lipid evidence topic",
                rsids: ["rs174546", "rs429358"],
                evidence: .moderate,
                question: "Research question: what do dietary pattern, medication history, and measured lipid values show?"
            ),
            topic(
                id: "topic-choline",
                name: "Choline metabolism evidence topic",
                rsids: ["rs7946"],
                evidence: .moderate,
                question: "Research question: is the cited association replicated for your ancestry and relevant to any measured outcome?"
            ),
            topic(
                id: "topic-iron",
                name: "Iron-status evidence topic",
                rsids: ["rs1800562", "rs1799945"],
                evidence: .strong,
                question: "Research question: if iron status is clinically relevant, which validated test and professional interpretation would be appropriate?"
            ),
        ].compactMap { $0 }

        return SupplementMatrix(recommended: topics, cautions: [])
    }

    static func protocolItems(hits: [MarkerHit], compounds: [CompoundTrait]) -> [ProtocolItem] {
        var items: [ProtocolItem] = []
        for pillar in LifestylePillar.allCases {
            let relevant = hits.filter { hit in
                hit.coverage == .matched && self.pillar(for: hit) == pillar
            }
            guard !relevant.isEmpty else { continue }
            let rsids = Array(relevant.map(\.rsid).prefix(8))
            items.append(ProtocolItem(
                id: "research-\(pillar.rawValue)",
                pillar: pillar,
                timing: .anytime,
                priority: 20,
                title: "Review the evidence behind \(pillar.title.lowercased()) associations",
                reason: "\(relevant.count) strand-resolved catalog observations are available. They are research associations, not a personal action plan; compare study design and uncertainty with your own context.",
                rsids: rsids
            ))
        }
        return items
    }

    static func insights(hits: [MarkerHit], compounds: [CompoundTrait]) -> [InsightCard] {
        var cards: [InsightCard] = []
        for compound in compounds where compound.impact != .typical {
            cards.append(InsightCard(
                id: "c-\(compound.id)",
                title: "\(compound.title) research rule",
                body: "A catalog rule produced an observation from \(compound.rsids.count) loci. Review marker coverage, phasing limits, evidence, and transferability before treating it as meaningful.",
                impact: .notable,
                rsids: compound.rsids,
                pillar: nil
            ))
        }
        let ranked = hits
            .filter { $0.coverage == .matched && $0.impact != .typical }
            .sorted { $0.rsid < $1.rsid }
        for hit in ranked.prefix(20) {
            cards.append(InsightCard(
                id: hit.rsid,
                title: "\(hit.gene) · \(hit.title)",
                body: "Observed catalog association at \(hit.rsid) (\(hit.evidence.label)). This is not a diagnosis, prediction, or recommendation.",
                impact: .notable,
                rsids: [hit.rsid],
                pillar: pillar(for: hit)
            ))
        }
        return Array(cards.prefix(28))
    }

    private static func pillar(for hit: MarkerHit) -> LifestylePillar? {
        if hit.categories.contains("sleep") || hit.categories.contains("circadian") { return .sleep }
        if hit.categories.contains("nutrition") || hit.categories.contains("vitamins") { return .eat }
        if hit.categories.contains("fitness") || hit.categories.contains("muscle") { return .move }
        if hit.categories.contains("caffeine") || hit.categories.contains("alcohol") { return .substances }
        if hit.categories.contains("cognition") || hit.categories.contains("stress") { return .mind }
        if hit.categories.contains("inflammation") || hit.categories.contains("detox") { return .recover }
        if hit.categories.contains("longevity") { return .longevity }
        return nil
    }
}
