# Counterarguments a reviewer will raise

Compiled 2026-11-13. The keys refer to `paper/references.bib`, and the evidence behind
each point is summarised in `notes.md`. Objections are ordered by how damaging I expect
them to be. Each has a suggested response: an analysis or framing that would meet it.

---

## Part A. Against the forage-fish (cultivation–depensation / role-reversal) explanation

### A1. The direct test on the ESS came out negative *(most damaging)*

**Objection.** Swain & Mohn tested exactly this hypothesis for 4VsW cod and found that
cod recruitment rate was **unrelated to forage-fish biomass**. They attribute the
non-recovery to high **adult** natural mortality. They attribute the late-2000s
improvement to the strong 2004 year class and a fall in M, neither linked to forage fish.
A reviewer from DFO, possibly one of these authors, will ask why a model should overrule
the data.

**Supporting refs.**
- `swain2012forage`
- `mohn2012laurentian` (M at ages 5+ ≈ 0.8–1.1 in the 1990s–2000s)
- `fanning2003assessment` (Z ≈ 1.0 for older cod after the closure)

**Suggested response.**
1. Show in the model where the forage-fish effect acts: on egg/larval survival, on
   juvenile growth through competition, or on adult condition. Test whether the model's
   implied recruitment-rate–forage relation would have been detectable in the noisy
   survey series. A power analysis on simulated survey data would do this.
2. Reproduce the adult-M pattern, or state honestly that the model needs an external
   adult mortality, such as seals, to match it.
3. Present the mechanism as acting *together with* elevated adult M, not instead of it.
   Bundy & Fanning (`bundy2005can`) proposed exactly this combination: competition gives
   poor condition, which gives high adult M. Dutil & Lambert (`dutil2000natural`) show
   that poor condition can kill cod.

### A2. Grey seals are the better-supported cause of elevated adult M

**Objection.** In neighbouring 4TVn, DFO concludes that grey-seal predation is the main
cause of adult cod M of 0.8 or more and of likely extirpation, through a predation-driven
Allee effect or "predator pit". Seals grew about 12–13% a year while ESS cod declined
about 17% a year, and the ESS seal herd is the largest in the world. Neuenhoff et al.
explicitly model a predation-driven Allee effect, which gives bistability **without**
forage fish.

**Supporting refs.**
- `swain2015extreme`, `neuenhoff2019continued`, `dfo2019sgsl`, `dfo2024sgsl`
- `chouinard2005covariation`, `hammill2014feeding` (cod 68% of male seal diet in Cabot
  Strait)
- `trzcinski2006continued` (seal M 0.21 after the closure)
- `swain2015spatial`, `bowen2003sustained`, `hammill2023grey`

**Counter-evidence we can use.**
- On the ESS itself, seals account for **under 17%** of total cod mortality in most
  models (`dfo2010greyseals` p. 5).
- Cod was **under 5%** of seal diet in 1993–2000 (`trzcinski2006continued`) or 2–7%
  (`dfo2010greyseals`).
- Trzcinski et al. leave **M = 0.62 unexplained** beyond seals.
- `mohn1996grey` and `fu2001why` show seals did not cause the collapse.
- `oboyle2012seal` argues the seal-model assumptions need reconsidering.

**Suggested response.**
- Include seals explicitly, for example as external size-selective mortality following
  `adekoya2026reexamining`.
- Run the 2×2 factorial: seals rising or constant × forage-fish predation on early cod
  on or off. Report which combination is needed for (i) non-recovery and (ii)
  hysteresis.
- Note that seals eat mostly **sand lance** near Sable (69%, `bowen1994offshore`). Seal
  predation therefore also controls forage fish, which our model must capture.

### A3. Weak direct evidence for pelagic predation on cod eggs and larvae in this system

**Objection.** No stomach-content study shows ESS herring, sand lance or mackerel eating
cod eggs or larvae.
- In the North Sea, herring ate only **0.04–0.19%** of cod egg production
  (`daan1985predation`).
- Baltic estimates of clupeid egg predation were later shown to be **overestimates**
  (`neumann2017quantifying`).
