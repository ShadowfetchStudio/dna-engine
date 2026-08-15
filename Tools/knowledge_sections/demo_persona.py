"""The demo persona (feature 2) — a hand-curated genotype table that IS the
test fixture. Every compound, PGx gene, and score panel rsid is pinned here
explicitly, so catalog growth can never silently orphan the demo (lint below).

Genotype value forms:
    "A/G"    emit this genotype
    "0/0"    emit as a no-call            (planted: rs3892097 -> CYP2D6 indeterminate)
    "absent" do not emit the rsid at all  (planted: rs7454108 -> celiac 'partially typed';
                                           rs1799963 + rs2066865 -> venous panel under 60% coverage)

Persona design (see the spec):
  APOE ε3/ε4 · CYP2C19 *1/*2 · SLCO1B1 *1/*5 · slow CYP1A2 · TAS2R38 PAV/AVI ·
  FUT2 non-secretor · MC1R one R allele · NUDT15 het (east-asian-derived badge on a
  mixed-ancestry profile) · MTHFR TT · Factor V Leiden NEGATIVE (typical paths
  must be exercised too) · Gilbert carrier · HFE H63D carrier · VKORC1 het ·
  ABCG2 Q141K het · CYP4F2 het.
Ancestry: free AIMs are seeded 70/20/10 east_asian/european/african by
DemoGenome's seeded RNG; hand-pinned trait genotypes below stay plausible for
that mix where the persona script allows.
"""

DEMO = {
    # --- APOE / lipids ---
    "rs429358": "C/T", "rs7412": "C/C",
    "rs10455872": "A/A", "rs11591147": "G/G", "rs708272": "A/G",
    # --- MTHFR / one-carbon ---
    "rs1801133": "T/T", "rs1801131": "A/A", "rs1801394": "A/G", "rs1805087": "A/A",
    # --- CYP2C19 *1/*2 ---
    "rs4244285": "A/G", "rs4986893": "G/G", "rs12248560": "C/C",
    # --- CYP2C9 / VKORC1 / CYP4F2 warfarin triad ---
    "rs1799853": "C/C", "rs1057910": "A/A", "rs9923231": "A/G", "rs2108622": "C/T",
    "rs28371686": "C/C", "rs7900194": "G/G", "rs12777823": "G/G",
    # --- CYP2D6: planted NO-CALL on *4 (indeterminate refuse-to-call path) ---
    "rs3892097": "0/0", "rs1065852": "C/C", "rs28371725": "C/C",
    # --- SLCO1B1 *1/*5 ---
    "rs4149056": "C/T",
    # --- DPYD (all wild-type) ---
    "rs3918290": "C/C", "rs55886062": "A/A", "rs67376798": "T/T", "rs75017182": "G/G",
    # --- TPMT wild / NUDT15 het ---
    "rs1800460": "C/C", "rs1142345": "T/T", "rs116855232": "C/T",
    # --- UGT1A1 Gilbert carrier ---
    "rs887829": "C/T", "rs4148323": "G/G",
    # --- HLA-B*5701 negative ---
    "rs2395029": "T/T",
    # --- CYP3A5 non-expressor ---
    "rs776746": "G/G", "rs10264272": "C/C", "rs41303343": "T/T",
    # --- ABCG2 / CYP3A4 ---
    "rs2231142": "G/T", "rs35599367": "C/C",
    # --- caffeine: slow CYP1A2, ADORA2A het ---
    "rs762551": "C/C", "rs5751876": "C/T", "rs2472297": "C/C", "rs4410790": "C/T",
    "rs73598374": "C/C",
    # --- alcohol: ALDH2 wild, ADH1B*2 het (fast converter; EAS-plausible) ---
    "rs671": "G/G", "rs1229984": "C/T",
    # --- TAS2R38 PAV/AVI ---
    "rs713598": "C/G", "rs1726866": "C/T", "rs10246939": "C/T",
    # --- FUT2 non-secretor ---
    "rs601338": "A/A", "rs492602": "G/G",
    # --- MC1R load = 1 ---
    "rs1805007": "C/T", "rs1805008": "C/C", "rs1805009": "G/G",
    # --- pigmentation: HERC2 blue, no OCA2 modifier ---
    "rs12913832": "G/G", "rs1800407": "C/C",
    # --- HFE: C282Y negative, H63D carrier ---
    "rs1800562": "G/G", "rs1799945": "C/G",
    # --- lactase persistent (two-site concordant) ---
    "rs4988235": "C/T", "rs182549": "C/T",
    # --- celiac tags: DQ2.5 typed negative, DQ8 deliberately ABSENT -> partially typed ---
    "rs2187668": "C/C", "rs7454108": "absent",
    # --- neuro profile: balanced fallback ---
    "rs4680": "A/G", "rs6265": "C/C", "rs1800497": "G/G",
    # --- muscle hybrid / connective typical ---
    "rs1815739": "C/T", "rs4343": "A/G", "rs1800012": "C/C", "rs12722": "C/T",
    # --- vitamin D lower-tendency / A intermediate / omega typical ---
    "rs2282679": "A/C", "rs10741657": "A/G", "rs2228570": "C/T", "rs7501331": "C/T",
    "rs174546": "C/T",
    # --- histamine typical / autoimmune typical ---
    "rs10156191": "C/C", "rs11558538": "C/C", "rs2052129": "G/G", "rs1049793": "C/C",
    "rs4349859": "G/G", "rs2476601": "G/G",
    # --- PEMT (fatty-liver compound partner) / AMPD1 (power panel) ---
    "rs7946": "C/T", "rs17602729": "G/G",
    # --- liver: PNPLA3 het / longevity FOXO3 carrier ---
    "rs738409": "C/G", "rs2802292": "G/T", "rs2736098": "A/G", "rs3758391": "C/T",
    # --- panels: remaining pinned genotypes ---
    "rs10757274": "A/G", "rs1333049": "C/G", "rs3798220": "T/T", "rs1799983": "G/T",
    "rs699": "A/G",
    # Factor V Leiden NEGATIVE (typical path) + prothrombin/FGG ABSENT so the
    # venous panel runs at 2/4 coverage -> 'Insufficient chip coverage'
    "rs6025": "C/C", "rs1799963": "absent", "rs505922": "C/T", "rs2066865": "absent",
    "rs7903146": "C/T", "rs5219": "C/T", "rs1801282": "C/C", "rs10830963": "C/G",
    "rs9939609": "A/T", "rs17782313": "T/T",
    "rs1801260": "A/A", "rs57875986": "C/C",
    "rs8192678": "C/T",
    "rs1800629": "G/G", "rs4880": "A/G",
    "rs855791": "A/G", "rs3811647": "A/G",
    # --- planted palindromic strand-ambiguous pair (alleles outside expected set) ---
    "rs1800795": "A/A", "rs4818": "A/A",
}

