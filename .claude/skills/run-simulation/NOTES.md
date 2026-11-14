# Project notes: run-simulation (eastern Scotian Shelf cod model)

* Use `run_scenario()` in `R/functions.R` for every scenario: it takes the
  baseline `MizerParams`, an initial state (NULL, a `MizerParams` or a
  `MizerSim`) and a piecewise-constant effort data frame (`year` + one column
  per gear) and returns a tidy yearly data frame. It has no side effects.
* With an effort array, `project()` runs from the first to the last row time;
  the last row is only the end marker (its effort is never applied).
  `effort_array()` builds one row per year, including the end year.
* Speed: 7 species, 120 size bins, dt = 0.1, edition 3 (van Leer): about
  0.03 s per simulated year on one core (500 years ~ 15 s).
* `projectUntilSettled()` / `findSteadyState()` stop when a species declines
  towards extinction (`extinction_threshold`), which is exactly what must be
  followed in the collapsed-cod runs. `equilibrate()` in `R/functions.R`
  projects in 25-year chunks until the largest relative biomass change rate is
  below a tolerance, without an extinction stop.
* A species set to exactly zero abundance stays at zero, which gives a clean
  cod-free community for invasion tests.

## v3

* `run_scenario()` with 7 species and 120 bins: ~2-3 s per 100 years at
  dt 0.1. dt 0.025, TR-BDF2 and a 200-bin rebuild change recovery times by
  2-3 years (`results/numerical_checks.csv`).
* Running several scripts with `mclapply(mc.cores = 8)` at once on the
  8-core machine pushed the load to ~23 and slowed everything ~3x; run the
  heavy ones (05, 03) one at a time.
