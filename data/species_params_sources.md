# Sources of empirical numbers used in the model

Every empirical number used in `data/*.csv` and in `R/functions.R`
(`default_config()`) is listed here with its source and a tag:

* **verified** — checked against the cited primary source by the literature
  agent (files in `literature/data/`, transcribed from the document) or read
  directly from a cached database extract in this repository
  (`data/fishbase/*.csv`, produced by `R/00_fishbase_lookup.R`).
* **FishBase** — taken from or bracketed by the FishBase records cached in
  `data/fishbase/` (verified as *what FishBase says*; FishBase records are
  secondary compilations and mostly not specific to the eastern Scotian Shelf).
* **unverified** — from the modeller's background knowledge of the literature,
  or an assumption. These should be checked before publication.

Area and units: the model works in g m^-2. The shelf area of NAFO 4Vs + 4W is
taken as **1.1 x 10^5 km^2** (DFO 2010 grey-seal science advisory report p. 7,
as read by the literature agent, `literature/empirical_targets.md` section 1;
tag **verified (literature agent)**; the Bundy 2004 Ecopath model implies
1.025 x 10^5 km^2), so that 1 g m^-2 = 110 kt. All conversions between tonnes
and g m^-2 scale with this area.

The literature agent's compilation `literature/empirical_targets.md` (sources
as `references.bib` keys with page/table pointers) was used for the
calibration and validation targets below. Its tags are kept: [R] = read in the
source by that agent, [D] = derived by that agent from a dataset. Numbers
tagged [R] are listed here as "verified (literature agent)"; [D] numbers as
"derived (literature agent)".

## Life history (data/species_params.csv)

Lengths in cm (total length), weights in g, ages in years.
`w_inf`, `w_mat` are computed by mizer from `l_inf`, `l_mat` with `w = a l^b`.
`k_vb` is recorded for reference only: mizer's growth is calibrated to
`age_mat` (`matchGrowth()`), which takes precedence.

| Species | Parameter | Value | Source | Tag |
|---|---|---|---|---|
| Cod | l_inf | 110 | FishBase NW-Atlantic records median 105 cm (n = 37); 4VsW cod in the 1970s reached 100-120 cm | FishBase / unverified |
| Cod | k_vb | 0.15 | FishBase NW-Atlantic median 0.151 | FishBase |
| Cod | l_mat | 42 | 4VsW L50 ~40-45 cm before the 1990s decline in size at maturity; FishBase Georges Bank/Gulf of Maine 1985-90 L50 32-41 cm | unverified |
| Cod | age_mat | 4.5 | 4VsW A50 ~4-5 yr in the 1970s-80s (declined to ~3 yr in the 1990s) | unverified |
| Cod | a, b | 0.0072, 3.07 | FishBase median of 51 length-weight records | FishBase |
| Haddock | l_inf, k_vb | 65, 0.25 | FishBase records for 4TVW / ICNAF 4 / Georges Bank: Loo 51-80 cm, K 0.22-0.35 | FishBase |
| Haddock | l_mat, age_mat | 33, 3 | FishBase Georges Bank / Gulf of Maine L50 27-35 cm, A50 1.3-2.5 yr; 3 yr used for the 1970s ESS stock | FishBase / unverified |
| Haddock | a, b | 0.0052, 3.16 | FishBase median (25 records) | FishBase |
| Silver hake | l_inf, k_vb | 45, 0.38 | FishBase 4VWX / Georges Bank / Gulf of Maine records: Loo 36-62 cm, K 0.25-0.74 (median 42.5 cm, 0.40) | FishBase |
| Silver hake | l_mat, age_mat | 23, 2 | FishBase Gulf of Maine / Georges Bank 1985-89: L50 22-23 cm, A50 1.6-1.7 yr | FishBase |
| Silver hake | a, b | 0.0046, 3.10 | FishBase median (6 records) | FishBase |
| American plaice | l_inf, k_vb | 55, 0.10 | FishBase NW Atlantic (mostly Grand Bank) Loo 60-80 cm, K 0.06-0.17; ESS fish are smaller | FishBase / unverified |
| American plaice | l_mat, age_mat | 30, 6 | FishBase Georges Bank females L50 28-30 cm; Newfoundland female A50 6-10 yr | FishBase / unverified |
| American plaice | a, b | 0.0030, 3.30 | FishBase median (8 records) | FishBase |
| Herring | l_inf, k_vb | 34, 0.32 | FishBase Nova Scotia / Bay of Fundy / Gulf of Maine: Loo 33.7-35.7 cm, K 0.32-0.41 | FishBase |
| Herring | l_mat, age_mat | 25, 3.5 | FishBase Georges Bank 1986-95 L50 25-27 cm, A50 3 yr | FishBase / unverified (3.5) |
| Herring | a, b | 0.00634, 3.03 | FishBase median (113 records) | FishBase |
| Sand lance | l_inf, k_vb | 25, 0.35 | FishBase Banquereau and Emerald Bank (N.S.) 1973: Loo 20.3 and 30.3 cm, K 0.38 and 0.33 | FishBase |
| Sand lance | l_mat, age_mat | 13, 2 | assumption (maturity at age 2, ~half of Loo) | unverified |
| Sand lance | a, b | 0.0020, 2.99 | FishBase Emerald Bank record | FishBase |
| Capelin | l_inf, k_vb | 19.5, 0.48 | FishBase Labrador Sea / Barents Sea: Loo 19-20 cm, K 0.45-0.48 | FishBase |
| Capelin | l_mat, age_mat | 14, 2.5 | FishBase Newfoundland L50 15.9 cm, A50 2-3 yr | FishBase / unverified (14 cm) |
| Capelin | a, b | 0.0029, 3.23 | FishBase median (8 records) | FishBase |
| all | w_min (egg) | 0.001 g | mizer default; a 1.4 mm cod egg weighs ~1.4 mg | unverified |

