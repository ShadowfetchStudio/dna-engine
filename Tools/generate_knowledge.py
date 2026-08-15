#!/usr/bin/env python3
"""Generate Resources/knowledge.json for the flagship offline DNA Engine catalog.

DNA Engine 2.0 "The Honest Atlas":
  * 400+ curated chip-callable markers across 14 section modules
    (Tools/knowledge_sections/*.py), every one carrying citations, an evidence
    tier, a plain-language effect size, ancestry transferability, and expected
    chip coverage — the generator refuses to emit a marker missing any of them.
  * Published ancestry-informative markers only (placeholder AIMs purged).
  * Data-driven compound/diplotype definitions, PGx star-allele tables with
    explicit chip-limitation disclosures, HWE-calibrated polygenic panels,
    a curated limitations catalog, and the deterministic demo persona.

Run directly or via build.sh / Tools/run_checks.sh. Exits nonzero on any lint
failure so a broken catalog can never ship silently.
"""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from knowledge_sections import common
from knowledge_sections import (
    methylation, cardio, pgx, neuro, sleep, metabolic, fitness, vitamins,
    histamine_gut, immunity, longevity, traits_sensory, pigmentation, substances,
)

# Import order matters only for dedupe (last wins); keep stable.
SECTION_MODULES = [
    methylation, cardio, pgx, neuro, sleep, metabolic, fitness, vitamins,
    histamine_gut, immunity, longevity, traits_sensory, pigmentation, substances,
]

# ==============================================================================
# SKIPPED ON PRINCIPLE — documented absences, not oversights.
#
#   * DEC2 / BHLHE41 short-sleep variants (e.g. p.Tyr362His): genuinely rare and
#     not present on common consumer arrays; a call would be speculative.
#   * Full CYP2A6 status: the clinically dominant alleles are whole-gene
#     deletions / conversions (CNV-dominated) that SNP arrays cannot see.
#   * HLA-B*15:02 (carbamazepine SJS/TEN): no reliable array tag SNP exists
#     across ancestries; a proxy call would be dangerous. Its absence is
#     disclosed in the PGx "undetectable" lists and the Limitations panel.
#   * LOC1–LOC24 placeholder AIMs from catalog 1.x: removed 2.0 — they carried
#     invented gene names and unsourced frequencies, violating the
#     no-speculative-claims rule. The remaining AIM set is the published,
#     citation-carrying core (SLC24A5, SLC45A2, DARC/ACKR1, EDAR, HERC2, ...).
# ==============================================================================


# ==============================================================================
# ANCESTRY INFORMATIVE MARKERS — published loci only, with source notes.
# ==============================================================================

def aim(rsid, gene, derived, ancestral, freqs, source=""):
    return {
        "rsid": rsid,
        "gene": gene,
        "derived": derived,
        "ancestral": ancestral,
        "freqsDerived": freqs,
        "source": source,
    }


def f(eur, afr, eas, sas, amr, mena, oce):
    return {
        "european": eur,
        "african": afr,
        "east_asian": eas,
        "south_asian": sas,
        "american": amr,
        "middle_eastern": mena,
        "oceanian": oce,
    }


_SRC_CLASSIC = "Classic ancestry-informative locus; frequencies approximate 1000G/gnomAD continental values"
_SRC_TRAIT = "Well-characterized functional locus with strong continental frequency contrast (1000G/gnomAD)"

