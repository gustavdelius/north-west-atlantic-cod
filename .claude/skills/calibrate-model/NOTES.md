# Project notes: calibrate-model (eastern Scotian Shelf cod model)

* Model is built with `defaults_edition(3)` (zero-padded FFT kernels, van Leer
  flux). Calibration code: `build_model()` in `R/functions.R`.
* `tuneSteadyState(solver = "newton")` often fails on intermediate states of
  this model (nleqslv codes 3 and 5, and once an `NA` error inside the van Leer
  limiter, see `notes/mizer-issues.md`). `tune_ss()` falls back to
  `solver = "project"` (t_max 500) whenever Newton errors or does not return
  `attractor == "fixed_point"`.
* `matchGrowth(keep = "biomass")` on a freshly built model failed for one
  particular cod effort (0.40) with "steady state has zero biomass for
  Haddock" but not for 0.38 or 0.45. Doing the growth matching unfished and
  switching on the effort afterwards avoids it.
* Building directly at the target resource coefficient (kappa ~ 1) fails or
  cycles; a continuation in kappa from 3 (weakly coupled, robust) via 1.7 to
  1, rescaling the given `gamma` by kappa_old / kappa_new at each step, works.
  The `matchBiomasses()` / `matchGrowth()` / `tuneSteadyState()` loop needs
  ~5-12 rounds to bring all biomasses within 3 %.
* Because `tuneSteadyState()` holds the resource abundance and rebalances the
  capacity, the calibrated steady state does not depend on `r_pp`. Vary
  `r_pp` afterwards with `setResource(params, resource_rate = r_pp)` (balances
  the capacity, keeps the state) rather than recalibrating.
* `erepro` comes out at ~1e-5 to 1e-4 for all species: the explicitly modelled
  early-life mortality is small, so almost all egg-to-recruit loss is in
  `erepro`.
* Setting `reproduction_level()` after calibration leaves the steady state
  unchanged; every later `tuneSteadyState()` preserves it.
* `matchBiomasses()` re-derives the Beverton-Holt parameters and drifts the
  reproduction levels (to ~1 for every species after 12 rounds in one run);
  `build_model()` therefore resets them with `reproduction_level<-` at the end.
* With the survey-based targets (cod 2.0, haddock 1.2, silver hake 1.0, plaice
  1.3, herring 1.5, sand lance 1.0, capelin 0.05 g m^-2 above cut-offs) the
  loop converges at kappa = 1.4 (all errors < 3 %, all erepro < 1) but not at
  kappa = 1 (max error 66 %, forage erepro up to 1e5 — a state the forage
  fish cannot fund) or kappa = 2 (343 %). kappa = 1.4 is the main model.
* Building with `no_w = 200` reached only 38 % max biomass error after 12
  rounds; fine-grid models need more iterations.

## v2 (main model, R/functions.R)

* Early-life background mortality is set as a hand-set `ext_mort` array
  (frozen) and recomputed with `refresh_bg()` after every `matchGrowth()`,
  because its size dependence is tied to each species' reference growth.
* A purely size-based background (Peterson & Wroblewski 1984) made forage
  fish and plaice need erepro of 1e2-1e6: mizer's allometric growth gives the
  larvae of small or slow-maturing species much slower growth than cod
  larvae, so they spend far longer in the high-mortality window. A background
  proportional to each species' growth (Z/G = 0.5) keeps all erepro < 1;
  Z/G = 1 did not.
* With reproduction levels 0.1 the matchBiomasses / tuneSteadyState loop
  oscillates (errors switching sign between rounds); allow ~20 rounds.
* Hindcast calibration (forage reproduction level, groundfish F) is cheap
  because `reproduction_level<-` does not move the steady state: optimise it
  with optim() on the hindcast directly, no rebuild needed.

## v3 (main model, R/functions.R)

* The matchBiomasses / tuneSteadyState loop does not converge for this
  strongly coupled model (errors oscillate and grow, even with R_max = Inf).
  What works: `solve_biomasses()` -- Newton's method on the log abundance
  factors of all species at once, each evaluation one
  `tuneSteadyState(solver = "project")` with recruitment and resource pinned,
  finite-difference Jacobian. Converges quadratically (0.43 -> 0.12 -> 0.003
  max log error), ~20 s per Newton step with 7 species and 120 bins.
* Keep R_max = Inf (reproduction level 0) while calibrating and set the
  reproduction levels at the end: with R_max finite, matchBiomasses() scaling
  is not matched by the pinned recruitment.
* Do not use `matchGrowth()` here: its final `steadySingleSpecies()` call
  wrecks the state (see `notes/mizer-issues.md` #4). `scale_growth()`
  rescales gamma, h, ks, k by age_mat(model)/age_mat(target) and keeps the
  spectra; growth then matches to < 0.5 %.
* `tuneSteadyState()` after a growth change can end with termination
  "residual_tolerance" but attractor NA (instantaneous drift 0.06-0.09/yr in
  the smallest sizes) although a 50-year projection moves < 4 %; accept
  those (`settled()`).
* The calibrated v3 baseline is only weakly stable (leading eigenvalue
  -0.006/yr) and its stability depends on the forage reproduction level
  (unstable below ~0.12): check getStability() after setting reproduction
  levels, not only isSteady().