## Predation kernels

| Species | beta (PPMR) | sigma | Source | Tag |
|---|---|---|---|---|
| Cod | 66 | 2.0 | beta from the North Sea model `NS_params` (Blanchard et al. 2014, J. Appl. Ecol. 51:612); sigma set to the mizer default 2 instead of the North Sea 1.3 (cod diets span shrimp to fish of 1/10-1/1000 of their weight; a wider kernel also damps cohort cycles) | analogue / unverified |
| Haddock | 558 | 2.1 | North Sea haddock (`NS_params`) | analogue |
| Silver hake | 22 | 1.5 | North Sea whiting (`NS_params`), a gadoid piscivore of similar size | analogue |
| American plaice | 113 | 1.6 | North Sea plaice (`NS_params`) | analogue |
| Herring | 280540 | 3.2 | North Sea herring (`NS_params`) | analogue |
| Sand lance | 398849 | 1.9 | North Sea sandeel (`NS_params`) | analogue |
| Capelin | 10000 | 2.0 | assumption: capelin eat copepods (~0.1-1 mg) and euphausiids (~50 mg) at 20-40 g body mass, PPMR ~10^3-10^5 | unverified |

`NS_params` values were read from the installed mizer package
(`species_params(NS_params)`), so the numbers are verified as the North Sea
model's values; their transfer to the Scotian Shelf is an assumption.

## Calibration targets (pre-collapse period, 1980-1985)

Biomasses are model biomass above `biomass_cutoff` (data/species_params.csv),
in g m^-2 (1 g m^-2 = 110 kt).

