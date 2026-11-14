# Number check for `manuscript.tex` and `supplement.tex`

Every quantitative claim in the main text, tables and figure captions is listed below
with the value used and its source. Paths are relative to the repository root.
"Derived" means a value computed from the named file (the calculation is given).
Rounding: values are rounded in the text; the file value is given in full where useful.
Supplementary Tables S1–S7 and S9–S13 were generated programmatically from the CSV files
named in their captions (no hand transcription); they are not repeated here.

Abbreviations: `BC` = `results/baseline_calibration.csv`; `CQ` = `results/calibration_quality.csv`;
`HM` = `results/hindcast_metrics.csv`; `PB` = `results/baseline_prerecruit_budget.csv`;
`SM` = `results/sensitivity_map.csv`; `ET` = `literature/empirical_targets.md`;
`SPS` = `data/species_params_sources.md`.

## Disagreements found between `results/SUMMARY.md` and the CSV files (CSV used)

| Item | SUMMARY.md | CSV value used | File |
|---|---|---|---|
| Max biomass error of the recalibrated s variants | "<= 1.4 %" | 1.7 % (s = 40: 0.0169) | `SM` column `max_biomass_error` |
| Effective F of other groundfish in v2 | "1.5–2.9" (Sec. 11) | 0.88–2.88 (haddock 0.875 / 0.98, hake 1.54 / 1.33, plaice 2.40 / 2.88) | `results/v2/hindcast_calibration.csv`, `results/v2/hindcast_calibration_stage2.csv` |
| Run-B cod ratio, 200-bin numerical check | 0.077 | 0.081 (0.0807) | `results/numerical_checks.csv`, `B_cod_ratio_1995_2004` |
| Run-A cod ratio, TR-BDF2 | 2.15 | 2.16 (2.159) | same file, `A_cod_ratio_1995_2004` |
| Cod start 0.04 in the conditional test described as "survey SSB 1997–2002" | ~0.04 | 0.04 is the minimum (1997: 0.038; 2002: 0.039); the 1997–2002 mean is 0.086 | `results/observed_cod_ssb.csv`, `ssb_rel` (described in the paper as "the lowest survey SSB values, in 1997 and 2002") |
| Recovered cod after forage fishing from the alternative state | "4–7x" | 1.3–6.6x among persistent recoveries (1.34 for F 0.75 x 10 yr; 4.21–6.56 otherwise) | `results/forage_fishing_alt_state_grid.csv`, `cod_ssb_end_rel` |
| Feeding level of 1-kg cod in the cod-free alternative state | 0.85 | 0.84 (0.836; the 0.85 value is the forage-F = 0 state with forage x26.5) | `results/forage_fishing_equilibria.csv`, row F_forage 0.1, F_cod 0.4 (identical state: forage 19.348x) |
| Effect of switching the forage pathways off on recovery from the 2025 state | "adds about one year" | s = 1: 40 yr vs 39 (slower); resource fixed: 38; both: 37; i.e. between −2 and +1 yr | `results/pathways_diagnostic_metrics.csv` |
| Forage boom raised by the forage mechanism (factorial, elevated M) | "~60 %" | 64 % (1.844 / 1.124) with M 0.8; 60 % (1.359 / 0.851) with baseline M | `results/alt_adult_M_factorial.csv` |
| Depth of cod depletion needed for the trap at s = 20 with the survey-sized boom | "~1 %" (claim 5) | 2 % or less (cod 0.02 does not recover for good; 0.04 does) | `website/data/site_data.json` `conditional_map` (finer grid than `results/observed_like_start.csv`, which tested 0.10, 0.04, 0.01 only) |
| Herring in the bistability end state | (not mentioned; "forage x2.0") | herring extinct; sand lance 4.49x, Capelin 1.83x; forage 1.96x | derived from `results/bistability_trajectories.csv`, year 500 vs year 0 |

## Abstract

| Claim | Value | Source |
|---|---|---|
| seven species | 7 | `data/v3/species_params.csv` |
| forage share of cod deaths 1 mg–1 g | 5.9 % | `PB`, Cod, w_hi 1, forage, `share_of_deaths` 0.0595 |
| cod regained half 1980–85 SSB two years after closure | 2 yr | `HM` run A `years_to_recover50` |
| forage rose 1.4-fold vs 7.9-fold observed | 1.36; 7.87 | `HM` run A and observed row, `forage` |
| forage fishing delayed recovery from collapsed state by 2–4 years | 39 vs 41–43 | `results/forage_fishing_grid.csv`, `years_to_50pct`, `years_saved_vs_status_quo` −2 to −4 |

## Introduction

