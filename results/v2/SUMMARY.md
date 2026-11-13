# Eastern Scotian Shelf cod: can forage-fish "role reversal" explain the failed moratorium? Model results (v1 and v2)

*For the agents drafting the paper and the policy website. The main model is
**v2** (`R/*.R`, `results/`, `figures/`, `models/`; run `Rscript R/run_all.R`).
**v1**, the first, naive calibration, is kept unchanged in `R/v1/`,
`results/v1/`, `figures/v1/`, `models/v1/` (run `Rscript R/v1/run_all.R`; its
own summary is `results/v1/SUMMARY.md`). Units: g m^-2 of shelf;
1 g m^-2 = 110 kt over the 1.1 x 10^5 km^2 of NAFO 4VsW. Sources and
verified/unverified tags for every number: `data/species_params_sources.md`.*

## 0. Headline

1. **v1 could not test the hypothesis** (coordinator's reading confirmed):
   forage fish could not boom (Beverton-Holt level 0.5 caps recruitment at 2x;
   herring peaked at 1.9x, the cod-free community had 0.55x baseline forage),
   cod early life was almost mortality-free (forage + groundfish killed ~7 % of
   cod between 1 mg and 0.1 g, erepro 5.6e-5 hid the rest), released haddock,
   hake and plaice ate the forage fish, and fish removed only 1-3 % of plankton
   production.
2. **v2 reproduces the forage boom and lets both pathways act, and cod still
   recovers fast.** v2 constrains the plankton resource with Scotian Shelf data
   (Bundy 2004), makes most egg-to-juvenile mortality explicit, uses low
   reproduction levels, and forces the other groundfish along their observed
   declines with calibrated effective mortality. The calibration hindcast gives
   a forage boom of **x9.4** (survey x7.9; Ecopath x9.6) and pelagic:demersal
   0.30 -> 6.9 (Bundy 0.3 -> 3.0). In the boom, plankton of 0.1 mg-0.1 g falls to
   81-85 % of capacity (98 % before), fish eat 15-20 % of its production
   (1.5-4 % before), juvenile cod feeding level drops 0.60 -> 0.56, and cod
   survival from 1 mg to 1 g falls from **2.4 % to 1.6 % (x0.67): x0.73 from
   slower growth, x0.93 from direct predation**. Forage fish then kill **4.3 %**
   of cod 1 mg-1 g (0.29 % at baseline). This is far too little: from the
   model's version of the observed 2000 community (cod SSB 0.1 % of baseline,
   forage x12-14) cod regains 50 % of baseline SSB in **7 years** under the
   moratorium; switching either pathway off changes this by < 1 year.
3. **No alternative stable state** in v2 (two starts converge, cod invades the
   cod-free, forage x19 community at **+0.52 yr^-1**; cod collapses at F ~1.4
   whether F rises or falls; the only path dependence, at F 0.9-1.3, comes from
   the other groundfish re-invading, not from forage fish).
4. **Thresholds (coordinator item E).** With the forage -> cod early-life
   preference `s_egg` raised (no recalibration), a >= 30-year failed moratorium
   needs **s_egg ~ 12** and a true alternative stable state **s_egg ~ 19**,
   i.e. forage fish eating ~30-47 % of cod 1 mg-1 g in the boom and 3-5 % at
   the 1980s baseline. Field estimates are far lower (North Sea herring ate
   0.04-0.19 % of cod eggs; no forage-recruitment relation on the ESS), and at
   s_egg >= 10 the uncalibrated model can no longer sustain the 1980s cod
   (equilibrium at baseline F drops to 62 % at s_egg = 10, 8 % at 20).
5. **Forage-fish fishing** cannot help in v2 (cod already recovered by 2009);
   it only reduces cod food (forage F = 1: cod SSB -33 %, weight at age 5
   -20 %; F >= 1.5 extirpates forage fish). In the s_egg = 20 what-if the
   moratorium fails (50 years to 50 % SSB from 2026), and a small push of
   forage F 0.25 for 5 years cuts that to 10 years (F >= 0.5: 6-7 years);
   recovery then persists.