| Quantity | Target used | Source / comparison | Tag |
|---|---|---|---|
| Cod biomass > 100 g | 2.0 g m^-2 (220 kt) | q-adjusted RV survey biomass, 1980-85 mean 259 kt (`literature/data/ess_rv_biomass_qadj_derived.csv`) | derived (literature agent), indicative |
| Cod SSB (check, not fitted) | survey SSB 1980-85 mean 120 kt = 1.09 g m^-2; peak 171.6 kt (1984) | Fanning et al. 2003 Table 13 (`literature/data/cod_4VsW_assessment.csv`) | verified (literature agent) |
| Cod landings (check, not fitted) | 53.5 kt yr^-1 = 0.486 g m^-2 yr^-1 (mean 1980-85) | Fanning et al. 2003 Table 1 (`literature/data/cod_4VsW_landings_1958_2002.csv`); stored as `yield_observed` in data/gear_params.csv | verified (literature agent) |
| Haddock biomass > 100 g | 1.2 g m^-2 (132 kt) | q-adj. survey 1980-85 mean 130 kt | derived (literature agent), indicative |
| Silver hake biomass > 20 g | 1.0 g m^-2 (110 kt) | q-adj. survey 1980-85 mean 109 kt | derived (literature agent), indicative |
| American plaice biomass > 100 g | 1.3 g m^-2 (143 kt) | q-adj. survey 1980-85 mean 142 kt | derived (literature agent), indicative |
| Herring biomass > 20 g | 1.5 g m^-2 (165 kt) | q-adj. survey 54 kt (1980-85), 309 kt (1980-89); pelagic fish poorly sampled by bottom trawl | assumption within survey range |
| Sand lance biomass > 2 g | 1.0 g m^-2 (110 kt) | q-adj. survey 108 kt (1970s), 18 kt (1980-89); buried sand lance poorly sampled | assumption within survey range |
| Capelin biomass > 5 g | 0.05 g m^-2 (5.5 kt) | q-adj. survey 0.2-1.8 kt in the 1980s; capelin reappeared on the ESS from the late 1980s (Frank et al. 1996) | assumption (kept small but non-zero) |
| Total forage fish (check) | model 2.55 g m^-2 = 280 kt | q-adj. survey 1980-89 mean herring + sand lance + capelin = 329 kt | derived (literature agent) |

Validation targets for the collapse (not fitted):

| Quantity | Value | Source | Tag |
|---|---|---|---|
| Cod SSB 2000-02 relative to 1980-85 | ~0.06 (survey SSB 4.7 kt in 2002) | Fanning et al. 2003 Table 13 | verified (literature agent) |
| Cod survey biomass 1995-2004 / 1980-89 | 0.10 (0.13 q-adj.) | survey ratios, `literature/empirical_targets.md` section 2b | derived (literature agent) |
| Forage fish 1995-2004 / 1980-89 | ~5 (herring 6.5; sand lance and capelin ratios unstable); declined again to ~2.6 in 2005-12 | `literature/empirical_targets.md` section 3 | derived (literature agent) |
| Forage-fish peak | ~900% above pre-collapse, then decline after exhausting zooplankton | Frank et al. 2011 (Nature 477:86), abstract | verified (literature agent) |
| Other groundfish 1995-2004 / 1980-89 | haddock 0.61, silver hake 0.60, plaice 0.45 | survey ratios | derived (literature agent) |
| Adult cod natural mortality after 1990 | VPA M ages 5+ mean 0.8 (1990-2004), peak ~1.1; ~0.2 before | Mohn & Rowe 2012 (Res. Doc. 2011/138) pp. v, 5, 12; Fanning et al. 2003 p. 5 | verified (literature agent); used only in R/07 |
| Cod F after 1993 | ages 5-15 mean 0.035, recently ~0.01; exploitation < 2% | Mohn & Rowe 2012 p. v; COSEWIC 2010 p. 100 | verified (literature agent); model uses 0.02 |
| Forage-fish predation on cod eggs | North Sea herring ate 0.04-0.19% of cod eggs (Daan 1985); Baltic sprat/herring a "considerable proportion" in 1988-95, later revised downward (Köster & Möllmann 2000; Neumann et al. 2014, 2017) | `literature/empirical_targets.md` section 5 | verified (literature agent), used to judge plausible `s_egg` |
| ESS cod recruitment vs forage biomass | no relationship (Swain & Mohn 2012) | `literature/empirical_targets.md` section 2e | verified (literature agent) |

