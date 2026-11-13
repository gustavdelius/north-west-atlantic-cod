# 01_build_model.R
# ---------------------------------------------------------------------------
# Acceptance test 1: build and calibrate the pre-collapse (1980-85),
# cod-dominated steady state of the eastern Scotian Shelf (NAFO 4VsW) model.
#
# Outputs
#   models/baseline_params.rds           (saveParams)
#   results/baseline_calibration.csv     observed vs modelled biomass, SSB, yield
#   results/baseline_species_params.csv  all species parameters used
#   results/baseline_spectra.csv, baseline_feeding_level.csv,
#   results/baseline_growth.csv, baseline_diet_cod.csv,
#   results/baseline_cod_mortality.csv, baseline_resource_level.csv,
#   results/baseline_diagnostics.csv     steady residual, stability, etc.
#   figures/fig1_baseline.(png|pdf)
# Run from the repository root:  Rscript R/v1/01_build_model.R
# ---------------------------------------------------------------------------
source("R/v1/functions.R")
suppressPackageStartupMessages({
    library(ggplot2); library(patchwork); library(dplyr); library(tidyr)
})
set.seed(1)
dir.create("models/v1", showWarnings = FALSE)
dir.create("results/v1", showWarnings = FALSE)
dir.create("figures/v1", showWarnings = FALSE)

cfg <- default_config()
# The calibration takes ~40 min. build_model() is deterministic, so its raw
# result is cached in models/calibration_cache.rds; delete that file (or set
# the environment variable REBUILD=1) to recalibrate from scratch.
cache <- "models/v1/calibration_cache.rds"
if (file.exists(cache) && Sys.getenv("REBUILD") == "") {
    params <- readParams(cache)
} else {
    params <- build_model(cfg)
    saveParams(params, cache)
}
# reproduction levels as configured (no effect on the steady state)
reproduction_level(params) <- repro_levels(cfg, species_params(params)$species)
params <- setMetadata(params,
    title = "Eastern Scotian Shelf (NAFO 4VsW) cod-forage fish model: 1980-85 baseline",
    description = paste("Seven-species mizer model (cod, haddock, silver hake, American plaice,",
                        "herring, sand lance, capelin) calibrated to a pre-collapse steady state.",
                        "Units g m^-2; 1 g m^-2 = 100 kt over 1e5 km^2. See results/SUMMARY.md."))
saveParams(params, "models/v1/baseline_params.rds")

options(mizer_info_level = 0)
sp <- species_params(params)
spn <- sp$species

# --- convergence diagnostics ------------------------------------------------
res <- getSteadyResidual(params)
drift <- rowSums(res) / getBiomass(params)       # relative biomass drift per year
stab <- getStability(params)
diag <- data.frame(
    quantity = c("isSteady", "max_relative_biomass_drift_per_yr",
                 "tuneSteadyState_attractor", "stability_max_real_eigenvalue",
                 "stability_dominant_period_yr", "kappa", "r_pp", "s_egg",
                 paste0("reproduction_level_", spn), paste0("erepro_", spn)),
    value = c(as.character(isSteady(params)), signif(max(abs(drift)), 3),
              as.character(attr(params, "convergence")$attractor),
              signif(stab$max_real_part, 3), signif(stab$dominant_period, 3),
              cfg$kappa, cfg$r_pp, cfg$s_egg,
              signif(reproduction_level(params), 3), signif(sp$erepro, 3)))
write.csv(diag, "results/v1/baseline_diagnostics.csv", row.names = FALSE)
print(diag)

# --- calibration table ------------------------------------------------------
Bc <- getBiomass(params, min_w = sp$biomass_cutoff)
calib <- data.frame(
    species = spn,
    biomass_cutoff_g = sp$biomass_cutoff,
    biomass_observed_gm2 = sp$biomass_observed,
    biomass_model_gm2 = as.numeric(Bc),
    total_biomass_model_gm2 = as.numeric(getBiomass(params)),
    ssb_model_gm2 = as.numeric(getSSB(params)),
    yield_model_gm2yr = as.numeric(getYield(params)),
    w_inf_g = sp$w_inf, w_mat_g = sp$w_mat,
    age_mat_target = sp$age_mat,
    age_mat_model = as.numeric(age_mat(params)),
    reproduction_level = as.numeric(reproduction_level(params)),
    erepro = sp$erepro)
