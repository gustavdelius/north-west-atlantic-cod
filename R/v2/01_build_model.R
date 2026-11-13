# 01_build_model.R  (v2)
# ---------------------------------------------------------------------------
# Acceptance test 1 for model v2: build the pre-collapse (1980-85) steady
# state, then calibrate the hindcast so that it reproduces the observed
# post-collapse community (forage-fish boom, declines of the other
# groundfish).
#
# Step A  static calibration (build_model(); cached in models/calibration_cache.rds;
#         delete the cache or set REBUILD=1 to recalibrate, ~1 h).
# Step B  hindcast calibration. Five quantities are fitted to the summer RV
#         survey ratios 1995-2004 / 1980-89 (literature/empirical_targets.md):
#           * forage-fish reproduction level  -> forage complex x7.9
#           * F of haddock, silver hake, plaice from 1986 -> 0.61, 0.60, 0.45
#           * an effective cod F from 1994 used ONLY in this calibration run,
#             which forces cod along its observed path (survey ratio 0.10)
#         The forced-cod run is a calibration device: it creates the
#         observed post-collapse community without assuming why cod stayed
#         low. The real moratorium (cod F = 0.02 from 1994) is run in 02.
#
# Outputs
#   models/baseline_params.rds, models/calibration_cache.rds
#   data/v2/effort_history.csv (moratorium; cod F 0.02 from 1994)
#   data/v2/effort_history_codforced.csv (calibration device)
#   results/hindcast_calibration.csv, results/baseline_*.csv
#   figures/fig1_baseline.(png|pdf)
# ---------------------------------------------------------------------------
source("R/v2/functions.R")
suppressPackageStartupMessages({
    library(ggplot2); library(patchwork); library(dplyr); library(tidyr)
})
set.seed(1)
for (d in c("models/v2", "results/v2", "figures/v2")) dir.create(d, showWarnings = FALSE)
options(mizer_info_level = 0)
cfg <- default_config()

# --- Step A: static calibration ----------------------------------------------
cache <- "models/v2/calibration_cache.rds"
if (file.exists(cache) && Sys.getenv("REBUILD") == "") {
    params <- readParams(cache)
} else {
    params <- build_model(cfg)
    saveParams(params, cache)
}
reproduction_level(params) <- repro_levels(cfg, species_params(params)$species)
# data-constrained plankton/benthos P/B (steady state unchanged; see functions.R)
params <- set_resource_rate(params, cfg)
spn <- species_params(params)$species

# --- Step B: hindcast calibration ---------------------------------------------
targets <- c(Cod = 0.10, Haddock = 0.61, `Silver hake` = 0.60,
             `American plaice` = 0.45, Forage = 7.87)
