# 05_sensitivity.R  (v2)
# ---------------------------------------------------------------------------
# Acceptance test 5 for v2.
#  Part 1, threshold analysis in the forage -> cod early-life preference
#  s_egg (interaction of forage fish with cod relative to plankton of the same
#  size; 1 = purely size-based). s_egg is changed in the calibrated main model
#  WITHOUT recalibration (recalibrating each variant proved erratic: the
#  steady-state solver jumps between solutions), starting from the main
#  model's observed-like 2000 state; the baseline inconsistency this creates
#  is reported (forage kill of cod early life at baseline, and the cod
#  equilibrium at baseline effort relative to the calibrated one). Then
#   (i)  the real moratorium is run from that 2000 state: years from 1993
#        until cod SSB regains 50 % of baseline (> 32 = still failed in 2025);
#   (ii) the invasion test at cod F = 0: a negative growth rate of rare cod in
#        the cod-free community means a true alternative stable state.
#  Part 2, one-at-a-time sensitivity of the same outputs to the cod and
#  forage reproduction levels, the background early-life mortality (Z/G) and
#  the plankton replenishment rate.
# Outputs: models/sensitivity/*.rds, results/sensitivity.csv,
#          figures/fig5_sensitivity.(png|pdf)
# ---------------------------------------------------------------------------
source("R/v2/functions.R")
suppressPackageStartupMessages({
    library(ggplot2); library(patchwork); library(dplyr); library(tidyr); library(parallel)
})
options(mizer_info_level = 0)
dir.create("models/v2/sensitivity", showWarnings = FALSE, recursive = TRUE)
base <- readParams("models/v2/baseline_params.rds")
cfg0 <- default_config()
eh <- read_effort_history()
ehf <- read_effort_history(file.path(DATA_DIR, "effort_history_codforced.csv"))
mor <- moratorium_effort(eh)
e0 <- mor; e0["cod"] <- 0
NCORES <- min(8, parallel::detectCores())

retune_generic <- function(params, modify, cfg = cfg0, n_iter = 8, tol = 0.03) {
    rl <- reproduction_level(params)
    params <- modify(params)
    params <- tune_ss(params)
    for (i in seq_len(n_iter)) {
        if (max(abs(biomass_error(params))) < tol) break
        params <- matchBiomasses(params)
        params <- refresh_bg(safe_match_growth(params), cfg)
        params <- tune_ss(params)
    }
    reproduction_level(params) <- rl
    params
}

s_values <- c(1, 1.5, 2, 3, 5, 10, 20, 50)
variants <- c(
    lapply(s_values, function(s) list(name = paste0("s_egg_", s), parameter = "s_egg", value = s)),
    list(list(name = "repro_cod_0.02", parameter = "repro_cod", value = 0.02),
         list(name = "repro_cod_0.3", parameter = "repro_cod", value = 0.3),
         list(name = "repro_cod_0.6", parameter = "repro_cod", value = 0.6),
         list(name = "repro_forage_x0.5", parameter = "repro_forage_factor", value = 0.5),
         list(name = "repro_forage_x2", parameter = "repro_forage_factor", value = 2),
         list(name = "bg_MG_0", parameter = "bg_MG", value = 0),
         list(name = "bg_MG_x0.5", parameter = "bg_MG_factor", value = 0.5),
         list(name = "bg_MG_x1.5", parameter = "bg_MG_factor", value = 1.5),
         list(name = "r_pp_0.5", parameter = "r_pp", value = 0.5),
         list(name = "r_pp_2", parameter = "r_pp", value = 2)))
# observed-like 2000 state of the main model (initial state for the s_egg runs)
p2000_main <- readParams("models/v2/collapsed_state_params.rds")

