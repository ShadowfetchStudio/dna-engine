"""Physical traits, sensory perception & benign phenotypes — curated chip-callable markers.

Everything here is deliberately low-stakes: taste, smell, hair form, stature.
Tiers are honest — several classic "fun" traits are tendencies, not laws.
"""
from .common import G, C, CHIPS_ALL, PGKB, GWAS, CLIN, CPIC


def register(add):
    add(
        "rs1726866", "TAS2R38", "Bitter Taste Receptor (V262A, PAV haplotype site 2)", "7", 141672705,
        ["traits", "taste", "sensory"], "strong", "C", "T",
        "Second of the three TAS2R38 haplotype sites. The PAV (taster) haplotype carries Pro49-Ala262-Val296 residues read jointly; site 2 distinguishes the taster (C) from non-taster (T) form here.",
        G("Taster allele pair (CC)", "typical", "Both copies carry the site-2 taster residue.", "Combined with the other two sites this supports the PAV (bitter-sensitive) haplotype."),
        G("Mixed haplotype site (CT)", "typical", "One taster, one non-taster residue at site 2.", "Intermediate PROP/PTC bitterness is common for PAV/AVI heterozygotes."),
        G("Non-taster allele pair (TT)", "typical", "Both copies carry the non-taster residue.", "Supports the AVI non-taster haplotype: cruciferous bitterness reads muted."),
        notes="Interpret as a haplotype with rs713598 and rs10246939 — the compound TAS2R38 card does this.",
        tier="well-replicated", transferability="multi-ancestry",
        effect="Near-Mendelian for PTC/PROP bitter perception as part of the PAV/AVI haplotype",
        citations=[C(12595690, "Kim 2003, Science — TAS2R38 haplotypes and PTC tasting")],
    )
    add(
        "rs10246939", "TAS2R38", "Bitter Taste Receptor (I296V, PAV haplotype site 3)", "7", 141672604,
        ["traits", "taste", "sensory"], "strong", "T", "C",
        "Third TAS2R38 haplotype site: the taster (T) vs non-taster (C) residue at position 296. The three sites travel together as PAV or AVI in almost all people.",
        G("Taster residue (TT)", "typical", "Site-3 taster residue on both copies.", "Consistent with PAV taster haplotype."),
        G("Heterozygous site 3 (CT)", "typical", "One copy each.", "Consistent with PAV/AVI intermediate tasting."),
        G("Non-taster residue (CC)", "typical", "Non-taster residue on both copies.", "Consistent with AVI non-taster haplotype."),
        tier="well-replicated", transferability="multi-ancestry",
        effect="Near-Mendelian as part of the PAV/AVI haplotype",
        citations=[C(12595690, "Kim 2003, Science — TAS2R38 haplotypes")],
    )
    add(
        "rs35874116", "TAS1R2", "Sweet Receptor Sensitivity (Ile191Val)", "1", 19166700,
        ["traits", "taste", "nutrition"], "moderate", "T", "C",
        "TAS1R2 pairs with TAS1R3 to form the main sweet receptor. Ile191Val subtly changes receptor efficiency; Val carriers showed modestly different sugar intake in cohort studies.",
        G("Ile/Ile (TT)", "typical", "Reference sweet receptor.", "Typical sweet perception; intake is driven mostly by habit and environment."),
        G("Ile/Val (CT)", "typical", "One Val copy.", "Possible slightly lower sweet sensitivity — evidence is modest."),
        G("Val/Val (CC)", "notable", "Two Val copies.", "Associated in some cohorts with higher sugar consumption, possibly via blunted sweet signaling. A tendency, not a destiny.",
          eat=["If you track sugar intake, be aware sweet perception can run slightly muted — measure, don't guess."]),
        tier="tendency", effect="Small shifts in sweet perception/sugar intake in cohort studies",
        citations=[C(GWAS, "TAS1R2 Ile191Val dietary intake studies (Eny 2010 and replications) — modest, heterogeneous")],
    )
    add(
        "rs10427255", "ZEB2 region", "Photic Sneeze Reflex (ACHOO)", "2", 145544783,
        ["traits", "sensory"], "moderate", "C", "T",
        "The photic sneeze reflex — sneezing on sudden bright light — mapped to this intergenic region near ZEB2 in large participant-cohort GWAS and has replicated since.",
        G("Higher photic-sneeze likelihood (CC)", "typical", "Two copies of the sneeze-associated allele.", "Bright-light sneezing is more likely; harmless, but worth knowing before you exit a tunnel into sunlight while driving."),
        G("Intermediate (CT)", "typical", "One copy.", "Intermediate likelihood of the reflex."),
        G("Lower likelihood (TT)", "typical", "No sneeze-associated allele at this site.", "The reflex is less likely, though this single SNP does not fully determine it."),
        tier="replicated", effect="OR ~1.3 per allele in GWAS — modest, polygenic trait",
        citations=[C(20585627, "Eriksson 2010, PLoS Genet — participant-driven GWAS incl. photic sneeze")],
    )
    add(
        "rs4481887", "OR2M7 region", "Asparagus Metabolite Anosmia", "1", 248496863,
        ["traits", "sensory"], "moderate", "G", "A",
        "Ability to smell asparagus metabolites in urine maps to an olfactory-receptor cluster on 1q44. The G allele associates with detection; many people are anosmic to these sulfurous metabolites.",
        G("Likely smeller (GG)", "typical", "Two detection-associated alleles.", "Most GG carriers can detect asparagus metabolites."),
        G("Intermediate (AG)", "typical", "One copy.", "Detection is common but not guaranteed."),
        G("Likely non-smeller (AA)", "typical", "No detection allele here.", "Higher likelihood of asparagus anosmia — a benign quirk of the OR cluster."),
        tier="replicated", effect="Strongest single locus for this benign trait; polygenic background remains",
        citations=[C(GWAS, "Asparagus-anosmia OR-cluster association (Pelchat 2011; Eriksson 2010)")],
    )
    add(
        "rs11803731", "TCHH", "Straight vs Curly Hair (European axis)", "1", 152083325,
        ["traits", "hair", "morphology"], "strong", "A", "T",
        "Trichohyalin cross-links keratin in the inner root sheath. The T allele associates with straighter hair in European-ancestry cohorts; EDAR dominates the East-Asian straight-hair axis instead.",
        G("Curl-leaning (AA)", "typical", "No straight-hair allele at TCHH.", "Hair form is polygenic; this locus contributes a modest push toward wave/curl."),
        G("Intermediate (AT)", "typical", "One straight-hair allele.", "Intermediate contribution."),
        G("Straight-leaning (TT)", "typical", "Two straight-hair alleles.", "Modest push toward straighter hair in European-ancestry backgrounds."),
        notes="Palindromic A/T site: strand cannot be resolved by complement; treat unexpected genotypes with caution.",
        tier="replicated", effect="Explains ~6% of European hair-curl variance — modest",
        transferability="euro-biased", reviewed=True,
        citations=[C(19896111, "Medland 2009, Am J Hum Genet — TCHH and straight hair")],
    )
    add(
        "rs17646946", "TCHH region", "Hair Texture Lead GWAS Signal", "1", 152062676,
        ["traits", "hair"], "moderate", "G", "A",
        "Lead TCHH-region GWAS signal for hair texture in European cohorts, in strong LD with the functional rs11803731 candidate.",
        G("Straight-associated (GG)", "typical", "Straight-texture lead-signal homozygote.", "Modest straight-hair contribution; polygenic background dominates."),
        G("One copy (AG)", "typical", "Intermediate.", "Intermediate contribution."),
        G("Curl-leaning (AA)", "typical", "Minor-allele homozygote.", "Modest wave/curl contribution."),
        tier="replicated", effect="Modest, LD with the main TCHH signal", transferability="euro-biased",
        citations=[C(19896111, "Medland 2009 — TCHH hair texture region")],
    )
    add(
        "rs3827760", "EDAR", "Hair Shaft Thickness & Tooth Shape (V370A)", "2", 109513601,
        ["traits", "hair", "morphology"], "strong", "A", "G",
        "EDAR V370A enhances ectodysplasin signaling: thicker straight hair shafts, shovel-shaped incisors, and altered sweat-gland density. One of the strongest selection signals in East-Asian and Indigenous-American ancestries.",
        G("Reference EDAR (AA)", "typical", "No 370A allele.", "Typical hair-shaft cross-section for non-East-Asian backgrounds."),
        G("One enhanced-signaling copy (AG)", "typical", "Intermediate hair-shaft thickness effect.", "Partial phenotype — the allele is semi-dominant."),
        G("Enhanced signaling (GG)", "typical", "Two 370A copies.", "Thicker, straighter hair shaft and often shovel incisors — a benign structural variant."),
        tier="well-replicated", transferability="east-asian-derived",
        effect="Strong, near-visible morphology effect in carriers",
        citations=[C(18561327, "Fujimoto 2008, Hum Mol Genet — EDAR V370A and hair thickness")],
    )
    add(
        "rs4778138", "OCA2 region", "Freckling / Sun Response Modifier", "15", 28335820,
        ["traits", "pigmentation"], "moderate", "A", "G",
        "OCA2-region modifier contributing to freckling and sun-response variation in European cohorts, partially independent of the main HERC2 eye-color switch.",
        G("Reference (AA)", "typical", "Typical freckling contribution.", "Freckling is strongly MC1R-driven; this adds a small modifier."),
        G("One copy (AG)", "typical", "Small modifier effect.", "Minor contribution."),
        G("Two copies (GG)", "typical", "Modifier homozygote.", "Small shift in freckling tendency."),
        tier="tendency", effect="Small modifier on a polygenic trait", transferability="euro-biased",
        citations=[C(GWAS, "OCA2-region freckling/pigmentation associations (Sulem 2007 and successors)")],
    )
    add(
        "rs6152", "AR", "Androgenic Alopecia (X-linked AR locus)", "X", 66765627,
        ["traits", "hair", "morphology"], "strong", "G", "A",
        "The androgen-receptor locus is the strongest single contributor to male-pattern hair loss. Males carry one X, so a single allele reports the maternal-line contribution; the trait remains strongly polygenic.",
        G("Risk-associated (GG)", "notable", "AR risk allele present (males: hemizygous).", "Higher likelihood of androgenic hair thinning with age; polygenic background and hormones dominate timing."),
        G("Mixed (AG)", "typical", "Female heterozygote.", "Intermediate contribution in females."),
        G("Lower-risk (AA)", "typical", "Protective allele.", "Lower AR-locus contribution to pattern hair loss."),
        tier="replicated", effect="Strongest single locus for male-pattern baldness; still far from deterministic",
        transferability="euro-biased",
        citations=[C(15902657, "Hillmer 2005, Am J Hum Genet — AR and androgenetic alopecia")],
    )
    add(
        "rs2180439", "PAX1/FOXA2 region", "Male Pattern Hair Loss (20p11 signal)", "20", 21845690,
        ["traits", "hair"], "strong", "C", "T",
        "The 20p11 region is the second major androgenic-alopecia locus after AR, replicated across European cohorts.",
        G("Higher-risk (CC)", "notable", "Two risk alleles.", "Adds to AR-locus risk for pattern hair loss."),
        G("Intermediate (CT)", "typical", "One risk allele.", "Intermediate contribution."),
        G("Lower-risk (TT)", "typical", "No risk allele at this locus.", "Lower 20p11 contribution."),
        tier="replicated", effect="OR ~1.6 per allele in European cohorts — moderate for this trait",
        transferability="euro-biased",
        citations=[C(18849994, "Hillmer 2008, Nat Genet — 20p11 and male-pattern baldness (with Richards 2008)")],
    )
    add(
        "rs1667394", "HERC2 region", "Blond vs Brown Hair Modifier", "15", 28530182,
        ["traits", "hair", "pigmentation"], "strong", "A", "G",
        "HERC2/OCA2-region variant strongly associated with blond vs brown hair in Northern-European cohorts, partially independent of the eye-color switch.",
        G("Blond-leaning (AA)", "typical", "Two light-hair alleles.", "Higher likelihood of lighter hair in European backgrounds."),
        G("Intermediate (AG)", "typical", "One copy.", "Intermediate pigment contribution."),
        G("Brown-leaning (GG)", "typical", "No light-hair allele here.", "Darker hair more likely."),
        tier="replicated", effect="Strong within-European hair-shade association (Icelandic discovery)",
        transferability="euro-biased",
        citations=[C(17952075, "Sulem 2007, Nat Genet — pigmentation loci in Icelanders")],
    )
    add(
        "rs17070145", "KIBRA (WWC1)", "Episodic Memory (T carrier signal)", "5", 167715339,
        ["traits", "cognition"], "moderate", "C", "T",
        "KIBRA participates in synaptic plasticity. T-carriers showed better delayed-recall episodic memory in the original Science report and several replications; effects are small and cohort-dependent.",
        G("No T allele (CC)", "typical", "Reference memory-locus genotype.", "Episodic memory is overwhelmingly driven by sleep, attention, and practice."),
        G("T carrier (CT)", "typical", "One T allele.", "Small average advantage in delayed-recall tasks in some cohorts."),
        G("T homozygote (TT)", "typical", "Two T alleles.", "Same small tendency; not a cognitive verdict."),
        tier="tendency", effect="~0.2 SD delayed-recall difference in discovery; shrinks in replication",
        citations=[C(17023657, "Papassotiropoulos 2006, Science — KIBRA and human memory")],
    )
    add(
        "rs4570625", "TPH2", "Serotonin Synthesis Promoter (-703 G/T)", "12", 72332954,
        ["traits", "stress", "neurotransmitters"], "moderate", "G", "T",
        "TPH2 is the brain-specific rate-limiting enzyme for serotonin synthesis. The promoter G/T variant shows small associations with emotional processing and amygdala reactivity in imaging-genetics cohorts.",
        G("GG", "typical", "Common promoter form.", "Typical serotonin-synthesis contribution."),
        G("GT", "typical", "Heterozygote.", "Small, inconsistent effects on emotional reactivity."),
        G("TT", "typical", "Minor-allele homozygote.", "Some imaging cohorts report altered amygdala reactivity — evidence is a tendency at best."),
        tier="tendency", effect="Small imaging-genetics effects, heterogeneous replication",
        citations=[C(GWAS, "TPH2 promoter imaging-genetics literature")],
    )
    add(
        "rs1800955", "DRD4", "Novelty Seeking Promoter (-521 C/T)", "11", 636784,
        ["traits", "cognition", "neurotransmitters"], "moderate", "T", "C",
        "DRD4 promoter variant with small associations to novelty-seeking temperament in meta-analyses; the famous exon-III 48-bp VNTR is NOT typed by SNP arrays.",
        G("TT", "typical", "Reference promoter.", "Temperament is massively multifactorial."),
        G("CT", "typical", "Heterozygote.", "Small average shift in novelty-seeking scores."),
        G("CC", "typical", "C homozygote.", "Meta-analyses show a small novelty-seeking association — a nudge, not a personality."),
        notes="The DRD4 7R VNTR itself is invisible to this array — see the Limitations panel.",
        tier="tendency", effect="Meta-analytic effect ~d 0.1 for novelty seeking — tiny",
        citations=[C(GWAS, "DRD4 -521C/T temperament meta-analyses (Munafò 2008)")],
    )
    add(
        "rs713586", "ADCY3/POMC region", "BMI Common Signal (2p23)", "2", 25129473,
        ["traits", "morphology", "weight", "metabolism"], "strong", "C", "T",
        "Replicated GIANT-consortium BMI locus near ADCY3/POMC, part of the central appetite-regulation axis.",
        G("Higher-BMI-leaning (CC)", "typical", "Two BMI-increasing alleles.", "Small appetite-axis contribution; energy balance dominates."),
        G("Intermediate (CT)", "typical", "One copy.", "Intermediate."),
        G("Reference (TT)", "typical", "No BMI-increasing allele here.", "Slightly lower average BMI contribution."),
        tier="well-replicated", effect="~0.1 BMI units per allele — small", transferability="euro-biased",
        citations=[C(20935630, "Speliotes 2010, Nat Genet — GIANT BMI meta-analysis")],
    )
    add(
        "rs143384", "GDF5", "Height & Joint Development (5'UTR)", "20", 34025756,
        ["traits", "morphology", "injury"], "strong", "A", "G",
        "GDF5 patterns skeletal joints. The A allele lowers GDF5 expression: associated with slightly shorter stature and modestly higher osteoarthritis risk in large meta-analyses.",
        G("Lower-expression (AA)", "notable", "Two low-expression alleles.", "Slightly shorter average stature and modestly higher knee/hip OA risk. Strength training and load management remain the levers that matter.",
          move=["Prioritize progressive strength work around hips/knees; strong joints out-run this odds ratio."]),
        G("Intermediate (AG)", "typical", "One copy.", "Intermediate expression."),
        G("Reference (GG)", "typical", "Typical GDF5 expression.", "Typical joint-development baseline."),
        tier="well-replicated", effect="OA OR ~1.15-1.2 per A allele; height −0.3 cm per allele — small",
        transferability="multi-ancestry",
        citations=[C(17384641, "Miyamoto 2007, Nat Genet — GDF5 and osteoarthritis"), C(GWAS, "GIANT height meta-analyses")],
    )
    add(
        "rs1042725", "HMGA2", "Adult Height Common Variant", "12", 66358347,
        ["traits", "morphology"], "strong", "C", "T",
        "The first robust common height SNP: each C allele associates with ~0.4 cm taller adult stature. Height is driven by thousands of loci; this is a flagship example of tiny per-SNP effects.",
        G("Taller-leaning (CC)", "typical", "Two height-increasing alleles (~+0.8 cm vs TT average).", "An honest yardstick for what one common SNP can and cannot say."),
        G("Intermediate (CT)", "typical", "One copy.", "~+0.4 cm average."),
        G("Reference (TT)", "typical", "Reference height contribution.", "Height remains >80% heritable but massively polygenic."),
        tier="well-replicated", effect="~0.4 cm per allele — tiny but iron-clad",
        transferability="multi-ancestry",
        citations=[C(17767157, "Weedon 2007, Nat Genet — HMGA2 and adult height")],
    )
    add(
        "rs7832552", "TRHR", "Lean Body Mass Signal", "8", 110114319,
        ["traits", "muscle", "morphology"], "moderate", "C", "T",
        "Thyrotropin-releasing-hormone receptor locus associated with lean body mass in GWAS; small effect on muscle-mass baseline.",
        G("Reference (CC)", "typical", "Typical lean-mass contribution.", "Resistance training dominates lean mass."),
        G("One copy (CT)", "typical", "Intermediate.", "Small average lean-mass difference."),
        G("Two copies (TT)", "typical", "Lean-mass-associated homozygote.", "Slightly higher average lean mass in cohorts — train anyway."),
        tier="tendency", effect="Small cohort-level lean-mass differences",
        citations=[C(GWAS, "TRHR lean-body-mass GWAS (Liu 2009)")],
    )
    add(
        "rs2274333", "CA6", "Carbonic Anhydrase VI (Gustin) — Taste Modulation", "1", 9005568,
        ["traits", "taste"], "moderate", "A", "G",
        "Salivary carbonic anhydrase (gustin) participates in taste-bud maintenance; variants associate with bitter-taste modulation and fungiform papillae density in small cohorts.",
        G("AA", "typical", "Reference gustin.", "Typical taste-bud trophic support."),
        G("AG", "typical", "Heterozygote.", "Minor shifts possible."),
        G("GG", "typical", "Variant homozygote.", "Associated with altered taste-papillae density in small studies — tendency only."),
        tier="tendency", effect="Small effects in small cohorts",
        citations=[C(GWAS, "CA6/gustin taste literature (Padiglia/Melis) — limited cohorts")],
    )
    add(
        "rs838133", "FGF21", "Sweet Tooth / Macronutrient Preference", "19", 49259529,
        ["traits", "taste", "nutrition"], "strong", "A", "G",
        "FGF21 is a liver-derived hormone regulating sweet preference and alcohol intake. The A allele associates with higher carbohydrate/sweet preference in large biobank analyses.",
        G("Sweet-leaning (AA)", "notable", "Two sweet-preference alleles.", "Higher average sweet/carb preference; useful self-knowledge when designing a sustainable diet.",
          eat=["Structure the environment: keep fruit visible, sweets out of the house; the preference is real but plastic."]),
        G("Intermediate (AG)", "typical", "One copy.", "Intermediate preference shift."),
        G("Reference (GG)", "typical", "Typical macronutrient preference baseline.", "Preference driven mostly by habit."),
        tier="well-replicated", effect="Small but robust macronutrient-preference shift at biobank scale",
        transferability="multi-ancestry",
        citations=[C(28494130, "Søberg 2017, Cell Metab — FGF21 and sweet preference")],
    )