6. **Seals / adult M.** Adult cod M = 0.8 from 1990 brings v2 cod SSB in
   2000-02 down from 4.9x to 0.74x the 1980-85 level (observed 0.06x): in the
   factorial, adult M accounts for ~93 % of the (log) reduction, forage
   predation on cod and plankton depletion together for ~7 % (+15 % SSB when
   both are switched off). v2 cod is too resilient: it needs an effective F of
   6.3 to stay at its observed post-collapse level and collapses only above
   F ~1.35 at equilibrium.

**Acceptance tests (v2):** 1 passed with caveats (cod biomass +61 %, plaice
+59 %, yield 2.1x landings; calibration stopped at 61 % max error);
2 failed (fast recovery); 3 failed (no bistability; quantified);
4 not applicable in the main model, illustrated in the s_egg = 20 what-if;
5 done (thresholds above). Numerical robustness confirmed.

## 1. Files (v2)

| What | Where |
|---|---|
| Functions incl. `run_scenario()`, `build_model()`, budgets, invasion test | `R/functions.R` |
| Test 1 baseline + hindcast calibration | `R/01_build_model.R` |
| Test 2 hindcast/moratorium + pathways (item D) | `R/02_collapse_moratorium.R` |
| Test 3 bistability, invasion, hysteresis | `R/03_bistability.R` |
| Test 4 forage fishing (main) / s_egg = 20 what-if | `R/04_forage_fishing_recovery.R`, `R/04b_forage_fishing_strong_variant.R` |
| Test 5 thresholds and sensitivity | `R/05_sensitivity.R` |
| Numerical checks | `R/06_numerical_checks.R` |
| Adult-M alternative + factorial (item F) | `R/07_adult_mortality_alternative.R` |
| Driver | `R/run_all.R` |
| Inputs | `data/v2/species_params.csv`, `gear_params.csv`, `interaction_matrix.csv`, `effort_history.csv` (moratorium), `effort_history_codforced.csv` (calibration device) |
| Models (`saveParams`) | `models/baseline_params.rds` (1980-85 steady state), `models/collapsed_state_params.rds` (observed-like 2000 community), `models/collapsed_2025_params.rds` (2025 of the moratorium run from 2000; cod recovered), `models/calibration_cache.rds`, `models/sensitivity/` |
| mizer issues | `notes/mizer-issues.md` |

`run_scenario(params, effort, years, initial = NULL, dt = 0.1, method = "euler", return_sim = FALSE)`:
`effort` = data frame with `year` and gear columns `cod`, `haddock`,
`silver_hake`, `plaice`, `pelagic` (piecewise constant; missing gears at
baseline) or a named constant vector with `years`. Returns year, species,
biomass, ssb, yield, F, n_juv and three resource-band rows. No side effects;
~3 s per 100 years.

## 2. v2 model: what changed from v1 and why

Same 7 species, life history, kernels (North Sea analogues), size grid
(120 bins, 1 mg-20 kg), defaults edition 3, and interaction matrix of 1s.

