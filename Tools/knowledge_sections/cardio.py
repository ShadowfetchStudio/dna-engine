"""Cardiovascular, lipid clearance & thrombosis — curated chip-callable markers."""
from .common import G, C, CHIPS_ALL, PGKB, GWAS, CLIN, CPIC


def register(add):
    add(
        "rs429358", "APOE", "Apolipoprotein E Cys112Arg (ε4 Determinant)", "19", 45411941,
        ["cardio", "lipids", "cognition", "longevity"], "strong", "C", "T",
        "rs429358 combined with rs7412 determines the APOE ε2, ε3, or ε4 isoform. The C allele creates the Arg112 variant (ε4), which alters VLDL/LDL binding, increases circulating LDL particle count, and influences amyloid clearance in the brain.",
        G("APOE ε4 Present (CC)", "caution",
          "Two copies of the ε4 determinant (ε4/ε4 if rs7412 is CC).",
          "Strongly associated with higher average LDL-C/ApoB and increased risk of atherosclerosis and late-onset Alzheimer's. Not a deterministic diagnosis. Lifestyle, metabolic fitness, aerobic exercise, and sleep quality strongly modulate lifetime expression.",
          eat=["Adopt a Mediterranean-style diet high in polyphenols, monounsaturated fats (extra virgin olive oil), and fiber.", "Limit excess saturated fat and refined carbohydrates to manage ApoB."],
          move=["Maintain a consistent weekly zone-2 aerobic and strength training regimen to stimulate cerebral blood flow and lipid clearance."],
          sleep=["Prioritize 7.5–8.5 hours of high-quality sleep for optimal glymphatic brain clearance."]),
        G("APOE ε4 Heterozygote (CT)", "notable",
          "One copy of the ε4 allele (typically ε3/ε4).",
          "Carries moderate sensitivity to dietary saturated fat with higher average ApoB and cardiovascular risk.",
          eat=["Emphasize extra virgin olive oil, wild fatty fish, high dietary soluble fiber (psyllium, oats, legumes).", "Check advanced lipid panel (ApoB, Lp(a), LDL-P) with a physician."],
          move=["Regular aerobic conditioning enhances lipid transport and endothelial function."]),
        G("APOE ε4 Absent (TT)", "typical",
          "No ε4 allele at this position (typically ε3/ε3, ε2/ε3, or ε2/ε2 depending on rs7412).",
          "Standard baseline lipid particle clearance and typical neurological risk profile.",
          eat=["Standard cardioprotective dietary pattern."]),
        notes="Must be interpreted in conjunction with rs7412 to identify the true APOE diplotype (ε2/ε2, ε2/ε3, ε3/ε3, ε3/ε4, ε4/ε4, ε2/ε4).",
    )

    add(
        "rs7412", "APOE", "Apolipoprotein E Arg158Cys (ε2 Determinant)", "19", 45412079,
        ["cardio", "lipids", "cognition"], "strong", "C", "T",
        "rs7412 determines the ε2 allele (T allele / Cys158). ε2 has defective binding to the LDL receptor (<2% normal affinity), leading to upregulation of hepatic LDL receptors, generally resulting in lower circulating LDL-C.",
        G("Typical (CC)", "typical", "Standard Arg158. Forms ε3 or ε4 depending on rs429358.", "Standard LDL receptor binding."),
        G("APOE ε2 Heterozygote (CT)", "advantageous",
          "One ε2 allele. Associated with lower average LDL-C and ApoB concentrations.",
          "Generally cardioprotective regarding LDL-mediated atherosclerosis, though triglycerides may be slightly higher.",
          eat=["Maintain balanced triglycerides by limiting refined sugars and alcohol."]),
        G("APOE ε2/ε2 Genotype (TT)", "notable",
          "Two ε2 alleles. Substantially reduced LDL receptor binding.",
          "Most individuals have very low LDL-C, but ~5–10% can develop Type III Hyperlipoproteinemia (dysbetalipoproteinemia) if obesity or insulin resistance is present.",
          eat=["Keep insulin sensitivity high; avoid high-sugar diets and excessive alcohol to prevent remnant lipoprotein accumulation."],
          recover=["Monitor fasting triglycerides and VLDL in routine checkups."]),
        notes="Pairs with rs429358 to define the APOE diplotype.",
    )

    add(
        "rs10455872", "LPA", "Lipoprotein(a) Elevation (KIV-2 Repeat Tag)", "6", 161010118,
        ["cardio", "lipids"], "strong", "A", "G",
        "LPA encodes apolipoprotein(a), which binds LDL to form Lp(a)—an independent, genetically determined driver of cardiovascular disease and calcific aortic stenosis. The G allele is strongly associated with high circulating Lp(a) levels (>50 mg/dL / 125 nmol/L).",
        G("Typical Lp(a) (AA)", "typical", "No risk allele detected. Lower baseline probability of genetically high Lp(a).",
          "Diet and lifestyle remain the primary drivers of general cardiovascular health."),
        G("Elevated Lp(a) Carrier (AG)", "caution",
          "One G allele. Associated with elevated plasma Lipoprotein(a).",
          "Lp(a) is predominantly genetically determined and largely resistant to standard statin therapy or diet. Strongly increases lifetime cardiovascular and thrombosis risk.",
          eat=["Strictly manage other modifiable cardiovascular risk factors: blood pressure, ApoB, fasting glucose, and inflammation."],
          recover=["Request a one-time quantitative Lp(a) blood test with a physician to establish your exact baseline concentration."]),
        G("High Lp(a) Homozygote (GG)", "caution",
          "Two G alleles. Associated with substantially elevated Lp(a) levels.",
          "High lifetime cardiovascular risk from both atherogenic and thrombogenic mechanisms of Lp(a).",
          eat=["Intensive cardiovascular prevention strategy focusing on blood pressure, optimal ApoB, smoking avoidance, and anti-inflammatory lifestyle."],
          recover=["Work closely with a cardiologist or lipid specialist to evaluate Lp(a)-lowering therapies and overall risk management."]),
        notes="Lp(a) is a top independent cardiovascular risk factor that is 90% genetically determined.",
    )

    add(
        "rs3798220", "LPA", "Lipoprotein(a) I4399M / KIV-2 Variant", "6", 161084224,
        ["cardio", "lipids"], "strong", "C", "T",
        "Another potent functional variant in the LPA gene associated with markedly elevated Lp(a) and increased risk of coronary artery disease and stroke.",
        G("Typical (TT)", "typical", "No I4399M variant detected.", "Standard baseline risk."),
        G("Elevated Lp(a) (CT)", "caution", "One C allele. High likelihood of elevated Lp(a).",
          "Independent risk factor for coronary disease and thrombosis.",
          recover=["Measure serum Lp(a) directly to quantify cardiovascular risk."]),
        G("High Lp(a) (CC)", "caution", "Homozygous C. Substantially elevated Lp(a).",
          "High atherogenic particle burden.",
          recover=["Consult a lipid specialist for comprehensive cardiovascular risk management."]),
    )

    add(
        "rs11591147", "PCSK9", "Proprotein Convertase Subtilisin/Kexin 9 (R46L / Loss of Function)", "1", 55505647,
        ["cardio", "lipids", "longevity"], "strong", "G", "T",
        "PCSK9 binds to and degrades LDL receptors on hepatocytes. The T allele is a loss-of-function mutation (R46L) that preserves LDL receptors, leading to lifelong lower LDL-C (~15–30% reduction) and ~40–80% lower lifetime coronary heart disease risk.",
        G("Typical PCSK9 Activity (GG)", "typical", "Normal PCSK9 expression and LDL receptor degradation.", "Standard lipid management."),
        G("PCSK9 Loss-of-Function Carrier (GT)", "advantageous",
          "One T allele (R46L). Lifelong lower LDL-C and significantly reduced cardiovascular risk.",
          "Natural genetic equivalent of PCSK9 inhibitor medications. Conveys substantial cardiovascular protection across the lifespan.",
          eat=["Continue healthy dietary habits; you have a favorable genetic buffer for LDL particle clearance."]),
        G("PCSK9 Homozygote Loss-of-Function (TT)", "advantageous",
          "Two T alleles. Markedly lower lifetime LDL-C and profound cardioprotection.",
          "Extremely rare and strongly protective against coronary artery disease.",
          eat=["Maintain overall metabolic health and cardiovascular fitness."]),
        notes="A premier example of a beneficial cardioprotective loss-of-function mutation.",
    )

    add(
        "rs708272", "CETP", "Cholesteryl Ester Transfer Protein (TaqIB / Intron 1)", "16", 56995836,
        ["cardio", "lipids", "longevity"], "moderate", "A", "G",
        "CETP transfers cholesteryl esters from HDL to VLDL/LDL. The A allele (B2 allele) is associated with lower CETP activity, resulting in higher circulating HDL-C and favorable longevity associations.",
        G("Typical CETP (GG)", "typical", "Higher CETP activity. Standard HDL-C levels.", "Normal lipid remodeling."),
        G("Intermediate CETP (AG)", "advantageous", "One A allele. Moderately lower CETP activity and higher average HDL-C.", "Favorable lipid profile."),
        G("Reduced CETP / High HDL (AA)", "advantageous",
          "Two A alleles. Lower CETP activity, higher HDL particle concentration and larger particle size.",
          "Associated in multiple centenarian cohorts with cardiovascular resilience and healthy aging.",
          eat=["Support HDL functionality with polyphenol-rich foods, extra virgin olive oil, and regular exercise."]),
    )

    add(
        "rs6025", "F5", "Factor V Leiden (Arg506Gln)", "1", 169519049,
        ["cardio", "clotting"], "strong", "C", "T",
        "Factor V Leiden (G1691A / Arg506Gln) renders Factor Va resistant to cleavage and inactivation by activated protein C (APC resistance), increasing venous thromboembolism (DVT/PE) risk.",
        G("Typical (CC)", "typical", "No Factor V Leiden mutation detected. Normal clotting cascade regulation.", "Standard thrombosis risk."),
        G("Factor V Leiden Heterozygote (CT)", "caution",
          "One copy of Factor V Leiden. ~3–7x increased lifetime risk of venous thromboembolism (DVT / PE).",
          "Important clinical context: long-haul flights, surgery, immobilization, pregnancy, or estrogen-containing oral contraceptives/HRT significantly amplify clotting risk.",
          move=["Stay active on flights over 4 hours: walk every 90 min, wear compression socks, and stay hydrated."],
          recover=["Inform physicians and surgeons before any procedure or when considering estrogen therapies. Do NOT self-prescribe blood thinners."]),
        G("Factor V Leiden Homozygote (TT)", "caution",
          "Two copies of Factor V Leiden. ~50–80x increased lifetime risk of venous thromboembolism.",
          "High risk of thrombosis requiring formal clinical hematology consultation and specialized precautions around surgery and travel.",
          recover=["Must be clinically confirmed with a medical genetic or coagulation panel. Discuss preventive strategies with a hematologist."]),
        notes="The most common inherited thrombophilia in European-ancestry populations.",
    )

    add(
        "rs1799963", "F2", "Prothrombin G20210A Mutation", "11", 46761055,
        ["cardio", "clotting"], "strong", "A", "G",
        "A point mutation in the 3' UTR of the Prothrombin (F2) gene that increases mRNA stability and elevates plasma prothrombin levels, raising venous thrombosis risk by ~2–3x in heterozygotes.",
        G("Typical Prothrombin (GG)", "typical", "Normal prothrombin regulation.", "Baseline clotting risk."),
        G("Prothrombin 20210A Carrier (AG)", "caution",
          "One 20210A allele. Elevated circulating prothrombin and increased venous clotting risk.",
          "Multiplies with other risk factors (smoking, surgery, oral contraceptives, prolonged immobility).",
          move=["Take active walking breaks during long-distance travel and use graduated compression socks."],
          recover=["Inform physicians prior to surgeries or pregnancy."]),
        G("Prothrombin 20210A Homozygote (AA)", "caution",
          "Two 20210A alleles. Significantly elevated prothrombin and thrombosis risk.",
          "Requires clinical hematology guidance.",
          recover=["Consult a physician for a formal thrombophilia assessment."]),
    )

    add(
        "rs10757274", "CDKN2A-CDKN2B", "9p21.3 Coronary Artery Disease Risk Locus", "9", 22124477,
        ["cardio"], "strong", "A", "G",
        "The 9p21.3 locus near CDKN2A/CDKN2B is the most replicated GWAS locus for coronary artery disease (CAD) and myocardial infarction, acting independently of traditional blood lipid levels.",
        G("Typical (AA)", "typical", "No 9p21.3 risk allele.", "Standard baseline CAD risk."),
        G("One 9p21.3 Risk Allele (AG)", "notable", "One risk allele. ~15–20% increased lifetime risk of CAD.",
          "Acts independently of cholesterol through vascular wall biology and cellular senescence.",
          eat=["Strong adherence to a vascular-protective lifestyle: blood pressure control, regular exercise, and non-smoking."]),
        G("Two 9p21.3 Risk Alleles (GG)", "caution", "Two risk alleles. ~30–40% increased lifetime risk of CAD.",
          "Significant genetic predisposition for vascular atherosclerosis. Highly responsive to lifestyle risk reduction.",
          eat=["Prioritize optimal blood pressure (<120/80), zero tobacco exposure, and tight metabolic management."]),
    )

    add(
        "rs1333049", "CDKN2A-CDKN2B", "9p21.3 Coronary Artery Disease Tag", "9", 22125504,
        ["cardio"], "strong", "C", "G",
        "Complementary tag SNP in the 9p21.3 vascular senescence locus.",
        G("Typical (GG)", "typical", "No risk variant.", "Baseline vascular risk."),
        G("Heterozygote (CG)", "notable", "One risk allele for coronary atherosclerosis.", "Support endothelial health."),
        G("Homozygous Risk (CC)", "caution", "Two risk alleles. Elevated coronary atherosclerosis risk.",
          "Emphasize comprehensive cardiovascular risk reduction.",
          move=["Maintain daily cardiovascular exercise to preserve vascular endothelial elasticity."]),
    )

    add(
        "rs1799983", "NOS3", "Endothelial Nitric Oxide Synthase (eNOS / Glu298Asp)", "7", 150696144,
        ["cardio", "fitness"], "moderate", "G", "T",
        "eNOS synthesizes nitric oxide (NO) in endothelial cells to regulate vasodilation and vascular tone. The T allele (Asp298) increases susceptibility to enzyme cleavage, reducing basal NO production under oxidative stress.",
        G("Normal eNOS (GG)", "typical", "Standard endothelial nitric oxide synthesis.", "Normal vascular reactivity."),
        G("Heterozygote (GT)", "typical", "Mildly reduced NO synthesis under oxidative conditions.", "Support with dietary nitrates."),
        G("Reduced eNOS Activity (TT)", "notable",
          "Two Asp298 alleles. Lower basal endothelial NO production and higher blood pressure sensitivity to oxidative stress.",
          "Endothelial lining benefits significantly from dietary nitrate donors and aerobic exercise.",
          eat=["Incorporate dietary nitrate-rich foods: beets, arugula, pomegranate, and citrus (citrulline/arginine sources)."],
          move=["Consistent zone-2 cardiovascular training stimulates eNOS phosphorylation and blood vessel dilation."]),
    )

    add(
        "rs699", "AGT", "Angiotensinogen (M235T / Met235Thr)", "1", 230845794,
        ["cardio"], "moderate", "C", "T",
        "AGT is the precursor of angiotensin I in the renin-angiotensin-aldosterone system (RAAS). The C allele (235T) is associated with higher plasma angiotensinogen levels and salt-sensitive blood pressure.",
        G("Typical RAAS (TT)", "typical", "Normal baseline angiotensinogen levels.", "Standard sodium sensitivity."),
        G("Intermediate Sensitivity (CT)", "typical", "One 235T allele. Moderate sensitivity to dietary sodium.", "Maintain balanced electrolytes."),
        G("Salt-Sensitive Hypertension Risk (CC)", "notable",
          "Homozygous 235T. Elevated baseline plasma angiotensinogen.",
          "Associated with higher risk of salt-sensitive hypertension. High potassium-to-sodium ratio is especially beneficial.",
          eat=["Ensure high dietary potassium (avocados, leafy greens, sweet potatoes) and moderate processed sodium intake."]),
    )

    add(
        "rs4343", "ACE", "Angiotensin-Converting Enzyme (ACE I/D Proxy)", "17", 61565507,
        ["cardio", "fitness"], "moderate", "A", "G",
        "rs4343 is in high linkage disequilibrium with the classic ACE Insertion/Deletion (I/D) polymorphism. The A allele tags the D (Deletion) allele (higher serum ACE activity / power leaning), while G tags the I (Insertion) allele (lower ACE activity / endurance leaning).",
        G("ACE I-Tag Homozygote (GG)", "typical",
          "Tags ACE II genotype. Lower circulating ACE and angiotensin II, higher bradykinin levels.",
          "Associated with enhanced muscle efficiency, capillary density, and endurance performance.",
          move=["Naturally predisposed toward aerobic endurance and sustained fatigue resistance."]),
        G("ACE Heterozygote (AG)", "typical", "Tags ACE ID genotype. Balanced power and endurance traits.", "Balanced athletic potential."),
        G("ACE D-Tag Homozygote (AA)", "notable",
          "Tags ACE DD genotype. Higher circulating ACE activity.",
          "Associated with greater muscular power output and sprint performance, but also slightly higher blood pressure reactivity.",
          move=["Naturally predisposed toward sprint, resistance, and explosive power adaptation."],
          recover=["Monitor resting blood pressure during heavy training blocks."]),
    )


    add(
        "rs1800788", "FGB", "Beta-Fibrinogen (-455G>A / Elevated Fibrinogen)", "4", 155509930,
        ["cardio", "clotting"], "strong", "A", "G",
        "FGB encodes the beta chain of fibrinogen. The A allele (-455A) elevates basal and IL-6-induced plasma fibrinogen levels, increasing blood viscosity and thrombotic risk.",
        G("Typical Fibrinogen (GG)", "typical", "Standard fibrinogen expression.", "Normal baseline plasma viscosity."),
        G("Elevated Fibrinogen Carrier (AG)", "notable", "One A allele. Moderately elevated circulating fibrinogen.",
          "Higher blood viscosity and inflammatory clotting reactivity.",
          eat=["Emphasize omega-3 fatty acids, systemic hydration, and regular aerobic exercise to support blood rheology."]),
        G("High Plasma Fibrinogen (AA)", "caution", "Two A alleles. Markedly higher baseline fibrinogen.",
          "Significantly higher plasma viscosity; avoid smoking which synergistically elevates fibrinogen.",
          eat=["Strict avoidance of smoking; regular cardiovascular conditioning."],
          recover=["Include plasma fibrinogen and hs-CRP in cardiovascular blood work."]),
    )

    add(
        "rs662", "PON1", "Paraoxonase 1 (Q192R / HDL Antioxidant Capacity)", "7", 94949104,
        ["cardio", "lipids", "antioxidant"], "strong", "A", "G",
        "PON1 is an HDL-associated esterase that protects LDL and HDL from oxidative modification and hydrolyzes organophosphates. The G allele (192R) has higher paraoxonase activity but lower efficiency in metabolizing lipid peroxides.",
        G("High Peroxide Hydrolysis (AA / 192Q)", "advantageous", "Two Q alleles. Superior protection against oxidized LDL.", "High endogenous antioxidant protection for HDL."),
        G("Intermediate (AG)", "typical", "Balanced PON1 enzyme kinetics.", "Standard lipid antioxidant support."),
        G("Altered Lipid Peroxide Clearance (GG / 192R)", "notable", "Two R alleles. Lower efficiency in detoxifying lipid peroxides.",
          "May benefit from higher dietary polyphenol intake (extra virgin olive oil, pomegranate, green tea) to preserve HDL quality.",
          eat=["Incorporate rich dietary polyphenols and extra virgin olive oil to enhance PON1 expression."]),
    )

    add(
        "rs5918", "ITGB3", "Platelet Glycoprotein IIIa (PlA1/PlA2 / Pro-Thrombotic Platelets)", "17", 45353597,
        ["cardio", "clotting"], "strong", "C", "T",
        "ITGB3 forms the platelet fibrinogen receptor GPIIb/IIIa. The C allele (PlA2 / Leu33Pro) increases platelet aggregability and thrombotic risk.",
        G("Typical Platelet Reactivity (TT / PlA1)", "typical", "Standard platelet fibrinogen binding.", "Normal baseline platelet aggregation."),
        G("Hyper-Reactive Platelet Carrier (CT / PlA2)", "notable", "One PlA2 allele. Moderately enhanced platelet reactivity.",
          "Slightly higher risk of arterial thrombosis under endothelial shear stress.",
          eat=["Support endothelial health with dietary nitrates and omega-3s."]),
        G("High Platelet Reactivity (CC / PlA2)", "caution", "Two PlA2 alleles. Hyper-reactive platelet aggregation.",
          "Higher risk of acute coronary syndrome; discuss antiplatelet strategies with a physician.",
          recover=["Clinical consultation if cardiovascular disease or stent placement is relevant."]),
    )

    add(
        "rs5128", "APOC3", "Apolipoprotein C3 (3238C>G / SstI / Hypertriglyceridemia)", "11", 116704648,
        ["cardio", "lipids"], "strong", "C", "G",
        "APOC3 inhibits lipoprotein lipase and hepatic uptake of triglyceride-rich particles. The G allele increases APOC3 expression, leading to elevated plasma triglycerides.",
        G("Typical Triglyceride Clearance (CC)", "typical", "Standard APOC3 expression.", "Normal baseline triglycerides."),
        G("Elevated Triglyceride Risk (CG)", "notable", "One G allele. Moderately higher circulating triglycerides.",
          "Sensitive to high-carbohydrate and alcohol intake.",
          eat=["Limit refined sugars, high-fructose corn syrup, and alcohol; emphasize EPA/DHA omega-3s."]),
        G("High Hypertriglyceridemia Susceptibility (GG)", "caution", "Two G alleles. Significantly reduced triglyceride clearance.",
          "Predisposed to high fasting triglycerides and remnant cholesterol.",
          eat=["Strict low-sugar, low-alcohol diet; high-dose marine omega-3s (2–3g/day EPA/DHA) effectively lower triglycerides."],
          recover=["Monitor fasting lipid panel with advanced particle testing."]),
    )

    add(
        "rs328", "LPL", "Lipoprotein Lipase (Ser447Ter / Cardioprotective Variant)", "8", 19819724,
        ["cardio", "lipids", "longevity"], "strong", "C", "G",
        "LPL hydrolyzes triglycerides in chylomicrons and VLDL. The G allele (447Ter) is a premature stop codon that creates a super-active LPL enzyme, leading to lower plasma triglycerides and higher HDL-C.",
        G("Typical LPL (CC)", "typical", "Standard lipoprotein lipase activity.", "Standard baseline lipid clearance."),
        G("Enhanced Triglyceride Clearance / Cardioprotective (CG)", "advantageous",
          "One 447Ter allele. ~15–20% lower plasma triglycerides and higher HDL.",
          "Conveys natural genetic protection against coronary artery disease.",
          eat=["Maintain balanced healthy fats; excellent genetic buffer for triglyceride clearance."]),
        G("Super-Active LPL Homozygote (GG)", "advantageous",
          "Two 447Ter alleles. Rapid triglyceride clearance and elevated HDL-C.",
          "Significant lifetime cardioprotection.",
          eat=["Standard cardioprotective whole food lifestyle."]),
    )

    # --- 2.0 expansion: lipid loci, blood pressure, arrhythmia, thrombosis ---
    add(
        "rs599839", "SORT1/PSRC1", "LDL & CAD Locus (1p13)", "1", 109822166,
        ["cardio", "lipids"], "strong", "A", "G",
        "The 1p13 SORT1 locus is the strongest common LDL-cholesterol locus: the G allele lowers LDL-C ~5-8 mg/dL and CAD risk via hepatic sortilin expression.",
        G("Higher-LDL-leaning (AA)", "typical", "Reference pair; slightly higher average LDL-C.", "Diet, weight, and (if indicated) clinician-managed lipid therapy dominate LDL far beyond this locus."),
        G("Intermediate (AG)", "typical", "One protective allele.", "Intermediate average LDL-C."),
        G("Protective pair (GG)", "advantageous", "Two LDL-lowering alleles.", "~10-15 mg/dL lower average LDL-C and modestly lower CAD odds."),
        tier="well-replicated", transferability="multi-ancestry",
        effect="~5-8 mg/dL LDL-C per allele; CAD OR ~0.9 — modest",
        citations=[C(20686565, "Musunuru 2010, Nature — SORT1 functional dissection"), C(19474294, "CARDIoGRAM")],
    )
    add(
        "rs4977574", "CDKN2B-AS1", "9p21 Core CAD Variant", "9", 22098574,
        ["cardio"], "strong", "A", "G",
        "Core 9p21.3 CAD signal (ANRIL locus) — the most replicated common coronary-disease association; mechanism runs through vascular smooth-muscle proliferation, independent of lipids.",
        G("Reference (AA)", "typical", "Baseline 9p21 contribution.", "Standard prevention fundamentals apply."),
        G("One risk allele (AG)", "typical", "OR ~1.15 average.", "Modifiable factors dwarf this."),
        G("Two risk alleles (GG)", "notable", "OR ~1.3-1.5 vs non-carriers.", "Worth folding into an honest family-history conversation; not a diagnosis.",
          move=["Zone-2 aerobic base + blood-pressure and ApoB awareness is the rational response to 9p21 risk."]),
        tier="well-replicated", effect="OR ~1.2 per allele — modest",
        transferability="euro-biased",
        citations=[C(19474294, "CARDIoGRAM meta-analysis"), C(GWAS, "9p21 replication across cohorts; weaker in African ancestry")],
    )
    add(
        "rs10757278", "CDKN2B-AS1", "9p21 Companion Signal", "9", 22124477,
        ["cardio"], "strong", "A", "G",
        "Companion 9p21 SNP in strong LD with rs4977574/rs1333049; carried for chip-coverage redundancy.",
        G("Reference (AA)", "typical", "Baseline.", "See the 9p21 core entry."),
        G("One risk allele (AG)", "typical", "Modest CAD odds increase.", "See 9p21 core entry."),
        G("Two risk alleles (GG)", "notable", "OR ~1.3-1.5.", "Same locus as rs4977574 — not additive with it."),
        tier="well-replicated", effect="OR ~1.2 per allele (same signal as rs4977574)",
        transferability="euro-biased",
        citations=[C(17478679, "Helgadottir 2007, Science — 9p21 and MI")],
    )
    add(
        "rs17465637", "MIA3", "CAD Locus (1q41)", "1", 222823529,
        ["cardio"], "moderate", "C", "A",
        "MIA3 participates in collagen secretion; the C allele is the replicated CAD risk allele from early GWAS.",
        G("Risk pair (CC)", "typical", "OR ~1.2 vs AA.", "Small; fundamentals dominate."),
        G("Intermediate (AC)", "typical", "Intermediate.", "Small effect."),
        G("Reference (AA)", "typical", "Baseline.", "Baseline."),
        tier="replicated", effect="OR ~1.1 per allele — small",
        citations=[C(17478681, "Samani 2007, NEJM — WTCCC CAD GWAS")],
    )
    add(
        "rs1746048", "CXCL12", "CAD Locus (10q11)", "10", 44775824,
        ["cardio"], "moderate", "C", "T",
        "CXCL12 (SDF-1) guides progenitor cells to injured endothelium; the C allele carries a small replicated CAD association.",
        G("Risk pair (CC)", "typical", "Small CAD odds increase.", "Small."),
        G("Intermediate (CT)", "typical", "Intermediate.", "Small."),
        G("Reference (TT)", "typical", "Baseline.", "Baseline."),
        tier="replicated", effect="OR ~1.1 per allele",
        citations=[C(19474294, "CARDIoGRAM — CXCL12 locus")],
    )
    add(
        "rs6725887", "WDR12", "CAD Locus (2q33)", "2", 203745885,
        ["cardio"], "moderate", "T", "C",
        "WDR12-region CAD signal from CARDIoGRAM-era meta-analyses.",
        G("Reference (TT)", "typical", "Baseline.", "Baseline."),
        G("One risk allele (CT)", "typical", "Small increase.", "Small."),
        G("Risk pair (CC)", "typical", "OR ~1.25 vs TT.", "Small-moderate; fundamentals dominate."),
        tier="replicated", effect="OR ~1.1-1.15 per allele",
        citations=[C(19474294, "CARDIoGRAM — WDR12")],
    )
    add(
        "rs11206510", "PCSK9 region", "LDL Regulatory Signal (1p32)", "1", 55496039,
        ["cardio", "lipids"], "strong", "T", "C",
        "Regulatory-region variant upstream of PCSK9: the T allele associates with slightly higher LDL-C and CAD odds — the common-variant counterpart of the rare R46L story.",
        G("Higher-LDL-leaning (TT)", "typical", "Reference pair with slightly higher average LDL.", "Small."),
        G("Intermediate (CT)", "typical", "Intermediate.", "Small."),
        G("Lower-LDL-leaning (CC)", "advantageous", "Two LDL-lowering alleles.", "Few mg/dL lower average LDL-C."),
        tier="well-replicated", effect="~2-4 mg/dL LDL per allele — small",
        citations=[C(19474294, "CARDIoGRAM"), C(GWAS, "GLGC lipid meta-analyses")],
    )
    add(
        "rs6511720", "LDLR", "LDL Receptor Intronic Variant (19p13)", "19", 11202306,
        ["cardio", "lipids"], "strong", "G", "T",
        "Strongest common LDLR variant: the minor T allele associates with ~7 mg/dL lower LDL-C and meaningfully lower CAD odds, via higher receptor expression.",
        G("Reference (GG)", "typical", "Typical LDLR expression.", "Baseline."),
        G("One protective allele (GT)", "advantageous", "~7 mg/dL lower average LDL-C.", "Modest lifelong advantage."),
        G("Protective pair (TT)", "advantageous", "~14 mg/dL lower average LDL-C.", "Uncommon; strongest common LDLR advantage."),
        tier="well-replicated", effect="~7 mg/dL LDL per allele; CAD OR ~0.85 — moderate",
        transferability="multi-ancestry",
        citations=[C(GWAS, "GLGC lipid meta-analyses — LDLR rs6511720")],
    )
    add(
        "rs2228671", "LDLR", "LDL Receptor Coding Region Signal", "19", 11210912,
        ["cardio", "lipids"], "moderate", "C", "T",
        "Synonymous LDLR variant tagging a protective haplotype with lower LDL-C in European cohorts.",
        G("Reference (CC)", "typical", "Baseline.", "Baseline."),
        G("One copy (CT)", "typical", "Slightly lower average LDL-C.", "Small."),
        G("Two copies (TT)", "advantageous", "Protective haplotype pair.", "~5-8 mg/dL lower average LDL-C."),
        tier="replicated", effect="Small protective LDL association",
        citations=[C(GWAS, "LDLR haplotype lipid studies")],
    )
    add(
        "rs3764261", "CETP", "HDL Master Signal (16q13)", "16", 56993324,
        ["cardio", "lipids"], "strong", "C", "A",
        "The strongest common HDL-C locus: each A allele raises HDL-C ~3-4 mg/dL via reduced CETP activity.",
        G("Reference (CC)", "typical", "Typical CETP activity.", "Baseline HDL."),
        G("One copy (AC)", "typical", "~3-4 mg/dL higher average HDL-C.", "Modest."),
        G("High-HDL pair (AA)", "advantageous", "~6-8 mg/dL higher average HDL-C.", "Favorable lipid profile contribution — HDL is a marker, not a guaranteed shield; overall metabolic health still rules."),
        tier="well-replicated", effect="~3-4 mg/dL HDL per allele — the largest common HDL effect",
        transferability="multi-ancestry",
        citations=[C(GWAS, "GLGC HDL meta-analyses — CETP")],
    )
    add(
        "rs1800775", "CETP", "CETP Promoter (-629C>A)", "16", 56995236,
        ["cardio", "lipids"], "strong", "C", "A",
        "Classic CETP promoter variant modulating expression; the A allele raises HDL-C modestly.",
        G("Reference (CC)", "typical", "Typical CETP expression.", "Baseline."),
        G("Intermediate (AC)", "typical", "Slightly higher HDL-C.", "Small."),
        G("Higher-HDL pair (AA)", "advantageous", "Lower CETP expression, higher HDL-C.", "Modest favorable shift."),
        tier="well-replicated", effect="~2-3 mg/dL HDL per allele",
        citations=[C(GWAS, "CETP promoter lipid meta-analyses")],
    )
    add(
        "rs693", "APOB", "ApoB XbaI Variant", "2", 21232195,
        ["cardio", "lipids"], "moderate", "G", "A",
        "Classic APOB polymorphism: the A allele associates with modestly higher LDL-C/ApoB in meta-analyses.",
        G("Reference (GG)", "typical", "Baseline ApoB.", "Baseline."),
        G("Intermediate (AG)", "typical", "Slightly higher average ApoB.", "Small."),
        G("Higher-ApoB pair (AA)", "typical", "Modestly higher average LDL/ApoB.", "Diet and clinician-managed lipids dominate."),
        tier="replicated", effect="Small LDL/ApoB shift",
        citations=[C(GWAS, "APOB XbaI lipid meta-analyses")],
    )
    add(
        "rs964184", "APOA5/ZPR1", "Triglyceride Major Locus (11q23)", "11", 116648917,
        ["cardio", "lipids"], "strong", "C", "G",
        "The 11q23 APOA5 cluster is the strongest common triglyceride locus; the G allele raises TG ~15-20 mg/dL per copy and pancreatitis-relevant TG spikes when combined with alcohol/refined carbs.",
        G("Reference (CC)", "typical", "Baseline TG handling.", "Baseline."),
        G("One risk allele (CG)", "notable", "~15-20 mg/dL higher average TG.", "TGs respond dramatically to carbohydrate restriction, alcohol reduction, and omega-3s.",
          eat=["If fasting TGs run high, this genotype responds well to cutting refined carbs and alcohol; marine omega-3s help."]),
        G("Risk pair (GG)", "caution", "~30-40 mg/dL higher average TG.", "Watch fasting triglycerides on routine labs; highly lifestyle-responsive.",
          eat=["Refined-carb and alcohol discipline; discuss persistent TG >200 mg/dL with a clinician."]),
        notes="Palindromic C/G pair — orientation reviewed against GLGC frequency data.",
        tier="well-replicated", effect="~15-20 mg/dL TG per allele — the largest common TG effect",
        transferability="multi-ancestry", reviewed=True,
        citations=[C(GWAS, "GLGC triglyceride meta-analyses — APOA5/ZPR1")],
    )
    add(
        "rs662799", "APOA5", "APOA5 Promoter (-1131T>C)", "11", 116663707,
        ["cardio", "lipids"], "strong", "A", "G",
        "APOA5 -1131T>C lowers ApoA-V, impairing lipoprotein-lipase-mediated TG clearance; the G (C) allele is common in East Asia where it drives a large share of hypertriglyceridemia.",
        G("Reference (AA)", "typical", "Typical ApoA-V level.", "Baseline."),
        G("One copy (AG)", "notable", "~15 mg/dL higher average TG.", "Lifestyle-responsive.",
          eat=["Same levers: refined carbs, alcohol, omega-3s."]),
        G("Two copies (GG)", "caution", "Markedly higher average TG.", "Fasting TG monitoring is worthwhile; respond early with diet.",
          eat=["This genotype shows strong TG response to carbohydrate moderation."]),
        tier="well-replicated", effect="~15 mg/dL TG per allele; stronger in East-Asian cohorts",
        transferability="multi-ancestry",
        citations=[C(GWAS, "APOA5 -1131T>C TG meta-analyses across ancestries")],
    )
    add(
        "rs12678919", "LPL region", "Lipoprotein Lipase Regulatory Signal", "8", 19844222,
        ["cardio", "lipids"], "strong", "A", "G",
        "LPL-region regulatory variant: the G allele tags higher LPL activity — lower TG, higher HDL.",
        G("Reference (AA)", "typical", "Typical LPL activity.", "Baseline."),
        G("One favorable allele (AG)", "typical", "Lower TG / higher HDL tendency.", "Modest."),
        G("Favorable pair (GG)", "advantageous", "Strongest common LPL-activity advantage.", "Favorable TG/HDL profile contribution."),
        tier="well-replicated", effect="Moderate TG/HDL shift",
        citations=[C(GWAS, "GLGC — LPL locus")],
    )
    add(
        "rs2954029", "TRIB1", "TRIB1 Lipid Pleiotropy (8q24)", "8", 126490972,
        ["cardio", "lipids"], "strong", "A", "T",
        "TRIB1 regulates hepatic lipogenesis: one variant moves TG, LDL, HDL, and CAD risk together — a good example of pleiotropy.",
        G("Risk-leaning (AA)", "typical", "Slightly less favorable lipid set.", "Small."),
        G("Intermediate (AT)", "typical", "Intermediate.", "Small."),
        G("Favorable (TT)", "typical", "Slightly favorable lipid set.", "Small."),
        notes="Palindromic A/T pair — orientation reviewed.",
        tier="well-replicated", effect="Small pleiotropic lipid shifts", reviewed=True,
        citations=[C(GWAS, "GLGC/CARDIoGRAM — TRIB1")],
    )
    add(
        "rs1883025", "ABCA1", "HDL Efflux Transporter Variant", "9", 107664301,
        ["cardio", "lipids"], "moderate", "C", "T",
        "ABCA1 loads cholesterol onto nascent HDL; the T allele associates with modestly lower HDL-C.",
        G("Reference (CC)", "typical", "Typical efflux.", "Baseline."),
        G("Intermediate (CT)", "typical", "Slightly lower HDL-C.", "Small."),
        G("Lower-HDL pair (TT)", "typical", "~2-4 mg/dL lower average HDL-C.", "Aerobic exercise raises HDL for every genotype."),
        tier="replicated", effect="~1-2 mg/dL HDL per allele",
        citations=[C(GWAS, "GLGC — ABCA1")],
    )
    add(
        "rs11887534", "ABCG8", "Gallstone & Sterol Absorption (D19H)", "2", 44066247,
        ["cardio", "lipids", "gut"], "strong", "G", "C",
        "ABCG5/G8 pumps sterols back into bile and gut lumen. D19H increases biliary cholesterol saturation: the strongest common gallstone risk factor, and it modestly shifts plant-sterol absorption.",
        G("Reference (GG)", "typical", "Typical sterol excretion.", "Baseline gallstone odds."),
        G("One 19H allele (CG)", "notable", "Gallstone OR ~2.",
          "Meaningful only alongside other stone factors (rapid weight loss, estrogen, fasting patterns); favor gradual weight change and regular meal rhythm.",
          eat=["Avoid crash diets; slow weight loss and regular meals reduce stone-formation windows."]),
        G("Two 19H alleles (CC)", "notable", "Rare; higher biliary cholesterol saturation.", "Same behavioral levers, stronger reason."),
        notes="Palindromic G/C pair — orientation reviewed.",
        tier="well-replicated", effect="Gallstone OR ~2 per allele — the largest common effect",
        reviewed=True,
        citations=[C(17632509, "Buch 2007, Nat Genet — ABCG8 D19H and gallstones")],
    )
    add(
        "rs2075650", "TOMM40/APOE region", "19q13 Lipid/Longevity Region Tag", "19", 45395619,
        ["cardio", "lipids", "longevity"], "strong", "A", "G",
        "TOMM40 tag in the APOE region: tracks the ε4 haplotype in Europeans. Included for chip redundancy — interpret APOE via rs429358/rs7412, not this tag.",
        G("Reference (AA)", "typical", "ε4-haplotype tag absent.", "See the APOE compound card for the real diplotype."),
        G("One tag allele (AG)", "typical", "ε4-haplotype tag present once.", "Defer to rs429358/rs7412."),
        G("Two tag alleles (GG)", "typical", "ε4-haplotype tag on both copies.", "Defer to rs429358/rs7412."),
        tier="well-replicated", effect="Tag SNP only — interpret via APOE proper",
        citations=[C(GWAS, "TOMM40/APOE LD structure literature")],
    )
    add(
        "rs1378942", "CSK", "Blood Pressure Signal (15q24)", "15", 75077367,
        ["cardio"], "strong", "A", "C",
        "CSK-region variant from large blood-pressure GWAS; the C allele associates with ~0.4 mmHg higher systolic BP — honest about how tiny common BP effects are.",
        G("Reference (AA)", "typical", "Baseline.", "Sodium, weight, sleep, and alcohol dominate BP."),
        G("Intermediate (AC)", "typical", "+~0.4 mmHg average.", "Tiny."),
        G("Risk pair (CC)", "typical", "+~0.8 mmHg average.", "Tiny — measure BP yearly like everyone should."),
        tier="well-replicated", effect="~0.4 mmHg per allele — tiny",
        citations=[C(19430483, "Newton-Cheh 2009, Nat Genet — Global BPgen")],
    )
    add(
        "rs17249754", "ATP2B1", "Blood Pressure Signal (12q21)", "12", 90060586,
        ["cardio"], "strong", "G", "A",
        "ATP2B1 encodes a calcium pump in vascular smooth muscle; among the largest common BP effects (still under 1 mmHg per allele).",
        G("Risk-leaning (GG)", "typical", "Slightly higher average BP.", "Tiny."),
        G("Intermediate (AG)", "typical", "Intermediate.", "Tiny."),
        G("Reference (AA)", "typical", "Baseline.", "Baseline."),
        tier="well-replicated", effect="<1 mmHg per allele",
        citations=[C(GWAS, "ICBP blood-pressure meta-analyses — ATP2B1")],
    )
    add(
        "rs5063", "NPPA", "Atrial Natriuretic Peptide (V32M)", "1", 11906068,
        ["cardio"], "moderate", "G", "A",
        "NPPA variants shift natriuretic-peptide levels; the A allele associates with slightly higher ANP and lower BP.",
        G("Reference (GG)", "typical", "Typical ANP.", "Baseline."),
        G("One copy (AG)", "typical", "Slightly higher ANP / lower BP tendency.", "Small."),
        G("Two copies (AA)", "typical", "Rare; small favorable BP shift.", "Small."),
        tier="replicated", effect="~1 mmHg scale — small",
        citations=[C(GWAS, "NPPA/NPPB natriuretic-peptide BP studies (Newton-Cheh 2009)")],
    )
    add(
        "rs2200733", "PITX2 region", "Atrial Fibrillation Lead Locus (4q25)", "4", 111710169,
        ["cardio"], "strong", "C", "T",
        "The 4q25/PITX2 region is the strongest common atrial-fibrillation locus: PITX2 patterns the pulmonary-vein myocardium where AF typically triggers.",
        G("Reference (CC)", "typical", "Baseline AF odds.", "Alcohol, sleep apnea, BP, and endurance-extremes are the modifiable AF levers."),
        G("One risk allele (CT)", "notable", "AF OR ~1.7.", "Worth knowing if palpitations ever appear — irregular-pulse checks (or a watch ECG) are cheap.",
          recover=["If you notice fluttering/irregular pulse episodes, capture a rhythm strip (smartwatch ECG) and show a clinician."]),
        G("Two risk alleles (TT)", "caution", "AF OR ~2.5-3 vs CC.", "Strongest common AF genotype; still absolute-risk-modest at younger ages. Moderate alcohol and treat sleep apnea seriously.",
          recover=["Alcohol moderation and sleep-apnea screening carry outsized value with this genotype."]),
        tier="well-replicated", effect="OR ~1.7 per allele — large for a common variant",
        transferability="multi-ancestry",
        citations=[C(17603472, "Gudbjartsson 2007, Nature — 4q25 and atrial fibrillation")],
    )
    add(
        "rs10965219", "CDKN2B region", "9p21 Companion (CAD/Stroke axis)", "9", 22081397,
        ["cardio"], "moderate", "G", "A",
        "Additional 9p21 tag covering chip variation; same underlying haplotype as the core CAD signal.",
        G("Risk-leaning (GG)", "typical", "Tracks the 9p21 risk haplotype.", "See rs4977574."),
        G("Intermediate (AG)", "typical", "Intermediate.", "See rs4977574."),
        G("Reference (AA)", "typical", "Baseline.", "See rs4977574."),
        tier="replicated", effect="Same signal as the 9p21 core", transferability="euro-biased",
        citations=[C(19474294, "CARDIoGRAM — 9p21 haplotype")],
    )
    add(
        "rs505922", "ABO", "ABO Locus — VTE & vWF Axis", "9", 136149229,
        ["cardio", "clotting"], "strong", "T", "C",
        "ABO intronic variant tagging non-O blood groups: the C allele (non-O tag) associates with ~25-50% higher von-Willebrand-factor levels and venous-thrombosis OR ~1.5 — the biggest common VTE factor after Factor V Leiden.",
        G("O-group tag pair (TT)", "advantageous", "Tags blood group O.", "Lower average vWF/FVIII and modestly lower VTE odds."),
        G("Mixed (CT)", "typical", "One non-O tag.", "Intermediate vWF levels."),
        G("Non-O tag pair (CC)", "notable", "Tags non-O groups.", "VTE OR ~1.5-1.8 vs O; matters mainly when combined with other factors (immobility, surgery, estrogen, Leiden).",
          recover=["On long-haul flights or post-surgery, take movement/hydration/compression basics seriously."]),
        tier="well-replicated", effect="VTE OR ~1.5 for non-O — moderate",
        transferability="multi-ancestry",
        citations=[C(GWAS, "ABO VTE and vWF meta-analyses (INVENT consortium)")],
    )
    add(
        "rs2066865", "FGG", "Fibrinogen Gamma Haplotype (VTE)", "4", 155525276,
        ["cardio", "clotting"], "strong", "G", "A",
        "FGG haplotype reducing the fibrinogen γ' isoform, which normally dampens thrombin; the A allele carries a replicated VTE association.",
        G("Reference (GG)", "typical", "Typical γ' fibrinogen.", "Baseline."),
        G("One risk allele (AG)", "typical", "Small VTE odds increase.", "Relevant mainly in combination with other factors."),
        G("Risk pair (AA)", "notable", "VTE OR ~1.4-1.6.", "One more reason for standard clot-risk hygiene in high-risk windows."),
        tier="well-replicated", effect="VTE OR ~1.25 per allele",
        citations=[C(GWAS, "FGG rs2066865 VTE meta-analyses (INVENT)")],
    )
    add(
        "rs2036914", "F11", "Factor XI Level Variant (VTE)", "4", 187192481,
        ["cardio", "clotting"], "strong", "C", "T",
        "F11 regulatory variant: the C allele raises factor XI levels with a replicated VTE association.",
        G("Higher-FXI pair (CC)", "typical", "VTE OR ~1.35 vs TT.", "Combination context matters most."),
        G("Intermediate (CT)", "typical", "Intermediate.", "Small."),
        G("Reference (TT)", "typical", "Baseline.", "Baseline."),
        tier="well-replicated", effect="VTE OR ~1.15-1.2 per allele",
        citations=[C(GWAS, "F11 VTE meta-analyses (INVENT)")],
    )
    add(
        "rs1801020", "F12", "Factor XII 46C>T", "5", 176836532,
        ["cardio", "clotting"], "moderate", "G", "A",
        "F12 5'UTR variant lowering factor XII levels (the A/T allele reduces translation). Effects on thrombosis risk are debated; aPTT lab values can run long in TT without bleeding risk.",
        G("Reference (GG)", "typical", "Typical FXII.", "Baseline."),
        G("Intermediate (AG)", "typical", "Moderately lower FXII.", "Can lengthen aPTT slightly — a lab curiosity more than a risk."),
        G("Low-FXII pair (AA)", "notable", "Substantially lower FXII levels.", "Worth knowing: an unexplained long aPTT before surgery may be this genotype, not a bleeding disorder — tell the anesthesiologist genetics may explain it (they will confirm with labs)."),
        tier="replicated", effect="Strong on FXII levels; debated on thrombosis",
        citations=[C(GWAS, "F12 46C>T level/aPTT studies")],
    )
    add(
        "rs5985", "F13A1", "Factor XIII V34L (Clot Architecture)", "6", 6318795,
        ["cardio", "clotting"], "strong", "C", "A",
        "FXIII V34L accelerates fibrin cross-linking activation but yields thinner-fibered clots; the L allele shows a mild protective VTE/MI association in meta-analyses.",
        G("Reference (CC)", "typical", "Typical clot cross-linking.", "Baseline."),
        G("One 34L allele (AC)", "typical", "Slightly altered clot architecture.", "Mildly protective association."),
        G("34L pair (AA)", "advantageous", "Thinner-fibered, easier-lysed clots.", "Modest protective association against VTE in meta-analyses."),
        tier="replicated", effect="Protective OR ~0.8-0.9 — small",
        citations=[C(GWAS, "F13 V34L VTE/MI meta-analyses")],
    )
    add(
        "rs6046", "F7", "Factor VII Level Variant (R353Q)", "13", 113773159,
        ["cardio", "clotting"], "moderate", "G", "A",
        "F7 R353Q: the A (353Q) allele lowers circulating FVII ~20-25% per copy; associations with MI are inconsistent but the level effect is solid.",
        G("Reference (GG)", "typical", "Typical FVII levels.", "Baseline."),
        G("Intermediate (AG)", "typical", "~20% lower FVII.", "Level effect only."),
        G("Low-FVII pair (AA)", "typical", "~40-50% lower FVII levels.", "Usually silent; a lab curiosity worth knowing before surgery conversations."),
        tier="replicated", effect="Strong on levels; unclear on events",
        citations=[C(GWAS, "F7 R353Q level studies")],
    )
    add(
        "rs1800790", "FGB", "Fibrinogen Beta Promoter (-455G>A)", "4", 155484396,
        ["cardio", "clotting", "inflammation"], "moderate", "G", "A",
        "Classic FGB promoter variant: the A allele raises fibrinogen ~7-10 mg/dL per copy, amplified by smoking and inflammation.",
        G("Reference (GG)", "typical", "Typical fibrinogen.", "Baseline."),
        G("Intermediate (AG)", "typical", "Slightly higher fibrinogen.", "Anti-inflammatory lifestyle (and absolutely no smoking) keeps this quiet."),
        G("Higher-fibrinogen pair (AA)", "typical", "~15-20 mg/dL higher average fibrinogen.", "Smoking multiplies this — one more reason it's off the table."),
        tier="replicated", effect="~7-10 mg/dL fibrinogen per allele",
        citations=[C(GWAS, "FGB -455G>A fibrinogen meta-analyses")],
    )
    add(
        "rs2070744", "NOS3", "eNOS Promoter (-786T>C)", "7", 150690079,
        ["cardio", "fitness"], "moderate", "T", "C",
        "NOS3 promoter variant reducing eNOS transcription; the C allele associates with slightly lower NO availability — relevant to vascular tone and training response literature.",
        G("Reference (TT)", "typical", "Typical eNOS expression.", "Baseline."),
        G("Intermediate (CT)", "typical", "Modestly lower expression.", "Beets/nitrate and aerobic training upregulate NO for every genotype."),
        G("Lower-expression pair (CC)", "typical", "Reduced promoter activity.", "Dietary nitrate and cardio are the levers.",
          eat=["Nitrate-rich vegetables (beets, arugula) support NO independent of genotype."]),
        tier="replicated", effect="Small vascular NO shift",
        citations=[C(GWAS, "NOS3 -786T>C meta-analyses")],
    )
    add(
        "rs12041331", "PEAR1", "Platelet Aggregation Variant", "1", 156869047,
        ["cardio", "clotting"], "moderate", "G", "A",
        "PEAR1 intronic variant with replicated effects on platelet aggregation and modest interactions with aspirin response in cohort studies — no therapy implication is drawn here.",
        G("Reference (GG)", "typical", "Typical platelet aggregation.", "Baseline."),
        G("Intermediate (AG)", "typical", "Modestly altered aggregation in assays.", "Lab-level finding."),
        G("Variant pair (AA)", "typical", "Replicated aggregation difference.", "Interesting biology; any antiplatelet questions belong to a clinician."),
        tier="replicated", effect="Assay-level platelet effects; clinical impact unresolved",
        citations=[C(GWAS, "PEAR1 platelet-function studies (Lewis 2013)")],
    )
    add(
        "rs11556924", "ZC3HC1", "CAD Locus (7q32)", "7", 129663496,
        ["cardio"], "moderate", "C", "T",
        "ZC3HC1 (NIPA) cell-cycle gene with a replicated CAD association from CARDIoGRAM.",
        G("Risk pair (CC)", "typical", "Small CAD odds increase.", "Small."),
        G("Intermediate (CT)", "typical", "Intermediate.", "Small."),
        G("Reference (TT)", "typical", "Baseline.", "Baseline."),
        tier="replicated", effect="OR ~1.1 per allele",
        citations=[C(21378990, "Schunkert 2011, Nat Genet — CARDIoGRAM 13 new loci")],
    )
    add(
        "rs9982601", "KCNE2 region", "CAD Locus (21q22)", "21", 35599128,
        ["cardio"], "moderate", "C", "T",
        "21q22 CAD signal near KCNE2 from early meta-analyses.",
        G("Reference (CC)", "typical", "Baseline.", "Baseline."),
        G("One risk allele (CT)", "typical", "Small increase.", "Small."),
        G("Risk pair (TT)", "typical", "OR ~1.35 vs CC.", "Fundamentals dominate."),
        tier="replicated", effect="OR ~1.15 per allele",
        citations=[C(19198609, "Myocardial Infarction Genetics Consortium 2009, Nat Genet")],
    )
    add(
        "rs2070895", "LIPC", "Hepatic Lipase Promoter (-514C>T)", "15", 58723675,
        ["cardio", "lipids"], "moderate", "G", "A",
        "Hepatic lipase remodels HDL and IDL particles. The A (-514T) allele lowers expression: higher HDL-C but larger, less-remodeled particles — a nuanced lipid variant.",
        G("Reference (GG)", "typical", "Typical hepatic lipase activity.", "Baseline HDL remodeling."),
        G("One low-expression allele (AG)", "typical", "Modestly higher HDL-C.", "Small favorable-looking shift."),
        G("Low-expression pair (AA)", "typical", "Higher HDL-C with altered particle remodeling.", "A reminder that 'higher HDL' is not automatically protective — particle function matters."),
        tier="replicated", effect="~2-3 mg/dL HDL per allele",
        citations=[C(GWAS, "LIPC -514C>T lipid meta-analyses")],
    )
    add(
        "rs1800206", "PPARA", "PPAR-alpha L162V (Lipid Response)", "22", 46614274,
        ["cardio", "lipids", "metabolism"], "moderate", "C", "G",
        "PPARα governs hepatic fat oxidation and fibrate response. L162V increases transactivation with small effects on lipids and their dietary-fat response.",
        G("Leu/Leu (CC)", "typical", "Reference receptor.", "Baseline."),
        G("Leu/Val (CG)", "typical", "Modestly altered lipid response.", "Small; diet quality dominates."),
        G("Val/Val (GG)", "typical", "Rare; stronger transactivation shift.", "Small dietary-fat interaction signals in cohorts."),
        notes="Palindromic C/G site — reviewed.",
        tier="tendency", effect="Small, diet-interacting", reviewed=True,
        citations=[C(GWAS, "PPARA L162V lipid interaction studies")],
    )
    add(
        "rs5082", "APOA2", "ApoA-II Promoter (-265T>C) — Saturated Fat Interaction", "1", 161193683,
        ["cardio", "lipids", "nutrition", "weight"], "moderate", "A", "G",
        "The classic gene-diet interaction variant: CC homozygotes showed higher BMI specifically under high saturated-fat intake across three replicated cohorts.",
        G("Reference (AA)", "typical", "No interaction genotype.", "Baseline."),
        G("Intermediate (AG)", "typical", "One C allele.", "Baseline."),
        G("Saturated-fat-sensitive (GG)", "notable", "CC-equivalent pair.", "Replicated interaction: higher BMI at high saturated-fat intake but NOT at low intake — genotype-conditional dietary advice at its most concrete.",
          eat=["Keep saturated fat moderate (<22 g/day was the study threshold) — this genotype amplifies its weight effect."]),
        tier="replicated", effect="Interaction effect ~+1 BMI unit under high saturated fat",
        citations=[C(19901139, "Corella 2009, Arch Intern Med — APOA2 × saturated fat, 3 cohorts")],
    )
    add(
        "rs854560", "PON1", "Paraoxonase L55M (Pesticide/Lipid Oxidation Axis)", "7", 94946084,
        ["cardio", "detox", "antioxidant"], "moderate", "A", "T",
        "PON1 detoxifies oxidized lipids and organophosphates. L55M lowers enzyme stability; pairs with Q192R for the functional read.",
        G("Met/Met (AA)", "typical", "Lower-stability pair.", "Modestly lower PON1 levels; dietary antioxidants and not smoking support the same axis."),
        G("Leu/Met (AT)", "typical", "Intermediate.", "Baseline."),
        G("Leu/Leu (TT)", "typical", "Reference stability.", "Baseline."),
        notes="Palindromic A/T site — reviewed.",
        tier="replicated", effect="Level shift; clinical endpoints mixed", reviewed=True,
        citations=[C(GWAS, "PON1 L55M functional studies")],
    )
