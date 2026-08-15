import Foundation

/// Static pathway context with observed-marker overlays.
///
/// No node estimates enzyme activity, expression, metabolite concentration,
/// pathway flux, or a health outcome. A single consumer-array marker cannot
/// support those quantities.
enum PathwaysEngine {
    private struct NodeSpec {
        var id: String
        var step: String
        var gene: String
        var rsid: String
        var substrate: String
        var product: String
        var x: Double
        var y: Double
    }

    static func buildGraphs(calls: [String: SNPCall], hits: [MarkerHit]) -> [PathwayGraph] {
        _ = calls
        let byRsid = Dictionary(uniqueKeysWithValues: hits.map { ($0.rsid, $0) })
        return [
            graph(
                .methylation,
                specs: [
                    NodeSpec(id: "mthfr", step: "Folate-cycle context", gene: "MTHFR", rsid: "rs1801133", substrate: "5,10-methylene-THF", product: "5-methyl-THF", x: 0.15, y: 0.28),
                    NodeSpec(id: "mtrr", step: "Methionine-cycle context", gene: "MTRR", rsid: "rs1801394", substrate: "Oxidized methionine synthase", product: "Reactivated enzyme", x: 0.40, y: 0.62),
                    NodeSpec(id: "pemt", step: "Phospholipid context", gene: "PEMT", rsid: "rs7946", substrate: "Phosphatidylethanolamine", product: "Phosphatidylcholine", x: 0.67, y: 0.28),
                    NodeSpec(id: "cbs", step: "Transsulfuration context", gene: "CBS", rsid: "rs234706", substrate: "Homocysteine", product: "Cystathionine", x: 0.87, y: 0.62),
                ],
                edges: [
                    PathwayEdge(fromId: "mthfr", toId: "mtrr", label: "pathway context"),
                    PathwayEdge(fromId: "mtrr", toId: "pemt", label: "methyl-donor context"),
                    PathwayEdge(fromId: "mtrr", toId: "cbs", label: "branch context"),
                ],
                byRsid: byRsid
            ),
            graph(
                .neurotransmitters,
                specs: [
                    NodeSpec(id: "comt", step: "Catechol metabolism context", gene: "COMT", rsid: "rs4680", substrate: "Catechol compounds", product: "Methylated metabolites", x: 0.15, y: 0.30),
                    NodeSpec(id: "ankk1", step: "Dopamine-receptor locus context", gene: "ANKK1", rsid: "rs1800497", substrate: "Receptor-system biology", product: "Association literature", x: 0.40, y: 0.65),
                    NodeSpec(id: "bdnf", step: "Neurotrophin context", gene: "BDNF", rsid: "rs6265", substrate: "BDNF precursor", product: "Mature BDNF", x: 0.68, y: 0.30),
                    NodeSpec(id: "maoa", step: "Monoamine metabolism context", gene: "MAOA", rsid: "rs6323", substrate: "Monoamines", product: "Metabolites", x: 0.87, y: 0.65),
                ],
                edges: [
                    PathwayEdge(fromId: "ankk1", toId: "comt", label: "dopamine-system context"),
                    PathwayEdge(fromId: "bdnf", toId: "ankk1", label: "neural context"),
                    PathwayEdge(fromId: "comt", toId: "maoa", label: "metabolism context"),
                ],
                byRsid: byRsid
            ),
            graph(
                .lipidClearance,
                specs: [
                    NodeSpec(id: "lpl", step: "Triglyceride-processing context", gene: "LPL", rsid: "rs328", substrate: "Triglyceride-rich particles", product: "Remnant particles", x: 0.14, y: 0.30),
                    NodeSpec(id: "apoe", step: "Lipoprotein transport context", gene: "APOE", rsid: "rs429358", substrate: "Lipoprotein particles", product: "Receptor-bound particles", x: 0.39, y: 0.65),
                    NodeSpec(id: "pcsk9", step: "LDL-receptor context", gene: "PCSK9", rsid: "rs11591147", substrate: "LDL receptor", product: "Receptor turnover", x: 0.68, y: 0.30),
                    NodeSpec(id: "cetp", step: "Lipid-transfer context", gene: "CETP", rsid: "rs708272", substrate: "HDL-associated lipids", product: "Transferred lipids", x: 0.87, y: 0.65),
                ],
                edges: [
                    PathwayEdge(fromId: "lpl", toId: "apoe", label: "particle context"),
                    PathwayEdge(fromId: "apoe", toId: "pcsk9", label: "receptor context"),
                    PathwayEdge(fromId: "apoe", toId: "cetp", label: "transport context"),
                ],
                byRsid: byRsid
            ),
            graph(
                .circadianClock,
                specs: [
                    NodeSpec(id: "clock", step: "Clock-gene context", gene: "CLOCK", rsid: "rs1801260", substrate: "Clock transcription network", product: "Rhythmic gene expression", x: 0.15, y: 0.30),
                    NodeSpec(id: "per3", step: "Period-gene context", gene: "PER3", rsid: "rs57875986", substrate: "Clock feedback network", product: "Period regulation", x: 0.41, y: 0.65),
                    NodeSpec(id: "mtnr1b", step: "Melatonin-receptor context", gene: "MTNR1B", rsid: "rs10830963", substrate: "Melatonin signal", product: "Receptor signaling", x: 0.68, y: 0.30),
                    NodeSpec(id: "adora2a", step: "Adenosine-receptor context", gene: "ADORA2A", rsid: "rs5751876", substrate: "Adenosine signal", product: "Receptor signaling", x: 0.87, y: 0.65),
                ],
                edges: [
                    PathwayEdge(fromId: "clock", toId: "per3", label: "feedback context"),
                    PathwayEdge(fromId: "per3", toId: "mtnr1b", label: "timing context"),
                    PathwayEdge(fromId: "mtnr1b", toId: "adora2a", label: "sleep-context literature"),
                ],
                byRsid: byRsid
            ),
            graph(
                .hepaticDetox,
                specs: [
                    NodeSpec(id: "cyp1a2", step: "CYP metabolism context", gene: "CYP1A2", rsid: "rs762551", substrate: "Selected xenobiotics", product: "Oxidized metabolites", x: 0.15, y: 0.30),
                    NodeSpec(id: "ugt1a1", step: "Glucuronidation context", gene: "UGT1A1", rsid: "rs887829", substrate: "Selected substrates", product: "Glucuronides", x: 0.41, y: 0.65),
                    NodeSpec(id: "aldh2", step: "Aldehyde metabolism context", gene: "ALDH2", rsid: "rs671", substrate: "Aldehydes", product: "Carboxylic acids", x: 0.68, y: 0.30),
                    NodeSpec(id: "sod2", step: "Mitochondrial antioxidant context", gene: "SOD2", rsid: "rs4880", substrate: "Superoxide", product: "Hydrogen peroxide", x: 0.87, y: 0.65),
                ],
                edges: [
                    PathwayEdge(fromId: "cyp1a2", toId: "ugt1a1", label: "metabolism context"),
                    PathwayEdge(fromId: "ugt1a1", toId: "aldh2", label: "clearance context"),
                    PathwayEdge(fromId: "aldh2", toId: "sod2", label: "redox context"),
                ],
                byRsid: byRsid
            ),
        ]
    }

    private static func graph(
        _ pathway: BiochemicalPathway,
        specs: [NodeSpec],
        edges: [PathwayEdge],
        byRsid: [String: MarkerHit]
    ) -> PathwayGraph {
        let nodes = specs.map { spec -> PathwayNode in
            let hit = byRsid[spec.rsid]
            let status: String
            switch hit?.coverage {
            case .matched: status = "Observed array locus"
            case .strandAmbiguous: status = "Strand unresolved"
            case .noCall: status = "No-call"
            case .missing, nil: status = "Not present on array"
            }
            return PathwayNode(
                id: spec.id,
                stepName: spec.step,
                gene: spec.gene,
                rsid: spec.rsid,
                observedGenotype: hit?.observed ?? "not present",
                substrate: spec.substrate,
                product: spec.product,
                observationStatus: status,
                impact: .typical,
                description: "This node locates \(spec.gene) in a research pathway and reports marker coverage only. It does not quantify enzyme activity, expression, metabolite concentration, pathway flux, or a health outcome.",
                x: spec.x,
                y: spec.y
            )
        }
        return PathwayGraph(
            pathway: pathway,
            title: pathway.rawValue,
            subtitle: pathway.subtitle,
            nodes: nodes,
            edges: edges
        )
    }
}