| Claim | Value | Source |
|---|---|---|
| landings 50–57 kt/yr in 1981–86 | 50–57 | `ET` §2a (Fanning et al. 2003 Table 1) |
| survey SSB peak 172 kt in 1984; 4.7 kt in 2002; 97 % decline | 171.6; 4.7 | `results/observed_cod_ssb.csv` (`SSB_t` 171591.6 in 1984, 4722.5 in 2002); `ET` §2b |
| fishery closed 1 Sept 1993 | — | `ET` §2a (Mohn & MacEachern 1994) |
| post-closure F ages 5–15 ≈0.035, recently ≈0.01 | 0.035; 0.01 | `ET` §2c (Mohn & Rowe 2012 p. v) |
| SSB 64 kt in 2009 | 64 | `ET` §2b (Mohn & Rowe 2012; Swain & Mohn 2012) |
| LRP 50 kt; below since 1992 except 2009 | 50 | `ET` §2b (DFO 2011 RPA) |
| survey index 8.2 kt (2023), 4.7 kt (2024) | 8,212 t; 4,691 t | `ET` §2b (DFO 2025) |
| Endangered 2010 | — | `ET` §2a (COSEWIC 2010) |
| P:D 0.3 → 3.0 | 0.3; 3.0 | `ET` §3 (Bundy 2005); `HM` observed row |
| forage complex ~10x (900 % increase) | 10 | `ET` §3 (Frank et al. 2011 abstract) |
| adult M ≈0.8 in 1990–2004 | 0.8 | `ET` §2d (Mohn & Rowe 2012) |
| survey Z ≈1.0 older cod after closure | 1.0 | `ET` §2d (Fanning et al. 2003 p. 5) |
| seal pup production +13 %/yr for four decades | 12.8 % | `ET` §4 (Bowen et al. 2003) |
| seals < 17 % of cod mortality | 17 % | `ET` §4 (DFO 2011 seal SAR p. 5) |
| post-closure exploitation < 2 % | 2 % | `ET` §2c (COSEWIC 2010 p. 100) |
| Adekoya et al.: 19 species, 1978–2024, forage Rmax ~8x | 19; 8 | `literature/notes.md` §0; `ET` §3 |

## Methods

