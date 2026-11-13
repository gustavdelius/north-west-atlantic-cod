# Eastern Scotian Shelf cod: does forage-fish "role reversal" explain the failed moratorium? Model results

*For the agents drafting the paper and the policy website. Everything here is
reproducible with `Rscript R/run_all.R` from the repository root (calibrations
are cached in `models/`; delete `models/calibration_cache.rds` and
`models/sensitivity/*.rds` to recalibrate from scratch, ~2-3 h on 8 cores).
Numbers come from the CSVs named in each section. Units: g m^-2 of shelf;
1 g m^-2 = 110 kt over the 1.1 x 10^5 km^2 of NAFO 4VsW.*

## 0. Headline (read this first)

1. **The hypothesis, implemented as size-based predation and competition in
   mizer with defensible parameters, does not reproduce the failed
   moratorium.** In the main model cod falls only to 30 % of baseline SSB by
   1993 under the historical fishing trajectory, recovers to 50 % of baseline
   within one year of the moratorium and exceeds baseline by 1996 (observed:
   SSB ~6 % of the 1980-85 mean in 2000-02, still low in 2025).
2. **There is no alternative stable state.** With identical parameters and
   cod F = 0, the baseline and the most-collapsed (1993) states converge to the
   same cod-dominated equilibrium (cod SSB 3.89x baseline); rare cod invade the
   cod-free community at +0.23 yr^-1; equilibrium cod SSB vs cod F is
   single-valued (no hysteresis; collapse threshold between F = 0.4 and 0.5).
   This holds in all 17 sensitivity variants.
3. **Why, quantitatively.** In mizer a forage fish kills a cod egg exactly as
   it kills a plankton particle of the same mass. At the calibrated forage
   biomass (2.5 g m^-2 above survey cut-offs, ~280 kt; 3.1 g m^-2 in total)
   forage fish kill only **2 %** of cod eggs and larvae (1 mg-0.1 g), and fish
   remove only ~1-3 % of plankton production at those sizes (resource level
   0.97-0.99), so neither egg predation nor
   competition is strong. Removing cod also releases haddock, silver hake and
   plaice, which then eat the forage fish: the cod-free equilibrium has
   **0.55x** the baseline forage biomass, not the observed ~5x. And unfished
   cod has a large compensatory reserve (equilibrium SSB 3.9x baseline).
4. **How strong the mechanism would have to be.** Raising the forage -> cod
   interaction `s_egg` (forage fish preferring cod eggs over equally sized
   plankton) delays recovery: `s_egg` = 30 (45 % of cod eggs/larvae eaten at
   baseline) gives a collapse to 5 % and 12 years to recover; `s_egg` = 100
   (87 % eaten) gives a collapse to 0.03 % and 90 years to 50 % SSB, i.e. a
   failed moratorium, **but even then the cod-free state is invadable
   (+0.12 yr^-1): a very slow transient, not an alternative stable state.**
   Field estimates of forage-fish predation on cod eggs (0.04-0.19 % by North
   Sea herring; a "considerable proportion", later revised down, by Baltic
   sprat) and the absence of a forage-recruitment relationship on the ESS
   (Swain & Mohn 2012) make `s_egg` = 30-100 implausible.
5. **Forage-fish fishing.** In the main model cod has recovered long before
   2026, so forage fishing cannot speed recovery; it only reduces cod food,
   growth and SSB (forage F = 1: equilibrium cod SSB -34 %, feeding level of
   1-kg cod 0.67 -> 0.55, weight at age 5 -25 %; F >= 1.5 extirpates forage
   fish). In the `s_egg` = 100 variant forage fishing does speed recovery: F = 1
   for 10 years cuts the time to 50 % SSB from 58 to 32 years (F = 0.5: 38
   years). Recovery then persists (one attractor), but programmes of F >= 1 for
   >= 10 years nearly extirpate the forage fish.
