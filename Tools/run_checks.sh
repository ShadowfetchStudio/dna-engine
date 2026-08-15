#!/bin/bash
# DNA Engine deterministic check harness (feature 2).
#
#   Tools/run_checks.sh                 run every check
#   UPDATE_EXPECTED=1 Tools/run_checks.sh   regenerate Tools/expected_checks.json
#                                           (review the diff before committing!)
#
# Steps:
#   1. generator + lints (must pass), lint SELF-TEST (broken fixture must fail)
#   2. knowledge.json content assertions (count, honesty schema, no LOC*)
#   3. compile the UI-free check CLI (any SwiftUI import in an engine file breaks this)
#   4. backward-compat decode of the pre-2.0 fixture knowledge.json
#   5. demo determinism (two runs byte-identical) + corruption canary
#   6. full report diff against expected_checks.json
#   7. compound/PGx parity vs the pre-migration Swift snapshot
#   8. independent Python recomputation of HWE calibration (1e-9)
#   9. QC fixtures (truncated chromosome; zero-ROH)
#  10. erase regression test (leftover-Reports bug)
#  11. static greps: networking symbols, dead constants, dosing verbs
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOOLS="$ROOT/Tools"
BUILD_DIR="${TMPDIR:-/tmp}/dnaengine-checks"
mkdir -p "$BUILD_DIR"
CLI="$BUILD_DIR/dnacheck"
FAILURES=0

cd "$ROOT"

step() { printf '\n== %s\n' "$1"; }
ok()   { printf '   ok: %s\n' "$1"; }
bad()  { printf '   FAIL: %s\n' "$1"; FAILURES=$((FAILURES + 1)); }

# ------------------------------------------------------------------ 1. generator
step "generator + lints"
if python3 "$TOOLS/generate_knowledge.py" > "$BUILD_DIR/gen.log" 2>&1; then
  ok "generate_knowledge.py exit 0 ($(tail -1 "$BUILD_DIR/gen.log"))"
else
  bad "generate_knowledge.py failed:"; cat "$BUILD_DIR/gen.log"
fi

step "lint self-test (broken fixture module must make the generator exit nonzero)"
if GEN_INCLUDE_BROKEN_FIXTURE=1 python3 "$TOOLS/generate_knowledge.py" > "$BUILD_DIR/gen_broken.log" 2>&1; then
  bad "generator ACCEPTED the deliberately broken fixture — lint has no teeth"
else
  ok "broken fixture rejected (exit nonzero)"
fi
# the broken run must not have poisoned knowledge.json
python3 "$TOOLS/generate_knowledge.py" > /dev/null 2>&1

# ------------------------------------------------- 1b. ancestry reference panel
step "ancestry reference panel packaging + content assertions"
if python3 "$TOOLS/build_reference_panel.py" > "$BUILD_DIR/panel.log" 2>&1; then
  ok "build_reference_panel.py exit 0 ($(tail -1 "$BUILD_DIR/panel.log"))"
else
  bad "build_reference_panel.py failed:"; cat "$BUILD_DIR/panel.log"
fi
python3 - "$ROOT/Resources/reference_panel.json" <<'PYEOF' && ok "panel content assertions" || bad "panel content assertions"
import json, sys
d = json.load(open(sys.argv[1]))
markers = d["markers"]
assert d["markerCount"] == len(markers) == 2621, f"marker count {len(markers)} != 2621"
cols = {"AFR","EUR","EAS","SAS","AMR","MID","NWE","TSI","IBS","FIN","ASJ","NFE"}
assert set(d["populations"]["continental"]) == {"AFR","EUR","EAS","SAS","AMR","MID"}
assert set(d["populations"]["withinEuropean"]) == {"NWE","TSI","IBS","FIN","ASJ"}
assert set(d["popSources"]) == cols, "popSources must cite every shipped column"
assert d["provenance"].get("sourceSummary") and d["provenance"].get("generated"), "provenance must survive pruning"
rsids = [m["rsid"] for m in markers]
assert rsids == sorted(rsids) and len(set(rsids)) == len(rsids), "markers must be rsid-sorted and unique (demo RNG stream depends on it)"
eur = asj = 0
for m in markers:
    assert m["ref"] in "ACGT" and m["alt"] in "ACGT" and m["ref"] != m["alt"], m["rsid"]
    assert set(m["af"]) <= cols, f"{m['rsid']}: stray population column"
    assert all(0.0 <= v <= 1.0 for v in m["af"].values()), f"{m['rsid']}: AF outside [0,1]"
    assert {"AFR","EUR","EAS","SAS","AMR"} <= set(m["af"]), f"{m['rsid']}: missing 1000G superpop"
    eur += 1 if m.get("eur") else 0
    asj += 1 if m.get("asj") else 0
assert 800 <= eur <= 1000, f"within-EUR subset drifted: {eur}"
assert asj == 375, f"ASJ founder subset must be 375 after LCT-cluster dedup, got {asj}"
lct_flagged = [r for r in ("rs4988235","rs182549","rs6754311")
               if next(m for m in markers if m["rsid"] == r).get("asj")]
