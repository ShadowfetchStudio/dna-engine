"""Data-driven compound/diplotype definitions (feature 3).

The Swift CompoundTraits engine is a thin interpreter over these rules.

Rule semantics (mirrored exactly in Sources/CompoundTraits.swift):
  gt(rsid)   -> sorted genotype key of a .matched hit, else "--"
  requireTyped: if any listed rsid is untyped -> emit the partial result and stop
                ("partially typed" honesty path; never guess a diplotype)
  rules      -> first rule whose every condition holds wins
  conditions:
    {"rsid": r, "gt": "CC"}                exact sorted-key match ("--" matches untyped)
    {"rsid": r, "gtIn": ["TT","CT"]}       membership
    {"rsid": r, "hasAllele": "A"}          typed AND contains allele
    {"rsid": r, "countAllele": "T", "min": 1, "max": 2}   allele count in gt (untyped = 0)
  kind == "count": sum matching alleles over countSnps, pick the band containing the sum
  fallback   -> emitted when no rule matches

Legacy declarations remain below for source review, but the release boundary at
the end of this module replaces every outcome with a non-interpretive coverage
receipt. The shipped resource keeps rule identifiers, referenced loci, tiers,
citations, conditions, and coverage requirements without genotype-derived
activity, phenotype, risk, or outcome claims.
"""

PMID = lambda p, n: {"pmid": str(p), "note": n}
GWAS = "GWAS Catalog"
CPIC = "CPIC"
CLIN = "ClinVar"


def R(value, detail, impact, *when):
    return {"when": list(when), "value": value, "detail": detail, "impact": impact}


def F(value, detail, impact):
    return {"value": value, "detail": detail, "impact": impact}


