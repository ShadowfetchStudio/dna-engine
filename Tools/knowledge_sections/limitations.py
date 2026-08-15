"""Curated 'What This Can't Tell You' entries (feature 8).

Static, always-true limits of consumer SNP-array data, rendered in the Limits
panel and appended unconditionally to every exported report. Computed,
file-specific limits (markers absent from this chip, under-covered panels, QC
warnings) are generated at runtime by Sources/HonestyEngine.swift and merged
with these.

category: structural  — the array physically cannot see it
          resolution  — the array sees a proxy, not the thing itself
          statistical — the math cannot honestly reach individual precision
"""


def lim(id_, category, title, explanation, pmidNote):
    return {"id": id_, "category": category, "title": title,
            "explanation": explanation, "pmidNote": pmidNote}


LIMITATIONS = [
    lim("cnv", "structural", "Copy-number variation is invisible",
        "SNP arrays read single letters. Whole-gene deletions and duplications — CYP2D6*5 and duplications (drug metabolism), GSTM1/GSTT1 nulls (detox), SMN1 (SMA carrier status), alpha-globin deletions — do not appear at all. Every metabolizer call here is a lower-bound estimate.",
        "CPIC CYP2D6 guideline; array-CNV methodology reviews"),
    lim("rare_variants", "structural", "Rare and family-specific variants are not on the chip",
        "Arrays type common population variants. The mutation that actually runs in one family — including most pathogenic BRCA1/2 variants (thousands are known; arrays carry a handful), Lynch-syndrome genes, and familial-hypercholesterolemia LDLR variants — is usually absent. A quiet report here says NOTHING about rare familial risk.",
        "ACMG secondary-findings statements; BRCA variant databases (ClinVar)"),
    lim("repeats", "structural", "Repeat expansions cannot be measured",
        "Huntington (HTT CAG), fragile X (FMR1 CGG), C9orf72, and myotonic-dystrophy expansions are length mutations. Arrays cannot count repeats — no reassurance and no alarm about any of these conditions can come from this data.",
        "Repeat-expansion disorder reviews (ClinVar/GeneReviews)"),
    lim("hla", "resolution", "HLA types are tagged, never typed",
        "Celiac DQ2.5/DQ8, HLA-B27, B*57:01, and DRB1*15:01 appear here via linkage tag SNPs. Tags have false positives and negatives; clinical HLA typing is a different technology. A negative tag lowers odds — it does not exclude the allele.",
        "Monsuur 2008 (PMID 18509540) tag-SNP validation"),
    lim("phasing", "resolution", "Maternal and paternal copies are not separated",
        "Arrays report unphased genotypes: two heterozygous sites cannot be assigned to the same or opposite chromosomes. Compound-heterozygote and haplotype calls (TAS2R38, CYP2D6 allele pairs, HFE trans/cis) are inferences that phase-aware clinical tests would confirm or overturn.",
        "Phasing methodology literature (Browning reviews)"),
    lim("denovo", "structural", "De novo and somatic changes are absent",
        "This file is one snapshot of inherited germline variation. Mutations acquired during life (clonal hematopoiesis, tumor genetics) and new mutations not carried by either parent are outside its reach entirely.",
        "Somatic-mosaicism reviews"),
    lim("mt_y_depth", "structural", "Mitochondrial and Y coverage is thin or absent",
        "Some vendors include sparse MT/Y probes, some none. Haplogroup-level ancestry, heteroplasmy, and Y-line detail need dedicated sequencing; absence of MT/Y rows in this file is a chip property, not a biological finding.",
        "Vendor chip documentation"),
    lim("prs_scale", "statistical", "Tendency panels are sketches, not clinical PRS",
        "The polygenic panels here use handfuls of well-replicated SNPs. Clinical polygenic risk scores use thousands to millions of variants with ancestry-matched validation — and even those explain a minority of risk for most diseases. Percentiles here are honest tendencies, never destiny.",
        "Khera 2018 (PMID 30104762) genome-wide PRS methodology"),
    lim("ancestry_bias", "statistical", "Most discovery cohorts were European",
        "The majority of GWAS participants have been of European ancestry. Effect sizes and percentiles transfer imperfectly to other ancestries — sometimes badly. Cards in this app carry per-marker transferability tags, and the ancestry-aware banners fire when this matters for your estimated mix.",
        "Martin 2019 (PMID 30926966) PRS transferability"),
    lim("penetrance", "statistical", "Risk genotypes are not diagnoses",
        "Even large-effect genotypes (HFE C282Y/C282Y, Factor V Leiden, APOE ε4/ε4) have incomplete penetrance — most carriers of most risk genotypes never develop the condition. Genotype sets a slope; environment, time, and luck set the curve.",
        "Penetrance epidemiology (Beutler 2002 HFE penetrance, PMID 11812557)"),
    lim("array_error", "resolution", "Single-marker results can simply be wrong",
        "Array genotyping error is real (roughly 0.1–0.5% per call, worse for rare alleles and indel-adjacent sites). Any single surprising result — especially a rare 'risk homozygote' — deserves clinical-grade confirmation before anyone acts on it.",
        "Array validation studies (Weedon 2021 rare-variant array error, PMID 33436824)"),
    lim("no_expression", "structural", "Gene expression, epigenetics, and environment are absent",
        "Methylation state, expression levels, microbiome, diet, training, and sleep — the things that actually run day-to-day biology — are not in this file. DNA is the parts list, not the running engine.",
        "Twin-study heritability reviews"),
    lim("drug_levels", "resolution", "Pharmacogenomics here is notes, not prescriptions",
        "PGx cards summarize CPIC-tier associations from a consumer array: unphased, CNV-blind, rare-allele-blind. They are conversation material for a physician or pharmacist, never grounds to start, stop, or change any medication.",
        "CPIC guideline scope statements"),
    lim("sex_chrom", "resolution", "X/Y interpretation is simplified",
        "Hemizygous male X calls, X-inactivation, and pseudoautosomal regions complicate X-linked interpretation; this app reports X-linked markers with reduced confidence and no dosage modeling.",
        "X-inactivation reviews"),
    lim("build_positions", "resolution", "Genome-build coordinates can disagree",
        "Files arrive in GRCh37 or GRCh38 coordinates. The QC tab infers the build from sentinel positions; a mixed or misdeclared build shifts positions, not genotypes — rsID matching keeps interpretation stable, but position displays may be off for a mismatched build.",
        "Genome Reference Consortium build documentation"),
    lim("dec2_cyp2a6_hla1502", "structural", "Deliberately excluded calls",
        "DEC2/BHLHE41 short-sleep variants (too rare, not on chips), full CYP2A6 status (deletion/duplication-dominated), and HLA-B*15:02 (no reliable array tag across ancestries) are deliberately NOT called in this app. Their absence is a refusal, not an oversight.",
        "Generator SKIPPED block; CPIC carbamazepine guideline for B*15:02 context"),
    lim("fine_scale_ancestry", "statistical", "Fine-scale ancestry is a signal, not a passport",
        "Continental admixture estimates are robust; within-continent estimates are not. Intra-European differentiation is tiny (Fst ~0.001-0.01), so sub-continental percentages carry +/-10-15 point uncertainty at best, recent admixture blurs them further, and reference panels (1000 Genomes, gnomAD) are convenience samples, not censuses of any people. No result here says what anyone 'is' — ancestry composition is not nationality, ethnicity, religion, or identity.",
        "Novembre 2008 (PMID 18758442) genes-mirror-geography; intra-European Fst literature"),
]


def lint_limitations(items):
    errors = []
    valid_cat = {"structural", "resolution", "statistical"}
    seen = set()
    for it in items:
        lid = it.get("id", "?")
        if lid in seen:
            errors.append(f"limitation {lid}: duplicate id")
        seen.add(lid)
        if it.get("category") not in valid_cat:
            errors.append(f"limitation {lid}: bad category {it.get('category')!r}")
        for key in ("title", "explanation", "pmidNote"):
            if not str(it.get(key, "")).strip():
                errors.append(f"limitation {lid}: missing {key}")
    return errors
