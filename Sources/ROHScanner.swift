import Foundation

/// Runs-of-homozygosity scanner (feature 7).
///
/// 2.0 changes vs 1.x:
///   * returns a full ROHReport with F_ROH, not a raw region list
///   * F_ROH denominator = OBSERVED typed span per autosome (max−min position,
///     summed) — never a hardcoded genome size, so sparse chips don't inflate F
///   * het tolerance is per-Mb density (1.x used a fragile index-count length/50)
///   * regions classified 3–8 Mb (ancient/background), 8–16 Mb (distant founder),
///     >16 Mb (recent parental relatedness)
///   * interpretation stays in published bands and always says "consistent
///     with", never asserts consanguinity
enum ROHScanner {
    static let minRegionMb = 3.0
    static let minRegionSNPs = 80
    static let maxGap = 1_000_000
    static let maxHetPerMb = 0.25   // per-Mb heterozygote density tolerance

    static func scan(ordered: [SNPCall]) -> ROHReport {
        let grouped = Dictionary(grouping: ordered.filter { GenomeStats.isAutosome($0.chromosome) && !$0.isNoCall }) {
            $0.chromosome
        }

        var regions: [ROHRegion] = []
        var coveredBases = 0.0

        for (chrom, snps) in grouped {
            let sorted = snps.sorted { $0.position < $1.position }
            if let first = sorted.first, let last = sorted.last, last.position > first.position {
                coveredBases += Double(last.position - first.position)
            }
            regions.append(contentsOf: scanChromosome(chrom, sorted))
        }

        regions.sort { $0.lengthMb != $1.lengthMb ? $0.lengthMb > $1.lengthMb : $0.id < $1.id }

        let coveredMb = coveredBases / 1_000_000.0
        let totalROHMb = regions.reduce(0.0) { $0 + $1.lengthMb }
        let fROH = coveredMb > 0 ? totalROHMb / coveredMb : 0
        let shortMb = regions.filter { $0.lengthClass == .short }.reduce(0.0) { $0 + $1.lengthMb }
        let mediumMb = regions.filter { $0.lengthClass == .medium }.reduce(0.0) { $0 + $1.lengthMb }
        let longMb = regions.filter { $0.lengthClass == .long }.reduce(0.0) { $0 + $1.lengthMb }

        return ROHReport(
            regions: regions,
            fROH: fROH,
            longestMb: regions.first?.lengthMb ?? 0,
            classShortMb: shortMb,
            classMediumMb: mediumMb,
            classLongMb: longMb,
            autosomalCoveredMb: coveredMb,
            interpretation: interpret(fROH: fROH, longMb: longMb, regionCount: regions.count)
        )
    }

    static func interpret(fROH: Double, longMb: Double, regionCount: Int) -> String {
        var parts: [String] = []
        if regionCount == 0 {
            parts.append("No runs of homozygosity ≥3 Mb detected — consistent with a typical outbred background at this chip's resolution.")
        } else if fROH < 0.01 {
            parts.append("F_ROH below 0.01 — consistent with a typical outbred background.")
        } else if fROH < 0.03 {
            parts.append("F_ROH between 0.01 and 0.03 — common in founder populations and geographically isolated ancestries; not by itself evidence of recent consanguinity.")
        } else if fROH < 0.05 {
            parts.append("F_ROH between 0.03 and 0.05 — consistent with background relatedness several generations back or a strong founder population.")
        } else {
            parts.append("F_ROH at or above 0.05 — a value of ~0.0625 is consistent with parents related at the first-cousin level. This is an array-based estimate, not a determination.")
        }
        if longMb > 16 {
            parts.append("At least one run exceeds 16 Mb, the length class associated with recent parental relatedness — founder-population background can produce similar patterns.")
        }
        return parts.joined(separator: " ")
    }

    private static func scanChromosome(_ chrom: String, _ snps: [SNPCall]) -> [ROHRegion] {
        var out: [ROHRegion] = []
        var startIdx: Int?
        var hetInRun = 0
        var i = 0
        while i < snps.count {
            let snp = snps[i]
            if startIdx == nil {
                if !snp.isHeterozygous { startIdx = i; hetInRun = 0 }
                i += 1
                continue
            }
            let start = startIdx!
            let gap = snp.position - snps[i - 1].position
            if gap > maxGap {
                flush(&out, chrom: chrom, snps: snps, start: start, end: i - 1)
                startIdx = nil
                continue
            }
            if snp.isHeterozygous {
                hetInRun += 1
                let runMb = Double(snp.position - snps[start].position) / 1_000_000.0
                // Per-Mb het density (2.0): tolerate isolated genotyping errors,
                // break on real heterozygous stretches.
                let allowance = max(1.0, runMb * maxHetPerMb)
                if Double(hetInRun) > allowance {
                    flush(&out, chrom: chrom, snps: snps, start: start, end: i - 1)
                    startIdx = nil
                    hetInRun = 0
                    i += 1
                    continue
                }
            }
            i += 1
        }
        if let start = startIdx {
            flush(&out, chrom: chrom, snps: snps, start: start, end: snps.count - 1)
        }
        return out
    }

    private static func flush(_ out: inout [ROHRegion], chrom: String, snps: [SNPCall], start: Int, end: Int) {
        guard end > start else { return }
        let a = snps[start], b = snps[end]
        let mb = Double(b.position - a.position) / 1_000_000.0
        let n = end - start + 1
        if mb >= minRegionMb && n >= minRegionSNPs {
            out.append(ROHRegion(chromosome: chrom, start: a.position, end: b.position, snpCount: n, lengthMb: mb))
        }
    }
}