## Fishing (data/gear_params.csv, data/effort_history.csv)

Catchability is 1 for every gear-species pair, so effort equals the fishing
mortality on fully selected sizes.

| Item | Value | Source | Tag |
|---|---|---|---|
| Cod gear selectivity | logistic in length, L50 = 40 cm, L25 = 35 cm | typical of 130 mm otter-trawl mesh / longline for cod | unverified |
| Groundfish gear | L50 35 (haddock), 25 (silver hake; small-mesh fishery), 30 cm (plaice) | assumption | unverified |
| Pelagic gear | L50 20 (herring), 10 (sand lance), 11 cm (capelin) | assumption | unverified |
| Baseline cod F | 0.40 | landings / survey SSB in 1980-85 ~0.3-0.6; F above Fmax in 1988-92 (Mohn et al. 1994). At the calibrated cod biomass this gives a model yield of 74 kt yr^-1, 38 % above the 1980-85 landings (53.5 kt) | stylised / partly verified |
| Historical cod F trajectory | 0.40 (1970-79), 0.45 (1980-85), 0.70 (1986-89), 1.10 (1990-92), 0.30 (1993), 0.02 (1994-2025) | stylised from landings and survey SSB in Fanning et al. 2003 (exploitation rose sharply in the late 1980s as landings of 30-35 kt were taken from SSB of 20-50 kt); post-1993 value from bycatch landings 0.1-0.4 kt on SSB ~5-20 kt | stylised / partly verified |
| Other groundfish F | 0.30, 0.35, 0.45, 0.55, 0.30, then 0.15 from 1994 | assumption (haddock fishery closed 1993; other groundfish fisheries reduced) | unverified |
| Forage (pelagic) F | 0.10 throughout | assumption (low exploitation of ESS forage fish; sand lance and capelin unfished) | unverified |

## Resource

| Parameter | Value | Justification | Tag |
|---|---|---|---|
| lambda | 2.05 | mizer default (Sheldon spectrum) | default |
| w_pp_cutoff | 10 g | mizer default (resource includes large zooplankton and benthos) | default |
| r_pp | 2 (`default_config()`) | resource replenishment rate r_pp w^(-1/3): r_pp = 2 gives a production/biomass ratio of ~20 yr^-1 for 1 mg zooplankton, ~4 yr^-1 for 0.1 g euphausiids and 2 yr^-1 for 1 g benthos, within published P/B ranges for these groups (mizer default 10 gives 100 yr^-1 at 1 mg) | unverified |
| kappa | 1.4 (`default_config()`) | resource abundance relative to the fish; the value at which calibration to the survey targets converged with all erepro < 1 (kappa = 1 and 2 did not converge); see results/SUMMARY.md | calibration choice |

## Comparison with the published ESS mizer model (Adekoya et al. 2026)

Values used by Adekoya, Tittensor, Boyce, Fulton & Blanchard (2026, ICES J.
Mar. Sci., doi 10.1093/icesjms/fsag195), as read by the literature agent from
their species-parameter file (`literature/empirical_targets.md` section 6;
nothing from that repository was downloaded or run here):