| Claim | Value | Source |
|---|---|---|
| shelf area 1.1 × 10^5 km²; 1 g m⁻² = 110 kt | 110 | `SPS`; `R/functions.R` (`SHELF_AREA_KM2`) |
| mizer 3.4.0.9003; R 4.6.2; ggplot2 4.0.3; patchwork 1.3.2 | — | `packageVersion()` run in this session; `notes/mizer-issues.md` |
| 120 bins, 1 mg to 20 kg | 120; 0.001–20000 g | `R/functions.R` `default_config()$no_w`; `results/baseline_spectra.csv` (largest cod w 20000) |
| external mortality 0.6 w∞^(−1/3) (0.025/yr cod) | 0.0253 | `results/baseline_species_params.csv` `z0` |
| cod L_mat 42 cm, A_mat 4.5 yr | 42; 4.5 | `data/v3/species_params.csv`; `SPS` (unverified) |
| Capelin β = 10^4; cod σ = 2 (North Sea 1.3) | — | `SPS` kernel table |
| resource λ = 2.05, cut-off 10 g | — | `SPS` resource table |
| standing resource 32 g m⁻² (< 1 mg), 16 g m⁻² (1–100 mg) | 31.9; 16.4 | `results/v2/baseline_zooplankton_vs_bundy.csv` (v2; same resource parameters kept in v3) |
| Bundy copepods 30–34, large zooplankton 9–16 g m⁻² | — | `SPS` (Bundy 2004 Tables 47, 61–62) |
| r(w) = 1.41 w^−0.22; 8.4/yr at 0.3 mg; 3.04/yr at 30 mg | — | `R/functions.R` `rr_coef`, `rr_exp`; `SPS` |
| background Z/G = 0.5, taper above 1 g; α = 0.6, f0 = 0.6, n = 2/3, p = 0.7 | — | `R/functions.R` `background_mort_array()`; `results/baseline_species_params.csv` (`alpha`, `n`, `p`) |
| reproduction levels 0.1 (groundfish), 0.171 (forage) | 0.1; 0.1707 | `BC` `reproduction_level` |
| s = 20 for herring, sand lance, Capelin on four groundfish | 20 | `R/functions.R` `default_config()`; `CQ` `s_egg` |
| forage PPMR 10^4 to 4 × 10^5 | 10000–398849 | `data/v3/species_params.csv` `beta` |
| share at s = 1: 0.3 % | 0.31 % | `SM`, s = 1, `forage_share_cod_deaths_baseline` 0.00314 |
| North Sea herring ate 0.04–0.19 % of cod eggs | — | `ET` §5 (Daan et al. 1985) |
| baseline F: cod 0.40, other groundfish 0.30, forage 0.10 | — | `R/functions.R` `default_config()$effort` |
| cod target 1.6 g m⁻² (176 kt) above 100 g; survey 259 kt | 1.6; 259 | `data/v3/species_params.csv`; `SPS` |
| landings 53.5 kt | 53.5 | `SPS` (Fanning et al. 2003 Table 1); `data/v3/gear_params.csv` `yield_observed` 0.486 |
| s stepped 5, 10, 20 | — | `R/01_build_model.R` (`s_path = c(5, 10, cfg$s_egg)`) |
| forage target ratio 7.87 | 7.87 | `results/hindcast_calibration.csv` `target_forage_1995_2004` |
| critical forage level 0.120; bound +0.05; fit 0.171 | 0.1196; 0.1696; 0.1707 | `results/hindcast_calibration.csv` |
| gear L50 values 40, 35, 25, 30, 20, 10, 11 cm | — | `data/v3/gear_params.csv` |
| cod F history 0.40/0.45/0.70/1.10/0.30/0.02; other groundfish 0.30/0.35/0.45/0.55/0.30/0.20; pelagic 0.10 | — | `data/v3/effort_history.csv` |
| run B: M 0.8 for cod ≥ 35 cm, 1990–2025 | 0.8; 35 | `R/functions.R` `elevate_M()`; `R/02_collapse_moratorium.R` |
| survey SSB 1980–85 mean 120 kt | 120.0 | derived: mean of `results/observed_cod_ssb.csv` `SSB_t` 1980–85 = 120,046 t |
| invasion: cod at 10^−6; fit from year 10 until 10^−3 or year 150; 400-yr cod-free equilibrium | — | `R/functions.R` `invasion_test()`, `invasion_fit()`; `results/bistability_invasion.csv` |
| hysteresis F 0→2→0 step 0.1, tol 5 × 10^−4, 400 yr, floor 10^−3 | — | `R/03_bistability.R` |
| s values 1, 5, 10, 20, 40 recalibrated; 80, 160 not | — | `SM` `recalibrated` |
| forage reproduction levels 0.05–0.90 | 0.05, 0.1, 0.171, 0.2, 0.5, 0.7, 0.9 | `SM` `repro_forage` |
| OAT: cod reproduction level 0.02, 0.3, 0.6; resource ×0.5, ×2 | — | `results/sensitivity_oat.csv` |
| imposed state: forage ×7.87, haddock 0.61, hake 0.60, plaice 0.45; cod 0.10, 0.04, 0.01 | — | `R/04c_observed_like_start.R`; `results/observed_like_start.csv` |
| lowest survey SSB 1997 and 2002 ≈0.04 | 0.038; 0.039 | `results/observed_cod_ssb.csv` `ssb_rel` |
| forage-fishing grid F 0.25–3, D 5–30 / permanent; status quo 0.10 | — | `results/forage_fishing_grid.csv`, `results/forage_fishing_alt_state_grid.csv` |
| reintroduction at 10^−3 in the alternative state | — | `R/04b_forage_fishing_from_alternative_state.R` |
| persistence: ≥ 50 % in each of last 30 years | — | `R/04_forage_fishing_recovery.R` |
| adult-M programmes F 0.1, 0.5, 1, 2 for 10 or 30 yr | — | `results/alt_adult_M_forage_fishing.csv` |
| equilibria forage F 0–3, cod F 0.02 / 0.40, up to 500 yr | — | `results/forage_fishing_equilibria.csv`; `R/04_forage_fishing_recovery.R` |
| factorial to 2085 | — | `R/07_adult_mortality_alternative.R` |
| numerical checks: dt 0.025, TR-BDF2, 200 bins | — | `results/numerical_checks.csv` |

## Results 3.1 (calibrated state) and Table 2A

