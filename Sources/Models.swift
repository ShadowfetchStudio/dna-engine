import Foundation

enum EvidenceLevel: String, Codable, CaseIterable {
    case strong, moderate, preliminary, trait

    var label: String {
        switch self {
        case .strong: return "Strong Evidence"
        case .moderate: return "Moderate Evidence"
        case .preliminary: return "Preliminary"
        case .trait: return "Trait / Sensory"
        }
    }
}

enum Impact: String, Codable, CaseIterable {
    case typical, advantageous, notable, caution

    var badge: String {
        switch self {
        case .typical: return "TYPICAL"
        case .advantageous: return "ADVANTAGE"
        case .notable: return "NOTABLE"
        case .caution: return "ATTENTION"
        }
    }
}

enum LifestylePillar: String, Codable, CaseIterable, Identifiable {
    case eat, sleep, move, recover, mind, substances, longevity, supplements
    var id: String { rawValue }

    var title: String {
        switch self {
        case .eat: return "Nutrition"
        case .sleep: return "Sleep & Circadian"
        case .move: return "Fitness & Movement"
        case .recover: return "Recovery & Detox"
        case .mind: return "Mind & Stress"
        case .substances: return "Caffeine & Alcohol"
        case .longevity: return "Cellular Longevity"
        case .supplements: return "Nutrient Evidence"
        }
    }

    var systemImage: String {
        switch self {
        case .eat: return "fork.knife"
        case .sleep: return "moon.stars.fill"
        case .move: return "figure.run"
        case .recover: return "leaf.fill"
        case .mind: return "brain.head.profile"
        case .substances: return "cup.and.saucer.fill"
        case .longevity: return "hourglass"
        case .supplements: return "pills.fill"
        }
    }
}

enum NavItem: String, CaseIterable, Identifiable {
    // Workstation Hub
    case overview
    case protocolDay
    case pharmacogenomics
    case pathways
    case polygenic
    case ancestry
    
    // Systems Biology
    case methylation
    case cardio
    case sleep
    case mind
    case move
    case metabolism
    case vitamins
    case immunity
    case histamine
    case longevity
    case traits
    
    // Genomics Tools
    case genome
    case search
    case compare
    case qc
    case privacy
    case limits

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview: return "Overview"
        case .protocolDay: return "Lifestyle Evidence"
        case .pharmacogenomics: return "PGx Research"
        case .pathways: return "Pathway Reference Maps"
        case .polygenic: return "Polygenic Panels"
        case .ancestry: return "Ancestry & PCA"
            
        case .methylation: return "Methylation & 1-Carbon"
        case .cardio: return "Heart & Lipids"
        case .sleep: return "Sleep & Circadian"
        case .mind: return "Mind, Stress & Neuro"
        case .move: return "Fitness & Muscle"
        case .metabolism: return "Glucose & Metabolism"
        case .vitamins: return "Vitamins & Micronutrients"
        case .immunity: return "Immunity & Autoimmunity"
        case .histamine: return "Histamine & Gut"
        case .longevity: return "Longevity & Healthspan"
        case .traits: return "Physical Traits & Sensory"
            