variant_params <- function(v) {
    f <- file.path("models/v2/sensitivity", paste0(v$name, ".rds"))
    if (file.exists(f)) return(readParams(f))
    p <- base
    rl <- reproduction_level(p)
    if (v$parameter == "s_egg") {
        im <- interaction_matrix(p); im[FORAGE, "Cod"] <- v$value; interaction_matrix(p) <- im
        return(p)                      # not recalibrated, not cached
    } else if (v$parameter == "repro_cod") {
        rl["Cod"] <- v$value; reproduction_level(p) <- rl
    } else if (v$parameter == "repro_forage_factor") {
        rl[FORAGE] <- pmin(rl[FORAGE] * v$value, 0.95); reproduction_level(p) <- rl
    } else if (v$parameter %in% c("bg_MG", "bg_MG_factor")) {
        cfg <- cfg0
        cfg$bg_MG <- if (v$parameter == "bg_MG") v$value else cfg0$bg_MG * v$value
        if (cfg$bg_MG == 0) cfg$background <- FALSE
        p <- retune_generic(p, function(q) refresh_bg(q, cfg), cfg = cfg)
    } else if (v$parameter == "r_pp") {
        p <- setResource(p, resource_rate = v$value)
    }
    saveParams(p, f)
    p
}

evaluate <- function(v) {
    p <- variant_params(v)
    base_ssb <- getSSB(p)[["Cod"]]; base_forage <- sum(getBiomass(p)[FORAGE])
    bud0 <- prerecruit_budget(p, "Cod", 0.001, 1)
    hf <- run_scenario(p, ehf, years = c(1970, 2004), return_sim = TRUE)
    p2000 <- if (v$parameter == "s_egg") set_state(p, p2000_main) else getParams(hf$sim, time_range = 2000)
    # baseline consistency: cod equilibrium at the baseline effort, relative to the calibrated cod
    eqb <- if (v$parameter == "s_egg") equilibrate(p, initial_effort(p), t_max = 200, t_check = 25, tol = 1e-3) else NULL
    budB <- prerecruit_budget(p2000, "Cod", 0.001, 1)
    dB <- run_scenario(p, mor, years = c(2000, 2200), initial = p2000)
    cod <- dB[dB$species == "Cod", ]
    rec <- cod$year[cod$ssb >= 0.5 * base_ssb]
    hA <- run_scenario(p, eh, years = c(1970, 2025), return_sim = TRUE)
    dA <- bind_rows(hA$data, filter(run_scenario(p, mor, years = c(2025, 2200), initial = hA$sim), year > 2025))
    mA <- recovery_metrics(dA, base_ssb, base_forage)
    it <- invasion_test(p, e0)
    data.frame(variant = v$name, parameter = v$parameter, value = v$value,
               max_biomass_error = max(abs(biomass_error(p))),
               erepro_cod = species_params(p)["Cod", "erepro"],
               max_erepro = max(species_params(p)$erepro),
               forage_kill_1mg_1g_baseline = bud0$fraction_killed[bud0$source == "forage"],
               forage_kill_1mg_1g_boom = budB$fraction_killed[budB$source == "forage"],
               cod_survival_1mg_1g_baseline = bud0$survival[1],
               cod_survival_1mg_1g_boom = budB$survival[1],
               forage_ratio_1995_2004 = period_ratio(hf$data, FORAGE),
               cod_ratio_1995_2004_forced = period_ratio(hf$data, "Cod"),
               B_years_to_50pct_from_1993 = if (length(rec)) min(rec) - 1993 else NA,
               B_cod_ssb_2025_rel = cod$ssb[cod$year == 2025] / base_ssb,
               A_ssb_min_rel = mA$ssb_min_rel, A_years_to_50pct = mA$years_to_recover50,
               A_forage_max_rel = mA$forage_max_rel_1993_2025,
               invasion_rate = it$rate, alternative_state = it$rate < 0,
               cod_free_forage_rel = sum(it$cod_free$biomass[FORAGE]) / base_forage,
               cod_free_other_groundfish_rel = sum(it$cod_free$biomass[OTHER_GF]) / sum(getBiomass(p)[OTHER_GF]),
               baseline_cod_equilibrium_rel = if (is.null(eqb)) NA else eqb$biomass[["Cod"]] / getBiomass(p)[["Cod"]])
}

res <- mclapply(variants, function(v) tryCatch(evaluate(v), error = function(e)
    data.frame(variant = v$name, parameter = v$parameter, value = v$value,
               error = conditionMessage(e))), mc.cores = NCORES)
