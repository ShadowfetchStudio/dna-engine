import SwiftUI

// MARK: - 1. Rotating Double Helix Canvas

struct HelixView: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let mid = size.width / 2
                let h = size.height
                let rungs = 18
                for i in 0..<rungs {
                    let y = h * (0.06 + 0.88 * Double(i) / Double(rungs - 1))
                    let phase = t * 2.4 + Double(i) * 0.35
                    let x1 = mid + cos(phase) * (size.width * 0.34)
                    let x2 = mid + cos(phase + .pi) * (size.width * 0.34)
                    
                    var rung = Path()
                    rung.move(to: CGPoint(x: x1, y: y))
                    rung.addLine(to: CGPoint(x: x2, y: y))
                    
                    let depthAlpha = 0.25 + 0.75 * ((sin(phase) + 1.0) / 2.0)
                    context.stroke(rung, with: .color(Theme.gold.opacity(0.30 * depthAlpha)), lineWidth: 1.4)
                    
                    // Node 1 (Teal)
                    context.fill(
                        Path(ellipseIn: CGRect(x: x1 - 3.5, y: y - 3.5, width: 7.0, height: 7.0)),
                        with: .color(Theme.teal.opacity(depthAlpha))
                    )
                    // Node 2 (Magenta)
                    context.fill(
                        Path(ellipseIn: CGRect(x: x2 - 3.5, y: y - 3.5, width: 7.0, height: 7.0)),
                        with: .color(Theme.magenta.opacity(1.0 - (depthAlpha - 0.25)))
                    )
                }
            }
        }
    }
}

// MARK: - 2. Badges & Chips

struct ImpactBadge: View {
    var impact: Impact
    var body: some View {
        Text(impact.badge)
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .foregroundStyle(impact.color)
            .background(impact.color.opacity(0.15), in: Capsule())
            .overlay(Capsule().stroke(impact.color.opacity(0.3), lineWidth: 0.8))
    }
}

struct StatChip: View {
    var label: String
    var value: String
    var sublabel: String? = nil
    var icon: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption2)
                        .foregroundStyle(Theme.teal)
                }
                Text(label.uppercased())
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Theme.textLow)
            }
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textHi)
            if let sublabel {
                Text(sublabel)
                    .font(.caption2)
                    .foregroundStyle(Theme.textMed)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .dnaCard()
    }
}

struct DisclaimerBanner: View {
    var text: String = "Educational and research-grade genomic interpretation from peer-reviewed human genetics literature, computed 100% on this Mac. Not medical advice, not a clinical diagnosis, and not a substitute for a licensed clinician. Pharmacogenomic notes must be reviewed with a doctor or pharmacist."
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "cross.case.fill")
                .font(.title3)
                .foregroundStyle(Theme.gold)
            Text(text)
                .font(.caption)
                .foregroundStyle(Theme.textMed)
                .fixedSize(horizontal: false, vertical: true)
        }
        .dnaCard()
    }
}

// MARK: - 3. Gaussian Polygenic Distribution Bell Curve