# Stage 1 (targets 1995-2004) sets the 1986-2004 levels; stage 2 (targets
# 2005-12) sets the levels from 2005 on, so that the groundfish settle near
# their observed 2005-12 levels instead of declining for ever.
make_effort <- function(F_gf, F_cod_post, F_gf2 = F_gf, F_cod2 = F_cod_post) {
    data.frame(year = c(1970, 1980, 1986, 1990, 1993, 1994, 2005),
               cod = c(0.40, 0.45, 0.70, 1.10, 0.30, F_cod_post, F_cod2),
               haddock = c(0.30, 0.30, rep(F_gf[1], 4), F_gf2[1]),
               silver_hake = c(0.30, 0.30, rep(F_gf[2], 4), F_gf2[2]),
               plaice = c(0.30, 0.30, rep(F_gf[3], 4), F_gf2[3]),
               pelagic = 0.10)
}
hindcast_ratios <- function(x, end = 2004) {
    p <- params
    rl <- reproduction_level(p); rl[FORAGE] <- plogis(x[5]); reproduction_level(p) <- rl
    eff <- make_effort(exp(x[2:4]), exp(x[1]))
    df <- run_scenario(p, eff, years = c(1970, end))
    c(Cod = period_ratio(df, "Cod"), Haddock = period_ratio(df, "Haddock"),
      `Silver hake` = period_ratio(df, "Silver hake"),
      `American plaice` = period_ratio(df, "American plaice"),
      Forage = period_ratio(df, FORAGE))
}
obj <- function(x) {
    r <- tryCatch(hindcast_ratios(x), error = function(e) rep(NA, 5))
    if (any(!is.finite(r)) || any(r <= 0)) return(1e6)
    sum(log(r / targets)^2)
}
cal_file <- "results/v2/hindcast_calibration.csv"
if (file.exists(cal_file) && Sys.getenv("REBUILD") == "") {
    cal <- read.csv(cal_file)
    xbest <- c(log(cal$F_cod_forced[1]), log(cal$F_haddock[1]), log(cal$F_silver_hake[1]),
               log(cal$F_plaice[1]), qlogis(cal$repro_forage[1]))
} else {
    x0 <- c(log(1.0), log(0.5), log(0.5), log(0.6), qlogis(cfg$repro_forage))
    fit <- optim(x0, obj, method = "Nelder-Mead", control = list(maxit = 250, reltol = 1e-4))
    xbest <- fit$par
    r <- hindcast_ratios(xbest)
    cal <- data.frame(F_cod_forced = exp(xbest[1]), F_haddock = exp(xbest[2]),
                      F_silver_hake = exp(xbest[3]), F_plaice = exp(xbest[4]),
                      repro_forage = plogis(xbest[5]), objective = fit$value,
                      convergence = fit$convergence, evaluations = fit$counts[1])
    cal <- cbind(cal, as.data.frame(t(setNames(targets, paste0("target_", names(targets))))),
                 as.data.frame(t(setNames(r, paste0("model_", names(r))))))
    write.csv(cal, cal_file, row.names = FALSE)
}
print(cal)

# stage 2: groundfish F from 2005 to match the 2005-12 survey ratios (the
# cod-forcing device is kept at its stage-1 value, so cod stays collapsed as
# observed); the forage ratio 2005-12 is not fitted (validation, observed 4.11)
targets2 <- c(Haddock = 0.72, `Silver hake` = 0.73, `American plaice` = 0.41)
cal2_file <- "results/v2/hindcast_calibration_stage2.csv"
pcal <- params; rl <- reproduction_level(pcal); rl[FORAGE] <- cal$repro_forage[1]
reproduction_level(pcal) <- rl
F1 <- c(cal$F_haddock[1], cal$F_silver_hake[1], cal$F_plaice[1])
ratios2 <- function(y) {
    eff <- make_effort(F1, cal$F_cod_forced[1], exp(y), cal$F_cod_forced[1])
    df <- run_scenario(pcal, eff, years = c(1970, 2012))
    c(Haddock = period_ratio(df, "Haddock", num = 2005:2012),
      `Silver hake` = period_ratio(df, "Silver hake", num = 2005:2012),
      `American plaice` = period_ratio(df, "American plaice", num = 2005:2012),
      Forage = period_ratio(df, FORAGE, num = 2005:2012),
      Cod = period_ratio(df, "Cod", num = 2005:2012))
}
if (file.exists(cal2_file) && Sys.getenv("REBUILD") == "") {
    cal2 <- read.csv(cal2_file)
} else {
    obj2 <- function(y) { r <- tryCatch(ratios2(y)[1:3], error = function(e) rep(NA, 3))
        if (any(!is.finite(r)) || any(r <= 0)) return(1e6); sum(log(r / targets2)^2) }
    fit2 <- optim(log(F1), obj2, method = "L-BFGS-B", lower = log(rep(0.02, 3)), upper = log(rep(5, 3)),
                  control = list(maxit = 60))
    r2 <- ratios2(fit2$par)
    cal2 <- data.frame(F_haddock_2005 = exp(fit2$par[1]), F_silver_hake_2005 = exp(fit2$par[2]),
                       F_plaice_2005 = exp(fit2$par[3]), objective = fit2$value)
    cal2 <- cbind(cal2, as.data.frame(t(setNames(c(targets2, 4.11), paste0("target_", c(names(targets2), "Forage_validation"))))),
                  as.data.frame(t(setNames(r2, paste0("model_", names(r2))))))
    write.csv(cal2, cal2_file, row.names = FALSE)
}
print(cal2)
F2 <- c(cal2$F_haddock_2005[1], cal2$F_silver_hake_2005[1], cal2$F_plaice_2005[1])

