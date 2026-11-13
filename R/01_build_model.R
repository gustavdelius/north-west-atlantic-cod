# 01_build_model.R  (v3, main model)
# ---------------------------------------------------------------------------
# Acceptance test 1 for v3: the 1980-85 baseline, recalibrated WITH the
# assumption under test (forage-fish early-life vulnerability factor s_egg on
# all four groundfish), and the hindcast driven by the documented cod F only.
#
# Step A  stage 1 = the v2 calibration procedure with s_egg = 1 (build_model();
#         cached in models/calibration_stage1.rds; identical to the v2 build).
# Step B  stage 2: survey-based targets of data/v3 (cod 1.6 g m^-2 above 100 g
#         so that the modelled yield at the baseline F 0.40 matches landings),
#         data-fitted resource P/B, s_egg stepped up 5 -> 10 -> 20 and the
#         baseline recalibrated at each step with calibrate_v3n(): Newton
#         solution of all seven biomass targets at once (recruitment and
#         resource pinned, R_max = Inf while calibrating), alternated with
#         matchGrowth() to age at maturity; Beverton-Holt density dependence
#         is imposed at the end at the configured reproduction levels, which
#         leaves the steady state unchanged (cached in
#         models/calibration_cache.rds).
# Step C  forage reproduction level calibrated (1-D) so that the documented-F
#         hindcast reproduces the forage boom (survey 1995-2004 / 1980-89 =
#         7.9). Nothing else is fitted to the hindcast.
#
# Outputs: models/baseline_params.rds, data/v3/effort_history.csv,
#   results/calibration_quality.csv, results/hindcast_calibration.csv,
#   results/baseline_*.csv, figures/fig1_baseline.(png|pdf)
# ---------------------------------------------------------------------------
source("R/functions.R")
suppressPackageStartupMessages({
    library(ggplot2); library(patchwork); library(dplyr); library(tidyr)
})
set.seed(1)
for (d in c("models", "results", "figures")) dir.create(d, showWarnings = FALSE)
options(mizer_info_level = 0)
cfg <- default_config()
REBUILD <- Sys.getenv("REBUILD") != ""

# --- Step A ---------------------------------------------------------------------
f1 <- "models/calibration_stage1.rds"
if (file.exists(f1) && !REBUILD) {
    p1 <- readParams(f1)
} else {
    c1 <- cfg; c1$s_egg <- 1; c1$repro_forage <- 0.284; c1$biomass_tol <- 0.03; c1$max_iter <- 20
    c1$effort <- cfg$effort
    p1 <- build_model(c1, dir = "data/v2")
    saveParams(p1, f1)
}

# --- Step B ---------------------------------------------------------------------
f2 <- "models/calibration_cache.rds"
if (file.exists(f2) && !REBUILD) {
    params <- readParams(f2)
} else {
    p <- p1
    sp3 <- read.csv(file.path(DATA_DIR, "species_params.csv"))
    species_params(p)$biomass_observed <- sp3$biomass_observed
    p <- set_resource_rate(p, cfg)
    params <- calibrate_v3n(p, cfg, outer = 4, s_path = c(5, 10, cfg$s_egg))
    saveParams(params, f2)
}
spn <- species_params(params)$species

# --- Step C: hindcast with documented fishing only ---------------------------------
eh <- data.frame(year = c(1970, 1980, 1986, 1990, 1993, 1994, 2025),
                 cod = c(0.40, 0.45, 0.70, 1.10, 0.30, 0.02, 0.02),
                 haddock = c(0.30, 0.35, 0.45, 0.55, 0.30, 0.20, 0.20),
                 silver_hake = c(0.30, 0.35, 0.45, 0.55, 0.30, 0.20, 0.20),
                 plaice = c(0.30, 0.35, 0.45, 0.55, 0.30, 0.20, 0.20),
                 pelagic = 0.10)
eh$note <- c("baseline 1970s", "1980-85", "1986-89", "1990-92", "1993 (cod moratorium from Sept)",
             "moratorium: cod bycatch 0.02; other groundfish reduced", "end of hindcast")
write.csv(eh, file.path(DATA_DIR, "effort_history.csv"), row.names = FALSE)

