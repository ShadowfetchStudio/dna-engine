#!/usr/bin/env python3
"""Package the validated ancestry reference panel into the app bundle (2.1).

Reads the frequency-source file produced by the panel-fetch tooling
(reference_frequencies.json: 2,621 markers x 43 population columns, ALT-allele
frequencies, full provenance) and writes Resources/reference_panel.json pruned
to exactly the columns the offline AdmixtureEngine consumes:

    continental tier : AFR EUR EAS SAS AMR (1000G superpops) + MID (gnomad_mid)
    within-EUR tier  : NWE (mean of 1000G CEU+GBR), TSI, IBS, FIN, ASJ (gnomad_asj)
    ASJ founder LR   : ASJ vs NFE (gnomad_nfe)

Also precomputes the two likelihood subsets:
    eur  — markers with |dAF| > 0.1 on any within-EUR axis
           (NWE vs S-Europe, FIN vs NWE, IBS vs TSI, ASJ vs NFE)
    asj  — the |ASJ-NFE| > 0.1 founder-signal subset (377 markers pre-dedup)

LD control: the LCT-region trio rs4988235/rs182549/rs6754311 is one haplotype
carrying three of the top ASJ/S-Europe separators; only the single strongest
(|ASJ-NFE|) keeps its subset flags so one LD block cannot dominate either
likelihood (staging PANEL_REPORT.md consumption note 5).

Offline invariant: this script runs at BUILD time against a local file. The
app only ever loads the bundled JSON — no network anywhere.

Exit nonzero on any sanity failure so a broken panel can never ship silently.
If the staging file is absent but a previously packaged panel exists, the
existing panel is kept (build machines without the staging tree stay green).
"""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "Resources" / "reference_panel.json"
STAGING = Path(os.environ.get(
    "ANCESTRY_STAGING",
    "reference_frequencies.json",  # set $ANCESTRY_STAGING to your frequency-source path
))

# bundle column -> staging pops key (NWE is derived below)
KEEP = {
    "AFR": "AFR", "EUR": "EUR", "EAS": "EAS", "SAS": "SAS", "AMR": "AMR",
    "MID": "gnomad_mid",
    "TSI": "TSI", "IBS": "IBS", "FIN": "FIN",
    "ASJ": "gnomad_asj", "NFE": "gnomad_nfe",
}

POP_SOURCES = {
    "AFR": "1000 Genomes phase 3 African superpopulation (via Ensembl REST, release 116, fetched 2026-08-13)",
    "EUR": "1000 Genomes phase 3 European superpopulation (via Ensembl REST, release 116, fetched 2026-08-13)",
    "EAS": "1000 Genomes phase 3 East Asian superpopulation (via Ensembl REST, release 116, fetched 2026-08-13)",
    "SAS": "1000 Genomes phase 3 South Asian superpopulation (via Ensembl REST, release 116, fetched 2026-08-13)",
    "AMR": "1000 Genomes phase 3 admixed Americas superpopulation (via Ensembl REST, release 116, fetched 2026-08-13) — reference itself is recently admixed",
    "MID": "gnomAD v4 genomes, Middle Eastern (modest reference sample size — supporting evidence, not a primary call)",
    "NWE": "Mean of 1000 Genomes phase 3 CEU (Utah/NW-European) + GBR (British) alt-allele frequencies (via Ensembl REST, release 116)",
    "TSI": "1000 Genomes phase 3 TSI — Toscani in Italia (via Ensembl REST, release 116)",
    "IBS": "1000 Genomes phase 3 IBS — Iberian populations in Spain (via Ensembl REST, release 116)",
    "FIN": "1000 Genomes phase 3 FIN — Finnish in Finland (via Ensembl REST, release 116)",
    "ASJ": "gnomAD v4 genomes, Ashkenazi Jewish (gnomADg via Ensembl + gnomad_r4 GraphQL fill-in, fetched 2026-08-13)",
    "NFE": "gnomAD v4 genomes, Non-Finnish European (used only as the ASJ likelihood-ratio baseline)",
}

# One LD block, three top separators (LCT region). Winner keeps flags.
LCT_CLUSTER = ["rs4988235", "rs182549", "rs6754311"]