| Claim | Value | Source |
|---|---|---|
| biomasses within 0.6 % | max 0.006 (plaice) | `CQ` "biomass error" rows |
| model biomasses 1.60, 1.21, 1.00, 1.31, 1.50, 1.00, 0.050 g m⁻² | 1.6019, 1.2065, 1.0027, 1.3077, 1.4963, 0.9989, 0.0500 | `BC` `biomass_model_gm2` |
| ages at maturity within 0.5 % | 4.518 vs 4.5 (0.41 %), max | `BC` `age_mat_model` |
| cod yield 57.3 kt | 57.3 | `CQ`; `BC` `yield_model_gm2yr` 0.5205 × 110 |
| cod SSB 139 kt | 139.2 | `BC` `ssb_model_gm2` 1.2659 × 110 |
| erepro ≤ 0.049 | 0.0486 | `CQ` "max erepro" |
| leading eigenvalue −0.0063/yr | −0.00626 | `CQ` |
| max |log change| over 100 yr 0.15 | 0.153 | `CQ` |
| P:D 0.59 | 0.585 | `HM` `pelagic_demersal_1980_85` |
| cod survival 1 mg–1 g 2.1 % over 0.39 yr | 0.02085; 0.387 | `PB` Cod w_hi 1 |
| background 93.5 %, forage 5.9 %, groundfish 0.5 % of deaths | 0.9347; 0.0595; 0.0046 | `PB` `share_of_deaths` |
| Haddock 5.7 %, Silver Hake 6.1 %, American Plaice 11.6 % | 0.0568; 0.0614; 0.1156 | `PB` forage `share_of_deaths`, w_hi 1 |
| adult cod diet 53 % fish (22 % forage, 31 % groundfish), 47 % resource | 0.531; 0.224; 0.307; 0.469 | `results/baseline_diet_adults.csv` predator Cod (sum of herring 0.136, sand lance 0.082, capelin 0.005; cod 0.057, haddock 0.053, hake 0.083, plaice 0.113; resource 0.469) |
| fish eat 1.8 % (1 mg), 8.5 % (0.1 g), 28 % (1 g) of resource production | 0.018; 0.085; 0.284 | `results/baseline_resource_level.csv` `share_of_production_eaten` |
| collapse F 0.5 (target 0.7–1.1) | 0.5 | `CQ`; `results/calibration_cod_F_sweep.csv` |
| collapse F 0.5 for s = 1–20 | 0.5 | `results/sensitivity_collapse_F.csv` |

## Results 3.2 (hindcast, pathways) and Table 2B, Fig. 2–3

| Claim | Value | Source |
|---|---|---|
| run A cod SSB min 0.26 in 1993 | 0.2557 | `HM` `ssb_min_rel`, `year_min` |
| survey 0.19 (1992), 0.38 (1993) | 0.187; 0.383 | `results/observed_cod_ssb.csv` |
| 50 % two years after closure; 6.1x by 2025 | 2; 6.10 | `HM` run A |
| A cod ratio 2.18; A0 2.35; observed 0.10 | 2.184; 2.355; 0.10 | `HM` `cod` |
| forage 1.36 (A), 1.33 (A0), 1.84 (B); observed 7.87 | — | `HM` `forage` |
| forage 2005–12: 0.70, 0.70, 1.27; observed 4.11 | — | `HM` `forage_2005_12` |
| haddock 0.91/0.89/1.26; hake 1.14/1.10/1.86; plaice 1.02/1.00/1.56; observed 0.61/0.60/0.45 | — | `HM` |
| herring 1.35/1.31/2.21; observed 6.55 | — | `HM` `herring` |
| P:D 1995–2000: 0.83/0.81/1.17; observed 3.0 | — | `HM` |
| run B cod ratio 0.081 | 0.0813 | `HM` |
| cod SSB 2000–02: A 2.93, B 0.044; observed 0.060 | 2.928; 0.0438; 0.0601 | `results/alt_adult_M_factorial.csv` `cod_ssb_2000_02_rel_1980_85` (baseline/on = run A; elevated/on = run B); observed derived from `results/observed_cod_ssb.csv` (mean 2000–02) |
| B SSB 2 × 10^−4 by 2025; recovery 2064 = 39 yr after 2025; 71 yr from 1993 | 0.000202; 2064; 71 | `HM` `ssb_2025_rel`, `year_recover50`, `years_to_recover50`; `results/pathways_diagnostic_metrics.csv` full = 39 |
| A0 SSB 2025 6.6 | 6.59 | `HM` |
| run B 2000: forage kill 13.0 % vs 5.8 % | 0.1298; 0.0582 | `results/pathways_cod_prerecruit_budget.csv` `fraction_killed` |
| survival 2.08 % → 1.47 %; ×0.71 = ×0.73 mortality, ×0.97 growth | 0.02085; 0.01471; 0.706; 0.731; 0.968 | `results/pathways_survival_decomposition.csv` w_hi 1 |
| resource level at 1 mg 0.98 → 0.96; eaten 1.8 % → 3.9 % | 0.982; 0.961; 0.018; 0.039 | `results/pathways_resource_level.csv` |
| recovery from 2025: 39 / 40 (s = 1) / 38 (resource fixed) / 37 (both) | — | `results/pathways_diagnostic_metrics.csv` |
| Fig. 3b alternative-state survival 0.0019 %, forage kill 61 % | 1.94e-5; 0.606 | `results/bistability_invasion.csv` |

## Results 3.3 (alternative state) and Fig. 4