assert len(lct_flagged) == 1, f"LCT LD cluster must keep exactly one flagged member, got {lct_flagged}"
print(f"  2621 markers, eur subset {eur}, asj subset {asj}, LCT representative {lct_flagged[0]}")
PYEOF

# ------------------------------------------------------------- 2. content checks
step "knowledge.json content assertions"
python3 - "$ROOT/Resources/knowledge.json" <<'PYEOF' && ok "content assertions" || bad "content assertions"
import json, sys
d = json.load(open(sys.argv[1]))
markers = d["markers"]
assert len(markers) >= 400, f"marker count {len(markers)} < 400"
missing_cit = [m["rsid"] for m in markers if not m.get("citations")]
missing_tier = [m["rsid"] for m in markers if not m.get("tier")]
missing_chips = [m["rsid"] for m in markers if not m.get("chips")]
assert not missing_cit, f"markers missing citations: {missing_cit[:5]}"
assert not missing_tier, f"markers missing tier: {missing_tier[:5]}"
assert not missing_chips, f"markers missing chips: {missing_chips[:5]}"
loc = [m["rsid"] for m in markers if m["gene"].upper().startswith("LOC")]
loc += [a["rsid"] for a in d["aims"] if a["gene"].upper().startswith("LOC")]
assert not loc, f"LOC placeholder genes remain: {loc}"
assert all(p.get("calibration") for p in d["scores"]), "panel missing calibration"
assert all(g.get("undetectable") for g in d["pgx"]), "pgx gene missing undetectable list"
marker_by = {m["rsid"]: m for m in markers}
neutral_mechanism = "Published marker context only. DNA Engine does not translate this consumer-array genotype into enzyme activity, biological function, phenotype, diagnosis, risk, or a personal outcome."
neutral_label = "Research locus observed"
neutral_summary = "Raw genotype recorded at this catalog locus. No genotype-to-outcome label or quantitative biological effect is inferred."
neutral_detail = "Identifiers, coverage, evidence tier, transferability, and citations are provided for independent research; the genotype is not a personalized interpretation."
for marker in markers:
    assert marker["mechanism"] == neutral_mechanism, marker["rsid"]
    assert marker.get("effect") is None, marker["rsid"]
    assert not marker.get("notes"), marker["rsid"]
    for genotype, observation in marker["genotypes"].items():
        assert observation == {
            "label": neutral_label,
            "impact": "typical",
            "summary": neutral_summary,
            "detail": neutral_detail,
            "actions": {},
        }, (marker["rsid"], genotype, observation)
for rsid in ("rs1801133", "rs7501331"):
    marker = marker_by[rsid]
    assert marker["citations"], f"{rsid}: reference provenance lost"
    assert marker["alleleA"] and marker["alleleB"] and marker["chips"], f"{rsid}: locus/coverage metadata lost"
neutral_compound_value = "Research rule coverage only"
neutral_compound_detail = "Referenced loci are retained for research provenance. No genotype-derived activity, phenotype, diagnosis, risk, sensitivity, or personal outcome is inferred."
for compound in d["compounds"]:
    outcomes = [compound["fallback"]] + compound.get("rules", []) + compound.get("bands", [])
    if compound.get("partial"):
        outcomes.append(compound["partial"])
    assert compound.get("caveat") == neutral_compound_detail, compound["id"]
    assert all(o.get("value") == neutral_compound_value and o.get("detail") == neutral_compound_detail and o.get("impact") == "typical" for o in outcomes), compound["id"]
    pal = [r for r in compound["rsids"] if r in marker_by and
           {marker_by[r]["alleleA"], marker_by[r]["alleleB"]} in ({"A", "T"}, {"C", "G"})]
    if pal:
        assert set(pal) <= set(compound.get("requireTyped") or []), f"{compound['id']}: palindromic loci not required"
        assert compound.get("partial", {}).get("value") == neutral_compound_value, \
            f"{compound['id']}: no explicit unresolved outcome"
for gene in d["pgx"]:
    assert gene.get("wildActivity") == 0.0, gene["gene"]
    assert gene.get("phenotypeBands") == [], gene["gene"]
    assert all(a.get("activity") == 0.0 for a in gene.get("alleles", []) + gene.get("subtractAlleles", [])), gene["gene"]
assert all(l.get("category") and l.get("explanation") and l.get("pmidNote") for l in d["limitations"]), "limitation missing fields"
assert d.get("demo"), "demo persona missing"
print(f"  {len(markers)} markers, {len(d['aims'])} aims, {len(d['scores'])} panels, {len(d['compounds'])} compounds, {len(d['pgx'])} pgx genes")
PYEOF