| Item | v1 | v2 | Justification / source |
|---|---|---|---|
| Resource abundance kappa | 1.4 | **3** | model zooplankton 32 g m^-2 < 1 mg and 16 g m^-2 at 1-100 mg vs Bundy 2004: copepods 30-34 (measured 1995-2001), large zooplankton 9 (independent) / 16 (Ecopath 1980-85) |
| Resource P/B | 2 w^-1/3 | **1.41 w^-0.22** | fitted to Bundy 2004 P/B: 8.4 yr^-1 at ~0.3 mg (C. finmarchicus), 3.04 yr^-1 at ~30 mg (euphausiids); gives 8.5 and 3.06 |
| Early-life background mortality | none | **Z/G = 0.5 x reference growth, tapered above 1 g**, all species | unmodelled predators of eggs/larvae (jellyfish, invertebrates, other fish); larval M/G ~0.5-2 (Houde 1997, unverified). Z/G = 1 made forage fish and plaice unsustainable (erepro >> 1); a purely size-based rule (Peterson & Wroblewski 1984) was rejected because mizer's allometric growth makes small/slow species' larvae grow much slower than cod larvae |
| Reproduction levels | cod 0.5, groundfish 0.75, forage 0.5 | **cod 0.1, groundfish 0.1, forage 0.284** | low imposed density dependence; forage level calibrated to the boom (Adekoya et al. 2026 needed R_max ~8x, level ~0.125) |
| Gears | cod, groundfish, pelagic | **cod, haddock, silver_hake, plaice, pelagic** | to follow observed groundfish declines |
| Other-groundfish F after 1985 | 0.35-0.55 then 0.15 | **effective F calibrated to survey ratios**: haddock 0.88 / 0.98, silver hake 1.54 / 1.33, plaice 2.40 / 2.88 (1986-2004 / 2005 on) | survey 1995-2004 / 1980-89: 0.61, 0.60, 0.45; 2005-12: 0.72, 0.73, 0.41. **Assumption**: these stand for fishing plus unmodelled mortality; no assessment F available |
| Cod hindcast forcing (calibration device only) | none | cod F 6.28 from 1994 | keeps cod near its survey ratio (model 0.07 vs 0.10) to create the observed post-collapse community without assuming why cod stayed low |

Calibration (`build_model()`): built at kappa = 3 unfished; growth matched to
age at maturity; background mortality recomputed after each growth change;
matchBiomasses / matchGrowth / tuneSteadyState iterated (with damping and
keeping the best fixed point with all erepro < 1). The steady-state solver
jumped between solutions (silver hake runaway roots), so calibration stopped
at **max biomass error 61 %**. Then the resource P/B was set (steady state
unchanged) and the hindcast calibrated with optim().

## 3. Test 1: baseline (1980-85), `results/baseline_*.csv`, Fig. 1

| Species | Target (g m^-2, above cut-off) | Model | Error |
|---|---|---|---|
| Cod | 2.0 | 3.22 | +61 % |
| Haddock | 1.2 | 1.35 | +13 % |
| Silver hake | 1.0 | 1.02 | +2 % |
| American plaice | 1.3 | 2.07 | +59 % |
| Herring | 1.5 | 1.40 | -7 % |
| Sand lance | 1.0 | 0.68 | -32 % |
| Capelin | 0.05 | 0.035 | -30 % |

Cod SSB 278 kt (survey 120 kt; peak 172 kt); cod yield 115 kt yr^-1
(landings 53.5 kt). Ages at maturity matched (within 0.03 yr). erepro
7.8e-4 (cod) to 0.12 (sand lance), all < 1. `isSteady()` TRUE; largest real
eigenvalue -0.017 yr^-1 (stable). Feeding levels 0.5-0.6.

**Pre-recruit budget of cod, 1 mg -> 1 g** (`results/baseline_prerecruit_budget.csv`):
survival 2.4 %, stage duration 0.39 yr; mortality integral 3.73 =
background 3.55 + modelled groundfish 0.16 + forage fish 0.010 + other 0.01.
Fraction of the cohort killed: background 96 %, groundfish 0.95 %, **forage
fish 0.29 %**. To 10 g: survival 1.1 %, forage 0.29 %, groundfish 1.8 %.
Haddock, silver hake, plaice: forage kill 0.27-0.59 %.

Resource level (abundance/capacity): 0.99 (1e-5 g), 0.98 (1 mg), 0.96 (10 mg),
0.86 (0.1 g), 0.63 (1 g), 0.49 (5 g); share of production eaten by the fish:
1-4 % for plankton < 10 mg, 14 % at 0.1 g, 37-51 % for benthos at 1-5 g.