COMPOUNDS = [
    # ------------------------------------------------------------------ ported
    {
        "id": "apoe", "title": "APOE Diplotype", "rsids": ["rs429358", "rs7412"],
        "tier": "well-replicated",
        "citations": [PMID(8346443, "Corder 1993, Science — APOE ε4 dose effect")],
        "rules": [
            R("ε3/ε3 (Typical)", "The most common worldwide APOE diplotype. Standard lipid transport and baseline neurological profile. Cardiovascular risk is primarily driven by lifestyle and standard lipids.", "typical",
              {"rsid": "rs429358", "gt": "TT"}, {"rsid": "rs7412", "gt": "CC"}),
            R("ε2/ε3 (Cardioprotective)", "One ε2 allele. Associated with higher hepatic LDL receptor affinity, lower average circulating LDL-C and ApoB, and lower APOE-related Alzheimer's risk.", "advantageous",
              {"rsid": "rs429358", "gt": "TT"}, {"rsid": "rs7412", "gt": "CT"}),
            R("ε2/ε2 (Low LDL / Monitor Remnants)", "Two ε2 alleles. Markedly lower LDL-C, with potential sensitivity to triglyceride remnant accumulation (Type III hyperlipoproteinemia) if obesity or insulin resistance is present.", "notable",
              {"rsid": "rs429358", "gt": "TT"}, {"rsid": "rs7412", "gt": "TT"}),
            R("ε3/ε4 (Single ε4 Carrier)", "One ε4 allele. Carries higher sensitivity to dietary saturated fat, higher average ApoB, and increased lifetime cardiovascular and neurological risk. Highly responsive to zone-2 exercise, omega-3s, and optimal sleep.", "caution",
              {"rsid": "rs429358", "gt": "CT"}, {"rsid": "rs7412", "gt": "CC"}),
            R("ε4/ε4 (Homozygous ε4)", "Two ε4 alleles. Substantially altered lipid particle clearance and higher lifetime cardiovascular and cognitive susceptibility. Proactive lifestyle prevention (metabolic health, ApoB management, aerobic fitness) is strongly advised.", "caution",
              {"rsid": "rs429358", "gt": "CC"}, {"rsid": "rs7412", "gt": "CC"}),
            R("ε2/ε4 (Mixed Isoforms)", "Contains both ε2 and ε4 alleles. Confers competing lipid clearance dynamics; monitor comprehensive lipid panel (ApoB, Lp(a), triglycerides).", "notable",
              {"rsid": "rs429358", "gt": "CT"}, {"rsid": "rs7412", "gt": "CT"}),
        ],
        "fallback": F("Incompletely Typed", "One or both core APOE markers were missing on this array.", "typical"),
        "caveat": "APOE ε4 is a risk factor, not a diagnosis — lifestyle strongly modulates outcomes, and the AD effect size is smaller in African-ancestry cohorts.",
    },
    {
        "id": "mthfr", "title": "MTHFR Folate Methylation", "rsids": ["rs1801133", "rs1801131"],
        "tier": "well-replicated",
        "citations": [PMID(7647779, "Frosst 1995 — C677T thermolability")],
        "rules": [
            R("Not typed", "Both MTHFR SNPs missing from file.", "typical",
              {"rsid": "rs1801133", "gt": "--"}, {"rsid": "rs1801131", "gt": "--"}),
            R("C677T TT Homozygote (~70% reduction)", "Significant drop in 5-MTHF production and heightened vulnerability to elevated homocysteine when dietary folate or riboflavin (B2) is low. Natural food folates (leafy greens, legumes) and riboflavin are primary lifestyle priorities.", "caution",
              {"rsid": "rs1801133", "countAllele": "T", "min": 2, "max": 2}),
            R("Compound Heterozygote (677CT + 1298AC)", "Compound heterozygous pairing (~40–50% reduction in MTHFR efficiency). Responsive to whole food folates, choline, and balanced B-complex support.", "notable",
              {"rsid": "rs1801133", "countAllele": "T", "min": 1, "max": 1},
              {"rsid": "rs1801131", "countAllele": "C", "min": 1, "max": 2}),
            R("C677T Heterozygote (~35% reduction)", "Intermediate enzyme activity. Easily maintained with regular dietary greens and adequate riboflavin.", "notable",
              {"rsid": "rs1801133", "countAllele": "T", "min": 1, "max": 1}),
            R("A1298C Homozygote (CC)", "Mild regulatory domain effect with minor impact on BH4 recycling under oxidative conditions.", "typical",
              {"rsid": "rs1801131", "countAllele": "C", "min": 2, "max": 2}),
        ],
        "fallback": F("Typical Folate Kinetics (CC/AA)", "No high-impact MTHFR variants detected. Folate conversion proceeds smoothly.", "typical"),
        "caveat": "MTHFR status is nutrient-conditional — with adequate folate and riboflavin most carriers have normal homocysteine.",
    },
    {
        "id": "lipid_complex", "title": "Cardiovascular Lipid Profile", "rsids": ["rs10455872", "rs11591147", "rs708272"],
        "tier": "well-replicated",
        "citations": [PMID(20032323, "Clarke 2009, NEJM — LPA and CAD"), PMID(16554528, "Cohen 2006 — PCSK9 R46L")],
        "rules": [
            R("Elevated Lipoprotein(a) Predisposition", "Carries high-risk LPA variant driving elevated plasma Lp(a)—an independent, genetically fixed driver of vascular atherosclerosis and calcific aortic stenosis. Modifiable risk factors (blood pressure, ApoB, glucose) warrant strict control.", "caution",
              {"rsid": "rs10455872", "hasAllele": "G"}),
            R("PCSK9 Loss-of-Function (Cardioprotective)", "Natural genetic equivalent of PCSK9 inhibitor therapy. Preserves hepatic LDL receptors, conferring lifelong lower LDL-C and substantial coronary disease protection.", "advantageous",
              {"rsid": "rs11591147", "hasAllele": "T"}),
            R("High HDL-C / Reduced CETP Flux", "Reduced CETP activity slows cholesterol transfer from HDL to LDL, promoting higher circulating HDL particle concentration and favorable longevity outcomes.", "advantageous",
              {"rsid": "rs708272", "gt": "AA"}),
        ],
        "fallback": F("Typical Lipid Regulatory Architecture", "Standard baseline for circulating lipoproteins and hepatic uptake.", "typical"),
        "caveat": "A one-time Lp(a) blood test outranks any genotype inference — Lp(a) is directly measurable.",
    },
    {
        "id": "neuro_profile", "title": "Cognitive & Stress Profile", "rsids": ["rs4680", "rs6265", "rs1800497"],
        "tier": "replicated",
        "citations": [PMID(8807664, "Lachman 1996 — COMT Val158Met"), PMID(12553913, "Egan 2003 — BDNF Val66Met")],
        "rules": [
            R("High Dopamine / Stress-Sensitive Neurotype", "Met/Met COMT (high prefrontal dopamine, superior working memory) paired with Met BDNF (reduced activity-dependent neuroplasticity). Thrives in structured, low-distraction environments; benefits deeply from daily mindfulness and aerobic exercise.", "notable",
              {"rsid": "rs4680", "gt": "AA"}, {"rsid": "rs6265", "hasAllele": "T"}),
            R("Resilient 'Warrior' Neurotype (Val/Val)", "Rapid prefrontal catecholamine clearance conferring excellent emotional resilience under high stress and competitive pressure.", "typical",
              {"rsid": "rs4680", "gt": "GG"}),
            R("Reduced D2 Receptor Density / Reward Seeking", "Lower striatal D2 receptor concentration predisposing to reward seeking. Thrives on vigorous athletic training and structured eating routines to prevent dopamine snacking.", "notable",
              {"rsid": "rs1800497", "hasAllele": "A"}),
        ],
        "fallback": F("Balanced Neurotransmitter Dynamics", "Equilibrated dopamine turnover, neuroplasticity, and baseline stress recovery.", "typical"),
        "caveat": "Behavioral-genetics effect sizes are small; these are stylized tendencies, not personality verdicts.",
    },
    {
        "id": "caffeine_sleep", "title": "Caffeine & Sleep Sensitivity", "rsids": ["rs762551", "rs5751876"],
        "tier": "replicated",
        "citations": [PMID(10233211, "Sachse 1999 — CYP1A2*1F"), PMID(GWAS, "ADORA2A caffeine sensitivity replication")],
        "rules": [
            R("High Caffeine Sensitivity & Sleep Disruption", "Slow hepatic caffeine clearance combined with hyper-sensitive adenosine receptors. Caffeine strongly fragments slow-wave deep sleep and can trigger palpitations or anxiety. Keep intake minimal (<100mg) and strictly early morning.", "caution",
              {"rsid": "rs762551", "gt": "CC"}, {"rsid": "rs5751876", "gt": "TT"}),
            R("High Caffeine Sensitivity & Sleep Disruption", "Slow CYP1A2 clearance (caffeine half-life ~8–10 hours). Caffeine strongly fragments slow-wave deep sleep and can trigger palpitations or anxiety. Keep intake minimal (<100mg) and strictly early morning.", "caution",
              {"rsid": "rs762551", "gt": "CC"}),
            R("High Caffeine Sensitivity & Sleep Disruption", "High ADORA2A adenosine receptor sensitivity (caffeine-induced anxiety). Caffeine strongly fragments slow-wave deep sleep and can trigger palpitations or anxiety. Keep intake minimal (<100mg) and strictly early morning.", "caution",
              {"rsid": "rs5751876", "gt": "TT"}),
            R("Fast Caffeine Metabolizer (*1F/*1F)", "Rapid hepatic caffeine clearance. Moderate morning coffee is well-tolerated and cardioprotective.", "advantageous",
              {"rsid": "rs762551", "gt": "AA"}),
        ],
        "fallback": F("Intermediate Caffeine Clearance", "Typical caffeine metabolism. Maintain an 8-hour cutoff before sleep.", "typical"),
        "caveat": "Caffeine response is also dose, tolerance, and sleep-pressure dependent — genotype is one input.",
    },
    {
        "id": "alcohol", "title": "Alcohol Handling & Toxicity", "rsids": ["rs671", "rs1229984"],
        "tier": "well-replicated",
        "citations": [PMID(GWAS, "ALDH2*2 / ADH1B His48 alcohol literature")],
        "rules": [
            R("ALDH2 Deficiency (Asian Flush / Severe Toxicity)", "Dominant negative loss of ALDH2 activity (~80–95% loss). Ingested alcohol rapidly converts to toxic, carcinogenic acetaldehyde causing flushing, tachycardia, and high upper-GI cancer risk. Absolute lifestyle recommendation: Avoid alcohol.", "caution",
              {"rsid": "rs671", "hasAllele": "A"}),
            R("Rapid Ethanol Conversion (ADH1B*2)", "Accelerated ethanol oxidation creating an early acetaldehyde signal, conferring strong natural protection against heavy drinking.", "advantageous",
              {"rsid": "rs1229984", "hasAllele": "T"}),
        ],
        "fallback": F("Standard Alcohol Dehydrogenase / ALDH2", "Normal baseline alcohol clearance.", "typical"),
        "caveat": "ALDH2*2 is East-Asian-derived; its absence here says nothing about other alcohol-risk biology.",
    },
    {
        "id": "iron", "title": "Iron Regulation & Hemochromatosis", "rsids": ["rs1800562", "rs1799945"],
        "tier": "well-replicated",
        "citations": [PMID(8696333, "Feder 1996 — HFE C282Y/H63D")],
        "rules": [
            R("C282Y Homozygote (Severe Hemochromatosis Risk)", "Classic hereditary hemochromatosis genotype causing progressive intestinal iron overload. Avoid all iron supplements and raw shellfish; periodic clinical blood donation (phlebotomy) is highly effective.", "caution",
              {"rsid": "rs1800562", "gt": "AA"}),
            R("Compound Heterozygote (C282Y + H63D)", "Compound carrier state with moderate susceptibility to elevated ferritin and transferrin saturation.", "caution",
              {"rsid": "rs1800562", "hasAllele": "A"}, {"rsid": "rs1799945", "hasAllele": "G"}),
            R("HFE C282Y Carrier", "Single copy carrier. Ferritin may run higher than average; avoid gratuitous iron supplements.", "notable",
              {"rsid": "rs1800562", "hasAllele": "A"}),
        ],
        "fallback": F("Typical Iron Absorption Kinetics", "No high-risk hemochromatosis variants detected.", "typical"),
        "caveat": "Carrier/compound status is not an iron-overload diagnosis; ferritin and transferrin saturation labs with a clinician are the ground truth.",
    },
    {
        "id": "lactase", "title": "Adult Dairy / Lactase Persistence", "rsids": ["rs4988235"],
        "tier": "well-replicated",
        "citations": [PMID(11788828, "Enattah 2002 — LCT -13910C>T")],
        "rules": [
            R("Lactase Persistent (Dairy Tolerant)", "The -13910T variant keeps intestinal lactase active in adulthood, allowing efficient milk sugar digestion.", "advantageous",
              {"rsid": "rs4988235", "gtIn": ["TT", "CT"]}),
            R("Lactase Non-Persistent (Lactose Intolerant)", "Adult decline in intestinal lactase enzyme. Ingestion of unfermented dairy sugar causes bloating and gas; choose fermented dairy (kefir/yogurt), hard cheese, or lactose-free products.", "notable",
              {"rsid": "rs4988235", "gt": "CC"}),
        ],
        "fallback": F("SNP Not Typed", "Lactase marker missing from file.", "typical"),
        "caveat": "This SNP covers the EUROPEAN persistence allele only — African and Middle-Eastern persistence variants are different SNPs this chip may not carry.",
    },
    {
        "id": "bitter", "title": "Bitter Taste Perception (TAS2R38)", "rsids": ["rs713598"],
        "tier": "well-replicated",
        "citations": [PMID(12595690, "Kim 2003 — TAS2R38")],
        "rules": [
            R("Super-Taster Phenotype (PAV)", "High sensitivity to glucosinolate bitterness in cruciferous vegetables and black coffee. Cook brassicas with healthy fats, salt, and lemon to neutralize bitterness.", "notable",
              {"rsid": "rs713598", "hasAllele": "C"}),
        ],
        "fallback": F("Non-Taster Phenotype (AVI)", "Cruciferous vegetables and coffee taste milder and less bitter.", "typical"),
        "caveat": "Single-site shortcut of the three-site haplotype — see the TAS2R38 diplotype card for the full read.",
    },
    {
        "id": "pigment", "title": "Iris & Skin Pigmentation", "rsids": ["rs12913832", "rs1805007"],
        "tier": "well-replicated",
        "citations": [PMID(18172690, "Eiberg 2008 — HERC2")],
        "rules": [
            R("Blue / Light Eyes (HERC2 GG)", "Suppressed OCA2 expression in iris stroma. High predictability for blue, gray, or light green eyes. Paired with MC1R sun-sensitivity variant.", "typical",
              {"rsid": "rs12913832", "gt": "GG"}, {"rsid": "rs1805007", "hasAllele": "T"}),
            R("Blue / Light Eyes (HERC2 GG)", "Suppressed OCA2 expression in iris stroma. High predictability for blue, gray, or light green eyes.", "typical",
              {"rsid": "rs12913832", "gt": "GG"}),
            R("Brown / Dark Eyes (HERC2 AA)", "Full OCA2 expression and dense iris eumelanin.", "typical",
              {"rsid": "rs12913832", "gt": "AA"}),
        ],
        "fallback": F("Hazel / Green / Intermediate Eyes (AG)", "Intermediate melanin synthesis.", "typical"),
        "caveat": "Eye-color prediction accuracy was established in European cohorts; it degrades in admixed and non-European ancestries.",
    },
    {
        "id": "muscle_type", "title": "Muscle Fiber & Athletic Phenotype", "rsids": ["rs1815739", "rs4343"],
        "tier": "well-replicated",
        "citations": [PMID(12879365, "Yang 2003 — ACTN3 R577X")],
        "rules": [
            R("Fast-Twitch Power Specialist (ACTN3 RR + ACE DD)", "Full alpha-actinin-3 expression in fast-twitch fibers paired with higher ACE activity. Primed for explosive power, sprinting, and maximal strength output.", "advantageous",
              {"rsid": "rs1815739", "gt": "CC"}, {"rsid": "rs4343", "hasAllele": "A"}),
            R("Oxidative Endurance Specialist (ACTN3 XX)", "Zero fast-twitch alpha-actinin-3, shifting muscle metabolism toward oxidative efficiency and fatigue resistance. Natural predisposition for distance running, cycling, and rowing.", "advantageous",
              {"rsid": "rs1815739", "gt": "TT"}),
        ],
        "fallback": F("Hybrid Power / Endurance Profile (ACTN3 RX)", "Versatile muscle architecture supporting both strength and aerobic conditioning.", "typical"),
        "caveat": "Sport outcome differences within genotypes dwarf differences between them — train by measured response.",
    },
    {
        "id": "connective_tissue", "title": "Tendon, Ligament & Bone Robustness", "rsids": ["rs1800012", "rs12722"],
        "tier": "replicated",
        "citations": [PMID(GWAS, "COL1A1 Sp1 / COL5A1 injury literature")],
        "rules": [
            R("Elevated Soft-Tissue Injury Susceptibility", "COL1A1 Sp1 variant alters collagen chain stoichiometry, reducing tendon tensile stiffness and increasing risk of cruciate ligament (ACL) and Achilles tendon sprains. Emphasize eccentric strengthening and landing mechanics.", "caution",
              {"rsid": "rs1800012", "hasAllele": "A"}),
            R("High Tendon Stiffness / Superior Running Economy", "Denser tendon collagen matrix providing excellent elastic recoil in running, with lower flexibility.", "advantageous",
              {"rsid": "rs12722", "gt": "TT"}),
        ],
        "fallback": F("Typical Connective Tissue Architecture", "Balanced tendon elasticity and joint mobility.", "typical"),
        "caveat": "Load management and progressive strengthening dominate injury risk regardless of genotype.",
    },
    {
        "id": "vit_d_axis", "title": "Vitamin D Synthesis & Transport", "rsids": ["rs2282679", "rs10741657", "rs2228570"],
        "tier": "well-replicated",
        "citations": [PMID(20418485, "Wang 2010, Lancet — SUNLIGHT consortium")],
        "rules": [
            R("Lower Circulating 25-OH D Tendency", "Carries DBP or CYP2R1 variants associated with lower baseline circulating 25-OH Vitamin D. Regular sun exposure or D3+K2 supplementation (2,000–4,000 IU) is recommended.", "notable",
              {"rsid": "rs2282679", "hasAllele": "C"}),
            R("Lower Circulating 25-OH D Tendency", "Carries DBP or CYP2R1 variants associated with lower baseline circulating 25-OH Vitamin D. Regular sun exposure or D3+K2 supplementation (2,000–4,000 IU) is recommended.", "notable",
              {"rsid": "rs10741657", "gt": "GG"}),
        ],
        "fallback": F("Typical Vitamin D Utilization", "Standard baseline transport and receptor signaling.", "typical"),
        "caveat": "A 25-OH-D blood test outranks genotype inference; supplement doses are a clinician conversation.",
    },
    {
        "id": "vit_a_conversion", "title": "Plant Vitamin A (Beta-Carotene) Cleavage", "rsids": ["rs7501331"],
        "tier": "replicated",
        "citations": [PMID(19103647, "Leung 2009 — BCMO1 variants")],
        "rules": [
            R("Poor Beta-Carotene Converter (~60% reduction)", "Severely blunted BCMO1 enzyme activity. Cannot rely solely on plant carotenoids (carrots/spinach) for active vitamin A; prioritize preformed retinol (egg yolks, wild salmon, grass-fed dairy).", "caution",
              {"rsid": "rs7501331", "gt": "TT"}),
            R("Intermediate Beta-Carotene Conversion (~30% reduction)", "Moderately reduced plant carotenoid cleavage. Include dietary preformed vitamin A.", "notable",
              {"rsid": "rs7501331", "hasAllele": "T"}),
        ],
        "fallback": F("Efficient Beta-Carotene Conversion", "Normal cleavage of dietary carotenoids to active retinal.", "typical"),
        "caveat": "Combined-variant status with rs12934922 gives the fuller conversion picture.",
    },
    {
        "id": "omega3_fads", "title": "Omega-3 Desaturation (ALA to EPA/DHA)", "rsids": ["rs174546"],
        "tier": "well-replicated",
        "citations": [PMID(GWAS, "FADS cluster PUFA GWAS")],
        "rules": [
            R("Low Endogenous EPA/DHA Conversion", "FADS1 desaturase deficiency. Plant ALA (flax/chia) is poorly converted to anti-inflammatory EPA/DHA; direct marine consumption (wild fish or algae oil) is essential.", "caution",
              {"rsid": "rs174546", "gt": "TT"}),
        ],
        "fallback": F("Standard Fatty Acid Desaturation", "Normal baseline conversion of plant essential fatty acids.", "typical"),
        "caveat": "FADS haplotype frequencies differ sharply by ancestry; conversion capacity is a spectrum, not a switch.",
    },
    {
        "id": "histamine_trait", "title": "Histamine Degradation Axis", "rsids": ["rs10156191", "rs11558538"],
        "tier": "replicated",
        "citations": [PMID(GWAS, "AOC1/HNMT functional studies")],
        "rules": [
            R("Elevated Histamine Sensitivity", "Reduced intestinal DAO degradation and slow central HNMT brain histamine clearance. Sensitive to aged cheeses, red wine, cured meats, and fermented foods.", "caution",
              {"rsid": "rs10156191", "hasAllele": "T"}, {"rsid": "rs11558538", "hasAllele": "T"}),
            R("Elevated Histamine Sensitivity", "Reduced gut Diamine Oxidase (DAO) activity. Sensitive to aged cheeses, red wine, cured meats, and fermented foods.", "caution",
              {"rsid": "rs10156191", "hasAllele": "T"}),
            R("Elevated Histamine Sensitivity", "Slower central nervous system HNMT clearance. Sensitive to aged cheeses, red wine, cured meats, and fermented foods.", "caution",
              {"rsid": "rs11558538", "hasAllele": "T"}),
        ],
        "fallback": F("Typical Histamine Clearance", "Standard DAO and HNMT enzyme kinetics.", "typical"),
        "caveat": "Histamine intolerance is a clinical pattern, not a genotype — a structured elimination trial with a log is the test that counts.",
    },
    {
        "id": "autoimmune_hla", "title": "HLA & Autoimmune Markers", "rsids": ["rs4349859", "rs2476601"],
        "tier": "well-replicated",
        "citations": [PMID(15208781, "Begovich 2004 — PTPN22"), PMID(GWAS, "HLA-B27 tag validation")],
        "rules": [
            R("Positive for HLA-B*27 Spondylitis Tag", "Carries HLA-B*27 tag associated with inflammatory back pain (axial spondyloarthritis) and uveitis.", "caution",
              {"rsid": "rs4349859", "hasAllele": "A"}),
            R("PTPN22 Autoimmune Susceptibility Carrier", "R620W variant lowers T-cell receptor activation threshold, increasing risk of thyroid and joint autoimmunity.", "caution",
              {"rsid": "rs2476601", "hasAllele": "A"}),
        ],
        "fallback": F("Low Autoimmune Risk Markers", "Common HLA-B27 and PTPN22 risk tags not detected.", "typical"),
        "caveat": "Tag SNPs approximate HLA typing; a negative tag lowers but does not eliminate the possibility of the allele.",
    },
    {
        "id": "fatty_liver", "title": "Hepatic Steatosis (Fatty Liver)", "rsids": ["rs738409", "rs7946"],
        "tier": "well-replicated",
        "citations": [PMID(18820647, "Romeo 2008 — PNPLA3 I148M")],
        "rules": [
            R("High NAFLD & Liver Fat Vulnerability (PNPLA3 148M)", "Impaired hepatic lipid droplet hydrolysis. Liver is highly sensitive to refined sugars, fructose, and alcohol. Prioritize dietary choline (eggs) and omega-3s.", "caution",
              {"rsid": "rs738409", "hasAllele": "G"}),
        ],
        "fallback": F("Standard Hepatic Lipid Hydrolysis", "Normal baseline PNPLA3 lipase activity.", "typical"),
        "caveat": "Liver fat is measurable (ultrasound/FibroScan) and reversible — genotype only sets the slope.",
    },
    {
        "id": "longevity_trait", "title": "Cellular Longevity & Autophagy", "rsids": ["rs2802292", "rs2736098", "rs3758391"],
        "tier": "well-replicated",
        "citations": [PMID(18765803, "Willcox 2008 — FOXO3")],
        "rules": [
            R("Centenarian FOXO3 Longevity Allele Present", "Carries the major global centenarian longevity factor promoting enhanced autophagy, DNA repair, and stem cell maintenance.", "advantageous",
              {"rsid": "rs2802292", "hasAllele": "G"}),
        ],
        "fallback": F("Standard Cellular Longevity Signaling", "Normal baseline autophagy and DNA repair dynamics.", "typical"),
        "caveat": "Longevity alleles shift odds by percent, not decades — habits remain the dominant term.",
    },
    {
        "id": "cyp2c19_trait", "title": "CYP2C19 Drug Metabolism", "rsids": ["rs4244285", "rs12248560"],
        "tier": "well-replicated",
        "citations": [PMID(CPIC, "CPIC CYP2C19 guidelines")],
        "rules": [
            R("Loss-of-Function Present (*2/*3-like)", "Impaired bioactivation of clopidogrel (Plavix) and slowed clearance of escitalopram and omeprazole.", "caution",
              {"rsid": "rs4244285", "hasAllele": "A"}),
            R("Rapid Metabolizer (*17-like)", "Accelerated drug clearance of PPIs and certain antidepressants.", "notable",
              {"rsid": "rs12248560", "hasAllele": "T"}),
        ],
        "fallback": F("Typical CYP2C19 Metabolism", "Normal drug clearance.", "typical"),
        "caveat": "Notes for discussion with a clinician or pharmacist — never a reason to change any medication yourself.",
    },
    # ------------------------------------------------------------------- new 10
    {
        "id": "tas2r38", "title": "TAS2R38 Bitter Haplotype (PAV/AVI)",
        "rsids": ["rs713598", "rs1726866", "rs10246939"],
        "tier": "well-replicated",
        "citations": [PMID(12595690, "Kim 2003, Science — TAS2R38 haplotypes")],
        "requireTyped": ["rs713598", "rs1726866", "rs10246939"],
        "partial": F("Partially typed", "One or more of the three TAS2R38 haplotype sites is missing from this file — the diplotype cannot be called honestly from a partial set.", "typical"),
        "rules": [
            R("PAV/PAV", "Two full taster haplotypes: strong bitter perception of PTC/PROP-class compounds (brassica glucosinolates, some medications). Supertaster-range perception is common.", "notable",
              {"rsid": "rs713598", "gt": "CC"}, {"rsid": "rs1726866", "gt": "CC"}, {"rsid": "rs10246939", "gt": "TT"}),
            R("PAV/AVI", "One taster and one non-taster haplotype: intermediate bitter perception — the most common configuration in European-ancestry populations.", "typical",
              {"rsid": "rs713598", "gt": "CG"}, {"rsid": "rs1726866", "gt": "CT"}, {"rsid": "rs10246939", "gt": "CT"}),
            R("AVI/AVI", "Two non-taster haplotypes: PTC/PROP bitterness reads faint or absent; cruciferous vegetables taste milder.", "typical",
              {"rsid": "rs713598", "gt": "GG"}, {"rsid": "rs1726866", "gt": "TT"}, {"rsid": "rs10246939", "gt": "CC"}),
        ],
        "fallback": F("Rare / recombinant haplotype pattern", "The three sites do not match the two common haplotypes — rare haplotypes (AAV, PVI, etc.) exist and this array cannot phase them. No confident call.", "typical"),
        "caveat": "Array data is unphased: only the classic PAV/AVI patterns can be called with confidence.",
    },
    {
        "id": "mc1r_load", "title": "MC1R Red-Hair / UV 'R' Allele Load",
        "rsids": ["rs1805007", "rs1805008", "rs1805009"],
        "tier": "well-replicated",
        "citations": [PMID(7581459, "Valverde 1995 — MC1R variants")],
        "kind": "count",
        "countSnps": [
            {"rsid": "rs1805007", "allele": "T"},
            {"rsid": "rs1805008", "allele": "T"},
            {"rsid": "rs1805009", "allele": "C"},
        ],
        "bands": [
            {"min": 0, "max": 0, "value": "0 R alleles detected", "impact": "typical",
             "detail": "None of the three major MC1R loss-of-function alleles detected. Rarer R and r alleles exist that this count does not include; sun sense still required."},
            {"min": 1, "max": 1, "value": "1 R allele (carrier)", "impact": "notable",
             "detail": "One major MC1R loss-of-function allele: fairer sun response, freckling tendency, and a modestly elevated melanoma risk. Sunscreen habits and skin checks carry outsized value."},
            {"min": 2, "max": 6, "value": "2+ R alleles", "impact": "caution",
             "detail": "Two or more major loss-of-function alleles: red-hair-range pheomelanin shift, poor tanning, and clearly elevated UV-damage risk. Daily SPF and dermatology skin checks are the rational baseline."},
        ],
        "fallback": F("Not assessable", "MC1R sites untyped on this file.", "typical"),
        "caveat": "Counts only the three classic R alleles typed on common chips; rarer MC1R variants are invisible here.",
    },
    {
        "id": "fut2_secretor", "title": "FUT2 Secretor Status",
        "rsids": ["rs601338"],
        "tier": "well-replicated",
        "citations": [PMID(GWAS, "FUT2 B12/norovirus literature (Hazra 2008; Lindesmith 2003)")],
        "requireTyped": ["rs601338"],
        "partial": F("Partially typed", "The FUT2 W143X site is missing from this file.", "typical"),
        "rules": [
            R("Non-secretor", "Two stop alleles: no ABO-sugar secretion into gut mucus. Resistant to common GII.4 norovirus strains; serum B12 reads ~10-15% higher than tissue status (labs can flatter you); bifidobacteria run lower — fermented-food variety helps.", "notable",
              {"rsid": "rs601338", "gt": "AA"}),
            R("Secretor (carrier of one stop allele)", "One functional copy is enough: mucosal sugars are secreted. Typical norovirus susceptibility and B12 lab behavior.", "typical",
              {"rsid": "rs601338", "gt": "AG"}),
            R("Secretor", "Full mucosal ABO-sugar secretion. Typical norovirus susceptibility and B12 lab behavior.", "typical",
              {"rsid": "rs601338", "gt": "GG"}),
        ],
        "fallback": F("Unclassified genotype", "Unexpected allele pattern at rs601338 — no call made.", "typical"),
        "caveat": "European-pattern nonsense allele; some other populations carry different FUT2-inactivating variants this SNP misses.",
    },
    {
        "id": "celiac_dq", "title": "Celiac HLA-DQ2.5 / DQ8 Tag Pair",
        "rsids": ["rs2187668", "rs7454108"],
        "tier": "well-replicated",
        "citations": [PMID(18509540, "Monsuur 2008 — HLA tag-SNP validation")],
        "requireTyped": ["rs2187668", "rs7454108"],
        "partial": F("Partially typed", "One of the two HLA tag SNPs is absent from this file. Half a tag pair is not a risk call — no inference is made. Tag SNPs are imperfect proxies even when complete; this is not a celiac test.", "typical"),
        "rules": [
            R("DQ2.5 and DQ8 tags both present", "Both celiac-permissive haplotype tags detected. Lifetime celiac risk is elevated (several percent) but still a minority outcome. If GI symptoms, anemia, or family history exist: celiac serology WHILE still eating gluten.", "caution",
              {"rsid": "rs2187668", "hasAllele": "T"}, {"rsid": "rs7454108", "hasAllele": "C"}),
            R("DQ2.5 tag present", "The stronger celiac-permissive haplotype tag is present (~90% of celiac cases carry DQ2.5; most carriers never develop it). Only meaningful with symptoms or family history — serology first, never a preemptive gluten-free diet.", "notable",
              {"rsid": "rs2187668", "hasAllele": "T"}),
            R("DQ8 tag present", "The weaker celiac-permissive haplotype tag is present. Same guidance: symptoms or family history warrant serology while still consuming gluten.", "notable",
              {"rsid": "rs7454108", "hasAllele": "C"}),
        ],
        "fallback": F("No DQ2.5/DQ8 tag detected", "Neither permissive-haplotype tag detected. Important honesty note: tag SNPs are imperfect proxies — a negative tag does not fully exclude DQ2.5, and this is not a celiac test. Persistent symptoms still deserve clinical evaluation.", "typical"),
        "caveat": "Tag SNPs are imperfect proxies — a negative tag does not exclude DQ2.5; this is not a celiac test.",
    },
    {
        "id": "warfarin_triad", "title": "Warfarin Sensitivity Triad (VKORC1 + CYP2C9 + CYP4F2)",
        "rsids": ["rs9923231", "rs1799853", "rs1057910", "rs2108622"],
        "tier": "well-replicated",
        "citations": [PMID(15930419, "Rieder 2005 — VKORC1"), PMID(CPIC, "CPIC warfarin guideline")],
        "requireTyped": ["rs9923231", "rs1799853", "rs1057910"],
        "partial": F("Partially typed", "Core warfarin-triad markers are missing from this file; no sensitivity summary is made. If warfarin is ever prescribed, clinical-grade genotyping exists.", "typical"),
        "rules": [
            R("Higher predicted sensitivity (VKORC1 + CYP2C9)", "Both reduced VKORC1 expression and reduced CYP2C9 clearance detected — the combination behind most 'low-dose' warfarin requirements. Strictly a note for a prescriber: dosing is always titrated by INR, never by genotype alone.", "caution",
              {"rsid": "rs9923231", "hasAllele": "A"}, {"rsid": "rs1799853", "hasAllele": "T"}),
            R("Higher predicted sensitivity (VKORC1 + CYP2C9)", "Both reduced VKORC1 expression and reduced CYP2C9 clearance detected — the combination behind most 'low-dose' warfarin requirements. Strictly a note for a prescriber: dosing is always titrated by INR, never by genotype alone.", "caution",
              {"rsid": "rs9923231", "hasAllele": "A"}, {"rsid": "rs1057910", "hasAllele": "C"}),
            R("Higher predicted sensitivity (VKORC1)", "Reduced VKORC1 expression (-1639A): the single largest genetic factor in warfarin dose requirement. Prescriber note only.", "notable",
              {"rsid": "rs9923231", "hasAllele": "A"}),
            R("Higher predicted sensitivity (CYP2C9)", "Reduced CYP2C9 clearance (*2/*3 allele present): slower warfarin elimination. Prescriber note only.", "notable",
              {"rsid": "rs1799853", "hasAllele": "T"}),
            R("Higher predicted sensitivity (CYP2C9)", "Reduced CYP2C9 clearance (*3 allele present): slower warfarin elimination. Prescriber note only.", "notable",
              {"rsid": "rs1057910", "hasAllele": "C"}),
            R("Lower predicted sensitivity (CYP4F2 V433M)", "CYP4F2 433M raises available vitamin K: average dose requirement runs slightly HIGHER. Prescriber note only.", "typical",
              {"rsid": "rs2108622", "hasAllele": "T"}),
        ],
        "fallback": F("Typical predicted warfarin sensitivity", "No triad variant detected — average dose-requirement genetics. INR titration remains the only real dosing method.", "typical"),
        "caveat": "African-ancestry-specific alleles (CYP2C9*5/*6/*8, rs12777823) also matter and are summarized on their own cards.",
    },
    {
        "id": "alcohol_flush", "title": "Alcohol Flush Composite (ADH1B + ALDH2)",
        "rsids": ["rs1229984", "rs671"],
        "tier": "well-replicated",
        "citations": [PMID(GWAS, "ADH1B/ALDH2 alcohol-response literature (Brooks 2009)")],
        "requireTyped": ["rs671", "rs1229984"],
        "partial": F("Partially typed", "One of the two flush-axis markers is missing; no composite is made.", "typical"),
        "rules": [
            R("Flush reaction highly likely (ALDH2*2 + fast ADH1B)", "Fast ethanol→acetaldehyde conversion feeding a crippled acetaldehyde-clearance enzyme: rapid flushing, nausea, tachycardia. The flush is an acetaldehyde (Group-1 carcinogen) exposure meter — treat alcohol as biologically expensive.", "caution",
              {"rsid": "rs671", "hasAllele": "A"}, {"rsid": "rs1229984", "hasAllele": "T"}),
            R("Flush reaction likely (ALDH2*2)", "ALDH2*2 halves-to-eliminates acetaldehyde clearance. Flushing with drinks signals acetaldehyde accumulation; esophageal-cancer risk rises steeply with regular drinking in *2 carriers. Minimal or no alcohol is the honest recommendation.", "caution",
              {"rsid": "rs671", "hasAllele": "A"}),
            R("Fast converter, normal clearance (ADH1B*2)", "Fast ethanol oxidation with intact ALDH2: brief acetaldehyde signal that discourages heavy drinking — a protective association against alcohol dependence.", "advantageous",
              {"rsid": "rs1229984", "hasAllele": "T"}),
        ],
        "fallback": F("Typical flush-axis genotype", "Standard conversion and clearance kinetics — no genetic flush expected.", "typical"),
        "caveat": "Both variants are ancestry-concentrated (East-Asian); their absence carries no information about other alcohol risks.",
    },
    {
        "id": "gilbert_ugt1a1", "title": "Gilbert Syndrome Pattern (UGT1A1)",
        "rsids": ["rs887829"],
        "tier": "well-replicated",
        "citations": [PMID(GWAS, "UGT1A1*28 rs887829 tagging literature")],
        "requireTyped": ["rs887829"],
        "partial": F("Partially typed", "UGT1A1 tag SNP missing from this file.", "typical"),
        "rules": [
            R("Gilbert-pattern genotype (TT)", "Tags UGT1A1*28/*28: reduced bilirubin conjugation. Harmless intermittent jaundice under fasting/illness/stress; mildly elevated 'indirect bilirubin' on labs is expected, not alarming. Relevant to irinotecan and atazanavir prescribing (clinician note).", "notable",
              {"rsid": "rs887829", "gt": "TT"}),
            R("Gilbert carrier (CT)", "One reduced-conjugation haplotype: slightly higher average bilirubin; occasionally visible under stress. Benign.", "typical",
              {"rsid": "rs887829", "gt": "CT"}),
            R("Typical conjugation (CC)", "Standard UGT1A1 promoter function — typical bilirubin handling.", "typical",
              {"rsid": "rs887829", "gt": "CC"}),
        ],
        "fallback": F("Unclassified genotype", "Unexpected allele pattern — no call.", "typical"),
        "caveat": "Gilbert syndrome is benign; the value of knowing is explaining a yellow-tinged lab result before anyone worries. East-Asian *6 allele (rs4148323) is a separate card.",
    },
    {
        "id": "lactase_mcm6", "title": "Lactase Persistence Two-Site Read (MCM6)",
        "rsids": ["rs4988235", "rs182549"],
        "tier": "well-replicated",
        "citations": [PMID(11788828, "Enattah 2002 — both MCM6 enhancer sites")],
        "requireTyped": ["rs4988235", "rs182549"],
        "partial": F("Partially typed", "Only one of the two MCM6 enhancer sites is present — see the single-site lactase card instead.", "typical"),
        "rules": [
            R("Lactase persistent (concordant two-site)", "Both enhancer sites carry the persistence haplotype — adult lactase production expected. Dairy tolerance is also microbiome-conditioned; genotype is the ceiling, not the floor.", "advantageous",
              {"rsid": "rs4988235", "gtIn": ["TT", "CT"]}, {"rsid": "rs182549", "gtIn": ["TT", "CT"]}),
            R("Lactase non-persistent (concordant two-site)", "Both sites carry the ancestral haplotype: adult lactase decline expected. Fermented dairy, hard cheeses, and lactase tablets cover most use-cases.", "notable",
              {"rsid": "rs4988235", "gt": "CC"}, {"rsid": "rs182549", "gt": "CC"}),
        ],
        "fallback": F("Discordant sites — reduced confidence", "The two enhancer sites disagree, which usually means a genotyping error at one site or a non-European persistence haplotype this pair cannot read. No confident call; symptoms are the better guide here.", "typical"),
        "caveat": "European-haplotype read; African/Middle-Eastern persistence alleles are different variants (e.g. -14010G>C) not covered here.",
    },
    {
        "id": "eye_color_v2", "title": "Eye Color Refinement (HERC2 + OCA2 R419Q)",
        "rsids": ["rs12913832", "rs1800407"],
        "tier": "well-replicated",
        "citations": [PMID(18172690, "Eiberg 2008 — HERC2"), PMID(17236130, "Duffy 2007 — OCA2")],
        "requireTyped": ["rs12913832", "rs1800407"],
        "partial": F("Partially typed", "One of the two eye-color loci is missing; see the basic pigmentation card.", "typical"),
        "rules": [
            R("Blue-leaning (HERC2 GG, no modifier)", "The blue-eye enhancer genotype without the green/hazel modifier: blue or gray iris highly likely in European-ancestry backgrounds.", "typical",
              {"rsid": "rs12913832", "gt": "GG"}, {"rsid": "rs1800407", "gt": "CC"}),
            R("Green/hazel-leaning (HERC2 GG + R419Q)", "Blue-enhancer genotype PLUS the OCA2 419Gln modifier: odds shift toward green or hazel.", "typical",
              {"rsid": "rs12913832", "gt": "GG"}, {"rsid": "rs1800407", "hasAllele": "T"}),
            R("Hazel/light-brown-leaning (HERC2 AG + R419Q)", "Intermediate enhancer with the green/hazel modifier: hazel to light brown most likely.", "typical",
              {"rsid": "rs12913832", "gt": "AG"}, {"rsid": "rs1800407", "hasAllele": "T"}),
            R("Intermediate (HERC2 AG)", "One enhancer copy: hazel/green/light-brown range; prediction confidence is genuinely lower here.", "typical",
              {"rsid": "rs12913832", "gt": "AG"}),
            R("Brown-leaning (HERC2 AA)", "Full OCA2 expression: brown iris highly likely regardless of the modifier.", "typical",
              {"rsid": "rs12913832", "gt": "AA"}),
        ],
        "fallback": F("Unclassified pattern", "Unexpected genotype combination — no call.", "typical"),
        "caveat": "Prediction accuracy was established in European cohorts and degrades with admixture — treat as an estimate.",
    },
    {
        "id": "hfe_compound", "title": "HFE Compound Status (C282Y × H63D)",
        "rsids": ["rs1800562", "rs1799945"],
        "tier": "well-replicated",
        "citations": [PMID(8696333, "Feder 1996 — HFE"), PMID(CLIN, "HFE penetrance annotations")],
        "requireTyped": ["rs1800562", "rs1799945"],
        "partial": F("Partially typed", "One HFE site is missing; see the single-marker iron cards.", "typical"),
        "rules": [
            R("C282Y homozygote", "The classic hereditary-hemochromatosis genotype. Penetrance is incomplete (~10-30% of males develop iron overload; fewer females pre-menopause). Ferritin + transferrin saturation labs with a clinician are the next honest step — not supplements, not panic.", "caution",
              {"rsid": "rs1800562", "gt": "AA"}),
            R("Compound heterozygote (C282Y + H63D)", "One copy of each variant: mildly elevated iron-overload susceptibility (~1-2% clinical penetrance). Carrier/compound status, not an iron-overload diagnosis; ferritin labs with a clinician settle it.", "notable",
              {"rsid": "rs1800562", "hasAllele": "A"}, {"rsid": "rs1799945", "hasAllele": "G"}),
            R("C282Y carrier", "One C282Y copy: ferritin may run modestly higher; skip gratuitous iron supplements. Not a diagnosis.", "notable",
              {"rsid": "rs1800562", "hasAllele": "A"}),
            R("H63D homozygote", "Two H63D copies: small average iron-index elevation, rarely clinically meaningful alone.", "typical",
              {"rsid": "rs1799945", "gt": "GG"}),
            R("H63D carrier", "One H63D copy: minimal effect in isolation.", "typical",
              {"rsid": "rs1799945", "hasAllele": "G"}),
        ],
        "fallback": F("No HFE risk alleles detected", "Neither C282Y nor H63D detected — typical HFE iron regulation.", "typical"),
        "caveat": "Carrier/compound status, not an iron-overload diagnosis; ferritin labs with a clinician are the ground truth.",
    },
]