# rsids exempt from the allele-consistency lint because they are DELIBERATE
# strand-garbage plants exercising MarkerMatcher's .strandAmbiguous path.
AMBIGUOUS_PLANTS = {"rs1800795", "rs4818"}


def lint_demo(demo, marker_ids, compounds, pgx_genes, scores, aims):
    errors = []
    aim_ids = {a["rsid"] for a in aims}
    score_ids = {s["rsid"] for panel in scores for s in panel["snps"]}

    def need(rsid, why):
        if rsid not in demo:
            errors.append(f"demo: {why} rsid {rsid} missing from the persona table")

    for c in compounds:
        for r in c.get("rsids", []):
            need(r, f"compound {c['id']}")
    for g in pgx_genes:
        for a in g.get("alleles", []) + g.get("subtractAlleles", []):
            need(a["rsid"], f"pgx {g['gene']}")
    for panel in scores:
        for s in panel["snps"]:
            need(s["rsid"], f"panel {panel['id']}")

    known = marker_ids | aim_ids | score_ids
    for rsid, gt in demo.items():
        if rsid not in known:
            errors.append(f"demo: {rsid} is not a catalog marker, AIM, or panel SNP")
        if gt in ("absent", "0/0"):
            continue
        if len(gt) != 3 or gt[1] != "/" or gt[0] not in "ACGT" or gt[2] not in "ACGT":
            errors.append(f"demo: {rsid} malformed genotype {gt!r}")

    absent = [r for r, g in demo.items() if g == "absent"]
    nocall = [r for r, g in demo.items() if g == "0/0"]
    if not absent:
        errors.append("demo: no deliberately-absent rsid (partially-typed path unexercised)")
    if not nocall:
        errors.append("demo: no planted no-call (refuse-to-call path unexercised)")
    return errors


def check_marker_alleles(demo, markers):
    """Called after markers list is final: genotypes must use marker alleles."""
    errors = []
    by = {m["rsid"]: m for m in markers}
    for rsid, gt in demo.items():
        if gt in ("absent", "0/0") or rsid in AMBIGUOUS_PLANTS:
            continue
        m = by.get(rsid)
        if not m:
            continue
        allowed = {m["alleleA"].upper(), m["alleleB"].upper()}
        obs = {gt[0], gt[2]}
        comp = {{"A": "T", "T": "A", "C": "G", "G": "C"}[c] for c in obs}
        if not (obs <= allowed or comp <= allowed):
            errors.append(f"demo: {rsid} genotype {gt} uses alleles {sorted(obs)} not in marker's {sorted(allowed)}")
    return errors