sens <- bind_rows(res)
write.csv(sens, "results/v2/sensitivity.csv", row.names = FALSE)
print(sens)

# thresholds in s_egg (log-linear interpolation)
thr <- function(x, y, level) {
    ok <- is.finite(x) & is.finite(y)
    x <- x[ok]; y <- y[ok]
    i <- which(diff(sign(y - level)) != 0)
    if (!length(i)) return(NA)
    i <- i[1]
    exp(approx(y[i:(i + 1)], log(x[i:(i + 1)]), xout = level)$y)
}
se <- sens |> filter(parameter == "s_egg", is.finite(invasion_rate)) |> arrange(value)
yrs <- ifelse(is.na(se$B_years_to_50pct_from_1993), 500, se$B_years_to_50pct_from_1993)
thresholds <- data.frame(
    quantity = c("s_egg for >= 32 years without recovery (moratorium from observed 2000 state)",
                 "s_egg for a true alternative stable state (invasion rate < 0)"),
    value = c(thr(se$value, yrs, 32), thr(se$value, se$invasion_rate, 0)))
write.csv(thresholds, "results/v2/sensitivity_thresholds.csv", row.names = FALSE)
print(thresholds)

# --- Figure 5 -------------------------------------------------------------------
se$yrs <- yrs
pA <- ggplot(se, aes(value, yrs)) + geom_line() + geom_point(aes(shape = alternative_state), size = 2.5) +
    scale_x_log10() + geom_hline(yintercept = 32, linetype = "dotted") +
    scale_shape_manual(values = c(`FALSE` = 16, `TRUE` = 4), name = "Alternative\nstable state") +
    labs(x = "Forage -> cod early-life preference s_egg (not recalibrated)", y = "Years from 1993 to 50 % SSB\n(500 = not within 200 yr)",
         title = "a  Moratorium from the observed 2000 community") + theme_paper()
pB <- ggplot(se, aes(value, invasion_rate)) + geom_line() + geom_point(size = 2) + scale_x_log10() +
    geom_hline(yintercept = 0, linetype = "dashed") +
    labs(x = "s_egg", y = expression("Invasion rate of rare cod (yr"^-1*")"),
         title = "b  Cod-free state at F = 0 (< 0: alternative state)") + theme_paper()
pC <- ggplot(se, aes(value)) +
    geom_line(aes(y = 100 * forage_kill_1mg_1g_baseline, colour = "baseline 1980-85")) +
    geom_line(aes(y = 100 * forage_kill_1mg_1g_boom, colour = "boom 2000")) +
    geom_point(aes(y = 100 * forage_kill_1mg_1g_baseline, colour = "baseline 1980-85")) +
    geom_point(aes(y = 100 * forage_kill_1mg_1g_boom, colour = "boom 2000")) +
    scale_x_log10() + scale_colour_manual(values = c("baseline 1980-85" = "#0072B2", "boom 2000" = "#D55E00")) +
    labs(x = "s_egg", y = "% of cod (1 mg-1 g) killed by forage fish", colour = NULL,
         title = "c  Implied forage-fish kill of cod early life") + theme_paper()
oat <- sens |> filter(parameter != "s_egg", is.finite(invasion_rate)) |>
    mutate(rec = ifelse(is.na(B_years_to_50pct_from_1993), 500, B_years_to_50pct_from_1993))
main <- sens |> filter(variant == "s_egg_1")
pD <- ggplot(oat, aes(variant, rec)) + geom_col(fill = "grey60") +
    geom_hline(yintercept = ifelse(is.na(main$B_years_to_50pct_from_1993), 500, main$B_years_to_50pct_from_1993),
               linetype = "dashed") + geom_hline(yintercept = 32, linetype = "dotted") + coord_flip() +
    labs(x = NULL, y = "Years from 1993 to 50 % SSB (dashed: main)", title = "d  Other parameters") + theme_paper()
save_fig((pA | pB) / (pC | pD), "fig5_sensitivity", width = 12, height = 9)
cat("05_sensitivity.R done\n")