        case .genome: return "Whole-Genome Karyotype"
        case .search: return "SNP Search (All SNPs)"
        case .compare: return "Raw Concordance"
        case .qc: return "Genome Quality Control"
        case .privacy: return "Privacy Center"
        case .limits: return "What This Can't Tell You"
        }
    }

    var systemImage: String {
        switch self {
        case .overview: return "square.grid.2x2.fill"
        case .protocolDay: return "sun.horizon.fill"
        case .pharmacogenomics: return "cross.case.fill"
        case .pathways: return "arrow.triangle.branch"
        case .polygenic: return "chart.bar.xaxis"
        case .ancestry: return "globe.americas.fill"
            
        case .methylation: return "atom"
        case .cardio: return "heart.fill"
        case .sleep: return "moon.stars.fill"
        case .mind: return "brain.head.profile"
        case .move: return "figure.run"
        case .metabolism: return "drop.fill"
        case .vitamins: return "pills.fill"
        case .immunity: return "shield.fill"
        case .histamine: return "allergens"
        case .longevity: return "hourglass"
        case .traits: return "eye.fill"
            
        case .genome: return "circle.hexagongrid.fill"
        case .search: return "magnifyingglass"
        case .compare: return "person.2.fill"
        case .qc: return "checkmark.seal.fill"
        case .privacy: return "lock.shield.fill"
        case .limits: return "eye.slash"
        }
    }

    var catalogCategories: Set<String> {
        switch self {
        case .methylation: return ["methylation", "nutrition"]
        case .cardio: return ["cardio", "lipids", "clotting"]
        case .sleep: return ["sleep", "circadian"]
        case .mind: return ["cognition", "stress", "neurotransmitters"]
        case .move: return ["fitness", "muscle", "injury", "endurance"]
        case .metabolism: return ["glucose", "metabolism", "weight"]
        case .vitamins: return ["vitamins", "bone", "nutrition"]
        case .immunity: return ["immunity", "autoimmunity", "inflammation"]
        case .histamine: return ["histamine", "gut", "nutrition"]
        case .longevity: return ["longevity", "cellular", "antioxidant"]
        case .traits: return ["traits", "pigmentation", "sensory", "morphology", "taste", "hair"]
        case .pharmacogenomics: return ["pharmacogenomics", "caffeine", "alcohol", "detox"]
        default: return []
        }
    }
}

// MARK: - Core SNP & Ingestion Types

struct SNPCall: Hashable, Identifiable {
    var id: String { rsid }
    var rsid: String
    var chromosome: String
    var position: Int
    var allele1: Character
    var allele2: Character

    var isNoCall: Bool {
        allele1 == "0" || allele2 == "0" || allele1 == "-" || allele2 == "-" || allele1 == "D" || allele1 == "I"
    }

    var genotypeKey: String {
        if isNoCall { return "--" }
        let a = String(allele1), b = String(allele2)
        return a <= b ? a + b : b + a
    }

    var display: String { isNoCall ? "—" : "\(allele1)/\(allele2)" }
    var isHeterozygous: Bool { !isNoCall && allele1 != allele2 }
}

struct GenomeFile: Codable, Hashable {
    var sourcePath: String
    var fileName: String
    var vendor: String
    var importedAt: Date
    var snpCount: Int
    var calledCount: Int
    var noCallCount: Int
    var autosomalHet: Double
    var inferredSex: String
    var chromosomeCounts: [String: Int]
    var buildHint: String
}

// MARK: - Knowledge Catalog Definitions

struct MarkerDef: Codable, Identifiable {
    var rsid: String
    var gene: String
    var title: String
    var chromosome: String
    var position: Int
    var categories: [String]
    var mechanism: String
    var evidence: EvidenceLevel
    var alleleA: String
    var alleleB: String
    var genotypes: [String: GenotypeDef]
    var notes: String

    // 2.0 honesty schema — OPTIONAL on purpose: KnowledgeBase.load fatalErrors
    // on decode failure and may encounter a pre-2.0 cached knowledge.json.
    var citations: [CitationDef]?
    var tier: String?
    var effect: String?
    var transferability: String?
    var chips: [String]?
    var position38: Int?

    var id: String { rsid }
}

struct CitationDef: Codable, Hashable {
    var pmid: String
    var note: String
}

enum Transferability {
    static func explainer(_ raw: String?) -> String? {
        switch raw {
        case "euro-biased":
            return "Discovered/validated mainly in European-ancestry cohorts — predictive value is reduced for other ancestries."
        case "multi-ancestry":
            return "Replicated across multiple continental ancestries."
        case "east-asian-derived":
            return "Derived from East-Asian-ancestry studies; the variant is rare or absent elsewhere."
        case "african-derived":
            return "Derived from African-ancestry studies; the variant is rare or absent elsewhere."
        default:
            return nil
        }
    }
}

struct GenotypeDef: Codable {
    var label: String
    var impact: Impact
    var summary: String
    var detail: String
    var actions: [String: [String]]
}

struct AIMDef: Codable, Identifiable {
    var rsid: String
    var gene: String
    var derived: String
    var ancestral: String
    var freqsDerived: [String: Double]

    var id: String { rsid }
}

struct ScoreSNP: Codable, Hashable {
    var rsid: String
    var risk: String
    var weight: Double
    var freq: [String: Double]?          // per-population risk-allele frequency (2.0)
}

