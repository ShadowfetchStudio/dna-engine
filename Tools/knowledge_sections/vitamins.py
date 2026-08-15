"""Vitamins, minerals, nutrients & iron — curated chip-callable markers."""
from .common import G, C, CHIPS_ALL, PGKB, GWAS, CLIN, CPIC


def register(add):
    add(
        "rs2282679", "GC", "Vitamin D Binding Protein (DBP / Circulating 25-OH D)", "4", 72608405,
        ["vitamins", "bone", "immunity"], "strong", "A", "C",
        "GC encodes Vitamin D Binding Protein, the primary carrier of 25-hydroxyvitamin D in circulation. The C allele is strongly associated with lower serum 25-OH vitamin D concentrations.",
        G("Typical Vitamin D Carrier Capacity (AA)", "typical", "Normal DBP affinity and circulating vitamin D levels.", "Standard dietary needs."),
        G("Moderate Reduction in 25-OH D (AC)", "notable", "One C allele. Moderately lower circulating 25-OH vitamin D.",
          "May require slightly higher vitamin D intake to achieve optimal blood concentrations (40–60 ng/mL).",
          vitamins=["Ensure regular sun exposure or 1,000–2,000 IU/day Vitamin D3 with K2."]),
        G("Lower Baseline Circulating Vitamin D (CC)", "caution",
          "Two C alleles. Significantly lower serum 25-OH D levels.",
          "High risk of seasonal vitamin D insufficiency, particularly at northern latitudes or with indoor lifestyles.",
          vitamins=["Test serum 25-OH Vitamin D via lab panel.", "Supplement with Vitamin D3 (2,000–4,000 IU/day) paired with Vitamin K2 and magnesium for proper absorption."]),
    )

    add(
        "rs10741657", "CYP2R1", "Vitamin D 25-Hydroxylase (Hepatic Activation)", "11", 14900995,
        ["vitamins", "bone", "immunity"], "strong", "A", "G",
        "CYP2R1 converts cholecalciferol (Vitamin D3) into active 25-hydroxyvitamin D3 in the liver. The G allele is associated with lower hepatic hydroxylation efficiency.",
        G("Typical 25-Hydroxylation (AA)", "typical", "Efficient hepatic conversion to 25-OH D3.", "Normal baseline."),
        G("Heterozygote (AG)", "typical", "Intermediate hepatic conversion.", "Standard vitamin D support."),
        G("Reduced Hepatic Activation (GG)", "notable", "Lower 25-hydroxylase activity.",
          "Requires higher oral D3 doses to achieve target blood levels.",
          vitamins=["Monitor blood levels and pair vitamin D with dietary fats for absorption."]),
    )

    add(
        "rs2228570", "VDR", "Vitamin D Receptor (FokI / C>T)", "12", 48272895,
        ["vitamins", "bone", "immunity"], "strong", "C", "T",
        "The FokI polymorphism in VDR alters the start codon. The C allele produces a shorter protein (424 AA) with higher transcriptional activity; the T allele produces a longer protein (427 AA) with lower transcriptional efficiency.",
        G("High VDR Transcriptional Activity (CC)", "advantageous", "Short, highly active VDR isoform.", "Optimal cellular vitamin D signaling."),
        G("Intermediate VDR Activity (CT)", "typical", "Balanced receptor activity.", "Standard baseline."),
        G("Lower VDR Transcriptional Activity (TT)", "notable", "Longer VDR isoform with reduced transcriptional potency.",
          "Cells may require higher circulating 25-OH D to achieve optimal downstream immune and bone gene expression.",
          vitamins=["Maintain circulating 25-OH D in the robust 40–60 ng/mL range."]),
    )

    add(
        "rs7501331", "BCMO1", "Beta-Carotene Oxygenase 1 (R267S / Plant Vitamin A Conversion)", "16", 81267851,
        ["vitamins", "nutrition", "eye"], "strong", "C", "T",
        "BCMO1 cleaves dietary provitamin A carotenoids (beta-carotene from carrots, sweet potatoes, spinach) into active retinal (Vitamin A). The T allele (267S) reduces cleavage activity by ~32%, and paired with A379V (rs12934922) reduces conversion by up to ~60–70%.",
        G("Efficient Carotene Conversion (CC)", "typical", "Normal BCMO1 enzyme activity.", "Standard conversion of plant carotenoids to active vitamin A."),
        G("Reduced Carotene Conversion (CT)", "notable",
          "One T allele. ~30% reduction in beta-carotene to retinol conversion.",
          "Plant-based carotenoids are converted less efficiently into active preformed vitamin A.",
          eat=["Incorporate preformed vitamin A (retinol) from animal foods (pastured egg yolks, dairy, wild fish, liver) or ensure high total carotenoid intake."]),
        G("Poor Carotenoid Converter (TT)", "caution",
          "Two T alleles. ~60% reduction in beta-carotene conversion.",
          "Cannot rely solely on plant carotenoids (carrots/spinach) for adequate vitamin A status; high carotenoid diets may cause carotenemia (orange palms).",
          eat=["Crucial to consume preformed Vitamin A (retinol) directly: pastured egg yolks, grass-fed butter, cod liver oil, or salmon."]),
        notes="A vital marker for individuals following strict vegan or plant-based diets.",
    )

    add(
        "rs602662", "FUT2", "Fucosyltransferase 2 (Secretor Status / B12 & Gut Microbiome)", "19", 49206674,
        ["vitamins", "gut", "immunity"], "strong", "A", "G",
        "FUT2 determines 'Secretor' status—the secretion of ABO blood group antigens into mucosal secretions. The A allele (W154X null allele) confers 'Non-Secretor' status (AA), which alters the gut microbiome, lowers circulating Vitamin B12, but confers high resistance to Norovirus.",
        G("Secretor Phenotype (GG)", "typical",
          "Full FUT2 expression. Secretes blood group antigens in gut mucosa.",
          "Optimal Bifidobacteria colonization; standard vitamin B12 absorption; susceptible to common Norovirus strains.",
          gut=["Standard prebiotic and fiber intake to nourish diverse gut flora."]),
        G("Secretor Heterozygote (AG)", "typical", "Secretor phenotype.", "Normal B12 absorption."),
        G("Non-Secretor Phenotype (AA)", "notable",
          "Two null alleles. Complete Non-Secretor status.",
          "Advantages: High resistance to Norovirus (stomach flu). Vulnerabilities: ~20–30% lower circulating B12 levels, lower Bifidobacteria abundance in the gut, higher risk of dysbiosis.",
          vitamins=["Ensure robust B12 intake and monitor serum B12 / methylmalonic acid."],
          gut=["Prioritize prebiotic fibers (inulin, resistant starch, acacia) and fermented foods to support Bifidobacteria."]),
    )

    add(
        "rs174546", "FADS1", "Fatty Acid Desaturase 1 (Omega-3 EPA/DHA Conversion)", "11", 61570783,
        ["nutrition", "lipids", "inflammation"], "strong", "C", "T",
        "FADS1 catalyzes the rate-limiting desaturation step converting plant ALA (flax, chia, walnuts) into long-chain anti-inflammatory EPA and DHA. The T allele is associated with significantly lower conversion efficiency.",
        G("Efficient Omega-3 Converter (CC)", "advantageous", "High FADS1 desaturase activity.", "Effective endogenous conversion of plant ALA to EPA."),
        G("Intermediate Desaturase (CT)", "typical", "Intermediate conversion efficiency.", "Include preformed marine omega-3s."),
        G("Poor Omega-3 Converter (TT)", "caution",
          "Two T alleles. Low FADS1 conversion velocity.",
          "Extremely poor conversion of plant ALA into active EPA and DHA. Plant omega-3 sources (flax/chia) cannot maintain adequate cellular omega-3 index.",
          eat=["Direct consumption of preformed EPA/DHA is essential: wild fatty fish (salmon, sardines, mackerel) or marine algae oil supplements (target 1,000–2,000 mg EPA/DHA daily)."]),
    )

    add(
        "rs1800562", "HFE", "Hemochromatosis C282Y (Severe Iron Overload)", "6", 26093141,
        ["vitamins", "cardio", "longevity"], "strong", "A", "G",
        "HFE regulates hepcidin production and cellular iron uptake. The A allele (C282Y) causes hereditary hemochromatosis Type 1, leading to unregulated intestinal iron absorption and progressive iron deposition in the liver, heart, and pancreas.",
        G("Typical Iron Homeostasis (GG)", "typical", "No C282Y mutation detected.", "Normal baseline iron regulation."),
        G("HFE C282Y Carrier (AG)", "notable",
          "One C282Y allele. ~10–12% of European ancestry individuals are carriers.",
          "Mildly increased iron absorption; ferritin may run high-normal. Men and postmenopausal women should avoid iron-fortified supplements unless deficiency is documented.",
          eat=["Avoid unnecessary iron supplements or high-dose vitamin C paired with red meat (vitamin C enhances iron absorption)."],
          recover=["Include serum ferritin and transferrin saturation in routine annual blood work."]),
        G("HFE C282Y Homozygote / Hemochromatosis Risk (AA)", "caution",
          "Two C282Y alleles. High risk for clinical Hereditary Hemochromatosis.",
          "Progressive iron accumulation leading to joint pain, liver fibrosis, diabetes ('bronze diabetes'), and cardiomyopathy if untreated.",
          eat=["Strictly avoid all iron supplements, multivitamin iron, cast-iron cooking, and raw shellfish (Vibrio vulnificus vulnerability)."],
          recover=["Clinical consultation essential: regular therapeutic phlebotomy (blood donation) completely prevents all organ damage if started early."]),
        notes="The premier genetic screen for preventable hereditary iron overload.",
    )

    add(
        "rs1799945", "HFE", "Hemochromatosis H63D (Mild Iron Overload)", "6", 26091178,
        ["vitamins", "cardio"], "strong", "C", "G",
        "The G allele (H63D) is a milder HFE variant. Compound heterozygotes (C282Y + H63D) have a moderate risk of clinical iron overload.",
        G("Typical (CC)", "typical", "No H63D variant.", "Normal iron regulation."),
        G("H63D Carrier (CG)", "typical", "One H63D allele. Very mild effect in isolation.",
          "Check ferritin if paired with C282Y."),
        G("H63D Homozygote (GG)", "notable", "Two H63D alleles. Mildly elevated iron absorption.",
          "Ferritin may run higher than average; monitor with standard labs.",
          eat=["Avoid gratuitous iron supplements."]),
    )

    add(
        "rs855791", "TMPRSS6", "Matriptase-2 (A736V / Iron Deficiency & Ferritin Regulator)", "22", 37067868,
        ["vitamins", "nutrition"], "strong", "C", "T",
        "TMPRSS6 inhibits hepcidin to allow iron absorption. The T allele (736V) impairs matriptase-2, resulting in higher hepcidin levels, lower dietary iron absorption, and lower baseline ferritin.",
        G("Higher Iron Retention (CC)", "typical", "Normal hepcidin suppression.", "Standard iron absorption."),
        G("Intermediate (CT)", "typical", "Balanced iron absorption.", "Standard nutrition."),
        G("Lower Baseline Ferritin (TT)", "notable",
          "Two T alleles. Higher baseline hepcidin and reduced dietary iron absorption.",
          "Prone to unexplained low ferritin and iron-deficiency anemia, particularly in menstruating women and endurance athletes.",
          eat=["Pair non-heme iron foods with Vitamin C to enhance absorption; consume bioavailable heme iron (meat/fish) if ferritin is low."]),
    )

    # --- 2.0 expansion: secretor status, vitamin D axis, minerals, fatty acids, VDR ---
    add(
        "rs601338", "FUT2", "Secretor Status (W143X) — B12, Microbiome, Norovirus", "19", 49206674,
        ["vitamins", "gut", "immunity", "nutrition"], "strong", "G", "A",
        "FUT2 secretes ABO-type sugars into gut mucus and body fluids. The A (stop) allele in homozygosity = 'non-secretor': ~10-15% higher serum B12, near-complete resistance to common norovirus strains, and a measurably different gut microbiome.",
        G("Secretor (GG)", "typical", "Fucosylated gut mucus; typical B12 binding.", "Standard norovirus susceptibility and typical bifidobacteria support."),
        G("Secretor carrier (AG)", "typical", "One functional copy — still a secretor.", "Phenotype follows the functional allele."),
        G("Non-secretor (AA)", "notable", "No mucosal ABO-sugar secretion.", "Resistant to GII.4 norovirus ('stomach flu' immunity is real for this genotype), higher average serum B12 (levels can look better than tissue status), and lower bifidobacteria — fermented-food variety helps.",
          eat=["Non-secretor B12 serum values run high — if B12 symptoms exist despite 'normal' labs, ask a clinician about methylmalonic acid (MMA) testing."]),
        tier="well-replicated", transferability="multi-ancestry",
        effect="Near-Mendelian for secretor status; B12 +~10-15% in non-secretors",
        citations=[C(GWAS, "FUT2 B12 GWAS (Hazra 2008) and norovirus resistance studies (Lindesmith 2003)")],
    )
    add(
        "rs492602", "FUT2", "Secretor Locus Companion SNP", "19", 49206172,
        ["vitamins", "gut"], "strong", "A", "G",
        "FUT2 companion variant in strong LD with W143X in Europeans; chip-redundancy for the secretor call.",
        G("Secretor-haplotype pair (AA)", "typical", "Tracks secretor status.", "Interpret with rs601338."),
        G("Mixed (AG)", "typical", "Carrier pattern.", "Interpret with rs601338."),
        G("Non-secretor-haplotype pair (GG)", "typical", "Tracks non-secretor status.", "Interpret with rs601338."),
        tier="well-replicated", effect="LD proxy of W143X",
        citations=[C(GWAS, "FUT2 haplotype B12 studies")],
    )
    add(
        "rs12934922", "BCO1 (BCMO1)", "Beta-Carotene Conversion (R267S)", "16", 81264597,
        ["vitamins", "nutrition"], "strong", "A", "T",
        "First of the two common BCO1 variants (R267S): together with A379V it reduces plant-carotene → retinal conversion up to ~60% in combination carriers.",
        G("Reference (AA)", "typical", "Typical conversion at this site.", "Interpret with rs7501331."),
        G("One 267S allele (AT)", "typical", "Modest conversion reduction.", "Counts toward the combined converter status."),
        G("Two 267S alleles (TT)", "notable", "Reduced conversion at this site.", "Combined with A379V this supports 'low converter' status — preformed vitamin A (eggs, dairy, fish, liver in moderation) becomes the reliable source.",
          eat=["Do not rely on carrots alone for vitamin A — include retinol sources weekly."]),
        notes="Palindromic A/T site — reviewed.",
        tier="replicated", reviewed=True,
        effect="Up to ~60% conversion reduction in combined-variant carriers",
        citations=[C(19103647, "Leung 2009, FASEB J — BCMO1 variants and carotene conversion")],
    )
    add(
        "rs11645428", "BCO1 region", "Carotene Conversion Regulatory Signal", "16", 81257519,
        ["vitamins", "nutrition"], "moderate", "G", "A",
        "Regulatory-region variant near BCO1 associated with circulating carotenoid levels in GWAS.",
        G("GG", "typical", "Reference carotenoid handling.", "Interpret with the coding pair."),
        G("AG", "typical", "Intermediate.", "Small."),
        G("AA", "typical", "Altered circulating-carotenoid pattern.", "Small; food variety answers it."),
        tier="replicated", effect="Carotenoid-level GWAS signal",
        citations=[C(GWAS, "Carotenoid-level GWAS (Ferrucci 2009)")],
    )
    add(
        "rs12785878", "DHCR7/NADSYN1", "Vitamin D Synthesis Locus (7-DHC Supply)", "11", 71167449,
        ["vitamins"], "strong", "T", "G",
        "DHCR7 diverts 7-dehydrocholesterol away from vitamin D synthesis. This SUNLIGHT-consortium locus shifts baseline 25-OH-D: one of the three core vitamin D genetics loci with GC and CYP2R1.",
        G("Reference (TT)", "typical", "Typical precursor supply.", "Baseline 25-OH-D contribution."),
        G("Intermediate (GT)", "typical", "Slightly lower average 25-OH-D.", "Sun/supplement habits dominate."),
        G("Lower-synthesis pair (GG)", "notable", "Lower average 25-OH-D (~-3-5 nmol/L).", "One more push toward knowing your actual level.",
          eat=["A winter 25-OH-D test answers what genetics only hints at."]),
        tier="well-replicated", transferability="euro-biased",
        effect="~2-4 nmol/L per allele — modest",
        citations=[C(20418485, "Wang 2010, Lancet — SUNLIGHT consortium (DHCR7)")],
    )
    add(
        "rs6013897", "CYP24A1", "Vitamin D Catabolism Locus", "20", 52742479,
        ["vitamins"], "strong", "T", "A",
        "CYP24A1 degrades active vitamin D. SUNLIGHT-consortium variant modestly shifting 25-OH-D via catabolic rate.",
        G("Reference (TT)", "typical", "Typical catabolism.", "Baseline."),
        G("Intermediate (AT)", "typical", "Small shift.", "Small."),
        G("Variant pair (AA)", "typical", "Slightly lower average 25-OH-D.", "Test, don't guess."),
        notes="Palindromic A/T site — reviewed.",
        tier="well-replicated", reviewed=True,
        effect="~1-2 nmol/L per allele — small",
        citations=[C(20418485, "Wang 2010, Lancet — SUNLIGHT (CYP24A1)")],
    )
    add(
        "rs4588", "GC", "Vitamin D Binding Protein Isoform (T436K)", "4", 72618334,
        ["vitamins"], "strong", "C", "A",
        "GC T436K defines (with D432E) the Gc1s/Gc1f/Gc2 binding-protein isoforms: different carrier affinity shifts measured total 25-OH-D and possibly bioavailable fraction — a caution against over-reading small lab differences.",
        G("Gc1-type pair (CC)", "typical", "Higher-affinity carrier isoform.", "Typical measured levels."),
        G("Mixed isoform (AC)", "typical", "Intermediate carrier profile.", "Slightly lower measured total 25-OH-D."),
        G("Gc2-type pair (AA)", "notable", "Lower-binding isoform.", "Measured TOTAL 25-OH-D runs lower while free fraction may be less affected — interpret borderline-low labs with this nuance in mind (a clinician conversation, not a supplement arms race)."),
        tier="well-replicated", transferability="multi-ancestry",
        effect="~5-8 nmol/L measured-level shift across isoforms",
        citations=[C(20418485, "Wang 2010 — GC locus"), C(GWAS, "GC isoform biochemistry literature")],
    )
    add(
        "rs7041", "GC", "Vitamin D Binding Protein Isoform (D432E)", "4", 72618323,
        ["vitamins"], "strong", "T", "G",
        "Second GC isoform-defining variant; combine with rs4588 to read the Gc isoform pair.",
        G("Isoform pole 1 (TT)", "typical", "Gc1f-leaning haplotype.", "Interpret with rs4588."),
        G("Mixed (GT)", "typical", "Intermediate.", "Interpret with rs4588."),
        G("Isoform pole 2 (GG)", "typical", "Gc1s-leaning haplotype.", "Interpret with rs4588."),
        tier="well-replicated", effect="Isoform definition partner",
        citations=[C(GWAS, "GC isoform studies")],
    )
    add(
        "rs526934", "TCN1", "Haptocorrin (B12 Transport Buffer)", "11", 59620487,
        ["vitamins"], "moderate", "A", "G",
        "TCN1 (haptocorrin) carries most circulating B12 in an inert form. Variants shift TOTAL measured B12 without changing delivered (holo-TC) B12 — another 'lab number vs biology' honesty case.",
        G("Reference (AA)", "typical", "Typical haptocorrin.", "Measured B12 reflects usual mix."),
        G("Intermediate (AG)", "typical", "Slightly lower total B12 measurement.", "Total B12 may under-state true status."),
        G("Lower-haptocorrin pair (GG)", "typical", "Lower measured total B12 pattern.", "If B12 labs run 'low' without symptoms, holo-TC or MMA testing gives the real answer."),
        tier="replicated", effect="Measurement-level shift more than biological deficiency",
        citations=[C(GWAS, "TCN1 B12 GWAS (Grarup 2013)")],
    )
    add(
        "rs11254363", "CUBN", "Cubilin (Intestinal B12 Receptor)", "10", 16932735,
        ["vitamins"], "moderate", "A", "G",
        "CUBN is the ileal receptor for intrinsic-factor-bound B12; common variants modestly shift B12 levels.",
        G("Reference (AA)", "typical", "Typical receptor function.", "Baseline."),
        G("Intermediate (AG)", "typical", "Small shift.", "Small."),
        G("Variant pair (GG)", "typical", "Modest B12-level association.", "Dietary B12 regularity covers it."),
        tier="replicated", effect="Small level shift",
        citations=[C(GWAS, "CUBN B12 GWAS (Hazra 2008)")],
    )
    add(
        "rs4654748", "NBPF3/ALPL region", "Vitamin B6 Level Signal", "1", 21796225,
        ["vitamins"], "moderate", "C", "T",
        "Variant near ALPL (which dephosphorylates PLP, active B6) shifting plasma B6 modestly in GWAS.",
        G("Higher-B6-leaning (CC)", "typical", "Higher average plasma PLP.", "Baseline."),
        G("Intermediate (CT)", "typical", "Intermediate.", "Small."),
        G("Lower-B6-leaning (TT)", "typical", "~1.5 ng/mL lower average PLP.", "Poultry, potatoes, bananas — B6 is easy to eat.",
          eat=["Regular whole-food B6 sources cover this comfortably."]),
        tier="replicated", effect="~1-2 ng/mL PLP shift",
        citations=[C(GWAS, "Vitamin B6 GWAS (Tanaka 2009, Am J Hum Genet)")],
    )
    add(
        "rs10882272", "RBP4 region", "Retinol Level Signal", "10", 95327262,
        ["vitamins"], "moderate", "T", "C",
        "Variant near retinol-binding protein 4 associated with circulating retinol in GWAS.",
        G("Reference (TT)", "typical", "Typical retinol carriage.", "Baseline."),
        G("Intermediate (CT)", "typical", "Small shift.", "Small."),
        G("Variant pair (CC)", "typical", "Modest retinol-level association.", "Food variety answers it."),
        tier="replicated", effect="Small level shift",
        citations=[C(GWAS, "Retinol GWAS (Mondul 2011)")],
    )
    add(
        "rs33972313", "SLC23A1", "Vitamin C Transporter (V264M)", "5", 138715502,
        ["vitamins"], "strong", "C", "T",
        "SLC23A1 (SVCT1) reabsorbs ascorbate in kidney and gut. V264M reduces transport: ~5-6 µmol/L lower circulating vitamin C per allele — one of the few solid micronutrient-transport variants.",
        G("Reference (CC)", "typical", "Typical ascorbate reabsorption.", "Standard intake suffices."),
        G("One 264M allele (CT)", "notable", "~5 µmol/L lower average vitamin C.", "An extra daily fruit/vegetable serving neutralizes this entirely.",
          eat=["Peppers, citrus, kiwi, broccoli — cheap, complete answer."]),
        G("Two 264M alleles (TT)", "notable", "Rare; larger reduction.", "Same food answer, stronger reason."),
        tier="well-replicated", transferability="multi-ancestry",
        effect="−5.3 µmol/L per allele (meta-analysis) — moderate",
        citations=[C(20519558, "Timpson 2010, Am J Clin Nutr — SLC23A1 and circulating vitamin C")],
    )
    add(
        "rs13107325", "SLC39A8", "Zinc/Manganese Transporter (A391T) — Pleiotropy Hub", "4", 103188709,
        ["vitamins", "metabolism"], "strong", "C", "T",
        "SLC39A8 (ZIP8) imports zinc and manganese. A391T is one of the most pleiotropic variants in the genome: blood pressure, lipids, BMI, and Mn-dependent glycosylation all shift — a lesson in how one transporter touches everything.",
        G("Reference (CC)", "typical", "Typical Zn/Mn transport.", "Baseline."),
        G("One 391T allele (CT)", "notable", "Altered Mn/Zn handling with small multi-trait shifts.", "Balanced mineral intake (not megadoses) is the rational response.",
          eat=["Whole-food zinc (shellfish, meat, seeds) beats high-dose supplements for this transporter biology."]),
        G("Two 391T alleles (TT)", "notable", "Uncommon; stronger transport shift.", "Same guidance — food-first minerals."),
        tier="well-replicated", transferability="euro-biased",
        effect="Pleiotropic small effects across many traits",
        citations=[C(GWAS, "SLC39A8 A391T pleiotropy literature (Pickrell 2016)")],
    )
    add(
        "rs4072037", "MUC1", "Magnesium Level Signal (1q22)", "1", 155162067,
        ["vitamins"], "moderate", "T", "C",
        "MUC1-region variant from serum-magnesium GWAS; small level shift.",
        G("Reference (TT)", "typical", "Typical serum Mg.", "Baseline."),
        G("Intermediate (CT)", "typical", "Small shift.", "Small."),
        G("Variant pair (CC)", "typical", "Slightly lower average Mg.", "Nuts, greens, legumes; Mg labs are cheap.",
          eat=["Most people under-eat magnesium regardless of genotype — greens and nuts fix both problems."]),
        tier="replicated", effect="Small serum-Mg shift",
        citations=[C(GWAS, "Serum magnesium GWAS (Meyer 2010, PLoS Genet)")],
    )
    add(
        "rs3877899", "SELENOP", "Selenoprotein P Variant (Selenium Distribution)", "5", 42345512,
        ["vitamins", "antioxidant"], "moderate", "G", "A",
        "SELENOP distributes selenium to tissues. Variants shift selenium biomarker response to intake in supplementation studies.",
        G("Reference (GG)", "typical", "Typical Se distribution.", "One brazil nut occasionally covers selenium for almost everyone."),
        G("Intermediate (AG)", "typical", "Small biomarker-response shift.", "Small."),
        G("Variant pair (AA)", "typical", "Altered Se biomarker kinetics in trials.", "Avoid chronic high-dose selenium supplements — the toxicity window is narrow for every genotype."),
        tier="tendency", effect="Biomarker-response shifts in supplementation trials",
        citations=[C(GWAS, "SELENOP supplementation-response studies (Méplan 2007)")],
    )
    add(
        "rs1801725", "CASR", "Calcium-Sensing Receptor (A986S)", "3", 122003757,
        ["vitamins", "bone"], "strong", "G", "T",
        "CASR sets the parathyroid calcium set-point. A986S raises average serum calcium slightly (still within normal range) — worth knowing before over-interpreting a single 'high-normal' calcium lab.",
        G("Reference set-point (GG)", "typical", "Typical serum calcium.", "Baseline."),
        G("One 986S allele (GT)", "typical", "~0.05 mmol/L higher average calcium.", "A repeatedly high-normal calcium may be genotype, not pathology — clinicians confirm with PTH if needed."),
        G("Two 986S alleles (TT)", "typical", "Slightly higher average calcium set-point.", "Same lab-interpretation nuance."),
        tier="well-replicated", effect="~0.05 mmol/L per allele — small but reliable",
        citations=[C(GWAS, "CASR A986S serum-calcium GWAS (Kapur 2010; O'Seaghdha 2010)")],
    )
    add(
        "rs3811647", "TF", "Transferrin Level Variant", "3", 133477701,
        ["vitamins"], "strong", "G", "A",
        "TF variants shift transferrin levels (~40 mg/dL per allele) without matching iron changes — inflating calculated TIBC interpretations. Read iron panels with this in mind.",
        G("Reference (GG)", "typical", "Typical transferrin.", "Baseline."),
        G("One copy (AG)", "typical", "Higher average transferrin.", "Calculated saturation runs slightly lower at identical iron."),
        G("Two copies (AA)", "typical", "Highest transferrin pattern.", "A 'low saturation' with normal ferritin may be this genotype, not deficiency."),
        tier="well-replicated", effect="~40 mg/dL transferrin per allele",
        citations=[C(GWAS, "Transferrin GWAS (Benyamin 2009)")],
    )
    add(
        "rs4820268", "TMPRSS6", "Matriptase-2 Secondary Iron Signal", "22", 37469591,
        ["vitamins"], "moderate", "A", "G",
        "Second TMPRSS6 variant supporting the hepcidin set-point reading from rs855791.",
        G("Reference (AA)", "typical", "Typical hepcidin axis.", "Interpret with rs855791."),
        G("Intermediate (AG)", "typical", "Haplotype support.", "Interpret with rs855791."),
        G("Variant pair (GG)", "typical", "Lower-iron-leaning haplotype support.", "Interpret with rs855791."),
        tier="replicated", effect="Haplotype support",
        citations=[C(GWAS, "TMPRSS6 iron GWAS")],
    )
    add(
        "rs1544410", "VDR", "Vitamin D Receptor BsmI", "12", 48239835,
        ["vitamins", "bone"], "moderate", "C", "T",
        "Classic VDR 3' haplotype variant (BsmI) studied for decades in bone density; meta-analytic effects are small and population-dependent.",
        G("bb-type (CC)", "typical", "Reference haplotype.", "Load-bearing exercise builds bone for every genotype."),
        G("Bb-type (CT)", "typical", "Intermediate.", "Small."),
        G("BB-type (TT)", "typical", "Small BMD association in meta-analyses.", "Strength training + vitamin D sufficiency + protein are the bone levers."),
        tier="replicated", effect="Small BMD associations",
        citations=[C(GWAS, "VDR BsmI BMD meta-analyses")],
    )
    add(
        "rs731236", "VDR", "Vitamin D Receptor TaqI", "12", 48238757,
        ["vitamins", "bone"], "moderate", "T", "C",
        "TaqI travels with BsmI in the VDR 3' haplotype.",
        G("TT", "typical", "Reference haplotype.", "Interpret with BsmI."),
        G("CT", "typical", "Intermediate.", "Interpret with BsmI."),
        G("CC", "typical", "Variant haplotype.", "Interpret with BsmI."),
        tier="replicated", effect="Haplotype partner",
        citations=[C(GWAS, "VDR haplotype literature")],
    )
    add(
        "rs7975232", "VDR", "Vitamin D Receptor ApaI", "12", 48238837,
        ["vitamins", "bone"], "moderate", "A", "C",
        "Third VDR 3' haplotype member (ApaI).",
        G("AA", "typical", "Haplotype pole 1.", "Interpret with BsmI/TaqI."),
        G("AC", "typical", "Intermediate.", "Interpret with the haplotype."),
        G("CC", "typical", "Haplotype pole 2.", "Interpret with the haplotype."),
        tier="replicated", effect="Haplotype member",
        citations=[C(GWAS, "VDR haplotype literature")],
    )
    add(
        "rs3736228", "LRP5", "Wnt Bone-Density Variant (A1330V)", "11", 68201295,
        ["bone", "vitamins"], "strong", "C", "T",
        "LRP5 drives Wnt bone-building. A1330V modestly lowers BMD (~0.1 SD) with replicated fracture association in large meta-analyses.",
        G("Reference (CC)", "typical", "Typical Wnt signaling.", "Baseline."),
        G("One 1330V allele (CT)", "typical", "Slightly lower average BMD.", "Progressive resistance training is the strongest BMD lever known.",
          move=["Loading (squats, jumps appropriate to level) beats any supplement for BMD."]),
        G("Two 1330V alleles (TT)", "notable", "~0.15-0.2 SD lower average BMD.", "DEXA at midlife is a reasonable ask; strength work is non-negotiable.",
          move=["Lifelong strength habit; calcium+D sufficiency; DEXA conversation at 50 (earlier with fracture history)."]),
        tier="well-replicated", effect="~0.1 SD BMD per allele; fracture OR ~1.1 — modest",
        transferability="multi-ancestry",
        citations=[C(GWAS, "GEFOS BMD meta-analyses — LRP5 (Estrada 2012)")],
    )
    add(
        "rs1535", "FADS2", "Omega-6/3 Desaturase Cluster Signal", "11", 61597972,
        ["nutrition", "lipids"], "strong", "A", "G",
        "FADS2 companion signal for the desaturase cluster: G-allele carriers convert plant ALA to EPA/DHA less efficiently — marine or algae omega-3s bypass the bottleneck.",
        G("Efficient-converter pair (AA)", "typical", "Higher desaturase-activity haplotype.", "Plant omega-3s convert comparatively well."),
        G("Intermediate (AG)", "typical", "Intermediate conversion.", "Mixed strategy works."),
        G("Low-converter pair (GG)", "notable", "Reduced conversion haplotype.", "Direct EPA/DHA (fish or algae oil) is the reliable route.",
          eat=["Two fatty-fish meals weekly or algae-oil DHA/EPA covers what conversion won't."]),
        tier="well-replicated", transferability="multi-ancestry",
        effect="Large shifts in blood PUFA ratios by haplotype",
        citations=[C(GWAS, "FADS cluster PUFA GWAS (Tanaka 2009; Lemaitre 2011)")],
    )
    add(
        "rs174575", "FADS2", "FADS2 Intronic (DHA in Pregnancy/Nursing Literature)", "11", 61614036,
        ["nutrition"], "moderate", "C", "G",
        "FADS2 variant studied in maternal-child DHA literature (breast-milk DHA and IQ-interaction studies — interesting, not settled).",
        G("CC", "typical", "Higher-conversion pattern.", "Baseline."),
        G("CG", "typical", "Intermediate.", "Baseline."),
        G("GG", "typical", "Lower-conversion pattern.", "Direct DHA sources matter most here (and in pregnancy for everyone — clinician guidance)."),
        notes="Palindromic C/G site — reviewed.",
        tier="replicated", effect="Conversion-haplotype member", reviewed=True,
        citations=[C(GWAS, "FADS2 maternal DHA studies (Caspi 2007 and successors)")],
    )
    add(
        "rs953413", "ELOVL2", "Omega-3 Elongase Variant", "6", 11044634,
        ["nutrition"], "moderate", "A", "G",
        "ELOVL2 elongates EPA→DPA→DHA precursors; variants shift DHA proportions in blood-lipid GWAS.",
        G("Reference (AA)", "typical", "Typical elongation.", "Baseline."),
        G("Intermediate (AG)", "typical", "Small shift.", "Small."),
        G("Variant pair (GG)", "typical", "Altered DHA-fraction pattern.", "Direct DHA covers any conversion shortfall."),
        tier="replicated", effect="Blood PUFA-fraction shifts",
        citations=[C(GWAS, "ELOVL2 PUFA GWAS (Lemaitre 2011)")],
    )
    add(
        "rs1799941", "SHBG", "Sex Hormone Binding Globulin Level", "17", 7521915,
        ["vitamins", "fitness"], "moderate", "G", "A",
        "SHBG-region variant raising SHBG levels; shifts measured total-vs-free hormone interpretation slightly.",
        G("Reference (GG)", "typical", "Typical SHBG.", "Baseline."),
        G("One A allele (AG)", "typical", "Higher average SHBG.", "Total-hormone labs read slightly higher at identical free levels."),
        G("Two A alleles (AA)", "typical", "Highest-SHBG pattern.", "Lab-interpretation nuance for hormone panels — clinicians handle it via free/bioavailable calculations."),
        tier="replicated", effect="Reliable SHBG level shift",
        citations=[C(GWAS, "SHBG GWAS (Coviello 2012)")],
    )
    add(
        "rs703842", "CYP27B1 region", "Vitamin D Activation Region (MS-Associated)", "12", 58020101,
        ["vitamins", "immunity"], "moderate", "A", "G",
        "Variant near CYP27B1 (renal 1α-hydroxylase activating vitamin D) associated with multiple sclerosis in GWAS — part of the vitamin D-immunity axis story.",
        G("Reference (AA)", "typical", "Typical activation-region haplotype.", "Baseline."),
        G("Intermediate (AG)", "typical", "Small shift.", "Vitamin D sufficiency is sensible for immune health regardless."),
        G("Variant pair (GG)", "typical", "MS-associated haplotype (small effect).", "Absolute MS risk remains very low; vitamin D sufficiency is the practical takeaway."),
        tier="replicated", effect="OR ~1.1-1.2 in MS GWAS — small",
        transferability="euro-biased",
        citations=[C(GWAS, "ANZgene/IMSGC MS GWAS — 12q14 region")],
    )