| Claim | Value | Source |
|---|---|---|
| two starts end at 7.0x baseline SSB | 6.962; 6.962 | `results/bistability_summary.csv` |
| forage 2.0x; sand lance 4.5x, Capelin 1.8x, herring absent; other groundfish extinct | 1.96; 4.49; 1.83; 0 | derived from `results/bistability_trajectories.csv` (year 500 / year 0) |
| 37 years from collapsed state at F = 0 | 37 | `results/bistability_summary.csv` |
| cod-free forage 19.3x (herring 22.6, sand lance 15.5, Capelin 14.3) | 19.35; 22.55; 15.48; 14.30 | `results/bistability_invasion.csv` |
| other groundfish absent in cod-free state | ~1e-17 to 1e-20 | `results/bistability_invasion.csv` |
| invasion −0.0099/yr, R² 0.99, years 10–150 | −0.00986; 0.989 | `results/bistability_invasion.csv` |
| survival 1.9 × 10^−5 vs 0.021; ~1/1000 | ratio 9.3e-4 | `results/bistability_invasion.csv` (derived ratio) |
| feeding level 1-kg cod 0.84 vs 0.52 | 0.836; 0.518 | `results/forage_fishing_equilibria.csv` (F_forage 0.1, F_cod 0.4 = cod-free state); `results/baseline_feeding_level.csv` (Cod, w = 1030 g) |
| hysteresis up: 7.0, 5.4, 4.5, 1.7 at F 0–0.3 | 6.96, 5.39, 4.47, 1.68 | derived: `results/hysteresis.csv` `cod_ssb` / `BC` Cod `ssb_model_gm2` |
| excluded at F ≥ 0.4; other groundfish 2.4x | 9.39 / 3.85 = 2.44 | `results/hysteresis.csv` `other_groundfish` / sum of `BC` `total_biomass_model_gm2` (haddock, hake, plaice) |
| down: 0.08, 2.3, 3.5, 4.4 at F 0.3, 0.2, 0.1, 0 | 0.084; 2.34; 3.49; 4.40 | derived as above |
| non-converged steps | up 0.3–0.7; down 0.3, 0.1 | `results/hysteresis.csv` `converged` |

## Results 3.4 (what it would take), Table 4, Fig. 5

| Claim | Value | Source |
|---|---|---|
| 35 recalibrated combinations recover in 2 years | all `years_to_50pct_from_1993` = 2 | `SM` rows with `recalibrated` TRUE |
| no forage boom above 2.05 | max 2.049 (s 40, 0.05) | `SM` `forage_ratio_1995_2004` |
| share 0.3, 1.6, 3.1, 5.9, 11.1, 20.1, 33.3 % | — | `SM` `forage_share_cod_deaths_baseline` |
| max biomass error 0.7, 1.4, 0.9, 0.6, 1.7 % | 0.0068, 0.0143, 0.0085, 0.0059, 0.0169 | `SM` `max_biomass_error` |
| boom ranges 0.86–1.10, 0.87–1.18, 0.89–1.23, 0.95–1.64, 1.04–2.05, 2.52–3.20, 1.56–1.71 | — | `SM` (min–max over levels) |
| invasion at R 0.17: +0.21, +0.20, +0.21, −0.010, +0.19, −0.024, −0.024 | 0.2055, 0.2047, 0.2065, −0.00986, 0.1929, −0.0236, −0.0236 | `SM` |
| alternative state at s 10 (0.05 only), s 20 (≤ 0.17), s 80/160 (all) | — | `SM` `invasion_rate` < 0 |
| baseline unstable s 40 at ≤ 0.20 | eigenvalues +0.024 … +0.006 | `SM` `baseline_eigenvalue` |
| run B years after 2025: 39–41, 40–42, 39–41, 36–41, 40–41 (s 40 NA at ≤ 0.2) | — | `SM` `B_years_to_50pct_after_2025` |
| collapse F 0.5 (s 1–20), 0.4 (s ≥ 40) | — | `results/sensitivity_collapse_F.csv` |
| OAT: invasion −0.011, −0.007, +0.003; recovery 43, 30, 15; resource −0.018, +0.20; 40, 39; hindcast 1–2 yr | −0.0108, −0.0066, +0.0033; −0.0175, +0.2025 | `results/sensitivity_oat.csv` |
| conditional: 4/9 yr (s 20), 4/6 (s 1); 0.01 trapped (26 yr then 0.025 at 150); s 1: 12; F 0.5: 4/9/14; F 1.0: 5/9/17 | — | `results/observed_like_start.csv` |
| forage at year 10 in trapped run 12x | 12.15 | `results/observed_like_start.csv` `forage_rel_year10` |
| baseline forage mortality integral 0.22; survival factor 0.80 | 0.2174; exp(−0.2174) = 0.805 | `PB` Cod w_hi 1 forage `integral` (derived) |
| eightfold boom alone: factor ≈4.6 | exp(−0.2174 × 7) = 0.218 → 1/4.58 | derived from `PB` (assumes forage mortality scales with forage biomass) |

