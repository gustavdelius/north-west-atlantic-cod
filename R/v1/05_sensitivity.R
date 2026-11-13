# 05_sensitivity.R
# ---------------------------------------------------------------------------
# Acceptance test 5: robustness of the result to the parameters that control
# the strength of the cultivation-depensation feedback:
#   s_egg        forage-fish -> cod interaction (egg/larval predation strength;
#                1 = purely size-based, as in the main model)
#   repro_cod    Beverton-Holt reproduction level of cod
#   repro_forage reproduction level of herring, sand lance and capelin
#   r_pp         resource replenishment rate (strength of competition for plankton)
#   kappa        resource abundance relative to the fish (requires recalibration)
# Plus a combined "strongest-feedback" variant.
#
# Each variant is a separately calibrated model at the same 1980-85 baseline
# (same biomasses, growth and yields), then run through: (i) the 1970-2025
# hindcast and 200 more years at moratorium efforts, (ii) the cod invasion
# test of the cod-free community at cod F = 0 (alternative stable state if the
# invasion growth rate is negative), (iii) a check that no species goes
# extinct at the cod-dominated F = 0 equilibrium.
#
# Outputs
#   models/sensitivity/*.rds (cached recalibrated variants)
#   results/sensitivity.csv, figures/fig5_sensitivity.(png|pdf)
# ---------------------------------------------------------------------------
source("R/v1/functions.R")
suppressPackageStartupMessages({
    library(ggplot2); library(patchwork); library(dplyr); library(tidyr); library(parallel)
})
options(mizer_info_level = 0)
dir.create("models/v1/sensitivity", showWarnings = FALSE, recursive = TRUE)
base <- readParams("models/v1/baseline_params.rds")
cfg0 <- default_config()
NCORES <- min(8, parallel::detectCores())
eh <- read_effort_history()
mor <- moratorium_effort(eh)
e0 <- c(cod = 0, groundfish = mor[["groundfish"]], pelagic = mor[["pelagic"]])

# ---- variant constructors -----------------------------------------------------
retune_with <- function(params, s_egg = NULL, rl = NULL, n_iter = 6) {
    if (!is.null(s_egg)) {
        im <- interaction_matrix(params); im[FORAGE, "Cod"] <- s_egg
        interaction_matrix(params) <- im
    }
    if (!is.null(rl)) reproduction_level(params) <- rl
    params <- tune_ss(params)
    for (i in seq_len(n_iter)) {
        if (max(abs(biomass_error(params))) < 0.03) break
        params <- matchBiomasses(params)
        params <- safe_match_growth(params)
        params <- tune_ss(params)
    }
    params
}
variant_params <- function(v) {
    f <- file.path("models/v1/sensitivity", paste0(v$name, ".rds"))
    if (file.exists(f)) return(readParams(f))
    cfg <- cfg0
    for (k in setdiff(names(v), c("name", "parameter", "value"))) cfg[[k]] <- v[[k]]
    rl <- repro_levels(cfg, species_params(base)$species)
    if (!identical(cfg$kappa, cfg0$kappa)) {
        cfg$kappa_path <- cfg0$kappa_path[cfg0$kappa_path > cfg$kappa]
        p <- build_model(cfg, verbose = FALSE)
    } else if (!identical(cfg$s_egg, cfg0$s_egg)) {
        p <- retune_with(base, s_egg = cfg$s_egg, rl = rl)
    } else {
        p <- base
        reproduction_level(p) <- rl      # leaves the steady state unchanged
        if (!identical(cfg$r_pp, cfg0$r_pp)) {
            # change the plankton replenishment rate, rebalancing the capacity so
            # that the calibrated steady state is kept
            p <- setResource(p, resource_rate = cfg$r_pp)
        }
    }
    saveParams(p, f)
    p
}

variants <- list(
    list(name = "main", parameter = "main", value = NA),
    list(name = "s_egg_3", parameter = "s_egg", value = 3, s_egg = 3),
    list(name = "s_egg_10", parameter = "s_egg", value = 10, s_egg = 10),
    list(name = "s_egg_30", parameter = "s_egg", value = 30, s_egg = 30),
    list(name = "s_egg_100", parameter = "s_egg", value = 100, s_egg = 100),
    list(name = "repro_cod_0", parameter = "repro_cod", value = 0, repro_cod = 0),
    list(name = "repro_cod_0.25", parameter = "repro_cod", value = 0.25, repro_cod = 0.25),
    list(name = "repro_cod_0.75", parameter = "repro_cod", value = 0.75, repro_cod = 0.75),
    list(name = "repro_forage_0.25", parameter = "repro_forage", value = 0.25, repro_forage = 0.25),
    list(name = "repro_forage_0.75", parameter = "repro_forage", value = 0.75, repro_forage = 0.75),
    list(name = "r_pp_1", parameter = "r_pp", value = 1, r_pp = 1),
    list(name = "r_pp_5", parameter = "r_pp", value = 5, r_pp = 5),
    list(name = "r_pp_10", parameter = "r_pp", value = 10, r_pp = 10),
    list(name = "kappa_1", parameter = "kappa", value = 1.0, kappa = 1.0),
    list(name = "kappa_2", parameter = "kappa", value = 2.0, kappa = 2.0),
    list(name = "strong_s10_rc0_rf0.25", parameter = "combined", value = NA,
         s_egg = 10, repro_cod = 0, repro_forage = 0.25),
    list(name = "strong_s30_rc0_rf0.25", parameter = "combined", value = NA,
         s_egg = 30, repro_cod = 0, repro_forage = 0.25))

