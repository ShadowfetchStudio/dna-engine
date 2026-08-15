"""Caffeine, alcohol, nicotine & reward biology — curated chip-callable markers.

Educational only: nothing here is a treatment recommendation. Dependence-risk
markers are framed as tendencies with honest effect sizes.
"""
from .common import G, C, CHIPS_ALL, PGKB, GWAS, CLIN, CPIC


def register(add):
    add(
        "rs2472297", "CYP1A1/CYP1A2", "Coffee Consumption Signal (15q24 intergenic)", "15", 75027880,
        ["substances", "caffeine", "detox"], "strong", "C", "T",
        "The CYP1A1-CYP1A2 intergenic region is the strongest habitual-coffee-intake locus in GWAS: the T allele associates with higher caffeine clearance and, behaviorally, with drinking more coffee to reach the same effect.",
        G("Reference clearance (CC)", "typical", "Typical constitutive CYP1A2 expression.", "Habit and sleep pressure drive intake more than genotype."),
        G("One faster-clearance allele (CT)", "typical", "Slightly faster caffeine turnover.", "Cohorts show ~0.2 cups/day higher average intake per T allele."),
        G("Faster-clearance pair (TT)", "typical", "Higher constitutive CYP1A2 expression.", "Higher average intake; pair with rs762551 for induced clearance."),
        tier="well-replicated", transferability="multi-ancestry",
        effect="~0.15-0.2 cups/day per allele in consumption GWAS — small but iron-clad",
        citations=[C(21490707, "Cornelis 2011, PLoS Genet — coffee consumption meta-GWAS"),
                   C(GWAS, "Replicated in UK Biobank coffee/caffeine analyses")],
    )
    add(
        "rs4410790", "AHR", "Caffeine Intake Signal (AHR promoter region)", "7", 17284577,
        ["substances", "caffeine", "detox"], "strong", "T", "C",
        "AHR regulates CYP1A induction. The C allele associates with higher habitual caffeine intake — the second core signal from coffee-consumption GWAS.",
        G("Reference (TT)", "typical", "Typical AHR-driven induction.", "Typical caffeine handling."),
        G("One copy (CT)", "typical", "Slightly higher average intake.", "Small behavioral effect."),
        G("Higher-intake pair (CC)", "typical", "Higher average caffeine consumption.", "Behavioral tendency only; sleep quality should set your ceiling, not genotype."),
        tier="well-replicated", transferability="multi-ancestry",
        effect="~0.2 cups/day per allele — small",
        citations=[C(21490707, "Cornelis 2011, PLoS Genet — AHR and coffee intake")],
    )
    add(
        "rs2470893", "CYP1A1/CYP1A2", "Caffeine Region Companion Signal", "15", 75019449,
        ["substances", "caffeine"], "moderate", "C", "T",
        "Companion intergenic signal at the CYP1A locus from coffee GWAS, in partial LD with rs2472297.",
        G("Reference (CC)", "typical", "Typical expression contribution.", "See rs2472297 for the lead signal."),
        G("One copy (CT)", "typical", "Intermediate.", "Small intake shift."),
        G("Two copies (TT)", "typical", "Higher-intake-associated pair.", "Small additional contribution."),
        tier="replicated", effect="Small, LD-supported",
        citations=[C(GWAS, "Coffee-consumption GWAS (Sulem 2011; Cornelis 2011)")],
    )
    add(
        "rs16969968", "CHRNA5", "Nicotine Dependence (D398N)", "15", 78882925,
        ["substances", "detox"], "strong", "G", "A",
        "The nicotinic receptor α5 D398N variant changes receptor desensitization: the A allele raises cigarettes-per-day, nicotine dependence, and smoking-related lung-cancer risk — the most replicated smoking-behavior variant known.",
        G("Reference (GG)", "typical", "Typical α5 receptor function.", "Dependence risk driven mainly by exposure and environment."),
        G("One risk allele (AG)", "notable", "Higher heaviness-of-smoking tendency if you smoke.", "OR ~1.3 for heavy smoking per allele. Irrelevant if you never start — the genotype only expresses through nicotine exposure.",
          recover=["If you smoke and have tried quitting before, structured cessation support has good evidence for D398N carriers."]),
        G("Two risk alleles (AA)", "caution", "Strongest common genetic push toward heavy smoking.", "OR ~1.6-2 for heavy smoking; also linked to higher smoking-related lung-cancer risk (largely through smoking behavior itself).",
          recover=["Treat nicotine as a substance your receptors handle atypically; never-starting or full cessation are the only clean answers."]),
        tier="well-replicated", transferability="multi-ancestry",
        effect="OR ~1.3 per allele for heavy smoking; +1 cigarette/day per allele averages",
        citations=[C(18385738, "Thorgeirsson 2008, Nature — CHRNA5 and smoking quantity/lung cancer"),
                   C(GWAS, "TAG consortium smoking meta-analyses")],
    )
    add(
        "rs1051730", "CHRNA3", "Smoking Quantity Tag (15q25 cluster)", "15", 78894339,
        ["substances", "detox"], "strong", "C", "T",
        "Synonymous CHRNA3 variant in near-perfect LD with CHRNA5 D398N; the classic 'cigarettes per day' GWAS tag.",
        G("Reference (CC)", "typical", "Typical at the 15q25 cluster.", "See rs16969968 for mechanism."),
        G("One risk allele (CT)", "notable", "Higher smoking-quantity tendency if smoking.", "Tracks the D398N signal."),
        G("Two risk alleles (TT)", "notable", "Strong smoking-quantity association.", "Tracks the D398N signal; meaningful only with nicotine exposure."),
        tier="well-replicated", transferability="multi-ancestry",
        effect="~1 cigarette/day per allele among smokers",
        citations=[C(18385738, "Thorgeirsson 2008, Nature — 15q25 smoking locus")],
    )
    add(
        "rs698", "ADH1C", "Alcohol Dehydrogenase 1C (Ile350Val)", "4", 100260789,
        ["substances", "detox"], "moderate", "A", "G",
        "ADH1C *1 (Ile) metabolizes ethanol ~2.5x faster than *2 (Val). A milder analogue of the ADH1B story: faster acetaldehyde generation modestly discourages heavy drinking.",
        G("Fast pair (*1/*1, AA)", "typical", "Faster ethanol oxidation.", "Slightly higher acetaldehyde flux while drinking; modest protective association against alcohol dependence."),
        G("Intermediate (*1/*2, AG)", "typical", "Intermediate kinetics.", "Typical response."),
        G("Slower pair (*2/*2, GG)", "typical", "Slower ADH1C kinetics.", "Slightly slower ethanol front-end clearance; effect far smaller than ADH1B His48."),
        tier="replicated", transferability="multi-ancestry",
        effect="~2.5x in-vitro kinetic difference; small behavioral effect",
        citations=[C(GWAS, "ADH1C alcohol-dependence meta-analyses")],
    )
    add(
        "rs2066702", "ADH1B", "ADH1B*3 (Arg369Cys, African-ancestry allele)", "4", 100229017,
        ["substances", "detox"], "moderate", "C", "T",
        "ADH1B*3 is a fast-metabolizing allele common in African-ancestry populations (and near-absent elsewhere) with protective associations against alcohol dependence — the African-ancestry counterpart of the East-Asian *2 story.",
        G("No *3 allele (CC)", "typical", "Reference kinetics at this site.", "See rs1229984 for the *2 allele."),
        G("One *3 allele (CT)", "typical", "Faster ethanol oxidation.", "Modest protective association against heavy drinking."),
        G("Two *3 alleles (TT)", "typical", "Fast-metabolizer pair.", "Stronger early-acetaldehyde signal while drinking."),
        tier="replicated", transferability="african-derived",
        effect="Protective OR ~0.5-0.7 for alcohol dependence in African-ancestry cohorts",
        citations=[C(GWAS, "ADH1B*3 alcohol-dependence studies (Edenberg lab and successors)")],
    )
    add(
        "rs279858", "GABRA2", "GABA-A α2 & Alcohol Dependence Tendency", "4", 46313967,
        ["substances", "stress"], "moderate", "T", "C",
        "GABRA2 variants showed replicated association with alcohol dependence in family and case-control studies; effect is modest and behaviorally mediated.",
        G("Reference (TT)", "typical", "Typical GABA-A α2 haplotype.", "Environment and drinking culture dominate risk."),
        G("One risk allele (CT)", "typical", "Small dependence-tendency signal.", "Meaningful only alongside heavy exposure."),
        G("Two risk alleles (CC)", "notable", "Replicated modest dependence association.", "Worth knowing if alcohol problems run in the family; genotype is a nudge, not a verdict.",
          recover=["Family history plus this tendency is a good reason for deliberate alcohol rules (quantity caps, alcohol-free days)."]),
        tier="replicated", effect="OR ~1.2-1.4 in meta-analyses — modest",
        citations=[C(GWAS, "GABRA2 alcohol-dependence meta-analyses (Edenberg 2004 and successors)")],
    )
    add(
        "rs1799971", "OPRM1", "Mu-Opioid Receptor (A118G) — Reward Sensitivity", "6", 154360797,
        ["substances", "stress"], "moderate", "A", "G",
        "OPRM1 A118G changes mu-receptor expression/binding. Evidence for reward-response differences (alcohol 'liking', social sensitivity) is replicated at tendency level; evidence for opioid ANALGESIC dosing implications is mixed — deliberately NOT presented as a drug card here.",
        G("Reference (AA)", "typical", "Common mu-receptor form.", "Typical reward-circuit baseline."),
        G("One 118G copy (AG)", "typical", "Possible heightened reward response to alcohol.", "Some studies suggest stronger naltrexone response in 118G carriers — evidence mixed; a clinician question, not a self-experiment."),
        G("Two 118G copies (GG)", "typical", "Reward-sensitivity tendency.", "Tendency-level evidence only. No dosing implication is offered because replication for clinical endpoints is inconsistent."),
        notes="Excluded from the pharmacogenomics drug cards on evidence grounds — see the Limitations panel.",
        tier="tendency", transferability="multi-ancestry",
        effect="Tendency-level behavioral associations; clinical PGx evidence mixed",
        citations=[C(GWAS, "OPRM1 A118G reward/naltrexone literature — heterogeneous"),
                   C(PGKB, "OPRM1 annotations (evidence level below CPIC actionability)")],
    )
    add(
        "rs806380", "CNR1", "Cannabinoid Receptor 1 — Dependence Tendency", "6", 88870761,
        ["substances", "stress"], "moderate", "A", "G",
        "CNR1 intronic variant with replicated but modest association to cannabis-dependence symptoms in adolescent/young-adult cohorts.",
        G("Reference (AA)", "typical", "Typical CB1 haplotype.", "Exposure age and frequency dominate risk."),
        G("One copy (AG)", "typical", "Small tendency signal.", "Modest association only."),
        G("Two copies (GG)", "typical", "Replicated modest association with dependence symptoms.", "A nudge worth knowing for heavy users; not a diagnosis."),
        tier="tendency", effect="Modest, cohort-dependent",
        citations=[C(GWAS, "CNR1 cannabis-dependence studies (Hopfer 2007 and successors)")],
    )
    add(
        "rs6277", "DRD2", "D2 Receptor C957T — Dopamine Signaling", "11", 113283459,
        ["substances", "cognition", "neurotransmitters"], "moderate", "C", "T",
        "C957T alters DRD2 mRNA stability and striatal D2 availability (distinct from ANKK1 Taq1A). The T allele associates with altered reinforcement learning in imaging cohorts.",
        G("CC", "typical", "Higher striatal D2 availability pattern.", "Typical reinforcement-learning baseline."),
        G("CT", "typical", "Intermediate.", "Intermediate receptor-availability pattern."),
        G("TT", "typical", "Lower striatal D2 availability pattern.", "Associated with different reward-learning style in studies; behavioral relevance modest."),
        tier="replicated", effect="Replicated receptor-availability effect; modest behavioral relevance",
        citations=[C(GWAS, "DRD2 C957T PET and learning studies (Hirvonen 2004)")],
    )
    add(
        "rs4633", "COMT", "COMT Haplotype Partner (His62His)", "22", 19950235,
        ["substances", "cognition", "neurotransmitters"], "moderate", "C", "T",
        "Synonymous COMT variant forming the functional expression haplotype with Val158Met; useful for reading COMT as a haplotype rather than a single SNP.",
        G("CC", "typical", "Common haplotype support.", "Interpret with rs4680."),
        G("CT", "typical", "Heterozygous haplotype support.", "Interpret with rs4680."),
        G("TT", "typical", "Minor haplotype pair.", "Interpret with rs4680."),
        tier="replicated", effect="Haplotype-refinement role",
        citations=[C(GWAS, "COMT haplotype expression studies (Nackley 2006)")],
    )