- On Georges Bank only *spatial overlap* was shown (`garrison2000predation`).
- Minto & Worm found the herring effect varies by region and the mackerel effect is weak
  (`minto2012interactions`).
- Sand lance, the dominant ESS forage fish, has no documented role as a cod-egg predator
  in the sources found.

**Supporting refs.**
- `daan1985predation`, `neumann2014recovery`, `neumann2017quantifying`
- `garrison2000predation`, `minto2012interactions`, `segers2007prey`

**Suggested response.**
- Make **competition** for zooplankton between forage fish and juvenile cod the primary
  role-reversal pathway in the model. Evidence: forage fish outstripped their
  zooplankton food (`frank2011transient`); Bundy & Fanning's competition result; Casini
  et al. on sprat regulating larval cod food (`casini2009trophic`).
- Treat direct egg/larval predation as a sensitivity parameter swept from zero up to the
  Baltic and North Sea magnitudes.
- State plainly what fraction of the effect comes from each pathway.

### A4. The ESS forage-fish boom collapsed by itself, so the cod-depleted state was transient, not an alternative stable state

**Objection.**
- Frank et al. report that the forage-fish complex, after rising 900%, declined
  ("outstripped their zooplankton food supply"). Large predators then began to increase,
  so the authors call the altered state *transient* and reversible.
- A transient driven by consumer–resource oscillation is a different claim from
  bistability with hysteresis. If the ecosystem "returns" on its own, then the
  forage-fishing intervention is unnecessary.

**Supporting refs.**
- `frank2011transient`
- `petrie2009structure`, `frank2006reconciling` (trophic control depends on temperature
  and diversity)
- `pedersen2017signatures` (slow recovery phases)

**Counter-evidence.**
- Cod did **not** stay on a recovery path. The VPA SSB peak of 64 kt in 2009 was followed
  by RV indices at a series low in 2016 (`dfo2018ifmp4vwx5`, not in the bib) and
  4.7–8.2 kt in 2023–24 (`dfo2025rvtrends`).
- Survey forage-fish indices rose again after 2012: herring 2013–18 at about 5× the 1980s
  level ([D], `empirical_targets.md` §3).

**Suggested response.**
- Distinguish explicitly between three possibilities: (i) a stable alternative state
  needing a perturbation, (ii) a long transient or limit cycle, and (iii) external
  forcing.
- Use the stability tools (eigenvalues of both steady states; bifurcation in cod F and
  forage F) to show that the low-cod state is an attractor.
- Show that the forage decline of the late 2000s was, or was not, large or long enough
  to cross the threshold.

### A5. Bistability may be a modelling artefact

**Objection.**
- Whether alternative stable states arise depends on details. Van Leeuwen et al. show
  that if juvenile cod use an extra, exclusive resource before turning piscivorous, the
  alternative states **disappear** (`vanleeuwen2013predators`).
- In mizer, bistability can also depend on the stock–recruitment (R_max) formulation,
  the interaction matrix and the predation kernel.
- A reviewer will ask whether the result survives reasonable changes to these.

**Supporting refs.**
- `vanleeuwen2013predators`, `gardmark2015regime`, `deroos2003influence`
- `reum2019species` (diet structure changes cascades)
- `collie2016ecosystem`

**Suggested response.**
- Run ensembles over the interaction matrix, as in `adekoya2026reexamining`, and over
  R_max and reproduction level.
- Include a juvenile-cod resource (benthos or external encounter) and show where
  bistability survives.
- Apply Gårdmark et al.'s growth diagnostic: under cultivation–depensation, juvenile cod
  growth should be depressed in the low state. Compare this with observed size at age
  and condition (`choi2004transition`, `zwanenburg2000effects`).

### A6. Depensation is rare in stock–recruit data

**Objection.** Meta-analyses find little evidence of depensation: 3 of 128 stocks
(`myers1995population`), and no more often than chance among more than 100 depleted
stocks (`hilborn2014dynamics`).

**Counter-refs.** `keith2012population` (Allee effect in cod), `perala2017detection`
(detection bias), `perala2022allee` (Allee threshold in a Newfoundland cod stock),
`kuparinen2014allee`, `frank2000allee` (masking by aggregation).