NEUTRAL_COMPOUND_VALUE = "Research rule coverage only"
NEUTRAL_COMPOUND_DETAIL = (
    "Referenced loci are retained for research provenance. No genotype-derived activity, "
    "phenotype, diagnosis, risk, sensitivity, or personal outcome is inferred."
)


def _neutralize_outcome(outcome):
    outcome["value"] = NEUTRAL_COMPOUND_VALUE
    outcome["detail"] = NEUTRAL_COMPOUND_DETAIL
    outcome["impact"] = "typical"


def neutralize_compound_outcomes(compounds):
    for compound in compounds:
        compound["caveat"] = NEUTRAL_COMPOUND_DETAIL
        _neutralize_outcome(compound["fallback"])
        if compound.get("partial"):
            _neutralize_outcome(compound["partial"])
        for rule in compound.get("rules", []):
            _neutralize_outcome(rule)
        for band in compound.get("bands", []):
            _neutralize_outcome(band)


neutralize_compound_outcomes(COMPOUNDS)


def lint_compounds(compounds):
    errors = []
    seen = set()
    for c in compounds:
        cid = c.get("id", "?")
        if cid in seen:
            errors.append(f"compound {cid}: duplicate id")
        seen.add(cid)
        for key in ("id", "title", "rsids", "fallback", "tier", "citations", "caveat"):
            if not c.get(key):
                errors.append(f"compound {cid}: missing {key}")
        if c.get("kind") == "count":
            if not c.get("countSnps") or not c.get("bands"):
                errors.append(f"compound {cid}: count kind requires countSnps + bands")
        elif not c.get("rules"):
            errors.append(f"compound {cid}: missing rules")
        for rule in c.get("rules", []):
            for cond in rule.get("when", []):
                if cond.get("rsid") not in c.get("rsids", []):
                    errors.append(f"compound {cid}: rule condition references rsid {cond.get('rsid')} not in rsids list")
        if c.get("requireTyped") and not c.get("partial"):
            errors.append(f"compound {cid}: requireTyped without partial result")
        outcomes = [c["fallback"]] + list(c.get("rules", [])) + list(c.get("bands", []))
        if c.get("partial"):
            outcomes.append(c["partial"])
        for outcome in outcomes:
            if outcome.get("value") != NEUTRAL_COMPOUND_VALUE \
                    or outcome.get("detail") != NEUTRAL_COMPOUND_DETAIL \
                    or outcome.get("impact") != "typical":
                errors.append(f"compound {cid}: genotype-derived outcome crossed the release boundary")
        if c.get("caveat") != NEUTRAL_COMPOUND_DETAIL:
            errors.append(f"compound {cid}: legacy caveat crossed the release boundary")
    return errors