# ------------------------------------------------------------------ 3. compile
step "compile UI-free check CLI"
ENGINE_FILES=(
  Sources/Models.swift Sources/Paths.swift Sources/KnowledgeBase.swift
  Sources/GenomeImportFoundation.swift Sources/GenomeParser.swift
  Sources/DemoGenome.swift Sources/AnalysisEngine.swift
  Sources/CompoundTraits.swift Sources/PharmacogenomicsEngine.swift
  Sources/ROHScanner.swift Sources/QCEngine.swift Sources/AncestryEstimator.swift
  Sources/ReferencePanel.swift Sources/AdmixtureEngine.swift
  Sources/ComparisonEngine.swift Sources/LifestyleEngine.swift Sources/PathwaysEngine.swift
  Sources/HonestyEngine.swift Sources/HeadlineBuilder.swift Sources/ReportExport.swift
)
for f in "${ENGINE_FILES[@]}"; do
  if grep -q "import SwiftUI\|import AppKit" "$ROOT/$f"; then
    bad "$f imports SwiftUI/AppKit — engines must stay UI-free"
  fi
done
# -O matches the app build and keeps the admixture bootstrap fast (~0.3s vs
# ~35s at -Onone). Swift does no unsafe FP reassociation: the report output
# was verified byte-identical across -O and -Onone when 2.1 landed.
if swiftc -O -target arm64-apple-macos14.0 -parse-as-library \
    "${ENGINE_FILES[@]/#/$ROOT/}" "$TOOLS/CheckMain.swift" -o "$CLI" > "$BUILD_DIR/swiftc.log" 2>&1; then
  ok "swiftc -O"
else
  bad "swiftc failed:"; tail -20 "$BUILD_DIR/swiftc.log"; exit 1
fi

# ---------------------------------------------- 3b. safe parser/import receipts
step "safe parser/import foundation — archives, VCF semantics, receipts"
if "$CLI" parser-checks "$TOOLS/fixtures/parser_multisample.vcf" > "$BUILD_DIR/parser_checks.json" 2> "$BUILD_DIR/parser_checks.err"; then
  python3 - "$BUILD_DIR/parser_checks.json" <<'PYEOF' && ok "bounded archives + VCF sample/accounting checks" || bad "parser receipt assertions"
import json, sys
d = json.load(open(sys.argv[1]))
v = d["vcf"]
assert v == {
    "accepted": 3, "conflict": 1, "defaultSample": "Alpha", "duplicate": 1,
    "explicitSample": "Beta", "filtered": 1, "malformed": 1, "noCall": 1,
    "reconciles": True, "skipped": 7, "total": 10, "unsupported": 4,
}, v
a = d["archives"]
assert a["gzip"] == a["zip"] == "validated"
assert a["signatureDetection"] is True
assert a["inMemoryGzip"] is True and a["inMemoryZip"] is True
assert a["singleMember"] == "genome.txt"
assert all(d["rejections"].values()), d["rejections"]
print("  signature-detected gzip/zip (file + memory); hostile, multi-entry, oversize, corrupt and concatenated rejected")
PYEOF
else
  bad "safe parser/import checks failed:"
  cat "$BUILD_DIR/parser_checks.err"
fi

# ------------------------------------------------------- 4. decode compatibility
step "knowledge decode — current + pre-2.0 fixture (optional-field back-compat)"
if "$CLI" decode "$ROOT/Resources/knowledge.json" > "$BUILD_DIR/decode_now.json" 2>&1; then
  ok "current knowledge.json decodes"
else
  bad "current knowledge.json failed to decode"
fi
if "$CLI" decode "$TOOLS/fixtures/knowledge_pre_upgrade.json" > "$BUILD_DIR/decode_pre.json" 2>&1; then
  ok "pre-upgrade fixture decodes (optional fields are truly optional)"
else
  bad "PRE-UPGRADE fixture failed to decode — a stale cached knowledge.json would crash the app"
fi

# ------------------------------------------------------------- 5. determinism
step "demo determinism"
"$CLI" demo-text > "$BUILD_DIR/demo1.txt" 2>/dev/null
"$CLI" demo-text > "$BUILD_DIR/demo2.txt" 2>/dev/null
if cmp -s "$BUILD_DIR/demo1.txt" "$BUILD_DIR/demo2.txt"; then
  ok "demo genome byte-identical across runs ($(wc -l < "$BUILD_DIR/demo1.txt" | tr -d ' ') rows)"
else
  bad "demo genome NOT deterministic"
fi
"$CLI" report > "$BUILD_DIR/report1.json" 2>/dev/null
"$CLI" report > "$BUILD_DIR/report2.json" 2>/dev/null
if cmp -s "$BUILD_DIR/report1.json" "$BUILD_DIR/report2.json"; then
  ok "check report byte-identical across runs"
else
  bad "check report NOT deterministic"
fi
# Corruption canary: flipping one genotype must change the observation receipt
# without producing a phenotype or medication action.
sed 's/^rs4244285	\([^	]*\)	\([^	]*\)	A	G$/rs4244285	\1	\2	G	G/' "$BUILD_DIR/demo1.txt" > "$BUILD_DIR/demo_corrupt.txt"
if cmp -s "$BUILD_DIR/demo1.txt" "$BUILD_DIR/demo_corrupt.txt"; then
  bad "corruption canary setup failed (sed did not change the file)"
