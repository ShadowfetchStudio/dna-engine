import Foundation

/// Builds research observations from the PGx catalog without calling star
/// alleles, diplotypes, phenotypes, medication response, or clinical action.
///
/// Consumer arrays are generally unphased and may not resolve CNVs, structural
/// variants, repeats, HLA alleles, or rare defining variants. A finite set of
/// observed SNPs cannot establish the absence of those classes. Palindromic
/// A/T and C/G definitions fail closed unless a future validated orientation
/// manifest explicitly supports them.
enum PharmacogenomicsEngine {
    static func analyze(calls: [String: SNPCall]) -> PharmacogenomicReport {
        guard let genes = KnowledgeBase.shared.pgx, !genes.isEmpty else {
            return PharmacogenomicReport(
                guidelines: [],
                assessedGenes: [:],
                highRiskDrugCount: 0,
                geneObservations: []
            )
        }

        let observations = genes.map { observation(for: $0, calls: calls) }

        // Compatibility records keep unassigned legacy surfaces compiling. They
        // intentionally carry no inferred phenotype, alert severity, or action.
        let guidelines = genes.flatMap { gene in
            let observation = observations.first { $0.gene == gene.gene }!
            let evidence = Dictionary(uniqueKeysWithValues: observation.loci.map {
                ($0.rsid, evidenceText($0))
            })
            return gene.drugs.map { drug in
                DrugGuideline(
                    drugName: drug.name,
                    brandNames: drug.brands,
                    therapeuticArea: area(for: drug.area),
                    gene: drug.gene,
                    cpicLevel: "Source: CPIC \(drug.cpicLevel)",
                    userPhenotype: .indeterminate,
                    clinicalGuideline: "Research observation only. DNA Engine does not infer a star allele, diplotype, phenotype, medication response, or clinical action from these array loci.",
                    alternativeNotes: "If this drug-gene pair is relevant to your history, ask a qualified clinician whether validated testing would add useful information.",
                    impact: .typical,
                    rsids: observation.loci.map(\.rsid),
                    chipLimitations: observation.chipLimitations,
                    evidenceRsids: evidence
                )
            }
        }

        return PharmacogenomicReport(
            guidelines: guidelines.sorted { $0.id < $1.id },
            assessedGenes: Dictionary(uniqueKeysWithValues: genes.map { ($0.gene, .indeterminate) }),
            highRiskDrugCount: 0,
            geneObservations: observations.sorted { $0.gene < $1.gene }
        )
    }

    static func gene(named name: String) -> PGxGeneDef? {
        KnowledgeBase.shared.pgx?.first { $0.gene == name }
    }

    private static func observation(for gene: PGxGeneDef, calls: [String: SNPCall]) -> PGxGeneObservation {
        let definitions = gene.alleles + (gene.subtractAlleles ?? [])
        let loci = definitions.map { locusObservation(definition: $0, calls: calls) }
        let references = gene.drugs.map {
            PGxDrugReference(
                name: $0.name,
                brands: $0.brands,
                gene: $0.gene,
                therapeuticArea: area(for: $0.area),
                sourceLevel: "CPIC \($0.cpicLevel)"
            )
        }
        let limits = "This consumer array is unphased and does not reliably resolve copy-number changes, structural variants, repeats, HLA alleles, or rare variants. No phenotype or medication action is inferred."
        return PGxGeneObservation(
            gene: gene.gene,
            loci: loci,
            drugReferences: references,
            undetectable: gene.undetectable,
            chipLimitations: limits
        )
    }

    private static func locusObservation(definition: PGxAlleleDef, calls: [String: SNPCall]) -> PGxLocusObservation {
        let expected = "\(definition.referenceAllele.uppercased())/\(definition.variantAllele.uppercased())"
        guard let call = calls[definition.rsid] else {
            return PGxLocusObservation(
                rsid: definition.rsid,
                alleleName: definition.name,
                expectedAlleles: expected,
                observedGenotype: "not present",
                status: .missing
            )
        }
        guard !call.isNoCall else {
            return PGxLocusObservation(
                rsid: definition.rsid,
                alleleName: definition.name,
                expectedAlleles: expected,
                observedGenotype: "no-call",
                status: .noCall
            )
        }
        if Strand.isPalindromic(
            alleleA: definition.referenceAllele,
            alleleB: definition.variantAllele
        ) {
            return PGxLocusObservation(
                rsid: definition.rsid,
                alleleName: definition.name,
                expectedAlleles: expected,
                observedGenotype: call.display,
                status: .strandUnresolved
            )
        }

        let expectedSet = Set([
            definition.referenceAllele.uppercased().first!,
            definition.variantAllele.uppercased().first!,
        ])
        let rawKey = call.genotypeKey.uppercased()
        let rawSet = Set(rawKey)
        let complementKey = Strand.complementGenotype(rawKey).uppercased()
        let complementSet = Set(complementKey)
        let status: PGxLocusStatus = rawSet.isSubset(of: expectedSet) || complementSet.isSubset(of: expectedSet)
            ? .observed
            : .alleleMismatch

        return PGxLocusObservation(
            rsid: definition.rsid,
            alleleName: definition.name,
            expectedAlleles: expected,
            observedGenotype: call.display,
            status: status
        )
    }

    private static func evidenceText(_ locus: PGxLocusObservation) -> String {
        locus.status == .observed
            ? locus.observedGenotype
            : "\(locus.status.rawValue.lowercased()): \(locus.observedGenotype)"
    }

    private static func area(for raw: String) -> TherapeuticArea {
        TherapeuticArea.allCases.first { $0.rawValue == raw } ?? .cardiology
    }
}
