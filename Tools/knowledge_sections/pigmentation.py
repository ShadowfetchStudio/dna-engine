"""Pigmentation — eyes, hair, skin, UV response. Curated chip-callable markers.

Pigmentation genetics is the honesty showcase: a handful of loci really are
near-Mendelian in Europeans (HERC2, MC1R), yet the same predictions degrade
sharply in other ancestries because discovery cohorts were European. The
transferability tags below say so explicitly.
"""
from .common import G, C, CHIPS_ALL, PGKB, GWAS, CLIN, CPIC


def register(add):
    add(
        "rs1800407", "OCA2", "Eye Color Modifier (R419Q, green/hazel push)", "15", 28230318,
        ["traits", "pigmentation"], "strong", "C", "T",
        "OCA2 Arg419Gln is the second-strongest common eye-color locus after the HERC2 switch: the T (419Gln) allele pushes HERC2-blue backgrounds toward green/hazel and increases iris heterogeneity.",
        G("No modifier (CC)", "typical", "Eye color follows the HERC2 genotype more directly.", "Typical OCA2 coding function."),
        G("One 419Gln copy (CT)", "typical", "Green/hazel push on light backgrounds.", "On a HERC2 GG (blue) background this allele raises the odds of green or hazel."),
        G("Two 419Gln copies (TT)", "typical", "Stronger green/hazel modifier.", "Rare; strongest single-locus push toward green iris color."),
        tier="well-replicated", effect="Explains a large share of green/hazel vs blue beyond HERC2 in Europeans",
        transferability="euro-biased",
        citations=[C(17236130, "Duffy 2007, Am J Hum Genet — OCA2 haplotypes and eye color"),
                   C(GWAS, "IrisPlex model component (Walsh/Kayser forensic validation)")],
    )
    add(
        "rs1805008", "MC1R", "Red Hair / UV Sensitivity (R160W, 'R' allele)", "16", 89986144,
        ["traits", "pigmentation"], "strong", "C", "T",
        "MC1R switches melanocytes between dark eumelanin and red-yellow pheomelanin. R160W is one of the three major loss-of-function 'R' alleles: two R alleles usually mean red hair, fair skin, and poor tanning; one R allele means freckling and higher UV sensitivity.",
        G("No R160W (CC)", "typical", "No loss-of-function at this MC1R site.", "Other MC1R alleles can still contribute — see the MC1R compound card."),
        G("One R allele (CT)", "notable", "Carrier: fairer skin, freckling, higher burn tendency.", "Melanoma risk runs modestly higher for R carriers even without red hair — sun protection has outsized value.",
          recover=["Treat sunscreen and UV-index awareness as non-negotiable; annual skin checks are cheap insurance."]),
        G("Two R alleles at this site (TT)", "caution", "Strong pheomelanin shift.", "Red hair and very fair, burn-prone skin are highly likely; melanoma and photoaging risk are elevated. This is a UV-behavior finding, not a disease diagnosis.",
          recover=["High-SPF habits, UV clothing, and dermatology skin checks; vitamin D via diet/supplement rather than burning exposure."]),
        tier="well-replicated", effect="Per R allele: red hair OR ~6-10; melanoma OR ~1.4-2 — strong for a common variant",
        transferability="euro-biased",
        citations=[C(7581459, "Valverde 1995, Nat Genet — MC1R variants, red hair and fair skin"),
                   C(GWAS, "MC1R melanoma meta-analyses")],
    )
    add(
        "rs1805009", "MC1R", "Red Hair / UV Sensitivity (D294H, 'R' allele)", "16", 89986546,
        ["traits", "pigmentation"], "strong", "G", "C",
        "D294H is the third major MC1R loss-of-function 'R' allele alongside R151C and R160W, with the same pheomelanin shift.",
        G("No D294H (GG)", "typical", "No loss-of-function at this site.", "See the MC1R compound card for the combined R-allele load."),
        G("One R allele (CG)", "notable", "Carrier-level UV sensitivity contribution.", "Adds to the total MC1R R load — freckling and burn tendency.",
          recover=["Consistent sun protection pays off disproportionately for R-allele carriers."]),
        G("Two R alleles at this site (CC)", "caution", "Strong pheomelanin shift at this site alone.", "Red hair and burn-prone skin highly likely; prioritize UV protection.",
          recover=["High-SPF habits and dermatology skin checks."]),
        notes="Palindromic G/C site — orientation reviewed against European R-allele frequencies.",
        tier="well-replicated", effect="Per R allele: red hair OR ~6-10 — strong", transferability="euro-biased",
        reviewed=True,
        citations=[C(7581459, "Valverde 1995, Nat Genet — MC1R variants and red hair")],
    )
    add(
        "rs1805005", "MC1R", "MC1R Minor Variant (V60L, 'r' allele)", "16", 89985844,
        ["traits", "pigmentation"], "moderate", "G", "T",
        "V60L is a partial-function 'r' allele: a weaker pheomelanin shift associated with strawberry-blond tones and modest UV sensitivity rather than full red hair.",
        G("No V60L (GG)", "typical", "No partial-function allele at this site.", "Typical eumelanin signaling here."),
        G("One r allele (GT)", "typical", "Mild pheomelanin shift.", "Slightly fairer sun response; contributes to the compound MC1R load."),
        G("Two r alleles (TT)", "notable", "Noticeable fair-skin tendency without full red hair.", "Often lighter hair tones and easier burning; sun protection worth taking seriously.",
          recover=["Mind the UV index; the tan you can't build is protection you must apply."]),
        tier="replicated", effect="Weaker than R alleles: red hair OR ~1.5-2 per allele", transferability="euro-biased",
        citations=[C(GWAS, "MC1R r-allele classification literature (Beaumont 2007; Duffy 2004)")],
    )
    add(
        "rs11547464", "MC1R", "Red Hair / UV Sensitivity (R142H, 'R' allele)", "16", 89986091,
        ["traits", "pigmentation"], "moderate", "G", "A",
        "R142H is a rarer major-loss 'R' allele of MC1R with the same strong pheomelanin shift as R151C/R160W/D294H.",
        G("No R142H (GG)", "typical", "No loss-of-function at this site.", "See the compound MC1R card."),
        G("One R allele (AG)", "notable", "Carrier-level contribution to the R load.", "Freckling and burn tendency contribution.",
          recover=["Sun protection habits matter more for you than for the average person."]),
        G("Two R alleles (AA)", "caution", "Strong pheomelanin shift.", "Red hair/fair skin highly likely; elevated UV damage risk.",
          recover=["UV protection plus dermatology skin checks."]),
        tier="replicated", effect="Rare allele, strong per-copy effect", transferability="euro-biased",
        citations=[C(GWAS, "MC1R R-allele functional classification (Beaumont 2007)")],
    )
    add(
        "rs885479", "MC1R", "MC1R R163Q (East-Asian common variant)", "16", 89986154,
        ["traits", "pigmentation"], "moderate", "G", "A",
        "R163Q is common in East Asia and has only a weak effect on pigmentation — a useful counter-example: not every MC1R coding variant is a red-hair allele.",
        G("No R163Q (GG)", "typical", "Reference at this site.", "Typical signaling."),
        G("One copy (AG)", "typical", "Weak effect.", "Minimal pigmentation shift; not an 'R' allele."),
        G("Two copies (AA)", "typical", "Common in East-Asian ancestry.", "Weak or no measurable pigmentation effect in most studies."),
        tier="replicated", effect="Weak — included to prevent over-reading MC1R variation",
        transferability="east-asian-derived",
        citations=[C(GWAS, "MC1R R163Q population-genetics literature")],
    )
    add(
        "rs1393350", "TYR", "Tyrosinase Eye/Freckle Modifier", "11", 89011046,
        ["traits", "pigmentation"], "strong", "G", "A",
        "Tyrosinase is the rate-limiting melanin enzyme. This intronic variant associates with blue eyes and freckling in Icelandic and replication cohorts, and with vitiligo susceptibility in immunity GWAS.",
        G("Reference (GG)", "typical", "Typical tyrosinase contribution.", "Eye color driven mainly by HERC2/OCA2."),
        G("One copy (AG)", "typical", "Small light-pigment push.", "Adds slightly to blue-eye and freckling odds."),
        G("Two copies (AA)", "typical", "Light-pigment modifier homozygote.", "Modest additional light-eye/freckle tendency."),
        tier="well-replicated", effect="Modest modifier beyond HERC2", transferability="euro-biased",
        citations=[C(17952075, "Sulem 2007, Nat Genet — TYR and pigmentation traits")],
    )
    add(
        "rs12896399", "SLC24A4", "Hair & Eye Shade Modifier (14q32)", "14", 92773663,
        ["traits", "pigmentation", "hair"], "strong", "G", "T",
        "SLC24A4 encodes a cation exchanger active in melanocytes; this variant contributes to the blond-vs-brown and blue-vs-green axes in European cohorts and is part of forensic HIrisPlex models.",
        G("Light-leaning (TT)", "typical", "Two light-shade alleles.", "Higher odds of lighter hair/eyes on a European background."),
        G("Intermediate (GT)", "typical", "One copy.", "Intermediate shade contribution."),
        G("Dark-leaning (GG)", "typical", "Reference.", "Darker-shade contribution at this locus."),
        tier="well-replicated", effect="Modest modifier used in forensic prediction panels",
        transferability="euro-biased",
        citations=[C(17952075, "Sulem 2007, Nat Genet — SLC24A4"), C(GWAS, "HIrisPlex validation studies")],
    )
    add(
        "rs12203592", "IRF4", "Freckling, Hair Shade & Sun Sensitivity", "6", 396321,
        ["traits", "pigmentation", "hair"], "strong", "C", "T",
        "IRF4 cooperates with MITF in melanocytes. The T allele associates with freckling, lighter hair, blue eyes, and poor tanning; it is one of the strongest freckling loci known.",
        G("Reference (CC)", "typical", "Typical IRF4 enhancer activity.", "Freckling driven mainly by MC1R."),
        G("One copy (CT)", "typical", "Higher freckling/sun-sensitivity odds.", "Modest fair-phenotype push."),
        G("Two copies (TT)", "notable", "Strong freckling and pale-tanning tendency.", "Treat UV protection seriously; freckling here is a marker of sun response, not a health problem.",
          recover=["Daily SPF on face/hands is the cheapest anti-photoaging tool available."]),
        tier="well-replicated", effect="One of the strongest freckling loci — moderate",
        transferability="euro-biased",
        citations=[C(GWAS, "IRF4 rs12203592 pigmentation associations (Sulem 2007; Han 2008)")],
    )
    add(
        "rs12821256", "KITLG", "Blond Hair Enhancer Variant (12q21)", "12", 89328335,
        ["traits", "pigmentation", "hair"], "strong", "T", "C",
        "A regulatory variant ~350 kb upstream of KITLG that lowers its expression in hair follicles — one of the best-understood blond-hair alleles, validated in mouse enhancer experiments.",
        G("Reference (TT)", "typical", "Typical KITLG expression.", "Darker-hair contribution at this locus."),
        G("One blond allele (CT)", "typical", "Modest lightening contribution.", "Blond odds rise modestly."),
        G("Two blond alleles (CC)", "typical", "Strong Northern-European blond signature.", "High blond-hair odds on European backgrounds."),
        tier="well-replicated", effect="OR ~2 per allele for blond hair in Northern Europeans",
        transferability="euro-biased",
        citations=[C(24887549, "Guenther 2014, Nat Genet — KITLG blond-hair enhancer mechanism"),
                   C(17952075, "Sulem 2007 — discovery")],
    )
    add(
        "rs1426654", "SLC24A5", "Skin Tone Major Locus (A111T)", "15", 48426484,
        ["traits", "pigmentation"], "strong", "A", "G",
        "The single largest known contributor to the European-African skin-tone difference (~25-38% of the difference). The A (Thr111) allele reduces melanosome cargo and is essentially fixed in Europe.",
        G("Light-skin allele pair (AA)", "typical", "Fixed-in-Europe light-pigment genotype.", "Typical for European and much of South-Asian ancestry."),
        G("Heterozygous (AG)", "typical", "Intermediate melanin index contribution.", "Common in admixed and South-Asian ancestries."),
        G("Ancestral pair (GG)", "typical", "Ancestral higher-melanin genotype.", "Typical for African and East-Asian ancestry (East-Asian skin lightening evolved via different loci — convergent evolution)."),
        tier="well-replicated", effect="Explains ~25-38% of the Eur-Afr melanin-index difference — exceptional",
        transferability="multi-ancestry",
        citations=[C(16357253, "Lamason 2005, Science — SLC24A5 golden zebrafish orthologue")],
    )
    add(
        "rs16891982", "SLC45A2", "Skin & Hair Lightening (L374F)", "5", 33951693,
        ["traits", "pigmentation"], "strong", "G", "C",
        "SLC45A2 (MATP) transports melanosome precursors. The G (374Phe→Leu... reference numbering: G=Leu374) allele is near-fixed in Europe and strongly lightens skin and hair.",
        G("European-typical (GG)", "typical", "Light-pigment genotype.", "Near-fixed in European ancestry."),
        G("Heterozygous (CG)", "typical", "Intermediate contribution.", "Common in Middle-Eastern, South-Asian, and admixed backgrounds."),
        G("Ancestral (CC)", "typical", "Higher-melanin genotype.", "Typical outside Europe."),
        notes="Palindromic G/C site — orientation reviewed against continental frequency profile.",
        tier="well-replicated", effect="Strong pigmentation locus, second only to SLC24A5 in Europeans",
        transferability="multi-ancestry", reviewed=True,
        citations=[C(GWAS, "SLC45A2 L374F pigmentation literature (Graf 2005; Soejima 2007)")],
    )
    add(
        "rs1042602", "TYR", "Tyrosinase S192Y (skin/eye modifier)", "11", 88911696,
        ["traits", "pigmentation"], "strong", "C", "A",
        "S192Y reduces tyrosinase activity ~40% in vitro; the A (Tyr) allele is common in Europe and contributes to lighter skin and eye shades.",
        G("Reference (CC)", "typical", "Full tyrosinase activity at this site.", "Typical melanin synthesis."),
        G("One 192Tyr copy (AC)", "typical", "Modest activity reduction.", "Small light-pigment contribution."),
        G("Two 192Tyr copies (AA)", "typical", "Reduced tyrosinase activity.", "Light-pigment contribution; also appears in vitiligo association studies."),
        tier="well-replicated", effect="Modest per-allele lightening; ~40% in-vitro activity drop",
        transferability="euro-biased",
        citations=[C(GWAS, "TYR S192Y functional + association literature")],
    )
    add(
        "rs1408799", "TYRP1", "TYRP1 Eye-Shade Modifier", "9", 12672097,
        ["traits", "pigmentation"], "moderate", "T", "C",
        "TYRP1 stabilizes tyrosinase and shifts eumelanin subtype. This upstream variant modifies blue-vs-brown odds modestly in European cohorts.",
        G("Light-leaning (TT)", "typical", "Two light-shade alleles.", "Small blue-eye push."),
        G("Intermediate (CT)", "typical", "One copy.", "Intermediate."),
        G("Dark-leaning (CC)", "typical", "Reference.", "Small brown push."),
        tier="replicated", effect="Small modifier", transferability="euro-biased",
        citations=[C(GWAS, "TYRP1 eye-color modifier studies (Sulem 2008)")],
    )
    add(
        "rs4959270", "EXOC2 region", "Hair Shade Signal (6p25, HIrisPlex)", "6", 457748,
        ["traits", "pigmentation", "hair"], "moderate", "C", "A",
        "6p25 hair-color signal near EXOC2/IRF4 used in the HIrisPlex forensic hair-color model; the A allele associates with lighter (blond-leaning) hair.",
        G("Light-leaning (AA)", "typical", "Two light-hair alleles.", "Modest blond push."),
        G("Intermediate (AC)", "typical", "One copy.", "Intermediate."),
        G("Dark-leaning (CC)", "typical", "Reference.", "Modest dark push."),
        tier="replicated", effect="Modest, forensic-model component", transferability="euro-biased",
        citations=[C(GWAS, "HIrisPlex hair-color model SNP set (Walsh 2013)")],
    )
    add(
        "rs683", "TYRP1", "TYRP1 3'UTR Hair/Eye Modifier (HIrisPlex)", "9", 12709305,
        ["traits", "pigmentation", "hair"], "moderate", "C", "A",
        "TYRP1 3' variant included in forensic pigmentation panels; modest hair- and eye-shade contribution, with a notable blond association in Solomon Islands populations via a different TYRP1 missense allele nearby (a reminder that 'blond' evolved more than once).",
        G("One shade pole (CC)", "typical", "Reference pair.", "Modest contribution."),
        G("Intermediate (AC)", "typical", "One copy.", "Intermediate."),
        G("Other shade pole (AA)", "typical", "Alternate pair.", "Modest contribution."),
        tier="replicated", effect="Small forensic-panel contribution", transferability="euro-biased",
        citations=[C(GWAS, "HIrisPlex SNP set; TYRP1 pigment literature")],
    )
    add(
        "rs28777", "SLC45A2", "SLC45A2 Secondary Signal (HIrisPlex)", "5", 33958959,
        ["traits", "pigmentation"], "moderate", "C", "A",
        "Secondary SLC45A2 signal used in forensic prediction models alongside L374F.",
        G("Light-associated (CC)", "typical", "European-common pair.", "Adds slightly to the main L374F signal."),
        G("Intermediate (AC)", "typical", "One copy.", "Intermediate."),
        G("Ancestral (AA)", "typical", "Ancestral pair.", "Higher-melanin contribution."),
        tier="replicated", effect="Small, LD-supported", transferability="euro-biased",
        citations=[C(GWAS, "HIrisPlex validation studies (Walsh 2013)")],
    )
    add(
        "rs1800414", "OCA2", "East-Asian Skin Lightening (His615Arg)", "15", 28197037,
        ["traits", "pigmentation"], "strong", "T", "C",
        "The East-Asian skin-lightening path ran through OCA2 His615Arg rather than SLC24A5 — convergent evolution toward lighter skin using a different gene. The C (Arg) allele is common only in East Asia.",
        G("Ancestral (TT)", "typical", "No East-Asian lightening allele.", "Typical outside East Asia."),
        G("One copy (CT)", "typical", "Intermediate melanin-index effect.", "Common in East-Asian and admixed backgrounds."),
        G("Two copies (CC)", "typical", "East-Asian light-skin genotype.", "Substantial melanin-index reduction; near-absent elsewhere."),
        tier="well-replicated", effect="Explains a meaningful share of East-Asian skin-tone variance",
        transferability="east-asian-derived",
        citations=[C(GWAS, "OCA2 His615Arg East-Asian pigmentation studies (Edwards 2010; Yang 2016)")],
    )
    add(
        "rs4778241", "OCA2 region", "Eye Shade Haplotype Support (15q13)", "15", 28338713,
        ["traits", "pigmentation"], "moderate", "C", "A",
        "OCA2-region haplotype SNP supporting the HERC2/OCA2 eye-color axis; used in multi-SNP eye-color models.",
        G("Light-associated (CC)", "typical", "Supports the light-iris haplotype.", "Adds context to the main HERC2 switch."),
        G("Intermediate (AC)", "typical", "One copy.", "Intermediate."),
        G("Dark-associated (AA)", "typical", "Supports the dark-iris haplotype.", "Adds context to HERC2."),
        tier="replicated", effect="Haplotype-support role", transferability="euro-biased",
        citations=[C(GWAS, "OCA2/HERC2 haplotype eye-color models (Liu 2009)")],
    )
    add(
        "rs2228479", "MC1R", "MC1R V92M (weak 'r' allele)", "16", 89985940,
        ["traits", "pigmentation"], "moderate", "G", "A",
        "V92M is a weak partial-function MC1R allele: small effect on pigmentation and a slight melanoma-risk contribution, far below the R alleles.",
        G("No V92M (GG)", "typical", "Reference at this site.", "Typical signaling."),
        G("One copy (AG)", "typical", "Very small fair-skin push.", "Counts weakly toward the MC1R compound load."),
        G("Two copies (AA)", "typical", "Weak partial-function pair.", "Small fair-skin tendency."),
        tier="replicated", effect="Weak r allele — small", transferability="multi-ancestry",
        citations=[C(GWAS, "MC1R V92M functional classification")],
    )
