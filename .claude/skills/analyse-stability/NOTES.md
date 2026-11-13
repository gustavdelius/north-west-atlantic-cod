# Project notes: analyse-stability (eastern Scotian Shelf cod model)

* Baseline steady state: `getStability()` max real part -0.072 yr^-1 (stable,
  non-oscillatory dominant mode).
* To test for an alternative stable state without relying on long runs, set
  cod abundance to exactly zero, equilibrate the rest of the community
  (`equilibrate()` in `R/functions.R`), reintroduce cod at 1e-6 of baseline
  and fit the log-biomass slope over years 30-60 (`log_growth_rate()`).
  A negative slope would mean the cod-free state is an attractor.
* In hysteresis sweeps over cod F, cod driven to ~1e-50 at high F cannot
  regrow within any finite run, which looks like hysteresis but is numerical
  near-extinction. `R/03_bistability.R` floors cod at 1e-3 of its baseline
  biomass before each step of the decreasing sweep.
* `scanModel()`/`projectUntilSettled()` were not used for the collapsed
  branch because they stop when a species heads for extinction.

## v2 lessons

* Measure the invasion rate only while the invader is still rare. In v2,
  reintroduced cod reaches its equilibrium within 30-50 years, so a slope
  fitted over years 30-60 is ~0 and was at first misread as a neutral or
  alternative state. `invasion_rate()` now fits from year 10 until cod
  passes 1e-3 of its baseline biomass.
* The cod-free community in v2 (other groundfish at the calibrated
  post-2005 effective F) had not converged after 400 years (slow drift of
  forage biomass, ~48 g m^-2); invasion rates are robust to this only when
  measured on the rare phase.
* With the hindcast-calibrated effective mortality of haddock, silver hake
  and plaice held forever, those species decline towards extinction in every
  long-run equilibrium; long-run results therefore describe a cod + forage
  system unless that mortality is relaxed.