calib$ssb_observed_gm2 <- ifelse(spn == "Cod", 120 / 110, NA)  # 1980-85 survey SSB, 120 kt
calib$yield_observed_gm2yr <- ifelse(spn == "Cod", 53.5 / 110, NA) # 1980-85 landings, 53.5 kt
write.csv(calib, "results/v1/baseline_calibration.csv", row.names = FALSE)
write.csv(as.data.frame(sp), "results/v1/baseline_species_params.csv", row.names = FALSE)
print(calib[, c("species", "biomass_observed_gm2", "biomass_model_gm2", "ssb_model_gm2",
                "yield_model_gm2yr", "age_mat_target", "age_mat_model")])

# --- spectra, feeding level, growth, diet, mortality -------------------------
w <- w(params)
spec <- as.data.frame(as.table(initialN(params))) |>
    setNames(c("species", "w", "n")) |>
    mutate(w = as.numeric(as.character(w)), biomass_per_logw = n * w^2) |>
    filter(n > 0)
wr <- params@w_full
res_df <- data.frame(species = "Resource", w = wr,
                     n = as.numeric(initialNResource(params))) |>
    mutate(biomass_per_logw = n * w^2) |> filter(n > 0, w <= 10, w >= 1e-5)
spectra <- bind_rows(spec, res_df)
write.csv(spectra, "results/v1/baseline_spectra.csv", row.names = FALSE)

fl <- as.data.frame(as.table(getFeedingLevel(params))) |>
    setNames(c("species", "w", "feeding_level")) |>
    mutate(w = as.numeric(as.character(w))) |>
    left_join(data.frame(species = spn, w_max = sp$w_max), by = "species") |>
    filter(w <= w_max) |> select(-w_max)
write.csv(fl, "results/v1/baseline_feeding_level.csv", row.names = FALSE)

gc <- getGrowthCurves(params, max_age = 15)
growth <- as.data.frame(as.table(gc)) |> setNames(c("species", "age", "w")) |>
    mutate(age = as.numeric(as.character(age)))
# von Bertalanffy reference curves (t0 = 0) from l_inf, k_vb, a, b
vb <- expand.grid(species = spn, age = seq(0, 15, by = 0.25), stringsAsFactors = FALSE) |>
    left_join(data.frame(species = spn, l_inf = sp$l_inf, k_vb = sp$k_vb, a = sp$a, b = sp$b),
              by = "species") |>
    mutate(w = a * (l_inf * (1 - exp(-k_vb * age)))^b)
growth_out <- bind_rows(mutate(growth, source = "model"),
                        mutate(select(vb, species, age, w), source = "von Bertalanffy (FishBase)"))
write.csv(growth_out, "results/v1/baseline_growth.csv", row.names = FALSE)

diet <- getDiet(params, proportion = TRUE)
dcod <- as.data.frame(as.table(diet["Cod", , ])) |> setNames(c("w", "prey", "proportion")) |>
    mutate(w = as.numeric(as.character(w))) |> filter(w >= 0.01, w <= sp["Cod", "w_max"])
write.csv(dcod, "results/v1/baseline_diet_cod.csv", row.names = FALSE)
diet_all <- lapply(spn, function(s) {
    d <- diet_summary(params, s, min_w = sp[s, "w_mat"] / 2, max_w = sp[s, "w_inf"])
    data.frame(predator = s, prey = names(d), proportion = as.numeric(d))
}) |> bind_rows()
write.csv(diet_all, "results/v1/baseline_diet_adults.csv", row.names = FALSE)
print(diet_all |> pivot_wider(names_from = prey, values_from = proportion) |>
          mutate(across(where(is.numeric), ~ round(.x, 3))))

wsz <- w[w <= 3000]
mort <- pred_mort_by_predator(params, "Cod", wsz)
fm <- getFMort(params)["Cod", ]; em <- ext_mort(params)["Cod", ]
mort_cod <- bind_rows(mort |> select(w, source = predator, mortality),
                      data.frame(w = w, source = "Fishing", mortality = as.numeric(fm)) |> filter(w <= 3000),
                      data.frame(w = w, source = "External", mortality = as.numeric(em)) |> filter(w <= 3000))
write.csv(mort_cod, "results/v1/baseline_cod_mortality.csv", row.names = FALSE)
# fraction of cod eggs/larvae (1 mg -> 0.1 g) eaten by forage fish, by groundfish
g_cod <- getEGrowth(params)["Cod", ]
sel <- w >= 0.001 & w <= 0.1
dwv <- params@dw[sel]
integ <- function(m) sum(m[sel] / g_cod[sel] * dwv)
mm <- mort |> group_by(w) |> summarise(forage = sum(mortality[predator %in% FORAGE]),
                                      groundfish = sum(mortality[!predator %in% FORAGE]))
