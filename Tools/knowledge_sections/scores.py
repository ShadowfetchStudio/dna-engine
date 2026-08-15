"""Polygenic tendency panels with per-population HWE calibration.

Every ScoreSNP carries hand-entered risk-allele frequencies per continental
population (approximate gnomAD/1000G-derived reference values — labeled as
approximations in-app). The generator computes, per panel per population:

    mean = sum(2 * p * w)                    (expected weighted risk-allele dose)
    sd   = sqrt(sum(2 * p * (1 - p) * w^2))  (HWE binomial variance, weighted)

and emits them as panel["calibration"][population] = {"mean": ..., "sd": ...}.
The Swift engine re-derives the same quantities over ONLY the SNPs actually
typed in the user's file (using these same freqs), so chip coverage cannot
bias the z-score. The old fixed 0.44/0.16 constants are dead.

Frequency provenance: approximate continental risk-allele frequencies compiled
from gnomAD v2/1000G population summaries; two decimals of precision is honest
for this purpose and the in-app caption says so.
"""

# population order helper: (eur, afr, eas, sas, amr, mena, oce)
def fq(eur, afr, eas, sas, amr, mena, oce):
    return {
        "european": eur, "african": afr, "east_asian": eas, "south_asian": sas,
        "american": amr, "middle_eastern": mena, "oceanian": oce,
    }


def snp(rsid, risk, weight, freq):
    return {"rsid": rsid, "risk": risk, "weight": weight, "freq": freq}


