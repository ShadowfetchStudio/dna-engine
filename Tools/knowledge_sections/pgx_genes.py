"""Data-driven pharmacogenomics star-allele tables (feature 5).

The Swift PharmacogenomicsEngine uses these tables as a research-observation
catalog only:

  * per gene: allele defs {name, rsid, referenceAllele, variantAllele}; no
    activity score or phenotype threshold is shipped
  * every defining rsid is emitted in the observation receipt
  * missing/no-call/mismatched/palindromic loci remain explicitly unresolved
  * no star allele, diplotype, phenotype, response, or clinical action is called
  * every gene MUST carry a non-empty `undetectable` list and a
    `chipLimitations` disclosure string — the lint enforces both, so the
    honesty text cannot be dropped from data.

Legacy per-phenotype call-site prose remains in this source only to keep the
catalog declarations reviewable during migration. `P` deliberately discards it
when generating the product resource; emitted records contain neutral research
framing and no treatment direction.
"""

CPIC = "CPIC"
PGKB = "PharmGKB"


def allele(name, rsid, ref, var, activity):
    _ = activity
    return {"name": name, "rsid": rsid, "referenceAllele": ref, "variantAllele": var, "activity": 0.0}


def bands(*pairs):
    _ = pairs
    return []


def drug(name, brands, area, gene, level, rsids, per, combineGenes=None):
    d = {"name": name, "brands": brands, "area": area, "gene": gene,
         "cpicLevel": level, "rsids": rsids, "perPhenotype": per}
    if combineGenes:
        d["combineGenes"] = combineGenes
    return d


def P(guideline, alternatives, impact):
    _ = (guideline, alternatives, impact)
    return {
        "guideline": "Published drug-gene guidance exists; DNA Engine reports observed array loci only and does not infer a clinical phenotype or action.",
        "alternatives": "If relevant to a personal medication history, a qualified clinician can decide whether validated testing would add useful information.",
        "impact": "typical",
    }