6. **The elevated-adult-mortality alternative fits the decline much better.**
   Natural mortality 0.8 yr^-1 for cod >= 35 cm from 1990 (VPA mean for ages
   5+, 1990-2004) reproduces the observed decline (model SSB 0.08x baseline in
   2000 vs ~0.06x observed in 2000-02) without any forage mechanism. Under that
   regime forage fishing cannot rescue cod (it declines faster: less food); if
   adult M returns to baseline in 2026, cod reaches 50 % SSB in 21 years
   without forage fishing and in 23-25 years with it.

**Acceptance tests.** Test 1 passed. Test 2 failed (collapse only to 30 %,
immediate recovery). Test 3 failed (no bistability or hysteresis; quantified
by recovery time and a positive invasion rate). Test 4 not applicable in the
main model (cod already recovered); illustrated in the `s_egg` = 100 variant.
Test 5 done: no variant gives bistability; only implausible `s_egg` gives
decades-long non-recovery. Numerical robustness confirmed.

## 1. Files

| What | Where |
|---|---|
| Model builder, `run_scenario()`, helpers | `R/functions.R` |
| Test 1 baseline | `R/01_build_model.R` |
| Test 2 hindcast + moratorium | `R/02_collapse_moratorium.R` |
| Test 3 bistability, invasion, hysteresis | `R/03_bistability.R` |
| Test 4 forage fishing (main model) | `R/04_forage_fishing_recovery.R` |
| Test 4 in the strong-egg-predation variant | `R/04b_forage_fishing_strong_variant.R` |
| Test 5 sensitivity | `R/05_sensitivity.R` |
| Numerical robustness | `R/06_numerical_checks.R` |
| Elevated adult-M alternative | `R/07_adult_mortality_alternative.R` |
| Driver | `R/run_all.R` (order 01, 02, 03, 04, 05, 04b, 06, 07) |
| FishBase extraction (internet; optional) | `R/00_fishbase_lookup.R`, cache in `data/fishbase/` |
| Inputs | `data/species_params.csv`, `data/gear_params.csv`, `data/interaction_matrix.csv`, `data/effort_history.csv` |
| Source and verified/unverified tag for every number | `data/species_params_sources.md` |
| Saved models (`saveParams`) | `models/baseline_params.rds` (1980-85 steady state); `models/collapsed_2025_params.rds` (end-2025 state of the hindcast: **not collapsed in this model**, cod 3.7x baseline); `models/calibration_cache.rds`; `models/sensitivity/*.rds` |
| Possible mizer issues | `notes/mizer-issues.md` |

`run_scenario(params, effort, years, initial = NULL, dt = 0.1, method = "euler", return_sim = FALSE)`:
`effort` is a data frame with `year` and columns `cod`, `groundfish`,
`pelagic` (piecewise constant from each listed year; missing gears held at
baseline) or a named constant vector with `years = c(start, end)`;
`initial` is NULL (state in `params`), a `MizerParams` or a `MizerSim` (its
last state). Returns a tidy data frame: year, species, biomass, ssb, yield,
F (fully selected, summed over gears), n_juv (numbers 1-10 g), plus species
"Resource" = plankton biomass < 0.01 g; g m^-2 and g m^-2 yr^-1. No side
effects; a 100-year run takes ~3 s.

## 2. Model description

* **Software:** mizer 3.4.0.9003, `defaults_edition(3)` (zero-padded FFT
  kernels, so planktivore kernels do not wrap around; van Leer flux;
  bin-averaged integrals); dt = 0.1 yr, semi-implicit Euler.
* **Species (7):** Atlantic cod; haddock, silver hake, American plaice (other
  groundfish); Atlantic herring, northern sand lance, capelin (forage fish).
  Mackerel omitted (seasonal migrant; survey shows no post-collapse increase).
* **Size grid:** 120 log-spaced bins from 1 mg (egg size, all species) to
  20 kg; resource down to ~1e-6 g.
* **Life history:** l_inf, l_mat, age_mat, a, b from FishBase records for the
  NW Atlantic / 4VsW where possible (`data/species_params_sources.md`). Growth
  calibrated so each species reaches w_mat at age_mat (`matchGrowth()`);
  f0 = 0.6, fc = 0.2 (defaults).