evaluate <- function(v) {
    p <- variant_params(v)
    base_ssb <- getSSB(p)[["Cod"]]
    base_forage <- sum(getBiomass(p)[FORAGE])
    h <- run_scenario(p, eh, years = c(1970, 2025), return_sim = TRUE)
    ext <- eh[nrow(eh), ]; ext$year <- 2025
    h2 <- run_scenario(p, ext, years = c(2025, 2225), initial = h$sim)
    df <- bind_rows(h$data, filter(h2, year > 2025))
    m <- recovery_metrics(df, base_ssb, base_forage)
    # invasion test
    pf <- p; n <- initialN(pf); n["Cod", ] <- 0; initialN(pf) <- n
    C <- equilibrate(pf, e0, t_max = 400, t_check = 25, tol = 5e-4, floor = 1e-14)
    pc <- C$params; n <- initialN(pc); n["Cod", ] <- initialN(p)["Cod", ] * 1e-6; initialN(pc) <- n
    inv <- project(pc, effort = e0, t_max = 60, progress_bar = FALSE)
    lam <- log_growth_rate(inv, years = 30)
    # F = 0 equilibrium from the baseline: extinctions?
    A <- equilibrate(p, e0, t_max = 400, t_check = 25, tol = 5e-4)
    relA <- A$biomass / getBiomass(p)
    cbind(data.frame(variant = v$name, parameter = v$parameter, value = v$value,
                     max_biomass_error = max(abs(biomass_error(p))),
                     erepro_cod = species_params(p)["Cod", "erepro"],
                     forage_kill_fraction_baseline = cod_early_forage_kill(p)[["fraction"]],
                     forage_kill_fraction_cod_free = cod_early_forage_kill(pc)[["fraction"]],
                     forage_cod_free_rel = sum(C$biomass[FORAGE]) / base_forage,
                     invasion_rate = lam,
                     alternative_state = lam < 0,
                     cod_F0_rel = relA[["Cod"]],
                     min_species_F0_rel = min(relA),
                     species_lost_F0 = paste(names(relA)[relA < 0.01], collapse = ";")),
          m)
}

res <- mclapply(variants, function(v) tryCatch(evaluate(v), error = function(e)
    data.frame(variant = v$name, parameter = v$parameter, value = v$value,
               error = conditionMessage(e))), mc.cores = NCORES)
sens <- bind_rows(res)
write.csv(sens, "results/v1/sensitivity.csv", row.names = FALSE)
print(sens)

# --- Figure 5 ------------------------------------------------------------------
main <- sens[sens$variant == "main", ]
oat <- sens |> filter(!parameter %in% c("main", "combined")) |>
    bind_rows(lapply(c("s_egg", "repro_cod", "repro_forage", "r_pp", "kappa"), function(pp)
        mutate(main, parameter = pp, value = c(s_egg = cfg0$s_egg, repro_cod = cfg0$repro_cod,
                                               repro_forage = cfg0$repro_forage, r_pp = cfg0$r_pp,
                                               kappa = cfg0$kappa)[[pp]]))) |>
    mutate(parameter = factor(parameter, levels = c("s_egg", "repro_cod", "repro_forage", "r_pp", "kappa")),
           rec = ifelse(is.na(years_to_recover50), 250, years_to_recover50))
pA <- ggplot(oat, aes(value, rec)) + geom_line() + geom_point(aes(shape = alternative_state), size = 2.5) +
    facet_wrap(~ parameter, scales = "free_x", nrow = 1) +
    geom_hline(yintercept = 32, linetype = "dotted") +
    scale_shape_manual(values = c(`FALSE` = 16, `TRUE` = 4), name = "Cod-free state\nstable") +
    labs(x = "Parameter value", y = "Years from 1993 to 50% of\nbaseline SSB (250 = never)",
         title = "a  Recovery time under the moratorium (dotted: 2025)") + theme_paper()
pB <- ggplot(oat, aes(value, invasion_rate)) + geom_line() + geom_point(size = 2) +
    facet_wrap(~ parameter, scales = "free_x", nrow = 1) + geom_hline(yintercept = 0, linetype = "dashed") +
    labs(x = "Parameter value", y = expression("Cod invasion rate (yr"^-1*")"),
         title = "b  Growth rate of rare cod in the cod-free community at F = 0 (< 0: alternative stable state)") +
    theme_paper()
fig5 <- pA / pB
save_fig(fig5, "fig5_sensitivity", width = 12, height = 7)
cat("05_sensitivity.R done\n")