struct PanelCal: Codable, Hashable {
    var mean: Double
    var sd: Double
}

struct ScorePanel: Codable, Identifiable, Hashable {
    var id: String
    var title: String
    var description: String
    var snps: [ScoreSNP]
    var calibration: [String: PanelCal]?  // per-population HWE calibration (2.0)
}

// MARK: - Data-Driven Compound Definitions (2.0)

struct CompoundCond: Codable, Hashable {
    var rsid: String?
    var gt: String?
    var gtIn: [String]?
    var hasAllele: String?
    var countAllele: String?
    var min: Int?
    var max: Int?
}

struct CompoundRule: Codable, Hashable {
    var when: [CompoundCond]
    var value: String
    var detail: String
    var impact: Impact
}

struct CompoundOutcome: Codable, Hashable {
    var value: String
    var detail: String
    var impact: Impact
}

struct CompoundCountSNP: Codable, Hashable {
    var rsid: String
    var allele: String
}

struct CompoundBand: Codable, Hashable {
    var min: Int
    var max: Int
    var value: String
    var detail: String
    var impact: Impact
}

struct CompoundDef: Codable, Identifiable, Hashable {
    var id: String
    var title: String
    var rsids: [String]
    var tier: String?
    var citations: [CitationDef]?
    var caveat: String?
    var kind: String?                      // nil/"rules" or "count"
    var requireTyped: [String]?
    var partial: CompoundOutcome?
    var rules: [CompoundRule]?
    var countSnps: [CompoundCountSNP]?
    var bands: [CompoundBand]?
    var fallback: CompoundOutcome
}

// MARK: - Data-Driven PGx Definitions (2.0)

struct PGxAlleleDef: Codable, Hashable {
    var name: String
    var rsid: String
    var referenceAllele: String
    var variantAllele: String
    var activity: Double
}

struct PGxBandDef: Codable, Hashable {
    var max: Double
    var phenotype: String
}

struct PGxPhenotypeText: Codable, Hashable {
    var guideline: String
    var alternatives: String
    var impact: Impact
}

struct PGxDrugDef: Codable, Hashable {
    var name: String
    var brands: String
    var area: String
    var gene: String
    var cpicLevel: String
    var rsids: [String]
    var perPhenotype: [String: PGxPhenotypeText]
    var combineGenes: [String]?
}

struct PGxGeneDef: Codable, Hashable {
    var gene: String
    var alleles: [PGxAlleleDef]
    var subtractAlleles: [PGxAlleleDef]?
    var wildActivity: Double
    var phenotypeBands: [PGxBandDef]
    var undetectable: [String]
    var chipLimitations: String
    var drugs: [PGxDrugDef]
}

// MARK: - Limitations Catalog (2.0)

struct LimitationDef: Codable, Identifiable, Hashable {
    var id: String
    var category: String                   // structural | resolution | statistical
    var title: String
    var explanation: String
    var pmidNote: String
}

struct KnowledgeFile: Codable {
    var version: String
    var disclaimer: String
    var populations: [String]
    var markers: [MarkerDef]
    var aims: [AIMDef]
    var scores: [ScorePanel]
    // 2.0 payloads — optional so pre-2.0 cached files still decode.
    var compounds: [CompoundDef]?
    var pgx: [PGxGeneDef]?
    var limitations: [LimitationDef]?
    var demo: [String: String]?
}

// MARK: - Analysis Output Types

struct MarkerHit: Identifiable, Hashable {
    var rsid: String
    var gene: String
    var title: String
    var chromosome: String
    var categories: [String]
    var mechanism: String
    var evidence: EvidenceLevel
    var observed: String
    var genotypeKey: String
    var label: String
    var impact: Impact
    var summary: String
    var detail: String
    var actions: [String: [String]]
    var notes: String
    var coverage: Coverage
    // 2.0 honesty passthrough
    var tier: String?
    var effect: String?
    var transferability: String?
    var citations: [CitationDef]?

    var id: String { rsid }

    enum Coverage: String, Hashable {
        case matched, noCall, missing, strandAmbiguous
    }
}

