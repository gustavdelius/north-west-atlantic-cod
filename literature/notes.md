# Literature notes: eastern Scotian Shelf cod, forage fish and size-spectrum modelling

Compiled 2026-11-13. One block per entry in `paper/references.bib`, grouped by theme,
using the same keys. Numbers come with a pointer to where they appear.

**How each source was read.** Every block ends with a tag:

- **[abs]** I read the abstract myself. It came from the Crossref record, PubMed,
  OpenAlex or the publisher's page. Numbers attributed to the abstract were read there.
- **[full]** Full text, or substantial parts of it, were read. For DFO/CSAS documents
  this was done by a delegated search agent that opened the PDFs. Its page pointers are
  reproduced here; I did not re-open those PDFs myself.
- **[meta]** Only the bibliographic record was checked. Content statements are
  **second-hand**: my background knowledge or the citing literature. They are flagged
  "(second-hand)" and must be checked before they are relied on in the paper.

Summaries are in my own words.

---

## 0. The single most important finding

### adekoya2026reexamining (+ adekoya2026code)
Adekoya, Tittensor, Boyce, Fulton & Blanchard 2026, *ICES J. Mar. Sci.* 83(10): fsag195.
Received 28 Nov 2025, accepted 28 Aug 2026, published 6 Oct 2026, open access.

**What it is.** A 19-species **mizer** model of the eastern Scotian Shelf, 1978–2024.
- Species: cod, haddock, pollock, redfish, American plaice, yellowtail, witch flounder,
  thorny and winter skate, monkfish, white hake, spiny dogfish, Atlantic halibut, silver
  hake, red hake, herring, sand lance, capelin and longhorn sculpin.
- Grey-seal predation is an external mortality applied like a "gear". It is
  size-selective on fish under about 40 cm (selectivity from Bowen & Harrison 1994) and
  scales with a normalised seal index digitised from Hammill & Stenson (2000) and
  extrapolated logistically.
- Two scenarios are compared: a factual run with rising seals and a counterfactual with
  seals held at 1978–81 levels. Each uses 1,000 food webs in which interaction
  coefficients are perturbed with lognormal noise (SD 0.1).
- Calibrated to 1978–81 steady state, then to DFO summer-survey biomass for strata
  443–466. Catches come from NAFO 21A/B, with effort in kW-days and four gears.

**Results.**
- Both scenarios reproduce cod non-recovery; the factual run fits better.
- The marginal seal effect on cod weakens as forage-fish predation on small cod (the
  herring→cod and sand lance→cod coefficients) increases. The authors call this
  consistent with cultivation–depensation. The effect is reported only qualitatively.
- Forage-fish maximum recruitment had to be raised about eight-fold to match observations.

**What it does not do.** No alternative stable states, hysteresis analysis or
forage-fishing scenarios; the authors list factorial forcing scenarios as future work.

**Code and data.** At github.com/Ezekiel-Adekoya/ESS_Restructured, with no licence file.
It includes q-adjusted ESS survey biomass at length for 1970–2022 and a mizer
species-parameter table built from FishBase.

**Implication.** This is the direct predecessor of our paper. We must cite it, differ
from it explicitly (bistability, hysteresis, forage-fishing intervention, mechanism), and
ideally reconcile parameter choices with it.

[abs + full: the abstract was read via Crossref; the methods and results were read
through two fetches of the OUP HTML page (first 100k characters of 171k), and the
GitHub repository was inspected through the GitHub API.]

---

## 1. Cod collapses and non-recovery in the Northwest Atlantic

### hutchings1994what
Hutchings & Myers 1994, CJFAS 51: 2126–2146.
- Overexploitation alone explains the northern cod collapse in 1992.
- Annual survival probabilities halved in the 1980s as fishing effort rose and shifted
  offshore.
- Temperature and salinity hypotheses are rejected, and the stock was rarely sustainable
  at survival and fecundity rates seen since 1962.

[abs]

### hutchings1996spatial
Hutchings 1996, CJFAS 53: 943–962.
- Spatial contraction and hyperaggregation of northern cod meant catch rates stayed high
  while biomass fell.
- The review of hypotheses concludes that very high fishing mortality was the only
  important cause of the collapse.

[abs (French version, via OpenAlex)]

### myers1995population
Myers, Barrowman, Hutchings & Rosenberg 1995, *Science* 269: 1106–1108.
- Only 3 of 128 spawner–recruit series showed significant depensation.
- The power analysis supports the conclusion that depensation is not apparent at the
  stock sizes observed.
- This is the classic counterpoint to Allee and cultivation arguments.

[abs]

### myers1996hypotheses
Myers, Hutchings & Barrowman 1996, MEPS 138: 293–308.
- 20 North Atlantic cod stocks. Collapses were not preceded by poor juvenile survival.
- F rose as stocks fell; overfishing caused the declines.

[abs]

### myers1997why
Myers, Hutchings & Barrowman 1997, *Ecol. Appl.* 7: 91–106.
- Six Canadian cod stocks were under moratorium in 1993.
- No detectable fall in recruitment of the year classes that formed the collapsing
  spawning stocks; power to detect a 20% decline was high.
- VPA and survey trends diverge; the authors suggest discarding and misreporting.

[abs]

### hutchings2000collapse
Hutchings 2000, *Nature* 406: 882–885.
- 90 stocks. Gadids show little or no recovery up to 15 years after 45–99% declines in
  spawning biomass.
- Clupeids recover faster, which is relevant to the asymmetry between cod and forage fish.

[abs]

### hutchings2004marine
Hutchings & Reynolds 2004, *BioScience* 54: 297–309.
- More than 230 populations, with a median 83% decline from historic levels.
- Few recover within 15 years; a Canadian cod population declined up to 99.9% over 30
  years.
- Pages corrected from the publisher page; Crossref gives only "297".

[abs (OUP page)]

### hutchings2005life
Hutchings 2005, CJFAS 62: 824–832.
- Earlier maturity (age 6 to 4) can reduce cod population growth by 25–30% in a
  life-history model.
- It also more than doubles the probability of negative growth per generation.

[abs]

### shelton2006fishing
Shelton, Sinclair, Chouinard, Mohn & Duplisea 2006, CJFAS 63: 235–238.
- 12 NW Atlantic cod stocks. Low productivity was ranked: increased M first, then reduced
  growth, then (sometimes) recruitment.
- With continued directed and bycatch fishing, 8 stocks had growth ≤2%/yr.
- With no fishing, 6 stocks would grow >5%/yr and 4 of those >10%/yr. Fishing is
  therefore still delaying recovery; this is the bycatch argument.

[abs]

### rose2004reconciling
Rose 2004, CJFAS 61: 1553–1557.
- A surplus-production reconstruction of Newfoundland cod, 1505–2004.
- Only a model with both climate forcing and depensation reproduced the history.