**Response.** The mechanism is an *emergent*, community-level Allee effect
(`deroos2002size`). It need not appear as single-species stock–recruit depensation.

### A7. The environment did it

**Objection.**
- The collapse and its aftermath coincided with the coldest bottom temperatures in 50
  years, poor condition and smaller sizes across many demersal species (`choi2004transition`,
  `zwanenburg2000effects`, `dutil2000natural`).
- Capelin entered the ESS because of cold anomalies (`frank1996recent`), so part of the
  forage-fish "release" may be climate-driven rather than predator release.
- On the western shelf, increased stratification contributed to prey increases
  (`shackell2010decline`).
- Warming elsewhere has prevented cod recovery (`pershing2015slow`, `drinkwater2005response`).

**Response.**
- Hindcast with and without temperature-dependent rates, or at least discuss how
  temperature would change the hysteresis width.
- Point out that Hutchings & Myers rejected temperature for the northern cod *collapse*
  (`hutchings1994what`), and that fishing synchronises cod dynamics at climate-like
  scales (`frank2016large`).

### A8. Life-history change and fisheries-induced evolution

**Objection.** Cod mature earlier and smaller, which raises adult M and lowers
productivity (`olsen2004maturation`, `swain2007evolutionary`, `swain2011life`,
`hutchings2005life`).

**Counter-ref.** Simulated fisheries-induced evolution barely changed population growth
rate (`kuparinen2012consequences`).

**Response.** Acknowledge it, and possibly run a scenario with reduced w_mat.

### A9. Continued fishing and bycatch

**Objection.** Fishing still delayed recovery of several NW Atlantic cod stocks
(`shelton2006fishing`, `hutchings2011correlates`).

**Response.** For 4VsW, F after the closure was about 0.01–0.035 and exploitation under
2% (`mohn2012laurentian`, `cosewic2010cod`). This is a weak explanation here, but include
residual F in the scenarios.

### A10. Novelty: the model already exists

**Objection.** A 19-species mizer model of the ESS, with seal forcing and an explicit
cultivation–depensation interpretation, was published in October 2026
(`adekoya2026reexamining`).

**Response.**
- Our contributions are (i) demonstrating bistability and hysteresis, (ii) the
  forage-fishing intervention, and (iii) the mechanistic decomposition across pathways.
- Engage directly with their parameterisation (their species table, seal selectivity and
  rmax scaling); see `empirical_targets.md` §6.

### A11. Other cod stocks did recover when food, not fewer forage fish, returned

**Objection.**
- Northern cod rebuilt to 2×LRP by 2025, together with a capelin increase
  (`rose2015northern`, `dfo2025northerncod`).
- Capelin limitation, i.e. too few forage fish, explains NL non-recovery
  (`rose2002capelin`, `buren2014bottom`, `koenalonso2021comparative`).
- This is the opposite sign of forage-fish effect to ours.

**Response.** The capelin–cod relation is predator food limitation. Ours is
prey-on-juvenile-predator suppression. Both operate on the same food web, and their
balance depends on size structure, which is precisely what a size-spectrum model
resolves.
- Show that in the model, forage fish benefit large cod (food) and harm small cod
  (predation and competition).
- Show where the net sign flips.

---

## Part B. Against a "fish more forage fish" policy

### B1. Forage fish sustain the rest of the ecosystem

**Objection.** Deliberately depleting forage fish runs against international guidance.
- The Lenfest Task Force recommends leaving *more* forage fish in the water
  (`pikitch2012little`).
- Forage fish support predator fisheries worth about twice the direct catch
  (`pikitch2014global`).
- Seabird breeding success drops below about one-third of maximum prey biomass
  (`cury2011global`).
- Fishing low-trophic-level species at MSY has large ecosystem impacts; halving it keeps
  80% of yield (`smith2011impacts`).
- Single-species MSY on every species loses top predators (`walters2005possible`).
- Canadian policy on forage-species fisheries is precautionary. DFO's policy on new
  fisheries for forage species exists, but I did **not verify** its text.

**Response.**
- Frame the intervention as **temporary and targeted**: a "kick" to cross the threshold,
  not a permanent harvest regime.