struct InsightCard: Identifiable, Hashable {
    var id: String
    var title: String
    var body: String
    var impact: Impact
    var rsids: [String]
    var pillar: LifestylePillar?
}

// MARK: - Pharmacogenomics Models (CPIC / PharmGKB)

enum CPICPhenotype: String, Codable, Hashable {
    case ultrarapid = "Ultrarapid Metabolizer"
    case rapid = "Rapid Metabolizer"
    case normal = "Normal (Extensive) Metabolizer"
    case intermediate = "Intermediate Metabolizer"
    case poor = "Poor Metabolizer"
    case indeterminate = "Indeterminate / Uncalled"

    var badgeColorName: String {
        switch self {
        case .normal: return "success"
        case .rapid, .intermediate: return "warning"
        case .poor, .ultrarapid: return "danger"
        case .indeterminate: return "textMed"
        }
    }
}

enum TherapeuticArea: String, CaseIterable, Identifiable, Hashable {
    case cardiology = "Cardiology & Clotting"
    case psychiatry = "Psychiatry & Mood"
    case painNeurology = "Pain & Neurology"
    case statins = "Statins & Lipids"
    case oncology = "Oncology & Chemotherapy"
    case gastroenterology = "Gastroenterology & PPIs"
    case immunology = "Immunology & Transplants"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .cardiology: return "heart.circle.fill"
        case .psychiatry: return "brain.head.profile"
        case .painNeurology: return "bolt.shield.fill"
        case .statins: return "cross.vial.fill"
        case .oncology: return "allergens"
        case .gastroenterology: return "pills.circle.fill"
        case .immunology: return "shield.lefthalf.filled"
        }
    }
}

struct DrugGuideline: Identifiable, Hashable {
    var id: String { "\(drugName)-\(gene)" }
    var drugName: String
    var brandNames: String
    var therapeuticArea: TherapeuticArea
    var gene: String
    var cpicLevel: String
    var userPhenotype: CPICPhenotype
    var clinicalGuideline: String
    var alternativeNotes: String
    var impact: Impact
    var rsids: [String]
    var chipLimitations: String = ""   // permanent amber disclosure (2.0)
    var evidenceRsids: [String: String] = [:]  // rsid -> observed genotype (clinician sheet)
}

enum PGxLocusStatus: String, Hashable {
    case observed = "Observed"
    case missing = "Not present on array"
    case noCall = "No-call"
    case strandUnresolved = "Strand unresolved"
    case alleleMismatch = "Alleles do not match definition"
}

struct PGxLocusObservation: Identifiable, Hashable {
    var id: String { "\(rsid)-\(alleleName)" }
    var rsid: String
    var alleleName: String
    var expectedAlleles: String
    var observedGenotype: String
    var status: PGxLocusStatus
}

struct PGxDrugReference: Identifiable, Hashable {
    var id: String { "\(name)-\(gene)" }
    var name: String
    var brands: String
    var gene: String
    var therapeuticArea: TherapeuticArea
    var sourceLevel: String
}

struct PGxGeneObservation: Identifiable, Hashable {
    var id: String { gene }
    var gene: String
    var loci: [PGxLocusObservation]
    var drugReferences: [PGxDrugReference]
    var undetectable: [String]
    var chipLimitations: String

    var observedCount: Int { loci.filter { $0.status == .observed }.count }
    var unresolvedCount: Int { loci.count - observedCount }
}

struct PharmacogenomicReport: Hashable {
    var guidelines: [DrugGuideline]
    var assessedGenes: [String: CPICPhenotype]
    var highRiskDrugCount: Int
    var geneObservations: [PGxGeneObservation] = []
}

// MARK: - Interactive Biochemical Pathways

enum BiochemicalPathway: String, CaseIterable, Identifiable, Hashable {
    case methylation = "One-Carbon Pathway Reference Map"
    case neurotransmitters = "Neurotransmitter Pathway Reference Map"
    case lipidClearance = "Lipid Transport Reference Map"
    case circadianClock = "Circadian Biology Reference Map"
    case hepaticDetox = "Hepatic Metabolism Reference Map"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .methylation: return "Research map of folate, methionine, and transsulfuration biology"
        case .neurotransmitters: return "Research map of neurotransmitter synthesis and clearance biology"
        case .lipidClearance: return "Research map of lipid transport and receptor biology"
        case .circadianClock: return "Research map of clock and melatonin-related biology"
        case .hepaticDetox: return "Research map of hepatic metabolism pathways"
        }
    }
}