struct GaussianPercentileCurve: View {
    var percentile: Int // 1 ... 99
    var zScore: Double
    var riskColor: Color = Theme.teal

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geo in
                Canvas { context, size in
                    let w = size.width
                    let h = size.height
                    let baselineY = h - 6
                    
                    // Draw bell curve
                    var curvePath = Path()
                    var fillPath = Path()
                    
                    let points = 80
                    let step = w / Double(points)
                    
                    // x maps from -3.0 to +3.0 std deviations
                    var started = false
                    fillPath.move(to: CGPoint(x: 0, y: baselineY))
                    
                    for i in 0...points {
                        let curX = Double(i) * step
                        let z = -3.0 + 6.0 * (curX / w)
                        // Standard normal pdf = (1/sqrt(2pi)) * exp(-z^2 / 2)
                        let pdf = exp(-z * z / 2.0)
                        let curY = baselineY - (pdf * (h * 0.85))
                        
                        if !started {
                            curvePath.move(to: CGPoint(x: curX, y: curY))
                            started = true
                        } else {
                            curvePath.addLine(to: CGPoint(x: curX, y: curY))
                        }
                        
                        // Shading up to user's zScore
                        if z <= zScore {
                            fillPath.addLine(to: CGPoint(x: curX, y: curY))
                        }
                    }
                    
                    // Close fill
                    let userX = max(0, min(w, ((zScore + 3.0) / 6.0) * w))
                    fillPath.addLine(to: CGPoint(x: userX, y: baselineY))
                    fillPath.closeSubpath()
                    
                    // Fill under curve
                    context.fill(fillPath, with: .color(riskColor.opacity(0.20)))
                    
                    // Draw base line and curve outline
                    var baseLine = Path()
                    baseLine.move(to: CGPoint(x: 0, y: baselineY))
                    baseLine.addLine(to: CGPoint(x: w, y: baselineY))
                    context.stroke(baseLine, with: .color(Theme.stroke), lineWidth: 1.0)
                    context.stroke(curvePath, with: .color(Theme.tealDim), lineWidth: 1.8)
                    
                    // Draw user position marker
                    var userMarker = Path()
                    userMarker.move(to: CGPoint(x: userX, y: baselineY))
                    let userPdf = exp(-zScore * zScore / 2.0)
                    let markerTopY = baselineY - (userPdf * (h * 0.85))
                    userMarker.addLine(to: CGPoint(x: userX, y: markerTopY - 4))
                    context.stroke(userMarker, with: .color(riskColor), style: StrokeStyle(lineWidth: 2.2, dash: [3, 2]))
                    
                    context.fill(
                        Path(ellipseIn: CGRect(x: userX - 4, y: markerTopY - 8, width: 8, height: 8)),
                        with: .color(riskColor)
                    )
                }
            }
            .frame(height: 70)
            
            HStack {
                Text("Lower (0%)")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(Theme.textLow)
                Spacer()
                Text("Average (50%)")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(Theme.textLow)
                Spacer()
                Text("Higher (100%)")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(Theme.textLow)
            }
        }
    }
}

// MARK: - 4. 2D PCA Population Scatter Map Canvas

struct PCAScatterPlotView: View {
    var report: AncestryPCAReport

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            GeometryReader { geo in
                Canvas { context, size in
                    let w = size.width
                    let h = size.height
                    let padding: CGFloat = 24
                    let plotW = w - padding * 2
                    let plotH = h - padding * 2
                    
                    // Grid background
                    var gridPath = Path()
                    let midX = padding + plotW / 2
                    let midY = padding + plotH / 2
                    gridPath.move(to: CGPoint(x: midX, y: padding))
                    gridPath.addLine(to: CGPoint(x: midX, y: h - padding))
                    gridPath.move(to: CGPoint(x: padding, y: midY))
                    gridPath.addLine(to: CGPoint(x: w - padding, y: midY))
                    context.stroke(gridPath, with: .color(Theme.stroke), lineWidth: 1.0)
                    
                    func mapCoord(x: Double, y: Double) -> CGPoint {
                        // x in -1.0 ... 1.0 -> screen X
                        let sx = midX + CGFloat(x) * (plotW * 0.45)
                        // y in -1.0 ... 1.0 -> screen Y (inverted)
                        let sy = midY - CGFloat(y) * (plotH * 0.45)
                        return CGPoint(x: sx, y: sy)
                    }
                    
                    // Draw reference population clusters
                    for pt in report.populationPoints where !pt.isUser {
                        let pos = mapCoord(x: pt.x, y: pt.y)
                        
                        // Cluster halo
                        context.fill(
                            Path(ellipseIn: CGRect(x: pos.x - 18, y: pos.y - 18, width: 36, height: 36)),
                            with: .color(colorForName(pt.clusterColorName).opacity(0.15))
                        )
                        context.fill(
                            Path(ellipseIn: CGRect(x: pos.x - 4, y: pos.y - 4, width: 8, height: 8)),
                            with: .color(colorForName(pt.clusterColorName))
                        )
                        
                        // Label
                        let text = Text(pt.label)
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(Theme.textMed)
                        context.draw(context.resolve(text), at: CGPoint(x: pos.x, y: pos.y + 12), anchor: .top)
                    }
                    
                    // Draw User Sample Point
                    if let userPt = report.populationPoints.first(where: { $0.isUser }) {
                        let pos = mapCoord(x: userPt.x, y: userPt.y)
                        
                        // Pulsing halo
                        context.stroke(
                            Path(ellipseIn: CGRect(x: pos.x - 14, y: pos.y - 14, width: 28, height: 28)),
                            with: .color(Theme.teal),
                            lineWidth: 2.0
                        )
                        context.fill(
                            Path(ellipseIn: CGRect(x: pos.x - 6, y: pos.y - 6, width: 12, height: 12)),
                            with: .color(Theme.teal)
                        )
                        
                        let userLabel = Text("📍 YOUR GENOME")
                            .font(.system(size: 10, weight: .heavy, design: .monospaced))
                            .foregroundStyle(Theme.teal)
                        context.draw(context.resolve(userLabel), at: CGPoint(x: pos.x, y: pos.y - 16), anchor: .bottom)
                    }
                }
            }
            .frame(height: 240)
            .background(Theme.bgInset, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.stroke, lineWidth: 1))
        }
    }

    private func colorForName(_ name: String) -> Color {
        switch name {
        case "blue": return Theme.blue
        case "gold": return Theme.gold
        case "magenta": return Theme.magenta
        case "teal": return Theme.teal
        case "success": return Theme.success
        case "warning": return Theme.warning
        case "tealDim": return Theme.tealDim
        default: return Theme.textMed
        }
    }
}