PGX_GENES = [
    {
        "gene": "CYP2C19",
        "alleles": [
            allele("*2", "rs4244285", "G", "A", 0.0),
            allele("*3", "rs4986893", "G", "A", 0.0),
            allele("*17", "rs12248560", "C", "T", 1.5),
        ],
        "wildActivity": 1.0,
        "phenotypeBands": bands((0.5, "poor"), (1.75, "intermediate"), (2.25, "normal"), (2.75, "rapid"), (99, "ultrarapid")),
        "undetectable": ["*4–*8 rare no-function alleles", "promoter rearrangements"],
        "chipLimitations": "What this array cannot detect: rare CYP2C19 no-function alleles (*4–*8) — a 'normal' call is a lower-bound estimate from the three common sites.",
        "drugs": [
            drug("Clopidogrel", "Plavix", "Cardiology & Clotting", "CYP2C19", "Level 1A",
                 ["rs4244285", "rs4986893", "rs12248560"],
                 {"poor": P("CPIC Level 1A: Significantly diminished antiplatelet response and increased risk of major adverse cardiovascular events (stent thrombosis) due to impaired bioactivation.",
                            "CPIC recommends alternative antiplatelet therapy such as Prasugrel or Ticagrelor in acute coronary syndromes / PCI.", "caution"),
                  "intermediate": P("CPIC Level 1A: Significantly diminished antiplatelet response and increased risk of major adverse cardiovascular events (stent thrombosis) due to impaired bioactivation.",
                                    "CPIC recommends alternative antiplatelet therapy such as Prasugrel or Ticagrelor in acute coronary syndromes / PCI.", "caution"),
                  "rapid": P("CPIC Level 1A: Normal to enhanced bioactivation of clopidogrel.", "Standard recommended dosing.", "typical"),
                  "ultrarapid": P("CPIC Level 1A: Normal to enhanced bioactivation of clopidogrel.", "Standard recommended dosing.", "typical"),
                  "default": P("CPIC Level 1A: Expected normal active metabolite generation.", "Standard recommended dosing.", "typical")}),
            drug("Escitalopram & Citalopram", "Lexapro, Celexa", "Psychiatry & Mood", "CYP2C19", "Level 1A",
                 ["rs4244285", "rs12248560"],
                 {"poor": P("CPIC Level 1A: Substantially reduced clearance and elevated plasma concentrations, increasing risk of QT prolongation and side effects.",
                            "CPIC recommends a lower starting point or an alternative antidepressant — a prescriber decision.", "caution"),
                  "rapid": P("CPIC Level 1A: Rapid drug clearance predisposing to therapeutic failure at standard doses.",
                             "Consider alternative antidepressant not predominantly metabolized by CYP2C19.", "notable"),
                  "ultrarapid": P("CPIC Level 1A: Rapid drug clearance predisposing to therapeutic failure at standard doses.",
                                  "Consider alternative antidepressant not predominantly metabolized by CYP2C19.", "notable"),
                  "intermediate": P("CPIC Level 1A: Moderately slowed clearance.", "Standard starting point with clinical monitoring.", "typical"),
                  "default": P("CPIC Level 1A: Standard clearance.", "Standard dosing.", "typical")}),
            drug("Omeprazole & Pantoprazole", "Prilosec, Protonix", "Gastroenterology & PPIs", "CYP2C19", "Level 1A",
                 ["rs4244285", "rs12248560"],
                 {"rapid": P("CPIC Level 1A: Rapid clearance lowers PPI systemic exposure, predisposing to persistent acid reflux or H. pylori treatment failure.",
                             "CPIC describes higher-exposure strategies or switching to rabeprazole — prescriber's call.", "notable"),
                  "ultrarapid": P("CPIC Level 1A: Rapid clearance lowers PPI systemic exposure, predisposing to persistent acid reflux or H. pylori treatment failure.",
                                  "CPIC describes higher-exposure strategies or switching to rabeprazole — prescriber's call.", "notable"),
                  "poor": P("CPIC Level 1A: Slower clearance produces higher acid suppression and greater healing rates.", "Standard or reduced exposure — prescriber's call.", "typical"),
                  "default": P("CPIC Level 1A: Normal clearance.", "Standard dosing.", "typical")}),
        ],
    },
    {
        "gene": "CYP2C9",
        "alleles": [
            allele("*2", "rs1799853", "C", "T", 0.5),
            allele("*3", "rs1057910", "A", "C", 0.0),
            allele("*5", "rs28371686", "C", "G", 0.5),
            allele("*8", "rs7900194", "G", "A", 0.5),
        ],
        "wildActivity": 1.0,
        "phenotypeBands": bands((0.5, "poor"), (1.5, "intermediate"), (99, "normal")),
        "undetectable": ["*6 frameshift (unreliable on arrays)", "*11/*13 rare alleles", "promoter variants"],
        "chipLimitations": "What this array cannot detect: CYP2C9*6 and other rare alleles — African-ancestry dose sensitivity can be under-called; clinical genotyping panels cover more.",
        "drugs": [
            drug("Warfarin", "Coumadin, Jantoven", "Cardiology & Clotting", "CYP2C9 / VKORC1", "Level 1A",
                 ["rs1799853", "rs1057910", "rs9923231"],
                 {"impaired": P("CPIC Level 1A: High sensitivity to warfarin with decreased clearance and increased initial bleeding risk.",
                                "CPIC pharmacogenetic algorithms describe substantially lower typical requirements with close INR titration — always the prescriber's algorithm, never self-managed.", "caution"),
                  "default": P("CPIC Level 1A: Typical warfarin metabolism and receptor sensitivity.", "Standard clinical initiation and INR monitoring.", "typical")},
                 combineGenes=["CYP2C9", "VKORC1"]),
            drug("Celecoxib & NSAIDs", "Celebrex, Advil", "Pain & Neurology", "CYP2C9", "Level 1B",
                 ["rs1799853", "rs1057910"],
                 {"poor": P("CPIC Level 1B: Reduced clearance and prolonged drug exposure, increasing gastrointestinal and cardiovascular risk.",
                            "CPIC describes lower-exposure strategies for celecoxib — prescriber's decision.", "caution"),
                  "intermediate": P("CPIC Level 1B: Reduced clearance and prolonged drug exposure, increasing gastrointestinal and cardiovascular risk.",
                                    "CPIC describes lower-exposure strategies for celecoxib — prescriber's decision.", "caution"),
                  "default": P("Standard clearance.", "Standard dosing.", "typical")}),
        ],
    },
    {
        "gene": "VKORC1",
        "alleles": [
            allele("-1639A", "rs9923231", "G", "A", 0.0),
        ],
        "wildActivity": 1.0,
        "phenotypeBands": bands((0.5, "poor"), (1.5, "intermediate"), (99, "normal")),
        "undetectable": ["rare coding warfarin-resistance mutations (e.g. D36Y)"],
        "chipLimitations": "What this array cannot detect: rare VKORC1 coding mutations that cause warfarin RESISTANCE — this call covers the common promoter sensitivity axis only.",
        "drugs": [],
    },
    {
        "gene": "CYP2D6",
        "alleles": [
            allele("*4", "rs3892097", "G", "A", 0.0),
            allele("*10", "rs1065852", "C", "T", 0.25),
            allele("*41", "rs28371725", "C", "T", 0.5),
        ],
        "wildActivity": 1.0,
        "phenotypeBands": bands((0.125, "poor"), (1.0, "intermediate"), (2.25, "normal"), (99, "ultrarapid")),
        "undetectable": ["*5 whole-gene deletion", "gene duplications (UM status)", "*3/*6 indel nulls (unreliable on arrays)"],
        "chipLimitations": "What this array cannot detect: CYP2D6 *5 deletion and duplications — PM/UM calls are lower-bound estimates.",
        "drugs": [
            drug("Codeine & Tramadol", "Tylenol #3, Ultram", "Pain & Neurology", "CYP2D6", "Level 1A",
                 ["rs3892097", "rs1065852"],
                 {"poor": P("CPIC Level 1A: Complete inability to bioactivate codeine or tramadol into morphine/M1. Lack of analgesia.",
                            "CPIC recommends avoiding codeine and tramadol. Use non-opioid analgesics or direct opioids (morphine, hydromorphone) not dependent on CYP2D6.", "caution"),
                  "ultrarapid": P("CPIC Level 1A: Extremely rapid conversion to morphine, leading to potentially fatal respiratory depression.",
                                  "CPIC Black Box Warning: Codeine and tramadol are contraindicated.", "caution"),
                  "intermediate": P("CPIC Level 1A: Reduced conversion to active analgesic metabolites.", "Monitor for inadequate pain control.", "notable"),
                  "default": P("CPIC Level 1A: Expected normal opioid conversion.", "Standard recommended dosing.", "typical")}),
            drug("Tamoxifen", "Nolvadex", "Oncology & Chemotherapy", "CYP2D6", "Level 1A",
                 ["rs3892097", "rs1065852"],
                 {"poor": P("CPIC Level 1A: Significantly reduced conversion to active endoxifen, increasing breast cancer recurrence risk.",
                            "CPIC recommends alternative endocrine therapy (Aromatase Inhibitors) in postmenopausal women.", "caution"),
                  "intermediate": P("CPIC Level 1A: Significantly reduced conversion to active endoxifen, increasing breast cancer recurrence risk.",
                                    "CPIC recommends alternative endocrine therapy (Aromatase Inhibitors) in postmenopausal women.", "caution"),
                  "default": P("Standard bioactivation.", "Standard dosing.", "typical")}),
            drug("Metoprolol", "Lopressor, Toprol-XL", "Cardiology & Clotting", "CYP2D6", "Level 1B",
                 ["rs3892097", "rs1065852"],
                 {"poor": P("CPIC Level 1B: Slow clearance producing 3–5x higher plasma drug levels and higher risk of bradycardia and hypotension.",
                            "Prescribers may consider alternative beta-blockers not metabolized by CYP2D6 (Atenolol, Bisoprolol).", "caution"),
                  "intermediate": P("CPIC Level 1B: Slow clearance producing 3–5x higher plasma drug levels and higher risk of bradycardia and hypotension.",
                                    "Prescribers may consider alternative beta-blockers not metabolized by CYP2D6 (Atenolol, Bisoprolol).", "caution"),
                  "default": P("Standard clearance.", "Standard dosing.", "typical")}),
        ],
    },
    {
        "gene": "SLCO1B1",
        "alleles": [
            allele("*5", "rs4149056", "T", "C", 0.0),
        ],
        "wildActivity": 1.0,
        "phenotypeBands": bands((0.5, "poor"), (1.5, "intermediate"), (99, "normal")),
        "undetectable": ["*15/*17 haplotype phasing", "rare decreased-function alleles"],
        "chipLimitations": "What this array cannot detect: full SLCO1B1 haplotypes — the *5 site alone distinguishes normal/decreased/poor OATP1B1 function classes.",
        "drugs": [
            drug("Simvastatin & Atorvastatin", "Zocor, Lipitor", "Statins & Lipids", "SLCO1B1", "Level 1A",
                 ["rs4149056"],
                 {"poor": P("CPIC Level 1A: Markedly reduced hepatic statin uptake leading to high systemic plasma exposure (~15–20x increased risk of statin-induced myopathy).",
                            "CPIC recommends avoiding high simvastatin exposure. Consider alternative statins with low OATP1B1 dependence (Pravastatin, Rosuvastatin).", "caution"),
                  "intermediate": P("CPIC Level 1A: Moderately reduced statin clearance with ~4–5x higher myopathy risk on high-dose simvastatin.",
                                    "CPIC recommends lower-exposure simvastatin strategies or selecting alternative statins — prescriber's decision.", "caution"),
                  "default": P("CPIC Level 1A: Normal hepatic transporter uptake and typical baseline myopathy risk.", "Standard clinical statin dosing.", "typical")}),
        ],
    },
    {
        "gene": "DPYD",
        "alleles": [
            allele("*2A", "rs3918290", "C", "T", 0.0),
            allele("*13", "rs55886062", "A", "C", 0.0),
            allele("D949V", "rs67376798", "T", "A", 0.5),
            allele("HapB3", "rs75017182", "G", "C", 0.5),
        ],
        "wildActivity": 1.0,
        "phenotypeBands": bands((0.5, "poor"), (1.5, "intermediate"), (99, "normal")),
        "undetectable": ["rare deleterious DPYD variants outside the four tested", "phasing of multi-variant carriers"],
        "chipLimitations": "What this array cannot detect: rare DPYD variants beyond the four CPIC-tier sites — clinical DPYD panels are broader before fluoropyrimidine therapy.",
        "drugs": [
            drug("5-Fluorouracil & Capecitabine", "Adrucil, Xeloda", "Oncology & Chemotherapy", "DPYD", "Level 1A",
                 ["rs3918290", "rs55886062", "rs67376798", "rs75017182"],
                 {"poor": P("CPIC Level 1A: High risk of life-threatening toxicity (severe myelosuppression, neurotoxicity, mucositis).",
                            "CPIC recommends alternative chemotherapy or drastically adjusted therapy with PK monitoring — strictly an oncology decision.", "caution"),
                  "intermediate": P("CPIC Level 1A: High risk of life-threatening toxicity (severe myelosuppression, neurotoxicity, mucositis).",
                                    "CPIC recommends substantially adjusted fluoropyrimidine therapy with monitoring — strictly an oncology decision.", "caution"),
                  "default": P("Standard clearance.", "Standard dosing.", "typical")}),
        ],
    },
    {
        "gene": "TPMT",
        "alleles": [
            allele("*3B", "rs1800460", "C", "T", 0.0),
            allele("*3C", "rs1142345", "T", "C", 0.0),
        ],
        "wildActivity": 1.0,
        "phenotypeBands": bands((0.5, "poor"), (1.5, "intermediate"), (99, "normal")),
        "undetectable": ["*2 (rs1800462) on some chip versions", "rare TPMT alleles"],
        "chipLimitations": "What this array cannot detect: TPMT*2 and rare alleles — combine with NUDT15 for the full thiopurine picture; enzymatic TPMT testing also exists.",
        "drugs": [
            drug("Azathioprine & 6-Mercaptopurine", "Imuran, Purinethol", "Immunology & Transplants", "TPMT", "Level 1A",
                 ["rs1800460", "rs1142345"],
                 {"poor": P("CPIC Level 1A: Severe bone marrow suppression and pancytopenia risk.",
                            "CPIC recommends drastically adjusted thiopurine therapy or alternatives, with CBC monitoring — a specialist decision made before the first dose.", "caution"),
                  "intermediate": P("CPIC Level 1A: Severe bone marrow suppression and pancytopenia risk.",
                                    "CPIC recommends adjusted thiopurine therapy with CBC monitoring — a specialist decision.", "caution"),
                  "default": P("Standard clearance.", "Standard dosing.", "typical")}),
        ],
    },
    {
        "gene": "NUDT15",
        "alleles": [
            allele("*3 (R139C)", "rs116855232", "C", "T", 0.0),
        ],
        "wildActivity": 1.0,
        "phenotypeBands": bands((0.5, "poor"), (1.5, "intermediate"), (99, "normal")),
        "undetectable": ["NUDT15 *3 subtypes and rare frameshift alleles"],
        "chipLimitations": "What this array cannot detect: rare NUDT15 alleles beyond R139C — East-Asian and Hispanic ancestry carry most of the burden at this one site, but not all of it.",
        "drugs": [
            drug("Thiopurines (NUDT15 axis)", "Imuran, Purinethol, Tabloid", "Immunology & Transplants", "NUDT15", "Level 1A",
                 ["rs116855232"],
                 {"poor": P("CPIC Level 1A: Severe thiopurine-induced leukopenia at standard therapy — NUDT15 poor metabolizers accumulate active metabolites.",
                            "CPIC recommends drastically adjusted therapy or alternatives — flagged to the specialist BEFORE the first dose.", "caution"),
                  "intermediate": P("CPIC Level 1A: Elevated leukopenia risk at standard thiopurine therapy (the dominant pharmacogenomic axis in East-Asian ancestry).",
                                    "CPIC recommends adjusted starting therapy with CBC monitoring — a specialist decision.", "caution"),
                  "default": P("Standard NUDT15 inactivation of active metabolites.", "Standard dosing.", "typical")}),
        ],
    },
    {
        "gene": "UGT1A1",
        "alleles": [
            allele("*28 tag", "rs887829", "C", "T", 0.5),
            allele("*6", "rs4148323", "G", "A", 0.5),
        ],
        "wildActivity": 1.0,
        "phenotypeBands": bands((1.0, "poor"), (1.5, "intermediate"), (99, "normal")),
        "undetectable": ["true *28 TA-repeat length (tagged, not measured)", "*36/*37 repeat variants"],
        "chipLimitations": "What this array cannot detect: the actual UGT1A1 TA-repeat — rs887829 tags it well in Europeans, less well elsewhere; *6 covers the East-Asian axis.",
        "drugs": [
            drug("Irinotecan", "Camptosar", "Oncology & Chemotherapy", "UGT1A1", "Level 1A",
                 ["rs887829", "rs4148323"],
                 {"poor": P("CPIC Level 1A: Reduced glucuronidation of toxic active metabolite SN-38 leading to severe neutropenia and diarrhea.",
                            "CPIC recommends an adjusted starting approach — an oncology decision.", "caution"),
                  "default": P("Standard clearance.", "Standard dosing.", "typical")}),
        ],
    },
    {
        "gene": "HLA-B*5701",
        "alleles": [
            allele("HCP5 tag", "rs2395029", "T", "G", 0.0),
        ],
        "wildActivity": 1.0,
        "phenotypeBands": bands((1.5, "poor"), (99, "normal")),
        "undetectable": ["actual HLA-B*57:01 typing — this is a linkage tag, not the allele"],
        "chipLimitations": "What this array cannot detect: true HLA-B*57:01 status — the HCP5 tag has rare false negatives/positives; clinical HLA typing confirms before abacavir.",
        "drugs": [
            drug("Abacavir", "Ziagen, Epzicom", "Immunology & Transplants", "HLA-B*5701", "Level 1A",
                 ["rs2395029"],
                 {"poor": P("CPIC Level 1A: Positive for HLA-B*5701. Severe, life-threatening multi-organ hypersensitivity reaction risk.",
                            "CPIC Black Box Warning: Abacavir is strictly contraindicated.", "caution"),
                  "default": P("Negative for HLA-B*5701 tag.", "Standard selection.", "typical")}),
        ],
    },
    {
        "gene": "CYP3A5",
        "alleles": [
            allele("*1 (expressor)", "rs776746", "G", "A", 1.0),
        ],
        "subtractAlleles": [
            allele("*6", "rs10264272", "C", "T", 0.0),
            allele("*7", "rs41303343", "T", "A", 0.0),
        ],
        "wildActivity": 0.0,
        "phenotypeBands": bands((0.5, "normal"), (1.5, "rapid"), (99, "ultrarapid")),
        "undetectable": ["*1 vs *6/*7 phasing (unphased array inference)", "rare expressor alleles"],
        "chipLimitations": "What this array cannot detect: haplotype phase — an apparent expressor allele could sit on a *6/*7-inactivated copy; clinical genotyping resolves it for transplant dosing.",
        "drugs": [
            drug("Tacrolimus", "Prograf", "Immunology & Transplants", "CYP3A5", "Level 1A",
                 ["rs776746"],
                 {"ultrarapid": P("CPIC Level 1A: Rapid drug clearance requiring significantly higher exposure to reach immunosuppressive target levels.",
                                  "CPIC describes higher-exposure initiation with therapeutic drug monitoring — entirely the transplant team's algorithm.", "caution"),
                  "rapid": P("CPIC Level 1A: Rapid drug clearance requiring significantly higher exposure to reach immunosuppressive target levels.",
                             "CPIC describes higher-exposure initiation with therapeutic drug monitoring — entirely the transplant team's algorithm.", "caution"),
                  "default": P("Standard clearance (Non-expressor).", "Standard dosing.", "typical")}),
        ],
    },
    {
        "gene": "ABCG2",
        "alleles": [
            allele("Q141K", "rs2231142", "G", "T", 0.5),
        ],
        "wildActivity": 1.0,
        "phenotypeBands": bands((1.0, "poor"), (1.5, "intermediate"), (99, "normal")),
        "undetectable": ["rare ABCG2 null alleles", "V12M modifier context"],
        "chipLimitations": "What this array cannot detect: rare ABCG2 loss alleles — Q141K carries most of the common signal for rosuvastatin exposure and urate.",
        "drugs": [
            drug("Rosuvastatin", "Crestor", "Statins & Lipids", "ABCG2", "Level 1A",
                 ["rs2231142"],
                 {"poor": P("CPIC: Substantially reduced BCRP efflux roughly doubles rosuvastatin systemic exposure; myopathy risk rises with exposure.",
                            "CPIC describes exposure-aware prescribing or alternative statins — the prescriber weighs it with SLCO1B1 status.", "caution"),
                  "intermediate": P("CPIC: Reduced BCRP efflux increases rosuvastatin exposure ~40–70%.",
                                    "Worth mentioning to the prescriber alongside SLCO1B1 status if statin therapy is ever discussed.", "notable"),
                  "default": P("Typical BCRP efflux and rosuvastatin exposure.", "Standard selection.", "typical")}),
        ],
    },
    {
        "gene": "CYP4F2",
        "alleles": [
            allele("V433M (*3)", "rs2108622", "C", "T", 0.0),
        ],
        "wildActivity": 1.0,
        "phenotypeBands": bands((0.5, "poor"), (1.5, "intermediate"), (99, "normal")),
        "undetectable": ["haplotype context of V433M"],
        "chipLimitations": "What this array cannot detect: CYP4F2 haplotype context — V433M alone captures the vitamin-K-oxidase warfarin-dose signal used by CPIC algorithms.",
        "drugs": [
            drug("Warfarin (CYP4F2 dose-requirement axis)", "Coumadin, Jantoven", "Cardiology & Clotting", "CYP4F2", "Level A (algorithm term)",
                 ["rs2108622"],
                 {"poor": P("Reduced CYP4F2 activity leaves more vitamin K available: average warfarin requirement runs HIGHER for 433M homozygotes in dosing algorithms.",
                            "One term in the CPIC warfarin algorithm alongside VKORC1 and CYP2C9 — informational for the prescriber only.", "notable"),
                  "intermediate": P("One 433M allele modestly raises the average warfarin requirement in dosing algorithms.",
                                    "One term in the CPIC warfarin algorithm — informational for the prescriber only.", "notable"),
                  "default": P("Typical CYP4F2 vitamin-K oxidation; no algorithm adjustment from this gene.", "Standard algorithm term.", "typical")}),
        ],
    },
    {
        "gene": "CYP3A4",
        "alleles": [
            allele("*22", "rs35599367", "C", "T", 0.5),
        ],
        "wildActivity": 1.0,
        "phenotypeBands": bands((0.75, "poor"), (1.75, "intermediate"), (99, "normal")),
        "undetectable": ["CYP3A4 rare alleles and expression variability (largely non-genetic)"],
        "chipLimitations": "What this array cannot detect: most CYP3A4 variability, which is non-genetic (diet, drug interactions) — *22 is the one solid inherited expression signal.",
        "drugs": [
            drug("Statins & Tacrolimus (CYP3A4 exposure note)", "Lipitor, Zocor, Prograf", "Statins & Lipids", "CYP3A4", "Level B",
                 ["rs35599367"],
                 {"poor": P("Substantially reduced CYP3A4 expression raises exposure to sensitive substrates (simvastatin, atorvastatin, tacrolimus, quetiapine).",
                            "Worth mentioning to any prescriber of CYP3A4-sensitive drugs; grapefruit interactions also hit harder.", "caution"),
                  "intermediate": P("Reduced CYP3A4 expression (~40% lower) raises exposure to sensitive substrates modestly.",
                                    "A useful note for prescribers of statins/tacrolimus/quetiapine — never a self-adjustment.", "notable"),
                  "default": P("Typical CYP3A4 expression.", "Standard exposure expected.", "typical")}),
        ],
    },
]