hind_ratios <- function(rf) {
    p <- params; rl <- reproduction_level(p); rl[FORAGE] <- rf; reproduction_level(p) <- rl
    df <- run_scenario(p, eh[, c("year", GEARS)], years = c(1970, 2025))
    list(df = df, r = c(cod = period_ratio(df, "Cod"), forage = period_ratio(df, FORAGE),
                        haddock = period_ratio(df, "Haddock"), silver_hake = period_ratio(df, "Silver hake"),
                        plaice = period_ratio(df, "American plaice"), herring = period_ratio(df, "Herring"),
                        forage_2005_12 = period_ratio(df, FORAGE, num = 2005:2012),
                        cod_2005_12 = period_ratio(df, "Cod", num = 2005:2012)))
}
cal_file <- "results/hindcast_calibration.csv"
if (file.exists(cal_file) && !REBUILD) {
    cal <- read.csv(cal_file)
} else {
    obj <- function(lr) { r <- tryCatch(hind_ratios(plogis(lr))$r, error = function(e) NULL)
        if (is.null(r) || !is.finite(r["forage"])) return(1e6); log(r["forage"] / 7.87)^2 }
    opt <- optimize(obj, interval = qlogis(c(0.02, 0.95)), tol = 0.02)
    rf <- plogis(opt$minimum)
    r <- hind_ratios(rf)$r
    cal <- data.frame(repro_forage = rf, target_forage_1995_2004 = 7.87, t(r))
    write.csv(cal, cal_file, row.names = FALSE)
}
print(cal)
rl <- reproduction_level(params); rl[FORAGE] <- cal$repro_forage[1]
reproduction_level(params) <- rl
params <- setMetadata(params,
    title = "Eastern Scotian Shelf (NAFO 4VsW) cod-forage model v3: 1980-85 baseline",
    description = paste("Seven-species mizer model with the forage-fish early-life vulnerability",
                        "factor s_egg (assumption under test) on all groundfish; baseline recalibrated with it.",
                        "Units g m^-2; 1 g m^-2 = 110 kt. See results/SUMMARY.md."))
saveParams(params, "models/baseline_params.rds")

# --- calibration quality --------------------------------------------------------------
sp <- species_params(params)
Bc <- getBiomass(params, min_w = sp$biomass_cutoff)
stab <- getStability(params)
# steadiness checked by projecting the full model 100 years at baseline effort
sim100 <- project(params, t_max = 100, t_save = 10, progress_bar = FALSE)
B100 <- getBiomass(sim100)
drift100 <- max(abs(log(B100[nrow(B100), ] / B100[1, ])))
# cod collapse F: equilibrium cod SSB over cod F (other gears at baseline effort)
csw <- cod_F_sweep(params, initial_effort(params), Fs = seq(0.4, 1.6, by = 0.1))
csw$ssb_rel <- csw$cod_ssb / getSSB(params)[["Cod"]]
write.csv(csw, "results/calibration_cod_F_sweep.csv", row.names = FALSE)
F_collapse <- { i <- which(csw$ssb_rel < 0.1); if (length(i)) csw$F_cod[min(i)] else NA }
F_msy <- csw$F_cod[which.max(csw$cod_yield)]
qual <- data.frame(
    criterion = c(paste("biomass error", spn), "cod yield (kt) vs 53.5 kt landings",
                  paste("age at maturity", spn), "max erepro", "isSteady",
                  "max |log biomass change| over 100 yr at baseline effort",
                  "max real eigenvalue",
                  "cod collapse F (equilibrium SSB < 10 % of baseline; 0.1 steps)",
                  "cod F at maximum equilibrium yield (0.1 steps, >= 0.4)",
                  "s_egg", "forage reproduction level"),
    value = c(round(as.numeric((Bc - sp$biomass_observed) / sp$biomass_observed), 3),
              round(gm2_to_kt(getYield(params)[["Cod"]]), 1),
              round(as.numeric(age_mat(params)), 2), signif(max(sp$erepro), 3),
              as.character(isSteady(params)), signif(drift100, 3), signif(stab$max_real_part, 3),
              F_collapse, F_msy, cfg$s_egg, round(cal$repro_forage[1], 3)),
    target = c(rep("within +-15 %", length(spn)), "40-67 kt (within 25 %)",
               paste("target", sp$age_mat), "< 1", "TRUE", "< 0.05", "< 0", "0.7-1.1", "-",
               "assumption", "fitted to forage boom"))
write.csv(qual, "results/calibration_quality.csv", row.names = FALSE)
print(qual)