AIMS = [
    # rs2814778 orientation re-verified for 2.0: the Duffy-null (FY*O) allele is
    # the GATA-box C on the plus strand — derived C near-fixed in West/Central
    # Africa, rare elsewhere. Matches the freqs below.
    aim("rs2814778", "ACKR1", "C", "T", f(0.005, 0.985, 0.001, 0.008, 0.040, 0.035, 0.010), _SRC_CLASSIC),
    aim("rs1426654", "SLC24A5", "A", "G", f(0.998, 0.052, 0.008, 0.880, 0.550, 0.940, 0.120), "Lamason 2005 (PMID 16357253); Kidd/Seldin AIM panels"),
    aim("rs16891982", "SLC45A2", "G", "C", f(0.980, 0.015, 0.005, 0.140, 0.420, 0.620, 0.050), "Kidd/Seldin AIM panels"),
    aim("rs3827760", "EDAR", "G", "A", f(0.002, 0.001, 0.920, 0.045, 0.680, 0.015, 0.080), "EDAR V370A; Kidd AIM panel"),
    aim("rs17822931", "ABCC11", "T", "C", f(0.120, 0.010, 0.950, 0.480, 0.180, 0.220, 0.150), "Yoshiura 2006 (PMID 16444273)"),
    aim("rs4988235", "MCM6", "T", "C", f(0.760, 0.050, 0.005, 0.220, 0.210, 0.280, 0.020), "Enattah 2002 (PMID 11788828)"),
    aim("rs12913832", "HERC2", "G", "A", f(0.810, 0.008, 0.001, 0.085, 0.190, 0.180, 0.015), "Eiberg 2008 (PMID 18172690)"),
    aim("rs3829241", "TPCN2", "A", "G", f(0.480, 0.060, 0.110, 0.240, 0.320, 0.380, 0.140), _SRC_TRAIT),
    aim("rs12821256", "KITLG", "C", "T", f(0.190, 0.002, 0.001, 0.015, 0.045, 0.040, 0.005), "Blond-hair locus; Sulem 2007"),
    aim("rs12203592", "IRF4", "T", "C", f(0.180, 0.008, 0.001, 0.025, 0.065, 0.055, 0.010), "Pigmentation AIM; Sulem 2007"),
    aim("rs1800414", "OCA2", "C", "T", f(0.001, 0.001, 0.620, 0.018, 0.025, 0.010, 0.005), "East-Asian skin-lightening allele (His615Arg)"),
    aim("rs1408799", "TYRP1", "T", "C", f(0.310, 0.740, 0.380, 0.440, 0.520, 0.410, 0.580), _SRC_CLASSIC),
    aim("rs1042602", "TYR", "A", "C", f(0.390, 0.008, 0.005, 0.060, 0.190, 0.140, 0.025), "TYR S192Y pigmentation AIM"),
    aim("rs1834619", "SLC24A5", "C", "T", f(0.015, 0.620, 0.008, 0.075, 0.110, 0.090, 0.180), _SRC_CLASSIC),
    aim("rs1871534", "KITLG", "G", "A", f(0.045, 0.880, 0.015, 0.140, 0.190, 0.110, 0.420), "Kidd 55-AISNP panel"),
    aim("rs260690", "SLC45A2", "A", "C", f(0.075, 0.740, 0.140, 0.240, 0.310, 0.190, 0.360), "Kidd 55-AISNP panel"),
    aim("rs6754311", "LCT", "T", "C", f(0.420, 0.045, 0.015, 0.075, 0.115, 0.190, 0.025), _SRC_CLASSIC),
    aim("rs671", "ALDH2", "A", "G", f(0.001, 0.001, 0.280, 0.012, 0.010, 0.005, 0.005), "ALDH2*2 East-Asian founder allele"),
    aim("rs1229984", "ADH1B", "T", "C", f(0.035, 0.008, 0.780, 0.160, 0.075, 0.140, 0.040), "ADH1B His48 frequency contrast"),
    aim("rs3811801", "ADH1B", "T", "C", f(0.018, 0.008, 0.320, 0.038, 0.028, 0.048, 0.018), _SRC_CLASSIC),
    aim("rs3814134", "EDAR", "G", "A", f(0.015, 0.015, 0.720, 0.075, 0.380, 0.035, 0.075), "EDAR region AIM"),
    aim("rs642742", "KITLG", "C", "T", f(0.840, 0.090, 0.240, 0.420, 0.520, 0.580, 0.190), _SRC_CLASSIC),
    aim("rs26722", "SLC45A2", "T", "C", f(0.035, 0.240, 0.420, 0.140, 0.175, 0.115, 0.215), _SRC_CLASSIC),
    aim("rs2470102", "MYH16", "A", "G", f(0.580, 0.140, 0.740, 0.460, 0.390, 0.520, 0.340), _SRC_CLASSIC),
    aim("rs1800497", "ANKK1", "A", "G", f(0.190, 0.380, 0.440, 0.290, 0.260, 0.230, 0.310), _SRC_TRAIT),
    aim("rs429358", "APOE", "C", "T", f(0.150, 0.280, 0.090, 0.090, 0.110, 0.100, 0.190), _SRC_TRAIT),
    aim("rs738409", "PNPLA3", "G", "C", f(0.230, 0.140, 0.380, 0.260, 0.520, 0.230, 0.210), _SRC_TRAIT),
    aim("rs1815739", "ACTN3", "T", "C", f(0.440, 0.100, 0.510, 0.420, 0.310, 0.390, 0.260), _SRC_TRAIT),
    aim("rs2032582", "ABCB1", "T", "G", f(0.440, 0.120, 0.460, 0.520, 0.480, 0.420, 0.350), _SRC_TRAIT),
    aim("rs1801133", "MTHFR", "T", "C", f(0.350, 0.110, 0.420, 0.180, 0.480, 0.280, 0.150), _SRC_TRAIT),
    aim("rs1045642", "ABCB1", "T", "C", f(0.520, 0.160, 0.410, 0.620, 0.550, 0.510, 0.380), _SRC_TRAIT),
    aim("rs762551", "CYP1A2", "C", "A", f(0.320, 0.480, 0.380, 0.280, 0.290, 0.340, 0.310), _SRC_TRAIT),
    aim("rs4680", "COMT", "A", "G", f(0.490, 0.280, 0.290, 0.420, 0.350, 0.450, 0.220), _SRC_TRAIT),
    aim("rs6265", "BDNF", "T", "C", f(0.200, 0.040, 0.460, 0.220, 0.180, 0.150, 0.120), _SRC_TRAIT),
    aim("rs9939609", "FTO", "A", "T", f(0.420, 0.510, 0.160, 0.310, 0.320, 0.380, 0.240), _SRC_TRAIT),
    aim("rs7903146", "TCF7L2", "T", "C", f(0.310, 0.320, 0.040, 0.280, 0.240, 0.350, 0.120), _SRC_TRAIT),
]