else
  "$CLI" pgx-of "$BUILD_DIR/demo1.txt" > "$BUILD_DIR/pgx_clean.json" 2>/dev/null
  "$CLI" pgx-of "$BUILD_DIR/demo_corrupt.txt" > "$BUILD_DIR/pgx_corrupt.json" 2>/dev/null
  python3 - "$BUILD_DIR/pgx_clean.json" "$BUILD_DIR/pgx_corrupt.json" <<'PYEOF' && ok "corrupting one genotype changes the CYP2C19 observation receipt" || bad "corrupted genotype did NOT change the observation receipt"
import json, sys
clean = json.load(open(sys.argv[1]))
corrupt = json.load(open(sys.argv[2]))
assert clean["rs4244285"]["genotype"] == "A/G", clean["rs4244285"]
assert corrupt["rs4244285"]["genotype"] == "G/G", corrupt["rs4244285"]
assert clean["rs4244285"]["status"] == corrupt["rs4244285"]["status"] == "Observed"
PYEOF
fi

# ------------------------------------------------------------ 6. expected diff
step "report vs expected_checks.json"
if [ "${UPDATE_EXPECTED:-0}" = "1" ]; then
  cp "$BUILD_DIR/report1.json" "$TOOLS/expected_checks.json"
  ok "expected_checks.json REGENERATED — review the diff"
elif [ -f "$TOOLS/expected_checks.json" ]; then
  if diff -u "$TOOLS/expected_checks.json" "$BUILD_DIR/report1.json" > "$BUILD_DIR/expected.diff"; then
    ok "report matches expected_checks.json"
  else
    bad "report diverges from expected_checks.json:"; cat "$BUILD_DIR/expected.diff" | head -60
  fi
else
  bad "Tools/expected_checks.json missing — run UPDATE_EXPECTED=1 once"
fi

# ----------------------------------------------------- 6b. ancestry assertions
step "ancestry admixture on the demo persona (deterministic seeds)"
python3 - "$BUILD_DIR/report1.json" <<'PYEOF' && ok "demo admixture recovers the seeded 70/20/10 mixture with honest CIs" || bad "demo admixture assertions failed"
import json, sys
rep = json.load(open(sys.argv[1]))
adm = rep["admixture"]
assert not adm.get("panelMissing"), "reference panel missing from the CLI run"
assert adm["insufficient"] is False
assert adm["markersTotal"] == 2621
assert adm["markersUsed"] >= 2000, f"demo should intersect nearly the whole panel, used {adm['markersUsed']}"
assert adm["palindromicDropped"] >= 300, "palindromic drop path unexercised"
cont = adm["continental"]
shares = {k: v["share"] for k, v in cont.items()}
total = sum(shares.values())
assert abs(total - 1.0) < 0.01, f"continental shares sum {total}"
# The demo persona is seeded 70/20/10 east-asian/european/african.
assert 0.55 <= shares["EAS"] <= 0.85, f"EAS {shares['EAS']}"
assert 0.08 <= shares["EUR"] <= 0.32, f"EUR {shares['EUR']}"
assert 0.02 <= shares["AFR"] <= 0.20, f"AFR {shares['AFR']}"
for pop, v in cont.items():
    assert v["lo"] - 1e-9 <= v["share"] <= v["hi"] + 1e-9, f"{pop}: point outside its own CI"
    assert 0.0 <= v["lo"] <= v["hi"] <= 1.0, f"{pop}: malformed CI"
# Tier 2 runs on the demo (EUR ~0.2 clears the 12% floor) and must disclose blur.
assert adm["tier2Applicable"] is True
assert adm["tier2Used"] >= 500, f"tier2 used {adm['tier2Used']}"
eur_sum = sum(v["share"] for v in adm["withinEuropean"].values())
assert abs(eur_sum - shares["EUR"]) < 0.01, f"within-EUR shares must sum to the EUR component ({eur_sum} vs {shares['EUR']})"
asj = adm["asj"]
assert asj["band"] in ("none-detected", "possible"), f"demo (no ASJ seeded) banded {asj['band']}"
assert asj["used"] >= 300, f"ASJ founder markers used {asj['used']}"
assert asj["total"] == 375
print(f"  EAS {shares['EAS']:.3f} EUR {shares['EUR']:.3f} AFR {shares['AFR']:.3f} | markers {adm['markersUsed']}/2621 | tier2 {adm['tier2Used']} | ASJ band {asj['band']}")
PYEOF

# --------------------------------- 6c. independent admixture EM recomputation
step "independent Python EM recomputation (Swift vs Python, main fits)"
python3 - "$ROOT/Resources/reference_panel.json" "$BUILD_DIR/demo1.txt" "$BUILD_DIR/report1.json" <<'PYEOF' && ok "admixture EM independently reproduced" || bad "admixture EM drift between Swift and Python"
import json, math, sys

