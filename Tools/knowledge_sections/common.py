"""Shared marker-construction helpers for the DNA Engine knowledge catalog.

Every marker carries the full honesty schema:
  citations       — list of {"pmid": ..., "note": ...}. "pmid" is a numeric PubMed ID
                    where hand-verified; otherwise a named curated registry tag
                    ("PharmGKB", "GWAS Catalog", "ClinVar", "CPIC") with an
                    author/year pointer in the note. Never invented digits.
  tier            — 'well-replicated' | 'replicated' | 'tendency'
  effect          — deliberately withheld from the shipped single-marker record
  transferability — 'euro-biased' | 'multi-ancestry' | 'east-asian-derived' | 'african-derived'
  chips           — consumer arrays the rsid is expected on (curated expectation,
                    not a guarantee; the app handles absence gracefully)

Legacy section modules still pass their historical interpretation prose into
`G` and `M`, but these two constructors are the release boundary: they discard
genotype labels, impacts, outcomes, action text, mechanism claims, and effect
sizes. The shipped catalog retains locus identity, alleles, coverage metadata,
evidence tier, transferability, and citations only.

The generator lint (generate_knowledge.py main()) refuses to emit any marker
missing citations, tier, or chips, and warns on palindromic A/T & C/G allele
pairs unless the entry is marked reviewed=True.
"""
from __future__ import annotations

CHIPS_ALL = ["ancestry_v2", "23andme_v5", "myheritage"]

MARKERS: list = []

NEUTRAL_MARKER_MECHANISM = (
    "Published marker context only. DNA Engine does not translate this consumer-array genotype "
    "into enzyme activity, biological function, phenotype, diagnosis, risk, or a personal outcome."
)
NEUTRAL_GENOTYPE_LABEL = "Research locus observed"
NEUTRAL_GENOTYPE_SUMMARY = (
    "Raw genotype recorded at this catalog locus. No genotype-to-outcome label or quantitative "
    "biological effect is inferred."
)
NEUTRAL_GENOTYPE_DETAIL = (
    "Identifiers, coverage, evidence tier, transferability, and citations are provided for "
    "independent research; the genotype is not a personalized interpretation."
)


def gk(x: str, y: str) -> str:
    return "".join(sorted([x, y]))


def C(pmid, note):
    """One citation entry. pmid: numeric PubMed ID (verified) or registry tag."""
    return {"pmid": str(pmid), "note": note}


def G(label, impact, summary, detail, **actions):
    """Build a non-interpretive genotype-key placeholder.

    Parameters remain for source compatibility while the catalog migrates, but
    no legacy genotype-specific assertion crosses this release boundary.
    """
    return {
        "label": NEUTRAL_GENOTYPE_LABEL,
        "impact": "typical",
        "summary": NEUTRAL_GENOTYPE_SUMMARY,
        "detail": NEUTRAL_GENOTYPE_DETAIL,
        "actions": {},
    }


def M(rsid, gene, title, chrom, pos, cats, evidence, a, b, mechanism, g0, g1, g2, notes="",
      citations=None, tier=None, effect=None, transferability=None, chips=None,
      position38=None, reviewed=False):
    cur = CURATION.get(rsid, {})
    m = {
        "rsid": rsid,
        "gene": gene,
        "title": title,
        "chromosome": str(chrom),
        "position": int(pos),
        "categories": cats,
        "mechanism": NEUTRAL_MARKER_MECHANISM,
        "evidence": evidence,
        "alleleA": a,
        "alleleB": b,
        "genotypes": {gk(a, a): g0, gk(a, b): g1, gk(b, b): g2},
        "notes": "",
        "citations": citations if citations is not None else cur.get("citations"),
        "tier": tier if tier is not None else cur.get("tier"),
        "effect": None,
        "transferability": transferability if transferability is not None
                           else cur.get("transferability", "euro-biased"),
        "chips": chips if chips is not None else cur.get("chips", CHIPS_ALL),
    }
    if position38 is not None:
        m["position38"] = int(position38)
    elif rsid in POSITION38:
        m["position38"] = int(POSITION38[rsid])
    m["_reviewed"] = bool(reviewed) or bool(cur.get("reviewed", False))
    return m


def add(*args, **kwargs):
    MARKERS.append(M(*args, **kwargs))


# ------------------------------------------------------------------------------
# GRCh38 positions for build-inference sentinels only.
# Hand-verified for a small set of landmark loci; the QC build check scores a
# file's positions against b37 (catalog `position`) vs b38 (this table) and only
# uses markers present here. Do NOT bulk-fill without a real liftover.
# ------------------------------------------------------------------------------
POSITION38 = {
    "rs1801133": 11796321,    # MTHFR chr1 (b37 11856378)
    "rs429358": 44908684,     # APOE chr19 (b37 45411941)
    "rs7412": 44908822,       # APOE chr19 (b37 45412079)
    "rs4988235": 135851076,   # MCM6 chr2 (b37 136608646)
    "rs671": 111803962,       # ALDH2 chr12 (b37 112241766)
    "rs6025": 169549811,      # F5 chr1 (b37 169519049)
    "rs12913832": 28120472,   # HERC2 chr15 (b37 28365618)
    "rs1815739": 66560624,    # ACTN3 chr11 (b37 66328095)
    "rs1800562": 26092913,    # HFE chr6 (b37 26093141)
    "rs9939609": 53786615,    # FTO chr16 (b37 53820527)
    "rs7903146": 112998590,   # TCF7L2 chr10 (b37 114758349)
    "rs4680": 19963748,       # COMT chr22 (b37 19951271)
}