## Results 3.5 (forage fishing), Table 4C, Fig. 6

| Claim | Value | Source |
|---|---|---|
| status quo 39 yr; programmes 41–43; all persistent | — | `results/forage_fishing_grid.csv` |
| F ≥ 0.5 for ≥ 10 yr → forage < 0.1 % of baseline | max 3.9e-4 (F 0.5, D 10) | `results/forage_fishing_grid.csv` `forage_min_rel` |
| 10-yr yields at F 0.25, 1, 3: 36, 52, 87 kt/yr | 36.2; 51.7; 86.5 | `results/forage_fishing_grid.csv` `forage_yield_during_kt_per_yr` |
| alternative state, status quo: no recovery; SSB 2.8 × 10^−4 at end | 0.000282 | `results/forage_fishing_alt_state_grid.csv` |
| thresholds: 5 yr F 2.0 (16 yr; F 1.5: 18 yr, not persistent); 10 yr F 0.75 (16–18); 15–30 yr F 0.5 (17–20); permanent F 0.25 (40; 0.5: 20; ≥ 0.75: 17) | — | `results/forage_fishing_alt_state_grid.csv` |
| recovered cod 1.3–6.6x; other groundfish do not return | 1.34–6.56; ≤ 3.1e-7 | `results/forage_fishing_alt_state_grid.csv` `cod_ssb_end_rel`, `other_groundfish_end_rel` |
| alternative state holds ~19x forage | 19.35 | `results/bistability_invasion.csv` |
| yield 1359 kt/yr (F 0.5, 10 yr) | 1359.0 | `results/forage_fishing_alt_state_grid.csv` |
| equilibria cod F 0.02: cod 4.2–7.4x | 4.21–7.35 | `results/forage_fishing_equilibria.csv` |
| forage persists only at F ≤ 0.5 | 0.237 at 0.5 (baseline start); 1.3e-9 at 0.75 | same |
| feeding level 0.60 → 0.45; weight at age 5 1.28 → 0.91 kg | 0.602 → 0.451; 1276 → 910 g | same |
| cod F 0.40: cod excluded at every forage F | ≤ 5e-9 | same |

## Results 3.6 (adult M) and Fig. 7

| Claim | Value | Source |
|---|---|---|
| SSB 2000–02: 2.93, 3.06, 0.044, 0.051; observed 0.060 | 2.928, 3.065, 0.0438, 0.0512 | `results/alt_adult_M_factorial.csv` |
| forage mechanism lowers SSB by 14 % (≈4 % of log decline) | 0.0438/0.0512 = 0.856; ln(0.856)/ln(0.0438/2.928) = 0.037 | derived from same file |
| boom 1.12 → 1.84 | 1.124; 1.844 | same, `forage_ratio_1995_2004` |
| M stays 0.8: no recovery by 2125; returns: 39 (status quo), 43 (programmes) | NA; 39; 43 | `results/alt_adult_M_forage_fishing.csv` |

## Results 3.7 (numerical robustness)

| Claim | Value | Source |
|---|---|---|
| A cod 2.15–2.18; forage 1.35–1.37 | 2.151–2.184; 1.352–1.371 | `results/numerical_checks.csv` |
| B cod 0.075–0.081; 39–41 yr; 43–46 with forage F 1 | — | same |
| invasion −0.0087 to −0.0169, R² ≥ 0.987; 200-bin error 1.0 % | — | same |

## Discussion

