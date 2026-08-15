"""Longevity, cellular defense & morphology — curated chip-callable markers."""
from .common import G, C, CHIPS_ALL, PGKB, GWAS, CLIN, CPIC


def register(add):
    add(
        "rs2802292", "FOXO3", "Forkhead Box O3 (Centenarian Longevity Factor)", "6", 108579958,
        ["longevity", "cellular"], "strong", "G", "T",
        "FOXO3 is a master transcriptional regulator of autophagy, DNA repair, antioxidant enzymes, and stem cell homeostasis. The G allele is heavily enriched in centenarians worldwide (2- to 3-fold higher prevalence in individuals living >100 years).",
        G("Centenarian Longevity Allele Homozygote (GG)", "advantageous",
          "Two G alleles. Maximized FOXO3-mediated stress resilience.",
          "Enhanced cellular autophagy, superior DNA damage repair, and reduced cardiovascular mortality across lifespan studies.",
          longevity=["Autophagy-inducing lifestyle practices (intermittent fasting, sauna, exercise) synergize powerfully with FOXO3 activation."]),
        G("Longevity Allele Carrier (GT)", "advantageous",
          "One G allele. Robust FOXO3 activation.",
          "Associated with healthy cellular aging and cardiovascular protection.",
          longevity=["Regular physical activity and caloric balance maintain FOXO3 pathway signaling."]),
        G("Typical FOXO3 (TT)", "typical",
          "Two T alleles. Standard baseline FOXO3 expression.",
          "Standard cellular repair dynamics; fully responsive to healthy lifestyle habits."),
        notes="The single most replicated genetic longevity locus across diverse global cohorts.",
    )

    add(
        "rs2736098", "TERT", "Telomerase Reverse Transcriptase (Telomere Length Maintenance)", "5", 1279611,
        ["longevity", "cellular"], "strong", "A", "G",
        "TERT encodes the catalytic subunit of telomerase, which maintains telomere length at chromosome ends during cellular division. The A allele is associated with longer leukocyte telomere length.",
        G("Longer Telomere Maintenance (AA)", "advantageous", "Two A alleles. Superior telomere length preservation.", "Favorable cellular replicative capacity."),
        G("Intermediate (AG)", "typical", "Balanced telomere dynamics.", "Standard baseline."),
        G("Shorter Telomere Tendency (GG)", "notable", "Two G alleles. Moderately shorter baseline leukocyte telomeres.",
          "Cellular aging is more sensitive to chronic psychological stress and smoking.",
          longevity=["Stress management, aerobic exercise, and Mediterranean diet are clinically proven to preserve telomere length."]),
    )

    add(
        "rs671", "ALDH2", "Aldehyde Dehydrogenase 2 (Glu504Lys / Asian Alcohol Flush)", "12", 112241766,
        ["alcohol", "substances", "detox", "cardio"], "strong", "A", "G",
        "ALDH2 breaks down carcinogenic acetaldehyde into harmless acetate. The A allele (ALDH2*2 / 504Lys) is a dominant negative mutation that abolishes enzyme activity (~80% loss in GA, >95% loss in AA), causing severe toxic acetaldehyde accumulation after alcohol (flushing, nausea, tachycardia, high esophageal cancer risk).",
        G("ALDH2*2 Homozygote / Severe Acetaldehyde Toxicity (AA)", "caution",
          "Two *2 null alleles. Near-complete absence of mitochondrial ALDH2 activity.",
          "Severe facial flushing, nausea, headache, and tachycardia after even sips of alcohol. Acetaldehyde is a potent DNA mutagen.",
          substances=["Strictly avoid all alcoholic beverages. Alcohol is highly toxic to your biology."]),
        G("Alcohol Flush Carrier / ALDH2*2 Heterozygote (AG)", "caution",
          "One *2 allele. ~80% reduction in acetaldehyde clearance velocity.",
          "Classic Asian flush reaction: rapid facial redness, palpitations, and elevated risk of upper gastrointestinal cancers if alcohol is consumed.",
          substances=["Strong recommendation to eliminate or severely restrict alcohol. Never take antihistamines to 'mask' the flush, which increases cancer risk."]),
        G("Normal Alcohol Metabolism (GG)", "typical", "Two *1 alleles. Fully functional ALDH2 enzyme.", "Normal acetaldehyde clearance."),
        notes="A critical public health pharmacogenomic and oncologic marker.",
    )

    add(
        "rs1229984", "ADH1B", "Alcohol Dehydrogenase 1B (Arg48His / Fast Ethanol Conversion)", "4", 100239319,
        ["alcohol", "substances"], "strong", "C", "T",
        "ADH1B converts ethanol into acetaldehyde. The T allele (48His / *2) accelerates ethanol oxidation by ~40–80x, rapidly generating acetaldehyde and conferring strong natural protection against alcohol dependence.",
        G("Rapid Ethanol Conversion / Alcohol Protection (TT)", "advantageous",
          "Two *2 alleles. Extremely rapid conversion of alcohol to acetaldehyde.",
          "High natural resistance to alcohol dependence and alcoholism.",
          substances=["Natural biological deterrent against alcohol overconsumption."]),
        G("Intermediate Conversion (CT)", "advantageous", "One *2 allele. Accelerated alcohol metabolism.", "Protective against heavy drinking."),
        G("Standard Alcohol Dehydrogenase (CC)", "typical", "Standard ADH1B rate.", "Standard baseline."),
    )

    add(
        "rs17822931", "ABCC11", "ATP-Binding Cassette C11 (538G>A / Dry Earwax & Body Odor)", "16", 48258198,
        ["traits", "morphology"], "strong", "A", "G",
        "ABCC11 encodes an apocrine gland transporter. The A allele (538A) is a loss-of-function mutation causing dry/flaky earwax and the complete absence of axillary body odor (no apocrine sweat secretion of odor precursors). Highly prevalent in East Asians (>80%).",
        G("Dry Earwax & Zero Underarm Odor (AA)", "advantageous",
          "Two A alleles. Complete loss of apocrine axillary odor secretion.",
          "Produces dry, grayish earwax and eliminates the genetic requirement for underarm deodorant.",
          traits=["Naturally free of apocrine body odor; no clinical need for aluminum antiperspirants."]),
        G("Wet Earwax & Standard Body Odor (AG)", "typical", "One G allele. Functional apocrine secretion.", "Produces wet earwax and typical body odor."),
        G("Wet Earwax & Standard Body Odor (GG)", "typical", "Two G alleles. Standard apocrine gland secretion.", "Standard baseline."),
    )

    add(
        "rs12913832", "HERC2/OCA2", "Iris & Hair Pigmentation Switch (Blue vs Brown Eyes)", "15", 28365618,
        ["traits", "pigmentation", "eye"], "strong", "A", "G",
        "rs12913832 in the HERC2 intron acts as the master enhancer switch regulating the promoter of OCA2. The G allele disrupts the chromatin loop, drastically reducing OCA2 expression in the iris stroma, leading to blue/gray/green eyes.",
        G("Blue / Gray / Light Green Eyes (GG)", "typical",
          "Two G alleles. Suppressed OCA2 expression in iris melanocytes.",
          "Strongly predictive (~99%) of blue, gray, or light green eyes in individuals of European ancestry.",
          traits=["Higher light sensitivity; wear UV-protective sunglasses in bright sunlight."]),
        G("Hazel / Green / Light Brown Eyes (AG)", "typical",
          "One A and one G allele. Intermediate melanin synthesis.",
          "Typically manifests as hazel, green, or mixed iris color."),
        G("Brown / Dark Eyes (AA)", "typical",
          "Two A alleles. Full OCA2 enhancer activity and dense iris eumelanin.",
          "Predictive of brown or dark brown eyes."),
    )

    add(
        "rs1805007", "MC1R", "Melanocortin 1 Receptor (Arg151Cys / Red Hair & Sun Sensitivity)", "16", 89986117,
        ["traits", "pigmentation"], "strong", "C", "T",
        "MC1R regulates the switch between dark eumelanin and red/yellow pheomelanin in melanocytes. The T allele (151Cys / 'R' allele) is a major loss-of-function variant causing red hair, fair skin, freckling, and high sunburn/melanoma susceptibility.",
        G("Red Hair & High Sun Sensitivity (TT)", "caution",
          "Two strong MC1R 'R' alleles.",
          "High likelihood of red hair, porcelain skin, inability to tan, and significantly elevated melanoma risk.",
          traits=["Strict sun protection: broad-spectrum SPF, protective clothing, and annual dermatologist skin checks."]),
        G("Carrier of Red Hair Variant / Fair Skin (CT)", "notable",
          "One 'R' allele. Increased freckling and sun sensitivity.",
          "Moderately higher tendency to burn easily under UV radiation.",
          traits=["Use daily sun protection and avoid deliberate tanning bed exposure."]),
        G("Typical Tanning Capability (CC)", "typical", "No Arg151Cys variant detected.", "Normal baseline melanogenesis."),
    )

    add(
        "rs3827760", "EDAR", "Ectodysplasin A Receptor (370A / Hair Thickness & Tooth Morphology)", "2", 109513601,
        ["traits", "morphology"], "strong", "A", "G",
        "EDAR 370A (G allele) is an adaptive mutation that arose ~30,000 years ago in East Asia. It increases EDAR signaling, producing significantly thicker hair fibers, shovel-shaped incisors, and altered mammary and sweat gland branching.",
        G("East Asian Adaptive Phenotype / Thick Hair (GG)", "advantageous",
          "Two 370A alleles. High EDAR signaling.",
          "Produces thick, cylindrical hair shaft cross-sections, shovel-shaped incisor morphology, and increased eccrine sweat gland density.",
          traits=["Thick, robust hair texture."]),
        G("Heterozygote (AG)", "typical", "Intermediate hair thickness.", "Standard morphology."),
        G("Ancestral Thin/Medium Hair (AA)", "typical", "Ancestral EDAR signaling.", "Standard hair shaft diameter."),
    )

    add(
        "rs72921001", "OR6A2", "Olfactory Receptor 6A2 (Cilantro / Coriander Soap Taste)", "11", 55562095,
        ["traits", "taste"], "strong", "A", "C",
        "OR6A2 detects aldehyde odorants. The A allele enhances binding to (2E)-alkenals found in cilantro leaves, making cilantro taste intensely of dish soap or bath soap.",
        G("Strong Cilantro Soapy Taste (AA)", "notable",
          "Two A alleles. Highly sensitized aldehyde olfactory receptor.",
          "Fresh cilantro/coriander tastes overwhelmingly soapy and pungent.",
          taste=["Crushing or cooking cilantro converts aldehydes and softens the soapy taste."]),
        G("Mild Soapy Note (AC)", "typical", "Intermediate perception.", "Mild soapiness detectable."),
        G("Herbaceous Cilantro Taste (CC)", "typical", "Normal receptor binding.", "Perceives cilantro as fresh, citrusy, and herbaceous."),
    )

    add(
        "rs34637584", "LRRK2", "Leucine-Rich Repeat Kinase 2 (G2019S / Parkinson's Risk Tag)", "12", 40614434,
        ["cognition", "cellular"], "strong", "A", "G",
        "LRRK2 G2019S is the most common genetic contributor to familial and sporadic Parkinson's disease (incomplete penetrance ~25–30% by age 80).",
        G("Typical (GG)", "typical", "No LRRK2 G2019S mutation detected.", "Standard baseline risk."),
        G("LRRK2 G2019S Carrier (AG)", "caution",
          "One G2019S allele. ~25–30% lifetime penetrance for Parkinson's disease.",
          "Neuroprotective habits (aerobic exercise, mitochondrial support, sound sleep) are strongly protective.",
          move=["Vigorous aerobic exercise stimulates neurotrophins and mitochondrial clearance in dopaminergic neurons."],
          recover=["Clinical genetic counseling recommended if neurological symptoms or family history exist."]),
        G("Homozygote (AA)", "caution", "Two G2019S alleles. High genetic susceptibility.", "Consult a neurologist for preventive neuro-health."),
    )


    # --- 2.0 expansion: klotho, antioxidant enzymes, telomeres, eye aging ---
    add(
        "rs9536314", "KL (Klotho)", "KL-VS Variant (F352V) — Longevity & Cognition", "13", 33628138,
        ["longevity", "cognition", "cellular"], "strong", "T", "G",
        "Klotho is an aging-regulator hormone. The KL-VS haplotype (F352V) in HETEROZYGOTES associates with longevity, higher klotho levels, and modestly better cognition — while homozygotes trend the other way. A rare true heterozygote-advantage story.",
        G("Non-carrier (TT)", "typical", "Typical klotho.", "Baseline."),
        G("KL-VS heterozygote (GT)", "advantageous", "Heterozygote-advantage pattern.", "Associated with higher klotho, modest cognitive and longevity advantages across several cohorts."),
        G("KL-VS homozygote (GG)", "typical", "Uncommon; advantage disappears.", "Homozygotes do not show the heterozygote benefit — biology is not linear."),
        tier="replicated", transferability="multi-ancestry",
        effect="Het advantage: longevity/cognition cohort effects — modest but consistent",
        citations=[C(GWAS, "KL-VS heterozygote-advantage studies (Arking 2002; Dubal 2014)")],
    )
    add(
        "rs1042522", "TP53", "p53 Codon 72 (Pro72Arg) — Apoptosis Balance", "17", 7579472,
        ["longevity", "cellular"], "moderate", "C", "G",
        "The guardian-of-the-genome's classic polymorphism: Arg72 induces apoptosis more efficiently; Pro72 favors cell-cycle arrest/repair. Cohort studies suggest small longevity/cancer-survival trade-offs in each direction.",
        G("Arg/Arg (CC)", "typical", "Efficient-apoptosis variant pair.", "Trade-off biology; no action implied."),
        G("Arg/Pro (CG)", "typical", "Mixed.", "Balanced."),
        G("Pro/Pro (GG)", "typical", "Repair-leaning variant pair.", "Small longevity-cohort associations in some populations."),
        notes="Palindromic C/G site — reviewed.",
        tier="replicated", effect="Small trade-off effects", reviewed=True,
        citations=[C(GWAS, "TP53 codon-72 meta-analyses")],
    )
    add(
        "rs1001179", "CAT", "Catalase Promoter (-262C>T)", "11", 34460231,
        ["longevity", "antioxidant", "cellular"], "moderate", "C", "T",
        "Catalase clears hydrogen peroxide. The T allele raises expression in red cells; disease associations are small — carried for antioxidant-pathway completeness.",
        G("Reference (CC)", "typical", "Typical catalase expression.", "Exercise remains the best antioxidant-system upregulator."),
        G("One T allele (CT)", "typical", "Higher expression pattern.", "Small."),
        G("Two T alleles (TT)", "typical", "Highest expression pattern.", "Small; produce antioxidants endogenously via training, not megadose pills."),
        tier="tendency", effect="Expression shift; clinical effects small",
        citations=[C(GWAS, "CAT -262 expression studies")],
    )
    add(
        "rs1050450", "GPX1", "Glutathione Peroxidase 1 (P198L)", "3", 49394834,
        ["longevity", "antioxidant"], "moderate", "C", "T",
        "GPx1 clears peroxides using selenium. The 198L allele modestly reduces activity; interacts with selenium status.",
        G("Pro/Pro (CC)", "typical", "Full GPx1 activity.", "Baseline."),
        G("Pro/Leu (CT)", "typical", "Mildly reduced activity.", "Selenium sufficiency (fish, eggs, occasional brazil nut) supports GPx either way."),
        G("Leu/Leu (TT)", "typical", "Reduced-activity pair.", "Same selenium-sufficiency note; avoid chronic high-dose Se supplements.",
          eat=["Food selenium beats supplements: the toxicity window is narrow."]),
        tier="replicated", effect="Modest activity reduction",
        citations=[C(GWAS, "GPX1 P198L functional studies")],
    )
    add(
        "rs713041", "GPX4", "Glutathione Peroxidase 4 (Membrane Lipid Protection)", "19", 1106232,
        ["longevity", "antioxidant"], "moderate", "C", "T",
        "GPx4 protects membrane lipids from peroxidation (the ferroptosis brake). This 3'UTR variant shifts selenoprotein synthesis priority under low selenium.",
        G("CC", "typical", "Reference synthesis priority.", "Baseline."),
        G("CT", "typical", "Intermediate.", "Baseline."),
        G("TT", "typical", "Altered priority under Se scarcity.", "Selenium sufficiency covers it."),
        tier="tendency", effect="Selenium-conditional biochemical shift",
        citations=[C(GWAS, "GPX4 rs713041 selenoprotein hierarchy studies")],
    )
    add(
        "rs2764264", "FOXO3", "FOXO3 Secondary Longevity Signal", "6", 108913590,
        ["longevity", "cellular"], "moderate", "T", "C",
        "Secondary FOXO3 longevity-haplotype SNP supporting the rs2802292 reading.",
        G("Reference (TT)", "typical", "Baseline haplotype.", "Interpret with rs2802292."),
        G("Intermediate (CT)", "typical", "Haplotype support.", "Interpret with rs2802292."),
        G("Longevity-haplotype pair (CC)", "typical", "Supports the longevity haplotype.", "Interpret with rs2802292."),
        tier="replicated", effect="Haplotype support",
        citations=[C(18765803, "Willcox 2008 — FOXO3 haplotype")],
    )
    add(
        "rs5882", "CETP", "CETP I405V (Ashkenazi Longevity Study Variant)", "16", 57016092,
        ["longevity", "lipids"], "moderate", "A", "G",
        "CETP I405V homozygosity (VV) associated with exceptional longevity and larger lipoprotein particles in Ashkenazi centenarian studies; replication elsewhere is mixed.",
        G("Ile/Ile (AA)", "typical", "Reference CETP.", "Baseline."),
        G("Ile/Val (AG)", "typical", "Intermediate.", "Baseline."),
        G("Val/Val (GG)", "typical", "Longevity-cohort-associated pair.", "Interesting; mixed replication keeps it a tendency."),
        tier="tendency", effect="Cohort-specific longevity association",
        citations=[C(GWAS, "CETP I405V Ashkenazi longevity studies (Barzilai 2003)")],
    )
    add(
        "rs12696304", "TERC region", "Telomerase RNA Component (Telomere Length)", "3", 169481271,
        ["longevity", "cellular"], "strong", "C", "G",
        "TERC-region variant reliably associated with leukocyte telomere length (~75 bp shorter per risk allele — a few years of average attrition).",
        G("Longer-telomere-leaning (CC)", "typical", "Reference pair.", "Sleep, exercise, and not smoking correlate with slower attrition — causality debated, habits good anyway."),
        G("Intermediate (CG)", "typical", "~75 bp shorter average LTL.", "Population-statistics scale — not personal fate."),
        G("Shorter-leaning pair (GG)", "typical", "~150 bp shorter average LTL.", "Same honest framing: measurable at cohort scale, invisible personally."),
        notes="Palindromic C/G site — reviewed.",
        tier="well-replicated", effect="~75 bp LTL per allele", reviewed=True,
        citations=[C(20139977, "Codd 2010, Nat Genet — TERC and telomere length")],
    )
    add(
        "rs9420907", "OBFC1", "Telomere Maintenance Component (CST Complex)", "10", 105676465,
        ["longevity", "cellular"], "strong", "A", "C",
        "OBFC1 (CST complex) variant from telomere-length GWAS; same honest framing as TERC.",
        G("Reference (AA)", "typical", "Baseline LTL contribution.", "Baseline."),
        G("Intermediate (AC)", "typical", "Small LTL shift.", "Cohort-scale effect."),
        G("Variant pair (CC)", "typical", "Small LTL shift.", "Cohort-scale effect."),
        tier="well-replicated", effect="Small LTL shift",
        citations=[C(GWAS, "Telomere-length GWAS (Codd 2013) — OBFC1")],
    )
    add(
        "rs2229765", "IGF1R", "IGF-1 Receptor (E1013E) — Growth/Longevity Axis", "15", 99478022,
        ["longevity", "cellular"], "moderate", "G", "A",
        "Reduced IGF-1 signaling extends lifespan across model organisms. This synonymous IGF1R variant associates with IGF-1 levels and appears in centenarian studies — human evidence is tendency-grade.",
        G("GG", "typical", "Reference IGF-1 axis.", "Strength training requires IGF signaling — do not fear it; the axis is contextual."),
        G("AG", "typical", "Intermediate.", "Baseline."),
        G("AA", "typical", "Lower-IGF-signaling pattern in cohort studies.", "Longevity-cohort enrichment reported; a tendency, not a program."),
        tier="tendency", effect="Cohort-level associations",
        citations=[C(GWAS, "IGF1R centenarian studies (Suh 2008)")],
    )
    add(
        "rs1061170", "CFH", "Complement Factor H (Y402H) — Macular Aging", "1", 196659237,
        ["longevity", "immunity"], "strong", "T", "C",
        "The landmark AMD variant: CFH Y402H weakens complement regulation in the retina. One of the largest common-variant effects in medicine — and strongly modified by smoking and diet.",
        G("Typical complement regulation (TT)", "typical", "Baseline AMD odds.", "Standard eye-health basics: UV protection, leafy greens, no smoking."),
        G("One 402H allele (CT)", "notable", "AMD OR ~2.5.", "Smoking multiplies this risk ~3-4x further — the single clearest gene-environment interaction to act on. Dilated eye exams after 60.",
          eat=["Dark leafy greens (lutein/zeaxanthin) have real AMD evidence (AREDS-style nutrition)."]),
        G("Two 402H alleles (CC)", "caution", "AMD OR ~6-7.", "Non-smoking is non-negotiable; regular retinal exams after 55-60 catch treatable disease early.",
          recover=["Schedule dilated retinal exams; report any new visual distortion (straight lines bending) promptly."]),
        tier="well-replicated", transferability="euro-biased",
        effect="AMD OR ~2.5 het / ~6 hom — among the largest common-variant effects known",
        citations=[C(15761122, "Klein 2005, Science — CFH and age-related macular degeneration")],
    )
    add(
        "rs10490924", "ARMS2/HTRA1", "Macular Degeneration Second Locus (A69S)", "10", 124214448,
        ["longevity", "immunity"], "strong", "G", "T",
        "The second major AMD locus, independent of CFH; combined CFH+ARMS2 risk genotypes multiply.",
        G("Reference (GG)", "typical", "Baseline ARMS2 contribution.", "Baseline."),
        G("One risk allele (GT)", "notable", "AMD OR ~2.5 at this locus.", "Same modifiables: no smoking, greens, retinal exams with age."),
        G("Risk pair (TT)", "caution", "AMD OR ~7 at this locus.", "Combined with CFH risk this stacks — eye-exam discipline after 55.",
          recover=["Annual dilated exams after 55; amsler-grid self-checks are free."]),
        tier="well-replicated", transferability="multi-ancestry",
        effect="OR ~2.5 per allele — major locus",
        citations=[C(16174643, "Dewan 2006 / Rivera 2005 — ARMS2/HTRA1 and AMD")],
    )
    add(
        "rs2010963", "VEGFA", "Vascular Endothelial Growth Factor (-634G>C)", "6", 43738350,
        ["longevity", "cardio", "cellular"], "moderate", "G", "C",
        "VEGF drives capillary growth. This 5'UTR variant shifts VEGF production in assays; studied across vascular and healing phenotypes with small effects.",
        G("GG", "typical", "Reference VEGF production.", "Aerobic training is the physiological VEGF stimulus."),
        G("CG", "typical", "Intermediate.", "Baseline."),
        G("CC", "typical", "Altered-production pattern.", "Small assay-level effects; train capillaries with zone-2 volume."),
        notes="Palindromic G/C site — reviewed.",
        tier="tendency", effect="Assay-level production shifts", reviewed=True,
        citations=[C(GWAS, "VEGFA -634 production studies")],
    )