calib <- data.frame(species = spn, biomass_cutoff_g = sp$biomass_cutoff,
                    biomass_observed_gm2 = sp$biomass_observed, biomass_model_gm2 = as.numeric(Bc),
                    total_biomass_model_gm2 = as.numeric(getBiomass(params)),
                    ssb_model_gm2 = as.numeric(getSSB(params)),
                    yield_model_gm2yr = as.numeric(getYield(params)),
                    age_mat_target = sp$age_mat, age_mat_model = as.numeric(age_mat(params)),
                    reproduction_level = as.numeric(reproduction_level(params)), erepro = sp$erepro)
write.csv(calib, "results/baseline_calibration.csv", row.names = FALSE)
write.csv(as.data.frame(sp), "results/baseline_species_params.csv", row.names = FALSE)

budgets <- bind_rows(lapply(GROUNDFISH, function(s) bind_rows(
    mutate(prerecruit_budget(params, s, 0.001, 1), species = s),
    mutate(prerecruit_budget(params, s, 0.001, 10), species = s))))
budgets$share_of_deaths <- ifelse(budgets$source == "total", 1,
    budgets$fraction_killed / ave(ifelse(budgets$source == "total", budgets$fraction_killed, NA),
                                  budgets$species, budgets$w_hi, FUN = function(x) max(x, na.rm = TRUE)))
write.csv(budgets, "results/baseline_prerecruit_budget.csv", row.names = FALSE)
print(budgets |> filter(species == "Cod"))

rl_df <- data.frame(w = c(1e-5, 1e-4, 1e-3, 1e-2, 0.1, 1, 5),
                    resource_level = resource_level_at(params),
                    share_of_production_eaten = resource_consumption_share(params))
write.csv(rl_df, "results/baseline_resource_level.csv", row.names = FALSE)

wf <- params@w_full; nr <- initialNResource(params)
spec <- as.data.frame(as.table(initialN(params))) |> setNames(c("species", "w", "n")) |>
    mutate(w = as.numeric(as.character(w)), biomass_per_logw = n * w^2) |> filter(n > 0)
res_df <- data.frame(species = "Resource", w = wf, n = as.numeric(nr)) |>
    mutate(biomass_per_logw = n * w^2) |> filter(n > 0, w <= 10, w >= 1e-6)
spectra <- bind_rows(spec, res_df)
write.csv(spectra, "results/baseline_spectra.csv", row.names = FALSE)
fl <- as.data.frame(as.table(getFeedingLevel(params))) |> setNames(c("species", "w", "feeding_level")) |>
    mutate(w = as.numeric(as.character(w))) |>
    left_join(data.frame(species = spn, w_max = sp$w_max), by = "species") |>
    filter(w <= w_max) |> select(-w_max)
write.csv(fl, "results/baseline_feeding_level.csv", row.names = FALSE)
gc <- getGrowthCurves(params, max_age = 15)
growth <- as.data.frame(as.table(gc)) |> setNames(c("species", "age", "w")) |>
    mutate(age = as.numeric(as.character(age)))
vb <- expand.grid(species = spn, age = seq(0, 15, by = 0.25), stringsAsFactors = FALSE) |>
    left_join(data.frame(species = spn, l_inf = sp$l_inf, k_vb = sp$k_vb, a = sp$a, b = sp$b), by = "species") |>
    mutate(w = a * (l_inf * (1 - exp(-k_vb * age)))^b)
growth_out <- bind_rows(mutate(growth, source = "model"),
                        mutate(select(vb, species, age, w), source = "von Bertalanffy (FishBase)"))
write.csv(growth_out, "results/baseline_growth.csv", row.names = FALSE)
diet_all <- lapply(spn, function(s) {
    d <- diet_summary(params, s, min_w = sp[s, "w_mat"] / 2, max_w = sp[s, "w_inf"])
    data.frame(predator = s, prey = names(d), proportion = as.numeric(d))
}) |> bind_rows()
write.csv(diet_all, "results/baseline_diet_adults.csv", row.names = FALSE)
mc <- mort_components(params, "Cod")
write.csv(mc, "results/baseline_cod_mortality.csv", row.names = FALSE)

# --- Figure 1 -------------------------------------------------------------------------
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
    pivot_longer(-w, names_to = "source", values_to = "mortality")
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
