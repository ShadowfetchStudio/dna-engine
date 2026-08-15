"""Neurotransmitters, mood, stress & cognition — curated chip-callable markers."""
from .common import G, C, CHIPS_ALL, PGKB, GWAS, CLIN, CPIC


def register(add):
    add(
        "rs4680", "COMT", "Catechol-O-Methyltransferase (Val158Met / Warrior vs Worrier)", "22", 19951271,
        ["cognition", "stress", "neurotransmitters", "methylation"], "strong", "A", "G",
        "COMT degrades dopamine, epinephrine, and norepinephrine in the prefrontal cortex (PFC). The A allele (Met158) is thermolabile and has 3–4x lower enzymatic activity, resulting in higher PFC dopamine levels (Worrier phenotype), while the G allele (Val158) clears dopamine rapidly (Warrior phenotype).",
        G("Met/Met Homozygote / High Dopamine 'Worrier' (AA)", "notable",
          "Two Met alleles. Low COMT activity leading to high baseline prefrontal dopamine.",
          "Advantages: Superior working memory, executive focus, attention to detail, and complex cognitive processing in calm environments. Vulnerabilities: Heightened stress reactivity, emotional amplification under high pressure, and slower recovery from catecholamine spikes.",
          mind=["Practice breathwork, progressive relaxation, and stress-buffering routines before high-stakes tasks.", "Avoid excessive stimulants (high caffeine, yohimbine) that overload dopamine receptors."],
          eat=["Ensure adequate magnesium to support COMT cofactor function.", "High-dose methyl donors can exacerbate anxiety in Met/Met individuals; use conservative doses."]),
        G("Val/Met Heterozygote / Balanced Phenotype (AG)", "advantageous",
          "One Val and one Met allele. Intermediate COMT activity.",
          "Combines good baseline cognitive focus with solid psychological resilience under moderate stress.",
          mind=["Well-balanced dopamine kinetics; adapts well across diverse working conditions."]),
        G("Val/Val Homozygote / Rapid Clearance 'Warrior' (GG)", "typical",
          "Two Val alleles. High COMT activity with rapid dopamine and catecholamine breakdown.",
          "Advantages: Outstanding stress resilience, calmness under extreme pressure, and fast recovery from acute stressors. Vulnerabilities: Lower baseline prefrontal dopamine; may experience boredom or lower sustained focus in routine, low-stimulation tasks.",
          mind=["Thrives in high-intensity, dynamic, fast-paced environments."],
          move=["High-intensity interval training (HIIT) and competitive athletics effectively stimulate dopamine."],
          eat=["Protein-rich meals providing tyrosine support steady dopamine synthesis."]),
        notes="The definitive cognitive trade-off polymorphism in human neuroscience.",
    )

    add(
        "rs6265", "BDNF", "Brain-Derived Neurotrophic Factor (Val66Met)", "11", 27679916,
        ["cognition", "stress", "fitness"], "strong", "C", "T",
        "BDNF governs neurogenesis, synaptic plasticity, and long-term memory consolidation in the hippocampus. The T allele (Met66) impairs activity-dependent secretion of BDNF.",
        G("Typical BDNF Plasticity (CC)", "typical",
          "Val/Val homozygote. Robust activity-dependent BDNF secretion.",
          "Standard hippocampal synaptic plasticity and memory formation.",
          move=["Aerobic exercise further enhances already healthy BDNF expression."]),
        G("Reduced BDNF Secretion / Met Carrier (CT)", "notable",
          "Val/Met heterozygote. ~25% reduction in activity-dependent BDNF release.",
          "Moderately lower hippocampal volume and vulnerability to stress-induced cognitive fatigue. Exercise is a potent epigenetic trigger to restore BDNF secretion.",
          move=["Prioritize 3–4 sessions/week of aerobic exercise and resistance training—physical activity is the strongest natural inducer of BDNF."],
          mind=["Incorporate cognitive novelty, continuous learning, and meditation to drive neuroplasticity."],
          eat=["Omega-3 DHA (wild fish or algae) and dietary polyphenols (blueberries, cacao) support neurotrophin signaling."]),
        G("Met/Met Homozygote (TT)", "caution",
          "Two Met alleles. Significantly blunted activity-dependent BDNF secretion.",
          "Higher susceptibility to anxiety and impaired memory consolidation under chronic stress.",
          move=["Daily physical exercise is non-negotiable for brain health and mood stability."],
          sleep=["High-quality sleep is critical for synaptic consolidation."],
          eat=["Supplement with high-quality EPA/DHA and dietary antioxidants."]),
    )

    add(
        "rs1800497", "ANKK1/DRD2", "Dopamine D2 Receptor Density (Taq1A)", "11", 113271507,
        ["cognition", "substances", "metabolism"], "strong", "A", "G",
        "The A allele (A1 allele) is associated with a 30–40% reduction in striatal Dopamine D2 receptor binding sites, predisposing to 'Reward Deficiency Syndrome' (higher propensity for food cravings, compulsive behaviors, or substance seeking).",
        G("Reduced D2 Receptor Density / A1 Carrier (AA)", "caution",
          "Two A1 alleles. Substantially reduced dopamine D2 receptor density in striatal reward centers.",
          "Prone to seek external reward stimulation: sweet/fatty comfort foods, excessive gaming, or substance use to achieve normal dopamine satisfaction.",
          eat=["Keep structured, whole-food protein meals to prevent dopamine-seeking snacking on hyperpalatable junk food."],
          move=["Engage in regular strength training and intense sports to provide healthy, natural dopamine surges."],
          substances=["Be strictly mindful with alcohol, nicotine, and gambling."]),
        G("Intermediate D2 Density / A1 Heterozygote (AG)", "notable",
          "One A1 allele. Moderately reduced D2 receptor density.",
          "Mild vulnerability to impulsive reward-seeking under stress.",
          eat=["Maintain predictable eating routines and avoid keeping ultra-processed junk food at home."]),
        G("Normal D2 Receptor Density (GG)", "typical",
          "Two A2 alleles. Standard baseline dopamine D2 receptor density.",
          "Typical satiety response and healthy baseline reward signaling."),
    )

    add(
        "rs53576", "OXTR", "Oxytocin Receptor (Empathy & Social Resilience)", "3", 8804371,
        ["cognition", "stress"], "moderate", "A", "G",
        "OXTR mediates the prosocial and stress-buffering effects of oxytocin. The G allele is linked to higher empathy, positive affect, and lower cortisol reactivity to social stress, whereas the A allele confers lower baseline social buffering.",
        G("High Social Buffering (GG)", "advantageous",
          "Two G alleles. Robust oxytocin receptor expression.",
          "High baseline social empathy, emotional connectedness, and strong stress-buffering from social support.",
          mind=["Cultivate deep interpersonal relationships and community connection."]),
        G("Intermediate OXTR (AG)", "typical", "One A allele. Balanced social reactivity.", "Standard psychological resilience."),
        G("Lower Social Buffering (AA)", "notable",
          "Two A alleles. Lower oxytocin receptor expression.",
          "May feel less naturally buffered by social reassurance during acute stress; benefits from deliberate cognitive reframing.",
          mind=["Practice individual grounding routines, journaling, and dedicated solitary recovery."]),
    )

    add(
        "rs1360780", "FKBP5", "Glucocorticoid Receptor Sensitivity & Stress Reactivity", "6", 35601446,
        ["stress", "cognition"], "strong", "C", "T",
        "FKBP5 regulates the sensitivity of the glucocorticoid receptor to cortisol. The T allele promotes hyper-responsiveness of the HPA axis, prolonging cortisol elevation after acute stress.",
        G("Typical Cortisol Feedback (CC)", "typical", "Standard HPA axis negative feedback.", "Normal stress recovery."),
        G("Heightened Cortisol Reactivity (CT)", "notable", "One T allele. Moderately prolonged cortisol response.",
          "Benefits from deliberate post-stress recovery practices.",
          mind=["Engage in daily parasympathetic breathing (4-7-8 breath) and evening wind-down routines."]),
        G("High Stress Sensitivity (TT)", "caution", "Two T alleles. Sensitized HPA axis.",
          "Prolonged cortisol elevation after psychological or physical stressors, predisposing to burnout and sleep disruption.",
          mind=["Prioritize active stress management, nature walks, and regular downtime.", "Avoid overtraining during high-stress life periods."],
          sleep=["Keep bedtime consistent to preserve normal diurnal cortisol rhythm."]),
    )

    add(
        "rs6323", "MAOA", "Monoamine Oxidase A (R297R / High vs Low Activity)", "X", 43615545,
        ["cognition", "neurotransmitters"], "moderate", "G", "T",
        "MAOA breaks down serotonin, dopamine, and norepinephrine in the brain. The G allele is associated with higher MAOA activity (faster monoamine clearance), whereas T is associated with lower activity.",
        G("High MAOA Activity (GG / Hemizygous G)", "typical", "Rapid monoamine breakdown.",
          "Stable mood baseline, fast clearance of neurotransmitters.",
          eat=["Adequate dietary tryptophan and tyrosine."]),
        G("Intermediate MAOA Activity (GT)", "typical", "Balanced monoamine breakdown in heterozygous females.",
          "Standard neurotransmitter degradation rate."),
        G("Low MAOA Activity (TT / Hemizygous T)", "notable", "Slower monoamine breakdown.",
          "Neurotransmitters remain active longer. Can be prone to histamine and tyramine sensitivity (aged cheeses, wine).",
          eat=["Moderate intake of high-tyramine fermented foods if headaches or palpitations occur."]),
    )


    add(
        "rs25531", "SLC6A4", "Serotonin Transporter (5-HTTLPR L(A)/L(G) Tri-Allelic Proxy)", "17", 28564342,
        ["cognition", "stress", "neurotransmitters"], "strong", "A", "G",
        "rs25531 modulates the transcriptional activity of the serotonin transporter (5-HTT / SERT). The G allele converts the high-expressing L allele into a low-expressing S-like allele, reducing serotonin reuptake velocity and predisposing to stress-induced emotional amplification.",
        G("High Serotonin Transporter Expression (AA)", "typical", "Normal SERT expression.",
          "Standard serotonin reuptake kinetics and baseline psychological resilience.",
          mind=["Standard stress management routines."]),
        G("Intermediate Serotonin Transporter (AG)", "typical", "Moderately reduced SERT expression.", "Balanced emotional reactivity."),
        G("Low Serotonin Transporter Expression (GG)", "caution",
          "Two G alleles. Functionally equivalent to the 5-HTTLPR short (S/S) genotype.",
          "Heightened amygdala reactivity to negative emotional stimuli and higher vulnerability to stress-induced mood disruption.",
          mind=["Prioritize cognitive behavioral strategies, daily mindfulness, and structured physical exercise.", "Avoid chronic sleep deprivation which depletes serotonin reserves."],
          eat=["Ensure adequate dietary L-tryptophan (turkey, eggs, salmon) and complex carbohydrates to support serotonin synthesis."]),
    )

    add(
        "rs6311", "HTR2A", "Serotonin 2A Receptor (-1438A>G / Sleep & Mood Sensitivity)", "13", 47471209,
        ["cognition", "sleep", "neurotransmitters"], "strong", "A", "G",
        "HTR2A regulates cortical 5-HT2A receptor density. The A allele increases receptor expression, predisposing to sleep architecture disturbances, heightened sensory processing, and variable response to SSRI medications.",
        G("Typical 5-HT2A Density (GG)", "typical", "Normal receptor expression.", "Standard serotonin signaling."),
        G("Intermediate (AG)", "typical", "Balanced 5-HT2A receptor density.", "Standard sleep and mood baseline."),
        G("High 5-HT2A Receptor Density (AA)", "notable", "Increased cortical 5-HT2A density.",
          "Associated with heightened emotional sensitivity, vivid dreams, and susceptibility to sleep fragmentation.",
          sleep=["Keep a dark, quiet sleep environment; practice evening progressive muscle relaxation."]),
    )

    add(
        "rs110402", "CRHR1", "Corticotropin-Releasing Hormone Receptor 1 (Stress Vulnerability)", "17", 43870830,
        ["stress", "cognition"], "strong", "A", "G",
        "CRHR1 mediates the initial pituitary response to stress-induced CRH release. The A allele protects against stress-induced mood disruption following early life stress.",
        G("Stress Protective Allele (AA)", "advantageous", "Two protective alleles. Resilient HPA axis stress gating.", "High psychological stress resilience."),
        G("Intermediate (AG)", "typical", "Balanced stress response.", "Standard coping mechanisms."),
        G("Stress Vulnerability (GG)", "notable", "Two G alleles. Heightened pituitary ACTH release under psychological threat.",
          "Benefits from deliberate parasympathetic relaxation and adaptogenic support.",
          mind=["Daily meditation, nature immersion, and breathwork actively calm the CRHR1 axis."]),
    )

    # --- 2.0 expansion: COMT haplotype, receptors, HPA axis, stress systems ---
    add(
        "rs4818", "COMT", "COMT Expression Haplotype (L136L)", "22", 19951207,
        ["cognition", "stress", "neurotransmitters"], "moderate", "C", "G",
        "Synonymous COMT variant that, with Val158Met, forms the high/low-expression haplotypes; explains additional enzyme-activity variance beyond rs4680 alone.",
        G("CC", "typical", "Lower-expression haplotype support.", "Interpret jointly with rs4680."),
        G("CG", "typical", "Mixed haplotype.", "Interpret jointly with rs4680."),
        G("GG", "typical", "Higher-expression haplotype support.", "Interpret jointly with rs4680."),
        notes="Palindromic C/G site — orientation reviewed.",
        tier="replicated", effect="Haplotype refinement of COMT activity", reviewed=True,
        citations=[C(GWAS, "COMT haplotype pain/expression studies (Nackley 2006; Diatchenko 2005)")],
    )
    add(
        "rs165599", "COMT", "COMT 3' Region Signal", "22", 19956781,
        ["cognition", "neurotransmitters"], "moderate", "G", "A",
        "3'-region COMT variant reported in psychiatric association studies; small and heterogeneous effects.",
        G("GG", "typical", "Reference.", "Interpret with the COMT haplotype."),
        G("AG", "typical", "Intermediate.", "Small."),
        G("AA", "typical", "Variant pair.", "Small, heterogeneous literature."),
        tier="tendency", effect="Small, mixed replication",
        citations=[C(GWAS, "COMT 3' association literature")],
    )
    add(
        "rs6280", "DRD3", "Dopamine D3 Receptor (Ser9Gly)", "3", 113890815,
        ["cognition", "neurotransmitters"], "moderate", "T", "C",
        "DRD3 Ser9Gly changes receptor binding affinity; studied for reward processing and (clinically) tardive-dyskinesia susceptibility in psychiatry cohorts.",
        G("Ser/Ser (TT)", "typical", "Reference D3 binding.", "Baseline."),
        G("Ser/Gly (CT)", "typical", "Mixed.", "Intermediate binding pattern."),
        G("Gly/Gly (CC)", "typical", "Higher-affinity D3 variant.", "Reward-circuit tuning difference; clinical relevance is specialist territory."),
        tier="replicated", effect="Receptor-affinity change; modest behavioral correlates",
        citations=[C(GWAS, "DRD3 Ser9Gly meta-analyses")],
    )
    add(
        "rs1006737", "CACNA1C", "Calcium Channel Mood Locus", "12", 2345295,
        ["stress", "cognition"], "strong", "G", "A",
        "CACNA1C (Cav1.2) is among the most replicated mood-disorder loci (bipolar/depression GWAS). The A allele modestly shifts risk and appears in imaging studies of emotional processing.",
        G("Reference (GG)", "typical", "Baseline calcium-channel signaling.", "Mood health is dominated by sleep, connection, exercise, and stress load."),
        G("One risk allele (AG)", "typical", "OR ~1.1-1.2 in mood-disorder GWAS.", "A nudge, not a diagnosis."),
        G("Two risk alleles (AA)", "notable", "Most-replicated common mood-risk genotype.", "If mood problems are present, this is context for a clinician conversation, never a label.",
          mind=["Exercise, light exposure, and sleep regularity are evidence-backed mood stabilizers for every genotype."]),
        tier="well-replicated", effect="OR ~1.15 per allele — modest",
        transferability="euro-biased",
        citations=[C(18711365, "Ferreira 2008, Nat Genet — CACNA1C and bipolar disorder"), C(GWAS, "PGC replications")],
    )
    add(
        "rs6295", "HTR1A", "Serotonin 1A Autoreceptor (-1019C>G)", "5", 63258565,
        ["stress", "neurotransmitters"], "moderate", "C", "G",
        "HTR1A promoter variant: the G allele de-represses autoreceptor expression, damping serotonergic firing; studied extensively in depression/anxiety with modest meta-analytic effects.",
        G("CC", "typical", "Typical autoreceptor repression.", "Baseline."),
        G("CG", "typical", "Intermediate.", "Small effect."),
        G("GG", "typical", "Higher autoreceptor expression pattern.", "Modest association with mood/anxiety traits in meta-analyses; environment dominates."),
        notes="Palindromic C/G site — orientation reviewed.",
        tier="tendency", effect="Meta-analytic OR ~1.1-1.2 — small", reviewed=True,
        citations=[C(GWAS, "HTR1A -1019C>G meta-analyses")],
    )
    add(
        "rs7997012", "HTR2A", "Serotonin 2A Intronic (Antidepressant-Response Literature)", "13", 47466821,
        ["stress", "neurotransmitters"], "moderate", "G", "A",
        "HTR2A intronic variant from the STAR*D antidepressant-response analyses; response associations replicated inconsistently — carried at tendency tier, with no medication implication.",
        G("GG", "typical", "Reference.", "Medication questions belong to the prescriber."),
        G("AG", "typical", "Intermediate.", "Informational."),
        G("AA", "typical", "Variant pair associated with better citalopram response in STAR*D.", "Inconsistently replicated — informational only."),
        tier="tendency", effect="Inconsistent pharmacogenetic literature",
        citations=[C(GWAS, "STAR*D HTR2A analyses (McMahon 2006) and replications")],
    )
    add(
        "rs5443", "GNB3", "G-Protein β3 (C825T) — Signal Transduction", "12", 6954875,
        ["stress", "cardio"], "moderate", "C", "T",
        "GNB3 C825T produces a splice variant with enhanced G-protein signaling; historical associations span blood pressure, mood, and metabolism — broad but shallow.",
        G("CC", "typical", "Reference signaling.", "Baseline."),
        G("CT", "typical", "Intermediate.", "Small."),
        G("TT", "typical", "Enhanced-signaling variant pair.", "Small, pleiotropic associations; nothing individually actionable."),
        tier="tendency", effect="Small pleiotropic effects",
        citations=[C(GWAS, "GNB3 C825T association literature")],
    )
    add(
        "rs4606", "RGS2", "Regulator of G-Protein Signaling 2 (Anxiety Tendency)", "1", 192778335,
        ["stress"], "moderate", "C", "G",
        "RGS2 terminates G-protein signaling; reduced-expression variants associate with anxious temperament in human and mouse work.",
        G("CC", "typical", "Typical RGS2 expression.", "Baseline."),
        G("CG", "typical", "Intermediate.", "Small."),
        G("GG", "typical", "Lower-expression pattern.", "Modest anxious-temperament association; breathwork and aerobic exercise are the levers that work regardless.",
          mind=["Slow-exhale breathing (physiological sighs) downshifts sympathetic tone acutely."]),
        notes="Palindromic C/G site — orientation reviewed.",
        tier="tendency", effect="Small temperament association", reviewed=True,
        citations=[C(GWAS, "RGS2 anxiety literature (Smoller 2008)")],
    )
    add(
        "rs324420", "FAAH", "Anandamide Hydrolase (C385A / P129T)", "1", 46870761,
        ["stress", "cognition"], "strong", "C", "A",
        "FAAH degrades anandamide (the endocannabinoid). The A (129T) allele destabilizes FAAH: higher anandamide tone, associated with lower baseline anxiety, faster fear extinction, and modestly different pain/reward profiles.",
        G("Typical FAAH (CC)", "typical", "Standard anandamide clearance.", "Baseline endocannabinoid tone."),
        G("One low-FAAH allele (AC)", "typical", "Higher anandamide tone.", "Associated with calmer threat response in imaging studies — a pleasant tendency, not a shield."),
        G("Low-FAAH pair (AA)", "advantageous", "Highest anandamide tone.", "Replicated association with lower anxiety measures and faster fear extinction; exercise ('runner's high') taps the same system."),
        tier="replicated", transferability="multi-ancestry",
        effect="Replicated imaging/behavioral shifts — modest",
        citations=[C(GWAS, "FAAH C385A fear-extinction studies (Dincheva 2015 and replications)")],
    )
    add(
        "rs1800532", "TPH1", "Tryptophan Hydroxylase 1 (A218C)", "11", 18042538,
        ["stress", "neurotransmitters"], "moderate", "G", "T",
        "Classic TPH1 intronic variant from the older serotonin literature; small associations across mood phenotypes.",
        G("GG", "typical", "Reference.", "Baseline."),
        G("GT", "typical", "Intermediate.", "Small."),
        G("TT", "typical", "Minor-allele pair.", "Small, older-literature associations."),
        tier="tendency", effect="Small, historical literature",
        citations=[C(GWAS, "TPH1 A218C meta-analyses")],
    )
    add(
        "rs6313", "HTR2A", "Serotonin 2A (T102C)", "13", 47469940,
        ["stress", "neurotransmitters"], "moderate", "G", "A",
        "HTR2A T102C travels with the -1438 promoter variant; extensively studied with small, mixed effects on mood and receptor expression.",
        G("GG", "typical", "Reference pair (102C-linked).", "Baseline."),
        G("AG", "typical", "Intermediate.", "Small."),
        G("AA", "typical", "102T-linked pair.", "Small, mixed literature."),
        tier="tendency", effect="Small, mixed",
        citations=[C(GWAS, "HTR2A T102C meta-analyses")],
    )
    add(
        "rs6314", "HTR2A", "Serotonin 2A (H452Y)", "13", 47409034,
        ["stress", "cognition"], "moderate", "C", "T",
        "Coding HTR2A variant altering receptor desensitization; studied for memory modulation and clozapine-response literature (specialist territory).",
        G("CC", "typical", "Reference receptor.", "Baseline."),
        G("CT", "typical", "One 452Y copy.", "Subtle signaling difference."),
        G("TT", "typical", "Rare 452Y pair.", "Subtle receptor-kinetics difference; no lifestyle implication."),
        tier="tendency", effect="Small",
        citations=[C(GWAS, "HTR2A H452Y literature")],
    )
    add(
        "rs41423247", "NR3C1", "Glucocorticoid Receptor BclI (Cortisol Sensitivity)", "5", 142778575,
        ["stress"], "moderate", "C", "G",
        "The BclI haplotype increases glucocorticoid sensitivity: modestly stronger tissue response to cortisol, associated with stress-related metabolic patterns in cohorts.",
        G("CC", "typical", "Typical cortisol sensitivity.", "Baseline."),
        G("CG", "typical", "Intermediate.", "Small."),
        G("GG", "notable", "Higher glucocorticoid sensitivity pattern.", "Chronic-stress hygiene (sleep, exercise, recovery blocks) pays a slightly higher dividend here.",
          mind=["Guard sleep and recovery under sustained stress — this genotype amplifies tissue-level cortisol response."]),
        notes="Palindromic C/G site — orientation reviewed.",
        tier="replicated", effect="Modest sensitivity shift", reviewed=True,
        citations=[C(GWAS, "NR3C1 BclI cortisol-sensitivity studies (van Rossum 2003)")],
    )
    add(
        "rs6190", "NR3C1", "Glucocorticoid Receptor ER22/23EK (Cortisol Resistance)", "5", 142780337,
        ["stress"], "moderate", "G", "A",
        "ER22/23EK mildly reduces glucocorticoid receptor transactivation: relative cortisol resistance, associated with favorable metabolic profiles in carriers.",
        G("Reference (GG)", "typical", "Typical receptor function.", "Baseline."),
        G("ER22/23EK carrier (AG)", "typical", "Mild cortisol resistance.", "Associated with slightly favorable metabolic profile in Dutch cohorts."),
        G("Rare homozygote (AA)", "typical", "Stronger resistance pattern.", "Rare; same direction."),
        tier="replicated", effect="Mild, favorable metabolic association",
        citations=[C(GWAS, "NR3C1 ER22/23EK cohort studies (van Rossum 2002)")],
    )
    add(
        "rs56149945", "NR3C1", "Glucocorticoid Receptor N363S (Sensitivity Variant)", "5", 142779317,
        ["stress"], "moderate", "A", "G",
        "N363S modestly increases glucocorticoid sensitivity; older cohort associations with stress-related weight patterns.",
        G("Reference (AA)", "typical", "Typical.", "Baseline."),
        G("N363S carrier (AG)", "typical", "Mildly higher sensitivity.", "Stress-hygiene dividend slightly higher."),
        G("Rare homozygote (GG)", "typical", "Rare.", "Same direction."),
        tier="tendency", effect="Small",
        citations=[C(GWAS, "NR3C1 N363S literature")],
    )
    add(
        "rs3800373", "FKBP5", "FKBP5 3' Haplotype (Stress-Axis Feedback)", "6", 35542476,
        ["stress"], "moderate", "T", "G",
        "FKBP5 slows glucocorticoid-receptor feedback. This 3' haplotype SNP travels with rs1360780; risk alleles associate with prolonged cortisol recovery after stress and interact with early adversity in PTSD/depression studies.",
        G("Reference (TT)", "typical", "Typical feedback kinetics.", "Baseline."),
        G("One risk allele (GT)", "typical", "Haplotype-intermediate.", "Interpret with rs1360780."),
        G("Risk pair (GG)", "notable", "Slower stress-axis shutdown pattern.", "Deliberate recovery (exercise, social connection, sleep) is the evidence-backed counterweight.",
          mind=["After acute stressors, schedule active recovery — this haplotype lingers in the stress response longer."]),
        tier="replicated", effect="Gene-environment interaction effects — modest",
        citations=[C(GWAS, "FKBP5 haplotype PTSD/depression interaction studies (Binder 2008)")],
    )
    add(
        "rs4713916", "FKBP5", "FKBP5 Promoter-Region Variant", "6", 35646435,
        ["stress"], "moderate", "G", "A",
        "Promoter-region member of the FKBP5 risk haplotype.",
        G("Reference (GG)", "typical", "Typical.", "Interpret with rs1360780."),
        G("Intermediate (AG)", "typical", "Haplotype support.", "Interpret with rs1360780."),
        G("Risk pair (AA)", "typical", "Haplotype support.", "Interpret with rs1360780."),
        tier="replicated", effect="Haplotype member",
        citations=[C(GWAS, "FKBP5 haplotype studies")],
    )
    add(
        "rs9296158", "FKBP5", "FKBP5 Intronic Haplotype Member", "6", 35567082,
        ["stress"], "moderate", "G", "A",
        "Intronic member of the same FKBP5 haplotype used in gene-adversity interaction studies.",
        G("Reference (GG)", "typical", "Typical.", "Interpret with rs1360780."),
        G("Intermediate (AG)", "typical", "Haplotype support.", "Interpret with rs1360780."),
        G("Risk pair (AA)", "typical", "Haplotype support.", "Interpret with rs1360780."),
        tier="replicated", effect="Haplotype member",
        citations=[C(GWAS, "FKBP5 haplotype studies (Binder 2008)")],
    )
    add(
        "rs16147", "NPY", "Neuropeptide Y Promoter (Stress Resilience)", "7", 24323387,
        ["stress"], "moderate", "T", "C",
        "NPY buffers stress responses. Promoter variation shifts NPY expression: lower-expression alleles associate with stronger amygdala responses to threat in imaging cohorts.",
        G("Higher-expression (TT)", "typical", "Higher NPY expression pattern.", "Associated with somewhat buffered stress reactivity."),
        G("Intermediate (CT)", "typical", "Intermediate expression.", "Baseline."),
        G("Lower-expression (CC)", "typical", "Lower NPY expression pattern.", "Slightly stronger threat reactivity in imaging studies; aerobic exercise raises NPY.",
          move=["Regular aerobic work is one of the few known NPY up-regulators."]),
        tier="replicated", effect="Imaging-level effects — modest",
        citations=[C(GWAS, "NPY expression/stress studies (Zhou 2008, Nature)")],
    )
    add(
        "rs2254298", "OXTR", "Oxytocin Receptor Variant (Social Buffering)", "3", 8802228,
        ["stress"], "moderate", "G", "A",
        "Second commonly studied OXTR variant; small, population-dependent associations with attachment and social-stress buffering.",
        G("GG", "typical", "Reference.", "Baseline."),
        G("AG", "typical", "Intermediate.", "Small, population-dependent."),
        G("AA", "typical", "Variant pair.", "Small; social connection benefits every genotype."),
        tier="tendency", effect="Small, heterogeneous",
        citations=[C(GWAS, "OXTR rs2254298 meta-analyses")],
    )
    add(
        "rs1076560", "DRD2", "D2 Receptor Splice Variant (Cognitive Flexibility)", "11", 113285365,
        ["cognition", "neurotransmitters"], "moderate", "G", "T",
        "DRD2 intronic variant shifting the D2S/D2L splice ratio; studied for working-memory and flexibility differences in imaging genetics.",
        G("GG", "typical", "Typical splice ratio.", "Baseline."),
        G("GT", "typical", "Intermediate.", "Subtle."),
        G("TT", "typical", "Shifted splice ratio.", "Subtle cognitive-control differences in studies; training effects dwarf them."),
        tier="tendency", effect="Small imaging-genetics effects",
        citations=[C(GWAS, "DRD2 rs1076560 splice studies (Zhang 2007)")],
    )