# Mirrors AdmixtureEngine EXACTLY (constants + loop order). Change both together.
AF_CLAMP = 1e-3
EM_ITERS = 300
CONT = ["AFR", "EUR", "EAS", "SAS", "AMR", "MID"]
EURP = ["NWE", "TSI", "IBS", "FIN", "ASJ"]
FIXED = ["AFR", "EAS", "SAS", "AMR", "MID"]
COMP = {"A": "T", "T": "A", "C": "G", "G": "C"}

panel = json.load(open(sys.argv[1]))
calls = {}
for line in open(sys.argv[2]):
    if line.startswith("#"):
        continue
    f = line.rstrip("\n").split("\t")
    if len(f) == 5:
        calls[f[0]] = (f[3], f[4])

def dosage(gt, ref, alt):
    pair = {ref, alt}
    if pair in ({"A", "T"}, {"C", "G"}):
        return "palindromic"
    a = [gt[0], gt[1]]
    if a[0] in "0-DI" or a[1] in "0-DI":
        return None
    if all(x in pair for x in a):
        return sum(1 for x in a if x == alt)
    fl = [COMP.get(x, x) for x in a]
    if all(x in pair for x in fl):
        return sum(1 for x in fl if x == alt)
    return "mismatch"

clamp = lambda v: min(max(v, AF_CLAMP), 1.0 - AF_CLAMP)
t1 = []   # (g, [af x6])
t2 = []   # (g, [af x10])
asj = []  # (g, pASJ, pNFE)
for m in panel["markers"]:
    gt = calls.get(m["rsid"])
    if gt is None:
        continue
    d = dosage(gt, m["ref"], m["alt"])
    if d in ("palindromic", "mismatch", None):
        continue
    af = m["af"]
    if all(p in af for p in CONT):
        t1.append((float(d), [clamp(af[p]) for p in CONT]))
    if m.get("eur") and all(p in af for p in EURP + FIXED):
        t2.append((float(d), [clamp(af[p]) for p in EURP + FIXED]))
    if m.get("asj") and "ASJ" in af and "NFE" in af:
        asj.append((float(d), clamp(af["ASJ"]), clamp(af["NFE"])))

def em(obs, k, free, budget, w0):
    w = list(w0)
    for _ in range(EM_ITERS):
        acc = [0.0] * free
        for g, af in obs:
            p = 0.0
            for j in range(k):
                p += w[j] * af[j]
            q = 1.0 - p
            for j in range(free):
                pj = af[j]
                acc[j] += g * (w[j] * pj / p) + (2.0 - g) * (w[j] * (1.0 - pj) / q)
        s = sum(acc)
        if s <= 0:
            break
        for j in range(free):
            w[j] = budget * acc[j] / s
    return w

rep = json.load(open(sys.argv[3]))
adm = rep["admixture"]

w1 = em(t1, 6, 6, 1.0, [1.0 / 6] * 6)
for j, pop in enumerate(CONT):
    swift = adm["continental"][pop]["share"]
    assert abs(w1[j] - swift) <= 6e-5, f"tier1 {pop}: python {w1[j]:.6f} vs swift {swift}"

fixed_w = [w1[CONT.index(p)] for p in FIXED]
budget = 1.0 - sum(fixed_w)
w0 = [budget / 5] * 5 + fixed_w
w2 = em(t2, 10, 5, budget, w0)
for j, pop in enumerate(EURP):
    swift = adm["withinEuropean"][pop]["share"]
    assert abs(w2[j] - swift) <= 6e-5, f"tier2 {pop}: python {w2[j]:.6f} vs swift {swift}"

llr = 0.0
for g, pa, pn in asj:
    llr += g * math.log(pa / pn) + (2.0 - g) * math.log((1.0 - pa) / (1.0 - pn))
assert abs(llr - adm["asj"]["llr4"]) <= 1e-3, f"ASJ LLR python {llr:.4f} vs swift {adm['asj']['llr4']}"
assert len(t1) == adm["markersUsed"], f"tier1 marker set python {len(t1)} vs swift {adm['markersUsed']}"
assert len(t2) == adm["tier2Used"]
assert len(asj) == adm["asj"]["used"]
print(f"  tier1 {len(t1)} markers, tier2 {len(t2)}, asj {len(asj)}: EM shares agree to 6e-5, LLR to 1e-3")
PYEOF

# ---------------------------------------------------- 7. reviewed migration diff
step "compound fail-closed diff + PGx research migration"
python3 - "$TOOLS/fixtures/parity_pre_migration.json" "$BUILD_DIR/report1.json" "$ROOT/Resources/knowledge.json" "$BUILD_DIR/demo1.txt" <<'PYEOF' && ok "reviewed scientific-truthfulness migration holds" || bad "truthfulness migration assertions failed"
import json, sys
pre = json.load(open(sys.argv[1]))
now = json.load(open(sys.argv[2]))
kb = json.load(open(sys.argv[3]))
demo_calls = {}
for line in open(sys.argv[4]):
    if line.startswith("#"):
        continue
    fields = line.rstrip("\n").split("\t")
    if len(fields) == 5:
        demo_calls[fields[0]] = fields[3:5]

