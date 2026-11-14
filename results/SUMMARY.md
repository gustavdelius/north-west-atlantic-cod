# Eastern Scotian Shelf cod: can forage-fish "role reversal" explain the failed moratorium? Model results (v1, v2, v3)

*For the agents drafting the paper and the policy website. The main model is
**v3** (`R/*.R`, `results/`, `figures/`, `models/`; run `Rscript R/run_all.R`).
v1 and v2 are kept unchanged in `R/v1/`, `R/v2/` and the matching
subfolders of `results/`, `figures/`, `models/` (their own write-ups:
`results/v1/SUMMARY.md`, `results/v2/SUMMARY.md`). Units: g m^-2 of shelf;
1 g m^-2 = 110 kt over the 1.1 x 10^5 km^2 of NAFO 4VsW. Sources and
verified/unverified tags: `data/species_params_sources.md`. Possible mizer
issues: `notes/mizer-issues.md`.*

**s is not supported by data.** v3 rests on one explicit assumption, the
early-life vulnerability factor s: forage fish eat the eggs, larvae and small
juveniles of the four groundfish s = 20 times more readily than plankton of
the same size. It is the assumption under test, chosen to make forage fish
cause 3-5 % (here 5.9 %) of cod deaths between 1 mg and 1 g at 1980s forage
abundance.

## Claims the paper may and may not make

**May (with the model's caveats):**

1. In a seven-species size-spectrum model calibrated to 1980-85 survey
   biomasses (all within 1 %), cod landings (57 vs 53.5 kt), ages at
   maturity and Scotian Shelf plankton data, the documented fishing history
   alone does **not** reproduce the failed recovery: cod falls to 0.26 of
   its 1980-85 SSB in 1993 (observed ~0.2-0.4) but is back above 50 % by
   1995 and at 2.2x the 1980s level in 1995-2004 (observed 0.10). This holds
   for every recalibrated s from 1 to 40 (0.3-11 % of cod early-life deaths)
   and every forage reproduction level from 0.05 to 0.9 (sensitivity map).
2. With s = 20 the model has a genuine alternative stable state: the
   community without cod at cod F = 0 has forage fish at ~19x baseline,
   no haddock, silver hake or plaice, and rare cod cannot invade it
   (growth rate -0.010 /yr, R^2 0.99). The observed post-collapse community
   does **not** lie in its basin in the model: from the modelled collapsed
   2025 state cod recovers (in 37-39 years, set by how deep the collapse
   was, not by forage fish).
3. Raising adult cod natural mortality to 0.8 /yr from 1990 (the documented
   post-collapse M; an alternative hypothesis, not a fishing scenario)
   reproduces the cod decline (1995-2004 ratio 0.08 vs 0.10). While adult M
   stays at 0.8, no forage-fishing programme tested lets cod recover; when it
   returns to baseline, cod needs ~39 years from its 2025 level, and the
   forage mechanism changes that by about one year.
4. Forage fishing does not speed cod recovery from the modelled collapsed
   2025 state; it slows it by 2-4 years (less food for cod), and forage
   F >= 0.5 for 10 years or more removes forage fish almost entirely. From
   the model's alternative state (or from an imposed x8 forage boom with cod
   at 1 % of its 1980s SSB) cod never recovers under the status quo, and
   forage fishing restores it persistently within 14-20 years (from the
   alternative state: F >= 0.75 for 10 years, F >= 0.5 for 15 years or F 2
   for 5 years; from the imposed boom: F 0.5 for 10 years). This is a
   conditional statement about the mechanism, not a forecast.
5. The trap is conditional: with s = 20 it captures cod only when an x8
   forage boom coincides with cod at ~1 % of its 1980s SSB; at the survey's
   post-collapse levels (cod 4-10 %) cod recovers in 4-9 years even with the
   boom imposed. A forage share of ~6 % of cod early-life deaths costs only
   x0.8 in pre-recruit survival at 1980s forage abundance; what holds cod in
   the alternative state is a ~1000-fold survival cut together with the loss
   of the other groundfish.