[abs]

### rose2002capelin
Rose & O'Driscoll 2002, *ICES J. Mar. Sci.* 59: 1018–1026.
- Of 3,383 northern cod stomachs, only 0.2% contained capelin.
- Cod condition (liver index) tracked capelin availability (p<0.05), and liver index
  correlated with gonad size.
- Conclusion: rebuilding needs capelin.
- Crossref lists only Rose; the second author was confirmed on the OUP page.

[abs]

### rose2015northern
Rose & Rowe 2015, CJFAS 72: 1789–1798.
- Acoustic-trawl surveys show northern cod rising from tens of thousands to more than
  200 kt within a decade; growth rates approached 30%/yr.
- The increase paralleled a capelin increase.

[abs]

### hutchings2011correlates
Hutchings & Rangeley 2011, *Can. J. Zool.* 89: 386–400.
- The collapse lost 1.5–2.5 billion reproductive individuals.
- Lack of recovery is linked to:
  - continued fishing, both directed and bycatch;
  - life-history change;
  - elevated M;
  - emergent and demographic Allee effects and altered species interactions.

[abs]

### neubauer2013resilience
Neubauer, Jensen, Hutchings & Baum 2013, *Science* 340: 347–349.
- Meta-analysis: recovery is slower than predicted, and exploitation history predicts
  recovery time.
- Strong harvest reductions may not give timely recovery.

[abs (editor summary only)]

### swain2008predicted
Swain & Chouinard 2008, CJFAS 65: 2315–2319.
- Southern Gulf (4T) cod is "no longer viable" even with no fishing.
- Extirpation (SSB <1,000 t, under 0.3% of historical) is projected within 40 years with
  no fishing, or 20 years at the 2,000 t TAC.
- The main cause is elevated adult M.

[abs]

### fu2001why
Fu, Mohn & Fanning 2001, CJFAS 58: 1613–1623.
- Age-structured model of 4VsW cod with fishing F, seal predation M_p and residual M
  (immature ages 1–4 versus mature ages 5+).
- Fishing caused the collapse.
- After 1993, rising M_p and mature M plus low recruitment contributed to non-recovery.

[abs]

### mohn1996grey
Mohn & Bowen 1996, CJFAS 53: 2722–2738.
- Grey seals in the 4VsW study area rose from about 5,000 (1970) to 64,000 (1994).
  Their total consumption rose from 10,000 to 121,000 t/yr.
- Cod eaten in 1994 was about 15,400 t (constant-ration model) or 6,300 t
  (proportional model).
- Seal mortality was only 10–20% of F before the closure, so seals did not cause the
  collapse.

[abs]

### swain2015extreme
Swain & Benoît 2015, MEPS 519: 165–182.
- Southern Gulf demersal fishes: negligible F and good juvenile production, yet no
  recovery.
- M of large individuals has risen to levels typical of forage fishes. The authors
  hypothesise a predator pit, i.e. a predation-driven Allee effect from grey seals.
- Recovery is judged impossible under current conditions.

[abs]

### neuenhoff2019continued
Neuenhoff et al. 2019, CJFAS 76: 168–184.
- 4T cod model with a grey-seal functional response.
- Seal predation is minor in the collapse but the main factor preventing recovery,
  making up most of adult mortality since the late 1990s.
- Consistent with a predation-driven Allee effect; extirpation is likely without a large
  seal decline.

[abs]

### keith2012population, perala2017detection, perala2022allee, kuparinen2014allee, frank2000allee, hilborn2014dynamics — see §6.

---

## 2. The eastern Scotian Shelf ecosystem and its change

### frank2005trophic
Frank, Petrie, Choi & Leggett 2005, *Science* 308: 1621–1623.

**From the abstract.** Decades of 4VsW data show a trophic cascade in a large, open
marine ecosystem after removal of cod and other benthic predators.

**Second-hand content, not checked here.**
- The figures show benthic fish down and small pelagic fishes and macroinvertebrates
  (snow crab, northern shrimp) up.
- Large herbivorous zooplankton are down; phytoplankton colour and nitrate changes also
  appear.
- The full-text figure and page numbers, and the shelf area the paper quotes, were **not
  verified**.

[abs; rest second-hand]

### frank2006reconciling
Frank, Petrie, Shackell & Choi 2006, *Ecol. Lett.* 9: 1096–1105.
- Nine western North Atlantic regions. Top-down control dominates in the north (cold,
  species-poor), bottom-up in the south; intermediate regions switch over time.
- Warmer, more diverse systems are more stable.

[abs]

### frank2007ups
Frank, Petrie & Shackell 2007, TREE 22: 236–242.
- Geographic variation in top-down versus bottom-up control across North Atlantic
  shelves.
- Susceptibility to top-down control relates to species richness and temperature.

[abs (PubMed)]

### frank2011transient
Frank, Petrie, Fisher & Leggett 2011, *Nature* 477: 86–89.
- The ESS forage-fish complex rose to biomass **900% greater** than pre-collapse levels.
  This is the key forage-fish magnitude.
- The complex then declined after outstripping its zooplankton food.
- Lagged increases followed in zooplankton and then in large-bodied predators. The
  authors read this as a transient phase and a return towards benthic-predator dominance.

[abs (PubMed). The year the forage decline began and the figure numbers were not
checked; second-hand, the decline started in the mid-2000s.]

### frank2016large
Frank, Petrie, Leggett & Boyce 2016, PNAS 113: 8248–8253.
- 22 Atlantic cod stocks. Fishing alone can produce large-scale synchronous abundance
  changes comparable to those attributed to climate.

[abs]

### choi2004transition
Choi, Frank, Leggett & Drinkwater 2004, CJFAS 61: 505–510.
- ESS demersal community: coherent declines in body size, biomass and condition over 4
  decades, over areas above 10⁴ km² and within 10 years.
- Interpreted as benthic–pelagic decoupling from fishing, compensatory pelagic increases
  and cold, stratified conditions. "Alternate state" language appears.

[abs]

### choi2005integrated
Choi, Frank, Petrie & Leggett 2005, *Oceanogr. Mar. Biol. Annu. Rev.* 43: 47–67.
- An integrated assessment over 43 years: a shift from large demersal fish to smaller
  fish and benthic invertebrates, described as a regime shift.

[meta: second-hand summary via the search snippet of the marineinfo record. Crossref
holds two inconsistent records (see bib comment), so the DOI is omitted.]

### bundy2005structure
Bundy 2005, CJFAS 62: 1453–1473.
- Ecopath models of the ESS before (1980–85) and after (1995–2000) the collapse. The
  periods are second-hand; Bundy 2004 is the technical report.