struct PathwayNode: Identifiable, Hashable {
    var id: String
    var stepName: String
    var gene: String
    var rsid: String
    var observedGenotype: String
    var substrate: String
    var product: String
    var observationStatus: String
    var impact: Impact
    var description: String
    var x: Double // 0.0 ... 1.0 relative canvas coordinates
    var y: Double
}

struct PathwayEdge: Identifiable, Hashable {
    var id: String { "\(fromId)->\(toId)" }
    var fromId: String
    var toId: String
    var label: String
}

struct PathwayGraph: Identifiable, Hashable {
    var id: BiochemicalPathway { pathway }
    var pathway: BiochemicalPathway
    var title: String
    var subtitle: String
    var nodes: [PathwayNode]
    var edges: [PathwayEdge]
}

// MARK: - Calibrated Polygenic Scores

struct CalibratedPolygenicScore: Identifiable, Hashable {
    var id: String
    var title: String
    var description: String
    var percentile: Int // 1 ... 99 (meaningless when insufficientCoverage)
    var zScore: Double
    var riskCategory: String // tendency language only — never "high risk"
    var impact: Impact
    var usedSNPs: Int
    var totalSNPs: Int
    var lifestyleMitigation: String
    var topContributingGenes: [String]
    // 2.0 honest calibration (feature 4)
    var referencePopulation: String
    var referencePopulationIsFallback: Bool
    var percentileByPopulation: [String: Int]
    var insufficientCoverage: Bool
}

// MARK: - PCA & Ancestry Projections

struct PCA2DPoint: Identifiable, Hashable {
    var id: String
    var label: String
    var x: Double // PC1 (-1.0 ... 1.0)
    var y: Double // PC2 (-1.0 ... 1.0)
    var isUser: Bool
    var clusterColorName: String
}

struct PCA2DCoordinate: Hashable {
    var x: Double
    var y: Double
}

struct AncestryPCAReport: Hashable {
    var userCoordinate: PCA2DCoordinate
    var populationPoints: [PCA2DPoint]
}

// MARK: - Lifestyle and Nutrient Evidence Topics

enum ChronoTimeSlot: String, CaseIterable, Identifiable, Hashable {
    case morning = "Morning Awakening (6:00 - 9:00 AM)"
    case midday = "Midday Productivity (11:00 AM - 2:00 PM)"
    case afternoon = "Afternoon Transition (3:00 - 5:30 PM)"
    case evening = "Evening Wind-Down (7:00 - 9:30 PM)"
    case bedtime = "Bedtime & Sleep Preparation (10:00 PM+)"

    var id: String { rawValue }

    var shortTitle: String {
        switch self {
        case .morning: return "Morning"
        case .midday: return "Midday"
        case .afternoon: return "Afternoon"
        case .evening: return "Evening"
        case .bedtime: return "Bedtime"
        }
    }

    var systemImage: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .midday: return "sun.max.fill"
        case .afternoon: return "sun.and.horizon.fill"
        case .evening: return "sunset.fill"
        case .bedtime: return "moon.zzz.fill"
        }
    }
}

struct ChronoProtocolItem: Identifiable, Hashable {
    var id: String
    var slot: ChronoTimeSlot
    var title: String
    var rationale: String
    var pillar: LifestylePillar
    var priority: Int
    var rsids: [String]
}

struct SupplementRecommendation: Identifiable, Hashable {
    var id: String
    var nutrientName: String
    var preferredForm: String
    var reason: String
    var dosageContext: String
    var evidence: EvidenceLevel
    var rsids: [String]
    var timing: String
}

struct SupplementCaution: Identifiable, Hashable {
    var id: String
    var supplementName: String
    var mechanismOfCaution: String
    var clinicalContext: String
    var rsids: [String]
    var severity: Impact
}

struct SupplementMatrix: Hashable {
    var recommended: [SupplementRecommendation]
    var cautions: [SupplementCaution]
}

// MARK: - Multi-Genome Raw Concordance