| Claim | Value | Source |
|---|---|---|
| fell to about a quarter, rebounded within two years | 0.26; 2 | `HM` |
| 4–9 years from imposed boom unless cod at 2 % or less | — | `results/observed_like_start.csv`; `website/data/site_data.json` `conditional_map` (s 20, boom 7.87) |
| forage share 6 % costs a fifth of survival | factor 0.805 | `PB` (derived) |
| thousand-fold reduction in alternative state | 9.3e-4 | `results/bistability_invasion.csv` |
| v2 and v3 (s = 1): 0.3 % of cod early-life deaths | v2: 0.286 % of cohort (0.29 % of deaths); v3 s 1: 0.31 % | `results/v2/baseline_prerecruit_budget.csv`; `SM` |
| v2 invasion +0.52 | 0.5217 | `results/v2/bistability_summary.csv` |
| plankton at 1 mg depleted 2 % more; growth cut survival by 3 % | 0.982 → 0.961; 0.968 | `results/pathways_resource_level.csv`; `results/pathways_survival_decomposition.csv` |
| Adekoya et al. 1000 perturbed food webs | 1000 | `literature/notes.md` §0 |
| boom 1.4 / 1.8 vs 7.9; Frank et al. ~10x | — | `HM`; `ET` §3 |
| v2 boom 9.4; cod effective F 6.3; other groundfish 0.9–2.9 | 9.40; 6.28; 0.88–2.88 | `results/v2/hindcast_calibration.csv`, `..._stage2.csv` |
| fish ate 2–4 % of plankton production at 1 mg | 1.8 %; 3.9 % | `results/pathways_resource_level.csv` |
| Ecopath: forage ate 7–10 % of small-zooplankton production, ~half (52 %) of large-zooplankton production, 1995–2000 | — | `SPS` "Derived (this project)" from Bundy (2004) Tables 59–62 |
| v3 P:D 0.59 vs 0.3; collapse F 0.5 vs 0.7–1.1 | — | `HM`; `CQ` |
| forage fishing slowed recovery 2–4 yr; F ≥ 0.5 ≥ 10 yr nearly eliminated forage | — | `results/forage_fishing_grid.csv` |
| 93 % of cod 1 mg–1 g deaths to unmodelled predators | 93.5 % | `PB` background `share_of_deaths` |
| about 6 % at s = 20 | 5.9 % | `PB` |

## Table 1 (species)

All values from `data/v3/species_params.csv` (L∞, L_mat, A_mat, a, b, β, σ, targets, cut-offs),
`results/baseline_species_params.csv` (w∞: 13317, 2785, 613, 1661, 277, 30.3, 42.6 g) and `BC`
(reproduction levels 0.1 / 0.1707). Targets in kt = g m⁻² × 110 (176, 132, 110, 143, 165, 110, 5.5).
Survey cod value 259 kt: `SPS`.

## Table 3 (versions)

| Entry | Value | Source |
|---|---|---|
| v1 resource 2 w^−1/3 | r_pp 2 | `results/v1/SUMMARY.md` §2 (κ 1.4) |
| v1 reproduction levels 0.5 / 0.75 / 0.5 | — | `results/v1/baseline_calibration.csv` `reproduction_level` |
| v2 levels 0.1 / 0.1 / 0.284 | 0.2842 | `results/v2/baseline_calibration.csv` |
| other-groundfish mortality after 1985: v1 0.45–0.55 then 0.15; v3 0.45–0.55 then 0.20 | — | `results/v1/SUMMARY.md` §4; `data/v3/effort_history.csv` |
| v2 effective F 0.88–2.88; cod 6.28 | — | `results/v2/hindcast_calibration*.csv` |
| max error 2.3 % / 61 % / 0.6 % | 0.0225; 0.6096; 0.0059 | `results/v1/sensitivity.csv` (main row); `results/v2/sensitivity.csv` (s_egg 1 row); `SM` |
| cod yield 74 / 115 / 57.3 kt | 73.7; 114.7; 57.3 | `yield_model_gm2yr` × 110 in the three `baseline_calibration.csv` files |
| forage share: v1 2.0 % of cohort 1 mg–0.1 g; v2 0.29 %; v3 5.9 % | 0.0199; 0.00286; 0.0595 | `results/v1/baseline_cod_early_life.csv`; `results/v2/baseline_prerecruit_budget.csv`; `PB` |
| boom: v1 peak 1.5x; v2 9.4; v3 1.36 | 1.504; 9.40; 1.355 | `results/v1/hindcast_metrics.csv` `forage_max_rel_1993_2025`; `results/v2/hindcast_metrics.csv`; `HM` |
| years: v1 1; v2 7 (from 2000 state); v3 2 | — | `results/v1/hindcast_metrics.csv`; `results/v2/hindcast_metrics.csv` run B; `HM` |
| invasion +0.23 / +0.52 / −0.0099 | 0.2304; 0.5217; −0.00986 | the three `bistability_summary.csv` files |

## Supplement text (S1–S6), beyond the generated tables