// MARK: - 5. Chromosome Ideogram Karyotype View

struct ChromosomeKaryotypeView: View {
    var chromosomeCounts: [String: Int]
    var selectedChrom: String
    var onSelectChrom: (String) -> Void
    var rohRegions: [ROHRegion] = []

    private let chromList: [String] = (1...22).map(String.init) + ["X", "Y", "MT"]

    private func rohFor(_ chrom: String) -> [ROHRegion] {
        rohRegions.filter { $0.chromosome == chrom }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("CHROMOSOME IDEOGRAM (23 KARYOTYPE)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.teal)
                Spacer()
                Text("Click chromosome to filter")
                    .font(.caption2)
                    .foregroundStyle(Theme.textLow)
            }
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 95), spacing: 8)], spacing: 8) {
                ForEach(chromList, id: \.self) { chrom in
                    let count = chromosomeCounts[chrom] ?? 0
                    let isSelected = selectedChrom == chrom
                    
                    Button {
                        onSelectChrom(chrom)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("chr\(chrom)")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundStyle(isSelected ? Theme.teal : Theme.textHi)
                                Spacer()
                                if isSelected {
                                    Circle().fill(Theme.teal).frame(width: 5, height: 5)
                                }
                            }
                            
                            // Visual density bar with ROH runs painted in gold (feature 7)
                            GeometryReader { geo in
                                let maxC = chromosomeCounts.values.max() ?? 1
                                let frac = Double(count) / Double(maxC)
                                Capsule().fill(Theme.bgInset)
                                Capsule()
                                    .fill(isSelected ? Theme.teal : Theme.blue.opacity(0.75))
                                    .frame(width: max(4, geo.size.width * frac))
                                let runs = rohFor(chrom)
                                if !runs.isEmpty {
                                    let maxPos = Double(runs.map(\.end).max() ?? 1)
                                    ForEach(runs) { r in
                                        let x0 = geo.size.width * CGFloat(Double(r.start) / max(maxPos, 1))
                                        let w = geo.size.width * CGFloat(Double(r.end - r.start) / max(maxPos, 1))
                                        Capsule()
                                            .fill(Theme.gold.opacity(0.9))
                                            .frame(width: max(3, w), height: 3)
                                            .offset(x: min(x0, geo.size.width - 3), y: 7)
                                    }
                                }
                            }
                            .frame(height: 10)

                            HStack(spacing: 4) {
                                Text("\(count.formatted()) SNPs")
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundStyle(Theme.textLow)
                                if !rohFor(chrom).isEmpty {
                                    Text("· \(rohFor(chrom).count) ROH")
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .foregroundStyle(Theme.gold)
                                }
                            }
                        }
                        .padding(8)
                        .background(isSelected ? Theme.bgCardHover : Theme.bgCard, in: RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isSelected ? Theme.teal : Theme.stroke, lineWidth: isSelected ? 1.4 : 0.8)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .dnaCard()
    }
}