## 4. Test 2: collapse and moratorium, `results/hindcast*.csv`, `results/pathways*.csv`, Figs 2, 2b

Effort: cod F 0.40 (1970-79), 0.45 (1980-85), 0.70 (1986-89), 1.10 (1990-92),
0.30 (1993), 0.02 from 1994; other gears as in Sec. 2; pelagic 0.10.

| Run | Cod ratio 1995-2004 | Forage ratio 1995-2004 | Forage 2005-12 | Herring | Haddock / hake / plaice | Pelagic:demersal 1995-2000 | Cod: years from 1993 to 50 % SSB |
|---|---|---|---|---|---|---|---|
| Observed (survey; Bundy) | 0.10 | 7.9 | 4.1 | 6.6 | 0.61 / 0.60 / 0.45 | 3.0 | not by 2025 |
| Calibration (cod forced) | 0.07 | 9.4 | 13.3 | 11.2 | 0.75 / 0.66 / 0.60 | 6.9 | (forced) |
| A: moratorium from 1970 | 3.6 | 2.1 | 1.6 | 1.6 | 0.17 / 0.11 / 0.12 | 0.7 | 1 (min SSB 0.45 in 1993) |
| B: moratorium from observed-like 2000 state | - | (state: x12-14) | - | - | - | - | 14 (7 from 2000) |

**Pathways (item D), baseline vs boom (2000 of the calibration run):**

| | Baseline | Boom |
|---|---|---|
| Resource level 0.1 mg / 1 mg / 10 mg / 0.1 g | 0.98 / 0.98 / 0.96 / 0.86 | 0.85 / 0.81 / 0.80 / 0.82 |
| Share of resource production eaten, same sizes | 1.5 / 2.0 / 3.8 / 14 % | 15 / 19 / 20 / 19 % |
| Cod feeding level at 0.01-1 g | 0.60 | 0.56-0.58 |
| Cod 1 mg -> 1 g: duration, survival | 0.39 yr, 2.41 % | 0.42 yr, 1.63 % |
| % of cod 1 mg-1 g killed by forage fish | 0.29 % | 4.3 % |

Rate-based decomposition of the survival change 1 mg -> 1 g: x0.67 overall =
x0.93 (boom mortality, baseline growth) and x0.73 (baseline mortality, boom
growth): **slower growth through the vulnerable window matters more than
direct predation**. To 10 g the net change is x0.94, because juvenile cod
also lose groundfish predators in the boom (mortality effect x1.31, growth
effect x0.71). Diagnostic runs from the 2000 state with forage predation on
cod off, plankton depletion off (resource held at baseline), or both: cod
regains 50 % SSB in 7 years in all four.

Comparison with Bundy (2004): forage fish ate ~7-10 % of small-zooplankton
production and 52 % (Ecopath) to ~200 % (independent biomass) of
large-zooplankton production in 1995-2000; the model's 19-20 % at 10-100 mg
under-represents this, partly because mizer forage Q/B (~2-3 yr^-1) is about
half of Ecopath's (4-7 yr^-1). So v2 may underestimate depletion of large
zooplankton by a factor 2-10.

**Forage biomass after the collapse (Frank et al. 2011).** In the calibration
run the boom does not fade (x13 in 2005-12 vs observed x4.1): with cod held
down and plankton only moderately depleted, nothing limits the forage fish.
In run A forage peaks at x4.7 (1995) and falls to x1.6 as cod recovers; with
elevated adult M (Sec. 9) it peaks at x9 around 2000 and settles at x5-6 by
the 2020s. **The model produces a forage decline only top-down (cod or
other predators recovering), not by forage fish exhausting their food.**

## 5. Test 3: bistability, `results/bistability_*.csv`, `results/hysteresis.csv`, Fig. 3