# Every catalog PGx gene is present as observations, never a phenotype/alert.
obs = now["pgxObservations"]
assert set(obs) == {g["gene"] for g in kb["pgx"]}
assert now["reportChecks"]["pgxNoPhenotypeCalls"] is True
assert now["reportChecks"]["pgxNoAlerts"] is True
assert now["reportChecks"]["cyp2c19CompleteDefiningLoci"] is True
assert now["reportChecks"]["coverageBucketsExplicit"] is True
assert now["reportChecks"]["markerDetailsNonDirective"] is True
assert now["reportChecks"]["demoActivityMarkersRetained"] is True
assert now["reportChecks"]["demoActivityClaimsWithheld"] is True
assert now["reportChecks"]["allSingleMarkerOutcomesWithheld"] is True
assert now["reportChecks"]["demoActivityReportReceiptsOnly"] is True
assert now["headlines"]["compoundFindings"] == 0

# Present-but-unresolved calls must never be counted as absent from the chip.
assert now["coverage"]["strandAmbiguous"] == len(now["strandAmbiguous"])
assert now["coverage"]["strandAmbiguous"] == now["honesty"]["strandAmbiguousMarkerCount"]
assert sum(now["coverage"].values()) == len(kb["markers"])

# Palindromic PGx definitions must be explicitly unresolved.
for gene in kb["pgx"]:
    by = {x["rsid"]: x for x in obs[gene["gene"]]["loci"]}
    for allele in gene["alleles"] + gene.get("subtractAlleles", []):
        if {allele["referenceAllele"], allele["variantAllele"]} in ({"A", "T"}, {"C", "G"}):
            assert by[allele["rsid"]]["status"] == "Strand unresolved", (gene["gene"], allele["rsid"], by[allele["rsid"]])

# All compound outputs are non-interpretive coverage receipts. Palindromic
# inputs remain withheld independently by the marker layer.
markers = {m["rsid"]: m for m in kb["markers"]}
pal_markers = {
    rsid for rsid, marker in markers.items()
    if {marker["alleleA"], marker["alleleB"]} in ({"A", "T"}, {"C", "G"})
}
assert pal_markers <= set(now["strandAmbiguous"]), "a palindromic marker did not fail closed"

# Polygenic used-counts must exclude every palindromic score locus while still
# accounting normally for non-palindromic called loci.
for panel in kb["scores"]:
    expected_used = sum(
        1 for snp in panel["snps"]
        if snp["rsid"] in demo_calls
        and snp["rsid"] not in pal_markers
        and all(a not in ("0", "-", "D", "I") for a in demo_calls[snp["rsid"]])
    )
    assert now["panels"][panel["id"]]["used"] == expected_used, \
        (panel["id"], now["panels"][panel["id"]]["used"], expected_used)

assert set(now["compounds"]) == {c["id"] for c in kb["compounds"]}
assert all(
    c["value"] == "Research rule coverage only" and c["impact"] == "typical"
    for c in now["compounds"].values()
)
print(f"  {len(obs)} PGx genes observation-only; {len(now['compounds'])} compound rules coverage-only")
PYEOF

# ------------------------------------------------ 8. independent HWE cross-check
step "independent HWE calibration recomputation (Python vs Swift, 1e-9)"
python3 - "$ROOT/Resources/knowledge.json" "$BUILD_DIR/report1.json" <<'PYEOF' && ok "HWE math agrees" || bad "HWE math drift"
import json, sys, math
kb = json.load(open(sys.argv[1]))
rep = json.load(open(sys.argv[2]))
checked = 0
for panel in kb["scores"]:
    swift = rep["calibDebug"][panel["id"]]
    for pop, cal in panel["calibration"].items():
        mean = sum(2 * min(max(s["freq"][pop], 1e-4), 1 - 1e-4) * s["weight"] for s in panel["snps"])
        var = sum(2 * (p := min(max(s["freq"][pop], 1e-4), 1 - 1e-4)) * (1 - p) * s["weight"] ** 2 for s in panel["snps"])
        sd = math.sqrt(var)
        # generator-baked values
        assert abs(cal["mean"] - mean) < 1e-9, f"{panel['id']}/{pop} baked mean drift"
        assert abs(cal["sd"] - sd) < 1e-9, f"{panel['id']}/{pop} baked sd drift"
        # Swift runtime values
        assert abs(swift[pop]["mean"] - mean) < 1e-9, f"{panel['id']}/{pop} swift mean {swift[pop]['mean']} vs {mean}"
        assert abs(swift[pop]["sd"] - sd) < 1e-9, f"{panel['id']}/{pop} swift sd drift"
        checked += 1
print(f"  {checked} panel-population calibrations verified to 1e-9")
PYEOF