* **Kernels:** lognormal; beta, sigma from the North Sea mizer model
  (Blanchard et al. 2014): cod beta 66, haddock 558, silver hake 22 (as
  whiting), plaice 113, herring 280,540 (sigma 3.2), sand lance 398,849;
  capelin beta 1e4 (assumption); cod sigma 2 (mizer default; North Sea 1.3).
  With beta ~1e4-4e5, forage fish eat 1 mg-0.1 g fish eggs/larvae alongside
  plankton.
* **Interaction matrix:** all 1 (mizer default). `s_egg` (forage -> cod) is
  the mechanism-strength parameter (1 in the main model).
* **Resource:** single plankton/benthos spectrum, lambda 2.05, cut-off 10 g,
  semichemostat; kappa = 1.4; r_pp = 2 (plankton P/B ~20 yr^-1 at 1 mg,
  2 yr^-1 at 1 g; mizer default 10 gives 100 yr^-1 at 1 mg).
* **Reproduction:** Beverton-Holt, reproduction levels cod 0.5, other
  groundfish 0.75, forage 0.5 (set after calibration; they do not move the
  steady state). Resulting erepro: 6e-5 (cod) to 0.01 (sand lance), all < 1.
* **External mortality:** default z0 = 0.6 w_inf^(-1/3) (0.025 yr^-1 for cod).
* **Fishing:** three gears, catchability 1 (effort = F on fully selected
  sizes), logistic length selectivity: `cod` (L50 40 cm); `groundfish`
  (haddock 35, silver hake 25, plaice 30 cm); `pelagic` (herring 20, sand
  lance 10, capelin 11 cm). Baseline efforts 0.40 / 0.30 / 0.10.
* **Calibration (`build_model()`):** built unfished at kappa = 3; growth
  matched; single-species steady states; baseline fishing switched on;
  continuation in kappa 3 -> 1.7 -> 1.4 (given gamma rescaled by
  kappa_old/kappa_new each step); iterate `matchBiomasses()` /
  `matchGrowth()` / `tuneSteadyState()` until biomasses are within 3 %; reset
  reproduction levels. Newton `tuneSteadyState()` falls back to projection
  when it fails (`notes/mizer-issues.md`).

**Departures from mizer defaults and why**

| Choice | Default | Used | Justification |
|---|---|---|---|
| defaults edition | 1 | 3 | non-circular kernels for planktivores with beta ~1e5; less numerical diffusion |
| r_pp | 10 | 2 | realistic plankton P/B; sensitivity 1-10 |
| kappa | 1e11 (absolute units) | 1.4 (g m^-2 scale) | calibration converged with all erepro < 1; kappa = 1 and 2 did not converge to targets (Sec. 7) |
| cod sigma | 2 (North Sea model 1.3) | 2 | broad cod diet; damps cohort cycles |
| beta, sigma | 30, 2 | North Sea analogues | published diet-based kernels |
| reproduction levels | 0 (R_max = Inf) | 0.5 / 0.75 / 0.5 | weaker cod regulation makes unfished cod extirpate prey (Sec. 10); sensitivity 0-0.75 |
| forage -> cod interaction | 1 | 1 (main) | purely size-based; 3-100 in sensitivity |

## 3. Test 1: baseline (1980-85), `results/baseline_*.csv`, Fig. 1

| | Target | Model |
|---|---|---|
| Cod biomass > 100 g | 2.0 g m^-2 = 220 kt (q-adj. survey total 259 kt) | 2.02 (total 229 kt) |
| Haddock > 100 g | 1.2 (survey 130 kt) | 1.19 |
| Silver hake > 20 g | 1.0 (survey 109 kt) | 0.99 |
| American plaice > 100 g | 1.3 (survey 142 kt) | 1.30 |
| Herring > 20 g | 1.5 (survey 54-309 kt) | 1.48 |
| Sand lance > 2 g | 1.0 (survey 18-108 kt) | 0.98 |
| Capelin > 5 g | 0.05 | 0.049 |
| Cod SSB (not fitted) | 120 kt (survey mean 1980-85; peak 172 kt in 1984) | **179 kt** |
| Cod yield (not fitted) | 53.5 kt yr^-1 (landings 1980-85) | **74 kt yr^-1** (+38 %) |
| Age at maturity (yr) | 4.5, 3, 2, 6, 3.5, 2, 2.5 | all within 0.02 |