| Species | This model: w_inf (g), l_mat (cm), age_mat (yr), a, b | Adekoya et al.: w_max (g), l_mat, age_mat, a, b | Comment |
|---|---|---|---|
| Cod | 13,300; 42; 4.5; 0.0072; 3.07 | 82,637; 66.5; 6.18; 0.00676; 3.08 | They use FishBase species-wide maxima/maturity; ours describe the smaller, earlier-maturing 4VsW cod of the 1970s-80s (L_inf ~110 cm, ICNAF 4V FishBase entry 110 cm). Biggest difference between the models. |
| Haddock | 2,800; 33; 3; 0.0052; 3.16 | 13,539; 35.0; 2.8; 0.00661; 3.08 | similar maturity; their w_max is a maximum, ours an asymptotic mean size |
| Silver hake | 610; 23; 2; 0.0046; 3.10 | 3,383; 22.9; 1.65; 0.00479; 3.11 | similar maturity |
| American plaice | 1,660; 30; 6; 0.0030; 3.30 | 4,742; 26.0; 6.43; 0.00646; 3.06 | similar age at maturity |
| Herring | 275; 25; 3.5; 0.00634; 3.03 | 733; 25.3; 3; 0.0055; 3.10 | similar maturity |
| Sand lance | 30; 13; 2; 0.0020; 2.99 | 44; 8.75; 1.5; 0.0024; 3.05 | they mature smaller and earlier |
| Capelin | 43; 14; 2.5; 0.0029; 3.23 | 54.5; 13.0; 2; 0.00363; 3.21 | similar |

Adekoya et al. needed forage-fish recruitment scaling (R_max about 8x the
steady-state value) to reproduce the forage boom (`literature/empirical_targets.md`
section 3). Their model has 19 species; it does not test alternative stable
states or forage fishing.

---

# Model v2 (main model): additional sources and choices

v2 uses the same species, life-history, kernel and baseline-biomass inputs as
v1 (copied to `data/v2/species_params.csv`, `data/v2/interaction_matrix.csv`).
Differences:

## Resource constrained by Scotian Shelf plankton data (Bundy 2004)

Source: Bundy, A. 2004. Mass balance models of the eastern Scotian Shelf
before and after the cod collapse and other ecosystem changes. Can. Tech.
Rep. Fish. Aquat. Sci. 2520 (`/home/gustav/Downloads/Fs97-6-2520-eng.pdf`,
read directly; scanned report). Tag: **verified (read in source)**.

| Quantity | Value | Where in Bundy 2004 |
|---|---|---|
| Copepod (small zooplankton, <= 10 mm) biomass, ESS, 1995-2001 | 30-34 g WW m^-2 (annual means 10-86) | Table 47, p. 61 (Head & Harris data) |
| Small zooplankton P/B | 8.4 yr^-1 (C. finmarchicus; Oithona 23) | p. 61 (McLaren et al. 1989) |
| Large zooplankton (> 10 mm; euphausiids, chaetognaths, jellies) biomass, independent estimate | 9 t km^-2 (from 3 t km^-2 krill, Sameoto & Cochrane 1996) | p. 59 |
| Large zooplankton P/B | 3.04 yr^-1 | p. 60 |
| Ecopath-balanced large / small zooplankton biomass | 16.1 / 34.0 (1980-85); 34.6 / 44.0 (1995-2000) t km^-2 (large zooplankton estimated by Ecopath at EE = 0.95) | Tables 61-62, pp. 92-93 |
| Forage fish biomass, Ecopath | capelin 0.028, sand lance 1.104, small pelagics 1.215 (1980-85); 2.90, 11.2, 8.5 (1995-2000) t km^-2 | Tables 61-62 |
| Forage fish Q/B | sand lance 7.67 / 4.07, small pelagics 4.59 / 4.60, capelin 4.67 / 6.68 yr^-1 (1980-85 / 1995-2000) | Tables 61-62 |
| Forage diets (share of large / small zooplankton) | sand lance 0.21 / 0.71, capelin 0.43 / 0.54, small pelagics 0.51 / 0.34 (1980-85); 0.72 / 0.10, 0.31 / 0.18, 0.41 / 0.44 (1995-2000) | Tables 59-60 |
| Cod (large + small) | 1.97 (1980-85), 0.17 (1995-2000) t km^-2 | Tables 61-62 |
| Haddock, plaice, silver hake (large+small) | 0.84, 1.08, 2.93 (1980-85); 0.50, 0.60, 2.56 (1995-2000) | Tables 61-62 |
| Pelagic : demersal biomass ratio | 0.3 -> 3 | Table 64, p. 95 |