def lint_pgx(genes):
    errors = []
    seen = set()
    for g in genes:
        name = g.get("gene", "?")
        if name in seen:
            errors.append(f"pgx {name}: duplicate gene")
        seen.add(name)
        if not g.get("undetectable"):
            errors.append(f"pgx {name}: undetectable list empty — the chip-limitation disclosure cannot be omitted")
        if not g.get("chipLimitations"):
            errors.append(f"pgx {name}: missing chipLimitations disclosure")
        if not g.get("alleles"):
            errors.append(f"pgx {name}: no alleles")
        if g.get("wildActivity") != 0.0:
            errors.append(f"pgx {name}: wildActivity must be neutralized")
        if g.get("phenotypeBands"):
            errors.append(f"pgx {name}: phenotype bands must not ship")
        for allele_def in g.get("alleles", []) + g.get("subtractAlleles", []):
            if allele_def.get("activity") != 0.0:
                errors.append(f"pgx {name}/{allele_def.get('name')}: activity score must be neutralized")
        for d in g.get("drugs", []):
            per = d.get("perPhenotype", {})
            if "default" not in per:
                errors.append(f"pgx {name}/{d.get('name')}: perPhenotype missing 'default'")
            lowered = " ".join(
                (v.get("guideline", "") + " " + v.get("alternatives", "")).lower()
                for v in per.values()
            )
            for banned in ("increase dose", "decrease dose", "take mg", "self-adjust your"):
                if banned in lowered:
                    errors.append(f"pgx {name}/{d.get('name')}: banned dosing phrase '{banned}'")
    return errors


for _gene in PGX_GENES:
    _gene["wildActivity"] = 0.0
