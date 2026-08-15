"""Histamine intolerance, gut & taste — curated chip-callable markers."""
from .common import G, C, CHIPS_ALL, PGKB, GWAS, CLIN, CPIC


def register(add):
    add(
        "rs10156191", "AOC1", "Diamine Oxidase (DAO / Histamine Breakdown in Gut)", "7", 150829807,
        ["histamine", "gut", "nutrition"], "strong", "C", "T",
        "AOC1 encodes Diamine Oxidase (DAO), the primary digestive enzyme that degrades ingested histamine in the intestinal lumen. The T allele reduces DAO enzyme activity, leading to histamine intolerance symptoms (headaches, flushing, nasal congestion, bloating, hives after aged or fermented foods).",
        G("Normal DAO Activity (CC)", "typical", "Full DAO expression in intestinal mucosa.", "Efficient degradation of dietary histamine."),
        G("Reduced DAO Activity (CT)", "notable",
          "One T allele. Moderately reduced luminal histamine breakdown.",
          "Sensitive to high-histamine food combinations (aged cheese + red wine + cured meats).",
          eat=["Moderate consumption of aged cheeses, wine, fermented foods, and cured meats if symptoms occur."]),
        G("High Histamine Intolerance Susceptibility (TT)", "caution",
          "Two T alleles. Significantly reduced DAO enzyme production.",
          "High susceptibility to dietary histamine overload: flushing, post-meal brain fog, migraine triggers, and digestive distress.",
          eat=["Follow a low-histamine dietary approach: prioritize fresh meats, avoid aged/fermented foods, leftovers, canned fish, and alcohol.", "DAO enzyme supplements taken before meals can assist in degrading dietary histamine."]),
        notes="Primary genetic locus for gut-mediated histamine intolerance.",
    )

    add(
        "rs4988235", "MCM6/LCT", "Lactase Persistence (-13910C>T / Adult Dairy Tolerance)", "2", 136608646,
        ["nutrition", "gut"], "strong", "C", "T",
        "rs4988235 in MCM6 is the master regulatory switch for the LCT gene. In ancestral humans, lactase shuts off after weaning (Lactase Non-Persistence / CC). The T allele keeps lactase production active into adulthood (Lactase Persistence / CT or TT).",
        G("Lactase Persistent (TT)", "advantageous",
          "Two persistence alleles. Lifelong high intestinal lactase production.",
          "Full capability to digest milk sugar (lactose) throughout adulthood without bloating or digestive symptoms.",
          eat=["Can consume regular milk, yogurt, and dairy products without lactose-related intolerance."]),
        G("Lactase Persistent Heterozygote (CT)", "advantageous",
          "One persistence allele. Sustained adult lactase production.",
          "Tolerates standard dairy products well.",
          eat=["Standard dairy tolerance."]),
        G("Lactase Non-Persistent / Lactose Intolerant (CC)", "notable",
          "Two ancestral alleles. Adult decline in lactase enzyme expression.",
          "Ingestion of unfermented milk sugar (lactose) leads to microbial fermentation, bloating, gas, and osmotic diarrhea.",
          eat=["Choose naturally lactose-free dairy (hard cheeses, butter), fermented dairy (kefir, Greek yogurt), lactose-free milk, or use lactase enzyme drops."]),
        notes="The classic human evolutionary selective sweep for adult pastoralism.",
    )

    add(
        "rs713598", "TAS2R38", "Bitter Taste Receptor (PAV / AVI Bitter Sensitivity)", "7", 141673345,
        ["traits", "taste", "nutrition"], "strong", "C", "G",
        "TAS2R38 governs sensitivity to glucosinolates and thiourea compounds (PTC/PROP) found in cruciferous vegetables (broccoli, kale, Brussels sprouts) and coffee. C corresponds to the taster (Proline/P) allele; G to non-taster (Alanine/A).",
        G("Super-Taster Allele (CC / PAV)", "notable",
          "Two bitter taster alleles. Intense perception of glucosinolate bitterness.",
          "Cruciferous vegetables (kale, broccoli, cabbage), black coffee, and tonic water taste intensely bitter.",
          eat=["Cook crucifers with healthy fats (olive oil, butter), sea salt, and acids (lemon/vinegar) to neutralize the bitter receptor binding.", "Do not skip brassicas—prepare them properly."]),
        G("Medium Taster (CG)", "typical", "Intermediate bitter taste sensitivity.", "Mild bitterness perception."),
        G("Non-Taster (GG / AVI)", "typical",
          "Two non-taster alleles. Dulled bitter perception.",
          "Cruciferous vegetables and coffee taste mild and sweet.",
          eat=["Naturally tolerates raw cruciferous vegetables."]),
    )

    # --- 2.0 expansion: DAO alleles, IBD biology, lactase refinement ---
    add(
        "rs2052129", "AOC1 (DAO)", "DAO Promoter Variant (Histamine Clearance)", "7", 150554592,
        ["histamine", "gut"], "moderate", "G", "T",
        "Promoter variant of diamine oxidase, the gut enzyme that degrades dietary histamine; the T allele reduces promoter activity and serum DAO in functional studies.",
        G("Typical DAO promoter (GG)", "typical", "Standard DAO expression.", "Typical histamine tolerance."),
        G("One reduced-activity allele (GT)", "typical", "Modestly lower DAO expression.", "Combined with other DAO variants this can lower histamine buffer capacity."),
        G("Reduced-promoter pair (TT)", "notable", "Lower serum DAO pattern.", "If aged/fermented foods, red wine, or leftovers reliably trigger flushing/headaches, this genotype supports a structured low-histamine trial.",
          eat=["Test systematically: 2-3 week low-histamine trial with a symptom log beats guessing.", "Freshness matters — histamine grows in leftovers; cook-and-freeze quickly."]),
        tier="replicated", effect="Replicated serum-DAO reduction — moderate for histamine handling",
        citations=[C(GWAS, "AOC1 promoter DAO-activity studies (Maintz 2011; Garcia-Martin 2015)")],
    )
    add(
        "rs1049793", "AOC1 (DAO)", "DAO H645D (Reduced Activity)", "7", 150561748,
        ["histamine", "gut"], "moderate", "C", "G",
        "Coding DAO variant (His645Asp) with reduced enzyme activity in expression studies; part of the functional DAO variant trio with rs10156191 and rs1049742.",
        G("Typical (CC)", "typical", "Reference DAO kinetics.", "Baseline."),
        G("One 645D allele (CG)", "typical", "Modestly reduced activity.", "Counts toward total DAO capacity."),
        G("Two 645D alleles (GG)", "notable", "Reduced-activity pair.", "Same structured-trial advice as the other DAO variants; DAO capacity is additive across variants.",
          eat=["A written trigger log (foods, timing, symptoms) turns this from a suspicion into an answer."]),
        notes="Palindromic C/G site — reviewed.",
        tier="replicated", effect="Reduced enzyme activity in vitro — moderate", reviewed=True,
        citations=[C(GWAS, "AOC1 H645D functional studies")],
    )
    add(
        "rs1049742", "AOC1 (DAO)", "DAO S332F (Reduced Activity)", "7", 150558467,
        ["histamine", "gut"], "moderate", "C", "T",
        "Third functional DAO variant (Ser332Phe) with modestly reduced activity.",
        G("Typical (CC)", "typical", "Reference.", "Baseline."),
        G("One 332F allele (CT)", "typical", "Modest reduction.", "Counts toward the DAO total."),
        G("Two 332F alleles (TT)", "typical", "Reduced-activity pair.", "Interpret with the other DAO variants."),
        tier="replicated", effect="Modest activity reduction",
        citations=[C(GWAS, "AOC1 S332F functional studies")],
    )
    add(
        "rs182549", "MCM6", "Lactase Persistence Haplotype Support (-22018G>A)", "2", 136616754,
        ["nutrition", "gut"], "strong", "C", "T",
        "Second MCM6 enhancer variant (-22018) traveling with the -13910 lactase-persistence allele in Europeans; corroborates the rs4988235 call.",
        G("Non-persistence support (CC)", "typical", "No persistence allele at this site.", "Interpret with rs4988235."),
        G("One persistence allele (CT)", "typical", "Persistence-haplotype support.", "Interpret with rs4988235."),
        G("Persistence pair (TT)", "typical", "Strong persistence-haplotype support.", "Interpret with rs4988235."),
        tier="well-replicated", transferability="euro-biased",
        effect="Haplotype confirmation for European lactase persistence",
        citations=[C(11788828, "Enattah 2002 — MCM6 enhancer variants")],
    )
    add(
        "rs2066844", "NOD2", "Crohn's Disease Variant (R702W)", "16", 50745926,
        ["gut", "immunity", "autoimmunity"], "strong", "C", "T",
        "NOD2 senses bacterial peptidoglycan in the gut wall. R702W impairs sensing: the strongest common Crohn's-disease factor family; absolute risk stays low even for carriers.",
        G("Typical NOD2 (CC)", "typical", "Reference bacterial sensing.", "Baseline IBD odds."),
        G("One R702W allele (CT)", "notable", "Crohn's OR ~2-3.", "Absolute risk remains low (~1-2%); persistent GI symptoms deserve earlier attention rather than worry.",
          eat=["Fiber diversity and not smoking are the two strongest modifiable gut-inflammation factors."]),
        G("Two R702W alleles (TT)", "caution", "Crohn's OR ~15-20 (still minority absolute risk).", "Chronic abdominal pain/diarrhea/weight loss warrant GI evaluation without delay. Smoking is the single worst input for NOD2-variant guts."),
        tier="well-replicated", transferability="euro-biased",
        effect="OR ~2-3 het, ~17 hom for Crohn's — large relative, small absolute",
        citations=[C(11385576, "Hugot 2001, Nature — NOD2 and Crohn's disease")],
    )
    add(
        "rs2066845", "NOD2", "Crohn's Disease Variant (G908R)", "16", 50756540,
        ["gut", "immunity", "autoimmunity"], "strong", "G", "C",
        "Second major NOD2 Crohn's allele (G908R), same impaired-sensing mechanism as R702W.",
        G("Typical (GG)", "typical", "Reference.", "Baseline."),
        G("One G908R allele (CG)", "notable", "Crohn's OR ~2-3.", "Same context as R702W — low absolute risk, earlier attention to persistent symptoms."),
        G("Two G908R alleles (CC)", "caution", "High relative risk (rare).", "Same guidance as R702W homozygosity."),
        notes="Palindromic G/C site — reviewed.",
        tier="well-replicated", transferability="euro-biased", reviewed=True,
        effect="OR ~2-3 het for Crohn's",
        citations=[C(11385576, "Hugot 2001, Nature — NOD2 variants")],
    )
    add(
        "rs11209026", "IL23R", "IL-23 Receptor Protective Variant (R381Q)", "1", 67705958,
        ["gut", "immunity", "autoimmunity"], "strong", "G", "A",
        "IL23R R381Q dampens IL-23 signaling: the A allele PROTECTS against Crohn's, ulcerative colitis, psoriasis, and ankylosing spondylitis — the variant that validated IL-23 blockade as a drug class.",
        G("Typical IL-23 signaling (GG)", "typical", "Reference inflammatory signaling.", "Baseline."),
        G("Protective carrier (AG)", "advantageous", "IBD OR ~0.4 — substantially protective.", "A rare piece of purely good news; lifestyle basics still apply."),
        G("Protective pair (AA)", "advantageous", "Very rare double-protective genotype.", "Strongest common IBD protection known."),
        tier="well-replicated", transferability="euro-biased",
        effect="Protective OR ~0.4 for IBD spectrum — strong",
        citations=[C(17068223, "Duerr 2006, Science — IL23R and IBD")],
    )
    add(
        "rs2241880", "ATG16L1", "Autophagy Variant (T300A, Crohn's)", "2", 234183368,
        ["gut", "immunity"], "strong", "A", "G",
        "ATG16L1 T300A impairs autophagy of gut bacteria; replicated Crohn's factor that interacts with NOD2 biology.",
        G("Typical autophagy (AA)", "typical", "Reference.", "Baseline."),
        G("One T300A allele (AG)", "typical", "Modest Crohn's contribution.", "Small."),
        G("T300A pair (GG)", "notable", "Crohn's OR ~1.7-2 vs AA.", "Same modifiables: no smoking, fiber diversity."),
        tier="well-replicated", transferability="euro-biased",
        effect="OR ~1.3 per allele",
        citations=[C(17200669, "Hampe 2007, Nat Genet — ATG16L1 and Crohn's")],
    )
    add(
        "rs4263839", "TNFSF15", "TL1A Variant (IBD/IBS Overlap)", "9", 117568766,
        ["gut", "immunity"], "moderate", "G", "A",
        "TNFSF15 (TL1A) drives mucosal inflammation; associated with IBD across ancestries (strongest in East-Asian Crohn's) and with IBS severity in some cohorts.",
        G("Risk-leaning (GG)", "typical", "Higher TL1A expression pattern.", "Small effect."),
        G("Intermediate (AG)", "typical", "Intermediate.", "Baseline."),
        G("Reference (AA)", "typical", "Lower-expression pattern.", "Baseline."),
        tier="replicated", transferability="multi-ancestry",
        effect="OR ~1.2-1.4 for IBD; East-Asian Crohn's strongest",
        citations=[C(GWAS, "TNFSF15 IBD meta-analyses (Yamazaki 2005)")],
    )
    add(
        "rs2294008", "PSCA", "Gastric Mucosa Variant", "8", 143761931,
        ["gut"], "moderate", "C", "T",
        "PSCA affects gastric epithelial renewal; the T allele associates with gastric-ulcer and gastric-cancer risk in East-Asian cohorts (where H. pylori context dominates).",
        G("Reference (CC)", "typical", "Baseline.", "H. pylori status and smoking dwarf this genotype."),
        G("One risk allele (CT)", "typical", "Small mucosal-vulnerability signal.", "If chronic reflux/gastritis is a theme, H. pylori testing is the useful step."),
        G("Risk pair (TT)", "typical", "Modest ulcer association (East-Asian data).", "Same practical step: H. pylori testing when symptomatic."),
        tier="replicated", transferability="east-asian-derived",
        effect="OR ~1.2-1.4 in East-Asian cohorts",
        citations=[C(GWAS, "PSCA gastric studies (Sakamoto 2008)")],
    )
    add(
        "rs653178", "ATXN2/SH2B3", "Celiac & Multi-Autoimmune Pleiotropy Locus", "12", 112007756,
        ["gut", "immunity", "autoimmunity", "cardio"], "strong", "T", "C",
        "The SH2B3 (LNK) region is a pleiotropy champion: celiac disease, type 1 diabetes, hypertension, and blood counts all associate here — one variant, many small effects.",
        G("Reference (TT)", "typical", "Baseline.", "Baseline."),
        G("Intermediate (CT)", "typical", "Small multi-trait shifts.", "Small."),
        G("Risk-leaning pair (CC)", "typical", "Modest celiac/autoimmune contribution plus ~1 mmHg BP.", "Context for the celiac HLA tags — the HLA-DQ card carries the real signal."),
        tier="well-replicated", effect="OR ~1.2 celiac; pleiotropic small effects",
        transferability="euro-biased",
        citations=[C(GWAS, "SH2B3 pleiotropy literature (Hunt 2008 celiac GWAS)")],
    )
