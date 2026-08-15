"""Methylation, 1-carbon metabolism & folate cycle — curated chip-callable markers."""
from .common import G, C, CHIPS_ALL, PGKB, GWAS, CLIN, CPIC


def register(add):
    add(
        "rs1801133", "MTHFR", "Folate Methylation (C677T / Ala222Val)", "1", 11856378,
        ["nutrition", "vitamins", "cardio", "methylation"], "strong", "C", "T",
        "C677T (Ala222Val) destabilizes the MTHFR enzyme. Heterozygotes (CT) retain ~65% activity; homozygotes (TT) retain ~30% activity, especially under low riboflavin (B2). Slower production of 5-MTHF impairs homocysteine remethylation.",
        G("Typical MTHFR activity (CC)", "typical",
          "Both copies are the wild-type C allele. Folate conversion to 5-MTHF proceeds normally.",
          "No genetic bottleneck at C677T. Folate requirements can be met with standard dietary leafy greens, legumes, and whole foods.",
          eat=["Maintain balanced leafy green vegetables and legume intake. No need for specialized high-dose methylfolate from this SNP."]),
        G("Intermediate MTHFR activity (CT)", "notable",
          "One T copy. Enzyme stability is moderately reduced (~65% residual activity).",
          "Slightly higher sensitivity to low dietary folate or low riboflavin (B2, the MTHFR cofactor). Usually clinically silent unless dietary intake is low.",
          eat=["Prioritize folate-rich foods (spinach, arugula, lentils, eggs) and dietary riboflavin.", "If supplementing B vitamins, a modest active B-complex is generally well tolerated."]),
        G("Reduced MTHFR activity (TT)", "caution",
          "TT homozygote. Enzyme activity drops to ~30%, significantly slowing conversion of folate into active 5-MTHF.",
          "Most strongly associated with elevated plasma homocysteine when dietary folate or riboflavin is low. Not a disease, but requires proactive nutritional attention. Megadoses of synthetic folic acid can lead to unmetabolized folic acid in plasma.",
          eat=["Prioritize natural folates (leafy greens, liver, legumes) and dietary riboflavin (eggs, dairy, almonds).", "Avoid heavy consumption of foods fortified with high-dose synthetic folic acid.", "Include natural choline sources (pastured egg yolks, sunflower lecithin) to support the alternate BHMT remethylation pathway."],
          recover=["Discuss a fasting homocysteine blood panel with your physician if cardiovascular or reproductive health is a focus."]),
        notes="Effect is highly nutrient-dependent. Pair with MTHFR A1298C, MTRR, and PEMT for a complete 1-carbon read.",
    )

    add(
        "rs1801131", "MTHFR", "Folate Methylation (A1298C / Glu429Ala)", "1", 11854476,
        ["nutrition", "vitamins", "methylation"], "moderate", "A", "C",
        "A1298C sits in the C-terminal regulatory domain of MTHFR. By itself it causes a minor reduction in enzyme activity (~80% in CC), but compound heterozygosity (677CT + 1298AC) has an additive effect.",
        G("Typical (AA)", "typical", "No A1298C variant. Normal regulatory domain function.",
          "Standard dietary folate needs."),
        G("Heterozygote (AC)", "typical",
          "One C copy. Very mild effect in isolation.",
          "In the absence of C677T variants, this is considered a typical variation with minimal clinical significance.",
          eat=["Standard whole food diet with regular green vegetables."]),
        G("A1298C Homozygote (CC)", "notable",
          "Two C copies. Mildly reduced MTHFR regulation and tetrahydrobiopterin (BH4) coupling.",
          "May have a modest effect on neurotransmitter cofactor recycling (BH4) when oxidative stress is high. Less potent than C677T TT on homocysteine.",
          eat=["Emphasize antioxidant-rich foods, dark berries, and leafy greens to support BH4 and nitric oxide coupling."]),
        notes="Evaluate together with C677T rather than in isolation.",
    )

    add(
        "rs1801394", "MTRR", "Methionine Synthase Reductase (A66G / Ile22Met)", "5", 7870973,
        ["nutrition", "methylation", "vitamins"], "moderate", "A", "G",
        "MTRR maintains the active, reduced state of Methionine Synthase (MTR, Cob(I)alamin). The 66G variant reduces MTRR efficiency, requiring higher cellular B12 availability to maintain homocysteine clearance.",
        G("Typical MTRR (AA)", "typical", "Normal cobalamin reduction efficiency.", "Standard B12 dietary requirements."),
        G("MTRR Heterozygote (AG)", "typical", "One G allele. Mild reduction in MTR reactivation.",
          "Adequate dietary B12 prevents any functional impairment.",
          eat=["Ensure consistent dietary intake of bioavailable B12 (fish, poultry, eggs, dairy or fortified sources)."]),
        G("Reduced MTRR Efficiency (GG)", "notable",
          "Two G alleles. Lower efficiency in maintaining active vitamin B12 in the methionine synthase cycle.",
          "Can contribute to elevated homocysteine if active B12 (methylcobalamin/adenosylcobalamin) levels are suboptimal.",
          eat=["Ensure robust active B12 intake. If plant-based, utilize sublingual methylcobalamin/adenosylcobalamin rather than basic cyanocobalamin."]),
        notes="Crucial cofactor enzyme linking the folate and methionine cycles.",
    )

    add(
        "rs1805087", "MTR", "Methionine Synthase (A2756G / Asp919Gly)", "1", 236885200,
        ["nutrition", "methylation"], "moderate", "A", "G",
        "MTR catalyzes the transfer of a methyl group from 5-methyltetrahydrofolate to homocysteine, forming methionine and tetrahydrofolate. The G allele is associated with altered homocysteine conversion.",
        G("Typical (AA)", "typical", "Common genotype. Standard methionine synthesis rate.", "Dietary baseline."),
        G("Heterozygote (AG)", "typical", "One G allele. Generally balanced enzymatic flux.", "Standard nutrition."),
        G("G Variant (GG)", "notable", "Homozygous G. Altered MTR kinetics.",
          "Interacts with MTRR and B12 status. High-protein or high-homocysteine states warrant adequate B12 and folate.",
          eat=["Support with balanced choline, betaine (beets, spinach), and active B12."]),
    )

    add(
        "rs234706", "CBS", "Cystathionine Beta-Synthase (C699T)", "21", 44483187,
        ["nutrition", "methylation", "detox"], "moderate", "C", "T",
        "CBS initiates the transsulfuration pathway, converting homocysteine to cystathionine, leading to glutathione and taurine synthesis. The T allele is an upregulation/gain-of-function variant, accelerating homocysteine clearance toward sulfites and taurine.",
        G("Typical CBS Flux (CC)", "typical", "Standard baseline transsulfuration velocity.", "Normal sulfur amino acid handling."),
        G("Mildly Accelerated CBS (CT)", "typical", "One upregulated T allele.", "Slightly faster conversion of homocysteine into the transsulfuration pathway."),
        G("Accelerated Transsulfuration (TT)", "notable",
          "Homozygous upregulation. Homocysteine is rapidly pulled down into transsulfuration.",
          "Can lead to lower baseline homocysteine and higher downstream sulfite/sulfate production. Some individuals may be sensitive to high-sulfur foods or excess crucifers if molybdenum is low.",
          eat=["Ensure adequate dietary molybdenum (legumes, leafy greens) to support sulfite oxidase (SUOX) downstream."]),
        notes="Balances the choice between methyl remethylation vs transsulfuration/glutathione generation.",
    )

    add(
        "rs7946", "PEMT", "Phosphatidylethanolamine N-Methyltransferase (-744G>C)", "17", 17502758,
        ["nutrition", "methylation", "lipids"], "strong", "C", "T",
        "PEMT synthesizes phosphatidylcholine de novo in the liver using 3 SAMe molecules. Estrogen induces PEMT. Variants reduce endogenous choline synthesis, making dietary choline essential to prevent fatty liver (NAFLD) and muscle damage.",
        G("Normal PEMT Synthesis (CC)", "typical", "Standard endogenous phosphatidylcholine synthesis.", "Standard choline requirement (~450–550 mg/day)."),
        G("Reduced PEMT Capacity (CT)", "notable",
          "Heterozygote. Reduced de novo choline production.",
          "Dietary choline becomes more critical, particularly during pregnancy, lactation, or low-estrogen states.",
          eat=["Include 2–3 whole pastured eggs daily, or dietary fish, beef, or sunflower lecithin to supply phosphatidylcholine."]),
        G("High Dietary Choline Requirement (TT)", "caution",
          "Homozygous variant. Severely blunted endogenous phosphatidylcholine production.",
          "High susceptibility to hepatic fat accumulation (NAFLD) on low-choline diets. Requires dedicated dietary choline intake.",
          eat=["Prioritize rich dietary choline sources: egg yolks, salmon, organ meats, or sunflower lecithin (target 550+ mg/day).", "Crucial for cell membrane integrity, bile flow, and VLDL export from liver."]),
        notes="Key gene linking methylation to liver health, lipid export, and cognitive function.",
    )

    add(
        "rs3737597", "BHMT", "Betaine-Homocysteine Methyltransferase (Arg239Gln)", "5", 78426002,
        ["nutrition", "methylation"], "moderate", "A", "G",
        "BHMT provides the secondary, folate-independent pathway for remethylating homocysteine using betaine (trimethylglycine).",
        G("Typical BHMT (AA)", "typical", "Standard betaine-dependent remethylation.", "Normal dietary baseline."),
        G("Heterozygote (AG)", "typical", "Intermediate betaine-homocysteine flux.", "Standard diet."),
        G("Altered BHMT (GG)", "notable", "Altered betaine utilization.",
          "Higher reliance on folate-dependent MTHFR/MTR pathway if betaine/choline intake is low.",
          eat=["Incorporate dietary betaine (beets, quinoa, spinach, wheat bran) to support liver remethylation."]),
    )

    add(
        "rs1979277", "SHMT1", "Serine Hydroxymethyltransferase (C1420T)", "17", 18274351,
        ["nutrition", "methylation"], "moderate", "C", "T",
        "SHMT1 directs 1-carbon units between folate-mediated thymidylate synthesis (DNA repair) and homocysteine remethylation.",
        G("Typical (CC)", "typical", "Standard SHMT1 partitioning.", "Normal DNA synthesis and methylation balance."),
        G("Heterozygote (CT)", "typical", "Intermediate 1-carbon flux.", "Standard diet."),
        G("Altered Partitioning (TT)", "notable", "Shifts folate allocation toward DNA synthesis.",
          "Can slightly lower available 5,10-methyleneTHF for methylation under low-folate conditions.",
          eat=["Maintain high intake of leafy vegetables and natural folates."]),
    )

    add(
        "rs1074810", "SLC44A1", "Choline Transporter-Like Protein 1 (CTL1)", "9", 107952924,
        ["nutrition", "methylation", "cognition"], "moderate", "A", "G",
        "SLC44A1 transports choline across cell membranes and into mitochondria for betaine synthesis.",
        G("Typical Transport (AA)", "typical", "Standard cellular choline uptake.", "Dietary baseline."),
        G("Heterozygote (AG)", "typical", "Mild reduction in transport velocity.", "Ensure adequate choline intake."),
        G("Reduced Choline Transport (GG)", "notable", "Decreased cellular choline uptake capacity.",
          "Increases dietary choline dependency for cognitive acetylcholine and hepatic phospholipid synthesis.",
          eat=["Prioritize bioavailable dietary choline (egg yolks, liver, fish) throughout the day."]),
    )

    # --- 2.0 expansion: one-carbon cofactor and choline axis ---
    add(
        "rs2236225", "MTHFD1", "Formate Shuttle (G1958A / R653Q)", "14", 64908332,
        ["nutrition", "methylation", "vitamins"], "strong", "G", "A",
        "MTHFD1 interconverts one-carbon folate species. The 653Gln allele destabilizes the synthetase domain, raising dependence on dietary choline and folate, with replicated associations to choline-related outcomes under depletion.",
        G("Typical formate shuttle (GG)", "typical", "Standard folate interconversion.", "Standard dietary needs."),
        G("One 653Gln copy (AG)", "typical", "Mildly reduced synthetase stability.", "Adequate folate plus choline covers the difference.",
          eat=["Keep egg/choline intake regular alongside folate-rich greens."]),
        G("Higher choline reliance (AA)", "notable", "Destabilized synthetase domain.", "Under low-choline, low-folate conditions this genotype showed higher susceptibility to depletion effects in feeding studies.",
          eat=["Treat choline as a first-class nutrient: eggs, fish, or lecithin most days."]),
        tier="replicated", effect="Moderate under nutrient depletion; silent with replete diet",
        citations=[C(GWAS, "MTHFD1 R653Q choline-depletion and NTD literature (Brody 2002; Kohlmeier 2005)")],
    )
    add(
        "rs1051266", "SLC19A1 (RFC1)", "Reduced Folate Carrier (G80A)", "21", 46957794,
        ["nutrition", "methylation", "vitamins"], "moderate", "G", "A",
        "RFC1 imports 5-MTHF into cells. G80A modestly shifts folate transport efficiency; homozygotes show small differences in red-cell folate in some cohorts.",
        G("Reference transport (GG)", "typical", "Typical folate import.", "Standard dietary folate suffices."),
        G("Intermediate (AG)", "typical", "Mild transport shift.", "No action needed beyond normal folate intake."),
        G("Variant pair (AA)", "typical", "Small folate-transport shift.", "Keep folate intake consistent; effect is small and diet-dominated.",
          eat=["Regular leafy greens and legumes cover this genotype comfortably."]),
        tier="replicated", effect="Small shifts in folate indices",
        citations=[C(GWAS, "SLC19A1 G80A folate-status studies")],
    )
    add(
        "rs202676", "FOLH1", "Folate Hydrolase (Dietary Folate Release)", "11", 49216760,
        ["nutrition", "methylation"], "moderate", "A", "G",
        "FOLH1 (glutamate carboxypeptidase II) cleaves dietary polyglutamate folates for absorption. The G allele has been associated with altered folate/homocysteine indices in small cohorts.",
        G("Reference (AA)", "typical", "Typical polyglutamate folate release.", "Standard absorption."),
        G("One copy (AG)", "typical", "Possible small absorption shift.", "Diet quality dominates."),
        G("Two copies (GG)", "typical", "Small association with folate indices.", "Evidence is modest; food folate variety is the answer either way."),
        tier="tendency", effect="Small, cohort-dependent",
        citations=[C(GWAS, "FOLH1 folate absorption studies — limited cohorts")],
    )
    add(
        "rs12676", "CHDH", "Choline Dehydrogenase (Betaine Supply)", "3", 53850055,
        ["nutrition", "methylation"], "moderate", "G", "T",
        "CHDH oxidizes choline to betaine, feeding the BHMT remethylation path. The T allele associates with altered susceptibility to choline depletion in feeding studies.",
        G("Reference (GG)", "typical", "Typical choline-to-betaine flux.", "Standard choline needs."),
        G("One copy (GT)", "typical", "Mild flux shift.", "Regular dietary choline covers it."),
        G("Two copies (TT)", "notable", "Higher sensitivity to low choline in depletion studies.", "Another push toward taking dietary choline seriously.",
          eat=["Anchor choline with eggs, fish, or liver weekly; betaine from beets/spinach supports the same pathway."]),
        tier="replicated", effect="Visible under depletion protocols; silent when replete",
        citations=[C(GWAS, "CHDH choline-depletion studies (da Costa 2006)")],
    )
    add(
        "rs12325817", "PEMT", "PEMT Promoter (Choline Requirement)", "17", 17505990,
        ["nutrition", "methylation"], "strong", "G", "C",
        "Second PEMT signal: promoter-region variant strongly associated with developing organ dysfunction under choline depletion in controlled feeding studies, especially in women.",
        G("Reference (GG)", "typical", "Typical endogenous phosphatidylcholine synthesis.", "Standard choline needs."),
        G("One copy (CG)", "notable", "Higher choline requirement tendency.", "In depletion studies, carriers developed dysfunction at higher rates.",
          eat=["Deliberate choline intake (eggs, fish, lecithin) is cheap insurance."]),
        G("Two copies (CC)", "notable", "Highest depletion susceptibility in feeding studies.", "Dietary choline is non-optional for this genotype.",
          eat=["Target consistent choline-rich foods daily; especially relevant for pregnancy planning (discuss with a clinician)."]),
        notes="Palindromic G/C pair — orientation reviewed against study allele frequencies.",
        tier="replicated", effect="Strong under depletion; modest day-to-day", reviewed=True,
        citations=[C(16816108, "da Costa 2006 / Zeisel lab — PEMT promoter and choline requirement")],
    )
    add(
        "rs2424913", "DNMT3B", "DNA Methyltransferase 3B Promoter (-579G>T)", "20", 31350190,
        ["methylation", "cellular"], "moderate", "C", "T",
        "DNMT3B establishes de-novo DNA methylation. This promoter variant has been studied for altered promoter activity; disease associations are heterogeneous — carried at tendency tier.",
        G("Reference (CC)", "typical", "Typical promoter activity.", "Global methylation is dominated by nutrition and age."),
        G("One copy (CT)", "typical", "Possible small promoter-activity shift.", "No individual-level implication."),
        G("Two copies (TT)", "typical", "In-vitro promoter-activity difference.", "Population studies are inconsistent; treated strictly as background information."),
        tier="tendency", effect="In-vitro promoter effect; inconsistent clinical associations",
        citations=[C(GWAS, "DNMT3B -579G>T promoter studies — heterogeneous")],
    )
    add(
        "rs1550117", "DNMT3A", "DNA Methyltransferase 3A Promoter (-448A>G)", "2", 25475882,
        ["methylation", "cellular"], "moderate", "G", "A",
        "Promoter variant of the de-novo methyltransferase DNMT3A studied for expression differences; association literature is mixed.",
        G("Reference (GG)", "typical", "Typical expression.", "Background information only."),
        G("One copy (AG)", "typical", "Possible small expression shift.", "No action implied."),
        G("Two copies (AA)", "typical", "Reported expression difference in some studies.", "Tendency-tier background only."),
        tier="tendency", effect="Mixed literature",
        citations=[C(GWAS, "DNMT3A promoter variant studies — heterogeneous")],
    )
    add(
        "rs234709", "CBS", "CBS Regulatory Variant (Transsulfuration Support)", "21", 44478192,
        ["nutrition", "methylation", "detox"], "moderate", "C", "T",
        "Second CBS signal associated with homocysteine level shifts in population studies, complementing C699T for reading transsulfuration flux.",
        G("Reference (CC)", "typical", "Typical CBS regulatory baseline.", "Standard sulfur amino-acid handling."),
        G("One copy (CT)", "typical", "Small flux shift.", "Diet dominates."),
        G("Two copies (TT)", "typical", "Small homocysteine association in cohorts.", "B6 sufficiency (poultry, potatoes, bananas) supports CBS either way."),
        tier="tendency", effect="Small homocysteine shifts",
        citations=[C(GWAS, "CBS regulatory-variant homocysteine studies")],
    )
    add(
        "rs2287780", "MTRR", "MTRR Secondary Variant (Remethylation Support)", "5", 7885959,
        ["nutrition", "methylation", "vitamins"], "moderate", "C", "T",
        "Secondary MTRR coding variant appearing in homocysteine/NTD association studies alongside A66G.",
        G("Reference (CC)", "typical", "Typical MTRR support.", "Standard B12 needs."),
        G("One copy (CT)", "typical", "Minor shift.", "Adequate B12 covers it."),
        G("Two copies (TT)", "typical", "Small homocysteine association.", "Keep active B12 intake consistent.",
          eat=["Bioavailable B12 (fish, eggs, dairy or methylcobalamin if plant-based)."]),
        tier="tendency", effect="Small",
        citations=[C(GWAS, "MTRR variant homocysteine/NTD studies")],
    )
    add(
        "rs1802059", "MTRR", "MTRR A664A Regulatory Site", "5", 7923973,
        ["nutrition", "methylation"], "moderate", "G", "A",
        "Synonymous MTRR site associated in some cohorts with homocysteine differences, likely via haplotype effects with A66G.",
        G("Reference (GG)", "typical", "Typical haplotype.", "Standard needs."),
        G("One copy (AG)", "typical", "Haplotype-support shift.", "Interpret with rs1801394."),
        G("Two copies (AA)", "typical", "Small cohort-level association.", "Interpret with rs1801394; B12 sufficiency is the lever."),
        tier="tendency", effect="Haplotype-support role",
        citations=[C(GWAS, "MTRR haplotype homocysteine studies")],
    )
    add(
        "rs6495446", "MTHFS", "5,10-Methenyl-THF Synthetase", "15", 80137316,
        ["nutrition", "methylation"], "moderate", "C", "T",
        "MTHFS governs folate turnover through the futile cycle of 5-formyl-THF. Variants associate with homocysteine shifts in population studies.",
        G("Reference (CC)", "typical", "Typical folate turnover.", "Standard needs."),
        G("One copy (CT)", "typical", "Small shift.", "Diet dominates."),
        G("Two copies (TT)", "typical", "Small homocysteine association.", "Food folate variety covers this comfortably."),
        tier="tendency", effect="Small",
        citations=[C(GWAS, "MTHFS homocysteine association studies")],
    )
    add(
        "rs2274976", "MTHFR", "MTHFR Distal Variant (G1793A / R594Q)", "1", 11850927,
        ["nutrition", "methylation"], "moderate", "G", "A",
        "Distal MTHFR coding variant occasionally co-inherited with C677T; small independent effect on enzyme function.",
        G("Reference (GG)", "typical", "No distal variant.", "Interpret MTHFR via C677T/A1298C."),
        G("One copy (AG)", "typical", "Minor haplotype note.", "Small effect; read alongside C677T."),
        G("Two copies (AA)", "typical", "Rare homozygote.", "Small functional shift; folate/riboflavin sufficiency remains the lever."),
        tier="tendency", effect="Small adjunct to C677T",
        citations=[C(GWAS, "MTHFR G1793A population studies")],
    )