rl <- reproduction_level(params); rl[FORAGE] <- cal$repro_forage[1]
reproduction_level(params) <- rl
params <- setMetadata(params,
    title = "Eastern Scotian Shelf (NAFO 4VsW) cod-forage model v2: 1980-85 baseline",
    description = paste("Seven-species mizer model with Scotian-Shelf-constrained plankton resource,",
                        "community-wide early-life background mortality and hindcast-calibrated",
                        "forage-fish reproduction. Units g m^-2; 1 g m^-2 = 110 kt. See results/SUMMARY.md."))
saveParams(params, "models/v2/baseline_params.rds")

eh <- make_effort(F1, 0.02, F2, 0.02)
eh <- rbind(eh, transform(eh[nrow(eh), ], year = 2025))
eh$note <- c("baseline 1970s", "1980-85", "1986-89 (groundfish F stage-1 calibrated)",
             "1990-92", "1993 (cod moratorium from Sept)", "moratorium: cod bycatch 0.02",
             "2005 on: groundfish F stage-2 calibrated", "end of hindcast")
write.csv(eh, file.path(DATA_DIR, "effort_history.csv"), row.names = FALSE)
ehf <- eh
ehf$cod[ehf$year >= 1994 & ehf$year < 2005] <- cal$F_cod_forced[1]
ehf$cod[ehf$year >= 2005] <- cal$F_cod_forced[1]
ehf$note[ehf$year >= 1994] <- "calibration device: effective cod F that keeps cod on its observed path"
write.csv(ehf, file.path(DATA_DIR, "effort_history_codforced.csv"), row.names = FALSE)

# --- baseline diagnostics ------------------------------------------------------
sp <- species_params(params)
res <- getSteadyResidual(params)
drift <- rowSums(res) / getBiomass(params)
stab <- getStability(params)
diag <- data.frame(
    quantity = c("isSteady", "max_relative_biomass_drift_per_yr",
                 "stability_max_real_eigenvalue", "kappa", "resource_PB_coef_exp", "s_egg",
                 paste0("reproduction_level_", spn), paste0("erepro_", spn)),
    value = c(as.character(isSteady(params)), signif(max(abs(drift)), 3),
              signif(stab$max_real_part, 3), cfg$kappa, paste(cfg$rr_coef, cfg$rr_exp), cfg$s_egg,
              signif(reproduction_level(params), 3), signif(sp$erepro, 3)))
write.csv(diag, "results/v2/baseline_diagnostics.csv", row.names = FALSE)
print(diag)

Bc <- getBiomass(params, min_w = sp$biomass_cutoff)
calib <- data.frame(species = spn, biomass_cutoff_g = sp$biomass_cutoff,
                    biomass_observed_gm2 = sp$biomass_observed,
                    biomass_model_gm2 = as.numeric(Bc),
                    total_biomass_model_gm2 = as.numeric(getBiomass(params)),
                    ssb_model_gm2 = as.numeric(getSSB(params)),
                    yield_model_gm2yr = as.numeric(getYield(params)),
                    age_mat_target = sp$age_mat, age_mat_model = as.numeric(age_mat(params)),
                    reproduction_level = as.numeric(reproduction_level(params)),
                    erepro = sp$erepro)
calib$ssb_observed_gm2 <- ifelse(spn == "Cod", 120 / 110, NA)
calib$yield_observed_gm2yr <- ifelse(spn == "Cod", 53.5 / 110, NA)
write.csv(calib, "results/v2/baseline_calibration.csv", row.names = FALSE)
write.csv(as.data.frame(sp), "results/v2/baseline_species_params.csv", row.names = FALSE)
print(calib[, c("species", "biomass_observed_gm2", "biomass_model_gm2", "ssb_model_gm2",
                "yield_model_gm2yr", "age_mat_model", "erepro")])

