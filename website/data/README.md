# website/data

`site_data.json` is the single data source of the policy explorer page
(`website/index.html`, `website/page.html`). It is written by
`R/08_website_data.R` (run `Rscript R/08_website_data.R` from the repository
root) and inlined into the page by `python3 website/build.py`.

Other files here:

| File | What it is |
|---|---|
| `sanity_checks.csv` | every overlapping combination of the new runs compared with the existing results in `results/` (columns: check, case, metric, existing, new, abs_diff, rel_diff, agree) |
| `cache/runs.rds` | the new model runs (explorer grid and conditional map); delete it or set `REBUILD=1` to recompute (about 10-20 minutes on 4-5 cores). Not needed by the page. |

## Conventions

* **Relative values** (`*_rel`, `cod`, `forage`, `share`) are ratios. Model
  values are divided by the model's 1980-85 baseline steady state
  (`models/baseline_params.rds`; cod spawning stock 139 kt, forage biomass
  in `facts.base_forage_kt`). Observed values are divided by the 1980s mean of
  the same series (1980-85 for the assessment spawning stock, 1980-89 for the
  survey indices). 1 = the 1980s level.
* **kt** = thousand tonnes over NAFO 4VsW (1.1 x 10^5 km^2; 1 g m^-2 = 110 kt).
* **F** = fishing mortality per year. Roughly the share of a stock caught in a
  year is 1 - exp(-F).
* **Years** in the explorer and the conditional map count from the start of the
  run (year 0). For the model's 2025 state, year 0 = 2026.
* **Recovery** = cod spawning stock back to at least half its 1980-85 baseline;
  **lasting** (`persist`) = at or above that level in every one of the last 30
  years of the 150-year run (as in `R/04b_*` and `R/04c_*`).
* `null` = not reached / not applicable.

## Top-level fields

### `meta`
`generated` (time stamp), `model` ("v3 (main model)"), `mizer_version`,
`script`, `units` (text), `shelf_area_km2`.

### `facts`
Named numbers quoted in the page text; `build.py` substitutes them into
`{{name}}` placeholders, so every number in the prose comes from here.
`fact_sources` maps groups of facts to the file each was computed from.