* `isSteady()` TRUE; max relative biomass drift 7e-8 yr^-1; tuneSteadyState
  attractor "fixed_point"; linearly stable (largest real eigenvalue
  -0.072 yr^-1, `results/baseline_diagnostics.csv`).
* Feeding levels 0.60-0.66 at all sizes; growth close to FishBase von
  Bertalanffy curves (cod a little slower at old ages).
* Cod diet (0.5 kg to w_inf): 70 % fish (herring 18 %, plaice 17 %, sand lance
  10 %, silver hake 10 %, cod 8 %, haddock 6 %, capelin 0.7 %) and 30 %
  resource (benthos/large zooplankton). Forage fish are 29 % of adult cod diet.
* Forage fish kill 2.0 % of cod eggs/larvae (1 mg-0.1 g; mortality integral
  0.020); groundfish kill 4.8 %. Forage fish are the main predators of 1-10 mg
  cod (herring ~0.3 yr^-1), but the 1 mg -> 0.1 g stage lasts only 0.17 yr.
* Cod cause 0.27 of the 0.43 yr^-1 predation mortality of mature herring.
* Resource level 0.98-0.99 at 1e-5-1e-3 g, 0.97 at 0.01 g, 0.87 at 0.1 g,
  0.63 at 1 g, 0.47 at 5 g: plankton barely depleted, benthos substantially.

## 4. Test 2: collapse and moratorium, `results/hindcast*.csv`, Fig. 2

Effort (`data/effort_history.csv`, stylised from Fanning et al. 2003 landings
and survey SSB): cod F 0.40 (1970-79), 0.45 (1980-85), 0.70 (1986-89), 1.10
(1990-92), 0.30 (1993; closure 1 Sept), 0.02 from 1994 (bycatch; Mohn & Rowe
2012 report ~0.035 falling to 0.01); groundfish 0.30, 0.35, 0.45, 0.55, 0.30,
then 0.15; pelagic 0.10 throughout. Variant: cod F = 0 from 1994.

| Quantity | Model (bycatch / zero) | Observed |
|---|---|---|
| Lowest cod SSB / baseline | 0.30 (1993) / same | ~0.03-0.06 (1997-2002 vs 1980-85) |
| Cod SSB 2000-02 / 1980-85 | 2.8 / 3.0 | 0.06 |
| Years from 1993 to 50 % of baseline SSB | 1 / 1 | not reached by 2025 |
| Cod SSB 2025 / baseline | 3.7 / 4.1 | ~0.1 (survey) |
| Peak forage biomass 1993-2025 / baseline | 1.50 / 1.53 | ~5 (survey 1995-2004 vs 1980s); ~10 (Frank et al. 2011) |
| Cod yield 1980-85 | 78 kt | 53.5 kt |

Forage-fish kill of cod eggs/larvae: 2.0 % (1975) -> 3.7 % (1993) -> 0.7 %
(2025). Plankton biomass (< 0.01 g) changes by < 0.1 % over the hindcast.
**Test 2 fails.**

**Forage fish over the decades after the collapse (the Frank et al. 2011
question).** Forage biomass rises to 1.5x baseline by 1993 (herring 1.9x),
falls to 0.7x by 2000 as recovering cod and briefly released haddock/plaice eat
them, then rises to 1.3x by 2015-2025 (sand lance 2.8x, capelin 2.5x, herring
declining towards extinction as cod reaches 3x baseline). So the model makes a
rise and fall of forage fish, but (i) the rise is ~1.5x, not 5-10x, and (ii)
the fall is top-down (cod recovering), not forage fish exhausting zooplankton:
the plankton is never depleted. In the elevated-adult-M alternative (Sec. 9)
forage fish peak at 1.6x in 1993 and fall to 0.6x by 2025 because haddock
(2.4x), silver hake (1.2x) and plaice (1.2x) increase and eat them; again not
zooplankton exhaustion. **The model cannot produce a zooplankton-limited
forage boom-and-bust.** That would require forage fish to be the dominant
plankton consumers, which is incompatible with this calibration (single
resource spectrum, gamma tied to observed forage biomass).