Cod F = 0, other gears at their post-2005 effective levels. From the
baseline and from the observed-like 2000 state, cod ends at 4.07x baseline
SSB in both (500 years). The cod-free community (forage x19, other groundfish
16 % of baseline, haddock 0.3 %) is invaded by cod at **+0.52 yr^-1**
(fitted while cod < 1e-3 of baseline). Hysteresis sweep (cod F 0 -> 2 -> 0):
equilibrium cod SSB 4.1 (F = 0), 2.4 (0.3), 1.5-1.7 (0.7-0.8), 1.0-1.25 (1.0),
0.15-0.6 (1.3) x baseline; cod collapses at F ~1.4 in both directions. At
F 0.9-1.3 the two branches differ by up to a factor 4 in cod SSB because
haddock, silver hake and plaice re-invade on the decreasing branch (where
cod is weak) and stay absent on the increasing one: path dependence in the
other groundfish, not cod-forage bistability. At F <= 0.8 the branches
coincide. **Caveat**: with the calibrated effective mortality held for
centuries, the other groundfish go extinct in most long-run equilibria, so
these equilibria describe mainly a cod + forage system.

## 6. Test 4: forage fishing, `results/forage_fishing_*.csv`, Figs 4, 4b

Main v2: from the 2025 state (cod already ~3.9x baseline SSB) no programme
changes recovery (years to 50 % = 0 everywhere). Constant-F equilibria at cod
F 0.02: forage F 0 / 0.5 / 1.0 / >= 1.5 gives cod SSB 4.1 / 3.3 / 2.8 / 2.7x
baseline, feeding level of 1-kg cod 0.59 / 0.52 / 0.48 / 0.47, cod weight at
age 5 1.24 / 1.09 / 0.99 / 0.97 kg, forage yield 0 / 96 (maximum) / 29 / ~0 kt
(forage extirpated at F >= 1.5).

What-if s_egg = 20 (not recalibrated; Sec. 7): status quo needs 50 years
from 2026 to 50 % SSB. Years to 50 % (`results/forage_fishing_grid_s20.csv`):

| Duration \ forage F | 0.25 | 0.5 | 1 | 2 |
|---|---|---|---|---|
| 5 yr | 10 | 7 | 6 | 6 |
| 10 yr | 10 | 7 | 6 | 6 |
| 20-40 yr | 10 | 7 | 6 | 6 |

Even the weakest programme tested (F 0.25 for 5 years) triggers recovery;
cod reaches ~3.9x baseline by 2100 in every programme (recovery persists).
Long programmes at F >= 1 push forage fish to < 1 % of baseline.

## 7. Test 5: thresholds and sensitivity, `results/sensitivity*.csv`, Fig. 5

`s_egg` changed in the calibrated model without recalibration, from the same
observed-like 2000 state:

| s_egg | Forage kill of cod 1 mg-1 g: baseline / boom | Cod survival 1 mg-1 g in boom | Years from 1993 to 50 % SSB | Invasion rate (yr^-1) | Cod equilibrium at baseline F, rel. to calibrated |
|---|---|---|---|---|---|
| 1 | 0.3 % / 4.3 % | 1.6 % | 14 | +0.52 | 0.99 |
| 2 | 0.6 % / 8.3 % | 1.4 % | 15 | +0.46 | 0.96 |
| 3 | 0.9 % / 12 % | 1.2 % | 15 | +0.41 | 0.92 |
| 5 | 1.4 % / 18 % | 0.8 % | 16 | +0.31 | 0.86 |
| 10 | 2.8 % / 31 % | 0.34 % | 18 | +0.13 | 0.62 |
| 20 | 5.4 % / 47 % | 0.06 % | 77 | -0.012 | 0.08 |
| 50 | 13 % / 68 % | 0.0003 % | never (200 yr) | -0.024 | ~0 |

Thresholds (log-interpolated, `results/sensitivity_thresholds.csv`):
**30-year failed moratorium at s_egg ~ 11.8; alternative stable state at
s_egg ~ 18.9.** At both, the 1980s cod state is not sustained by the same
parameters (it would need recalibration with a higher erepro).