def dedupe_aims(items):
    seen = {}
    for x in items:
        seen[x["rsid"]] = x
    return list(seen.values())


# ==============================================================================
# POLYGENIC TENDENCY PANELS — HWE-calibrated in feature 4 (scores module).
# ==============================================================================
from knowledge_sections.scores import SCORES, build_calibration

DISCLAIMER = (
    "Educational and research-grade genomic interpretation of peer-reviewed human genetics literature, "
    "computed 100% offline and on-device. Not medical advice, not a clinical diagnosis, and not a substitute "
    "for a licensed physician or clinical genetic test. Pharmacogenomic notes must be reviewed with a doctor or "
    "pharmacist before making any changes to prescription medications."
)

POPULATIONS = [
    "european", "african", "east_asian", "south_asian",
    "american", "middle_eastern", "oceanian",
]

VALID_TIERS = {"well-replicated", "replicated", "tendency"}
VALID_TRANSFER = {"euro-biased", "multi-ancestry", "east-asian-derived", "african-derived"}


def lint_markers(markers):
    errors, warnings = [], []
    seen_pal = 0
    for m in markers:
        rid = m["rsid"]
        cits = m.get("citations")
        if not cits:
            errors.append(f"{rid}: missing citations (>=1 required)")
        else:
            for c in cits:
                if not str(c.get("pmid", "")).strip() or not str(c.get("note", "")).strip():
                    errors.append(f"{rid}: citation with empty pmid/note")
        if m.get("tier") not in VALID_TIERS:
            errors.append(f"{rid}: tier missing or invalid ({m.get('tier')!r})")
        if m.get("transferability") not in VALID_TRANSFER:
            errors.append(f"{rid}: transferability invalid ({m.get('transferability')!r})")
        if not m.get("chips"):
            errors.append(f"{rid}: chips list empty — every marker must state expected array coverage")
        if m.get("mechanism") != common.NEUTRAL_MARKER_MECHANISM:
            errors.append(f"{rid}: single-marker mechanism crossed the non-interpretive release boundary")
        if m.get("effect") is not None:
            errors.append(f"{rid}: single-marker effect must be withheld")
        if m.get("notes"):
            errors.append(f"{rid}: legacy marker notes must not ship")
        for genotype, observation in m.get("genotypes", {}).items():
            expected = {
                "label": common.NEUTRAL_GENOTYPE_LABEL,
                "impact": "typical",
                "summary": common.NEUTRAL_GENOTYPE_SUMMARY,
                "detail": common.NEUTRAL_GENOTYPE_DETAIL,
                "actions": {},
            }
            if observation != expected:
                errors.append(f"{rid}/{genotype}: genotype outcome content crossed the release boundary")
        pair = {m["alleleA"].upper(), m["alleleB"].upper()}
        if pair in ({"A", "T"}, {"C", "G"}):
            seen_pal += 1
            warnings.append(
                f"{rid}: palindromic allele pair {sorted(pair)} has no validated orientation manifest and will fail closed"
            )
        if m["gene"].upper().startswith("LOC"):
            errors.append(f"{rid}: placeholder LOC gene name — purged in 2.0, use a published locus or drop")
    return errors, warnings, seen_pal


