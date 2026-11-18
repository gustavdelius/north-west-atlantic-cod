# Possible mizer issues found while building the eastern Scotian Shelf model

Installed mizer: 3.4.0.9003 (defaults edition 3 used for the model). Filed
upstream as <https://github.com/sizespectrum/mizer/issues/652> (items 1, 3, 4)
and <https://github.com/sizespectrum/mizer/issues/653> (item 2). None of them
changes the scientific results: the work-arounds are described in the scripts.

## 1. `matchGrowth(keep = "biomass")` fails erratically depending on fishing effort

**Status:** filed upstream as part of
<https://github.com/sizespectrum/mizer/issues/652> (same root cause in
`get_steady_state_n()` as #4 below).

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

**Status:** isolated to a 3-line `NS_params` reprex and filed upstream as
<https://github.com/sizespectrum/mizer/issues/653>.

`tuneSteadyState(params, solver = "newton")` on intermediate calibration
states of this model (and on `NS_params` with `second_order_w(p) <- TRUE`)
stops with

    Error in chi_int[nz] <- limiter(num[nz], den[nz]):
      NAs are not allowed in subscripted assignments

(edition-3 model, i.e. `second_order_w` flux `"van_leer"`). It also sometimes
returns with nleqslv termination code 5 ("Jacobian is too ill-conditioned")
or 3 ("No better point found"). Cause: (a) active bins at `w_top` where somatic
growth $g \approx 0$ (e.g. `w[no_w] == w_max`, or bins in $[w_\infty, 1.5 w_\infty]$
where `repro_prop` is clamped to 1) have $r_{\text{ss}} = \text{res}/N \approx \mu$
nearly independent of $\log N$, giving the Jacobian a $\sim 10^{-9}$ singular
value and a $\Delta x \sim 10^7$ Newton step; (b) `exp(x)` overflows to `Inf`,
`delta` has `Inf - Inf = NaN`, and `nz <- den != 0` has `NA`. Work-around in
`tune_ss()` (R/functions.R): fall back to `solver = "project"` whenever the
Newton solve errors or does not return a fixed point.

## 3. tuneSteadyState() lands on very different solutions for tiny input changes (v2)

**Status:** explained by #4 (<https://github.com/sizespectrum/mizer/issues/652>).

In the v2 calibration (`R/v2/functions.R`, `build_model()`), repeating
`match_biomass_damped(p, 0.01)` (abundances changed by < 1 %) followed by
`safe_match_growth()` and `tuneSteadyState(solver = "newton")` returned states
whose maximum biomass error jumped between 0.9 and 8, and once a state in which
silver hake had grown by a factor ~3e7 while every other species was near zero
(`attractor` NA). Cause: calling `match_biomass_damped(p, 0.01)` followed
directly by `tuneSteadyState()` changes biomasses by < 1 % as expected; the
jump was introduced by the intervening `matchGrowth(keep = "biomass")` call,
which ran `steadySingleSpecies(keep = "biomass")` (#4 below) followed by
`setBevertonHolt()`, changing `getRDD()` by factors of 0.15--7.7x before
`tuneSteadyState()` held recruitment fixed. Work-around in v2: keep the best
fixed point with all erepro < 1; fixed cleanly in v3 by `scale_growth()`.

## 4. steadySingleSpecies() (and hence matchGrowth()) is far from the identity on a steady state of the v3 model

**Status:** root cause identified and filed upstream as
<https://github.com/sizespectrum/mizer/issues/652>.

The help page says `steadySingleSpecies()` "solves the steady-state equation
with these growth and death rates and the current abundance at the smallest
size". Applied to a model that *is* at steady state, it should therefore
return (nearly) the same spectra. On the v3 calibration at s = 5
(`isSteady()` TRUE, R_max = Inf for all species, hand-set `ext_mort` holding
the early-life background mortality) — and even on
`tuneSteadyState(newSingleSpeciesParams(), solver = "newton")` in edition 3 —
it does not:

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

Cause: `get_steady_state_n()` uses the same discretisation as `project()`, and
the true steady state *is* an exact fixed point of its equation, but when
`flux_limiter != "none"` it iterates by inverting the frozen-$\chi$ matrix
$M(\chi(n^{(k)}))$. Because $M(\chi)$ at $\chi \approx 1$ is nearly central
differences (eigenvalue $O(\mu \Delta w / g) \ll 1$ on the grid-scale sawtooth
mode $(-1)^j$) while the omitted $\partial \chi / \partial n$ Jacobian term is
$O(g / \Delta w)$, the true steady state is a linearly unstable repeller of the
frozen-$\chi$ Picard map. The iteration develops alternating negative values
that get clipped by `n_new[n_new < 0] <- 0` and runs all 500 iterations without
converging. Preconditioning the residual with the first-order upwind operator
($M_{\text{upwind}}$ at $\chi = 0$) instead of $M(\chi)$ converges in ~30
iterations to `< 1e-10`. Work-around in v3: `scale_growth()` in `R/functions.R`
does the same rescaling of gamma, h, ks and k but keeps the spectra, and
`tuneSteadyState()` re-settles them.