mmf <- approx(mm$w, mm$forage, xout = w, rule = 2)$y
mmg <- approx(mm$w, mm$groundfish, xout = w, rule = 2)$y
early <- data.frame(
    quantity = c("cod_early_life_mortality_integral_forage", "cod_early_life_mortality_integral_groundfish",
                 "fraction_cod_eggs_larvae_eaten_by_forage", "cod_larval_duration_1mg_to_0.1g_yr"),
    value = c(integ(mmf), integ(mmg), 1 - exp(-integ(mmf)), sum(dwv / g_cod[sel])))
write.csv(early, "results/v1/baseline_cod_early_life.csv", row.names = FALSE)
print(early)

rl <- resource_level_at(params, c(1e-5, 1e-4, 1e-3, 1e-2, 0.1, 1, 5))
write.csv(data.frame(w = as.numeric(names(rl)), resource_level = rl),
          "results/v1/baseline_resource_level.csv", row.names = FALSE)

# --- Figure 1 ---------------------------------------------------------------
sp_lev <- c(spn, "Resource")
cols <- SPECIES_COLOURS[sp_lev]
pA <- calib |>
    select(species, Observed = biomass_observed_gm2, Model = biomass_model_gm2) |>
    pivot_longer(-species, names_to = "source", values_to = "biomass") |>
    mutate(species = factor(species, levels = spn)) |>
    ggplot(aes(species, gm2_to_kt(biomass), fill = source)) +
    geom_col(position = position_dodge(width = 0.75), width = 0.7) +
    scale_fill_manual(values = c(Observed = "grey60", Model = "#0072B2")) +
    labs(x = NULL, y = "Biomass above survey cutoff (kt)", fill = NULL,
         title = "a  Calibration (1980-85)") +
    theme_paper() + theme(axis.text.x = element_text(angle = 35, hjust = 1),
                          legend.position = c(0.8, 0.85))
pB <- spectra |> mutate(species = factor(species, levels = sp_lev)) |>
    ggplot(aes(w, biomass_per_logw, colour = species)) + geom_line(linewidth = 0.7) +
    scale_x_log10(limits = c(1e-5, 3e4)) + scale_y_log10(limits = c(1e-4, NA)) +
    scale_colour_manual(values = cols) +
    labs(x = "Body mass (g)", y = expression("Biomass density (g m"^-2*" per ln w)"),
         colour = NULL, title = "b  Size spectra") + theme_paper()
pC <- growth_out |> filter(age <= 12) |> mutate(species = factor(species, levels = spn)) |>
    ggplot(aes(age, w, colour = species, linetype = source)) + geom_line(linewidth = 0.6) +
    scale_y_log10() + scale_colour_manual(values = cols, guide = "none") +
    scale_linetype_manual(values = c(model = "solid", "von Bertalanffy (FishBase)" = "dashed")) +
    labs(x = "Age (years)", y = "Body mass (g)", linetype = NULL, title = "c  Growth") +
    theme_paper() + theme(legend.position = c(0.65, 0.15))
pD <- fl |> mutate(species = factor(species, levels = spn)) |>
    ggplot(aes(w, feeding_level, colour = species)) + geom_line(linewidth = 0.6) +
    scale_x_log10() + scale_colour_manual(values = cols, guide = "none") +
    coord_cartesian(ylim = c(0, 1)) +
    labs(x = "Body mass (g)", y = "Feeding level", title = "d  Feeding level") + theme_paper()
prey_cols <- c(SPECIES_COLOURS[spn], Resource = "#999999", External = "white")
pE <- dcod |> filter(prey != "External") |> mutate(prey = factor(prey, levels = c(spn, "Resource"))) |>
    ggplot(aes(w, proportion, fill = prey)) + geom_area(colour = NA) + scale_x_log10() +
    scale_fill_manual(values = prey_cols) +
    labs(x = "Cod body mass (g)", y = "Proportion of diet", fill = "Prey",
         title = "e  Cod diet") + theme_paper()
mort_plot <- mort_cod |> filter(w >= 0.001) |>
    mutate(source = factor(source, levels = c(spn, "Fishing", "External")))
pF <- ggplot(mort_plot, aes(w, mortality, fill = source)) + geom_area(colour = NA) +
    scale_x_log10() +
    scale_fill_manual(values = c(SPECIES_COLOURS[spn], Fishing = "grey30", External = "grey80")) +
    labs(x = "Cod body mass (g)", y = expression("Mortality rate (yr"^-1*")"), fill = "Source",
         title = "f  Mortality of cod by source") + theme_paper()
fig1 <- (pA | pB) / (pC | pD) / (pE | pF)
save_fig(fig1, "fig1_baseline", width = 11, height = 12)
cat("01_build_model.R done\n")