## 5. Test 3: bistability, `results/bistability_*.csv`, `results/hysteresis.csv`, Fig. 3

* **Two starts, identical parameters**, cod F = 0, groundfish 0.15, pelagic
  0.10, 500 years: from the baseline and from the 1993 hindcast state (cod SSB
  0.30x baseline) both end at cod SSB 3.89x baseline (forage 1.35x). Two
  attractors: **no**.
* **Invasion test:** the community with cod exactly absent equilibrates in 125
  years (haddock 3.0, plaice 2.2, silver hake 1.3, herring 1.2, sand lance 0.46
  g m^-2; forage total 0.55x baseline). Cod reintroduced at 1e-6 of baseline
  grows at **+0.23 yr^-1** (doubling ~3 yr) and reaches baseline biomass in
  ~60 years. Forage fish kill 1.4 % of cod eggs/larvae in that community.
* **Hysteresis sweep** (cod F 0 -> 2 -> 0 in steps of 0.1, each step run to
  equilibrium or 400 years; in the decreasing sweep cod is floored at 1e-3 of
  baseline biomass so that numerical near-extinction at high F cannot
  masquerade as an alternative state): branches coincide. Equilibrium cod SSB
  / baseline: 3.89 (F = 0), 2.7 (0.1), 1.7 (0.2), 1.0 (0.3), 0.38 (0.4), 1.3 %
  and still falling at 0.5, extinct for F >= 0.6. **Bistable range of cod F:
  none.** (Other gears at post-1993 levels, which is why F = 0.4 gives 0.38
  rather than the baseline 1.0.)
* At the cod-dominated F = 0 equilibrium herring falls to ~1e-7 of baseline
  (Sec. 10).

## 6. Test 4: recovery by fishing forage fish, `results/forage_fishing_*.csv`, Figs 4, 4b

**Main model.** From the 2025 state (cod 3.7x baseline) raising pelagic F to
0.25-3 for 5-30 years has no recovery to accelerate (years to 50 % = 0 in all
cells; Fig. 4b panel uninformative by construction). Effects: a temporary
drop in cod SSB (to 2.3-3.5x baseline) and, for F >= 1.5 over >= 10 years,
near-extirpation of forage fish (minimum 1e-3 to 1e-8 of baseline). Forage
yield during programmes: 36 kt yr^-1 (status quo) to 312 kt yr^-1 (F = 3,
5 years).

Constant-F equilibria (`results/forage_fishing_equilibria.csv`), cod F = 0.02:

| Forage F | Cod SSB / baseline | Feeding level, 1-kg cod | Cod weight at age 5 | Forage yield |
|---|---|---|---|---|
| 0 | 3.88 | 0.67 | 1.24 kg | 0 |
| 0.1 | 3.62 | 0.66 | 1.19 kg | 34 kt |
| 0.5 | 3.03 | 0.60 | 1.05 kg | 88 kt (maximum) |
| 1.0 | 2.56 | 0.55 | 0.92 kg | 59 kt |
| >= 1.5 | 2.29 | 0.51 | 0.84 kg | ~0 (forage extirpated) |

With cod F = 0.40 instead, forage F >= 0.5 extirpates forage fish and cod SSB
falls to 3 % of baseline: in this model cod depends on forage fish as food.

**Strong-egg-predation variant, `s_egg` = 100** (87 % of cod eggs/larvae
eaten by forage fish at baseline; implausible, used to show what would happen
if the mechanism were that strong). The moratorium fails (cod SSB 0.2 % of
baseline in 2025); status quo (pelagic F 0.1): 58 years from 2026 to 50 % of
baseline SSB. Years to 50 % (`results/forage_fishing_grid_s100.csv`):