**May not:**

1. That s = 20 (or any value) is supported by data. It is the assumption
   under test; field estimates of forage-fish predation on cod eggs and larvae
   are far lower (v2 summary, Sec. 6).
2. That the model reproduces the post-collapse community: the forage boom is
   x1.4 (documented F) or x1.8 (with elevated adult M) against x7.9 in the
   survey; haddock, silver hake and plaice stay level or increase (model
   0.9-1.9) instead of falling to 0.45-0.61.
3. That the forage mechanism is ruled out for the real ecosystem. The model
   cannot produce the observed boom with plausible fishing, so it cannot test
   the mechanism at the boom magnitude that actually occurred; it shows only
   that the boom does not arise endogenously in this model structure.
4. Quantitative recovery times or a policy recommendation on forage fishing.
   The v3 community is fragile: long-run equilibria away from the 1980s point
   lose species (cod collapses at equilibrium cod F 0.5, below the realistic
   0.7-1.1; other groundfish go extinct when cod is 4-7x baseline). The
   website scenario grid was therefore not produced (Sec. 10).
5. That v1 or v2 results are the main results.

**Acceptance tests (v3).** 1 passes on every calibration target (biomasses,
yield, maturity, erepro) but **fails** the cod collapse F (0.5 vs 0.7-1.1) and
is only marginally steady (17 % drift over 100 years); 2 **fails** (cod
recovers within 2 years of the closure under documented fishing; boom x1.4);
3 finds a weak alternative stable state (invasion -0.010 /yr) that no
hindcast reaches; 4: forage fishing does not help from the modelled 2025
state but releases cod from the alternative state; 5 done (map below);
numerical check passed. Policy grid not produced.

## 1. Checking the arithmetic behind the threshold

The coordinator's reading of the v2 thresholds was: s ~ 12 / 19 corresponds
to forage fish causing 3-5 % of cod 1 mg-1 g deaths at 1980s forage
abundance, and a trap needs a 5-10x cut in pre-recruit survival.

* **Share: correct.** In v2 (s raised without recalibration) forage fish
  killed 2.8 % (s = 10) and 5.4 % (s = 20) of the cohort, with 97.6 % of the
  cohort dying overall, i.e. 2.9-5.5 % of deaths. In the recalibrated v3 at
  s = 20 the share is **5.9 %** (5.8 % of the cohort; haddock 5.7 %, silver
  hake 6.1 %, plaice 11.6 %; `results/baseline_prerecruit_budget.csv`).
* **Survival cut: larger than 5-10x.** At baseline the forage term is a
  mortality integral of 0.22 over 1 mg-1 g, so forage predation costs only
  x0.80 in survival. In v2 a 30-year failure needed survival cut ~x10 and an
  alternative state ~x30. In v3 the cod-free alternative state has cod
  survival 1 mg-1 g of 1.9e-5 against 0.021 at baseline (**x1/1000**;
  forage fish kill 61 % of the cohort there) and rare cod still only just
  fails to invade (-0.010 /yr), because adult cod in that state have abundant
  food (feeding level of 1 kg cod 0.85 vs 0.52) and no groundfish competitors or
  predators. A 5-10x cut corresponds at s = 20 to a forage boom of ~x8-11
  acting alone (survival factor exp(-0.22 x (boom - 1))); it is not enough
  for a trap in this model.
* **And without recalibration the baseline breaks** (v2 at s >= 10), which is
  why v3 recalibrates.

## 2. v3 design

Same seven species, kernels, grid (120 bins), plankton (kappa 3,
P/B = 1.41 w^-0.22; Bundy 2004), early-life background mortality (Z/G = 0.5)
and groundfish reproduction level (0.1) as v2. Changes:

| Item | v3 | Why |
|---|---|---|
| Assumption under test | forage -> groundfish (all four) interaction **s = 20** | 5.9 % of cod early-life deaths at baseline; all four groundfish because nothing singles out cod |
| Calibration | Newton solution of all seven biomass targets at once + growth rescaling, s stepped 5 -> 10 -> 20 (`calibrate_v3n()`) | the matchBiomasses loop oscillates; `matchGrowth()` wrecks the state (mizer issue #4) |
| Cod target | 1.6 g m^-2 > 100 g (was 2.0) | yield at baseline F 0.40 = landings |
| Fishing | documented cod F only (0.40, 0.45, 0.70, 1.10, 0.30, 0.02 from 1994); haddock / hake / plaice 0.30-0.55, 0.20 from 1994 | no artificial cod F after 1994, no 1.5-2.9 effective F |
| Forage reproduction level | 0.171, fitted to the boom but bounded to keep the 1980s state stable (unstable below 0.12) | boom target x7.9 unreachable; fit sits on the bound |

## 3. Test 1: calibration quality (`results/calibration_quality.csv`, Fig. 1)

| Criterion | Target | v3 | |
|---|---|---|---|
| Biomasses (7 species) | within 15 % | all within **0.6 %** | pass |
| Cod yield at F 0.40 | 53.5 kt +-25 % | **57.3 kt** | pass |
| Age at maturity | FishBase-derived | within 0.5 % | pass |
| erepro | < 1 | max 0.049 | pass |
| Steady and stable | | isSteady TRUE; leading eigenvalue -0.006 /yr | pass, weakly |
| 100-yr projection at baseline effort | < 5 % drift | damped oscillation, max 17 % (sand lance), plaice -14 % | marginal |
| Cod collapse F at equilibrium | 0.7-1.1 | **0.5** (0.5-0.6 even with cod reproduction level up to 0.85) | **fail** |

Cod SSB 139 kt (survey peak 172 kt). Cod 1 mg -> 1 g: survival 2.1 %,
deaths 93 % background, 5.9 % forage fish, 0.5 % groundfish. The model was
calibrated quickly and robustly once the Newton approach was used (~1 min).
The collapse-F failure does **not** come from s: recalibrated at s = 1, 5,
10 or 20 cod also collapses at F 0.5 (0.4 at s = 40;
`results/sensitivity_collapse_F.csv`). At cod F >= 0.4-0.5 haddock, silver
hake and plaice, now fished at plausible rates, exclude cod in the long run
(Sec. 5); v2 collapsed only at F ~1.4 because its other groundfish were held
down by effective F of 1.5-2.9. With reproduction levels of 0.1 there is
little density dependence to stabilise coexistence.

## 4. Test 2: hindcast with documented fishing (`results/hindcast*.csv`, Figs 2, 2b)

| Run | Cod 1995-2004 / 1980-89 | Forage | Forage 2005-12 | Haddock / hake / plaice | P:D 1995-2000 | Cod SSB 2025 / 1980-85 | Years from 1993 to 50 % SSB |
|---|---|---|---|---|---|---|---|
| Observed (survey; Bundy 2004) | 0.10 | 7.9 | 4.1 | 0.61 / 0.60 / 0.45 | 3.0 | low (survey index 4.7-8.2 kt in 2023-24) | not by 2025 |
| A: documented F, bycatch 0.02 | **2.18** | 1.36 | 0.70 | 0.91 / 1.14 / 1.02 | 0.83 | 6.1 | **2** |
| A0: cod F = 0 from 1994 | 2.35 | 1.33 | 0.70 | 0.89 / 1.10 / 1.00 | 0.81 | 6.6 | 2 |
| B (alternative): A + adult M 0.8 in 1990-2025 | **0.08** | 1.84 | 1.27 | 1.26 / 1.86 / 1.56 | 1.17 | 0.0002 | 71 (2064) |

Under documented fishing cod SSB falls to 0.26 of baseline in 1993 (close to
the survey's 1992-93 values) and recovers within two years of the closure.
**Test 2 fails** for the fishing-only hindcast: the forage boom never
develops (x1.4) because cod rebounds before forage fish are released, and
haddock, silver hake and plaice do not decline with plausible F. Run B
reproduces the cod decline but not the boom (x1.8) or the groundfish
declines; the 2025 state of run B (with baseline parameters) is the
"collapsed" initial state for tests 3-4.

**Pathways (run B, 2000, vs baseline):** forage fish kill 13.0 % of cod
1 mg-1 g (5.8 % at baseline); survival 2.08 % -> 1.47 % (x0.71 = x0.73
direct predation, x0.97 slower growth); plankton level at 1 mg 0.98 -> 0.96.
From the collapsed 2025 state cod regains 50 % of baseline SSB in 39 years;
with s = 1 in 40, with plankton held at baseline in 38, with both in 37
(`results/pathways_diagnostic_metrics.csv`). **The forage mechanism adds
about one year to recovery; the depth of the M-driven collapse sets the
time.**

## 5. Test 3: bistability (`results/bistability_*.csv`, `results/hysteresis.csv`, Fig. 3)

Cod F = 0, other gears at moratorium levels, baseline parameters.

* **Two starts, 500 years:** from the 1980s baseline and from the collapsed
  2025 state (run B) cod ends at the same state, 7.0x baseline SSB (forage
  x2.0, haddock, hake and plaice extinct). From the collapsed state cod
  reaches 50 % in 37 years.
* **Invasion test: an alternative stable state exists.** The community
  without cod settles (400 years) at forage fish x19 and haddock, silver hake
  and plaice extinct (forage fish kill their larvae too). Rare cod declines in
  it at **-0.0099 /yr** (fit over years 10-150 while cod < 1e-3 of baseline,
  R^2 0.99; -0.009 to -0.017 in the numerical checks). Weak, but robust.
* **Hysteresis sweep (cod F 0 -> 2 -> 0):** cod SSB 7.0 / 5.4 / 4.5 / 1.7x
  baseline at F 0 / 0.1 / 0.2 / 0.3, then excluded for F >= 0.4, where
  haddock, silver hake and plaice take over (x2.4 their baseline) and forage
  fish also disappear. On the way down (cod floored at 1e-3 of baseline)
  cod returns only at F <= 0.3 (0.08x at F 0.3, 2.3x at 0.2, 4.4x at 0). The
  branches differ at F <= 0.3, partly because several equilibria had not
  converged in 400 years (slow dynamics); there is no cod-forage hysteresis
  in the sweep - the switch is between cod and the other groundfish.

**Conditional test (`R/04c_observed_like_start.R`, Fig. 4c).** Because no
hindcast reaches the observed community, it was imposed as an initial state
(baseline spectra scaled: forage x7.9, haddock 0.61, hake 0.60, plaice 0.45;
cod 0.10, 0.04 or 0.01), with baseline parameters and moratorium effort:

| Cod start | s = 20 | s = 1 (diagnostic) | s = 20 + forage F 0.5 for 10 yr | + forage F 1.0 for 10 yr |
|---|---|---|---|---|
| 0.10 (survey biomass ratio) | 50 % in 4 yr | 4 yr | 4 yr | 5 yr |
| 0.04 (survey SSB 1997-2002) | 9 yr | 6 yr | 9 yr | 9 yr |
| 0.01 | **trapped**: touches 0.5x at year 26, then declines to 0.025x by year 150 | 12 yr | 14 yr, persistent | 17 yr, persistent |

So with s = 20 the role-reversal trap does operate in v3, but only if the
forage boom (x8) coincides with cod at about 1 % of its 1980s SSB - a few
times lower than the survey minimum. Short forage fishing then releases it.


## 6. Test 4: forage fishing (`results/forage_fishing_*.csv`, Figs 4, 4b)

**(a) From the modelled collapsed 2025 state** (run B state, adult M back at
baseline; cod F 0.02; forage F raised for D years then back to 0.1):
status quo reaches 50 % of baseline cod SSB in **39 years** (2065); every
programme (F 0.25-3, D 5 years to permanent) takes **41-43 years**, i.e.
forage fishing delays recovery by 2-4 years, and recovery persists in all
runs. Forage F >= 0.5 for >= 10 years drives forage fish below 0.1 % of
baseline. Forage yields during the programme: e.g. F 0.25 / 1 / 3 for 5
years: 46 / 96 / 173 kt yr^-1; for 10 years 36 / 52 / 87 kt yr^-1. No
threshold exists because no programme helps.

**(b) From the model's alternative stable state** (forage x19, cod and the
other groundfish reintroduced at 1e-3 of baseline; `R/04b_*`): status quo
gives **no recovery in 150 years** (cod SSB 3e-4 of baseline at the end).
Forage fishing flips the system:

| Duration | Smallest forage F giving persistent recovery | Years to 50 % SSB |
|---|---|---|
| 5 yr | 2.0 (F 1.5: recovers in 18 yr, then declines again) | 16 |
| 10 yr | 0.75 | 16-18 |
| 15-30 yr | 0.5 | 17-20 |
| permanent | 0.25 | 40 (F 0.5: 20; F >= 0.75: 17) |

Recovered cod settles at 4-7x its 1980s SSB; haddock, silver hake and plaice
do not return. Forage yields during the programme are very large because the
alternative state holds ~19x the 1980s forage biomass (mean over a 10-year
programme: 1.36 Mt yr^-1 at F 0.5, 1.50 Mt yr^-1 at F 1; permanent F 0.5:
220 kt yr^-1 averaged over 150 years). Cod bycatch yield over the first 60
years: 31 kt (F 0.5, 10 yr; no recovery) vs 704 kt (F 1, 10 yr). This is the
hypothesised policy lever working, but only from a state the hindcasts do
not reach.

**(c) Trade-off at equilibrium (constant forage F, cod F 0.02 or 0.40, two
starts):** the long-run equilibria are mostly single-group communities.
With cod F 0.02 cod settles at 4.2-7.4x baseline and haddock, hake and plaice
go extinct; forage fish persist only at forage F <= 0.5 (yield 29-71 kt
yr^-1 at F 0.25-0.5) and cod weight at age 5 falls from 1.28 kg (F 0) to
0.91 kg (F >= 0.75). With no forage fishing and the collapsed start, cod
stays absent (forage x26): bistability at forage F 0. With cod F 0.40
cod is excluded in every case (forage x19-26 at forage F <= 0.1; other
groundfish x2.4 otherwise).

## 7. Test 5: what it would take (`results/sensitivity_*.csv`, Fig. 5)

Map over s (recalibrated to the same 1980s targets for s = 1, 5, 10, 20, 40;
max biomass error <= 1.4 %) x forage reproduction level 0.05-0.9 (boom
magnitude; exact, no recalibration needed). s = 80 and 160 could not be
recalibrated within the time box (the Newton evaluations stopped settling)
and were run as s changed in the main model; at those values the 1980s cod
cannot persist even under 1980s fishing, so their "trapped" outcome is an
artefact of an inconsistent baseline.

| s | Forage share of cod 1 mg-1 g deaths at baseline | Forage boom 1995-2004 (documented F), range over levels | Years from 1993 to 50 % SSB | Invasion rate < 0 (alternative state) | Baseline unstable at levels |
|---|---|---|---|---|---|
| 1 | 0.3 % | x0.86-1.10 | 2 | never | none |
| 5 | 1.6 % | x0.88-1.18 | 2 | never | none |
| 10 | 3.1 % | x0.89-1.23 | 2 | at level 0.05 only | 0.05 |
| 20 | 5.9 % | x0.95-1.64 | 2 | at levels <= 0.17 (main model) | <= 0.10 |
| 40 | 11.1 % | x1.04-2.05 | 2 | never (+0.19 /yr) | <= 0.20 |
| 80 (not recal.) | 20 % | x2.5-3.2 | never | yes | most |
| 160 (not recal.) | 33 % | x1.6-1.7 | never | yes | most |

* **Under documented fishing every recalibrated combination recovers within
  two years of the closure** (outcome "recovers quickly"; with an alternative
  state existing but not reached at s = 10-20 and low forage levels). No
  recalibrated cell produces a "decades-long transient" or a reached
  alternative state, and none produces a forage boom above x2.1.
* After run B (adult M 0.8 in 1990-2025) recovery takes 36-42 years for
  s <= 20 at every forage level; at s = 40 it fails (> 100 years) only where
  the 1980s baseline is itself unstable (levels <= 0.2).
* Cod collapse F at equilibrium: 0.5 for s = 1-20, 0.4 for s = 40.
* One at a time at s = 20: cod reproduction level 0.02 / 0.3 / 0.6 gives
  invasion rates -0.011 / -0.007 / +0.003 and recovery after run B in 43 /
  30 / 15 years; resource productivity x0.5 / x2 gives -0.018 / +0.20 and
  40 / 39 years. The documented-F hindcast recovers in 1-2 years in all.

**What it would take**, within this model: not a larger s alone (s = 40
recalibrated still recovers immediately, s >= 80 cannot be calibrated), and
not a weaker forage density dependence alone (the boom stays below x2.1).
The trap needs the observed post-collapse community itself - an x8 forage
boom coinciding with cod at ~1 % of its 1980s SSB (Sec. 5, conditional
test) - which documented fishing does not create in the model.

## 8. Adult natural mortality alternative (`results/alt_adult_M_*.csv`, Fig. 6)

2x2 factorial hindcast with documented fishing (adult cod M 0.8 from 1990 on
or off x forage mechanism on (s = 20) or off (s = 1 from 1990)):

| Adult M | s | Cod SSB 2000-02 / 1980-85 | Cod 1995-2004 ratio | Forage 1995-2004 | Forage 2005-12 |
|---|---|---|---|---|---|
| baseline | 20 | 2.93 | 2.18 | 1.36 | 0.70 |
| baseline | 1 | 3.06 | 2.32 | 0.85 | 0.31 |
| 0.8 | 20 | **0.044** | **0.081** | 1.84 | 1.27 |
| 0.8 | 1 | 0.051 | 0.103 | 1.12 | 0.49 |
| observed | | ~0.06 | 0.10 | 7.9 | 4.1 |

Adult M accounts for essentially all of the cod decline; the forage
mechanism lowers 2000-02 cod SSB by a further 14 % (about 4 % of the log
decline) and adds ~60 % to the (small) forage boom. With adult M held at 0.8
after 2025 cod does not recover by 2125 under any forage programme (F
0.1-2, 10 or 30 years); with M back at baseline recovery takes 39 years
(status quo) or 43 years (with forage fishing).

## 9. Numerical check (`results/numerical_checks.csv`, Fig. S1)

| Case | Cod ratio A | Forage ratio A | Cod ratio B | Years to 50 % after 2025 (B) | Same + forage F 1 for 10 yr | Invasion rate |
|---|---|---|---|---|---|---|
| Reference (dt 0.1, Euler, 120 bins) | 2.18 | 1.36 | 0.081 | 39 | 43 | -0.0099 |
| dt 0.025 | 2.16 | 1.37 | 0.076 | 41 | 44 | -0.0087 |
| TR-BDF2 | 2.15 | 1.36 | 0.075 | 41 | 45 | -0.0098 |
| 200 bins (rebuilt and recalibrated, max error 1 %) | 2.15 | 1.35 | 0.077 | 41 | 46 | -0.0169 |

All conclusions hold; recovery times move by 2-3 years and the invasion rate
stays negative (R^2 >= 0.987).

## 10. Policy scenario grid: not produced

The brief made the website grid conditional on a usable v3. It is not
usable for that purpose: under fishing-only scenarios the modelled 2025
state is not collapsed (cod 6x baseline), the collapsed state needs the
adult-M alternative, the observed forage boom and groundfish declines are
not reproduced, and long-run equilibria lose species. A grid would show
forage fishing delaying recovery by 2-4 years and adult M deciding
everything, with recovery times that are not credible as forecasts.
`website/data/` was not written. Running it is cheap (~400 runs of 60
years, minutes) if the coordinator decides otherwise.

## 11. v1 and v2: why the mechanism was absent at s = 1

Both earlier models are kept unchanged (`R/v1/`, `R/v2/` and the matching
`results/`, `figures/`, `models/` subfolders; full write-ups in
`results/v1/SUMMARY.md` and `results/v2/SUMMARY.md`). In both, forage fish
eat groundfish eggs and larvae only as plankton of the same size (s = 1).

* **v1** (naive calibration) could not test the hypothesis: Beverton-Holt
  levels capped the forage boom at x1.9, cod early life was almost free of
  modelled mortality (forage fish and groundfish together killed ~7 % of cod
  between 1 mg and 0.1 g; erepro 5.6e-5 hid the rest), and fish removed 1-3 %
  of plankton production. Cod
  recovered within a few years of 1994.
* **v2** made early-life mortality explicit (background Z/G = 0.5),
  constrained the plankton with Bundy (2004) and reproduced the forage boom
  (x9.4) - but only by forcing cod down with an artificial F of 6.3 after 1994
  and the other groundfish with effective F of 1.5-2.9. Even in that boom
  forage fish killed only 4.3 % of cod 1 mg-1 g (0.29 % at baseline) and cod
  survival fell x0.67 (mostly via slower growth); from the observed-like 2000
  state cod regained 50 % of baseline SSB in 7 years and the cod-free state
  was invaded at +0.52 /yr. Without recalibration, s ~ 12 gave a >= 30-year
  failure and s ~ 19 an alternative state, but at s >= 10 the unrecalibrated
  baseline could no longer sustain the 1980s cod. v2's calibration was also
  poor (cod +61 %, plaice +59 %, cod yield 2.1x landings).

At s = 1 the mechanism is absent because forage fish are a small part of
the predator field of cod larvae (background predators dominate) and the
size-based kernel puts cod eggs and larvae in the diet of forage fish only in
proportion to their tiny biomass. The v3 recalibration at s = 1 (sensitivity
map) confirms this: forage share of cod early-life deaths ~0.3 %.

## 12. Departures from "scenarios differ only in fishing and initial state"

| Departure | Where | Justification |
|---|---|---|
| s = 20 (assumption under test) | all v3 runs | the hypothesis being tested; recalibrated baseline |
| Forage reproduction level bounded at 0.17 | all v3 runs | fitted value would make the 1980s state unstable |
| Adult cod M 0.8 in 1990-2025 (run B) and the M axis of 07 | 02 run B, 07, and the initial state of 03/04 | documented post-collapse M (Mohn & Rowe 2012); labelled alternative. Needed because fishing alone leaves cod uncollapsed |
| s set to 1, plankton held constant | 02 pathway diagnostics, 07 "s off" | diagnostics only, not scenarios |
| Cod and groundfish reintroduced at 1e-3 into the cod-free attractor | 03 invasion test, 04b | tests of the alternative state |
| Imposed observed-like initial state (survey ratios) | 04c | conditional test; initial state only |
| Cod reproduction level, resource P/B x0.5/x2, s values without recalibration (s = 80, 160 if flagged) | 05 | sensitivity |

No artificial F is used anywhere in v3.

## 13. Weaknesses

* The hindcast fails its targets (forage boom, groundfish declines, cod
  non-recovery under fishing alone); the collapsed state rests on the adult-M
  alternative.
* Fragile community: with groundfish reproduction level 0.1 and the forage
  level at its stability bound, equilibria away from 1980s conditions are
  single-group communities; cod collapses at equilibrium cod F 0.5 (target
  0.7-1.1) at every s, excluded by haddock, silver hake and plaice, and
  recovered cod at 4-7x its 1980s SSB excludes them in turn. Raising the cod
  reproduction level (to 0.85) does not fix this.
* The alternative state is weak (invasion rate -0.01 /yr) and far from the
  observed community (no groundfish, forage x19).
* Baseline pelagic:demersal ratio 0.59 vs Bundy's 0.3.
* The 100-year projection of the baseline drifts by up to 17 % (slow damped
  oscillation).
* Other inherited v2 weaknesses: North Sea kernel parameters, single
  resource spectrum for plankton and benthos, background early-life
  mortality form (Z/G = 0.5, unverified range), no seals as a species.

## 14. Figures (300 dpi PNG + PDF, Okabe-Ito / viridis palettes)

| Figure | Content |
|---|---|
| `figures/fig1_baseline` | calibration vs targets, spectra, growth vs von Bertalanffy, feeding level, cod mortality by source, resource depletion |
| `figures/fig2_collapse_moratorium` | runs A, A0, B: cod SSB vs survey, groups, survey comparison per species, plankton |
| `figures/fig2b_pathways` | cod feeding, growth, forage predation, resource level (baseline vs run B 2000); recovery from 2025 with pathways off |
| `figures/fig3_bistability` | two starts, forage, invasion test with fit window, hysteresis sweep |
| `figures/fig4_forage_fishing` | programmes from the collapsed 2025 state; recovery-time grid; equilibrium trade-offs |
| `figures/fig4b_forage_fishing_alt_state` | programmes from the alternative state; threshold grid |
| `figures/fig4c_observed_like_start` | cod from an imposed observed-like community (forage x7.9; cod 0.10 / 0.04 / 0.01) |
| `figures/fig5_sensitivity` | "what it would take" map; recovery after run B; cod reproduction level and resource productivity |
| `figures/fig6_adult_mortality` | 2x2 factorial; forage under elevated M |
| `figures/figS1_numerical_checks` | dt, TR-BDF2, 200 bins |

v1 and v2 figures are in `figures/v1/` and `figures/v2/`.

## 15. Files

| What | Where |
|---|---|
| Functions (`run_scenario()`, `calibrate_v3n()`, `solve_biomasses()`, `scale_growth()`, `elevate_M()`, `invasion_test()`, `invasion_fit()`, budgets) | `R/functions.R` |
| Scripts | `R/01_build_model.R` ... `R/07_adult_mortality_alternative.R`, `R/04b_forage_fishing_from_alternative_state.R`, `R/04c_observed_like_start.R`; driver `R/run_all.R` |
| Inputs | `data/v3/species_params.csv`, `gear_params.csv`, `interaction_matrix.csv`, `effort_history.csv` |
| Models (`saveParams`) | `models/baseline_params.rds` (1980-85), `models/collapsed_2025_params.rds` (run B 2025 state, baseline parameters), `models/hindcast_2025_documentedF_params.rds`, `models/boom_2000_params.rds`, `models/alternative_state_params.rds`, `models/calibration_*.rds`, `models/sensitivity/` |

`Rscript R/run_all.R` was run end to end on 13 Nov 2026 with the calibration
caches in place: all nine v3 scripts finished with status 0 in 61 min
(`logs/run_all.log`).

`run_scenario(params, effort, years, initial = NULL, dt = 0.1, method = "euler", return_sim = FALSE)`:
`effort` = data frame with `year` and gear columns `cod`, `haddock`,
`silver_hake`, `plaice`, `pelagic` (piecewise constant) or a named constant
vector with `years`; returns tidy yearly output (biomass, ssb, yield, F,
n_juv per species, plus resource bands). No side effects.

## 16. Next steps

1. Decide whether the paper's question is better served by a model in which
   the boom can arise: e.g. forage fish with less food limitation or a
   separate zooplankton/benthos resource, groundfish reproduction levels
   that allow coexistence over a wider range, or seals as an explicit
   predator. Then rerun this suite.
2. Map the conditional trap more finely: cod start between 0.01 and 0.04
   crossed with forage boom x4-x12 and s, from imposed states (04c does three
   points); this needs no new parameters.
3. If wanted, produce the website grid from the run-B 2025 state (cheap),
   with the caveats of Sec. 10.
4. File mizer issue #4 (`steadySingleSpecies()`) upstream after reducing it
   to a portable reprex.