- Total productivity and biomass were similar, but trophic levels 3–4 gained biomass and
  piscivory rose.
- The ratio of pelagic to demersal feeders went from **0.3 to 3.0**: a demersal-dominated
  system became pelagic-dominated.

[abs]

### bundy2005can
Bundy & Fanning 2005, CJFAS 62: 1474–1489.
- Mass-balance models with cod split into small and large.
- High predation pressure on small cod; small cod compete with abundant forage fish for
  a declining prey base and are in poor condition.
- Large cod suffer high unexplained mortality.
- The authors describe a "vicious circle" in which forage fish may also eat young cod.
  This is the closest statement of our hypothesis in the ESS literature.

[abs. The diet fractions in the full text were not read; a **gap**.]

### bundy2004mass
Bundy 2004, Can. Tech. Rep. Fish. Aquat. Sci. 2520.
- The Ecopath technical report behind Bundy 2005, with the model domain 4VsW to 500 m.
- Biomass/density conversions imply a model area of about 102,500 km² (e.g.
  14,559 t = 0.142 t/km², p. 11). This is derived; the report does not state it.

[full: only pp. 1–2 and 8–11 viewed, delegated; scanned PDF]

### bundy2009seals
Bundy, Heymans, Morissette & Savenkoff 2009, *Prog. Oceanogr.* 81: 188–206.
- Compares 4 NW Atlantic ecosystems (ESS, southern and northern Gulf, Newfoundland) using
  mass-balance models and indicators. All shifted to an alternate state after the
  groundfish collapse.
- Seals, cod and forage fish are the recurring "theme".

[meta + machine summary; second-hand]

### shackell2010decline
Shackell, Frank, Fisher, Petrie & Leggett 2010, *Proc. R. Soc. B* 277: 1353–1360.
- **Western** Scotian Shelf: prey biomass grew exponentially (doubling time 11 yr) while
  predator biomass stayed flat.
- Predator body mass fell about 60% since the early 1970s; the regression explains 65% of
  prey variance.
- Body size of predators, not their biomass, mattered. This argues for size-structured
  modelling.

[abs]

### shackell2007compensation
Shackell & Frank 2007, MEPS 336: 235–247.
- East–west contrast. Several eastern species collapsed in the early 1990s; the warmer
  west shows compensation.
- Condition declined in many species, and growth rates declined in both areas.

[abs]

### petrie2009structure
Petrie, Frank, Shackell & Leggett 2009, *Fish. Oceanogr.* 18: 83–101.
- Predator–prey correlations across shelves (15 predator and 8 prey groups) are modelled
  from depletion rate and bottom temperature, explaining 58% of variance.
- Warm, species-rich systems tolerate exploitation rates about twice those in cold
  systems before the correlation sign flips.

[abs]

### pedersen2017signatures
Pedersen et al. 2017, *R. Soc. Open Sci.* 4: 170215.
- A 33-year trawl survey (Newfoundland/NW Atlantic groundfish) shows four phases:
  1. synchronous collapse;
  2. regime shift with loss of functional diversity;
  3. slow compositional recovery;
  4. slow biomass growth.

[abs. The region is NAFO 2J3KL/3NO, not the ESS, according to my reading of the
abstract context; second-hand. Check before citing as ESS evidence.]

### zwanenburg2000effects
Zwanenburg 2000, *ICES J. Mar. Sci.* 57: 503–509.
- Since the 1970s, average individual weight of targeted demersal fish fell **51% on the
  eastern shelf** and 41% on the western.
- In the east this coincided with doubled fishing effort and the coldest bottom
  temperatures in 50 years.
- After the 1993 closure, size structure stabilised.

[abs]

### frank1996recent
Frank, Carscadden & Simon 1996, CJFAS 53: 1473–1486.
- Capelin reappeared on the Scotian Shelf from the late 1980s with cold anomalies and
  reproduced there (1993 year class).
