import SwiftUI

struct PathwaysView: View {
    @EnvironmentObject private var engine: DNAEngine
    var report: AnalysisReport { engine.report! }

    @State private var selectedNode: PathwayNode?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                pathwaySelector
                diagramContainer
                nodeBreakdownList
            }
            .padding(22)
        }
        .background(Theme.bgDeep)
        .sheet(item: $selectedNode) { node in
            PathwayNodeDetailModal(node: node)
                .frame(minWidth: 540, minHeight: 460)
        }
    }

    private var currentGraph: PathwayGraph {
        report.pathwayGraphs.first(where: { $0.pathway == engine.selectedPathway }) ?? report.pathwayGraphs[0]
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(currentGraph.title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Theme.textHi)
                Spacer()
                Text("MARKER-COVERAGE RESEARCH MAP")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.teal)
            }
            Text(currentGraph.subtitle)
                .font(.subheadline)
                .foregroundStyle(Theme.textMed)
        }
    }

    private var pathwaySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(BiochemicalPathway.allCases) { pathway in
                    FilterChip(title: pathway.rawValue, isSelected: engine.selectedPathway == pathway) {
                        engine.selectedPathway = pathway
                    }
                }
            }
        }
    }

    private var diagramContainer: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("PATHWAY CONTEXT — NO RATE OR FLUX ESTIMATE")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.textLow)
                Spacer()
                Text("Click any marker node to inspect")
                    .font(.caption2)
                    .foregroundStyle(Theme.teal)
            }

            // Visual pathway canvas
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                
                ZStack {
                    // 1. Draw Connecting Edges
                    Canvas { context, size in
                        for edge in currentGraph.edges {
                            if let fromNode = currentGraph.nodes.first(where: { $0.id == edge.fromId }),
                               let toNode = currentGraph.nodes.first(where: { $0.id == edge.toId }) {
                                let start = CGPoint(x: fromNode.x * w, y: fromNode.y * h)
                                let end = CGPoint(x: toNode.x * w, y: toNode.y * h)
                                
                                var line = Path()
                                line.move(to: start)
                                line.addLine(to: end)
                                context.stroke(line, with: .color(Theme.teal.opacity(0.35)), style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
                            }
                        }
                    }
                    
                    // 2. Render Interactive Nodes
                    ForEach(currentGraph.nodes) { node in
                        Button {
                            selectedNode = node
                        } label: {
                            VStack(spacing: 4) {
                                HStack(spacing: 4) {
                                    Text(node.gene)
                                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                                        .foregroundStyle(Theme.teal)
                                    Text("(\(node.observedGenotype))")
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .foregroundStyle(Theme.textHi)
                                }
                                Text(node.stepName)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(Theme.textHi)
                                    .lineLimit(1)
                                
                                Text(node.observationStatus)
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .foregroundStyle(node.impact.color)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(node.impact.color.opacity(0.15), in: Capsule())
                            }
                            .padding(8)
                            .frame(width: 140)
                            .background(Theme.bgCard, in: RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(node.impact == .caution ? Theme.danger : (node.impact == .notable ? Theme.gold : Theme.stroke), lineWidth: 1.2)
                            )
                            .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)
                        .position(x: node.x * w, y: node.y * h)
                    }
                }
            }
            .frame(height: 320)
            .background(Theme.bgInset, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.stroke, lineWidth: 1))
        }
    }

    private var nodeBreakdownList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pathway Marker Nodes (\(currentGraph.nodes.count))")
                .font(.headline)
                .foregroundStyle(Theme.textHi)

            ForEach(currentGraph.nodes) { node in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(node.gene) — \(node.stepName)")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Theme.textHi)
                            Text("rsID: \(node.rsid) · Genotype: \(node.observedGenotype)")
                                .font(.caption2.monospaced())
                                .foregroundStyle(Theme.textLow)
                        }
                        Spacer()
                        Text("COVERAGE ONLY")
                            .font(.system(size: 9, weight: .heavy, design: .monospaced))
                            .foregroundStyle(Theme.teal)
                    }

                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("SUBSTRATE")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(Theme.textLow)
                            Text(node.substrate)
                                .font(.caption)
                                .foregroundStyle(Theme.textMed)
                        }
                        Image(systemName: "arrow.right")
                            .font(.caption2)
                            .foregroundStyle(Theme.teal)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("PRODUCT")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(Theme.textLow)
                            Text(node.product)
                                .font(.caption)
                                .foregroundStyle(Theme.textMed)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("OBSERVATION STATUS")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(Theme.textLow)
                            Text(node.observationStatus)
                                .font(.caption.weight(.bold).monospaced())
                                .foregroundStyle(node.impact.color)
                        }
                    }
                    .padding(8)
                    .background(Theme.bgInset, in: RoundedRectangle(cornerRadius: 8))

                    Text(node.description)
                        .font(.callout)
                        .foregroundStyle(Theme.textMed)
                }
                .dnaCard()
                .onTapGesture {
                    selectedNode = node
                }
            }
        }
    }
}

struct PathwayNodeDetailModal: View {
    var node: PathwayNode
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(node.gene)
                            .font(.caption.monospaced().weight(.bold))
                            .foregroundStyle(Theme.teal)
                        Text(node.stepName)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Theme.textHi)
                        Text("Marker: \(node.rsid) · Observed Genotype: \(node.observedGenotype)")
                            .font(.caption.monospaced())
                            .foregroundStyle(Theme.textLow)
                    }
                    Spacer()
                    Text("NO ACTIVITY CALL")
                        .font(.system(size: 9, weight: .heavy, design: .monospaced))
                        .foregroundStyle(Theme.teal)
                    Button("Close") { dismiss() }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("OBSERVATION STATUS")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.gold)
                    Text(node.observationStatus)
                        .font(.headline)
                        .foregroundStyle(node.impact.color)
                }
                .dnaCard()

                VStack(alignment: .leading, spacing: 6) {
                    Text("BIOCHEMICAL REACTION")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.teal)
                    HStack {
                        Text("Substrate: \(node.substrate)")
                            .font(.callout.weight(.medium))
                        Spacer()
                        Image(systemName: "arrow.right")
                            .foregroundStyle(Theme.teal)
                        Spacer()
                        Text("Product: \(node.product)")
                            .font(.callout.weight(.medium))
                    }
                }
                .dnaCard()

                VStack(alignment: .leading, spacing: 6) {
                    Text("RESEARCH LIMIT")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.textLow)
                    Text(node.description)
                        .font(.callout)
                        .foregroundStyle(Theme.textMed)
                }
                .dnaCard()
                
                DisclaimerBanner()
            }
            .padding(22)
        }
        .background(Theme.bgDeep)
    }
}