Derived (this project): forage fish consumed ~13 g m^-2 yr^-1 of zooplankton
in 1980-85 (3 % of small-zooplankton production, 17 % of independently
estimated large-zooplankton production) and ~80 g m^-2 yr^-1 in 1995-2000
(7-10 % of small-zooplankton production; 52 % of the Ecopath large-zooplankton
production, ~200 % of the independent estimate).

Model choices: kappa = 3 makes the model's standing resource biomass
32 g m^-2 below 1 mg and 16 g m^-2 between 1 and 100 mg (vs 34 and 9-16).
(kappa = 2.5 was tried first; calibration then failed with erepro >> 1.)
The resource replenishment rate (P/B) is set after calibration to
1.41 w^-0.22 yr^-1, fitted through Bundy's two values (8.4 yr^-1 for
C. finmarchicus at ~0.3 mg; 3.04 yr^-1 for euphausiids at ~30 mg); it gives
8.5 and 3.06 at those sizes and 1.4 yr^-1 at 1 g (benthos P/B 0.6-2.5 in
Bundy Table 61). lambda stays at 2.05. See
`results/baseline_zooplankton_vs_bundy.csv`.

## Background early-life mortality

Eggs, larvae and small juveniles of all species experience a background
(unmodelled-predator) mortality equal to bg_MG = 0.5 times their reference
specific growth rate (alpha f0 h w^(n-1) - ks w^(p-1)), tapered as
1 / (1 + (w / 1 g)^2). Mortality-to-growth ratios of order 0.5-2 are
typical of marine fish larvae (Houde 1997, J. Fish Biol. 51A: 52-83; Beyer
1989, Dana 7: 45-147) — **unverified** (from memory). bg_MG = 1 was tried
first: the forage fish and plaice then needed erepro >> 1 (their spawners
could not fund the recruitment), so 0.5 is used; sensitivity 0, 0.25, 0.75.
A purely size-based form (Peterson & Wroblewski 1984, M = 5.26 W_dry^-0.25)
was tried and rejected because mizer's allometric growth makes the larvae of
small, slow-maturing species (sand lance, capelin, plaice) grow several times
slower than cod larvae, so the same size-based rate removed them entirely.

## Reproduction levels

Cod and other groundfish 0.1 (weak imposed density dependence, so recruitment
emerges from early-life survival and growth). Forage fish: started at 0.125
(Adekoya et al. 2026 needed forage R_max ~8x the steady-state value, i.e.
level ~0.125) and calibrated in `R/01_build_model.R` so that the cod-forced
hindcast reproduces the forage boom: **0.284** (`results/hindcast_calibration.csv`).

## Fishing (data/v2/gear_params.csv, data/v2/effort_history*.csv)

One gear per groundfish species (cod, haddock, silver_hake, plaice) plus the
pelagic gear. Cod F as in v1. F of haddock, silver hake and plaice: 0.30
until 1985, then a level for 1986-2004 calibrated so that their
1995-2004 / 1980-89 biomass ratios match the summer survey (0.61, 0.60, 0.45;
`literature/empirical_targets.md`): 0.88, 1.54, 2.40; and a level from 2005
calibrated to the 2005-12 ratios (0.72, 0.73, 0.41): 0.98, 1.33, 2.88
(`results/hindcast_calibration*.csv`). **Assumption**: these are effective
mortalities standing in for fishing plus any unmodelled post-1985 mortality;
no assessment F was available in `literature/`. The cod-forced file adds an
effective cod F from 1994 (calibrated to the survey cod ratio 0.10) that is
used only to create the observed-like post-collapse community.