- Arctic-boreal species (Greenland halibut, Vahl's eelpout) showed similar patterns.
- Part of the forage-fish increase is therefore climate-driven range expansion.

[abs (French version)]

### duplisea1995application
Duplisea & Kerr 1995, *J. Theor. Biol.* 177: 263–269.
- An early biomass size-spectrum model applied to Scotian Shelf demersal survey data.

[meta; second-hand]

### choi2022reconstructing
Choi 2022, bioRxiv preprint (not peer reviewed).
- A Bayesian spatiotemporal reconstruction of Scotian Shelf cod with environmental
  covariates.

[abs]

### dfo2024rvtrends, dfo2025rvtrends
DFO Sci. Resp. 2024/010 and 2025/017.
- Summer RV survey biomass index for 4VsW cod, not q-adjusted:
  - 36,809 t in 2020, inflated by one 5,800 kg tow;
  - no estimate in 2022 (incomplete coverage);
  - 8,232 t in 2023, later revised to 8,212 t;
  - 4,691 t in 2024.
- The 3-year geometric mean is 11,234 t, between 40% (10,293 t) and 80% (20,585 t) of the
  long-term geometric mean.

[full (delegated): 2024/010 Table 1 p. 5; 2025/017 Table 1 p. 8]

### ricard2010extracting, harley2001hierarchical
- **Ricard et al. 2010** (ICES JMS 67: 638–645) shows how to extract DFO groundfish
  survey indices from OBIS, the public route to RV survey data.
- **Harley & Myers 2001** (CJFAS 58: 1569–1584) gives length-specific trawl catchability
  from a meta-analysis:
  - q is rarely near 1, so swept-area biomass underestimates true biomass;
  - haddock q is greater than cod q at the same length;
  - summer q is higher than winter q.
- Both are needed to turn survey indices into absolute biomass for calibration.

[abs]

---

## 3. Cultivation–depensation, predator–prey role reversal and egg/larval predation

### walters2001cultivation
Walters & Kitchell 2001, CJFAS 58: 39–50.
- The defining paper. Dominant predators "cultivate" their juveniles' environment by
  cropping forage species that compete with or prey on those juveniles.
- When adults are fished down, released forage fish produce lagged, depensatory
  juvenile mortality.
- Implication: manage for higher spawning stocks than stock–recruit data suggest.

[abs]

### swain2000pelagic
Swain & Sinclair 2000, CJFAS 57: 1321–1325.
- Southern Gulf cod recovered quickly from low abundance in the mid-1970s, when herring
  and mackerel had collapsed. Prerecruit survival was remarkably high then.
- There is a strong negative relationship between pelagic biomass and cod recruitment
  rate.
- The authors flag a triangle of cod, seals and pelagics, which makes a seal cull's
  outcome unpredictable.

[abs]

### swain2012forage
Swain & Mohn 2012, CJFAS 69: 997–1001.
- **The key counter-evidence.** On the ESS, cod recruitment rate was **unrelated to
  forage fish biomass**.
- The delay in recovery came from high adult M. The recent improvement came from a
  strong 2004 year class and a drop in M, neither attributable to forage fish.

[abs]

### minto2012interactions
Minto & Worm 2012, *Ecology* 93: 2139–2154.
- Hierarchical Bayesian analysis across the North Atlantic:
  - herring–cod recruitment relationships are negative in 8 of 14 regions, absent in 4
    and positive in 2;
  - overall P(negative) is **0.94** for herring and 0.68 for mackerel;
  - capelin and sprat effects are weak or absent.

[abs. The ESS-specific posterior was not read; a **gap** worth checking in the full
text.]

### fauchald2010predator
Fauchald 2010, *Ecology* 91: 2191–2197.
- North Sea, 44 years: cod recruitment is negatively related to herring SSB, with an
  effect comparable in size to *Calanus finmarchicus*.
- Proposes predator–prey reversal causing hysteresis, and suggests herring harvesting
  currently prevents a shift to a herring-dominated state. A direct analogue of our
  policy claim.

[abs]

### bakun2006adverse
Bakun & Weeks 2006, *Fish Fish.* 7: 316–333.
- Self-reinforcing feedback loops can lock ecosystems into adverse states, e.g. the
  Benguela.
- Discusses whether deliberate "interruptive" management actions are warranted.

[abs]

### barkai1988predator
Barkai & McQuaid 1988, *Science* 242: 62–64.
- The original predator–prey role reversal: rock lobsters transplanted to Marcus Island
  were overwhelmed and eaten by whelks.
- The two alternative communities persisted for 4 years.

[abs]

### koster2000trophodynamic
Köster & Möllmann 2000, *ICES J. Mar. Sci.* 57: 310–323.
- Baltic, 1988–1995 stomach data: substantial predation on cod **eggs** by sprat and
  herring, especially sprat early in the spawning season.
- Larvae are little affected because of limited overlap.
- Crossref lists one author; the OUP page confirms Köster & Möllmann.

[abs]

### neumann2014recovery, neumann2017quantifying
- **Neumann et al. 2014** (ICES JMS 71: 1382–1392): sprat and herring diets in 2004–08
  were similar to the 1990s, but less ichthyoplankton was eaten.
- **Neumann et al. 2017** (CJFAS 74: 833–842): spatially resolved estimates show that
  earlier studies **overestimated** clupeid predation on cod eggs. Predation pressure was
  lower in the late 2000s.
- Important for honesty about effect sizes.

[abs]

### daan1985predation
Daan, Rijnsdorp & van Overbeeke 1985, *Trans. Am. Fish. Soc.* 114: 499–506.
- North Sea herring stomachs (n = 5,408): herring ate an estimated **0.04–0.19% of cod
  eggs** and 0.7–1.9% of plaice eggs produced.
- Mainly young herring (ages 2–3) were responsible.
- The authors judge it unlikely that reduced herring predation explains the 1970s
  "gadoid outburst". Direct evidence that egg predation can be small.

[abs]

### segers2007prey
Segers, Dickey-Collas & Rijnsdorp 2007, *ICES J. Mar. Sci.* 64: 60–68.
- North Sea herring feed selectively on larger, late-stage fish eggs when stocks are
  high.

[abs]

### garrison2000predation
Garrison, Michaels, Link & Fogarty 2000, CJFAS 57: 2455–2469.
- Georges Bank: herring overlapped spatially with haddock larvae (and with cod larvae in
  1995). Mackerel overlapped little.
- Predation by planktivores is likely important for gadid larval survival. This is the
  nearest NW Atlantic evidence for our mechanism.

[abs]

### hanson2002diet
Hanson & Chouinard 2002, *J. Fish Biol.* 60: 902–922.
- Southern Gulf cod diet, 1959–2000. Herring share of prey mass:
  - cod 46–60 cm: mean **1.3%** (1959–80) rising to **19.6%** (1987–2000);
  - cod 61–75 cm: **9.4%** rising to **54.2%**.
- Evidence that adult cod eat forage fish in proportion to their abundance, i.e. the
  "adults suppress forage fish" limb.

[abs]

### kohler1969comparisons
Kohler & Fitzgerald 1969, *J. Fish. Res. Board Can.* 26: 1273–1287.
- Cod switch from crustaceans to fish with size; they are mainly piscivorous from about
  **50 cm**.
- On the Nova Scotia banks the main fish prey is **sand lance**; in the Gulf it is
  herring.

[abs]

### scott1968morphometrics
Scott 1968, *J. Fish. Res. Board Can.* 25: 1775–1785.
- Offshore sand lance (*Ammodytes dubius*) on the Nova Scotia banks are larger than
  elsewhere, concentrated at 20–50 fathoms, and spawn in winter.
- Gives a tentative growth curve and documents sand lance as an important cod prey.

[abs]

### staudinger2020role
Staudinger et al. 2020, *Fish Fish.* 21: 522–556.
- Synthesis on NW Atlantic sand lances: life history, trophic role, and 72 regional
  predators including 45 fish species.
- A source for sand lance parameters.

[abs]

### worm2003meta
Worm & Myers 2003, *Ecology* 84: 162–173.
- Cod and shrimp biomass are inversely correlated in 8 of 9 North Atlantic regions,
  which is top-down control.
- The interaction weakens with warmer mean temperature.

[abs]

### benoit2008impacts
Benoît & Swain 2008, CJFAS 65: 2088–2104.
- Southern Gulf fish community, 35 years. Ocean climate, fishing and seal predation all
  have effects.
- Small-fish biomass is inversely related to predation by large fish (predator control).
  Mean body length fell sharply in the 1990s.

[abs]

---

## 4. Size-structured theory: alternative stable states and emergent Allee effects

### deroos2002size
de Roos & Persson 2002, PNAS 99: 12907–12912.
- In an individual-based, size-structured model, food-dependent growth plus mortality
  that declines with size gives an **emergent Allee effect** and catastrophic predator
  collapse.
- No explicit depensation is needed.

[abs]

### deroos2003influence
de Roos, Persson & McCauley 2003, *Ecol. Lett.* 6: 473–487.
- Review: size-selective predation and density-dependent development produce emergent
  Allee effects and alternative states.

[abs]

### deroos2013population
de Roos & Persson 2013, *Population and Community Ecology of Ontogenetic Development*,
Princeton.
- Book-length theory: ontogenetic asymmetry leads to maturation or reproduction
  bottlenecks, which lead to community consequences such as emergent Allee effects.

[abs (book blurb)]

### persson2007culling
Persson et al. 2007, *Science* 316: 1743–1746.
- Whole-lake experiment: culling stunted prey (char) released small prey and allowed the
  predator (trout) to recover.
- The new state persisted for more than 15 years after the cull.
- The closest experimental analogue to "fish forage fish to recover cod". Note the
  mechanism there is overcompensation in prey, not cultivation.

[abs]

### vanleeuwen2008how
van Leeuwen, de Roos & Persson 2008, *J. Sea Res.* 60: 89–104.
- Size-structured cod model. Cod can shape its prey community; alternative states and
  lack of recovery are discussed for NW Atlantic and Baltic cod.

[meta + fragment; second-hand]

### vanleeuwen2013predators
van Leeuwen et al. 2013, *Am. Nat.* 182: 53–66.
- **A theoretical caveat.** If juvenile cod use an extra resource, i.e. an intermediate
  niche before piscivory, then alternative stable states **disappear**, and top-down
  control occurs only without feedback on that resource.
- Our model's diet structure for small cod therefore matters for whether bistability
  appears.

[abs]

### gardmark2015regime
Gårdmark et al. 2015, *Phil. Trans. R. Soc. B* 370: 20130262.
- Distinguishes "cultivation–depensation" from "overcompensation" mechanisms of
  alternative stable states, using Baltic cod.
- Diagnostic: the mechanism can be inferred from changes in predator body growth by life
  stage. **Useful as a model-validation test.**

[abs]

### scheffer2001catastrophic
Scheffer, Carpenter, Foley, Folke & Walker 2001, *Nature* 413: 591–596.
- Loss of resilience allows sudden shifts to alternative states. Manage resilience
  rather than reacting to a shift.

[abs]

### conversi2015holistic
Conversi et al. 2015, *Phil. Trans. R. Soc. B* 370: 20130279.
- Overview of marine regime shifts: there is no common understanding of drivers, and the
  top-down versus bottom-up debate should give way to multi-driver views.

[abs]

### mollmann2009reorganization
Möllmann et al. 2009, *Glob. Change Biol.* 15: 1377–1393.
- Central Baltic regime shift driven by climate plus overfishing; a discontinuous
  shift with hysteresis.

[abs]

### casini2009trophic
Casini et al. 2009, PNAS 106: 197–202.
- Baltic: after cod collapsed, sprat above about 17×10¹⁰ individuals decouple
  zooplankton from hydrography.
- High sprat regulates food for larval cod, which may hinder cod recovery.

[abs]

### huss2013cohort
Not included in bib. Its Baltic sprat–herring alternative stable states were judged
marginal.

---

## 5. Competing explanations

### 5a. Grey seals and elevated natural mortality

#### trzcinski2006continued
Trzcinski, Mohn & Bowen 2006, *Ecol. Appl.* 16: 2276–2292.
- From 1984 ESS cod declined at about 17%/yr, while seals grew at about 12%/yr.
- Cod were under 5% of grey-seal diet in 1993–2000 (QFASA).
- Since the closure, seal-induced instantaneous mortality is **0.21**, with **0.62** from
  other unknown sources. Both contribute to non-recovery.

[abs (OpenAlex)]

#### trzcinski2011estimating
Trzcinski, Mohn & Bowen 2011, DFO Res. Doc. 2011/078.
- In 2009, seal predation M was 0.013–0.166, about 2–22% of total Z ≈ 0.75.

[full (abstract and front matter, delegated)]

#### oboyle2012seal
O'Boyle & Sinclair 2012, *Fish. Res.* 115–116: 1–13.
- Re-examines the assumptions of ESS seal–cod models. Seals have contributed to higher M
  since the late 1980s and to non-recovery.
- Functional-response model predictions fit poorly with the recent rise in cod survey
  abundance.

[meta + machine summary; second-hand. **Needs full-text reading.**]

#### dfo2010greyseals
DFO 2011, Sci. Advis. Rep. 2010/071, "Impacts of grey seals on fish populations in
eastern Canada".
- In most models seals account for **under 17% of total cod mortality** on the ESS (p. 5).
- Estimated cod consumption is 3,000–11,000 t/yr in 4VsW (p. 5); cod is 2–7% of seal diet
  (p. 4).
- The ESS (4VsW) area is about **110,000 km²** (p. 7).
- Seal numbers were about 10,000 (p. 3) or 13,000 (p. 8) in 1960, an internal
  inconsistency.

[full (delegated)]

#### chouinard2005covariation
Chouinard, Swain, Hammill & Poirier 2005, CJFAS 62: 1991–2000.
- Southern Gulf: cod M (ages 3+) rose from the late 1970s to the mid-1990s, tracking
  grey-seal abundance.
- But diets suggest seals eat mostly juvenile cod, which is a mismatch.

[abs]

#### sinclair2001natural
A. F. Sinclair 2001, *ICES J. Mar. Sci.* 58: 1–10.
- Direct estimate after closure: southern Gulf cod M is about **0.4**, not the assumed
  0.2; it possibly increased in the early 1980s.

[abs]

#### benoit2011evaluating
Benoît et al. 2011, MEPS 442: 149–167.
- Simulations of seal predation potential on southern Gulf cod, white hake and skate.
- Seals *could* explain the elevated M, but prey selection is too poorly known to
  conclude.

[meta + machine summary; second-hand]

#### hammill2014feeding
Hammill, Stenson, Swain & Benoît 2014, *ICES J. Mar. Sci.* 71: 1332–1341.
- Cabot Strait overwintering area: cod was **68%** of male grey-seal diet by stomach
  contents and 46% by intestines.
- Cod eaten averaged 39 cm there and 28 cm along Cape Breton.

[abs]

#### swain2015spatial
Swain, Benoît & Hammill 2015, *J. Anim. Ecol.* 84: 1286–1298.
- In the southern Gulf (75,000 km²), seal prey (cod, hake, skate) shifted distribution
  away from seal-risk areas over 1971–2012. Non-prey species did not.

[abs]

#### bowen1994offshore
Bowen & Harrison 1994, MEPS 112: 1–11.
- Grey-seal diet near Sable Island, 1991–93: **sand lance 69.2%**, cod 15.5% and
  flatfishes 10.7% of estimated wet weight consumed.
- Seals are therefore major **forage-fish** predators too. This complicates the forage-fish
  release argument and argues for including seal predation on sand lance in the model.

[abs]

#### bowen2003sustained, bowen2007reduced
- **Bowen et al. 2003**: Sable Island pup production was 25,400 (95% CI 23,500–26,900)
  in 1997, with exponential growth of **12.8%/yr** for four decades.
- **Bowen et al. 2007**: 41,500 (SE 4,381) in 2004; growth rate fell to r = 0.070 from
  0.128, and age at first birth rose.

[abs]

#### hammill2017grey, denheyer2017pup, dfo2022greyseal, hammill2023grey, denheyer2024pup
DFO grey-seal series (all [full], delegated).
- Total NW Atlantic grey seals:
  - 2016: 424,300 (Hammill et al. 2017), later revised to 339,400;
  - 2021: 366,400 (95% CI 317,800–409,400) (SAR 2022/018 p. 2).
- Sable Island pups:
  - 2016: 87,495 (revised, Hammill et al. 2023 Table 4);
  - 2021: 76,600, the first decrease in about 60 years.
- Sable pup growth was 13%/yr before 1997 and about 4%/yr in 1997–2016.
- The series is transcribed in `literature/data/grey_seal_sable_pups.csv`.

#### savenkoff2007effects
Savenkoff et al. 2007, *Ecol. Model.* 204: 115–128.
- Southern Gulf inverse/mass-balance models before and after the collapse, with seals
  and fishing as mortality sources.

[meta; second-hand]

#### dutil2000natural
Dutil & Lambert 2000, CJFAS 57: 826–836.
- Northern Gulf cod in 1993–95: poor condition (energy depletion) after spawning can
  cause natural mortality.
- A non-predation route to elevated M, linked to the food-competition limb of our
  hypothesis.

[abs]

### 5b. Environment and temperature

#### drinkwater2005response
Drinkwater 2005, *ICES J. Mar. Sci.* 62: 1327–1337.
- Review of cod–temperature responses; southern stocks decline and northern stocks spread
  under warming.

[abs]

#### pershing2015slow
Pershing et al. 2015, *Science* 350: 809–812.
- Gulf of Maine warming, faster than 99% of the ocean, reduced cod recruitment and raised
  mortality. Ignoring it contributed to overfishing.

[abs]

#### choi2004transition, zwanenburg2000effects, frank1996recent
See §2. On the ESS, cold, stratified conditions in the late 1980s to early 1990s
coincided with low condition and capelin incursions.

### 5c. Life-history change and fisheries-induced evolution

#### olsen2004maturation
Olsen et al. 2004, *Nature* 428: 932–935.
- Northern cod maturation shifted to younger ages and smaller sizes before the
  moratorium (July 1992). Probabilistic maturation reaction norms indicate
  fisheries-induced evolution.

[abs]

#### swain2007evolutionary
Swain, Sinclair & Hanson 2007, *Proc. R. Soc. B* 274: 1015–1022.
- Southern Gulf cod: the change in length at age 4 correlates with the selection
  differential on parents, evidence of a genetic response to size-selective fishing.

[abs]

#### swain2011life
Swain 2011, *Evol. Appl.* 4: 18–29.
- Southern Gulf cod: early maturation dates from the 1950s–60s cohorts. Current high M
  is a *cause* rather than a consequence of continued early maturation.

[abs]

#### kuparinen2012consequences
Kuparinen & Hutchings 2012, *Proc. R. Soc. B* 279: 2571–2579.
- Simulated fisheries-induced evolution changed life histories but **not** per-capita
  population growth rate appreciably, so it is a weak explanation for non-recovery.

[abs]

#### hutchings2005life
See §1.

### 5d. Depensation and Allee effects in recruitment

#### keith2012population
Keith & Hutchings 2012, CJFAS 69: 1150–1163.
- 207 stocks (104 species): compensation is often weak. Atlantic cod and walleye pollock
  show evidence of an Allee effect.

[abs]

#### perala2017detection
Perälä & Kuparinen 2017, *Proc. R. Soc. B* 284: 20171284.
- Nine herring populations: detecting Allee effects depends on low-abundance data. There
  is no basis for believing Allee effects are rare in marine fish.

[abs]

#### perala2022allee
Perälä, Hutchings & Kuparinen 2022, *Biol. Lett.* 18: 20210439.
- Strong evidence for an Allee effect in a south Newfoundland cod population (likely
  3Ps; second-hand), with an estimated Allee threshold.

[abs]

#### kuparinen2014allee
Kuparinen, Keith & Hutchings 2014, *Conserv. Biol.* 28: 790–798.
- Individual-based cod simulations: an Allee effect slows recovery, which can be
  negligible after 100+ years, and makes recovery time much less predictable.

[abs]

#### frank2000allee
Frank & Brickman 2000, CJFAS 57: 513–517.
- Substocks with Allee effects can appear compensatory when aggregated to the management
  unit.

[abs]

#### hilborn2014dynamics
Hilborn, Hively, Jensen & Branch 2014, *ICES J. Mar. Sci.* 71: 2141–2151.
- More than 100 stocks depleted below 20% of maximum. Depensation is found no more often
  than by chance, and most evidence supports no depensation. A key sceptical reference.

[abs]

#### myers1995population
See §1.

### 5e. Capelin limitation (northern cod)

#### buren2014bottom
Buren et al. 2014, PLoS ONE 9: e87589.
- Newfoundland–Labrador capelin is regulated bottom-up: a regime shift and sea-ice timing
  set the spring bloom.

[abs]

#### koenalonso2021comparative
Koen-Alonso, Lindstrøm & Cuff 2021, *Front. Mar. Sci.* 8: 579946.
- A bioenergetic-allometric biomass model driven by catches and capelin availability fits
  both the NL and Barents Sea cod trajectories with similar parameters.
- The NL non-recovery is consistent with capelin scarcity.

[abs]

#### rose2002capelin, rose2015northern
See §1.

#### dfo2024northerncod, dfo2024northerncodframework, dfo2025northerncod, dfo2024northerncodnews
Northern cod (2J3KL), all [full] or news release, delegated.
- **2024:** SSB 342 kt, 1.2×LRP; 22% probability of being in the Critical Zone; M for
  ages 5+ averaged 0.47 since 1995 and was 0.59 in 2023.
- Capelin remains at about 10% of pre-collapse levels.
- **Commercial fishery reopened** 26 June 2024 with an 18,000 t TAC.
- **2025:** SSB 524 kt, 2.0×LRP; M was 0.32 in 2024.

#### dfo2019sgsl, swain2019assessment, dfo2024sgsl
Southern Gulf cod (4TVn), [full], delegated.
- **2018:** SSB 13.9 kt, 17% of the 80 kt LRP; adult M 0.81–0.85; grey seals concluded
  to be the main cause (SAR 2019/021 p. 2).
- **2023:** SSB 12 kt; 97% probability of commercial extinction within 50 years even
  with no fishing (SAR 2024/026 p. 7).
- The LRP was revised to 210 kt in the text but 80 kt in the figures, an inconsistency
  within the document.

### 5f. Bycatch
- **shelton2006fishing** (§1): directed and bycatch fishing still slowed recovery in the
  2000s.
- For 4VsW, F after 1993 averaged 0.035 for ages 5–15 and recently about 0.01 (Mohn &
  Rowe 2012 p. v). Exploitation has been under 2% since 1994 (COSEWIC 2010 p. 100).
- Bycatch is therefore a weak explanation for the ESS specifically.

---

## 6. Forage-fish management and the policy trade-off; culling analogues

### pikitch2012little
Lenfest Forage Fish Task Force 2012.
- Recommends precautionary forage-fish harvest rules, leaving more forage fish in the
  water. Press material says "twice as many" in most ecosystems.
- Numeric rules, such as the 40% B0 threshold, are **not verified here**; second-hand.

[meta: report page only]

### pikitch2014global
Pikitch et al. 2014, *Fish Fish.* 15: 43–64.
- From 72 Ecopath models: forage fish are worth US$16.9 bn/yr, 20% of global ex-vessel
  value. US$5.6 bn is direct catch and US$11.3 bn is support of predator fisheries.

[abs]

### smith2011impacts
Smith et al. 2011, *Science* 333: 1147–1150.
- Across five ecosystem models, fishing low-trophic-level species at MSY has large
  ecosystem impacts.
- Halving exploitation still gives 80% of MSY with much smaller impacts.

[abs (PubMed)]

### cury2011global
Cury et al. 2011, *Science* 334: 1703–1706.
- Seabird breeding success drops below a threshold of about **one-third** of maximum
  observed prey biomass.
- Consistent across 7 ecosystems and 14 species.

[abs (PubMed)]

### hilborn2017when
Hilborn et al. 2017, *Fish. Res.* 191: 211–221.
- Trophic models overstate the effect of forage fishing on predators because they ignore
  forage variability, weak stock–recruitment, size selectivity and spatial distribution.
- Little empirical link exists between forage abundance and predator population change in
  US fisheries. Supports the feasibility of forage fishing; cuts both ways for us.

[abs]

### essington2015fishing
Essington et al. 2015, PNAS 112: 6648–6652.
- High fishing rates persist as forage stock productivity declines, amplifying the
  magnitude and frequency of collapses. Risk-based rules cost little catch.

[abs]

### walters2005possible
Walters, Christensen, Martell & Kitchell 2005, *ICES J. Mar. Sci.* 62: 558–568.
- Ecosim: applying single-species MSY to every species would degrade ecosystems and lose
  top predators.
- Supports protecting forage species. It is also the authors' own counterweight to
  Walters & Kitchell 2001.

[abs]

### houle2013emerging
Houle, Andersen, Farnsworth & Reid 2013, *J. Fish Biol.* 83: 890–904.
- **Size/trait-based model**: moderate forage fishing has small effects on predator
  fisheries.
- Predator fisheries can *enhance* forage yields. The most direct size-spectrum precedent
  for our policy scenarios.

[abs]

### szuwalski2017high
Szuwalski, Burgess, Costello & Gaines 2017, PNAS 114: 717–721.
- East China Sea ecosystem model (size-based, second-hand): high catches arise from
  predator removal and release of small fish.
- Single-species management would reduce catch. An example of policy-relevant
  predator-release dynamics.

[abs]

### yodzis2001must
Yodzis 2001, TREE 16: 78–84.
- Review of the culling debate (marine mammals versus fisheries) and the difficulty of
  predicting cull outcomes in complex webs.

[abs (PubMed)]

### lessard2005should
Lessard, Martell, Walters, Essington & Kitchell 2005, *Ecol. Soc.* 10(2): 1.
- Asks whether ecosystem management should actively manipulate abundances (e.g.
  predator or prey control). Ecosim-based (second-hand).

[meta; second-hand]

### bowen2013marine
Bowen & Lidgard 2013, *Mammal Rev.* 43: 207–220.
- Review of marine-mammal culls: they reduce predator density, but effects on prey
  fisheries are often uncertain or absent.

[abs]

### persson2007culling
See §4; the experimental success of prey culling.

---

## 7. Size-spectrum modelling and mizer

### andersen2006asymptotic
Andersen & Beyer 2006, *Am. Nat.* 168: 54–61.
- Derives the abundance of species as a function of asymptotic size, N ∝ w^−2.05, from
  individual-level processes.
- Predicts K ∝ L∞^−1. The theoretical basis for mizer's default rmax and abundance
  scaling.

[abs (PubMed)]

### hartvig2011food
Hartvig, Andersen & Beyer 2011, *J. Theor. Biol.* 272: 113–122.
- The food-web size-spectrum framework that mizer's multispecies model implements.
  Species are characterised by size at maturation.

[abs (PubMed)]

### andersen2010damped
Andersen & Pedersen 2010, *Proc. R. Soc. B* 277: 795–802.
- Size/trait model: fishing does not change the community spectrum slope but depletes the
  largest individuals.
- Induces trophic cascades that are damped.

[abs]

### andersen2016theoretical
Andersen, Jacobsen & Farnsworth 2016, CJFAS 73: 575–588.
- Review of size-spectrum model foundations: food encounter, bioenergetics, and the
  food-web, trait-based and community variants.

[abs]

### andersen2019fish
Andersen 2019, *Fish Ecology, Evolution, and Exploitation*, Princeton.
- A textbook on size- and trait-based theory.

[abs (blurb)]

### scott2014mizer, delius2013mizer, pennino2025decade
- **Scott, Blanchard & Andersen 2014** (MEE 5: 1121–1125) is the mizer package paper.
- **The CRAN record** (doi:10.32614/CRAN.package.mizer) lists authors Delius, Scott,
  Blanchard and Andersen. The project uses mizer 3.4.0.9003.
- **Pennino et al. 2025** (*Ecol. Model.* 508: 111241) is a systematic review of 43 mizer
  studies.
  - A second record with the same title (vol. 512: 111392, 2026) is linked to an erratum;
    cite the 2025 original.

[abs]

### blanchard2014evaluating
Blanchard et al. 2014, *J. Appl. Ecol.* 51: 612–622.
- A calibrated North Sea multispecies size-spectrum model (mizer) used to evaluate
  trade-offs between F_MSY, large-fish indicators and biodiversity. Template for
  calibration.

[abs]

### spence2021quantifying
Spence et al. 2021, *Fish Fish.* 22: 667–681.
- Combines state-space single-species assessments with a size-based multispecies model
  (mizer) to quantify uncertainty in F, catches and biomass.

[abs]

### reum2019species
Reum et al. 2019, *Oikos* 128: 1051–1064.
- Eastern Bering Sea multispecies size-spectrum models. Species- plus size-based prey
  preferences predict about three times more observed diet links.
- Ontogenetic diet shifts attenuate cascades. Relevant to how we set the interaction
  matrix.

[abs]

### collie2016ecosystem
Collie et al. 2016, *Fish Fish.* 17: 101–125.
- Models of intermediate complexity hit a "sweet spot" of uncertainty for policy
  indicators.

[abs]

### froese2014bayesian, wigley2003length, froese2026fishbase
Length–weight sources.
- **Froese, Thorson & Reyes 2014** (*J. Appl. Ichthyol.* 30: 78–85) is the Bayesian
  method behind FishBase length–weight a and b; W in g, L in cm.
- **Wigley et al. 2003** (NOAA Tech. Memo. NMFS-NE-171) gives length–weight relations for
  74 NW Atlantic species from NEFSC surveys, 1992–99.
- **FishBase** pages for 6 species were read on 2026-11-13; values are in
  `empirical_targets.md`.

[abs or meta]

### duplisea1995application, adekoya2026reexamining
See §2 and §0.

---

## 8. Other DFO and COSEWIC grey literature (4VsW)

All read in full or in part by the delegated agent.

### mohn1994assessment
Res. Doc. 94/40.
- The 4VsW fishery closed **1 September 1993** (abstract p. 2).
- F was above Fmax in 1988–92.
- Gives the pre-revision 1993 landings of 3,474 t.

### fanning2003assessment
Res. Doc. 2003/027.
- Landings (Table 1, p. 10) peaked at **80,428 t in 1968** and were 29,892 t in 1992,
  3,294 t in 1993 and 83 t in 2002.
- Survey-based q-corrected SSB (Table 13, p. 22) peaked at 171.6 kt in 1984 and was
  4.7 kt in 2002, a 97% decline.
- RV-survey Z by age group (Table 14) is transcribed.
- Since 1993, Z ≈ M is about 1.0 for older and 0.5 for younger ages (p. 5).
- CSVs are in `literature/data/`.

### dfo2003ssr4vsw, dfo2003proceedings
- The 2003 stock status report gives decadal mean landings: 61.9 kt (1958–69), 40.2 kt
  (1970s), 49.3 kt (1980s) and 12.7 kt (1990–97). This is from Proceedings 2003/021
  p. 72.

### dfo2011framework
Proceedings 2011/051.
- The December 2010 framework meeting concluded the 4VsW LRP is 33,000 t, the lowest SSB
  from which the stock had recovered (p. 29). This differs from the 50 kt adopted later.

### dfo2011rpa, mohn2012laurentian
Recovery potential assessment for the Laurentian South DU.
- VPA SSB reached a record low of about 7,500 t in 2003. A minimum of 6.3 kt in 2001 is
  given on p. 6, an internal inconsistency.
- SSB rose to 64,000 t in 2009; the long-term mean is 75,000 t.
- **LRP 50 kt** (0.4 BMSY; BMSY 135 kt). SSB has been below the LRP since 1992 except in
  2009.
- M at ages 5+ peaked at about 1.1 in the 1990s to early 2000s, averaged 0.8 in 1990–2004
  and 0.6 in the last 5 years, and was 0.36 at the end of the series. Recovery needs
  M ≈ 0.3.
- Adult M across the Laurentian South DU has been near 45–50% per year for 20 years
  (SAR p. 6).
- The Sable Island herd was under 50,000 when 4VsW cod was productive and about 300,000
  in 2011 (Res. Doc. p. 13).

### cosewic2010cod
COSEWIC 2010.
- The Laurentian South population was assessed **Endangered** (April 2010) after a 90%
  decline.
- 4VsW Z = 0.845 (SE 0.151) for ages 3–8 in 2004–08 (Table A2, p. 99).

### dfo2018ifmp4vwx5
Not included in the bib.
- The 4VWX5 groundfish management plan web page says the 50 kt LRP was adopted on
  26 Sept 2012 and RV indices hit a series low in 2016.
- Cite it as a web page if needed.

---

## 9. Gaps, unverified items and caveats

1. **"Sinclair et al. 2015 on seals"** (named in the brief): **no such paper found**. Not
   in the bib. The closest real items are:
   - O'Boyle & **Sinclair** 2012 (Fish. Res.), on ESS seal–cod interactions;
   - A. F. **Sinclair** 2001 (ICES JMS), on southern Gulf M;
   - Swain & Benoît 2015 (MEPS).
   Please tell me which was meant.
2. **Full texts not read** for the papers that matter most: Frank et al. 2005 and 2011,
   Bundy & Fanning 2005, Swain & Mohn 2012, O'Boyle & Sinclair 2012, Minto & Worm 2012
   and Bundy et al. 2009. Abstract numbers are reliable; everything else about them is
   second-hand.
   - Specific gaps: the ESS forage-fish indices in Frank 2005, the cod diet fractions in
     Bundy & Fanning 2005, and the ESS herring–cod posterior in Minto & Worm.
3. **No direct ESS evidence was found that pelagic fish eat cod eggs or larvae.** The
   evidence is from the North Sea (Daan 1985, Segers 2007), the Baltic (Köster &
   Möllmann 2000; Neumann 2014, 2017) and Georges Bank (Garrison 2000, overlap only).
   Correlational evidence comes from the southern Gulf (Swain & Sinclair 2000) and the
   North Atlantic meta-analysis (Minto & Worm 2012). It is *negative* on the ESS (Swain &
   Mohn 2012).
4. **4VsW status after 2011.** No full stock assessment was found after the 2011 RPA,
   so current SSB relative to the LRP is unknown. Only RV survey index trends to 2024
   are available.
5. **Areas.** 4Vs and 4W areas were not found separately. ESS ≈ 110,000 km² (DFO SAR
   2010/071 p. 7). Bundy 2004 implies about 102,500 km² (derived).
6. **Herring and mackerel stock assessments for the ESS** were not compiled. The summer
   bottom-trawl survey samples pelagics poorly.
7. **Choi et al. 2005**: Crossref metadata is inconsistent, so the DOI is omitted.
   **Pikitch et al. 2012**: author line to be checked on the PDF.
   **Hammill & Stenson 2000** (*J. Northw. Atl. Fish. Sci.* 26: 1–23,
   doi:10.2960/j.v26.a1, the seal source used by Adekoya et al.) was left out because the
   Crossref title is truncated and the PDF was not opened.
8. **Adekoya et al. 2026** cite "Frank et al. (2013)" for a several-fold forage-fish
   increase. I could not identify that paper.
9. The **CJFAS author-guidelines page** returned HTTP 403 to my fetcher. The journal
   facts in `journal_choice.md` come from a delegated reading and should be re-checked.
10. **File left in the user's Downloads folder.** During the delegated grey-literature
    search, a click on publications.gc.ca saved `/home/gustav/Downloads/Fs97-6-2520-eng.pdf`
    (Bundy 2004 technical report, about 15 MB). That download was not cleared with the
    user first. It is still there.