# ------------------------------------------------------------------------------
# CURATION: honesty metadata for catalog markers keyed by rsid.
# Explicit kwargs on add() override these. Kept as one table so every marker's
# evidence posture is auditable in a single place.
# ------------------------------------------------------------------------------
PGKB = "PharmGKB"
GWAS = "GWAS Catalog"
CLIN = "ClinVar"
CPIC = "CPIC"

CURATION = {
    # --- Methylation / 1-carbon ---
    "rs1801133": dict(tier="well-replicated", transferability="multi-ancestry",
                      effect="TT raises fasting homocysteine ~2-3 µmol/L when folate is low — modest, diet-dependent",
                      citations=[C(7647779, "Frosst 1995, Nat Genet — original C677T thermolability report"),
                                 C(GWAS, "Replicated across homocysteine GWAS in European and East Asian cohorts")]),
    "rs1801131": dict(tier="replicated", effect="CC mildly lowers enzyme regulation — small; additive with C677T only",
                      citations=[C(PGKB, "MTHFR A1298C haplotype annotations; effect modest vs C677T")]),
    "rs1801394": dict(tier="replicated", effect="GG modestly reduces MTR reactivation efficiency — small",
                      citations=[C(PGKB, "MTRR A66G (Ile22Met) homocysteine modifier annotations")]),
    "rs1805087": dict(tier="tendency", effect="GG alters MTR kinetics — small, B12-dependent",
                      citations=[C(GWAS, "MTR A2756G homocysteine association, mixed replication")]),
    "rs234706": dict(tier="tendency", effect="TT accelerates transsulfuration — small",
                     citations=[C(GWAS, "CBS C699T homocysteine studies, direction consistent, small effect")]),
    "rs7946": dict(tier="replicated", effect="TT blunts endogenous choline synthesis — moderate on low-choline diets",
                   citations=[C(16816108, "da Costa/Zeisel choline-depletion studies; PEMT -744G>C"),
                              C(GWAS, "Replicated in NAFLD/choline requirement cohorts")]),
    "rs3737597": dict(tier="tendency", effect="Small shift in betaine remethylation flux",
                      citations=[C(GWAS, "BHMT Arg239Gln homocysteine modifier, limited effect size")]),
    "rs1979277": dict(tier="tendency", effect="Small shift in serine/folate shuttling",
                      citations=[C(GWAS, "SHMT1 C1420T one-carbon flux studies")]),
    "rs1801198": dict(reviewed=True, tier="replicated", effect="GG modestly lowers holo-transcobalamin — small",
                      citations=[C(GWAS, "TCN2 C776G B12 transport association, replicated")]),
    "rs1074810": dict(tier="tendency", effect="Minor promoter effect on transcobalamin",
                      citations=[C(GWAS, "TCN2 promoter variant B12 studies")]),
    "rs25531": dict(tier="tendency", effect="Modifies 5-HTTLPR expression readout — small",
                    citations=[C(GWAS, "SLC6A4 rs25531 A/G expression modifier literature")]),

    # --- Cardio / lipids / clotting ---
    "rs429358": dict(tier="well-replicated", transferability="multi-ancestry",
                     effect="ε4: AD OR ~3 (het) to ~12 (hom) in Europeans; weaker in African-ancestry cohorts — large for a common variant",
                     citations=[C(8346443, "Corder 1993, Science — APOE ε4 dose effect on Alzheimer risk"),
                                C(GWAS, "Consistent lipid/CAD associations across ancestries with attenuated AD effect in African cohorts")]),
    "rs7412": dict(tier="well-replicated", transferability="multi-ancestry",
                   effect="ε2 lowers LDL-C ~10-15 mg/dL — moderate; ε2/ε2 rare remnant-lipemia susceptibility",
                   citations=[C(8346443, "Corder 1993, Science — APOE isoform definitions"),
                              C(GWAS, "APOE ε2 lipid associations, multi-ancestry")]),
    "rs10455872": dict(tier="well-replicated", effect="G: Lp(a) +~30 mg/dL, CAD OR ~1.5-1.7 — one of the strongest common CAD SNPs",
                       citations=[C(20032323, "Clarke 2009, NEJM — LPA variants, Lp(a), and CAD"),
                                  C(GWAS, "Replicated across CAD consortia; Lp(a) distributions differ by ancestry")]),
    "rs3798220": dict(tier="well-replicated", effect="C: Lp(a) elevation, CAD OR ~1.5 — strong",
                      citations=[C(20032323, "Clarke 2009, NEJM — LPA rs3798220"),]),
    "rs11591147": dict(tier="well-replicated", effect="T (R46L): LDL-C -~15-20 mg/dL, CAD OR ~0.7 — protective, moderate-large",
                       citations=[C(16554528, "Cohen 2006, NEJM — PCSK9 loss-of-function and CHD reduction")]),
    "rs708272": dict(tier="replicated", effect="B1/B2 shifts HDL-C a few mg/dL — small",
                     citations=[C(GWAS, "CETP TaqIB HDL meta-analyses")]),
    "rs1333049": dict(reviewed=True, tier="well-replicated", effect="C: CAD OR ~1.2-1.3 per allele — modest",
                      citations=[C(19474294, "CARDIoGRAM meta-analysis, n≈86k"),
                                 C(GWAS, "9p21.3 CAD locus, replicated across ancestries with weaker effect in African cohorts")]),
    "rs10757274": dict(tier="well-replicated", effect="G: CAD OR ~1.2 per allele — modest",
                       citations=[C(19474294, "CARDIoGRAM meta-analysis"), C(GWAS, "9p21.3 CAD region")]),
    "rs6025": dict(tier="well-replicated", effect="Factor V Leiden het: venous thrombosis OR ~4-7 — large for VTE, absolute risk still low",
                   citations=[C(8164741, "Bertina 1994, Nature — APC resistance / Factor V Leiden"),
                              C(CLIN, "Pathogenic for hereditary thrombophilia; rare outside European ancestry")]),
    "rs1799963": dict(tier="well-replicated", effect="Prothrombin G20210A het: VTE OR ~2-3 — moderate",
                      citations=[C(8916933, "Poort 1996, Blood — F2 G20210A and venous thrombosis")]),
    "rs1799983": dict(tier="replicated", effect="T (Asp298): small endothelial NO effect",
                      citations=[C(GWAS, "NOS3 E298D vascular meta-analyses, small effect")]),
    "rs699": dict(tier="replicated", effect="C (M235T-linked): small blood-pressure shift",
                  citations=[C(GWAS, "AGT M235T hypertension meta-analyses")]),
    "rs5918": dict(tier="replicated", effect="PlA2: small platelet reactivity shift",
                   citations=[C(GWAS, "ITGB3 PlA1/A2 platelet studies, mixed clinical endpoints")]),
    "rs662": dict(tier="replicated", effect="Q192R shifts paraoxonase substrate kinetics — small clinical effect",
                  citations=[C(GWAS, "PON1 Q192R CAD meta-analyses, small effect")]),
    "rs328": dict(reviewed=True, tier="well-replicated", effect="S447X: triglycerides -~10-15%, protective — moderate",
                  citations=[C(GWAS, "LPL S447X lipid meta-analyses, replicated")]),
    "rs5128": dict(reviewed=True, tier="replicated", effect="G: triglyceride elevation tendency — small",
                   citations=[C(GWAS, "APOC3 SstI triglyceride studies")]),
    "rs1800629": dict(tier="replicated", effect="A (-308): small TNF-α expression shift",
                      citations=[C(GWAS, "TNF -308G>A inflammation meta-analyses"),], reviewed=True),
    "rs1800795": dict(tier="replicated", effect="G (-174): small IL-6 expression shift",
                      citations=[C(GWAS, "IL6 -174G>C meta-analyses; effect small and context-dependent")], reviewed=True),
    "rs1800788": dict(tier="tendency", effect="Small fibrinogen level shift",
                      citations=[C(GWAS, "FGB promoter fibrinogen studies")]),
    "rs5186": dict(tier="replicated", effect="C: small AT1R signaling shift",
                   citations=[C(GWAS, "AGTR1 A1166C hypertension meta-analyses")]),

    # --- PGx ---
    "rs4244285": dict(tier="well-replicated", transferability="multi-ancestry",
                      effect="*2 no-function allele; het reduces clopidogrel activation — clinically actionable (CPIC A)",
                      citations=[C(CPIC, "CPIC clopidogrel-CYP2C19 guideline (Scott 2013 update)"),
                                 C(PGKB, "CYP2C19*2 rs4244285 Level 1A")]),
    "rs4986893": dict(tier="well-replicated", transferability="east-asian-derived",
                      effect="*3 no-function allele — mainly East Asian populations",
                      citations=[C(CPIC, "CPIC CYP2C19 allele definitions"), C(PGKB, "CYP2C19*3 Level 1A")]),
    "rs12248560": dict(tier="well-replicated", transferability="multi-ancestry",
                       effect="*17 increased-function promoter allele — rapid/ultrarapid metabolism",
                       citations=[C(CPIC, "CPIC CYP2C19 guideline"), C(PGKB, "CYP2C19*17 Level 1A")]),
    "rs1799853": dict(tier="well-replicated", effect="*2 decreased-function; warfarin dose sensitivity — actionable (CPIC A)",
                      citations=[C(CPIC, "CPIC warfarin guideline (Johnson 2017)"), C(PGKB, "CYP2C9*2 Level 1A")]),
    "rs1057910": dict(tier="well-replicated", effect="*3 low-function; strong warfarin/NSAID exposure effect",
                      citations=[C(CPIC, "CPIC warfarin & NSAID guidelines"), C(PGKB, "CYP2C9*3 Level 1A")]),
    "rs9923231": dict(tier="well-replicated", transferability="multi-ancestry",
                      effect="-1639A halves VKORC1 expression; largest single warfarin-dose factor",
                      citations=[C(15930419, "Rieder 2005, NEJM — VKORC1 haplotypes and warfarin dose"),
                                 C(CPIC, "CPIC warfarin guideline")]),
    "rs3892097": dict(tier="well-replicated", effect="*4 splice-defect null allele — poor-metabolizer contributor",
                      citations=[C(CPIC, "CPIC CYP2D6 guidelines (codeine/tamoxifen)"), C(PGKB, "CYP2D6*4 Level 1A")]),
    "rs1065852": dict(tier="well-replicated", transferability="east-asian-derived",
                      effect="*10 reduced-function allele — common in East Asian populations",
                      citations=[C(CPIC, "CPIC CYP2D6 allele definitions"), C(PGKB, "CYP2D6*10")]),
    "rs4149056": dict(tier="well-replicated", transferability="multi-ancestry",
                      effect="C (*5): simvastatin myopathy OR ~4.5 het / ~17 hom — strong, actionable (CPIC A)",
                      citations=[C(18650507, "SEARCH Collaborative 2008, NEJM — SLCO1B1 and statin myopathy"),
                                 C(CPIC, "CPIC statin guideline 2022")]),
    "rs3918290": dict(tier="well-replicated", effect="DPYD*2A splice null — severe fluoropyrimidine toxicity risk (CPIC A)",
                      citations=[C(CPIC, "CPIC fluoropyrimidine-DPYD guideline"), C(CLIN, "Pathogenic; rare")]),
    "rs1800460": dict(tier="well-replicated", effect="TPMT*3B component — thiopurine myelosuppression risk (CPIC A)",
                      citations=[C(CPIC, "CPIC thiopurine guideline"), C(PGKB, "TPMT*3B Level 1A")]),
    "rs1142345": dict(tier="well-replicated", transferability="multi-ancestry",
                      effect="TPMT*3C component — thiopurine sensitivity (CPIC A)",
                      citations=[C(CPIC, "CPIC thiopurine guideline"), C(PGKB, "TPMT*3C Level 1A")]),
    "rs887829": dict(tier="well-replicated", transferability="multi-ancestry",
                     effect="T tags UGT1A1*28 — Gilbert-pattern bilirubin elevation; irinotecan caution",
                     citations=[C(CPIC, "CPIC atazanavir/irinotecan UGT1A1 guidance"), C(PGKB, "UGT1A1 rs887829 Level 1A")]),
    "rs2395029": dict(tier="well-replicated", effect="HCP5 tag for HLA-B*57:01 — abacavir hypersensitivity (CPIC A); tag, not the allele itself",
                      citations=[C(18684101, "Mallal 2008, NEJM — HLA-B*5701 screening for abacavir"),
                                 C(PGKB, "rs2395029 proxy annotations")]),
    "rs776746": dict(tier="well-replicated", transferability="multi-ancestry",
                     effect="*1 expressor vs *3 non-expressor; tacrolimus dose requirement — actionable (CPIC A); African-ancestry cohorts mostly expressors",
                     citations=[C(CPIC, "CPIC tacrolimus-CYP3A5 guideline"), C(PGKB, "CYP3A5*3 Level 1A")]),
    "rs762551": dict(tier="replicated", transferability="multi-ancestry",
                     effect="C (*1F) slows induced caffeine clearance — moderate for caffeine handling",
                     citations=[C(10233211, "Sachse 1999 — CYP1A2 *1F inducibility"),
                                C(GWAS, "Caffeine metabolism GWAS support")]),
    "rs2472297": dict(tier="replicated", effect="T: faster caffeine clearance tendency — small",
                      citations=[C(GWAS, "CYP1A1/1A2 region caffeine consumption GWAS")]),
    "rs4410790": dict(tier="replicated", effect="C: higher caffeine intake tendency — small",
                      citations=[C(GWAS, "AHR caffeine consumption GWAS, replicated")]),
    "rs1051740": dict(tier="replicated", effect="Slow microsomal epoxide hydrolase variant — small",
                      citations=[C(PGKB, "EPHX1 Tyr113His annotations")]),
    "rs1800566": dict(tier="replicated", effect="T (P187S) inactivates NQO1 — moderate for quinone handling",
                      citations=[C(PGKB, "NQO1*2 annotations"), C(GWAS, "NQO1 P187S functional literature")]),
    "rs1695": dict(tier="replicated", effect="Ile105Val shifts GST-pi conjugation — small",
                   citations=[C(PGKB, "GSTP1 Ile105Val annotations")]),
    "rs4880": dict(tier="replicated", transferability="multi-ancestry",
                   effect="Ala16Val alters MnSOD mitochondrial import — small",
                   citations=[C(GWAS, "SOD2 Ala16Val oxidative-stress literature")]),
    "rs1138272": dict(tier="tendency", effect="Secondary GSTP1 variant — small",
                      citations=[C(PGKB, "GSTP1 Ala114Val annotations")]),
    "rs8175347": dict(tier="well-replicated", effect="UGT1A1*28 TA-repeat itself (often untyped on arrays)",
                      citations=[C(PGKB, "UGT1A1*28 annotations")], chips=["myheritage"]),

    # --- Neuro ---
    "rs4680": dict(tier="well-replicated", transferability="multi-ancestry",
                   effect="Val158Met: ~3-4x COMT activity difference between homozygotes — robust enzymatic, modest behavioral effect",
                   citations=[C(8807664, "Lachman 1996 — COMT Val158Met thermolability"),
                              C(GWAS, "Extensive replication for enzyme activity; behavioral endpoints heterogeneous")]),
    "rs6265": dict(tier="well-replicated", transferability="multi-ancestry",
                   effect="Met allele reduces activity-dependent BDNF secretion — modest cognitive/plasticity effect",
                   citations=[C(12553913, "Egan 2003, Cell — BDNF Val66Met and hippocampal function")]),
    "rs1800497": dict(tier="replicated", effect="A1 (Taq1A): ~30% lower striatal D2 density — modest",
                      citations=[C(GWAS, "ANKK1/DRD2 Taq1A PET and addiction meta-analyses; effect modest")]),
    "rs53576": dict(tier="tendency", effect="OXTR social-behavior association — small, mixed replication",
                    citations=[C(GWAS, "OXTR rs53576 social cognition meta-analyses; heterogeneous")]),
    "rs6311": dict(tier="tendency", effect="HTR2A expression shift — small",
                   citations=[C(GWAS, "HTR2A -1438G/A psychiatric studies, mixed")]),
    "rs6323": dict(tier="tendency", effect="MAOA activity shift — small",
                   citations=[C(GWAS, "MAOA T941G activity studies")]),
    "rs110402": dict(tier="tendency", effect="CRHR1 stress-axis modulation — small",
                     citations=[C(GWAS, "CRHR1 early-adversity interaction literature, mixed")]),
    "rs1360780": dict(tier="replicated", effect="T: FKBP5 stress-axis feedback shift — small-moderate in interaction models",
                      citations=[C(GWAS, "FKBP5 rs1360780 HPA-axis replication")]),
    "rs34637584": dict(tier="well-replicated", effect="LRRK2 G2019S — high lifetime Parkinson risk in carriers; rare",
                       citations=[C(CLIN, "Pathogenic, incomplete penetrance"), C(GWAS, "LRRK2 G2019S founder studies")]),

    # --- Sleep ---
    "rs1801260": dict(tier="replicated", effect="C: eveningness tendency — small",
                      citations=[C(GWAS, "CLOCK 3111T/C chronotype meta-analyses")]),
    "rs57875986": dict(tier="replicated", effect="PER3 length variant — diurnal preference, small",
                       citations=[C(GWAS, "PER3 VNTR chronotype literature")], chips=["myheritage"]),
    "rs5751876": dict(tier="replicated", effect="TT: caffeine-induced sleep disruption/anxiety tendency — moderate for caffeine response",
                      citations=[C(GWAS, "ADORA2A 1976C>T caffeine sensitivity replication")]),
    "rs73598374": dict(tier="replicated", effect="Reduced ADA activity — deeper slow-wave sleep tendency",
                       citations=[C(GWAS, "ADA G22A sleep-depth studies, small n but consistent")]),
    "rs10830963": dict(reviewed=True, tier="well-replicated", transferability="multi-ancestry",
                       effect="G: fasting glucose +~0.07 mmol/L, T2D OR ~1.1, melatonin-timing shift — modest",
                       citations=[C(19060907, "Prokopenko 2009, Nat Genet — MTNR1B and fasting glucose"),
                                  C(GWAS, "Replicated glycemic + circadian associations")]),

    # --- Metabolic ---
    "rs7903146": dict(tier="well-replicated", transferability="multi-ancestry",
                      effect="T: T2D OR ~1.4 per allele — the strongest common T2D SNP",
                      citations=[C(16415884, "Grant 2006, Nat Genet — TCF7L2 and type 2 diabetes"),
                                 C(GWAS, "Replicated in most ancestries; frequency varies widely")]),
    "rs9939609": dict(reviewed=True, tier="well-replicated", transferability="multi-ancestry",
                      effect="A: +~0.4 BMI units, obesity OR ~1.3 per allele — modest, strongly diet/activity-modifiable",
                      citations=[C(17434869, "Frayling 2007, Science — FTO and BMI"),
                                 C(GWAS, "Attenuated effect in African-ancestry cohorts")]),
    "rs17782313": dict(tier="well-replicated", effect="C: +~0.2 BMI units per allele — small",
                       citations=[C(18454148, "Loos 2008, Nat Genet — MC4R common variants and BMI")]),
    "rs5219": dict(tier="well-replicated", effect="T (E23K): T2D OR ~1.15 — small",
                   citations=[C(GWAS, "KCNJ11 E23K T2D meta-analyses, replicated")]),
    "rs1801282": dict(reviewed=True, tier="well-replicated", effect="Pro12: T2D OR ~1.2 vs Ala12 protective — small",
                      citations=[C(10973253, "Altshuler 2000, Nat Genet — PPARG Pro12Ala and T2D")]),
    "rs738409": dict(reviewed=True, tier="well-replicated", transferability="multi-ancestry",
                     effect="G (I148M): hepatic-fat +, NAFLD OR ~1.5-2 per allele — strong for liver fat; highest frequency in Hispanic/Latino cohorts",
                     citations=[C(18820647, "Romeo 2008, Nat Genet — PNPLA3 I148M and hepatic fat")]),
    "rs13266634": dict(tier="well-replicated", effect="C: T2D OR ~1.15, zinc-transport effect on insulin granules — small",
                       citations=[C(GWAS, "SLC30A8 R325W T2D meta-analyses")]),
    "rs1260326": dict(tier="well-replicated", transferability="multi-ancestry",
                      effect="T (P446L): triglycerides +, fasting glucose − — pleiotropic, modest",
                      citations=[C(GWAS, "GCKR P446L metabolic pleiotropy, extensively replicated")]),
    "rs780094": dict(tier="well-replicated", effect="GCKR intronic proxy of P446L — modest metabolic pleiotropy",
                     citations=[C(GWAS, "GCKR locus lipid/glucose GWAS")]),
    "rs1799884": dict(tier="replicated", effect="Small fasting-glucose elevation",
                      citations=[C(GWAS, "GCK -30G>A fasting glucose meta-analyses")]),
    "rs10885122": dict(tier="tendency", effect="Small fasting-glucose shift",
                       citations=[C(GWAS, "ADRA2A fasting glucose GWAS")]),
    "rs1042713": dict(tier="replicated", effect="Arg16 alters β2-receptor downregulation — small",
                      citations=[C(GWAS, "ADRB2 Arg16Gly exercise/asthma literature")]),
    "rs1042714": dict(tier="replicated", effect="Gln27Glu β2-receptor variant — small",
                      citations=[C(GWAS, "ADRB2 Gln27Glu metabolic literature")]),
    "rs4994": dict(tier="replicated", effect="Trp64Arg: small resting-metabolism/weight effect",
                   citations=[C(GWAS, "ADRB3 Trp64Arg meta-analyses, small")]),
    "rs659366": dict(tier="tendency", effect="UCP2 promoter — small energy-expenditure shift",
                     citations=[C(GWAS, "UCP2 -866G>A studies")]),
    "rs1800592": dict(tier="tendency", effect="UCP1 promoter — small thermogenesis shift",
                      citations=[C(GWAS, "UCP1 -3826A>G brown-fat literature")]),
    "rs2287019": dict(tier="replicated", effect="Small weight-loss-response association",
                      citations=[C(GWAS, "GIPR variant diet-response meta-analyses")]),
    "rs17817449": dict(tier="well-replicated", effect="FTO intron 1 proxy — modest BMI effect",
                       citations=[C(GWAS, "FTO locus BMI GWAS")]),

    # --- Fitness ---
    "rs1815739": dict(tier="well-replicated", transferability="multi-ancestry",
                      effect="X (577X) abolishes α-actinin-3; RR over-represented in sprint/power athletes — robust for protein, modest for performance",
                      citations=[C(12879365, "Yang 2003, Am J Hum Genet — ACTN3 R577X and elite athletic performance")]),
    "rs4343": dict(tier="replicated", effect="ACE I/D proxy; D-allele higher ACE activity — small performance associations",
                   citations=[C(GWAS, "ACE I/D endurance-power literature; rs4343 as proxy")]),
    "rs8192678": dict(tier="replicated", effect="Gly482Ser: small aerobic-adaptation effect",
                      citations=[C(GWAS, "PPARGC1A Gly482Ser endurance studies")]),
    "rs17602729": dict(tier="replicated", effect="AMPD1 Q12X: reduced muscle AMP deaminase; small sprint-fatigue effect",
                       citations=[C(CLIN, "AMPD1 deficiency allele"), C(GWAS, "Exercise phenotype studies")], reviewed=True),
    "rs1800012": dict(tier="replicated", effect="Sp1 T: altered collagen α1 ratio; soft-tissue injury association — small-moderate",
                      citations=[C(GWAS, "COL1A1 Sp1 injury/BMD meta-analyses")]),
    "rs12722": dict(tier="replicated", effect="COL5A1 3'UTR: tendon-stiffness and injury association — small",
                    citations=[C(GWAS, "COL5A1 BstUI tendinopathy literature")]),
    "rs679620": dict(tier="tendency", effect="MMP3 promoter-linked; tendinopathy tendency — small",
                     citations=[C(GWAS, "MMP3 5A/6A musculoskeletal literature")]),
    "rs1049434": dict(tier="tendency", effect="MCT1 lactate-transport variant — small",
                      citations=[C(GWAS, "SLC16A1 E490D lactate clearance studies")]),
    "rs11549465": dict(tier="tendency", effect="HIF1A Pro582Ser — small hypoxia-response shift",
                       citations=[C(GWAS, "HIF1A P582S athlete studies, small n")]),
    "rs2070744": dict(tier="replicated", effect="NOS3 -786T>C: small NO-availability shift",
                      citations=[C(GWAS, "NOS3 promoter vascular meta-analyses")]),

    # --- Vitamins / minerals ---
    "rs1800562": dict(tier="well-replicated", effect="C282Y hom: hereditary hemochromatosis genotype (clinical penetrance incomplete, ~10-30% males) — strong",
                      citations=[C(8696333, "Feder 1996, Nat Genet — HFE C282Y discovery"),
                                 C(CLIN, "Pathogenic with incomplete penetrance; largely North-European allele")]),
    "rs1799945": dict(reviewed=True, tier="well-replicated", effect="H63D: mild iron-uptake shift; compound C282Y/H63D moderate risk",
                      citations=[C(8696333, "Feder 1996, Nat Genet — HFE H63D"),
                                 C(CLIN, "Low penetrance alone")]),
    "rs855791": dict(tier="well-replicated", transferability="multi-ancestry",
                     effect="V736A shifts hepcidin set-point; ~0.1 g/dL hemoglobin per allele — small",
                     citations=[C(GWAS, "TMPRSS6 iron/hemoglobin GWAS, replicated")]),
    "rs2282679": dict(tier="well-replicated", effect="C: 25-OH-D −~5 nmol/L per allele — modest",
                      citations=[C(20418485, "Wang 2010, Lancet — GC locus and vitamin D (SUNLIGHT)")]),
    "rs10741657": dict(tier="well-replicated", effect="G: lower 25-OH-D synthesis — small",
                       citations=[C(20418485, "Wang 2010, Lancet — CYP2R1 (SUNLIGHT)")]),
    "rs2228570": dict(tier="replicated", effect="FokI VDR start-codon variant — small receptor-potency shift",
                      citations=[C(GWAS, "VDR FokI meta-analyses, small heterogeneous effects")]),
    "rs7501331": dict(tier="replicated", effect="T: ~30-60% lower β-carotene conversion (with rs12934922) — moderate for conversion",
                      citations=[C(19103647, "Leung 2009, FASEB J — BCMO1 variants blunt β-carotene conversion")]),
    "rs174546": dict(tier="well-replicated", transferability="multi-ancestry",
                     effect="Large blood PUFA-ratio shifts by haplotype; TT lowers ALA→EPA/DHA conversion",
                     citations=[C(GWAS, "FADS1/2 cluster PUFA GWAS (Tanaka 2009; Lemaitre 2011)")]),
    "rs602662": dict(tier="well-replicated", transferability="multi-ancestry",
                     effect="FUT2 secretor-linked; non-secretors show higher B12 — modest",
                     citations=[C(GWAS, "FUT2 B12 GWAS, replicated across ancestries")]),
    # (duplicate key removed — rs1801198 is curated once in the methylation block)
    "rs4654748": dict(tier="replicated", effect="Small plasma-B6 shift",
                      citations=[C(GWAS, "NBPF3/ALPL region vitamin B6 GWAS")]),
    "rs1799941": dict(tier="replicated", effect="A: higher SHBG — small",
                      citations=[C(GWAS, "SHBG level GWAS, replicated")]),
    "rs2274976": dict(tier="tendency", effect="MTHFR distal variant — small",
                      citations=[C(GWAS, "MTHFR G1793A studies")]),
    "rs1051266": dict(tier="replicated", effect="RFC1 G80A folate-transport shift — small",
                      citations=[C(GWAS, "SLC19A1 folate transport literature")]),

    # --- Histamine / gut / taste ---
    "rs10156191": dict(tier="replicated", effect="T: reduced DAO activity — moderate for histamine clearance",
                       citations=[C(GWAS, "AOC1 Thr16Met DAO activity studies")]),
    "rs11558538": dict(tier="replicated", effect="T (Thr105Ile): ~30-50% lower HNMT activity — moderate",
                       citations=[C(GWAS, "HNMT Thr105Ile enzymatic replication")]),
    "rs713598": dict(tier="well-replicated", transferability="multi-ancestry",
                     effect="PAV vs AVI haplotype tag: near-Mendelian PTC/PROP bitter tasting",
                     citations=[C(12595690, "Kim 2003, Science — TAS2R38 and PTC taste"),], reviewed=True),
    "rs72921001": dict(tier="replicated", effect="Cilantro-soap perception tendency — small",
                       citations=[C(GWAS, "23andMe cilantro GWAS near OR6A2")]),
    "rs4988235": dict(tier="well-replicated", transferability="euro-biased",
                      effect="-13910T keeps lactase on in adults — near-deterministic in Europeans; other pops use different variants this chip may miss",
                      citations=[C(11788828, "Enattah 2002, Nat Genet — LCT -13910C>T"),
                                 C(GWAS, "African/Middle-Eastern persistence alleles (e.g. -14010G>C) are NOT tagged by this SNP")]),

    # --- Immunity ---
    "rs2476601": dict(tier="well-replicated", effect="R620W: RA/T1D OR ~1.6-1.9 — moderate; largely absent outside European ancestry",
                      citations=[C(15208781, "Begovich 2004, Am J Hum Genet — PTPN22 R620W and RA"),
                                 C(GWAS, "Replicated autoimmunity association; allele rare in East Asian/African cohorts")]),
    "rs4349859": dict(tier="well-replicated", effect="HLA-B*27 tag SNP — strong AS association via linkage; tag, not the allele",
                      citations=[C(GWAS, "HLA-B27 tag validation studies (sensitivity <100%)")]),
    "rs12979860": dict(tier="well-replicated", transferability="multi-ancestry",
                       effect="CC: ~2-3x higher HCV spontaneous/treatment clearance — strong",
                       citations=[C(19684573, "Ge 2009, Nature — IL28B and HCV clearance")]),
    "rs2187668": dict(tier="well-replicated", effect="Tags HLA-DQ2.5 — celiac necessary-but-not-sufficient haplotype; imperfect proxy",
                      citations=[C(GWAS, "Celiac HLA tag validation (Monsuur 2008)")]),
    "rs7454108": dict(tier="well-replicated", effect="Tags HLA-DQ8 — celiac susceptibility haplotype tag",
                      citations=[C(GWAS, "Celiac HLA-DQ8 tag validation")]),

    # --- Longevity / cellular ---
    "rs2802292": dict(tier="well-replicated", transferability="multi-ancestry",
                      effect="G: longevity OR ~1.5-2.7 in centenarian studies — replicated across Japanese, German, US cohorts",
                      citations=[C(18765803, "Willcox 2008, PNAS — FOXO3 and human longevity")]),
    "rs2736098": dict(tier="replicated", effect="Small telomere-length association",
                      citations=[C(GWAS, "TERT locus telomere GWAS")]),
    "rs3758391": dict(tier="tendency", effect="SIRT1 promoter — small",
                      citations=[C(GWAS, "SIRT1 promoter cohort studies, mixed")]),
    "rs1042522": dict(tier="replicated", effect="Pro72Arg apoptosis-efficiency shift — small",
                      citations=[C(GWAS, "TP53 Pro72Arg meta-analyses, heterogeneous")], reviewed=True),
    "rs1800566": dict(tier="replicated", effect="NQO1 P187S null — moderate for quinone detox",
                      citations=[C(PGKB, "NQO1*2 annotations")]),

    # --- Pigmentation / traits ---
    "rs12913832": dict(tier="well-replicated", effect="GG: blue eye color ~99% in Europeans — near-Mendelian",
                       citations=[C(18172690, "Eiberg 2008, Hum Genet — HERC2 regulatory variant and blue eyes")]),
    "rs1805007": dict(tier="well-replicated", effect="R151C 'R' allele: red hair/fair skin, UV sensitivity — strong",
                      citations=[C(7581459, "Valverde 1995, Nat Genet — MC1R variants and red hair")]),
    "rs17822931": dict(tier="well-replicated", transferability="east-asian-derived",
                       effect="TT: dry earwax + reduced axillary odor — near-Mendelian",
                       citations=[C(16444273, "Yoshiura 2006, Nat Genet — ABCC11 and earwax type")]),
    "rs3827760": dict(tier="well-replicated", transferability="east-asian-derived",
                      effect="370A (G): thicker hair shaft, shovel incisors — strong in East Asian populations",
                      citations=[C(GWAS, "EDAR V370A hair-morphology replication (Fujimoto 2008)")]),
    "rs1426654": dict(tier="well-replicated", transferability="multi-ancestry",
                      effect="A: major skin-lightening allele (explains ~25-38% Eur-Afr skin difference)",
                      citations=[C(16357253, "Lamason 2005, Science — SLC24A5 and pigmentation")]),
    "rs16891982": dict(tier="well-replicated", effect="G: skin/hair lightening — strong",
                       citations=[C(GWAS, "SLC45A2 L374F pigmentation replication")]),

    # --- Substances ---
    "rs671": dict(tier="well-replicated", transferability="east-asian-derived",
                  effect="A (*2): dominant ALDH2 inactivation; flush + esophageal-cancer risk with alcohol — strong",
                  citations=[C(GWAS, "ALDH2*2 flush/cancer literature (Brooks 2009 PLoS Med)"),
                             C(PGKB, "ALDH2 alcohol annotations")]),
    "rs1229984": dict(tier="well-replicated", transferability="multi-ancestry",
                      effect="T (His48): ~40-100x faster ADH1B kinetics; protective against heavy drinking — strong",
                      citations=[C(GWAS, "ADH1B His48Arg alcohol-dependence meta-analyses across ancestries")]),
}