# early-life budgets for all groundfish
budgets <- bind_rows(lapply(GROUNDFISH, function(s) bind_rows(
    mutate(prerecruit_budget(params, s, 0.001, 1), species = s),
    mutate(prerecruit_budget(params, s, 0.001, 10), species = s))))
write.csv(budgets, "results/v2/baseline_prerecruit_budget.csv", row.names = FALSE)
print(budgets |> filter(species == "Cod"))

# resource: level and share of production eaten by fish, vs size
rl_df <- data.frame(w = c(1e-5, 1e-4, 1e-3, 1e-2, 0.1, 1, 5),
                    resource_level = resource_level_at(params),
                    share_of_production_eaten = resource_consumption_share(params))
write.csv(rl_df, "results/v2/baseline_resource_level.csv", row.names = FALSE)
print(rl_df)

# zooplankton biomass and production in the model vs Bundy (2004)
wf <- params@w_full; dwf <- params@dw_full; nr <- initialNResource(params); rr <- resource_rate(params)
band <- function(lo, hi) { s <- wf >= lo & wf < hi
    c(biomass = sum(nr[s] * wf[s] * dwf[s]), production = sum(rr[s] * nr[s] * wf[s] * dwf[s])) }
zoo <- rbind(`small zooplankton (<1 mg)` = band(1e-6, 1e-3),
             `large zooplankton (1-100 mg)` = band(1e-3, 0.1),
             `0.1-10 g (benthos/macrozooplankton)` = band(0.1, 10))
zoo <- data.frame(band = rownames(zoo), zoo, row.names = NULL)
zoo$bundy_biomass <- c(34, 9, NA); zoo$bundy_PB <- c(8.4, 3.04, NA)
zoo$model_PB <- zoo$production / zoo$biomass
write.csv(zoo, "results/v2/baseline_zooplankton_vs_bundy.csv", row.names = FALSE)
print(zoo)

spec <- as.data.frame(as.table(initialN(params))) |> setNames(c("species", "w", "n")) |>
    mutate(w = as.numeric(as.character(w)), biomass_per_logw = n * w^2) |> filter(n > 0)
res_df <- data.frame(species = "Resource", w = wf, n = as.numeric(nr)) |>
    mutate(biomass_per_logw = n * w^2) |> filter(n > 0, w <= 10, w >= 1e-6)
spectra <- bind_rows(spec, res_df)
write.csv(spectra, "results/v2/baseline_spectra.csv", row.names = FALSE)
fl <- as.data.frame(as.table(getFeedingLevel(params))) |> setNames(c("species", "w", "feeding_level")) |>
    mutate(w = as.numeric(as.character(w))) |>
    left_join(data.frame(species = spn, w_max = sp$w_max), by = "species") |>
    filter(w <= w_max) |> select(-w_max)
write.csv(fl, "results/v2/baseline_feeding_level.csv", row.names = FALSE)
gc <- getGrowthCurves(params, max_age = 15)
growth <- as.data.frame(as.table(gc)) |> setNames(c("species", "age", "w")) |>
    mutate(age = as.numeric(as.character(age)))
vb <- expand.grid(species = spn, age = seq(0, 15, by = 0.25), stringsAsFactors = FALSE) |>
    left_join(data.frame(species = spn, l_inf = sp$l_inf, k_vb = sp$k_vb, a = sp$a, b = sp$b), by = "species") |>
    mutate(w = a * (l_inf * (1 - exp(-k_vb * age)))^b)
growth_out <- bind_rows(mutate(growth, source = "model"),
                        mutate(select(vb, species, age, w), source = "von Bertalanffy (FishBase)"))
write.csv(growth_out, "results/v2/baseline_growth.csv", row.names = FALSE)
diet_all <- lapply(spn, function(s) {
    d <- diet_summary(params, s, min_w = sp[s, "w_mat"] / 2, max_w = sp[s, "w_inf"])
    data.frame(predator = s, prey = names(d), proportion = as.numeric(d))
}) |> bind_rows()
write.csv(diet_all, "results/v2/baseline_diet_adults.csv", row.names = FALSE)
mc <- mort_components(params, "Cod")
write.csv(mc, "results/v2/baseline_cod_mortality.csv", row.names = FALSE)

