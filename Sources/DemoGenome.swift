import Foundation

/// Deterministic splitmix64 — the demo genome must be byte-stable so the
/// check harness can diff it run-to-run. Never swap back to SystemRandom.
struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    /// Uniform double in [0, 1).
    mutating func unit() -> Double {
        Double(next() >> 11) * (1.0 / 9007199254740992.0)
    }
}

enum DemoGenome {
    static let seed: UInt64 = 0xD14_E461_1E20 // stable arbitrary seed — never change casually
    /// Ancestry mixture for free AIMs: 70% east_asian / 20% european / 10% african.
    static let mixture: [(pop: String, w: Double)] = [
        ("east_asian", 0.7), ("european", 0.2), ("african", 0.1),
    ]
    static let rohChromosome = "7"
    static let rohStart = 40_000_000
    static let rohEnd = 60_000_000
    static let noCallChromosome = "11"

    static func makeText() -> String {
        let kb = KnowledgeBase.shared
        var rng = SplitMix64(seed: seed)
        let demo = kb.demo ?? [:]

        var lines: [String] = [
            "#AncestryDNA raw data download",
            "#This file is a DEMO genome generated locally by DNA Engine.",
            "#It is not a real person — generated locally.",
            "#Genotypes chosen to demonstrate app features, not a plausible individual.",
            "#rsid\tchromosome\tposition\tallele1\tallele2"
        ]
        var used = Set<String>()
        var syntheticPos = 310_000_000

        func emit(rsid: String, chrom: String, position: Int, a: String, b: String) {
            guard used.insert(rsid).inserted else { return }
            lines.append("\(rsid)\t\(chrom)\t\(position)\t\(a)\t\(b)")
        }

        func nextSyntheticPos() -> Int {
            syntheticPos += 1500
            return syntheticPos
        }

        // 1. Catalog markers: persona table wins; default = alleleA homozygote.
        //    Markers landing inside the planted ROH window are forced homozygous.
        for marker in kb.markers {
            let position = marker.position == 0 ? nextSyntheticPos() : marker.position
            let inROH = marker.chromosome == rohChromosome && position >= rohStart && position <= rohEnd

            if let entry = demo[marker.rsid] {
                if entry == "absent" { continue }
                if entry == "0/0" {
                    emit(rsid: marker.rsid, chrom: marker.chromosome, position: position, a: "0", b: "0")
                    continue
                }
                let parts = entry.split(separator: "/").map(String.init)
                if parts.count == 2 {
                    var a = parts[0], b = parts[1]
                    if inROH && a != b { b = a } // keep the ROH run homozygous
                    emit(rsid: marker.rsid, chrom: marker.chromosome, position: position, a: a, b: b)
                    continue
                }
            }
            let a = marker.alleleA
            emit(rsid: marker.rsid, chrom: marker.chromosome, position: position, a: a, b: a)
        }

        // 2. Free AIMs: seeded draw from the 70/20/10 mixture.
        for aim in kb.aims where used.contains(aim.rsid) == false {
            var p = 0.0
            for (pop, w) in mixture {
                p += w * (aim.freqsDerived[pop] ?? 0.05)
            }
            p = min(max(p, 0.001), 0.999)
            let a1 = rng.unit() < p ? aim.derived : aim.ancestral
            let a2 = rng.unit() < p ? aim.derived : aim.ancestral
            emit(rsid: aim.rsid, chrom: "1", position: nextSyntheticPos(), a: a1, b: a2)
        }

        // 3. Panel-only SNPs pinned in the persona table but absent from the
        //    marker catalog (e.g. rs57875986, rs1333049).
        for (rsid, entry) in demo.sorted(by: { $0.key < $1.key }) where !used.contains(rsid) {
            if entry == "absent" || entry == "0/0" { continue }
            let parts = entry.split(separator: "/").map(String.init)
            guard parts.count == 2 else { continue }
            emit(rsid: rsid, chrom: "2", position: nextSyntheticPos(), a: parts[0], b: parts[1])
        }

        // 4. Planted 20 Mb homozygous run on chr7 (ROH), 350 SNPs.
        let rohCount = 350
        let spacing = (rohEnd - rohStart) / rohCount
        for i in 0..<rohCount {
            let base = ["A", "C", "G", "T"][Int(rng.next() % 4)]
            emit(rsid: "rs77\(String(format: "%06d", i))",
                 chrom: rohChromosome,
                 position: rohStart + i * spacing,
                 a: base, b: base)
        }

        // 5. Planted no-call cluster on chr11: 60 no-calls within 0.6 Mb.
        for i in 0..<60 {
            emit(rsid: "rs78\(String(format: "%06d", i))",
                 chrom: noCallChromosome,
                 position: 5_000_000 + i * 10_000,
                 a: "0", b: "0")
        }

        // 6. Autosomal padding: 2600 SNPs across chr1–22 at 38% guaranteed
        //    heterozygosity (compensating the homozygous catalog defaults and
        //    the ROH block so the file lands inside the 25–35% QC band),
        //    plus scattered background no-calls.
        let bases = ["A", "C", "G", "T"]
        func distinct(from a: String) -> String {
            var b = bases[Int(rng.next() % 4)]
            while b == a { b = bases[Int(rng.next() % 4)] }
            return b
        }
        for i in 0..<2600 {
            let chrom = "\(1 + (i % 22))"
            let position = 320_000_000 + (i / 22) * 12_000
            if i % 130 == 0 {
                emit(rsid: "rs90\(String(format: "%07d", i))", chrom: chrom, position: position, a: "0", b: "0")
                continue
            }
            let a = bases[Int(rng.next() % 4)]
            let b = rng.unit() < 0.38 ? distinct(from: a) : a
            emit(rsid: "rs90\(String(format: "%07d", i))", chrom: chrom, position: position, a: a, b: b)
        }

        // 7. X padding: 300 SNPs, ~20% het -> female call; zero Y rows.
        for i in 0..<300 {
            let a = bases[Int(rng.next() % 4)]
            let b = rng.unit() < 0.20 ? distinct(from: a) : a
            emit(rsid: "rs91\(String(format: "%07d", i))", chrom: "X", position: 1_000_000 + i * 400_000, a: a, b: b)
        }

        // 8. Ancestry reference-panel markers (2.1): seeded draws from the same
        //    70/20/10 east_asian/european/african mixture so the AdmixtureEngine
        //    is deterministic on the demo. Panel-array order is stable (packaging
        //    sorts by rsid); markers already emitted above (persona pins, AIMs,
        //    catalog defaults) are skipped by the dedupe. Panel AFs are
        //    ALT-allele frequencies, so draws are Bernoulli(p_alt) per allele.
        //    Positions are synthetic and spread across chr1-22 far above real
        //    coordinates; the admixture model matches by rsid only.
        if let panel = ReferencePanel.shared {
            var i = 0
            for m in panel.markers {
                guard !used.contains(m.rsid),
                      let eas = m.af["EAS"], let eur = m.af["EUR"], let afr = m.af["AFR"],
                      let ref = m.ref.first, let alt = m.alt.first else { continue }
                var p = 0.7 * eas + 0.2 * eur + 0.1 * afr
                p = min(max(p, 0.001), 0.999)
                let a1 = rng.unit() < p ? alt : ref
                let a2 = rng.unit() < p ? alt : ref
                emit(rsid: m.rsid,
                     chrom: "\(1 + (i % 22))",
                     position: 400_000_000 + (i / 22) * 15_000,
                     a: String(a1), b: String(a2))
                i += 1
            }
        }

        return lines.joined(separator: "\n") + "\n"
    }
}