enum RelationshipDegree: String, Hashable {
    /// Compatibility surface for the app status line. DNA Engine deliberately
    /// does not infer a relationship from raw-array concordance.
    case notInferred = "Relationship not inferred"
}

struct TraitComparisonRow: Identifiable, Hashable {
    var id: String
    var traitName: String
    var gene: String
    var genotypeA: String
    var genotypeB: String
    var isMatch: Bool
    var summaryA: String
    var summaryB: String
    var impactA: Impact
    var impactB: Impact
}

struct GenomeComparison: Hashable {
    var profileNameA: String
    var profileNameB: String
    var totalComparedSNPs: Int
    var exactGenotypeMatchCount: Int
    var oneAlleleOverlapCount: Int
    var noAlleleOverlapCount: Int
    var exactGenotypeConcordance: Double
    var oneAlleleOverlapFraction: Double
    var noAlleleOverlapFraction: Double
    var researchSimilaritySummary: String
    var estimatedRelationship: RelationshipDegree
    var comparedTraits: [TraitComparisonRow]
}

// MARK: - Whole-Genome Analysis Report Master

struct ProtocolItem: Identifiable, Hashable {
    var id: String
    var pillar: LifestylePillar
    var timing: Timing
    var priority: Int
    var title: String
    var reason: String
    var rsids: [String]

    enum Timing: String, CaseIterable, Hashable {
        case morning, daytime, evening, anytime
        var title: String {
            switch self {
            case .morning: return "Morning"
            case .daytime: return "Day"
            case .evening: return "Evening"
            case .anytime: return "Anytime"
            }
        }
    }
}

struct AncestryResult: Hashable {
    var shares: [String: Double]
    var usedMarkers: Int
    var missingMarkers: Int
    var confidence: String
    var notes: [String]
}

// MARK: - Fine-Scale Ancestry (2.1, reference-panel admixture)

struct AdmixtureComponent: Hashable, Identifiable {
    var id: String            // panel column id ("EUR", "NWE", "ASJ", ...)
    var title: String
    var share: Double         // absolute genome share, 0...1
    var ciLow: Double         // seeded-bootstrap 95% interval
    var ciHigh: Double

    var percentText: String { String(format: "%.1f%%", share * 100) }
    var ciText: String { String(format: "95%% CI %.1f–%.1f%%", ciLow * 100, ciHigh * 100) }
}

struct ASJSignal: Hashable {
    /// insufficient-markers | not-assessed | none-detected | possible | likely | strong
    var band: String
    var sharePercent: Double        // absolute genome %, 0...100 (joint tier-2 fit)
    var ciLowPercent: Double
    var ciHighPercent: Double
    var logLikelihoodRatio: Double  // Σ LLR (ASJ vs NFE reference) over founder-subset markers
    var markersUsed: Int
    var markersTotal: Int
    var framing: String             // mandatory honesty framing — never identity/religion

    var bandLabel: String {
        switch band {
        case "none-detected": return "None detected"
        case "possible": return "Possible"
        case "likely": return "Likely"
        case "strong": return "Strong"
        case "insufficient-markers": return "Insufficient markers"
        default: return "Not assessed"
        }
    }
}

struct AdmixtureReport: Hashable {
    var continental: [AdmixtureComponent]       // sorted by share, descending
    var markersUsed: Int
    var markersTotal: Int                       // full panel size (2,621)
    var palindromicDropped: Int                 // A/T–C/G sites present but never strand-resolvable
    var mismatchDropped: Int                    // observed alleles fit neither ref/alt nor complement
    var insufficient: Bool                      // below the tier-1 marker floor — shares withheld

    var withinEuropean: [AdmixtureComponent]    // absolute genome shares; empty when not applicable
    var withinEuropeanApplicable: Bool
    var withinEuropeanNote: String
    var tier2MarkersUsed: Int
    var tier2MarkersTotal: Int

    var asj: ASJSignal?

    var disclosure: String                      // "Markers used: N of 2,621 ..." — always shown
    var notes: [String]                         // model + honesty notes
    var sourceFootnotes: [String]               // per-population reference-source citations
}

struct CompoundTrait: Identifiable, Hashable {
    var id: String
    var title: String
    var value: String
    var detail: String
    var impact: Impact
    var rsids: [String]
}

