"""Metabolic, glucose, insulin & body composition — curated chip-callable markers."""
from .common import G, C, CHIPS_ALL, PGKB, GWAS, CLIN, CPIC


def register(add):
    add(
        "rs7903146", "TCF7L2", "Transcription Factor 7-Like 2 (Type 2 Diabetes Locus / Intron 3)", "10", 114758349,
        ["glucose", "metabolism"], "strong", "C", "T",
        "TCF7L2 is the strongest and most consistently replicated genetic locus for Type 2 Diabetes worldwide. The T allele impairs GLP-1 signaling, proinsulin processing, and pancreatic beta-cell insulin secretion.",
        G("Typical Diabetes Risk (CC)", "typical", "Two wild-type C alleles.", "Standard baseline risk for Type 2 Diabetes."),
        G("Elevated Diabetes Susceptibility (CT)", "notable",
          "One T allele. ~1.4x increased lifetime risk of Type 2 Diabetes.",
          "Impaired incretin (GLP-1) response and lower beta-cell capacity under chronic glycemic load.",
          eat=["Adopt a low-glycemic, high-fiber dietary pattern to minimize postprandial insulin demand.", "Prioritize protein and fiber before starches in meals."],
          move=["Perform post-meal 10–15 minute walks to clear glucose via muscle contraction without requiring insulin."]),
        G("High Diabetes Susceptibility (TT)", "caution",
          "Two T alleles. ~2.0x increased lifetime risk of Type 2 Diabetes.",
          "Significant genetic impairment in beta-cell insulin secretory reserve. Highly responsive to lifestyle intervention—exercise and carbohydrate moderation can completely overcome the genetic risk.",
          eat=["Emphasize a low-glycemic Mediterranean or low-carbohydrate approach with generous healthy fats and fiber.", "Avoid sugary beverages, refined starches, and ultra-processed carbohydrates."],
          move=["Regular resistance training increases skeletal muscle glucose disposal independent of insulin."],
          recover=["Monitor fasting glucose and HbA1c at annual medical checkups."]),
        notes="The single most important single-SNP predictor of beta-cell vulnerability in human genetics.",
    )

    add(
        "rs1801282", "PPARG", "Peroxisome Proliferator-Activated Receptor Gamma (Pro12Ala)", "3", 12393125,
        ["glucose", "metabolism", "lipids"], "strong", "C", "G",
        "PPARG is the master regulator of adipogenesis and insulin sensitivity (the target of thiazolidinediones). The G allele (Ala12) reduces PPARG transcriptional activity, conferring enhanced insulin sensitivity and ~20% lower Type 2 Diabetes risk.",
        G("Standard PPARG / Pro12 (CC)", "typical", "Standard Pro12 allele. Typical adipocyte differentiation.", "Standard baseline insulin sensitivity."),
        G("Enhanced Insulin Sensitivity / Ala12 Carrier (CG)", "advantageous",
          "One Ala12 allele. Favorable adipocyte metabolism and enhanced whole-body insulin sensitivity.",
          "Protective against diabetes and metabolic syndrome, particularly when paired with a diet rich in monounsaturated fats.",
          eat=["Extra virgin olive oil, avocados, and nuts actively support PPARG-mediated insulin sensitivity."]),
        G("High Insulin Sensitivity (GG)", "advantageous",
          "Two Ala12 alleles. Highest genetic insulin sensitivity.",
          "Protective against metabolic dysfunction across diverse dietary conditions.",
          eat=["Maintain balanced whole food nutrition."]),
    )

    add(
        "rs5219", "KCNJ11", "Potassium Inwardly-Rectifying Channel (E23K / Kir6.2)", "11", 17409572,
        ["glucose", "metabolism"], "strong", "C", "T",
        "KCNJ11 forms the pore of the ATP-sensitive potassium (K-ATP) channel in pancreatic beta cells. The T allele (Lys23) over-activates the channel, keeping it open and reducing insulin release in response to glucose.",
        G("Typical (CC)", "typical", "Normal K-ATP channel gating.", "Normal insulin secretion threshold."),
        G("Heterozygote (CT)", "notable", "One Lys23 allele. Mildly blunted insulin secretion.", "Standard low-glycemic diet."),
        G("Reduced Insulin Secretion (TT)", "caution", "Two Lys23 alleles. Impaired beta-cell glucose-stimulated insulin release.",
          "Contributes to higher postprandial glucose spikes.",
          eat=["Focus on low glycemic index foods, lean proteins, and fiber to prevent sharp glucose spikes."]),
    )

    add(
        "rs9939609", "FTO", "Fat Mass and Obesity-Associated Gene (Appetite & Satiety Signaling)", "16", 53820527,
        ["metabolism", "weight", "nutrition"], "strong", "A", "T",
        "FTO intron 1 variants alter IRX3/IRX5 expression in the hypothalamus and adipose tissue, increasing circulating ghrelin (hunger hormone), blunting post-meal satiety, and promoting caloric intake.",
        G("Typical Appetite Signaling (TT)", "typical", "Two T alleles. Standard baseline hunger and satiety regulation.", "Baseline obesity risk."),
        G("Elevated Appetite & Caloric Drive (AT)", "notable",
          "One A allele. ~1.2x higher likelihood of higher BMI if diet is unstructured.",
          "Tendency toward larger portion sizes and stronger cravings for calorie-dense foods.",
          eat=["Anchor meals with 30–40g of high-quality protein and high-volume fiber to maximize satiety signals.", "Eat meals mindfully without digital distractions."]),
        G("High Caloric Drive / Satiety Deficit (AA)", "caution",
          "Two A alleles. Associated with elevated baseline ghrelin and delayed post-meal fullness.",
          "Stronger biological pull toward snacking and hyperpalatable foods. Highly responsive to high-protein diets and physical exercise, which completely normalize the FTO risk.",
          eat=["High-protein dietary strategy (1.6–2.2 g/kg body weight) effectively blunts FTO-mediated hunger.", "Avoid liquid calories and keep trigger foods out of the house."],
          move=["Regular physical exercise is proven to attenuate the genetic effect of the FTO risk allele by over 70%."]),
        notes="A major locus for behavioral appetite regulation, heavily modulated by protein intake and movement.",
    )

    add(
        "rs17782313", "MC4R", "Melanocortin 4 Receptor (Hypothalamic Satiety / Obesity Tag)", "18", 58006845,
        ["metabolism", "weight"], "strong", "C", "T",
        "MC4R acts in the leptin-melanocortin satiety pathway in the hypothalamus. The C allele is associated with blunted leptin signaling, higher ad libitum food intake, and increased risk of adiposity.",
        G("Typical MC4R (TT)", "typical", "Standard hypothalamic satiety response.", "Baseline weight regulation."),
        G("Heterozygote (CT)", "notable", "One C allele. Moderately reduced satiety signaling.",
          "Benefits from structured meal routines and mindful eating.",
          eat=["Focus on protein, fiber, and structured meal timings."]),
        G("Reduced Satiety Response (CC)", "caution", "Two C alleles. Impaired fullness signaling.",
          "Prone to continuous snacking and binge eating behavior under stress.",
          eat=["Structured meal planning with designated portion sizes.", "Prioritize high-satiety index foods (potatoes, fish, oatmeal, lean meat)."]),
    )

    add(
        "rs738409", "PNPLA3", "Patatin-Like Phospholipase Domain-Containing 3 (I148M / Fatty Liver)", "22", 44324727,
        ["metabolism", "lipids", "alcohol"], "strong", "C", "G",
        "PNPLA3 (adiponutrin) mediates triacylglycerol hydrolysis in hepatic lipid droplets. The G allele (148M) impairs enzymatic clearance, leading to hepatic triglyceride accumulation and markedly increased risk of non-alcoholic fatty liver disease (NAFLD) and alcohol-induced liver damage.",
        G("Typical Hepatic Lipid Clearance (CC)", "typical", "Normal PNPLA3 lipase activity.", "Standard baseline liver fat risk."),
        G("Elevated Fatty Liver Susceptibility (CG)", "caution",
          "One G allele. ~2x increased risk of hepatic steatosis (NAFLD).",
          "Liver is particularly sensitive to high-fructose corn syrup, refined sugars, and alcohol.",
          eat=["Strictly eliminate sugary drinks, high-fructose corn syrup, and excess refined carbohydrates.", "Adopt a Mediterranean diet rich in choline and omega-3s."],
          substances=["Moderate alcohol consumption; avoid heavy drinking episodes."]),
        G("High Fatty Liver & Cirrhosis Risk (GG)", "caution",
          "Two G alleles. ~4–5x increased risk of NAFLD, NASH, and hepatic fibrosis.",
          "Pronounced genetic vulnerability to hepatic fat accumulation even at normal body weight (lean NAFLD).",
          eat=["Strict avoidance of added sugars, refined fructose, and ultra-processed seed oils.", "Ensure robust dietary choline (eggs) and omega-3 EPA/DHA to support hepatic VLDL secretion."],
          substances=["Strongly advised to minimize or completely eliminate alcohol consumption to protect liver tissue."],
          recover=["Monitor liver enzymes (ALT, AST, GGT) and consider a liver ultrasound/FibroScan in routine checkups."]),
        notes="The single most potent genetic risk factor for hepatic steatosis (fatty liver).",
    )


    add(
        "rs13266634", "SLC30A8", "Zinc Transporter 8 (ZnT-8 / Arg325Trp / Beta-Cell Protection)", "8", 118184783,
        ["glucose", "metabolism", "vitamins"], "strong", "C", "T",
        "SLC30A8 transports zinc into pancreatic beta-cell insulin secretory granules for insulin crystallization. The T allele (325Trp) preserves zinc transport and is protective against Type 2 Diabetes.",
        G("High Beta-Cell Zinc Crystallization (TT)", "advantageous", "Two protective alleles.", "Optimal insulin crystallization and beta-cell longevity."),
        G("Intermediate (CT)", "typical", "Balanced zinc transport.", "Ensure adequate dietary zinc."),
        G("Reduced Beta-Cell Zinc Transport (CC)", "notable", "Lower ZnT-8 transport efficiency.",
          "Higher dietary requirement for zinc to maintain optimal insulin packaging.",
          eat=["Include zinc-rich foods (oysters, pumpkin seeds, grass-fed beef) in your dietary rotation."]),
    )

    add(
        "rs1042713", "ADRB2", "Beta-2 Adrenergic Receptor (Arg16Gly / Fat Oxidation During Exercise)", "5", 148206442,
        ["fitness", "metabolism", "weight"], "strong", "A", "G",
        "ADRB2 mediates catecholamine-induced lipolysis in adipose tissue. The G allele (Gly16) causes enhanced receptor downregulation upon agonist stimulation, making fat loss more reliant on high-intensity exercise.",
        G("High Lipolytic Sensitivity (AA / Arg16)", "advantageous",
          "Two Arg16 alleles. Resilient beta-2 adrenergic signaling in fat cells.",
          "Mobilizes stored triglycerides efficiently in response to caloric restriction and moderate exercise.",
          move=["Responds well to steady-state Zone 2 cardio for fat oxidation."]),
        G("Intermediate Lipolysis (AG)", "typical", "Balanced beta-adrenergic response.", "Standard fat loss response."),
        G("Lower Lipolytic Sensitivity (GG / Gly16)", "notable",
          "Two Gly16 alleles. Receptors downregulate more rapidly.",
          "Fat loss is optimized by high-intensity interval training (HIIT) and resistance training rather than steady-state cardio alone.",
          move=["Incorporate HIIT sprints and compound lifting to overcome receptor downregulation."]),
    )

    add(
        "rs1801198", "TCN2", "Transcobalamin II (Pro259Arg / Cellular B12 Delivery)", "22", 31012356,
        ["vitamins", "methylation"], "strong", "C", "G",
        "TCN2 encodes Transcobalamin II, the primary carrier delivering active vitamin B12 from blood into peripheral tissues and the brain. The G allele (Arg259) reduces B12 delivery efficiency.",
        G("Optimal Cellular B12 Delivery (CC)", "typical", "High transcobalamin affinity.", "Efficient cellular B12 uptake."),
        G("Intermediate (CG)", "typical", "Standard B12 transport.", "Maintain standard B12 intake."),
        G("Reduced Cellular B12 Delivery (GG)", "notable", "Lower efficiency of peripheral B12 delivery.",
          "Serum B12 may appear normal while intracellular B12 is suboptimal.",
          vitamins=["Ensure regular active B12 intake (methylcobalamin/adenosylcobalamin) and check methylmalonic acid (MMA) if fatigue occurs."]),
    )

    add(
        "rs11558538", "HNMT", "Histamine N-Methyltransferase (Thr105Ile / Brain Histamine Clearance)", "2", 138760076,
        ["histamine", "cognition", "sleep"], "strong", "C", "T",
        "HNMT is the primary enzyme inactivating histamine in the central nervous system and bronchial tissues via methylation. The T allele (105Ile) destabilizes the enzyme, causing slow clearance of brain histamine (leading to insomnia, racing thoughts, and allergic reactivity).",
        G("Typical Brain Histamine Clearance (CC)", "typical", "Standard HNMT activity.", "Normal central histamine clearance."),
        G("Intermediate HNMT (CT)", "typical", "Moderately slowed central histamine breakdown.", "Standard sleep hygiene."),
        G("Slow Central Histamine Clearance (TT)", "caution",
          "Two T alleles. Marked reduction in brain HNMT activity.",
          "Histamine stays elevated in the brain, promoting hyper-vigilance, difficulty falling asleep with a racing mind, and allergic headaches.",
          sleep=["Avoid high-histamine evening meals.", "Ensure adequate SAMe and methylation cofactors (B6, B12, folate) to support HNMT methylation."],
          mind=["Practice evening parasympathetic grounding to dampen histamine-driven neurological arousal."]),
    )

    add(
        "rs3758391", "SIRT1", "Sirtuin 1 (-1400C>T / NAD+-Dependent Longevity Deacetylase)", "10", 69640487,
        ["longevity", "cellular", "metabolism"], "strong", "C", "T",
        "SIRT1 is the primary NAD+-dependent deacetylase regulating mitochondrial health, metabolic flexibility, and DNA repair. The T allele is associated with enhanced SIRT1 transcription and favorable metabolic healthspan.",
        G("Enhanced SIRT1 Transcription (TT)", "advantageous", "Two T alleles. Favorable baseline SIRT1 expression.",
          "High metabolic flexibility and robust response to caloric restriction and NAD+ precursors.",
          longevity=["Intermittent fasting and aerobic exercise synergize powerfully with SIRT1 activation."]),
        G("Intermediate SIRT1 (CT)", "typical", "Balanced SIRT1 signaling.", "Standard longevity lifestyle."),
        G("Standard SIRT1 (CC)", "typical", "Standard baseline SIRT1 expression.", "Supports standard metabolic health."),
    )

    # --- 2.0 expansion: T2D loci, adiposity, liver, urate, thyroid, appetite hormones ---
    add(
        "rs12255372", "TCF7L2", "T2D Second Signal (G/T intronic)", "10", 114808902,
        ["glucose", "metabolism"], "strong", "G", "T",
        "Second TCF7L2 intronic signal from the original deCODE discovery, in strong LD with rs7903146; included for chip redundancy on the most important common T2D locus.",
        G("Reference (GG)", "typical", "Baseline TCF7L2 contribution.", "Interpret with rs7903146."),
        G("One risk allele (GT)", "notable", "T2D OR ~1.3 (same haplotype as rs7903146).", "Muscle mass, fiber, and post-meal walks blunt this pathway's expression."),
        G("Risk pair (TT)", "notable", "T2D OR ~1.7 vs GG.", "Annual fasting glucose/HbA1c awareness is rational.",
          eat=["Prioritize protein+fiber-first meals and post-meal movement; this genotype's risk is strongly behavior-responsive."]),
        tier="well-replicated", transferability="multi-ancestry",
        effect="OR ~1.3 per allele — tracks rs7903146",
        citations=[C(16415884, "Grant 2006, Nat Genet — TCF7L2 discovery (both SNPs)")],
    )
    add(
        "rs1260326", "GCKR", "Glucokinase Regulator (P446L) — Metabolic Trade-off", "2", 27730940,
        ["glucose", "metabolism", "lipids"], "strong", "C", "T",
        "GCKR P446L weakens glucokinase inhibition in liver: MORE glycolysis (lower fasting glucose) but more lipogenesis (higher triglycerides and CRP) — a textbook pleiotropic trade-off variant.",
        G("Reference (CC)", "typical", "Typical GCKR restraint.", "Baseline glucose/TG balance."),
        G("One 446L allele (CT)", "typical", "Slightly lower fasting glucose, slightly higher TG.", "The trade-off is small; refined-carb restraint keeps the TG side quiet."),
        G("Trade-off pair (TT)", "notable", "Lower fasting glucose but ~10-15 mg/dL higher average TG.", "If labs show 'great glucose, mediocre triglycerides', this genotype may be why.",
          eat=["TG side responds to cutting refined carbs/alcohol and adding omega-3s."]),
        tier="well-replicated", transferability="multi-ancestry",
        effect="Fasting glucose −0.06 mmol/L, TG +8-10 mg/dL per allele",
        citations=[C(GWAS, "MAGIC/GLGC — GCKR P446L pleiotropy (Orho-Melander 2008)")],
    )
    add(
        "rs780094", "GCKR", "GCKR Intronic Proxy", "2", 27741237,
        ["glucose", "metabolism"], "strong", "C", "T",
        "Intronic proxy of GCKR P446L; same trade-off signal, carried for chip redundancy.",
        G("Reference (CC)", "typical", "Baseline.", "See rs1260326."),
        G("Intermediate (CT)", "typical", "Trade-off intermediate.", "See rs1260326."),
        G("Trade-off pair (TT)", "typical", "Lower glucose / higher TG pattern.", "See rs1260326."),
        tier="well-replicated", effect="Proxy of P446L",
        citations=[C(GWAS, "MAGIC — GCKR locus")],
    )
    add(
        "rs1799884", "GCK", "Glucokinase Promoter (-30G>A)", "7", 44229068,
        ["glucose"], "strong", "C", "T",
        "GCK -30 promoter variant raises fasting glucose ~0.06 mmol/L per allele by shifting the hepatic glucose set-point — small, stable, lifelong.",
        G("Reference (CC)", "typical", "Typical set-point.", "Baseline."),
        G("One copy (CT)", "typical", "+~0.06 mmol/L fasting glucose.", "A set-point shift, not a disease."),
        G("Two copies (TT)", "typical", "+~0.12 mmol/L average fasting glucose.", "Interpret borderline fasting readings with this in mind."),
        tier="well-replicated", effect="+0.06 mmol/L per allele",
        citations=[C(GWAS, "MAGIC fasting-glucose meta-analyses — GCK")],
    )
    add(
        "rs10885122", "ADRA2A", "Alpha-2A Receptor & Insulin Release", "10", 113042093,
        ["glucose"], "moderate", "G", "T",
        "ADRA2A over-signaling suppresses insulin granule release; this variant associates with modestly higher fasting glucose.",
        G("Reference (GG)", "typical", "Typical adrenergic restraint on beta cells.", "Baseline."),
        G("One copy (GT)", "typical", "Small fasting-glucose shift.", "Small."),
        G("Two copies (TT)", "typical", "Modest fasting-glucose elevation.", "Chronic stress (adrenergic tone) is the amplifier to manage."),
        tier="replicated", effect="+0.02-0.04 mmol/L per allele — small",
        citations=[C(GWAS, "MAGIC — ADRA2A (Dupuis 2010)")],
    )
    add(
        "rs7754840", "CDKAL1", "Beta-Cell Development Locus", "6", 20661250,
        ["glucose"], "strong", "G", "C",
        "CDKAL1 affects proinsulin processing; among the earliest replicated T2D loci with consistent beta-cell-function effects.",
        G("Risk pair (CC)", "typical", "Modestly reduced insulin secretion pattern.", "Small; training and diet dominate."),
        G("Intermediate (CG)", "typical", "Intermediate.", "Small."),
        G("Reference (GG)", "typical", "Baseline.", "Baseline."),
        notes="Palindromic C/G site — orientation reviewed.",
        tier="well-replicated", effect="T2D OR ~1.15 per allele", reviewed=True,
        transferability="multi-ancestry",
        citations=[C(GWAS, "T2D consortium meta-analyses — CDKAL1 (Zeggini 2007)")],
    )
    add(
        "rs10811661", "CDKN2A/B", "Beta-Cell Senescence Locus (9p21 diabetes side)", "9", 22134094,
        ["glucose"], "strong", "T", "C",
        "The diabetes-side signal of 9p21 (distinct from the CAD haplotype): the T allele associates with reduced beta-cell reserve.",
        G("Risk pair (TT)", "typical", "T2D OR ~1.2 vs CC.", "Beta-cell reserve is spent by chronic overfeeding — the levers are the usual ones."),
        G("Intermediate (CT)", "typical", "Intermediate.", "Small."),
        G("Reference (CC)", "typical", "Baseline.", "Baseline."),
        tier="well-replicated", effect="OR ~1.2 per allele",
        transferability="multi-ancestry",
        citations=[C(GWAS, "T2D meta-analyses — CDKN2A/B (Zeggini/Scott 2007)")],
    )
    add(
        "rs4402960", "IGF2BP2", "Insulin Secretion Locus", "3", 185511687,
        ["glucose"], "strong", "G", "T",
        "IGF2BP2 variants modestly impair insulin secretion; early replicated T2D locus.",
        G("Reference (GG)", "typical", "Baseline.", "Baseline."),
        G("One risk allele (GT)", "typical", "Small secretion effect.", "Small."),
        G("Risk pair (TT)", "typical", "T2D OR ~1.2 vs GG.", "Fundamentals dominate."),
        tier="well-replicated", effect="OR ~1.1 per allele",
        citations=[C(GWAS, "T2D meta-analyses — IGF2BP2")],
    )
    add(
        "rs1111875", "HHEX/IDE", "Hepatocyte Nuclear Factor Region (T2D)", "10", 94462882,
        ["glucose"], "strong", "C", "T",
        "HHEX/IDE region affects beta-cell development and insulin degradation; consistently replicated T2D locus.",
        G("Risk pair (CC)", "typical", "T2D OR ~1.2 vs TT.", "Small."),
        G("Intermediate (CT)", "typical", "Intermediate.", "Small."),
        G("Reference (TT)", "typical", "Baseline.", "Baseline."),
        tier="well-replicated", effect="OR ~1.1 per allele",
        citations=[C(GWAS, "T2D meta-analyses — HHEX (Sladek 2007)")],
    )
    add(
        "rs2237892", "KCNQ1", "Potassium Channel T2D Locus (East-Asian Discovery)", "11", 2839751,
        ["glucose"], "strong", "C", "T",
        "KCNQ1 was discovered in Japanese T2D GWAS and replicates across ancestries — a rare example of East-Asian-first discovery; the C allele associates with reduced insulin secretion.",
        G("Risk pair (CC)", "typical", "T2D OR ~1.3-1.4 vs TT (East-Asian data).", "Beta-cell-protective habits (sleep, activity, weight) are the levers."),
        G("Intermediate (CT)", "typical", "Intermediate.", "Small."),
        G("Reference (TT)", "typical", "Baseline.", "Less common in East-Asian ancestry."),
        tier="well-replicated", transferability="east-asian-derived",
        effect="OR ~1.2-1.4 per C allele, strongest in East-Asian cohorts",
        citations=[C(18711366, "Yasuda 2008, Nat Genet — KCNQ1 and T2D"), C(GWAS, "Cross-ancestry replication")],
    )
    add(
        "rs2943641", "IRS1", "Insulin Receptor Substrate 1 (Insulin Resistance)", "2", 227093745,
        ["glucose", "metabolism"], "strong", "C", "T",
        "IRS1-region variant associated with insulin RESISTANCE (not secretion) — the C allele carries higher fasting insulin and lower adipose insulin sensitivity.",
        G("Resistance-leaning (CC)", "typical", "Higher fasting-insulin pattern.", "Resistance training is the most direct counter — muscle is the glucose sink."),
        G("Intermediate (CT)", "typical", "Intermediate.", "Small."),
        G("Reference (TT)", "typical", "Baseline insulin sensitivity contribution.", "Baseline."),
        tier="well-replicated", effect="OR ~1.1; insulin-resistance axis",
        citations=[C(GWAS, "IRS1 insulin-resistance GWAS (Rung 2009)")],
    )
    add(
        "rs2867125", "TMEM18", "BMI Locus #2 (2p25)", "2", 622827,
        ["weight", "metabolism"], "strong", "C", "T",
        "TMEM18 is the second-strongest common BMI locus after FTO, acting through hypothalamic appetite circuits.",
        G("Higher-BMI-leaning (CC)", "typical", "~+0.3 BMI units vs TT average.", "Environment design beats willpower."),
        G("Intermediate (CT)", "typical", "Intermediate.", "Small."),
        G("Reference (TT)", "typical", "Baseline.", "Baseline."),
        tier="well-replicated", effect="~0.15 BMI units per allele",
        citations=[C(20935630, "Speliotes 2010, Nat Genet — GIANT BMI")],
    )
    add(
        "rs10938397", "GNPDA2", "BMI Locus (4p12)", "4", 45182527,
        ["weight"], "strong", "G", "A",
        "GNPDA2-region appetite-axis BMI locus from GIANT.",
        G("Higher-BMI-leaning (GG)", "typical", "Small appetite-axis push.", "Small."),
        G("Intermediate (AG)", "typical", "Intermediate.", "Small."),
        G("Reference (AA)", "typical", "Baseline.", "Baseline."),
        tier="well-replicated", effect="~0.1 BMI units per allele",
        citations=[C(20935630, "Speliotes 2010 — GIANT BMI")],
    )
    add(
        "rs543874", "SEC16B", "BMI Locus (1q25)", "1", 177889480,
        ["weight"], "strong", "G", "A",
        "SEC16B BMI locus from GIANT meta-analyses.",
        G("Higher-BMI-leaning (GG)", "typical", "Small push.", "Small."),
        G("Intermediate (AG)", "typical", "Intermediate.", "Small."),
        G("Reference (AA)", "typical", "Baseline.", "Baseline."),
        tier="well-replicated", effect="~0.1 BMI units per allele",
        citations=[C(20935630, "Speliotes 2010 — GIANT BMI")],
    )
    add(
        "rs7359397", "SH2B1", "BMI / Insulin Signaling Locus (16p11)", "16", 28885659,
        ["weight", "metabolism"], "strong", "C", "T",
        "SH2B1 enhances leptin/insulin signaling; common variants nudge BMI, rare deletions cause severe obesity (arrays can't see those — Limitations panel).",
        G("Reference (CC)", "typical", "Baseline.", "Baseline."),
        G("Intermediate (CT)", "typical", "Small push.", "Small."),
        G("Higher-BMI-leaning (TT)", "typical", "~+0.2 BMI units vs CC.", "Small."),
        tier="well-replicated", effect="~0.1 BMI units per allele",
        citations=[C(20935630, "Speliotes 2010 — GIANT BMI")],
    )
    add(
        "rs987237", "TFAP2B", "Fat Distribution Locus (6p12)", "6", 50803050,
        ["weight", "metabolism"], "moderate", "A", "G",
        "TFAP2B influences adipocyte biology and waist-related measures; also appeared in diet-response analyses (higher protein worked better for G-carriers in POUNDS-LOST — hypothesis-level).",
        G("Reference (AA)", "typical", "Baseline.", "Baseline."),
        G("Intermediate (AG)", "typical", "Small distribution shift.", "Small."),
        G("Variant pair (GG)", "typical", "Waist-leaning distribution tendency.", "Diet-composition response signals are hypothesis-level only."),
        tier="replicated", effect="Small WHR/BMI effect",
        citations=[C(GWAS, "GIANT — TFAP2B; POUNDS-LOST interaction analyses")],
    )
    add(
        "rs10195252", "GRB14/COBLL1", "Waist-Hip Ratio Locus (Insulin Sensitivity)", "2", 165513091,
        ["weight", "metabolism"], "moderate", "T", "C",
        "GRB14 region links fat distribution to insulin sensitivity; the T allele associates with higher WHR in women especially — fat-distribution genetics is strongly sex-dimorphic.",
        G("Central-leaning (TT)", "typical", "Higher-WHR tendency (female-skewed effect).", "Training and energy balance dominate."),
        G("Intermediate (CT)", "typical", "Intermediate.", "Small."),
        G("Reference (CC)", "typical", "Baseline.", "Baseline."),
        tier="replicated", effect="Small, sex-dimorphic",
        citations=[C(20935629, "Heid 2010 — GIANT WHR")],
    )
    add(
        "rs58542926", "TM6SF2", "Liver Fat vs Blood Lipids Trade-off (E167K)", "19", 19379549,
        ["metabolism", "lipids"], "strong", "C", "T",
        "TM6SF2 E167K impairs VLDL export: fat stays IN the liver (higher NAFLD risk) instead of entering blood (lower LDL/TG and modestly lower CAD risk) — a stark biological trade-off.",
        G("Reference (CC)", "typical", "Typical VLDL export.", "Baseline."),
        G("One 167K allele (CT)", "notable", "Higher liver-fat tendency, lower circulating lipids.", "Alcohol restraint and fructose moderation protect the liver side of the trade.",
          eat=["Treat alcohol and liquid fructose as the liver's main enemies with this variant."]),
        G("Two 167K alleles (TT)", "caution", "Rare; strong liver-fat accumulation tendency.", "Worth mentioning if liver enzymes ever run high — ultrasound-based liver checks are noninvasive.",
          recover=["Ask about a FibroScan/ultrasound if ALT trends high; early NAFLD reverses with weight loss."]),
        tier="well-replicated", transferability="multi-ancestry",
        effect="NAFLD OR ~1.8 per allele; LDL −4-5 mg/dL — trade-off",
        citations=[C(24531328, "Kozlitina 2014, Nat Genet — TM6SF2 and hepatic steatosis")],
    )
    add(
        "rs641738", "MBOAT7/TMC4", "Liver Fat Modifier", "19", 54676763,
        ["metabolism"], "moderate", "C", "T",
        "MBOAT7-region variant modestly increasing hepatic-fat and fibrosis tendency, additive with PNPLA3/TM6SF2.",
        G("Reference (CC)", "typical", "Baseline.", "Baseline."),
        G("One copy (CT)", "typical", "Small liver-fat push.", "Alcohol/fructose moderation."),
        G("Two copies (TT)", "typical", "Modest additive liver-fat tendency.", "Same levers as PNPLA3."),
        tier="replicated", effect="Small additive NAFLD effect",
        citations=[C(GWAS, "MBOAT7 NAFLD studies (Mancina 2016)")],
    )
    add(
        "rs1800546", "ALDOB", "Hereditary Fructose Intolerance Carrier (A149P)", "9", 104189907,
        ["metabolism", "nutrition"], "strong", "C", "G",
        "ALDOB A149P is the most common European HFI allele. HFI is recessive: carriers are healthy; two defective alleles cause severe fructose reactions (usually diagnosed in infancy). This chip sees only this one allele — a negative does NOT exclude carrier status for other ALDOB variants.",
        G("Non-carrier at this allele (CC)", "typical", "No A149P.", "Other rarer ALDOB alleles are not covered by this array."),
        G("HFI carrier (CG)", "notable", "One A149P allele — healthy carrier.", "Relevant only for family planning with another carrier; no dietary change is indicated for carriers.",
          eat=["No fructose restriction is needed for carriers; this is inheritance information, not a diet flag."]),
        G("Two A149P alleles (GG)", "caution", "HFI-pattern genotype.", "Almost always already diagnosed clinically; if truly unknown, discuss with a physician before interpreting further — do not self-diagnose from an array.",
          recover=["Clinical confirmation is essential; array homozygote calls can be wrong."]),
        notes="Palindromic C/G site — reviewed. Recessive-condition carrier information, framed accordingly.",
        tier="well-replicated", transferability="euro-biased",
        effect="Recessive: carriers unaffected; ~1 in 60 Europeans carries A149P",
        reviewed=True,
        citations=[C(CLIN, "ALDOB A149P pathogenic (HFI)"), C(GWAS, "Cross 1988 and European allele surveys")],
    )
    add(
        "rs734553", "SLC2A9", "Urate Transporter Major Locus", "4", 9922167,
        ["metabolism"], "strong", "G", "T",
        "SLC2A9 (GLUT9) reabsorbs urate in the kidney; this locus explains more serum-urate variance than any other (~2-3%), sex-dimorphic (stronger in women).",
        G("Higher-urate-leaning (GG)", "typical", "Higher average serum urate.", "Hydration, fructose moderation; urate is a cheap lab."),
        G("Intermediate (GT)", "typical", "Intermediate.", "Small."),
        G("Lower-urate (TT)", "typical", "Lower average urate.", "Baseline."),
        tier="well-replicated", effect="Largest common urate locus; gout OR ~1.3-1.5 per allele",
        transferability="multi-ancestry",
        citations=[C(18327257, "Vitart 2008, Nat Genet — SLC2A9 and urate/gout")],
    )
    add(
        "rs4293393", "UMOD", "Uromodulin (Kidney Function Tendency)", "16", 20364588,
        ["metabolism"], "moderate", "A", "G",
        "UMOD promoter variant shifting uromodulin secretion; associated with eGFR and hypertension-CKD tendency in large cohorts.",
        G("Reference (AA)", "typical", "Typical uromodulin.", "Baseline."),
        G("Intermediate (AG)", "typical", "Small shift.", "Hydration + BP control protect kidneys for everyone."),
        G("Protective pair (GG)", "typical", "Lower-uromodulin pattern with modestly better eGFR trajectory in cohorts.", "Baseline."),
        tier="replicated", effect="Small eGFR/CKD association",
        citations=[C(GWAS, "UMOD kidney-function GWAS (Köttgen 2009)")],
    )
    add(
        "rs225014", "DIO2", "Deiodinase 2 (T92A) — T4→T3 Conversion", "14", 80669580,
        ["metabolism"], "moderate", "T", "C",
        "DIO2 converts T4 to active T3 inside tissues. T92A modestly reduces conversion efficiency; studied (with mixed results) for wellbeing differences on thyroid therapy — strictly an endocrinologist conversation.",
        G("Reference (TT)", "typical", "Typical tissue T3 generation.", "Baseline."),
        G("One 92A allele (CT)", "typical", "Slightly reduced conversion.", "No action for healthy thyroid function."),
        G("Two 92A alleles (CC)", "typical", "Reduced-conversion pattern.", "Only relevant within an existing thyroid-treatment conversation with an endocrinologist."),
        tier="replicated", effect="Modest conversion shift; therapy implications unproven",
        citations=[C(GWAS, "DIO2 T92A thyroid literature — heterogeneous")],
    )
    add(
        "rs2235544", "DIO1", "Deiodinase 1 (T3/rT3 Ratio)", "1", 54375570,
        ["metabolism"], "moderate", "A", "C",
        "DIO1 variants reliably shift the circulating T3/rT3 ratio in population studies — a solid biochemical effect with minimal clinical consequence in healthy people.",
        G("Higher-T3-leaning (AA)", "typical", "Higher T3:rT3 ratio pattern.", "Biochemical curiosity in health."),
        G("Intermediate (AC)", "typical", "Intermediate.", "Baseline."),
        G("Lower-T3-leaning (CC)", "typical", "Lower T3:rT3 pattern.", "Biochemical curiosity in health."),
        tier="replicated", effect="Reliable hormone-ratio shift, minimal clinical impact",
        citations=[C(GWAS, "DIO1 thyroid-hormone GWAS (Panicker 2008)")],
    )
    add(
        "rs17300539", "ADIPOQ", "Adiponectin Promoter (-11391G>A)", "3", 186559460,
        ["metabolism"], "moderate", "G", "A",
        "ADIPOQ promoter variant with replicated effects on circulating adiponectin (insulin-sensitizing adipokine); the A allele raises levels.",
        G("Reference (GG)", "typical", "Typical adiponectin.", "Body composition moves adiponectin more than genotype."),
        G("One A allele (AG)", "typical", "Higher average adiponectin.", "Mildly favorable metabolic marker."),
        G("Two A alleles (AA)", "typical", "Highest-level pattern (uncommon).", "Mildly favorable."),
        tier="replicated", effect="Reliable level shift; downstream effect modest",
        citations=[C(GWAS, "ADIPOQ promoter adiponectin meta-analyses")],
    )
    add(
        "rs7799039", "LEP", "Leptin Promoter (-2548G>A)", "7", 127878783,
        ["weight", "metabolism"], "moderate", "G", "A",
        "Classic leptin promoter variant with modest associations to circulating leptin and obesity measures across many small studies.",
        G("GG", "typical", "Reference leptin expression.", "Leptin tracks fat mass overwhelmingly."),
        G("AG", "typical", "Intermediate.", "Small."),
        G("AA", "typical", "Modest leptin-level association.", "Sleep deprivation lowers leptin far more than genotype — protect sleep."),
        tier="tendency", effect="Small, heterogeneous",
        citations=[C(GWAS, "LEP -2548 meta-analyses")],
    )
    add(
        "rs1137101", "LEPR", "Leptin Receptor (Q223R)", "1", 66058513,
        ["weight", "metabolism"], "moderate", "A", "G",
        "LEPR Q223R changes receptor signaling efficiency; meta-analyses show small obesity-measure associations with population heterogeneity.",
        G("Gln/Gln (AA)", "typical", "Reference receptor.", "Baseline."),
        G("Gln/Arg (AG)", "typical", "Intermediate.", "Small."),
        G("Arg/Arg (GG)", "typical", "Modest association with leptin resistance measures.", "Satiety hygiene (protein, fiber, sleep) works for every genotype."),
        tier="tendency", effect="Small, heterogeneous",
        citations=[C(GWAS, "LEPR Q223R meta-analyses")],
    )
    add(
        "rs696217", "GHRL", "Ghrelin (L72M)", "3", 10328453,
        ["weight", "metabolism"], "moderate", "G", "T",
        "Ghrelin preprohormone variant with small associations to appetite/metabolic measures in cohort studies.",
        G("GG", "typical", "Reference ghrelin.", "Meal regularity shapes ghrelin rhythms."),
        G("GT", "typical", "Intermediate.", "Small."),
        G("TT", "typical", "72M pair.", "Small appetite-hormone shifts in studies."),
        tier="tendency", effect="Small",
        citations=[C(GWAS, "GHRL L72M studies")],
    )
    add(
        "rs1761667", "CD36", "Fat Taste Perception (Oral Lipid Sensing)", "7", 80300449,
        ["taste", "nutrition", "metabolism"], "moderate", "G", "A",
        "CD36 senses fatty acids on taste buds. The A allele lowers CD36 expression: reduced oral fat sensitivity, associated with higher preference for added fats in several cohorts.",
        G("Sensitive fat taster (GG)", "typical", "Higher oral fat detection.", "Typically easier satisfaction with less added fat."),
        G("Intermediate (AG)", "typical", "Intermediate.", "Baseline."),
        G("Reduced fat taster (AA)", "notable", "Lower oral fat sensitivity.", "Fat-heavy foods may under-register; plate deliberately rather than by mouthfeel.",
          eat=["Measure cooking fats rather than pouring — oral feedback under-reports for this genotype."]),
        tier="replicated", effect="Replicated psychophysical shift; dietary effect modest",
        citations=[C(GWAS, "CD36 fat-taste studies (Pepino 2012; Keller 2012)")],
    )
    add(
        "rs340874", "PROX1", "Fasting Glucose Locus (1q32)", "1", 214159256,
        ["glucose"], "moderate", "C", "T",
        "PROX1 fasting-glucose locus from MAGIC meta-analyses.",
        G("Risk-leaning (CC)", "typical", "Small fasting-glucose elevation.", "Small."),
        G("Intermediate (CT)", "typical", "Intermediate.", "Small."),
        G("Reference (TT)", "typical", "Baseline.", "Baseline."),
        tier="replicated", effect="+~0.01-0.02 mmol/L per allele — tiny",
        citations=[C(GWAS, "MAGIC — PROX1 (Dupuis 2010)")],
    )
    add(
        "rs11605924", "CRY2", "Circadian-Metabolic Glucose Locus", "11", 45873091,
        ["glucose", "circadian"], "moderate", "A", "C",
        "CRY2 links the molecular clock to gluconeogenesis; the A allele associates with slightly higher fasting glucose — biology connecting late nights to morning numbers.",
        G("Risk-leaning (AA)", "typical", "Slightly higher fasting glucose.", "Regular sleep-wake timing supports the same axis."),
        G("Intermediate (AC)", "typical", "Intermediate.", "Small."),
        G("Reference (CC)", "typical", "Baseline.", "Baseline."),
        tier="replicated", effect="+~0.02 mmol/L per allele",
        citations=[C(GWAS, "MAGIC — CRY2 (Dupuis 2010)")],
    )
    add(
        "rs7944584", "MADD", "Fasting Glucose Locus (11p11)", "11", 47336320,
        ["glucose"], "moderate", "A", "T",
        "MADD locus affecting proinsulin conversion; MAGIC fasting-glucose signal.",
        G("Risk-leaning (AA)", "typical", "Small elevation.", "Small."),
        G("Intermediate (AT)", "typical", "Intermediate.", "Small."),
        G("Reference (TT)", "typical", "Baseline.", "Baseline."),
        notes="Palindromic A/T site — reviewed.",
        tier="replicated", effect="Small", reviewed=True,
        citations=[C(GWAS, "MAGIC — MADD")],
    )
    add(
        "rs174550", "FADS1", "FADS1 Glycemic/Lipid Signal", "11", 61571478,
        ["glucose", "lipids", "nutrition"], "strong", "T", "C",
        "The FADS cluster (delta-5/6 desaturases) shows up in glucose, lipid, and omega-3 GWAS simultaneously — diet-gene interaction central. In LD with rs174546.",
        G("Reference (TT)", "typical", "Higher desaturase-activity haplotype.", "Efficient plant-omega conversion; interpret with rs174546."),
        G("Intermediate (CT)", "typical", "Intermediate.", "See rs174546."),
        G("Lower-activity pair (CC)", "typical", "Lower desaturase activity.", "Marine omega-3s bypass the bottleneck."),
        tier="well-replicated", effect="Pleiotropic lipid/glycemic shifts — modest",
        citations=[C(GWAS, "MAGIC/GLGC — FADS cluster")],
    )
    add(
        "rs2241766", "ADIPOQ", "Adiponectin Exon 2 (+45T>G)", "3", 186560645,
        ["metabolism"], "moderate", "T", "G",
        "Second classic ADIPOQ variant with small associations to adiponectin levels and insulin sensitivity across meta-analyses.",
        G("TT", "typical", "Reference.", "Body composition dominates adiponectin."),
        G("GT", "typical", "Small shift.", "Baseline."),
        G("GG", "typical", "Modest level association.", "Small."),
        tier="tendency", effect="Small, heterogeneous",
        citations=[C(GWAS, "ADIPOQ +45T>G meta-analyses")],
    )