# --------------------------------------------------------------- 9. QC fixtures
step "QC fixtures"
python3 - "$TOOLS/fixtures" <<'PYEOF'
import sys, random
from pathlib import Path
fx = Path(sys.argv[1])
rng = random.Random(42)
# Truncated-chromosome fixture: chr2 is 60% no-calls -> call-rate must NOT pass.
rows = ["#fixture: truncated chromosome", "#rsid\tchromosome\tposition\tallele1\tallele2"]
for i in range(1200):
    chrom = "1" if i < 600 else "2"
    if chrom == "2" and i % 10 < 6:
        rows.append(f"rs55{i:06d}\t{chrom}\t{1000 + i * 5000}\t0\t0")
    else:
        a = rng.choice("ACGT"); b = rng.choice("ACGT")
        rows.append(f"rs55{i:06d}\t{chrom}\t{1000 + i * 5000}\t{a}\t{b}")
(fx / "genome_truncated_chr.txt").write_text("\n".join(rows) + "\n")
# Zero-ROH fixture: alternating het everywhere.
rows = ["#fixture: zero ROH", "#rsid\tchromosome\tposition\tallele1\tallele2"]
for i in range(1200):
    chrom = str(1 + i % 4)
    rows.append(f"rs66{i:06d}\t{chrom}\t{1000 + (i // 4) * 40000}\tA\tG")
(fx / "genome_zero_roh.txt").write_text("\n".join(rows) + "\n")
print("  fixtures written")
PYEOF
if "$CLI" fixture "$TOOLS/fixtures/genome_truncated_chr.txt" > "$BUILD_DIR/fx1.json" 2>&1; then
  python3 - "$BUILD_DIR/fx1.json" <<'PYEOF' && ok "truncated-chromosome fixture fails call-rate loudly" || bad "truncated fixture passed silently"
import json, sys
d = json.load(open(sys.argv[1]))
assert d["callRateGrade"] in ("warn", "fail"), f"call rate graded {d['callRateGrade']} on a 30%-no-call file"
PYEOF
else
  bad "truncated fixture crashed the CLI"
fi
if "$CLI" fixture "$TOOLS/fixtures/genome_zero_roh.txt" > "$BUILD_DIR/fx2.json" 2>&1; then
  python3 - "$BUILD_DIR/fx2.json" <<'PYEOF' && ok "zero-ROH fixture: fROH == 0, typical-outbred wording" || bad "zero-ROH fixture wrong"
import json, sys
d = json.load(open(sys.argv[1]))
assert d["fROH"] == 0.0, f"fROH {d['fROH']} != 0"
assert d["rohRegions"] == 0
assert "typical outbred" in d["rohInterpretation"], d["rohInterpretation"]
PYEOF
else
  bad "zero-ROH fixture crashed the CLI"
fi

# ------------------------------------------------------------- 10. erase test
step "erase regression test (leftover-Reports bug)"
if "$CLI" erase-test > "$BUILD_DIR/erase.json" 2>&1; then
  ok "$(cat "$BUILD_DIR/erase.json" | tr -d '\n ' )"
else
  bad "erase test failed:"; cat "$BUILD_DIR/erase.json"
fi

# ------------------------------------------------------------- 11. static greps
step "static greps"
if grep -rn "URLSession\|NSURLConnection\|Network.framework" "$ROOT/Sources" > "$BUILD_DIR/net.grep"; then
  bad "networking symbols found:"; cat "$BUILD_DIR/net.grep"
else
  ok "no networking symbols anywhere in Sources/ (non-negotiable #1, executable form)"
fi
if grep -n "0\.44\|0\.16" "$ROOT/Sources/AnalysisEngine.swift" > "$BUILD_DIR/const.grep"; then
  bad "dead fake-calibration constants 0.44/0.16 still present:"; cat "$BUILD_DIR/const.grep"
else
  ok "fake 0.44/0.16 constants are gone from AnalysisEngine"
fi
step "independent citation-appendix recount (Python vs Swift)"
python3 - "$ROOT/Resources/knowledge.json" "$BUILD_DIR/report1.json" <<'PYEOF' && ok "citation appendix count independently verified" || bad "citation count drift"
import json, sys
kb = json.load(open(sys.argv[1]))
rep = json.load(open(sys.argv[2]))
seen = set()
for m in kb["markers"]:
    for c in m.get("citations") or []:
        seen.add((c["pmid"], c["note"]))
for comp in kb.get("compounds") or []:
    for c in comp.get("citations") or []:
        seen.add((c["pmid"], c["note"]))
swift_count = rep["reportChecks"]["citationAppendixCount"]
assert swift_count == len(seen), f"Swift dedup {swift_count} != Python dedup {len(seen)}"
print(f"  {len(seen)} unique citations")
PYEOF

"$CLI" clinician-sheet > "$BUILD_DIR/clinician.html" 2>/dev/null || true
if [ -s "$BUILD_DIR/clinician.html" ]; then
  if grep -Ein "increase dose|decrease dose|take [0-9.]+ ?mg|recommended dosing|standard dosing|contraindicated|avoid (the |this )?(drug|medication)|your phenotype|inferred phenotype|actionable|drug safety" "$BUILD_DIR/clinician.html" > "$BUILD_DIR/dose.grep"; then
    bad "clinical action or phenotype wording in the PGx research sheet:"; cat "$BUILD_DIR/dose.grep"
  else
    ok "PGx research sheet contains zero phenotype, action, or dosing language"
  fi