One-at-a-time (main s_egg = 1): cod reproduction level 0.02-0.6, forage
reproduction level x0.5 / x2, background Z/G 0 / x0.5 / x1.5, resource P/B
x0.5 / x2: years from 1993 to 50 % SSB 12-16, invasion rate +0.45 to +0.66.
The background variants were recalibrated imperfectly (max errors 34 %,
123 %, 244 %).

## 8. Numerical robustness, `results/numerical_checks.csv`, Fig. S1

| Case | Forage ratio 1995-2004 | Cod survival 1 mg-1 g, boom | Run B years from 1993 to 50 % | Invasion rate |
|---|---|---|---|---|
| reference (dt 0.1, 120 bins, Euler) | 9.40 | 1.63 % | 14 | 0.522 |
| dt 0.025 | 9.41 | 1.60 % | 15 | 0.516 |
| TR-BDF2 | 9.46 | 1.59 % | 15 | 0.516 |
| 200 bins (recalibrated; max error 53 %) | 8.56 | 1.86 % | 14 | 0.517 |

## 9. Elevated adult natural mortality and the factorial (item F), `results/alt_adult_M*.csv`, Fig. 6

Natural mortality of cod >= 35 cm set to 0.8 yr^-1 from 1990 (VPA ages 5+,
1990-2004 mean; Mohn & Rowe 2012), real moratorium efforts otherwise.

| Adult M | Forage predation on cod | Plankton depletion | Cod SSB 2000-02 / 1980-85 | Forage 1995-2004 | Forage 2005-12 | Cod SSB 2025 / baseline |
|---|---|---|---|---|---|---|
| baseline | on | on | 4.87 | 2.1 | 1.6 | 3.9 |
| elevated | on | on | 0.74 | 7.1 | 6.9 | 1.29 |
| elevated | off | on | 0.81 | 6.9 | 6.1 | 1.34 |
| elevated | on | off | 0.79 | 7.1 | 5.9 | 1.25 |
| elevated | off | off | 0.86 | 6.9 | 5.4 | 1.31 |

Adult M reduces 2000-02 cod SSB by a factor 6.5; the two forage pathways
together by a further 13 % (~7 % of the log effect). Observed 2000-02 SSB was
0.06x, so v2 cod remains far more resilient than the real stock even with
seal-level M. With M kept at 0.8 after 2025, forage fishing lowers cod (2050
SSB 1.34x at status quo vs 0.40x with forage F 2 for 30 years); with M back
to baseline it changes nothing (cod already > 50 % of baseline).

## 10. Limitations and caveats

* **Cod is too resilient in both versions.** It needs F_eff ~6 to stay at
  its observed level, collapses only above F ~1.35, and survives adult M 0.8.
  The real stock collapsed under F ~0.7-1.1 and stayed low. Missing
  ingredients probably include declining size and age at maturity and
  condition, and higher juvenile mortality. Because model cod cannot be held
  down, the hypothesis is tested against an optimistic cod.
* **Baseline calibration is loose** (cod +61 %, plaice +59 %, sand lance
  -32 %); the steady-state solver jumped between solutions.
* **Other groundfish need very high effective mortality** (F 0.9-2.9) to
  follow the survey; held indefinitely it drives them extinct in long-run
  runs. Their real decline had other causes too, and the forage hypothesis
  applies to their larvae as well (forage fish kill 0.3-0.6 % of their
  1 mg-1 g stage at baseline).
* **Plankton depletion is probably underestimated**: mizer forage Q/B is
  half of Ecopath's, and one power-law resource cannot separate copepods,
  euphausiids and benthos.
* The background early-life mortality (Z/G 0.5) is density-independent and
  not itself predation by the modelled community; 96 % of cod pre-recruit
  deaths are in it. Its size dependence is tied to each species' reference
  growth (a modelling choice).
