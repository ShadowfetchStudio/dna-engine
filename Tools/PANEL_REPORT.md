<!-- Validation + consumption contract for Resources/reference_panel.json
     (packaged by Tools/build_reference_panel.py). -->

# DNA Engine — Ancestry Reference Panel Validation Report

Generated 2026-08-13 by `validate_panel.py` against `reference_frequencies.json`
(2,621 markers, 0 fetch failures). Machine-readable results: `validate_results.json`.
Validation exit code: **0 — all known-answer checks pass.**

## Data file and schema

`reference_frequencies.json`:

```
{
  "provenance": { generated, generator, sources{ensembl, gnomad_graphql},
                  marker_source_breakdown, pop_key_legend,
                  frequency_convention, pop_marker_counts, dropped_rsids },
  "markers": {
    "<rsid>": {
      "ref": "<REF base>",
      "alt": "<ALT base>",
      "pops": { "<pop_key>": <alt-allele frequency, float 0..1>, ... },
      "sources": ["ensembl" and/or "gnomad_graphql"]
    }, ...
  }
}
```

Population keys (43 total per marker, near-complete coverage):

- **1000 Genomes phase 3 (via Ensembl REST, release 116)** — 26 populations as bare
  codes (`ACB ASW BEB CDX CEU CHB CHS CLM ESN FIN GBR GIH GWD IBS ITU JPT KHV LWK
  MSL MXL PEL PJL PUR STU TSI YRI`) plus superpops `AFR AMR EAS EUR SAS` and `ALL`.
- **gnomAD (gnomADg via Ensembl + gnomad_r4 GraphQL fill-in)** — prefixed keys:
  `gnomad_afr gnomad_amr gnomad_asj gnomad_eas gnomad_fin gnomad_mid gnomad_nfe
  gnomad_sas gnomad_ami gnomad_remaining gnomad_ALL`.

**Frequency convention (critical for the wiring phase):** every stored value is the
**ALT-allele frequency** for the stated `ref`/`alt` pair. Nothing is pre-oriented to
"derived" or "minor" — consumers must orient against the genotype's alleles using
`ref`/`alt`. Example: rs1426654 is stored ref=A/alt=G, so the European-fixed light-skin
allele A has frequency `1 - AF`.

Every marker carries a `sources` array; per-source endpoints, fetch dates, and release
versions are in `provenance.sources`. 2,608 markers are Ensembl-only, 13 came from both
Ensembl and the gnomAD GraphQL fill-in, 0 were dropped.

## (a) Known-answer sanity checks — 5/5 PASS

Checks are orientation-aware (allele named explicitly, frequency computed as AF if
allele==alt, 1−AF if allele==ref).

| Check | Result | Observed |
|---|---|---|
| rs1426654 (SLC24A5) A allele >0.95 in CEU/GBR/TSI/IBS/FIN, <0.10 in YRI | PASS | CEU 1.000, GBR 1.000, TSI 0.995, IBS 1.000, FIN 0.990; YRI 0.014 |
| rs3827760 (EDAR V370A) G allele >0.60 in all 5 EAS pops, <0.05 in CEU/GBR/TSI/IBS | PASS | CHB 0.937, JPT 0.803, CHS 0.905, CDX 0.898, KHV 0.823; EUR all 0.000 |
| rs2814778 (Duffy-null) C allele >0.95 in YRI/ESN/GWD/MSL, <0.05 in CEU/GBR | PASS | YRI 0.995, ESN 1.0, GWD 1.0, MSL 1.0; CEU/GBR 0.000 |
| rs4988235 (LCT) persistence allele >0.60 in GBR & CEU, <0.20 in TSI, TSI < CEU | PASS | GBR 0.720, CEU 0.737, TSI 0.089 |
| rs12913832 (HERC2) blue-eye G gradient: min(FIN,GBR,CEU) > max(TSI,IBS); YRI <0.05 | PASS | FIN 0.909 > GBR 0.819 > CEU 0.768 > TSI 0.421 > IBS 0.322; YRI 0.000 |

The rs4988235 result (CEU 0.737 vs TSI 0.089, Δ=0.65) specifically confirms the panel
powers the North-vs-South Europe axis; rs12913832 confirms the full N→S gradient
including FIN at the top.

## (b) Informativeness (per-marker |ΔAF| and Hudson Fst)

n = markers with both sides available. Counts are markers exceeding the |ΔAF| threshold.

| Axis | n | mean&#124;Δ&#124; | mean Fst | &#124;Δ&#124;>0.1 | >0.2 | >0.5 |
|---|---|---|---|---|---|---|
| EUR vs AFR | 2621 | 0.225 | 0.159 | 1873 | 1181 | 213 |
| EUR vs EAS | 2621 | 0.187 | 0.119 | 1714 | 1015 | 77 |
| EUR vs SAS | 2621 | 0.104 | 0.042 | 1201 | 289 | 7 |
| NW-Europe (CEU+GBR) vs S-Europe (TSI+IBS) | 2621 | 0.041 | 0.008 | 102 | 8 | 0 |
| FIN vs NW-Europe | 2621 | 0.057 | 0.013 | 439 | 11 | 0 |
| IBS vs TSI | 2621 | 0.040 | 0.007 | 168 | 3 | 0 |
| **ASJ vs NFE (gnomAD)** | 2615 | 0.057 | 0.014 | **377** | 22 | 3 |
| MID vs NFE (gnomAD) | 2615 | 0.072 | 0.023 | 685 | 65 | 6 |

Interpretation, honestly stated:

- **Continental axes are very strong** (hundreds of markers with Δ>0.5 on EUR/AFR).
  Continental % estimates will be robust.
- **Sub-European axes are individually weak but collectively adequate** — this mirrors
  real population genetics (intra-European Fst ≈ 0.001–0.01). No single marker separates
  CEU from TSI; the signal is the *aggregate* of 102–439 markers with Δ>0.1 per axis.
  Expect resolution at the level of "Southern-European-like vs NW-European vs Finnish vs
  Iberian-leaning", not confident country calls.
- **Ashkenazi founder-signal: 377 markers with |ASJ−NFE| > 0.1** (22 above 0.2). That is
  a genuinely usable aggregate signal for the Ashkenazi (ASJ) axis, with the caveat
  that ASJ separates from NFE mostly by many small shifts, and the top ASJ separators
  (rs182549/rs4988235 LCT region, rs6754311) are also N-vs-S Europe markers — the model
  must fit ASJ *jointly* with S-Europe, not marginally, or Southern-European ancestry
  will masquerade as ASJ (and vice versa).
- gnomAD **MID** has modest sample size; treat MID as supporting evidence, not a primary
  call.
- Top continental discriminators recovered are the canonical AIMs (rs1871534, rs2814778,
  rs1426654, rs1834640, rs16891982, rs3827760) — an independent confirmation that the
  fetched frequencies are real.

## (c) Coverage

43 population keys tracked; 2,621 markers total. **No population falls below the
500-usable-marker floor — flag list is empty.** Worst coverage is 2,613/2,621
(gnomad_ALL); all 26 1000G pops + 5 superpops are at 2,620–2,621. Full matrix in
`validate_results.json` (`coverage_counts`) and `provenance.pop_marker_counts`.

## (d) Chip overlap (worked example)

`chip_rsids.txt` has 1,974 lines = **174 real rsids + 1,800 synthetic `rs9000xxxx`
placeholder lines** (a stand-in block, not real dbSNP ids — they resolve to nothing and
must not be counted).

- Usable overlap: **168 of 174 real chip rsids (96.6%) are in the panel** with full
  frequency vectors.
- The 6 real chip rsids not in the panel: rs113851554, rs1799963 (prothrombin), rs328
  (LPL), rs4986893 (CYP2C19*3), rs6025 (Factor V Leiden), rs7454108 — all
  clinical/pharmacogenomic variants with no ancestry signal; correct to exclude.
- **Honest caveat for the wiring phase:** 174 rsids is a small extract, so today's
  ancestry-usable count is 168 markers — enough for confident continental % and a
  meaningful (not fine-grained) ASJ/S-Europe read, but thin for the sub-European axes.
  The panel itself holds 2,621 markers; when a full consumer raw-DNA array is
  loaded, recompute overlap (a full array should intersect far more of the panel).

## Wiring-phase consumption notes (likelihood model)

1. **Genotype orientation first.** For each chip genotype at rsid r with panel entry
   (ref, alt): count alt alleles g ∈ {0,1,2}. If the chip reports the complementary
   strand, flip bases before matching; discard A/T and C/G markers on strand-ambiguity
   *only if* the chip's strand convention is unknown (the panel stores ref/alt on the
   forward strand as per Ensembl).
2. **Per-population log-likelihood.** For population k with alt-AF p (clamped to
   [ε, 1−ε], ε ≈ 1e-3, to avoid −∞ from fixed alleles — many 0.0/1.0 values exist,
   e.g. rs2814778 GWD=1.0): binomial `logL += g·ln p + (2−g)·ln(1−p)`, summed over
   markers where population k has a value (`pops.get(k)` may be missing for ≤8 markers
   in gnomAD keys — skip, don't impute).
3. **Admixture rather than argmax.** Single-population argmax will misbehave for admixed
   users. Model genotype AF as a mixture `p_i = Σ_k w_k · p_{ik}` over a chosen
   reference set (e.g. the 26 1000G pops, or a curated subset + gnomad_asj) and maximize
   over the simplex (EM or projected gradient — this is supervised ADMIXTURE / summary-
   statistic style). Report w as the ancestry %.
4. **Two-tier output.** Tier 1: continental (AFR/EUR/EAS/SAS/AMR components — use 1000G
   pops grouped by superpop). Tier 2: within-Europe run on the European component only,
   with reference columns CEU/GBR, TSI, IBS, FIN + `gnomad_asj` — the axes measured in
   (b). Fit ASJ jointly with TSI/IBS (see the confounding note above).
5. **Independence caveat.** The binomial model assumes unlinked markers. The panel was
   window-sampled so LD is mostly controlled, but the LCT region contributes several
   correlated top markers (rs4988235/rs182549/rs6754311) — either keep one per LD block
   for the likelihood, or downweight duplicates; do not let one haplotype dominate the
   N-vs-S or ASJ score.
6. **Uncertainty honesty in the UI.** Sub-European and ASJ calls should ship with
   confidence intervals (e.g. block-bootstrap over markers). With only 168 chip-usable
   markers today, intervals will be wide — show them.
7. **Provenance passthrough.** Each marker's `sources` + `provenance.sources` (endpoint,
   release, fetch date) should be carried into the app bundle so results screens can
   cite "1000 Genomes phase 3 via Ensembl release 116, fetched 2026-08-13; gnomAD v4".
   The app remains offline: this JSON is the only data it needs.

## Files

- `reference_frequencies.json` — the frequency source consumed by `build_reference_panel.py`
- `validate_panel.py` — this validation (exit 0 = all known-answer checks pass)
- `validate_results.json` — machine-readable results
- `validate_stdout.txt` — run transcript
