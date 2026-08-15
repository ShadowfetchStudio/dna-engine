"""Circadian rhythms, sleep architecture & melatonin — curated chip-callable markers."""
from .common import G, C, CHIPS_ALL, PGKB, GWAS, CLIN, CPIC


def register(add):
    add(
        "rs1801260", "CLOCK", "Circadian Locomotor Output Cycles Kaput (3111T/C / Eveningness)", "4", 56345942,
        ["sleep", "circadian", "metabolism"], "strong", "A", "G",
        "CLOCK is a core transcription factor driving the master cellular circadian rhythm. The G allele (3111C on some strands) is strongly associated with an evening chronotype ('night owl'), delayed sleep phase, and increased vulnerability to metabolic disruption from late-night eating.",
        G("Typical Morning/Intermediate Chronotype (AA)", "typical",
          "Two A alleles. Standard circadian period (~24.1 hours).",
          "Naturally aligned with traditional day-oriented schedules.",
          sleep=["Maintain consistent wake-up times and early daylight exposure."]),
        G("Evening Chronotype Tendency (AG)", "notable",
          "One G allele. Shifted circadian phase toward eveningness.",
          "May feel more alert in late evening. Vulnerable to 'social jetlag' if forced onto rigid early schedules.",
          sleep=["Get 15–30 minutes of bright outdoor sunlight immediately upon waking to anchor the circadian clock.", "Dim artificial blue lights after 8:30 PM."],
          eat=["Avoid heavy dinners after 8:00 PM to protect insulin sensitivity."]),
        G("Strong Evening Chronotype / Delayed Phase (GG)", "caution",
          "Two G alleles. Substantial delay in endogenous melatonin onset and core body temperature drop.",
          "Prone to delayed sleep phase syndrome and circadian misalignment. Late-night snacking causes significantly higher glucose spikes in GG individuals.",
          sleep=["Strict morning light therapy (10,000 lux lamp or direct sunlight for 30 min) to entrain the clock.", "Use 100% blue-blocking glasses 2 hours before target sleep time."],
          eat=["Practice strict time-restricted feeding: finish all caloric intake at least 3 hours before sleep."]),
        notes="A master genetic anchor for personalized circadian medicine.",
    )

    add(
        "rs57875986", "PER3", "Period Circadian Regulator 3 (4/5 Repeat Proxy / Deep Sleep)", "1", 7887989,
        ["sleep", "circadian"], "moderate", "C", "T",
        "PER3 regulates homeostatic sleep pressure and slow-wave sleep (N3) architecture. The T allele is linked to higher sleep drive and sensitivity to acute sleep deprivation.",
        G("Standard Sleep Homeostasis (CC)", "typical", "Normal baseline sleep pressure accumulation.", "Typical sleep requirements."),
        G("Elevated Deep Sleep Drive (CT)", "notable", "One variant copy. Higher need for restorative slow-wave sleep.",
          "Experiences greater cognitive degradation from sleep restriction.",
          sleep=["Protect an 8-hour sleep window; avoid sacrificing sleep for early morning alarms."]),
        G("High Slow-Wave Sleep Dependency (TT)", "caution", "Two variant copies. High sensitivity to sleep debt.",
          "Requires consistent, uncompromised sleep duration to maintain executive cognitive function.",
          sleep=["Prioritize a cold, dark sleep sanctuary (65–68°F) to maximize slow-wave recovery."]),
    )

    add(
        "rs10830963", "MTNR1B", "Melatonin Receptor 1B (Late Eating Glucose Disruption)", "11", 92708710,
        ["glucose", "metabolism", "circadian", "sleep"], "strong", "C", "G",
        "MTNR1B encodes the melatonin receptor on pancreatic beta cells. The G allele increases receptor expression. When melatonin rises in the evening, beta-cell insulin secretion is strongly inhibited. Eating late in the presence of elevated melatonin causes severe glucose spikes in G carriers.",
        G("Typical Melatonin-Insulin Coupling (CC)", "typical", "Standard beta-cell melatonin receptor density.", "Normal glycemic control."),
        G("Late-Meal Glucose Sensitivity (CG)", "notable",
          "One G allele. Heightened beta-cell suppression by melatonin.",
          "Late-night meals (when endogenous melatonin is active) cause markedly higher blood glucose and insulin resistance.",
          eat=["Finish all carbohydrate and heavy food intake at least 2.5–3 hours before bed.", "Avoid midnight snacking."]),
        G("Severe Late-Meal Glucose Intolerance (GG)", "caution",
          "Two G alleles. High beta-cell melatonin sensitivity; ~1.5x increased Type 2 Diabetes risk.",
          "Direct gene-environment interaction: daytime carbohydrate tolerance is normal, but nighttime carbohydrate tolerance is severely compromised.",
          eat=["Strict dinner cutoff: no calories within 3–4 hours of sleep.", "If eating late, keep meals strictly protein/vegetable based with minimal starch."],
          sleep=["Avoid taking high-dose exogenous melatonin close to meals."]),
        notes="A textbook example of chrono-nutrition and gene-meal timing interactions.",
    )

    add(
        "rs5751876", "ADORA2A", "Adenosine A2A Receptor (Caffeine-Induced Anxiety & Insomnia)", "22", 24832569,
        ["sleep", "caffeine", "stress"], "strong", "C", "T",
        "Adenosine binds to ADORA2A receptors in the brain to build sleep pressure. Caffeine is an antagonist. The T allele alters receptor conformation, conferring high sensitivity to caffeine-induced anxiety, panic, and sleep architecture disruption.",
        G("Low Caffeine Sensitivity (CC)", "typical", "Standard adenosine A2A receptor.", "Standard caffeine tolerance."),
        G("Moderate Caffeine Sensitivity (CT)", "typical", "Intermediate receptor sensitivity.", "Standard moderate intake."),
        G("High Caffeine-Induced Anxiety & Jitters (TT)", "caution",
          "Two T alleles. Highly sensitive adenosine receptor.",
          "Even modest doses of caffeine (100–200 mg) can trigger heart palpitations, somatic anxiety, restlessness, and severe reductions in slow-wave deep sleep.",
          substances=["Keep caffeine intake under 100 mg/day (e.g. green tea) or eliminate it entirely.", "Never consume caffeine in the afternoon."],
          sleep=["Caffeine will severely fragment sleep quality even if you are able to fall asleep."]),
    )

    add(
        "rs73598374", "ADA", "Adenosine Deaminase (Deep Sleep Intensity)", "20", 43258814,
        ["sleep"], "moderate", "A", "G",
        "ADA breaks down adenosine. The A allele reduces enzyme activity, leading to higher brain adenosine levels and significantly deeper, more consolidated slow-wave sleep.",
        G("Typical ADA (GG)", "typical", "Normal adenosine clearance.", "Standard sleep depth."),
        G("Enhanced Deep Sleep Carrier (AG)", "advantageous",
          "One A allele. Higher baseline brain adenosine accumulation.",
          "Associated with deeper, more efficient slow-wave sleep (N3) and greater subjective sleep satisfaction.",
          sleep=["Natural predisposition for restorative, deep sleep."]),
        G("Deep Sleep Homozygote (AA)", "advantageous", "Two A alleles. Maximized slow-wave sleep intensity.", "High sleep efficiency."),
    )

    # --- 2.0 expansion: chronotype, restless legs, sleep depth ---
    add(
        "rs35333999", "PER2", "Morningness Coding Variant (V903I)", "2", 239154886,
        ["sleep", "circadian"], "strong", "C", "T",
        "PER2 is a core clock gene. This missense variant reached genome-wide significance for morning chronotype in UK-Biobank-scale GWAS — one of the few coding chronotype hits.",
        G("Reference (CC)", "typical", "Typical PER2 clock period.", "Chronotype is polygenic plus light behavior."),
        G("One morningness allele (CT)", "typical", "Small shift toward earlier chronotype.", "Light timing still dominates phase."),
        G("Two morningness alleles (TT)", "typical", "Rare; strongest single-SNP morning push here.", "Earlier natural phase tendency — schedule deep work accordingly."),
        tier="well-replicated", effect="Minutes-scale phase shift per allele — small but genome-wide significant",
        transferability="euro-biased",
        citations=[C(30696823, "Jones 2019, Nat Commun — chronotype GWAS of 697,828 individuals")],
    )
    add(
        "rs2300478", "MEIS1", "Restless Legs Syndrome Lead Variant", "2", 66634957,
        ["sleep", "circadian"], "strong", "G", "T",
        "MEIS1 is the strongest known restless-legs-syndrome locus, implicating limb-development and iron-handling pathways. Genotype shifts odds meaningfully but most carriers never develop RLS.",
        G("Higher-tendency pair (GG)", "notable", "Two risk alleles (OR ~1.7 each).", "If evening leg discomfort disrupts sleep, RLS is worth naming to a clinician — and ferritin status is the first thing they will check.",
          sleep=["Evening leg restlessness + this genotype → ask a clinician about ferritin; low iron amplifies RLS."]),
        G("One risk allele (GT)", "typical", "Intermediate tendency.", "Most carriers are unaffected."),
        G("Reference (TT)", "typical", "Lower MEIS1-locus tendency.", "Baseline RLS odds."),
        tier="well-replicated", effect="OR ~1.7 per allele — the largest common RLS effect",
        transferability="euro-biased",
        citations=[C(17634447, "Winkelmann 2007, Nat Genet — MEIS1/BTBD9 RLS GWAS")],
    )
    add(
        "rs9357271", "BTBD9", "Restless Legs / PLMS Signal", "6", 38440727,
        ["sleep"], "strong", "T", "C",
        "BTBD9 is the second core RLS locus, also associated with periodic limb movements in sleep and lower ferritin.",
        G("Risk-leaning (TT)", "typical", "Two risk alleles.", "Adds to MEIS1-locus tendency; iron status matters."),
        G("Intermediate (CT)", "typical", "One risk allele.", "Intermediate."),
        G("Reference (CC)", "typical", "Lower BTBD9-locus tendency.", "Baseline."),
        tier="well-replicated", effect="OR ~1.4-1.5 per allele",
        transferability="euro-biased",
        citations=[C(17634447, "Winkelmann 2007 — BTBD9"), C(GWAS, "BTBD9 PLMS/ferritin replication")],
    )
    add(
        "rs3923809", "BTBD9", "RLS / Serum Ferritin Signal", "6", 38434081,
        ["sleep", "vitamins"], "strong", "G", "A",
        "Companion BTBD9 variant associated with RLS and with ~13% lower serum ferritin per risk allele in the discovery study — a concrete gene-nutrient link.",
        G("Risk-leaning (AA)", "typical", "Two risk alleles; lower average ferritin.", "If restless sleep is a theme, ferritin is the measurable to discuss."),
        G("Intermediate (AG)", "typical", "One risk allele.", "Intermediate."),
        G("Reference (GG)", "typical", "Baseline.", "Baseline BTBD9 contribution."),
        tier="well-replicated", effect="OR ~1.5; ferritin −13% per allele in discovery",
        transferability="euro-biased",
        citations=[C(17637780, "Stefansson 2007, NEJM — BTBD9, PLMS and ferritin")],
    )
    add(
        "rs1026732", "MAP2K5/SKOR1", "Restless Legs Third Locus", "15", 67714478,
        ["sleep"], "moderate", "G", "A",
        "Third replicated RLS locus (MAP2K5/SKOR1 region).",
        G("Risk-leaning (GG)", "typical", "Two risk alleles.", "Adds modestly to RLS tendency."),
        G("Intermediate (AG)", "typical", "One risk allele.", "Intermediate."),
        G("Reference (AA)", "typical", "Baseline.", "Baseline."),
        tier="replicated", effect="OR ~1.4", transferability="euro-biased",
        citations=[C(17634447, "Winkelmann 2007 — MAP2K5/SKOR1")],
    )
    add(
        "rs113851554", "MEIS1", "Insomnia Structural-Region Variant", "2", 66523432,
        ["sleep"], "strong", "G", "T",
        "Low-frequency MEIS1 variant with a comparatively large insomnia association in biobank GWAS — the same locus surfaces for RLS and insomnia, suggesting shared limb/arousal biology.",
        G("Reference (GG)", "typical", "Common genotype.", "Baseline insomnia odds."),
        G("One risk allele (GT)", "notable", "Carrier of the stronger insomnia allele.", "If sleep-onset restlessness is chronic, the RLS/iron conversation applies here too.",
          sleep=["Persistent restless sleep onset deserves a ferritin check and sleep-hygiene basics before anything stronger."]),
        G("Two risk alleles (TT)", "notable", "Rare homozygote.", "Strongest tendency at this locus."),
        tier="replicated", effect="One of the larger common insomnia effects (still modest absolute)",
        transferability="euro-biased",
        citations=[C(28604731, "Hammerschlag 2017, Nat Genet — insomnia GWAS, MEIS1")],
    )
    add(
        "rs228697", "PER3", "PER3 Coding Chronotype Variant (P415A)", "1", 7844725,
        ["sleep", "circadian"], "moderate", "C", "G",
        "PER3 coding variant associated with diurnal preference in candidate and biobank studies; a milder cousin of the (untypable) PER3 VNTR.",
        G("Reference (CC)", "typical", "Typical PER3.", "Chronotype dominated by light exposure."),
        G("One copy (CG)", "typical", "Small evening-shift association.", "Behavioral light timing dominates."),
        G("Two copies (GG)", "typical", "Rare; small phase tendency.", "Anchor mornings with light regardless."),
        notes="Palindromic C/G pair — orientation reviewed.",
        tier="replicated", effect="Small phase shift", reviewed=True,
        citations=[C(GWAS, "PER3 P415A chronotype studies")],
    )
    add(
        "rs516134", "RGS16 region", "Morningness GWAS Lead (1q25)", "1", 182568207,
        ["sleep", "circadian"], "strong", "A", "G",
        "RGS16 accelerates clock-neuron signaling; this was among the top morningness hits in the first large consumer-cohort chronotype GWAS and replicated in UK Biobank.",
        G("Morning-leaning (GG)", "typical", "Two morningness alleles.", "Earlier phase tendency."),
        G("Intermediate (AG)", "typical", "One copy.", "Intermediate."),
        G("Evening-leaning (AA)", "typical", "Reference.", "Slightly later phase tendency."),
        tier="well-replicated", effect="Minutes-scale — small", transferability="euro-biased",
        citations=[C(26835600, "Hu 2016, Nat Commun — morningness GWAS (23andMe)")],
    )
    add(
        "rs1823125", "PAX8 region", "Sleep Duration Signal (2q13)", "2", 113960529,
        ["sleep"], "moderate", "A", "G",
        "PAX8-region variant reproducibly associated with self-reported sleep duration in biobank GWAS; effects are minutes, not hours.",
        G("Longer-sleep-leaning (GG)", "typical", "~2-3 min longer average sleep per allele.", "Behavior dwarfs this effect."),
        G("Intermediate (AG)", "typical", "Intermediate.", "Intermediate."),
        G("Reference (AA)", "typical", "Baseline.", "Baseline."),
        tier="replicated", effect="~2-3 minutes per allele — honest and tiny",
        citations=[C(GWAS, "Sleep-duration GWAS (Dashti 2019, Nat Commun)")],
    )
    add(
        "rs10830962", "MTNR1B", "Melatonin Receptor Promoter Region", "11", 92698427,
        ["sleep", "circadian", "glucose"], "moderate", "C", "G",
        "Promoter-region companion to rs10830963: melatonin-receptor expression in islets links evening eating, melatonin, and glucose handling.",
        G("Reference (CC)", "typical", "Typical MTNR1B expression signal.", "See rs10830963 for the lead interpretation."),
        G("One copy (CG)", "typical", "Intermediate.", "Late-night eating is the modifiable exposure here."),
        G("Two copies (GG)", "typical", "Higher-expression-associated pair.", "Finish eating 3+ hours before melatonin onset — good advice for every genotype, sharper for this one."),
        notes="Palindromic C/G pair — orientation reviewed.",
        tier="replicated", effect="Tracks the main MTNR1B glycemic signal", reviewed=True,
        citations=[C(19060907, "Prokopenko 2009 — MTNR1B region")],
    )
    add(
        "rs2653349", "HCRTR2", "Hypocretin Receptor 2 (Cluster-Headache Tendency)", "6", 55146549,
        ["sleep", "circadian"], "moderate", "G", "A",
        "Hypocretin/orexin receptor variant with meta-analytic association to cluster headache — a strongly circadian pain syndrome; included at tendency tier.",
        G("Reference (GG)", "typical", "Typical orexin signaling baseline.", "Background information."),
        G("One copy (AG)", "typical", "Small association signal.", "Background information."),
        G("Two copies (AA)", "typical", "Meta-analytic tendency.", "Only meaningful in the context of an existing diagnosis conversation."),
        tier="tendency", effect="Meta-analytic association, modest",
        citations=[C(GWAS, "HCRTR2 cluster-headache meta-analyses")],
    )
    add(
        "rs7221412", "PER1 region", "Activity-Timing Signal", "17", 8100000,
        ["sleep", "circadian"], "moderate", "A", "G",
        "PER1-region variant associated with objective activity timing (actigraphy peak) in cohort studies; small effect on behavioral phase.",
        G("Reference (AA)", "typical", "Typical activity phase.", "Light exposure dominates."),
        G("Intermediate (AG)", "typical", "Small later-phase shift reported.", "Small."),
        G("Later-phase pair (GG)", "typical", "~1h later activity peak in one cohort.", "Replication is limited — tendency tier."),
        tier="tendency", effect="Reported ~1h actigraphy shift, limited replication",
        citations=[C(GWAS, "PER1 activity-timing cohort studies (Lim 2012)")],
    )
    add(
        "rs12649507", "CLOCK", "CLOCK Intronic (Sleep Duration Modifier)", "4", 56316430,
        ["sleep", "circadian"], "moderate", "A", "G",
        "CLOCK intronic variant appearing in sleep-duration and exercise-interaction cohort analyses; small effects.",
        G("AA", "typical", "Reference.", "Behavioral light/dark timing dominates."),
        G("AG", "typical", "Intermediate.", "Small."),
        G("GG", "typical", "Modifier pair.", "Small cohort-level sleep-duration shifts."),
        tier="tendency", effect="Small",
        citations=[C(GWAS, "CLOCK sleep-duration cohort studies")],
    )