struct ROHRegion: Identifiable, Hashable {
    var id: String { "\(chromosome):\(start)-\(end)" }
    var chromosome: String
    var start: Int
    var end: Int
    var snpCount: Int
    var lengthMb: Double

    var lengthClass: ROHClass {
        if lengthMb > 16 { return .long }
        if lengthMb > 8 { return .medium }
        return .short
    }
}

enum ROHClass: String, Hashable {
    case short   // 3–8 Mb: ancient/background haplotype sharing
    case medium  // 8–16 Mb: distant founder effects
    case long    // >16 Mb: recent parental relatedness
}

struct ROHReport: Hashable {
    var regions: [ROHRegion]
    var fROH: Double                 // Σ ROH length / observed typed autosomal span
    var longestMb: Double
    var classShortMb: Double
    var classMediumMb: Double
    var classLongMb: Double
    var autosomalCoveredMb: Double   // denominator actually used
    var interpretation: String
}

// MARK: - Genome QC (2.0, feature 6)

enum QCGrade: String, Hashable {
    case pass, warn, fail
}

struct QCCheck: Identifiable, Hashable {
    var id: String
    var title: String
    var grade: QCGrade
    var summary: String
    var details: [String]
}

struct QCReport: Hashable {
    var checks: [QCCheck]
    var buildCall: String            // "GRCh37/hg19", "GRCh38/hg38", "mixed/uncertain"
    var chipFingerprint: String
    var palindromicMatched: Int      // catalog palindromic sites that matched (not strand-resolvable)
    var complementFlippedMatches: Int

    var worstGrade: QCGrade {
        if checks.contains(where: { $0.grade == .fail }) { return .fail }
        if checks.contains(where: { $0.grade == .warn }) { return .warn }
        return .pass
    }

    func details(for id: String) -> [String] {
        checks.first { $0.id == id }?.details ?? []
    }
}

// MARK: - Honesty Surface (2.0, feature 8)

struct HonestyItem: Identifiable, Hashable {
    var id: String
    var category: String             // structural | resolution | statistical | this-file
    var title: String
    var explanation: String
    var pmidNote: String
    var navHint: String?             // catalog category slug this item is most relevant to
}

struct HonestyReport: Hashable {
    var staticEntries: [HonestyItem]
    var computed: [HonestyItem]
    var missingMarkerCount: Int
    var missingMarkerRsids: [String]
    var strandAmbiguousMarkerCount: Int
    var strandAmbiguousMarkerRsids: [String]
    var underCoveredPanels: [String]
    var qcWarnings: [String]
    var euroBiasBannerFires: Bool
    var all: [HonestyItem] { computed + staticEntries }
}

// MARK: - Tiered Headlines (2.0, feature 9)

enum HeadlineSource: String, Hashable {
    case marker, drug, compound, score
}

struct HeadlineFinding: Identifiable, Hashable {
    var id: String
    var tier: Int                    // 1 discuss-with-clinician · 2 act-at-home · 3 good news & typical
    var title: String
    var body: String
    var evidence: String
    var caveat: String               // mandatory — harness fails on empty
    var source: HeadlineSource
    var navTarget: String            // NavItem rawValue to route to
    var rsids: [String]
}

struct CatalogCoverage: Hashable {
    var matched: Int
    var noCall: Int
    var missing: Int
    var strandAmbiguous: Int
    var total: Int { matched + noCall + missing + strandAmbiguous }
}

struct AnalysisReport: Hashable {
    var genome: GenomeFile
    var hits: [MarkerHit]
    var insights: [InsightCard]
    var protocolItems: [ProtocolItem]
    var chronoSchedule: [ChronoProtocolItem]
    var supplementMatrix: SupplementMatrix
    var pharmacogenomics: PharmacogenomicReport
    var pathwayGraphs: [PathwayGraph]
    var calibratedScores: [CalibratedPolygenicScore]
    var ancestry: AncestryResult
    var ancestryPCA: AncestryPCAReport
    var admixture: AdmixtureReport?             // nil when the bundle carries no reference panel
    var compounds: [CompoundTrait]
    var roh: ROHReport
    var catalogCoverage: CatalogCoverage
    var qc: QCReport
}