* The `s_egg` threshold runs are not recalibrated; at the thresholds the
  1980s baseline is no longer a steady state.
* Herring in v2 boom far above the survey (x11 vs x6.6) while sand lance and
  capelin carry less of the boom than the survey suggests.

## 11. Comparison with Adekoya et al. 2026

See `data/species_params_sources.md`. They used FishBase species-wide cod
(w_max 82.6 kg, l_mat 66.5 cm, age_mat 6.2), we use the 1970s-80s 4VsW stock
(13.3 kg, 42 cm, 4.5 yr). They needed forage R_max ~8x to get the boom; v2
needs a forage reproduction level of 0.28 (R_max ~3.5x) plus strong
suppression of the other groundfish.

## 12. Figures (v2; v1 figures in `figures/v1/`)

| Figure | File | Caption |
|---|---|---|
| 1 | `figures/fig1_baseline.png`, `.pdf` | v2 pre-collapse steady state. a, biomass above survey cut-offs vs targets (kt); b, size spectra and resource; c, growth vs FishBase von Bertalanffy; d, feeding level; e, cod mortality by source (background early-life, forage fish, groundfish, fishing, other); f, resource level by size. |
| 2 | `figures/fig2_collapse_moratorium.png`, `.pdf` | a, cod SSB in the calibration run (cod forced, to 2012), the moratorium from 1970 (A) and the moratorium from the observed-like 2000 state (B), with survey SSB; b, cod, forage and other groundfish; c, calibration run vs summer survey by species/group (1980-89 = 1); d, resource biomass bands. |
| 2b | `figures/fig2b_pathways.png`, `.pdf` | Pathways, baseline vs boom (2000): a, cod feeding level; b, cod specific growth; c, mortality of cod by forage fish; d, resource level; e, moratorium from 2000 with forage predation and/or plankton depletion switched off. |
| 3 | `figures/fig3_bistability.png`, `.pdf` | Bistability test at cod F = 0: a, cod SSB from two initial states; b, forage biomass; c, cod reintroduced into the cod-free community; d, equilibrium cod SSB vs cod F, up and down. |
| 4 | `figures/fig4_forage_fishing.png`, `.pdf` | Forage fishing in v2: a, cod SSB with 10-year programmes from 2026; b, years to 50 % (all 0); c-f, constant-F equilibria: cod SSB, feeding level of 1-kg cod, forage yield, cod weight at age 5. |
| 4b | `figures/fig4b_forage_fishing_strong_variant.png`, `.pdf` | What-if s_egg = 20: cod SSB for 10-year programmes and years to 50 % SSB by forage F and duration. |
| 5 | `figures/fig5_sensitivity.png`, `.pdf` | a, years from 1993 to 50 % SSB vs s_egg; b, invasion rate vs s_egg; c, implied % of cod 1 mg-1 g killed by forage fish at baseline and in the boom; d, other parameters. |
| 6 | `figures/fig6_adult_mortality.png`, `.pdf` | Factorial of adult M x forage predation x plankton depletion: a, cod SSB vs survey; b, forage biomass; c, forage fishing under elevated M. |
| S1 | `figures/figS1_numerical_checks.png`, `.pdf` | Cod SSB in the calibration run and run B with dt 0.025, TR-BDF2 and 200 size bins. |

## 13. What would be needed / next steps

1. A cod that can actually be held down by the observed F and M (time-varying
   maturation and condition, or a stronger juvenile bottleneck), before the
   forage feedback can matter.
2. Separate copepod, euphausiid and benthos resources (e.g. mizerMR) and forage
   consumption matched to Ecopath, to test whether large-zooplankton depletion
   (Bundy: 52-200 % of production eaten) starves juvenile cod enough.
3. ESS evidence on forage-fish predation on cod eggs and larvae to bound
   s_egg (the model needs ~12-19, field data suggest << 1-2).