Calibration targets for the hindcast (summer RV survey, not q-adjusted,
1995-2004 / 1980-89; derived by this project from
`literature/data/ess_rv_biomass_not_qadj_derived.csv`): cod 0.10, haddock
0.61, silver hake 0.60, plaice 0.45, herring + sand lance + capelin 7.87
(herring 6.55; 2005-12: 4.11). Tag: derived (literature agent's file), indicative.

# Model v3 (main model): the assumption under test and the recalibration

v3 keeps every v2 input (resource from Bundy 2004, background early-life
mortality Z/G = 0.5, reproduction level 0.1 for groundfish) and changes:

## The assumption under test: early-life vulnerability factor s

Forage fish (herring, sand lance, capelin) feed on the eggs, larvae and small
juveniles of all four groundfish (cod, haddock, silver hake, American plaice)
s = 20 times more readily than on plankton of the same size (interaction-matrix
entries forage -> groundfish = 20; all other entries 1). **Assumption, not
data.** It was chosen so that, in the recalibrated 1980-85 baseline, forage
fish cause 5.9 % of the deaths of cod between 1 mg and 1 g (5.8 % of the cohort;
`results/baseline_prerecruit_budget.csv`), i.e. at the top of the 3-5 % range
named in the brief and at the v2 threshold for an alternative state (s ~ 19
without recalibration). Applied to all four groundfish because there is no
basis for singling out cod; the sensitivity analysis varies s from 1 to 160
(recalibrated for s = 1-40; s = 80 and 160 not recalibrated, flagged).

## Calibration targets (data/v3/species_params.csv)

As v2 except cod: 1.6 g m^-2 above 100 g (176 kt) instead of 2.0, so that the
modelled cod yield at the baseline cod F (0.40) is 57 kt, within 7 % of the
1980-85 mean landings of 53.5 kt (`literature/data/cod_4VsW_landings_1958_2002.csv`;
tag: derived). The survey-based q-adjusted cod biomass is uncertain by more
than this change.

## Calibration method

`calibrate_v3n()` in `R/functions.R`: s stepped 5 -> 10 -> 20; at each step
all seven biomass targets solved simultaneously by Newton's method on the log
abundance factors (recruitment and resource pinned by `tuneSteadyState()`,
R_max = Inf while calibrating), alternated with a growth rescaling to age at
maturity (`scale_growth()`, used instead of `matchGrowth()`, see
`notes/mizer-issues.md` #4). Beverton-Holt levels imposed at the end. Result:
all biomass errors < 1 %, ages at maturity within 0.5 %, erepro <= 0.05.

## Forage reproduction level

Fitted (`R/01_build_model.R`, Step C) to the forage boom in the documented-F
hindcast, but restricted to values at least 0.05 above the level below which
the 1980-85 state is dynamically unstable (0.12). The boom cannot be reached
(target x7.9; at most x1.4 at the bound), so the fit sits on the bound:
0.17 (`results/hindcast_calibration.csv`).

## Fishing (data/v3/gear_params.csv, data/v3/effort_history.csv)

Documented cod F only: 0.40 (1970s), 0.45 (1980-85), 0.70 (1986-89), 1.10
(1990-92, "above Fmax", Mohn et al. 1994; survey Z of ages 5-8 about 1.0-1.8
in 1989-93, Fanning et al. 2003 Table 14), 0.30 (1993, closure in September),
0.02 from 1994 (mean F ages 5-15 after 1993 0.035, recently ~0.01; Mohn &
Rowe 2012). Tag: **derived from the cited summaries, not an assessment time
series**. Haddock, silver hake and plaice: 0.30, 0.35 (1980-85), 0.45
(1986-89), 0.55 (1990-92), 0.30 (1993), 0.20 from 1994. **Assumption**
(plausible groundfish F, replacing the v2 effective mortalities of 0.9-2.9).
Pelagic gear 0.10 throughout.

## Elevated adult M (alternative, run B and 07)

Adult cod (>= 35 cm) natural mortality 0.8 /yr from 1990 to 2025: VPA M of
ages 5+ mean 0.8 in 1990-2004 (Mohn & Rowe 2012, p. v) and survey Z ~ M ~ 1.0
of older ages after the closure (Fanning et al. 2003). Tag: verified in
`literature/empirical_targets.md` (sources marked [R] there).