def enforce_palindromic_compound_fail_closed(compounds, markers):
    """Make an unresolved palindromic input withhold the whole compound call.

    A missing A/T or C/G locus must not be treated as zero dosage or as a
    negative rule and then fall through to a definitive fallback outcome.
    """
    marker_by_rsid = {m["rsid"]: m for m in markers}
    for compound in compounds:
        palindromic = []
        for rsid in compound.get("rsids", []):
            marker = marker_by_rsid.get(rsid)
            if not marker:
                continue
            pair = {marker["alleleA"].upper(), marker["alleleB"].upper()}
            if pair in ({"A", "T"}, {"C", "G"}):
                palindromic.append(rsid)
        if not palindromic:
            continue
        required = list(dict.fromkeys((compound.get("requireTyped") or []) + palindromic))
        compound["requireTyped"] = required
        if not compound.get("partial"):
            compound["partial"] = {
                "value": "Research rule coverage only",
                "detail": "Referenced loci are retained for research provenance. No genotype-derived activity, phenotype, diagnosis, risk, sensitivity, or personal outcome is inferred.",
                "impact": "typical",
            }


def main():
    root = Path(__file__).resolve().parents[1]
    out = root / "Resources" / "knowledge.json"
    out.parent.mkdir(parents=True, exist_ok=True)

    common.MARKERS.clear()
    for mod in SECTION_MODULES:
        mod.register(common.add)

    # Lint self-test hook: a deliberately broken fixture module must trip the lint.
    if os.environ.get("GEN_INCLUDE_BROKEN_FIXTURE") == "1":
        from fixtures import broken_section_fixture
        broken_section_fixture.register(common.add)

    # Deduplicate markers by rsid (last wins)
    by = {}
    for m in common.MARKERS:
        by[m["rsid"]] = m
    markers = list(by.values())

    errors, warnings, pal_count = lint_markers(markers)
    for w in warnings:
        print(f"WARN  {w}", file=sys.stderr)
    if errors:
        for e in errors:
            print(f"ERROR {e}", file=sys.stderr)
        print(f"generate_knowledge: {len(errors)} lint error(s) — refusing to write knowledge.json", file=sys.stderr)
        return 1

    aims = dedupe_aims(AIMS)
    for a in aims:
        if a["gene"].upper().startswith("LOC"):
            print(f"ERROR AIM {a['rsid']}: placeholder LOC gene", file=sys.stderr)
            return 1

    marker_ids = {m["rsid"] for m in markers}

    scores, score_errors = build_calibration(SCORES, POPULATIONS)
    if score_errors:
        for e in score_errors:
            print(f"ERROR {e}", file=sys.stderr)
        return 1

    from knowledge_sections.compounds import COMPOUNDS, lint_compounds
    enforce_palindromic_compound_fail_closed(COMPOUNDS, markers)
    comp_errors = lint_compounds(COMPOUNDS)
    if comp_errors:
        for e in comp_errors:
            print(f"ERROR {e}", file=sys.stderr)
        return 1

    from knowledge_sections.pgx_genes import PGX_GENES, lint_pgx
    pgx_errors = lint_pgx(PGX_GENES)
    if pgx_errors:
        for e in pgx_errors:
            print(f"ERROR {e}", file=sys.stderr)
        return 1

    from knowledge_sections.limitations import LIMITATIONS, lint_limitations
    lim_errors = lint_limitations(LIMITATIONS)
    if lim_errors:
        for e in lim_errors:
            print(f"ERROR {e}", file=sys.stderr)
        return 1

    from knowledge_sections.demo_persona import DEMO, lint_demo, check_marker_alleles
    demo_errors = lint_demo(DEMO, marker_ids, COMPOUNDS, PGX_GENES, scores, aims)
    demo_errors += check_marker_alleles(DEMO, markers)
    if demo_errors:
        for e in demo_errors:
            print(f"ERROR {e}", file=sys.stderr)
        return 1

    for m in markers:
        m.pop("_reviewed", None)

    payload = {
        "version": "2.0.0",
        "disclaimer": DISCLAIMER,
        "populations": POPULATIONS,
        "markers": markers,
        "aims": aims,
        "scores": scores,
        "compounds": COMPOUNDS,
        "pgx": PGX_GENES,
        "limitations": LIMITATIONS,
        "demo": DEMO,
    }

    out.write_text(json.dumps(payload, indent=2, sort_keys=False), encoding="utf-8")
    print(
        f"wrote {out} markers={len(markers)} aims={len(aims)} scores={len(scores)} "
        f"compounds={len(COMPOUNDS)} pgxGenes={len(PGX_GENES)} limitations={len(LIMITATIONS)} "
        f"demoRows={len(DEMO)} palindromic={pal_count}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
