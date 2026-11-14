# Possible mizer issues found while building the eastern Scotian Shelf model

Installed mizer: 3.4.0.9003 (defaults edition 3 used for the model). None of
these has been filed upstream yet; each is described with enough detail to
build a reprex. None of them changes the scientific results: the work-arounds
are described in the scripts.

## 1. `matchGrowth(keep = "biomass")` fails erratically depending on fishing effort

**Status:** observed, not isolated to a minimal example; may be a genuine
property of a far-from-steady initial state rather than a bug.

On a freshly built model (`newMultispeciesParams()` with the species in
`data/species_params.csv`, `kappa = 3`, `no_w = 120`, the gears in
`data/gear_params.csv`), `matchGrowth(params, keep = "biomass")` stops with

    The steady state has zero biomass for Haddock, so it cannot be rescaled to
    keep the biomass it had before.

for `initial_effort = c(cod = 0.40, groundfish = 0.3, pelagic = 0.1)` but
succeeds for cod effort 0.30, 0.35, 0.38 and 0.45, and for groundfish effort 0.
The cod gear does not select haddock, so the cod effort should not affect the
haddock steady state at all. `matchGrowth(keep = "egg", species = "Haddock")`
on the same object succeeds and gives a positive haddock biomass above the
cutoff. Reproduce with:

```r
source("R/functions.R"); defaults_edition(3)
inp <- read_inputs(); sp <- inp$sp; sp$latin <- NULL; sp$group <- NULL
p <- newMultispeciesParams(sp, no_w = 120, kappa = 3, gear_params = inp$gp,
                           initial_effort = c(cod = 0.4, groundfish = 0.3, pelagic = 0.1))
matchGrowth(p, keep = "biomass")   # error; cod = 0.35 or 0.45 works
```

Work-around in `build_model()`: the single-species growth matching is done
unfished, and the baseline effort is switched on afterwards.

## 2. Newton solver errors inside the van Leer limiter

**Status:** observed repeatedly, not isolated.

`tuneSteadyState(params, solver = "newton")` on intermediate calibration
states of this model sometimes stops with

    Error in chi_int[nz] <- limiter(num[nz], den[nz]):
      NAs are not allowed in subscripted assignments

(edition-3 model, i.e. `second_order_w` flux `"van_leer"`). It also sometimes
returns with nleqslv termination code 5 ("Jacobian is too ill-conditioned")
or 3 ("No better point found"). The help page of `findSteadyState()` warns
that with van Leer the residual is only Lipschitz, so non-convergence is
documented; an `NA` error from inside the limiter is not, and suggests a
`0/0` in the limiter's ratio that is not guarded. Work-around in
`tune_ss()` (R/functions.R): fall back to `solver = "project"` whenever the
Newton solve errors or does not return a fixed point.

## 3. tuneSteadyState() lands on very different solutions for tiny input changes (v2)

**Status:** observed; probably a property of this model (several fixed points
with recruitment held), not necessarily a bug.

In the v2 calibration (`R/functions.R`, `build_model()`), repeating
`match_biomass_damped(p, 0.01)` (abundances changed by < 1 %) followed by
`tuneSteadyState(solver = "newton")` returned states whose maximum biomass
error jumped between 0.9 and 8, and once a state in which silver hake had
grown by a factor ~3e7 while every other species was near zero
(`attractor` NA). `solver = "project"` from the same start produced the
silver-hake runaway as well. The help pages document that Newton can converge
to unstable fixed points; whether a runaway with reproduction held fixed is
expected is unclear. Work-around: keep the best fixed point with all
erepro < 1 and accept a looser calibration (max error 61 %).

## 4. steadySingleSpecies() (and hence matchGrowth()) is far from the identity on a steady state of the v3 model

**Status:** observed with project files; a portable reprex with
`NS_species_params` (editions 2 and 3) shows only a 0-2 % change, so the
effect needs this model's steep early-life mortality to become large. Not
filed upstream.

The help page says `steadySingleSpecies()` "solves the steady-state equation
with these growth and death rates and the current abundance at the smallest
size". Applied to a model that *is* at steady state, it should therefore
return (nearly) the same spectra. On the v3 calibration at s = 5
(`isSteady()` TRUE, R_max = Inf for all species, hand-set `ext_mort` holding
the early-life background mortality) it does not:

```r
library(mizer)
p <- readParams("notes/reprex_cal_s5.rds")   # v3 calibration at s = 5 (saved with saveParams)
isSteady(p)                                            # TRUE
getBiomass(steadySingleSpecies(p, keep = "egg")) / getBiomass(p)
#  Cod 0.371  Haddock 0.628  Silver hake 1.14  Plaice 0.445  Herring 0.0414  Sand lance 0.316  Capelin 0.236
getBiomass(steadySingleSpecies(p, keep = "biomass")) / getBiomass(p)
#  1.02 1.01 1 1.18 4.97 1.07 1.11
packageVersion("mizer")                                # 3.4.0.9003, defaults_edition(3)
```

A likely cause is that the steady-state equation is solved with a different
discretisation from the edition-3 transport scheme used by `project()`,
which matters where mortality/growth is large (here Z/G = 0.5 background plus
forage predation on larvae). Because `matchGrowth()` ends with
`steadySingleSpecies()`, a growth rescaling of < 0.5 % turned the calibrated
state into one with silver hake x20 and the other species near zero.
Work-around in v3: `scale_growth()` in `R/functions.R` does the same
rescaling of gamma, h, ks and k but keeps the spectra, and
`tuneSteadyState()` re-settles them.