| Duration \ forage F | 0.25 | 0.5 | 1 | 2 |
|---|---|---|---|---|
| 5 yr | 53 | 46 | 37 | 32 |
| 10 yr | 49 | 38 | 32 | 31 |
| 20 yr | 42 | 34 | 32 | 31 |
| 40 yr | 39 | 34 | 32 | 31 |

The response is graded, not a threshold: any forage fishing speeds recovery,
with diminishing returns above F ~1 or ~10 years (floor ~31 years, set by
cod's own growth). Recovery persists after the programme (one cod attractor).
Programmes with F >= 1 for >= 10 years push forage fish below 0.1 % of
baseline, and the system then settles with cod at 3.2x rather than 1.9x
baseline and forage fish effectively lost (`cod_ssb_2200_rel`).

## 7. Test 5: sensitivity, `results/sensitivity.csv`, Fig. 5

Each variant is separately calibrated to the same 1980-85 baseline, then run
through the hindcast plus 200 years of moratorium, the cod-free invasion test
and an F = 0 extinction check.

| Variant | Eggs/larvae eaten by forage (baseline) | Min cod SSB / baseline | Years 1993 -> 50 % | Invasion rate (yr^-1) | Alt. state | Lost at F = 0 |
|---|---|---|---|---|---|---|
| main (s_egg 1, r_cod 0.5, r_for 0.5, r_pp 2, kappa 1.4) | 2.0 % | 0.30 | 1 | 0.23 | no | herring |
| s_egg = 3 | 5.8 % | 0.28 | 2 | 0.23 | no | herring |
| s_egg = 10 | 18 % | 0.20 | 2 | 0.23 | no | herring |
| s_egg = 30 | 45 % | 0.049 | 12 | 0.21 | no | herring |
| s_egg = 100 | 87 % | 0.0003 | 90 | 0.12 | no | none |
| repro_cod = 0 | 2.0 % | 0.27 | 2 | 0.20 | no | haddock, plaice, herring |
| repro_cod = 0.25 | 2.0 % | 0.28 | 2 | 0.22 | no | herring |
| repro_cod = 0.75 | 2.0 % | 0.32 | 1 | 0.18 | no | herring |
| repro_forage = 0.25 | 2.0 % | 0.31 | 1 | 0.23 | no | herring |
| repro_forage = 0.75 | 2.0 % | 0.30 | 1 | 0.23 | no | none |
| r_pp = 1 / 5 / 10 | 2.0 % | 0.30 | 1 | 0.23 | no | herring |
| kappa = 1 (calibration error up to 66 %) | 2.6 % | 0.32 | 1 | 0.21 | no | herring |
| kappa = 2 (calibration error up to 343 %) | 0.8 % | 0.26 | 2 | 0.22 | no | herring |
| s_egg 10, r_cod 0, r_for 0.25 | 18 % | 0.16 | 3 | 0.17 | no | haddock, plaice, herring |
| s_egg 30, r_cod 0, r_for 0.25 | 45 % | 0.025 | 24 | 0.15 | no | haddock, herring |

The result (no alternative state, fast recovery) is robust to the
reproduction levels, plankton productivity and kappa; only the egg-predation
strength matters, and decades-long non-recovery needs forage fish to eat
about half or more of cod eggs and larvae at the pre-collapse baseline. Even
at `s_egg` = 100 the invasion rate stays positive; a linear extrapolation of
the `s_egg` trend reaches zero only near `s_egg` ~200 (> 95 % of eggs eaten;
not tested). The kappa = 1 and 2 variants did not reach the biomass targets,
so those rows compare differently calibrated communities.

## 8. Numerical robustness, `results/numerical_checks.csv`, Fig. S1

| Case | Min cod SSB / baseline | 50 % recovery year | SSB 2025 / baseline | Invasion rate |
|---|---|---|---|---|
| reference (dt 0.1, 120 bins, Euler) | 0.301 | 1994 | 3.72 | 0.2304 |
| dt = 0.025 | 0.296 | 1994 | 3.72 | 0.2306 |
| TR-BDF2 (second order in time) | 0.295 | 1994 | 3.72 | 0.2306 |
| 200 size bins (recalibrated; biomass error up to 38 %) | 0.330 | 1994 | 3.24 | 0.227 |

Conclusions unchanged. The 200-bin model did not fully reach the biomass
targets, which explains its different unfished level.

## 9. Alternative hypothesis: elevated adult natural mortality, `results/alt_adult_M*.csv`, Fig. 6

External mortality of cod >= 35 cm raised so that their natural mortality is
0.8 yr^-1 from 1990 (VPA M ages 5+, mean 1990-2004; Mohn & Rowe 2012). A
time-varying parameter change, hence not one of the fishing-only scenarios.

* Hindcast: cod SSB 0.11x baseline in 1993, 0.08x in 2000, 0.02x in 2010,
  0.002x in 2025 (observed 2000-02 ~0.06x; observed M fell to ~0.36-0.6 after
  2005 and SSB rose temporarily to 64 kt in 2009, which this constant-M run
  does not include).
* Forage fish: 1.6x baseline in 1993, 0.6x by 2025.
* Forage fishing from 2026 with M kept at 0.8: no recovery in any programme;
  more forage fishing makes cod decline faster (2125 SSB 1e-9x at status quo vs
  2e-11x at F = 2 for 100 years).
* With M back to baseline in 2026: 50 % recovery in 21 years at status quo,
  23-25 years with forage fishing (it slows recovery by reducing cod food).

## 10. Limitations and caveats

* **Weak forage release.** Removing cod lets haddock, silver hake and plaice
  increase and eat the forage fish, whereas on the ESS they declined too
  (survey 1995-2004 / 1980s: 0.61, 0.60, 0.45). Our post-1993 groundfish F of
  0.15 is an assumption; their real decline (cold period, seals, low
  condition) is not represented.
* **Unfished cod extirpates herring** (and, with r_cod <= 0.25, haddock and
  plaice): apparent competition with full spatial overlap (all interactions 1)
  and moderate herring compensation. repro_forage = 0.75 removes it.
* **Baseline cod SSB and yield are 50 % and 38 % above the 1980-85
  observations** (cod biomass target from q-adjusted survey totals).
* **Collapse depth missed** (0.30 vs ~0.05). Real 1990-92 F may exceed the
  stylised 1.1, but the large compensatory reserve of model cod means deep
  collapses rebuild within years at F ~ 0.
* One resource spectrum for plankton and benthos; constant default external
  mortality; no temperature, seals, maturation changes or immigration;
  capelin's cold-driven appearance not modelled.
* mizer eggs grow from 1 mg immediately; the non-growing egg stage (2-3 weeks)
  is not represented. This shortens exposure to egg predators by perhaps a
  factor 2, far less than the factor 15-50 in `s_egg` needed for
  decades-long non-recovery.
* Forage-fish biomass targets are order-of-magnitude assumptions (pelagic
  species poorly sampled by the bottom-trawl survey).
* `s_egg` > 1 means forage fish prefer cod eggs over equally sized plankton;
  values far above 1 are not defensible and are used only to measure how
  strong the mechanism would need to be.
* The kappa sensitivity rows and the 200-bin model are imperfectly calibrated.

## 11. Comparison with Adekoya et al. 2026 (ESS mizer model)

Read via `literature/empirical_targets.md` (nothing from their repository was
downloaded or run). Agreements: region and survey strata; maturity size and
age of haddock, silver hake, plaice, herring, capelin; length-weight
parameters. Differences: their cod uses FishBase species-wide values (w_max
82.6 kg, l_mat 66.5 cm, age_mat 6.2 yr), ours the 1970s-80s 4VsW stock (w_inf
13.3 kg, l_mat 42 cm, age_mat 4.5 yr); their sand lance matures smaller
(8.75 cm, 1.5 yr). They needed forage-fish R_max ~8x the steady-state value to
reproduce the forage boom, consistent with our finding that the boom does not
emerge from the size-based food web alone.

## 12. Figures

| Figure | File | Caption |
|---|---|---|
| 1 | `figures/fig1_baseline.png`, `.pdf` | Pre-collapse (1980-85) steady state. a, modelled vs observed biomass above survey cut-offs (kt; observed = q-adjusted survey 1980-85 for groundfish, assumptions for forage fish); b, biomass size spectra and resource; c, modelled growth (solid) vs von Bertalanffy curves from FishBase parameters (dashed); d, feeding level; e, cod diet by cod size; f, mortality rate of cod by source and size. Data: `results/baseline_*.csv`. |
| 2 | `figures/fig2_collapse_moratorium.png`, `.pdf` | Historical scenario 1970-2025 and continuation. a, stylised fishing mortality by gear; b, cod SSB relative to baseline (lines: model with bycatch F = 0.02 or F = 0 after 1993) and survey SSB (points, Fanning et al. 2003, scaled to the model's 1980-85 level); c, cod, forage fish and other groundfish relative to baseline; d, individual species; e, % of cod eggs and larvae (1 mg-0.1 g) eaten by forage fish; f, modelled cod yield vs landings. Data: `results/hindcast*.csv`, `results/observed_cod_ssb.csv`. |
| 3 | `figures/fig3_bistability.png`, `.pdf` | Bistability test at cod F = 0 (other gears at post-1993 levels). a, cod SSB over 500 years from the baseline and from the most-collapsed (1993) state; b, forage biomass in the same runs; c, growth of cod reintroduced at 1e-6 of baseline into the cod-free equilibrium; d, equilibrium cod SSB vs cod F for increasing (filled) and decreasing (open) F; dotted line, baseline F. Data: `results/bistability_*.csv`, `results/hysteresis.csv`. |
| 4 | `figures/fig4_forage_fishing.png`, `.pdf` | Forage-fish fishing in the main model. a, cod SSB after 10-year programmes starting 2026 (shaded); b, years to 50 % of baseline SSB by intensity and duration (all 0: cod already recovered); c-f, constant-forage-F equilibria for cod F = 0.02 (orange) and 0.40 (blue): cod SSB, feeding level of 1-kg cod, forage yield, cod weight at age 5. Data: `results/forage_fishing_*.csv`. |
| 4b | `figures/fig4b_forage_fishing_strong_variant.png`, `.pdf` | Forage fishing in the implausibly strong egg-predation variant (s_egg = 100). a, cod SSB for 10-year programmes; b, years from 2026 to 50 % of baseline SSB. Data: `results/forage_fishing_grid_s100.csv`, `results/forage_fishing_trajectories_s100.csv`. |
| 5 | `figures/fig5_sensitivity.png`, `.pdf` | Sensitivity of a, years from 1993 to 50 % recovery and b, growth rate of rare cod in the cod-free community (< 0 would mean an alternative stable state) to egg-predation strength s_egg, cod and forage reproduction levels, plankton replenishment r_pp and resource coefficient kappa. Data: `results/sensitivity.csv`. |
| 6 | `figures/fig6_adult_mortality.png`, `.pdf` | Elevated adult natural mortality (M = 0.8 for cod >= 35 cm from 1990). a, hindcast with and without elevated M vs survey SSB; b, forage-fishing programmes from 2026 with adult M kept at 0.8 or returned to baseline. Data: `results/alt_adult_M*.csv`. |
| S1 | `figures/figS1_numerical_checks.png`, `.pdf` | Cod SSB in the key scenario with reference numerics, dt = 0.025, TR-BDF2 time stepping and a 200-bin (recalibrated) grid. Data: `results/numerical_checks*.csv`. |

## 13. Next steps

1. Make other-groundfish dynamics after 1993 realistic (drive all gears with
   landings-derived F, or add the post-1990 mortality of all large demersals)
   before judging forage release.
2. Split the resource into plankton and benthos (e.g. mizerMR) so forage fish
   can dominate plankton consumption without inflating fish-on-fish predation;
   then re-test competition-driven depensation and a zooplankton-limited
   forage bust.
3. Represent the non-growing egg stage and use ESS evidence to bound `s_egg`.
4. Factorial design combining elevated adult M (seals) with the forage
   mechanism, as Adekoya et al. did for seals.