| Group | Facts | Source |
|---|---|---|
| Landings | `landings_peak_kt`, `landings_peak_year`, `landings_1992_kt`, `landings_1993_kt`, `landings_1994_t`, `landings_2002_t`, `landings_1980s_mean_kt` | `literature/data/cod_4VsW_landings_1958_2002.csv` |
| Spawning stock | `ssb_peak_kt`, `ssb_peak_year`, `ssb_2002_kt`, `ssb_decline_frac` (fraction, peak to 2002), `ssb_1997_2002_rel`, `ssb_min_post1993_rel` (relative to 1980-85 mean) | `literature/data/cod_4VsW_assessment.csv` |
| Survey ratios (period mean / 1980-89 mean) | `survey_cod_1995_2004`, `survey_cod_2013_18`, `survey_forage_1995_2004`, `survey_forage_2005_12`, `survey_forage_2013_18`, `survey_haddock_1995_2004`, `survey_plaice_1995_2004`, `survey_hake_1995_2004` | `literature/data/ess_rv_biomass_not_qadj_derived.csv` (forage = herring + sand lance + capelin) |
| Grey seals | `seal_pups_1980`, `seal_pups_1993`, `seal_pups_2016`, `seal_pups_2021` (Sable Island pups) | `literature/data/grey_seal_sable_pups.csv` |
| Literature constants | `rv_index_2023_t`, `rv_index_2024_t` (t; DFO 2025 RV trends), `adult_M_1990_2004` (0.8 /yr), `adult_M_normal` (0.2 /yr), `north_sea_herring_egg_max_pct` (0.19 %), `seal_diet_sand_lance` (fraction), `moratorium_year` | `literature/empirical_targets.md`, `literature/counterarguments.md` |
| Conversions | `adult_M_frac_high`, `adult_M_frac_normal` = 1 - exp(-M) | computed |
| Model set-up | `s_value` (20), `cod_age_mat` (yr, model age at maturity), `adult_length_cm` (35; adult threshold of `elevate_M()`), `alt_reintro` (0.001; reintroduction level of `R/04b_*`), `cod_collapse_F_target` (text, "0.7-1.1"), `forage_share_cod_deaths` (fraction of cod deaths 1 mg-1 g caused by forage fish at baseline), `model_cod_yield_kt`, `observed_landings_kt`, `max_biomass_error` (fraction), `base_cod_ssb_kt`, `base_forage_kt`, `invasion_rate` (/yr), `alt_forage_cod_free` (forage in the cod-free state / baseline), `cod_collapse_F_model`, `status_quo_F`, `cod_bycatch_F`, `mizer_version_text` | `results/calibration_quality.csv`, `results/baseline_prerecruit_budget.csv`, `results/bistability_invasion.csv`, `data/v3/effort_history.csv` |
| Hindcast | `hindA_year_min` (year of the cod low), `hindA_*` (documented fishing only = run A), `hindB_*` (plus adult M 0.8 from 1990 = run B): `ssb_1993_rel`, `year_50`, `years_to_50` (from the 1993 low), `cod_ratio`, `forage_ratio` (1995-2004 / 1980-89), `other_min`/`other_max` (haddock, hake, plaice ratios), `ssb_2025_rel`, `mech_on/off_ssb_2000_02` and `mech_effect` (1 - on/off) | `results/hindcast_metrics.csv`, `results/alt_adult_M_factorial.csv` |
| Explorer summaries | `dep_sq_years`, `dep_prog_min_years`, `dep_prog_max_years`, `dep_delay_min`, `dep_delay_max`, `dep_start_cod_rel`, `dep_start_forage_rel`, `dep_M_any_recovery`, `all_M_any_recovery` (number of elevated-M runs with lasting recovery), `all_M_n_runs`, `alt_start_forage_rel`, `alt_min_F_D5/D10/D15/perm` (smallest forage F giving lasting recovery from the cod-free state), `alt_rec_years_min/max`, `alt_rec_cod_end_min/max`, `alt_F05_D10_yield`, `alt_F1_D10_yield` (kt/yr), `dep_hardF_forage_low_max` (highest whole-run forage low point over forage F >= 0.5 for >= 10 years from the 2025 state), `dep_sq_forage_low` (same, status quo) | new runs (`cache/runs.rds`) |
| Survey-like starts | `ols_*` | `results/observed_like_start.csv` |
| Sensitivity | `sens_max_boom`, `sens_min_boom`, `sens_max_years`, `sens_share_min`, `sens_share_max`, `sens_n_rec`, `sens_share_s80`, `sens_share_s160`, `map_stuck_cells`, `map_cells`, `map_cells_per_panel`, `map_stuck_low_s` (stuck cells at s <= 10), `map_stuck_s20`, `map_stuck_s40`, `map_share_s10/s20/s40`, `map_s40_eigenvalue`, `map_s20_cod04_boom787_years`, `map_s20_cod10_boom787_years` | `results/sensitivity_map.csv`, new map runs |
| Equilibria | `eq_cod_w5_sq_kg`, `eq_cod_w5_F1_kg` (cod weight at age 5, kg, long-run state at forage F 0.1 and 1, cod F 0.02) | `results/forage_fishing_equilibria.csv` |
| Checks | `sanity_n`, `sanity_agree` | `sanity_checks.csv` |
| Numerical | `numcheck_max_shift_yr` (largest change in years to 50 % across dt, solver and grid checks) | `results/numerical_checks.csv` |

### `observed` (observations only)
* `landings`: `year` (1958-2002), `kt` (total nominal landings).
* `ssb`: `year` (1970-2002), `kt` (survey-based, q-corrected spawning stock biomass), `rel` (/ 1980-85 mean).
* `survey`: `year` (1970-2018), `cod_rel`, `forage_rel` (summer RV survey stratified biomass, not q-adjusted, / 1980-89 mean; forage = herring + sand lance + capelin; 0 = no record).
* `survey_periods`: list of `{period, start, end, cod, forage, haddock, silver_hake, plaice, herring}` period-mean ratios.
* `seals`: `year`, `sable_pups` (pup production, Sable Island; years with an estimate only).

### `hindcast`
`year` (1970-2025) and `runs`, each with `cod_ssb_rel` and `forage_rel`
(yearly, 3 significant digits), from `results/alt_adult_M_factorial_traj.csv`:

| Run | Meaning |
|---|---|
| `fishing_only` | documented fishing, s = 20 (same as run A of `R/02_*`) |
| `fishing_only_s1` | same, forage -> groundfish vulnerability set to 1 from 1990 (diagnostic) |
| `high_M` | documented fishing + adult cod (>= 35 cm) natural mortality 0.8 /yr from 1990, s = 20 (run B; labelled alternative) |
| `high_M_s1` | same with s = 1 from 1990 (diagnostic) |

