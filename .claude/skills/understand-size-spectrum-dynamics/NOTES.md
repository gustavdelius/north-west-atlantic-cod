# Project notes: size-spectrum dynamics (eastern Scotian Shelf cod model)

* **Forage-fish predation on cod eggs is weak under pure size-based
  predation.** With `gamma` calibrated from `f0` against the resource,
  a forage fish encounters a cod egg exactly as it encounters a resource
  particle of the same mass, so the mortality forage fish impose on cod eggs
  equals the per-capita mortality they impose on 1 mg plankton. At observed
  forage biomass (~2.7 g m^-2) they consume a few percent of plankton
  production, and they kill only ~3 % of cod eggs and larvae (1 mg - 0.1 g).
  Raising this needs either forage fish that eat most of the plankton
  production (low kappa) or an egg-predation interaction above 1 (`s_egg`).
* The cod egg-to-0.1 g stage lasts only ~0.05-0.16 yr at f ~ 0.6, so even
  large changes in larval mortality rates translate into small changes in
  survival.
* **Compensatory reserve of cod at F = 0 is large** (lifetime egg production
  per recruit at F = 0 is ~8x that at the baseline F = 0.4). For the
  moratorium to fail permanently, the forage-fish effect must remove that
  whole reserve, i.e. cut early survival by an order of magnitude.
* With a low cod reproduction level (0-0.25) the unfished cod-dominated state
  has cod at ~3.5x the baseline biomass and drives herring and haddock nearly
  extinct (cod is sustained by the benthic resource: apparent competition).
* Removing cod releases the other groundfish (haddock, silver hake, plaice),
  which then eat small forage fish; the net forage release in a cod-free
  community with other groundfish at their baseline F is only ~1.2x.
* Final main model (kappa 1.4, r_pp 2): forage fish kill 2.0 % of cod eggs and
  larvae (1 mg-0.1 g); the cod-free community has 0.55x the baseline forage
  biomass (haddock, plaice, silver hake take over); rare cod invade at
  +0.23 yr^-1. Making forage fish eat 45 % (s_egg 30) or 87 % (s_egg 100) of
  cod eggs gives 12- and 90-year recoveries, but the invasion rate stays
  positive (0.21, 0.12 yr^-1): no alternative stable state was found.
* Plankton (< 0.01 g) biomass changes by < 0.1 % over the whole collapse
  hindcast: competition for plankton is negligible in this calibration.

## v2 (main model)

* With a Scotian-Shelf-constrained resource (kappa 3, P/B 1.41 w^-0.22) and
  a x9 forage boom, plankton of 0.1 mg-0.1 g drops only to ~0.8 of capacity
  and fish eat 15-20 % of its production; cod survival 1 mg -> 1 g falls by a
  third, mostly through slower growth through the background-mortality window
  rather than direct predation.
* Cod remains extremely resilient (needs effective F ~6 to stay at the
  observed post-collapse level; equilibrium SSB at F = 0 ~4x baseline): the
  forage feedback would have to make forage fish eat ~30-50 % of cod 1 mg-1 g
  (s_egg ~12-19) to stall recovery for 30 years or create an alternative state.