SUBSET_THRESHOLD = 0.1


def fail(msg: str) -> "None":
    print(f"ERROR build_reference_panel: {msg}", file=sys.stderr)
    sys.exit(1)


def main() -> int:
    if not STAGING.exists():
        if OUT.exists():
            print(f"build_reference_panel: staging file absent, keeping existing {OUT}")
            return 0
        fail(f"staging panel {STAGING} missing and no packaged panel exists at {OUT}")

    staging = json.loads(STAGING.read_text(encoding="utf-8"))
    src_markers = staging["markers"]
    prov = staging.get("provenance", {})

    if len(src_markers) != 2621:
        fail(f"expected 2621 staging markers, found {len(src_markers)}")
    convention = prov.get("frequency_convention", "")
    if "ALT allele frequency" not in convention:
        fail(f"staging frequency convention changed: {convention!r}")

    out_markers = []
    asj_flagged = []
    eur_flagged = []
    for rsid in sorted(src_markers):  # stable order — the demo RNG stream depends on it
        m = src_markers[rsid]
        ref, alt = m["ref"], m["alt"]
        if len(ref) != 1 or len(alt) != 1 or ref not in "ACGT" or alt not in "ACGT":
            fail(f"{rsid}: non-SNV alleles {ref}/{alt}")
        pops = m["pops"]

        af = {}
        for col, key in KEEP.items():
            v = pops.get(key)
            if v is None:
                continue  # skip, don't impute (<=8 gnomAD gaps)
            if not (0.0 <= v <= 1.0):
                fail(f"{rsid}: {col} frequency {v} outside [0,1]")
            af[col] = round(v, 4)
        ceu, gbr = pops.get("CEU"), pops.get("GBR")
        if ceu is not None and gbr is not None:
            af["NWE"] = round((ceu + gbr) / 2.0, 4)

        for col in ("AFR", "EUR", "EAS", "SAS", "AMR"):
            if col not in af:
                fail(f"{rsid}: missing 1000G superpop column {col}")

        row = {"rsid": rsid, "ref": ref, "alt": alt, "af": af}

        # Subset flags (raw staging precision, not the rounded values).
        asj, nfe = pops.get("gnomad_asj"), pops.get("gnomad_nfe")
        tsi, ibs, fin = pops.get("TSI"), pops.get("IBS"), pops.get("FIN")
        nwe = (ceu + gbr) / 2.0 if (ceu is not None and gbr is not None) else None
        s_eur = (tsi + ibs) / 2.0 if (tsi is not None and ibs is not None) else None

        asj_informative = asj is not None and nfe is not None and abs(asj - nfe) > SUBSET_THRESHOLD
        eur_axes = []
        if nwe is not None and s_eur is not None:
            eur_axes.append(abs(nwe - s_eur))
        if fin is not None and nwe is not None:
            eur_axes.append(abs(fin - nwe))
        if ibs is not None and tsi is not None:
            eur_axes.append(abs(ibs - tsi))
        if asj is not None and nfe is not None:
            eur_axes.append(abs(asj - nfe))
        eur_informative = any(d > SUBSET_THRESHOLD for d in eur_axes)

        if asj_informative:
            row["asj"] = True
            asj_flagged.append(rsid)
        if eur_informative:
            row["eur"] = True
            eur_flagged.append(rsid)
        out_markers.append(row)

    if len(asj_flagged) != 377:
        fail(f"ASJ founder subset should be 377 markers pre-dedup, computed {len(asj_flagged)}")

    # LCT-cluster dedup: keep the strongest |ASJ-NFE| member's flags only.
    by_rsid = {m["rsid"]: m for m in out_markers}
    cluster = [r for r in LCT_CLUSTER if r in by_rsid]
    if len(cluster) >= 2:
        def asj_delta(r):
            p = src_markers[r]["pops"]
            return abs(p.get("gnomad_asj", 0.0) - p.get("gnomad_nfe", 0.0))
        winner = max(cluster, key=asj_delta)
        for r in cluster:
            if r != winner:
                by_rsid[r].pop("asj", None)
                by_rsid[r].pop("eur", None)
    else:
        winner = cluster[0] if cluster else "none"

    asj_final = sum(1 for m in out_markers if m.get("asj"))
    eur_final = sum(1 for m in out_markers if m.get("eur"))

    # Orientation-preserving known-answer spot checks on the PRUNED data
    # (mirrors validate_panel.py's checks a): allele named explicitly,
    # frequency = AF if allele==alt else 1-AF.
    def freq_of(rsid, allele, col):
        m = by_rsid[rsid]
        v = m["af"][col]
        return v if allele == m["alt"] else (1.0 - v)

    if not freq_of("rs1426654", "A", "EUR") > 0.95:
        fail("known-answer: rs1426654 A should be >0.95 in EUR after pruning")
    if not freq_of("rs1426654", "A", "AFR") < 0.10:
        fail("known-answer: rs1426654 A should be <0.10 in AFR after pruning")
    if not freq_of("rs3827760", "G", "EAS") > 0.60:
        fail("known-answer: rs3827760 G should be >0.60 in EAS after pruning")
    if not freq_of("rs3827760", "G", "EUR") < 0.05:
        fail("known-answer: rs3827760 G should be <0.05 in EUR after pruning")
    if not freq_of("rs2814778", "C", "AFR") > 0.90:
        fail("known-answer: rs2814778 C should be >0.90 in AFR after pruning")

    palindromic = sum(1 for m in out_markers if {m["ref"], m["alt"]} in ({"A", "T"}, {"C", "G"}))

    src = prov.get("sources", {})
    ens = src.get("ensembl", {})
    gno = src.get("gnomad_graphql", {})
    payload = {
        "version": "1.0",
        "markerCount": len(out_markers),
        "populations": {
            "continental": ["AFR", "EUR", "EAS", "SAS", "AMR", "MID"],
            "withinEuropean": ["NWE", "TSI", "IBS", "FIN", "ASJ"],
        },
        "popSources": POP_SOURCES,
        "provenance": {
            "generated": prov.get("generated", ""),
            "generator": prov.get("generator", ""),
            "frequencyConvention": "every value is the ALT-allele frequency for the stated ref/alt pair",
            "sourceSummary": [
                f"1000 Genomes phase 3 via Ensembl REST ({ens.get('endpoint', 'rest.ensembl.org')}), release {','.join(str(r) for r in ens.get('ensembl_release', []) or ['116'])}, fetched {ens.get('fetched', '2026-08-13')}",
                f"gnomAD v4 genomes ({gno.get('endpoint', 'gnomad.broadinstitute.org GraphQL')}), fetched {gno.get('fetched', '2026-08-13')}",
                f"marker source breakdown: {json.dumps(prov.get('marker_source_breakdown', {}), sort_keys=True)}",
            ],
            "notes": [
                "Pruned at build time from the 43-column staging panel to the 12 population columns the offline AdmixtureEngine consumes; frequencies rounded to 4 decimals.",
                "NWE is the mean of 1000G CEU and GBR alt-allele frequencies.",
                f"Within-EUR informative subset (eur flag): |dAF| > {SUBSET_THRESHOLD} on any of NWE-vs-S-Europe, FIN-vs-NWE, IBS-vs-TSI, ASJ-vs-NFE; {eur_final} markers after LD dedup.",
                f"ASJ founder subset (asj flag): |ASJ-NFE| > {SUBSET_THRESHOLD}; 377 markers pre-dedup, {asj_final} after LD dedup.",
                f"LCT-region LD cluster {'/'.join(LCT_CLUSTER)}: subset flags kept only on {winner} so one haplotype cannot dominate the within-EUR or ASJ likelihoods.",
                f"{palindromic} palindromic (A/T or C/G) markers are shipped but are dropped by the engine at match time — strand orientation is never guessable for them from array data.",
                "This panel ships inside the app bundle; the app performs zero network access.",
            ],
        },
        "markers": out_markers,
    }

    OUT.write_text(json.dumps(payload, separators=(",", ":"), sort_keys=False) + "\n", encoding="utf-8")
    print(
        f"wrote {OUT} markers={len(out_markers)} eurSubset={eur_final} asjSubset={asj_final} "
        f"palindromic={palindromic} bytes={OUT.stat().st_size}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