### `explorer` (new runs)
430 runs: 5 starting states x 2 adult-M settings x (status quo + 7 forage F x 6 durations), 150 years each, set up as in `R/04_*`, `R/04b_*`, `R/04c_*` and `R/07_*`. Only fishing effort, initial state and the labelled adult-M alternative differ.

* `t`: the years stored for every trajectory (0-30 yearly, 32-60 every 2, 65-150 every 5).
* `F_levels`: forage (pelagic gear) F during the programme; 0.1 = status quo (no programme).
* `D_levels`: programme durations in years; `permanent_D` (150) = the whole run.
* `status_quo_F` (0.1), `cod_bycatch_F` (0.02), `horizon` (150), `encoding` (text).
* `runs`: object keyed `"<start>|<M>|<F>|<D>"`; the status quo is stored once per start x M with D = 5.
  * `<start>`: `depleted_2025` (`models/collapsed_2025_params.rds`: run B 2025 state), `alt_state` (`models/alternative_state_params.rds`: cod-free state, groundfish reintroduced at 1e-3), `boom_cod10`, `boom_cod04`, `boom_cod01` (1980s spectra x survey ratios: forage x7.87, haddock 0.61, hake 0.60, plaice 0.45, cod 0.10 / 0.04 / 0.01, as `R/04c_*`).
  * `<M>`: `baseline` (baseline parameters) or `elevated` (`elevate_M()` on the baseline parameters: adult cod M 0.8 /yr for the whole run).
  * Each run has:

| Field | Unit | Meaning |
|---|---|---|
| `y50`, `y100` | years | first year cod SSB >= 50 % / 100 % of baseline |
| `persist` | bool | lasting recovery (see Conventions) |
| `cod_end` | rel | cod SSB in year 150 |
| `f_min` | rel | lowest forage biomass over the whole 150-year run (as `forage_min_rel` in `results/forage_fishing_grid.csv`); the page shows this one |
| `f_min_prog` | rel | lowest forage biomass from year 0 to the end of the programme |
| `f_end_prog`, `f_end` | rel | forage biomass at the end of the programme / in year 150 |
| `fy_mean`, `fy_total` | kt/yr, kt | forage-fish yield during the programme (mean per year, total) |
| `cy60` | kt | cod yield summed over years 0-59 |
| `ogf_end` | rel | haddock + silver hake + plaice biomass in year 150 |
| `cod`, `forage` | encoded | cod SSB and forage biomass at the years in `t`, as round(100 x log10(rel)), floored at -1200 (1e-12) |
| `fy`, `cy` | kt/yr | forage-fish and cod yield at the years in `t` (3 significant digits; < 0.01 shown as 0) |

### `sensitivity_documented`
Rows of `results/sensitivity_map.csv` (documented-fishing hindcast at each s x forage reproduction level): `s`, `recalibrated`, `share` (forage share of cod 1 mg-1 g deaths at baseline), `repro_forage`, `boom` (forage 1995-2004 / 1980-89), `years_to_50` (from the 1993 low), `outcome` (class from `R/05_*`), `invasion_rate` (/yr).

### `conditional_map` (new runs)
Imposed survey-like starts (as `R/04c_*`: other groundfish at survey ratios) crossed over `s` (1, 5, 10, 40: recalibrated variants in `models/sensitivity/`; 20: main model), `boom` (forage factor at the start), `cod_start` (cod factor at the start); moratorium effort, baseline adult M, 150 years. `share` = forage share of cod 1 mg-1 g deaths at baseline for each s (as computed in `R/05_*`). `baseline_eigenvalue` and `baseline_stable` give, per s, the leading eigenvalue of that variant's 1980s state at the main forage reproduction level (from `results/sensitivity_map.csv`; s = 40 is unstable, so its long-run cells are flagged on the page). `cells`: `{s, boom, cod, y50, persist, outcome, cod_end}` with `outcome` one of `fast` (lasting recovery, y50 <= 10), `slow` (11-30), `very_slow` (> 30), `stuck` (no lasting recovery in 150 years). Varying s is the sensitivity analysis itself (as in `R/05_*`); the s = 20 cells at boom 7.87 reproduce `results/observed_like_start.csv`.

### `sanity`
`n_checks`, `n_agree`, `file`.