# --- Figure 1 -------------------------------------------------------------------
sp_lev <- c(spn, "Resource")
pA <- calib |> select(species, Observed = biomass_observed_gm2, Model = biomass_model_gm2) |>
    pivot_longer(-species, names_to = "source", values_to = "biomass") |>
    mutate(species = factor(species, levels = spn)) |>
    ggplot(aes(species, gm2_to_kt(biomass), fill = source)) +
    geom_col(position = position_dodge(width = 0.75), width = 0.7) +
    scale_fill_manual(values = c(Observed = "grey60", Model = "#0072B2")) +
    labs(x = NULL, y = "Biomass above survey cut-off (kt)", fill = NULL, title = "a  Calibration (1980-85)") +
    theme_paper() + theme(axis.text.x = element_text(angle = 35, hjust = 1), legend.position = c(0.8, 0.85))
pB <- spectra |> mutate(species = factor(species, levels = sp_lev)) |>
    ggplot(aes(w, biomass_per_logw, colour = species)) + geom_line(linewidth = 0.7) +
    scale_x_log10(limits = c(1e-6, 3e4)) + scale_y_log10(limits = c(1e-4, NA)) +
    scale_colour_manual(values = SPECIES_COLOURS[sp_lev]) +
    labs(x = "Body mass (g)", y = expression("Biomass density (g m"^-2*" per ln w)"), colour = NULL,
         title = "b  Size spectra") + theme_paper()
pC <- growth_out |> filter(age <= 12) |> mutate(species = factor(species, levels = spn)) |>
    ggplot(aes(age, w, colour = species, linetype = source)) + geom_line(linewidth = 0.6) +
    scale_y_log10() + scale_colour_manual(values = SPECIES_COLOURS[spn], guide = "none") +
    scale_linetype_manual(values = c(model = "solid", "von Bertalanffy (FishBase)" = "dashed")) +
    labs(x = "Age (years)", y = "Body mass (g)", linetype = NULL, title = "c  Growth") +
    theme_paper() + theme(legend.position = c(0.65, 0.15))
pD <- fl |> mutate(species = factor(species, levels = spn)) |>
    ggplot(aes(w, feeding_level, colour = species)) + geom_line(linewidth = 0.6) +
    scale_x_log10() + scale_colour_manual(values = SPECIES_COLOURS[spn], guide = "none") +
    coord_cartesian(ylim = c(0, 1)) + labs(x = "Body mass (g)", y = "Feeding level", title = "d  Feeding level") +
    theme_paper()
mlong <- mc |> filter(w <= 3000) |> select(-growth) |>
    pivot_longer(-w, names_to = "source", values_to = "mortality") |>
    mutate(source = factor(source, levels = c("background", "forage", "groundfish", "fishing", "other_external")))
pE <- ggplot(filter(mlong, mortality > 1e-3), aes(w, mortality, colour = source)) + geom_line(linewidth = 0.8) +
    scale_x_log10() + scale_y_log10() +
    scale_colour_manual(values = c(background = "grey50", forage = "#D55E00", groundfish = "#0072B2",
                                   fishing = "black", other_external = "#CC79A7")) +
    labs(x = "Cod body mass (g)", y = expression("Mortality rate (yr"^-1*")"), colour = NULL,
         title = "e  Mortality of cod by source") + theme_paper()
pF <- ggplot(rl_df, aes(w, resource_level)) + geom_line() + geom_point() + scale_x_log10() +
    coord_cartesian(ylim = c(0, 1)) +
    labs(x = "Resource body mass (g)", y = "Resource level (abundance / capacity)",
         title = "f  Plankton and benthos depletion") + theme_paper()
save_fig((pA | pB) / (pC | pD) / (pE | pF), "fig1_baseline", width = 11, height = 12)
cat("01_build_model.R done\n")
