import Foundation

/// Bundled ancestry reference panel (2.1) — the pruned, provenance-carrying
/// output of Tools/build_reference_panel.py. UI-free by contract: compiled
/// into the check harness alongside the engines.
///
/// The panel is a build-time resource exactly like knowledge.json: it ships
/// inside the app bundle, is never written at runtime, and is the ONLY data
/// the AdmixtureEngine needs — the offline invariant holds.
///
/// Frequency convention (staging PANEL_REPORT.md): every stored value is the
/// ALT-allele frequency for the stated ref/alt pair. Consumers must orient
/// the observed genotype against ref/alt (complement-flipping when needed)
/// before counting ALT dosage.

struct RefPanelMarker: Codable {
    var rsid: String
    var ref: String
    var alt: String
    /// Population column -> ALT-allele frequency. Missing keys mean the
    /// source had no value (skip, don't impute).
    var af: [String: Double]
    /// Within-European informative subset flag (|dAF| > 0.1 on a within-EUR axis).
    var eur: Bool?
    /// Ashkenazi founder-signal subset flag (|ASJ-NFE| > 0.1).
    var asj: Bool?
}

struct RefPanelPopulations: Codable {
    var continental: [String]
    var withinEuropean: [String]
}

struct RefPanelProvenance: Codable {
    var generated: String?
    var generator: String?
    var frequencyConvention: String?
    var sourceSummary: [String]?
    var notes: [String]?
}

struct ReferencePanelFile: Codable {
    var version: String
    var markerCount: Int
    var populations: RefPanelPopulations
    var popSources: [String: String]
    var provenance: RefPanelProvenance
    var markers: [RefPanelMarker]
}

enum ReferencePanel {
    /// nil when the bundle carries no panel (pre-2.1 install): every consumer
    /// must degrade gracefully — the app runs, the ancestry module discloses
    /// that the reference panel is unavailable.
    static let shared: ReferencePanelFile? = load()

    private static func load() -> ReferencePanelFile? {
        var candidates: [URL] = []
        if let bundled = Bundle.main.url(forResource: "reference_panel", withExtension: "json") {
            candidates.append(bundled)
        }
        // Check-harness CLI runs from the repo root.
        candidates.append(URL(fileURLWithPath: "Resources/reference_panel.json"))
        if let resourcePath = Bundle.main.resourcePath {
            candidates.append(URL(fileURLWithPath: resourcePath).appendingPathComponent("reference_panel.json"))
        }
        // swiftc bundles put resources next to the executable's ../Resources
        if let exe = Bundle.main.executableURL {
            candidates.append(
                exe.deletingLastPathComponent().deletingLastPathComponent()
                    .appendingPathComponent("Resources/reference_panel.json")
            )
        }

        for url in candidates {
            if let data = try? Data(contentsOf: url),
               let file = try? JSONDecoder().decode(ReferencePanelFile.self, from: data),
               !file.markers.isEmpty {
                return file
            }
        }
        return nil
    }
}
