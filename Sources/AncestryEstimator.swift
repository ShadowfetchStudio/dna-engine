import Darwin
import Foundation

enum AncestryEstimator {
    static let populationTitles: [String: String] = [
        "european": "European",
        "african": "African",
        "east_asian": "East Asian",
        "south_asian": "South Asian",
        "american": "Americas / Indigenous-leaning",
        "middle_eastern": "Middle Eastern / North African",
        "oceanian": "Oceanian"
    ]

    static let populationColors: [String: String] = [
        "european": "blue",
        "african": "gold",
        "east_asian": "magenta",
        "south_asian": "teal",
        "american": "success",
        "middle_eastern": "warning",
        "oceanian": "tealDim"
    ]

    static let populationCentroids: [String: (x: Double, y: Double)] = [
        "european": (-0.45, 0.50),
        "african": (-0.75, -0.60),
        "east_asian": (0.75, 0.20),
        "south_asian": (0.15, 0.40),
        "american": (0.60, -0.45),
        "middle_eastern": (-0.20, 0.45),
        "oceanian": (0.75, -0.15),
    ]

    static func estimate(calls: [String: SNPCall], aims: [AIMDef]) -> AncestryResult {
        let pops = KnowledgeBase.shared.populations
        var logL = Dictionary(uniqueKeysWithValues: pops.map { ($0, 0.0) })
        var used = 0
        var missing = 0
        var notes: [String] = []

        for aim in aims {
            guard let call = calls[aim.rsid], !call.isNoCall else {
                missing += 1
                continue
            }
            guard let derivedCount = derivedAlleleCount(call: call, aim: aim) else {
                missing += 1
                continue
            }
            used += 1
            for pop in pops {
                let p = min(max(aim.freqsDerived[pop] ?? 0.05, 1e-4), 1 - 1e-4)
                let q = 1 - p
                let like: Double
                switch derivedCount {
                case 2: like = p * p
                case 1: like = 2 * p * q
                default: like = q * q
                }
                logL[pop, default: 0] += log(like + 1e-12)
            }
        }

        guard used >= 6 else {
            return AncestryResult(
                shares: [:],
                usedMarkers: used,
                missingMarkers: missing,
                confidence: "Too few ancestry-informative SNPs typed",
                notes: ["This chip version did not include enough AIM SNPs for a continental sketch."]
            )
        }

        let maxLog = logL.values.max() ?? 0
        var weights: [String: Double] = [:]
        var sum = 0.0
        for (pop, ll) in logL {
            let w = exp(ll - maxLog)
            weights[pop] = w
            sum += w
        }
        var shares: [String: Double] = [:]
        for (pop, w) in weights {
            shares[pop] = sum > 0 ? w / sum : 0
        }

        let top = shares.max(by: { $0.value < $1.value })
        let confidence: String
        if used >= 35, (top?.value ?? 0) > 0.55 {
            confidence = "Legacy 7-population sketch from \(used) AIMs — single-population posterior; admixed profiles collapse toward one population (the admixture model is the honest estimate)"
        } else if used >= 20 {
            confidence = "Legacy sketch — \(used) AIMs, overlapping frequency spectrum"
        } else {
            confidence = "Preliminary sketch — \(used) ancestry-informative SNPs"
        }

        notes.append("Computed entirely on-device using a 7-population Bayesian likelihood model across published AIMs.")
        notes.append("This 36-AIM sketch is the legacy 2.0 continental model, kept for continuity; the reference-panel admixture above refines it with 2,621 markers. Even so, fine distinctions such as British Isles vs Scandinavia remain out of reach — they require individual-level reference biobanks this offline tool does not ship.")
        if let top {
            notes.append("Primary ancestral affinity: \(populationTitles[top.key] ?? top.key).")
        }

        return AncestryResult(
            shares: shares,
            usedMarkers: used,
            missingMarkers: missing,
            confidence: confidence,
            notes: notes
        )
    }

    static func estimatePCA(shares: [String: Double]) -> AncestryPCAReport {
        var userX = 0.0
        var userY = 0.0
        var totalWeight = 0.0

        for (pop, share) in shares {
            if let centroid = populationCentroids[pop] {
                userX += share * centroid.x
                userY += share * centroid.y
                totalWeight += share
            }
        }

        if totalWeight > 0 {
            userX /= totalWeight
            userY /= totalWeight
        }

        var points: [PCA2DPoint] = []
        // Add population reference points
        for (pop, coord) in populationCentroids {
            points.append(PCA2DPoint(
                id: "pop-\(pop)",
                label: populationTitles[pop] ?? pop,
                x: coord.x,
                y: coord.y,
                isUser: false,
                clusterColorName: populationColors[pop] ?? "textMed"
            ))
        }

        // Add user point
        points.append(PCA2DPoint(
            id: "user-sample",
            label: "Your Sample",
            x: userX,
            y: userY,
            isUser: true,
            clusterColorName: "teal"
        ))

        return AncestryPCAReport(
            userCoordinate: PCA2DCoordinate(x: userX, y: userY),
            populationPoints: points
        )
    }

    private static func derivedAlleleCount(call: SNPCall, aim: AIMDef) -> Int? {
        guard let d = aim.derived.uppercased().first, let a = aim.ancestral.uppercased().first else { return nil }
        func count(derived: Character, ancestral: Character) -> Int? {
            let alleles = [call.allele1, call.allele2]
            if alleles.allSatisfy({ $0 == derived || $0 == ancestral }) {
                return alleles.filter { $0 == derived }.count
            }
            return nil
        }
        if let n = count(derived: d, ancestral: a) { return n }
        return count(derived: Strand.complement(d), ancestral: Strand.complement(a))
    }
}