else
  bad "PGx research sheet not emitted"
fi

"$CLI" report-md > "$BUILD_DIR/report.md" 2>/dev/null || true
if [ -s "$BUILD_DIR/report.md" ]; then
  if grep -Ein "[0-9]+([.,][0-9]+)?[[:space:]]*(mcg|iu|g/day)|recommended (supplement|dosing)|dose reduction|required dose|standard dosing|contraindicated|avoid (the |this )?(drug|medication)" "$BUILD_DIR/report.md" > "$BUILD_DIR/report-medical.grep"; then
    bad "dose, supplement, or medication-action wording in the full report:"; cat "$BUILD_DIR/report-medical.grep"
  else
    ok "full report contains no supplement amounts, dosing, or medication-action directions"
  fi
else
  bad "full markdown report not emitted"
fi

if grep -Ein "exact kinship|estimated relationship|kinship coefficient|IBD[012]|parent[ -]child|full sibling|first cousin|second cousin" \
    "$ROOT/Sources/ComparisonEngine.swift" "$ROOT/Sources/CompareView.swift" > "$BUILD_DIR/kinship.grep"; then
  bad "unsupported kinship/IBD claims remain in comparison surfaces:"; cat "$BUILD_DIR/kinship.grep"
else
  ok "comparison surfaces contain no exact relationship, kinship, or IBD claims"
fi

if grep -Ein "[0-9]+([.,][0-9]+)?[[:space:]]*(mcg|mg|iu|gram|grams|g/day)|capsule (taken|daily|before|after)|supplements? to avoid|preferred form:|enzyme (flux )?rate|rate multiplier|-[0-9]+%|activity \(-" \
    "$ROOT/Sources/LifestyleEngine.swift" "$ROOT/Sources/ProtocolView.swift" \
    "$ROOT/Sources/PathwaysEngine.swift" "$ROOT/Sources/PathwaysView.swift" > "$BUILD_DIR/medical.grep"; then
  bad "dose, avoidance, or numeric pathway-rate claim remains:"; cat "$BUILD_DIR/medical.grep"
else
  ok "lifestyle/pathway surfaces contain no doses, avoidance plan, or numeric activity-rate claims"
fi

if grep -En "Text\(c\.(value|detail)\)|title: .*c\.value|body: c\.detail" \
    "$ROOT/Sources/OverviewView.swift" "$ROOT/Sources/HeadlineBuilder.swift" > "$BUILD_DIR/compound-ui.grep"; then
  bad "raw multi-locus outcome labels remain in general UI/headlines:"; cat "$BUILD_DIR/compound-ui.grep"
else
  ok "general UI/headlines withhold raw multi-locus outcome labels"
fi

if grep -En "ImpactBadge\(impact: (hit|node)\.impact\)|hit\.impact\.badge|hit\.effect" \
    "$ROOT/Sources/MarkerViews.swift" "$ROOT/Sources/PathwaysView.swift" \
    "$ROOT/Sources/HeadlineBuilder.swift" "$ROOT/Sources/ReportExport.swift" > "$BUILD_DIR/marker-outcome-ui.grep"; then
  bad "single-marker impact/effect output remains in a UI or export:"; cat "$BUILD_DIR/marker-outcome-ui.grep"
else
  ok "UI and exports do not render single-marker impact/effect outcomes"
fi

if grep -En "mechanism: marker\.mechanism|label: .*g\?\.label|impact: .*g\?\.impact|summary: .*g\?\.summary|effect: marker\.effect" \
    "$ROOT/Sources/KnowledgeBase.swift" > "$BUILD_DIR/marker-pass-through.grep"; then
  bad "legacy genotype outcome pass-through remains in MarkerMatcher:"; cat "$BUILD_DIR/marker-pass-through.grep"
else
  ok "MarkerMatcher withholds legacy genotype outcome fields"
fi

if [ -s "$BUILD_DIR/report.md" ]; then
  if grep -Ein "(enzyme activity|residual activity|cleavage activity|acetaldehyde clearance|tyrosinase activity|carotene conversion).{0,80}[~><]?[0-9]+([.][0-9]+)?%|[~><]?[0-9]+([.][0-9]+)?%.{0,80}(enzyme activity|residual activity|cleavage activity|acetaldehyde clearance|tyrosinase activity|carotene conversion)" \
      "$BUILD_DIR/report.md" > "$BUILD_DIR/activity-percent.grep"; then
    bad "deterministic enzyme/activity percentage remains in full report:"; cat "$BUILD_DIR/activity-percent.grep"
  else
    ok "full report contains no deterministic enzyme/activity percentage"
  fi
fi

echo
echo "NOTE: PDF generation (WKWebView) needs a runloop and is verified manually once per build:"
echo "      open the app -> Export -> Export Full PDF Report."
echo
if [ "$FAILURES" -gt 0 ]; then
  echo "run_checks: $FAILURES FAILURE(S)"
  exit 1
fi
echo "run_checks: ALL CHECKS PASSED"