- Quantify in the model the minimum forage reduction and its duration.
- Report impacts on other predators in the model, and state that seabirds and mammals are
  not modelled. Cury's one-third threshold is a natural constraint to report against.

### B2. Cod need forage fish as food

**Objection.**
- Large cod on the Nova Scotia banks eat mainly sand lance (`kohler1969comparisons`,
  `scott1968morphometrics`).
- Cod condition and reproductive potential track capelin availability (`rose2002capelin`).
- Northern cod growth is still impeded by low capelin (`dfo2024northerncod`).
- Removing forage fish could reduce adult cod growth and fecundity, offsetting any
  juvenile benefit.

**Response.**
- This is a size-structured trade-off the model handles naturally. Report adult cod
  feeding level and growth under the intervention.
- Houle et al. found in a size-based model that moderate forage fishing has only small
  effects on predator fisheries (`houle2013emerging`).

### B3. Seals switch prey

**Objection.**
- Grey seals near Sable eat mainly sand lance (69%, `bowen1994offshore`).
- Depleting sand lance could push seals onto cod, worsening the adult-M problem. Swain &
  Sinclair already warned of this cod–seal–pelagic triangle (`swain2000pelagic`).
- Cull and predator-control outcomes in complex webs are hard to predict
  (`yodzis2001must`, `bowen2013marine`).

**Response.** If seals are modelled as external mortality, this feedback is absent. State
this limitation, or model seal predation as a function of the availability of sand lance
versus cod.

### B4. Forage stocks collapse easily, and the ESS forage complex already collapsed by itself

**Objection.**
- Forage fish are volatile. Fishing at high rates when productivity drops amplifies
  collapses (`essington2015fishing`).
- The ESS forage complex already declined without a fishery (`frank2011transient`).
- A forage fishery could overshoot and remove the food base for all piscivores.

**Response.** Use harvest-control rules with biomass thresholds in the scenarios. Report
the risk that forage biomass falls below one-third of B0 or the pre-collapse level.

### B5. Forage fishing may simply not matter much to predators

**Objection.** Empirically, forage abundance has weak effects on predator population
change, and trophic models exaggerate forage–predator coupling (`hilborn2017when`). By
the same logic, forage fishing may do little to help cod.

**Response.** Report effect sizes with uncertainty bands from the ensemble. State the
conditions under which the intervention fails.

### B6. Precedents are few and come from small systems

**Objection.**
- The only experimental demonstration of prey culling releasing a predator is a lake
  (`persson2007culling`), and there the mechanism was overcompensation in prey, not
  cultivation.
- Marine "interruptive actions" remain speculative (`bakun2006adverse`, `lessard2005should`).
- The North Sea suggestion that herring harvest prevents a herring-dominated state is
  correlational (`fauchald2010predator`).

**Response.** Present the intervention as a model-based hypothesis for adaptive
management, for example a monitored experimental reduction of herring. Do not present
it as a recommendation.

### B7. Practicality and governance

**Objection.**
- There is no commercial sand lance fishery on the ESS.
- Herring and mackerel in the region are managed as separate stocks with their own
  conservation concerns. Their current status was not compiled here; it is a **gap**.
- Small-mesh fisheries would take juvenile cod as bycatch.

**Response.** Discuss which species and gears are realistic targets. Herring is the
species with an existing fishery and the strongest herring–cod signal
(`minto2012interactions`). Model bycatch of small cod by any forage gear.

---

## The two or three objections that matter most

1. **Swain & Mohn 2012** (A1) together with the **seal / adult-M** evidence (A2). The
   empirical record points to adult mortality, not recruitment. The model must reproduce
   high adult M and show the forage pathway adds something.
2. **Frank et al. 2011** (A4). The forage complex collapsed by itself, and the authors
   read the altered state as *transient*. The paper must show true bistability (stable low
   state, hysteresis) and explain why cod stayed low after the forage decline.
3. **Weak direct evidence of egg and larval predation** (A3), plus the **ecosystem role
   of forage fish** (B1–B3). These argue for presenting competition and predation as
   alternative pathways tested by sensitivity analysis, and the policy as a conditional,
   temporary intervention.