| Claim | Value | Source |
|---|---|---|
| q = 0.717 | 0.71667 | `results/baseline_species_params.csv` `q` |
| z0 cod 0.025 | 0.0253 | same, `z0` |
| v1: biomasses within 2.3 %; cod min 0.30 in 1993; 50 % after 1 yr; forage peak 1.50; 2.0 % kill 1 mg–0.1 g; 3.89x; +0.23 | — | `results/v1/sensitivity.csv`, `hindcast_metrics.csv`, `baseline_cod_early_life.csv`, `bistability_summary.csv` |
| v1 s 30: 45 %, 12 yr; s 100: 87 %, 90 yr, +0.12 | 0.4526, 12; 0.8656, 90, 0.1157 | `results/v1/sensitivity.csv` |
| v1 cod erepro 5.6e-5; resource level 0.98–0.99 at 1e-5–1e-3 g | 5.60e-5; 0.994, 0.990, 0.985 | `results/v1/baseline_calibration.csv`; `results/v1/baseline_resource_level.csv` |
| v2 cod +61 %, plaice +59 %; yield 115 kt | 3.219/2; 2.071/1.3 | `results/v2/baseline_calibration.csv` |
| v2 boom 9.40, 2005–12 13.3 | 9.402; 13.28 | `results/v2/hindcast_metrics.csv` |
| v2 4.3 % vs 0.29 %; survival 2.41 → 1.63 %; ×0.93, ×0.73 | — | `results/v2/pathways_cod_prerecruit_budget.csv`, `pathways_survival_decomposition.csv` |
| v2 7 years with or without pathways | 7 | `results/v2/pathways_diagnostic_metrics.csv` |
| v2 thresholds 11.8, 18.9; cod equilibrium 62 %, 8 % | 11.79; 18.91; 0.623; 0.078 | `results/v2/sensitivity_thresholds.csv`; `results/v2/sensitivity.csv` `baseline_cod_equilibrium_rel` |
| v2 effective F haddock 0.88/0.98, hake 1.54/1.33, plaice 2.40/2.88 | — | `results/v2/hindcast_calibration.csv`, `..._stage2.csv` |
| sensitivity variants error 0.7–1.7 % | — | `SM` |
| Newton step 0.05; trust region ×4.5 | h = 0.05; exp(1.5) | `R/functions.R` `solve_biomasses()` |
| equilibrium at forage F 0: 7.35 (baseline) vs absent, forage 26.5, not converged (collapsed) | — | `results/forage_fishing_equilibria.csv` |
| run_all 61 min | 1.7+1.4+11.0+8.2+3.2+0.9+27.9+5.6+1.2 = 61.1 | `logs/run_all.log` |
| package versions dplyr 1.2.1, tidyr 1.3.2 | — | `packageVersion()` in this session |

## Conditional map (Supplementary Table S14; main text Sections 2.7 and 3.4, Table 4 caption, Discussion 4.1)

Source: `website/data/site_data.json`, field `conditional_map` (150 cells: `s`, `boom`, `cod`,
`y50`, `persist`, `outcome`, `cod_end`), written by `R/08_website_data.R` (another agent's script,
same `run_scenario()` set-up; not modified here). Its 355 runs that overlap `results/` agree
exactly (`website/data/sanity_checks.csv`; `sanity.n_checks` 355, `n_agree` 355). Checked by
reading the JSON directly.

| Claim | Value | JSON cells |
|---|---|---|
| grid: s 1, 5, 10, 20, 40; boom 1, 2, 4, 7.87, 16; cod start 0.1, 0.04, 0.02, 0.01, 0.005, 0.001 | — | `conditional_map.s`, `.boom`, `.cod_start` |
| s ≤ 10: every start recovers for good, ≤ 29 years | max y50 29 (s 10, boom 16, cod 0.001); all `persist` true | s 1, 5, 10 |
| s 20: every start recovers with boom ≤ 4 | all `persist` true | s 20, boom 1, 2, 4 |
| s 20, boom 7.87: stuck at cod ≤ 0.02 (0.02: touches at 14 yr, not lasting, end 0.12; 0.01: 26 yr, end 0.025; ≤ 0.005: never) | — | s 20, boom 7.87 |
| s 20, boom 7.87: cod 0.10 → 4 yr, 0.04 → 9 yr (reproduces `results/observed_like_start.csv`) | 4; 9 | same |
| s 20, boom 16: stuck at cod ≤ 0.04 (0.04: touches at 10 yr, end 0.032); 0.10 → 3 yr | — | s 20, boom 16 |
| "2 % … about half the lowest survey value" | 0.02 vs 0.038–0.039 | `results/observed_cod_ssb.csv` (1997, 2002) |
| s 40: stuck from cod 0.10 with boom ≥ 4 (4 yr, not lasting) | — | s 40, boom 4, 7.87, 16 |
| s 40 baseline unstable, eigenvalue +0.009/yr | +0.00912 | `conditional_map.baseline_eigenvalue`; `results/sensitivity_map.csv` (s 40, R 0.171) |
| forage shares 0.3, 1.6, 3.1, 5.9, 11.1 % | — | `conditional_map.share` (= `results/sensitivity_map.csv`) |

## Title page word counts

Main text by `texcount -sub=section manuscript.tex` (text words: Introduction 970, Methods 2568,
Results 1871, Discussion 1882; 7291 in total, plus about 110 heading words); abstract 169 words
(counted on the abstract paragraph); reference list about 1900 words (`pdftotext` of the
compiled PDF). Totals change with editing; recount before submission.