SCORES = [
    {
        "id": "cad",
        "title": "Coronary Artery Disease Predisposition",
        "description": "Multi-locus vascular panel covering 9p21.3, LPA, APOE, and endothelial signaling.",
        "snps": [
            snp("rs10757274", "G", 1.4, fq(0.47, 0.28, 0.45, 0.44, 0.42, 0.45, 0.35)),
            snp("rs1333049", "C", 1.3, fq(0.47, 0.26, 0.47, 0.45, 0.42, 0.46, 0.34)),
            snp("rs10455872", "G", 1.8, fq(0.07, 0.02, 0.01, 0.04, 0.05, 0.06, 0.02)),
            snp("rs3798220", "C", 1.6, fq(0.02, 0.02, 0.06, 0.04, 0.08, 0.03, 0.03)),
            snp("rs429358", "C", 1.2, fq(0.15, 0.28, 0.09, 0.09, 0.11, 0.10, 0.19)),
            snp("rs1799983", "T", 0.8, fq(0.33, 0.12, 0.12, 0.20, 0.22, 0.28, 0.15)),
            snp("rs699", "C", 0.6, fq(0.42, 0.85, 0.82, 0.70, 0.65, 0.55, 0.75)),
            snp("rs6025", "T", 0.9, fq(0.03, 0.005, 0.002, 0.01, 0.015, 0.025, 0.005)),
        ],
    },
    {
        "id": "t2d",
        "title": "Type 2 Diabetes & Insulin Resistance Tendency",
        "description": "Beta-cell secretory capacity, incretin signaling, and insulin receptor sensitivity markers (TCF7L2, KCNJ11, PPARG, MTNR1B).",
        "snps": [
            snp("rs7903146", "T", 1.8, fq(0.31, 0.32, 0.04, 0.28, 0.24, 0.35, 0.12)),
            snp("rs5219", "T", 0.9, fq(0.37, 0.08, 0.36, 0.38, 0.30, 0.33, 0.25)),
            snp("rs1801282", "C", 0.8, fq(0.88, 0.98, 0.95, 0.90, 0.89, 0.91, 0.94)),
            snp("rs10830963", "G", 1.2, fq(0.28, 0.08, 0.42, 0.38, 0.25, 0.30, 0.20)),
            snp("rs9939609", "A", 0.6, fq(0.42, 0.51, 0.16, 0.31, 0.32, 0.38, 0.24)),
            snp("rs17782313", "C", 0.7, fq(0.24, 0.28, 0.20, 0.28, 0.22, 0.25, 0.23)),
            snp("rs738409", "G", 0.9, fq(0.23, 0.14, 0.38, 0.26, 0.52, 0.23, 0.21)),
        ],
    },
    {
        "id": "longevity",
        "title": "Cellular Longevity & Healthspan Potential",
        "description": "Autophagy regulation, telomere length dynamics, and lipid clearance resilience (FOXO3, TERT, PCSK9, CETP, APOE).",
        "snps": [
            snp("rs2802292", "G", 2.0, fq(0.38, 0.55, 0.32, 0.40, 0.42, 0.40, 0.45)),
            snp("rs2736098", "A", 1.2, fq(0.27, 0.15, 0.35, 0.30, 0.25, 0.26, 0.28)),
            snp("rs11591147", "T", 1.5, fq(0.015, 0.005, 0.001, 0.008, 0.01, 0.012, 0.003)),
            snp("rs708272", "A", 1.0, fq(0.43, 0.35, 0.40, 0.42, 0.40, 0.42, 0.38)),
            snp("rs7412", "T", 1.1, fq(0.08, 0.10, 0.09, 0.05, 0.06, 0.07, 0.11)),
        ],
    },
    {
        "id": "bmi",
        "title": "Adiposity & Caloric Intake Drive",
        "description": "Hypothalamic appetite drive, leptin sensitivity, and satiety signaling (FTO, MC4R, DRD2).",
        "snps": [
            snp("rs9939609", "A", 1.5, fq(0.42, 0.51, 0.16, 0.31, 0.32, 0.38, 0.24)),
            snp("rs17782313", "C", 1.2, fq(0.24, 0.28, 0.20, 0.28, 0.22, 0.25, 0.23)),
            snp("rs1800497", "A", 0.8, fq(0.19, 0.38, 0.44, 0.29, 0.26, 0.23, 0.31)),
            snp("rs738409", "G", 0.7, fq(0.23, 0.14, 0.38, 0.26, 0.52, 0.23, 0.21)),
        ],
    },
    {
        "id": "chronotype",
        "title": "Circadian Phase & Eveningness Tendency",
        "description": "Core transcription factors of the molecular clock (CLOCK, PER3, MTNR1B, ADORA2A).",
        "snps": [
            snp("rs1801260", "G", 1.6, fq(0.26, 0.35, 0.20, 0.28, 0.30, 0.28, 0.32)),
            snp("rs57875986", "T", 1.0, fq(0.10, 0.28, 0.06, 0.12, 0.15, 0.12, 0.18)),
            snp("rs10830963", "G", 0.9, fq(0.28, 0.08, 0.42, 0.38, 0.25, 0.30, 0.20)),
            snp("rs5751876", "T", 0.8, fq(0.41, 0.30, 0.35, 0.38, 0.36, 0.39, 0.33)),
        ],
    },
    {
        "id": "vo2max",
        "title": "Aerobic Capacity & VO2 Max Trainability",
        "description": "Mitochondrial biogenesis, vascular capillarization, and muscle oxidative adaptation (PPARGC1A, ACE, ACTN3, eNOS).",
        "snps": [
            snp("rs8192678", "C", 1.5, fq(0.63, 0.85, 0.55, 0.60, 0.65, 0.64, 0.70)),
            snp("rs4343", "G", 1.2, fq(0.47, 0.60, 0.55, 0.50, 0.52, 0.50, 0.55)),
            snp("rs1815739", "T", 1.0, fq(0.44, 0.10, 0.51, 0.42, 0.31, 0.39, 0.26)),
            snp("rs1799983", "G", 0.8, fq(0.67, 0.88, 0.88, 0.80, 0.78, 0.72, 0.85)),
            snp("rs12722", "T", 0.7, fq(0.45, 0.55, 0.40, 0.48, 0.46, 0.47, 0.50)),
        ],
    },
    {
        "id": "power",
        "title": "Muscular Power & Fast-Twitch Output",
        "description": "Fast-twitch alpha-actinin-3 structural anchoring, ACE activity, and explosive force generation.",
        "snps": [
            snp("rs1815739", "C", 1.8, fq(0.56, 0.90, 0.49, 0.58, 0.69, 0.61, 0.74)),
            snp("rs4343", "A", 1.3, fq(0.53, 0.40, 0.45, 0.50, 0.48, 0.50, 0.45)),
            snp("rs17602729", "G", 0.9, fq(0.90, 0.97, 0.99, 0.95, 0.94, 0.92, 0.97)),
        ],
    },
    {
        "id": "bone",
        "title": "Bone Mineral Density & Connective Tissue Robustness",
        "description": "Collagen Type I cross-linking, Vitamin D receptor signaling, and calcium homeostasis (COL1A1, VDR, GC).",
        "snps": [
            snp("rs1800012", "A", 1.5, fq(0.18, 0.10, 0.05, 0.12, 0.13, 0.15, 0.08)),
            snp("rs2228570", "T", 1.0, fq(0.40, 0.25, 0.50, 0.42, 0.45, 0.40, 0.44)),
            snp("rs2282679", "C", 0.9, fq(0.28, 0.10, 0.28, 0.25, 0.24, 0.26, 0.20)),
            snp("rs12722", "C", 0.7, fq(0.55, 0.45, 0.60, 0.52, 0.54, 0.53, 0.50)),
        ],
    },
    {
        "id": "inflammation",
        "title": "Systemic Inflammatory Reactivity",
        "description": "Cytokine transcription and oxidative stress defense (IL6, TNF-alpha, SOD2).",
        "snps": [
            snp("rs1800795", "G", 1.4, fq(0.58, 0.92, 0.98, 0.80, 0.75, 0.65, 0.90)),
            snp("rs1800629", "A", 1.5, fq(0.16, 0.12, 0.06, 0.08, 0.10, 0.12, 0.09)),
            snp("rs4880", "A", 0.9, fq(0.50, 0.42, 0.14, 0.35, 0.40, 0.45, 0.25)),
        ],
    },
    {
        "id": "homocysteine",
        "title": "1-Carbon Stress & Homocysteine Vulnerability",
        "description": "Methylenetetrahydrofolate reductase, methionine synthase, and B12 remethylation velocity.",
        "snps": [
            snp("rs1801133", "T", 1.9, fq(0.35, 0.11, 0.42, 0.18, 0.48, 0.28, 0.15)),
            snp("rs1801131", "C", 0.7, fq(0.31, 0.16, 0.20, 0.42, 0.28, 0.35, 0.25)),
            snp("rs1801394", "G", 0.8, fq(0.52, 0.28, 0.28, 0.45, 0.40, 0.48, 0.30)),
            snp("rs1805087", "G", 0.6, fq(0.20, 0.28, 0.10, 0.22, 0.18, 0.21, 0.15)),
        ],
    },
    {
        "id": "cognitive_reserve",
        "title": "Neuro-Plasticity & Cognitive Reserve",
        "description": "Brain-derived neurotrophic factor, catecholamine clearance, and hippocampal resilience (BDNF, COMT, APOE).",
        "snps": [
            snp("rs6265", "C", 1.6, fq(0.80, 0.96, 0.54, 0.78, 0.82, 0.85, 0.88)),
            snp("rs4680", "A", 1.1, fq(0.49, 0.28, 0.29, 0.42, 0.35, 0.45, 0.22)),
            snp("rs429358", "T", 1.4, fq(0.85, 0.72, 0.91, 0.91, 0.89, 0.90, 0.81)),
        ],
    },
    {
        "id": "histamine_load",
        "title": "Histamine Degradation & Intolerance Tendency",
        "description": "Intestinal diamine oxidase variants and central HNMT clearance (AOC1/DAO, HNMT).",
        "snps": [
            snp("rs10156191", "T", 1.8, fq(0.30, 0.20, 0.12, 0.25, 0.28, 0.28, 0.18)),
            snp("rs2052129", "T", 1.0, fq(0.28, 0.18, 0.10, 0.24, 0.26, 0.26, 0.16)),
            snp("rs1049793", "G", 0.9, fq(0.30, 0.22, 0.14, 0.26, 0.28, 0.28, 0.18)),
            snp("rs11558538", "T", 0.8, fq(0.10, 0.05, 0.03, 0.08, 0.08, 0.09, 0.05)),
        ],
    },
    # --- 2.0: three new panels built from catalog-1/expansion markers ---
    {
        "id": "caffeine_sensitivity",
        "title": "Caffeine Sensitivity & Clearance Tendency",
        "description": "Constitutive and induced CYP1A2 clearance plus adenosine-receptor sensitivity (CYP1A2, AHR region, ADORA2A, ADA).",
        "snps": [
            snp("rs762551", "C", 1.6, fq(0.32, 0.48, 0.38, 0.28, 0.29, 0.34, 0.31)),
            snp("rs5751876", "T", 1.2, fq(0.41, 0.30, 0.35, 0.38, 0.36, 0.39, 0.33)),
            snp("rs2472297", "C", 0.9, fq(0.74, 0.92, 0.97, 0.85, 0.82, 0.78, 0.90)),
            snp("rs4410790", "T", 0.8, fq(0.37, 0.55, 0.30, 0.40, 0.42, 0.40, 0.38)),
            snp("rs73598374", "T", 0.7, fq(0.05, 0.03, 0.02, 0.04, 0.04, 0.05, 0.03)),
        ],
    },
    {
        "id": "iron_overload",
        "title": "Iron Accumulation Tendency",
        "description": "HFE hemochromatosis alleles and hepcidin set-point modifiers (HFE, TMPRSS6, TF). Educational only — ferritin labs are the ground truth.",
        "snps": [
            snp("rs1800562", "A", 2.0, fq(0.06, 0.005, 0.001, 0.01, 0.02, 0.02, 0.005)),
            snp("rs1799945", "G", 1.0, fq(0.14, 0.02, 0.03, 0.09, 0.10, 0.12, 0.04)),
            snp("rs855791", "G", 0.8, fq(0.55, 0.85, 0.45, 0.50, 0.60, 0.58, 0.65)),
            snp("rs3811647", "G", 0.5, fq(0.65, 0.70, 0.75, 0.68, 0.66, 0.66, 0.72)),
        ],
    },
    {
        "id": "venous_thrombosis",
        "title": "Venous Thrombosis Tendency",
        "description": "Factor V Leiden, prothrombin, ABO non-O, and fibrinogen gamma (F5, F2, ABO, FGG). Context factors (immobility, surgery, estrogen) dominate absolute risk.",
        "snps": [
            snp("rs6025", "T", 2.0, fq(0.03, 0.005, 0.002, 0.01, 0.015, 0.025, 0.005)),
            snp("rs1799963", "A", 1.6, fq(0.012, 0.003, 0.001, 0.006, 0.008, 0.015, 0.002)),
            snp("rs505922", "C", 1.0, fq(0.36, 0.42, 0.40, 0.42, 0.38, 0.40, 0.45)),
            snp("rs2066865", "A", 0.8, fq(0.25, 0.18, 0.30, 0.26, 0.24, 0.25, 0.28)),
        ],
    },
]


def build_calibration(scores, populations):
    """Attach HWE-derived per-population calibration; return (scores, errors)."""
    errors = []
    for panel in scores:
        cal = {}
        for pop in populations:
            mean = 0.0
            var = 0.0
            for s in panel["snps"]:
                freq = s.get("freq") or {}
                if pop not in freq:
                    errors.append(f"panel {panel['id']}: snp {s['rsid']} missing freq for {pop}")
                    continue
                p = float(freq[pop])
                if not (0.0 < p < 1.0):
                    # clamp fixed alleles just inside the open interval
                    p = min(max(p, 1e-4), 1 - 1e-4)
                w = float(s["weight"])
                mean += 2.0 * p * w
                var += 2.0 * p * (1.0 - p) * w * w
            cal[pop] = {"mean": mean, "sd": var ** 0.5}
        panel["calibration"] = cal
        if not panel["snps"]:
            errors.append(f"panel {panel['id']}: no snps")
        for pop in populations:
            if cal.get(pop, {}).get("sd", 0) <= 0:
                errors.append(f"panel {panel['id']}: zero-variance calibration for {pop}")
    return scores, errors
