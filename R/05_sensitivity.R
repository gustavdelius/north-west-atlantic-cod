# 05_sensitivity.R  (v3)
# ---------------------------------------------------------------------------
# Acceptance test 5 for v3: "what it would take".
# Outcome classes for the documented-F hindcast and the moratorium:
#   recovers quickly         cod SSB back to 50 % of baseline <= 20 years after 1993
#   decades-long transient   > 20 years (or not by 2125), but rare cod can
#                            invade the cod-free community (invasion rate > 0)
#   alternative state exists, not reached: rare cod cannot invade the
#                            cod-free community (invasion rate < 0 at cod
#                            F = 0) but the hindcast does not enter its basin
#   alternative state reached: invasion rate < 0 and no recovery by 2125
# Axes
#   s, the forage -> groundfish early-life vulnerability factor (the
#     assumption under test), expressed as the baseline share of cod
#     1 mg - 1 g deaths caused by forage fish. Every s value is RECALIBRATED
#     to the same 1980-85 targets with calibrate_v3n() (flagged if that fails,
#     in which case s is changed without recalibration);
#   (outcome classes use run A, documented fishing only; panel d gives the
#   recovery time after run B, documented fishing + adult M 0.8 in 1990-2025)
#   boom magnitude, set by the forage-fish Beverton-Holt reproduction level
#     (exact: reproduction_level<- leaves the steady state unchanged), and
#     reported as the hindcast forage ratio 1995-2004 / 1980-89 (survey 7.9);
#   one at a time at the main s: cod reproduction level, and resource
#     productivity (P/B x0.5, x2; setResource() rebalances the capacity so
#     the baseline is unchanged: exact, no recalibration needed).
# Also: the cod collapse F (equilibrium SSB < 10 % of baseline) for each s.
# Outputs: models/sensitivity/*.rds, results/sensitivity_map.csv,
#          results/sensitivity_collapse_F.csv,
#          results/sensitivity_oat.csv, figures/fig5_sensitivity.(png|pdf)
# ---------------------------------------------------------------------------
source("R/functions.R")
suppressPackageStartupMessages({
    library(ggplot2); library(patchwork); library(dplyr); library(tidyr); library(parallel)
})
options(mizer_info_level = 0)
dir.create("models/sensitivity", showWarnings = FALSE, recursive = TRUE)
main <- readParams("models/baseline_params.rds")
cal0 <- readParams("models/calibration_cache.rds")
cfg <- default_config()
eh <- read_effort_history()
mor <- moratorium_effort(eh)
e0 <- mor; e0["cod"] <- 0
NCORES <- min(8, parallel::detectCores())
rf_main <- reproduction_level(main)[["Herring"]]

# --- recalibrated s variants ---------------------------------------------------
s_vals <- c(1, 5, 10, 20, 40, 80, 160)
get_s_variant <- function(s) {
    if (s == cfg$s_egg) return(list(p = main, recalibrated = TRUE))
    f <- sprintf("models/sensitivity/s_%g.rds", s)
    if (file.exists(f)) return(list(p = readParams(f), recalibrated = TRUE))
    if (s > 40) {
        # A first attempt to recalibrate at s = 80 and 160 had not finished
        # after 25 min (the Newton evaluations stop settling); time-boxed:
        # s is changed in the main model without recalibration and flagged.
        p <- main; im <- interaction_matrix(p); im[FORAGE, cfg$s_prey] <- s; interaction_matrix(p) <- im
        return(list(p = p, recalibrated = FALSE))
    }
    path <- signif(exp(seq(log(cfg$s_egg), log(s), length.out = 4))[-1], 3)
    p <- tryCatch(calibrate_v3n(cal0, cfg, outer = 3, s_path = path, verbose = FALSE),
                  error = function(e) NULL)
    if (!is.null(p) && max(abs(biomass_error(p))) < 0.15 && all(species_params(p)$erepro < 1)) {
        reproduction_level(p) <- reproduction_level(main)
        saveParams(p, f)
        return(list(p = p, recalibrated = TRUE))
    }
    p <- main; im <- interaction_matrix(p); im[FORAGE, cfg$s_prey] <- s; interaction_matrix(p) <- im
    list(p = p, recalibrated = FALSE)
}
svar <- mclapply(s_vals, get_s_variant, mc.cores = 7)
names(svar) <- s_vals

forage_share <- function(p) {
    b <- prerecruit_budget(p, "Cod", 0.001, 1)
    b$fraction_killed[b$source == "forage"] / b$fraction_killed[b$source == "total"]
}

evaluate <- function(p, label) {
    base_ssb <- getSSB(p)[["Cod"]]; base_forage <- sum(getBiomass(p)[FORAGE])
    # run A: documented fishing only
    h <- run_scenario(p, eh, years = c(1970, 2025), return_sim = TRUE)
    d <- bind_rows(h$data, filter(run_scenario(p, mor, years = c(2025, 2125), initial = h$sim), year > 2025))
    m <- recovery_metrics(d, base_ssb, base_forage)
    # run B: documented fishing + adult M 0.8 in 1990-2025, then baseline M
    h1 <- run_scenario(p, eh[eh$year < 1990, ], years = c(1970, 1990), return_sim = TRUE)
    h2 <- run_scenario(elevate_M(p), eh[eh$year >= 1990, ], years = c(1990, 2025), initial = h1$sim,
                       return_sim = TRUE)
    dB <- bind_rows(h1$data, filter(h2$data, year > 1990),
                    filter(run_scenario(p, mor, years = c(2025, 2125), initial = h2$sim), year > 2025))
    codB <- dB[dB$species == "Cod", ]
    recB <- codB$year[codB$year > 2025 & codB$ssb >= 0.5 * base_ssb]
    it <- invasion_test(p, e0)
    fit <- invasion_fit(it$inv, getBiomass(p)[["Cod"]])
    y50 <- m$years_to_recover50
    cls <- if (fit$rate < 0) {
        if (!is.na(y50)) "alternative state exists, not reached" else "alternative state reached"
    } else if (!is.na(y50) && y50 <= 20) "recovers quickly (<= 20 yr)" else "decades-long transient"
    data.frame(label,
               max_biomass_error = max(abs(biomass_error(p))),
               max_erepro = max(species_params(p)$erepro),
               baseline_eigenvalue = getStability(p)$max_real_part,
               forage_share_cod_deaths_baseline = forage_share(p),
               forage_ratio_1995_2004 = period_ratio(d, FORAGE),
               forage_ratio_2005_2012 = period_ratio(d, FORAGE, num = 2005:2012),
               cod_ratio_1995_2004 = period_ratio(d, "Cod"),
               cod_ssb_2025_rel = m$ssb_2025_rel, cod_ssb_min_rel = m$ssb_min_rel,
               years_to_50pct_from_1993 = y50,
               B_forage_ratio_1995_2004 = period_ratio(dB, FORAGE),
               B_cod_ratio_1995_2004 = period_ratio(dB, "Cod"),
               B_years_to_50pct_after_2025 = if (length(recB)) min(recB) - 2025 else NA,
               invasion_rate = fit$rate, invasion_fit_r2 = fit$r2,
               outcome = cls)
}

# --- map: s x forage reproduction level ---------------------------------------------
rf_vals <- sort(unique(c(0.05, 0.1, 0.2, rf_main, 0.5, 0.7, 0.9)))
map_grid <- expand.grid(s = s_vals, repro_forage = rf_vals)
map <- bind_rows(mclapply(seq_len(nrow(map_grid)), function(i) {
    g <- map_grid[i, ]; v <- svar[[as.character(g$s)]]
    p <- v$p; rl <- reproduction_level(p); rl[FORAGE] <- g$repro_forage; reproduction_level(p) <- rl
    tryCatch(evaluate(p, data.frame(s = g$s, recalibrated = v$recalibrated, repro_forage = g$repro_forage)),
             error = function(e) data.frame(s = g$s, recalibrated = v$recalibrated,
                                            repro_forage = g$repro_forage, error = conditionMessage(e)))
}, mc.cores = NCORES))
write.csv(map, "results/sensitivity_map.csv", row.names = FALSE)
print(map)

# --- cod collapse F for each s (main forage level; other gears at baseline) ---------
collapse <- bind_rows(mclapply(s_vals, function(sv) {
    v <- svar[[as.character(sv)]]; p <- v$p
    rl <- reproduction_level(p); rl[FORAGE] <- rf_main; reproduction_level(p) <- rl
    sw <- cod_F_sweep(p, initial_effort(p), Fs = seq(0.4, 1.6, by = 0.1), t_max = 300)
    r <- sw$cod_ssb / getSSB(p)[["Cod"]]
    data.frame(s = sv, recalibrated = v$recalibrated,
               cod_collapse_F = { i <- which(r < 0.1); if (length(i)) sw$F_cod[min(i)] else NA },
               ssb_rel_F0.6 = r[which.min(abs(sw$F_cod - 0.6))], ssb_rel_F1.0 = r[which.min(abs(sw$F_cod - 1))])
}, mc.cores = NCORES))
write.csv(collapse, "results/sensitivity_collapse_F.csv", row.names = FALSE)
print(collapse)

# --- one at a time at the main s ----------------------------------------------------
oat_def <- list(
    list(parameter = "main model", value = NA, f = function(p) p),
    list(parameter = "repro_cod", value = 0.02, f = function(p) { rl <- reproduction_level(p); rl["Cod"] <- 0.02; reproduction_level(p) <- rl; p }),
    list(parameter = "repro_cod", value = 0.3, f = function(p) { rl <- reproduction_level(p); rl["Cod"] <- 0.3; reproduction_level(p) <- rl; p }),
    list(parameter = "repro_cod", value = 0.6, f = function(p) { rl <- reproduction_level(p); rl["Cod"] <- 0.6; reproduction_level(p) <- rl; p }),
    list(parameter = "resource_productivity_factor", value = 0.5,
         f = function(p) setResource(p, resource_rate = 0.5 * resource_rate(p))),
    list(parameter = "resource_productivity_factor", value = 2,
         f = function(p) setResource(p, resource_rate = 2 * resource_rate(p))))
oat <- bind_rows(mclapply(oat_def, function(o) {
    p <- o$f(main)
    tryCatch(evaluate(p, data.frame(parameter = o$parameter, value = o$value, recalibrated = "exact (baseline unchanged)")),
             error = function(e) data.frame(parameter = o$parameter, value = o$value, error = conditionMessage(e)))
}, mc.cores = NCORES))
write.csv(oat, "results/sensitivity_oat.csv", row.names = FALSE)
print(oat)

# --- Figure 5 ------------------------------------------------------------------------
ok <- map |> filter(!is.na(outcome))
share_lab <- ok |> group_by(s) |> summarise(share = mean(forage_share_cod_deaths_baseline), rec = first(recalibrated)) |>
    mutate(lab = sprintf("s = %g\n%.1f %%%s", s, 100 * share, ifelse(rec, "", " (not recal.)")))
ok <- ok |> left_join(share_lab, by = "s") |>
    mutate(lab = factor(lab, levels = share_lab$lab[order(share_lab$s)]),
           rf = factor(sprintf("%.2f", repro_forage), levels = sprintf("%.2f", rf_vals)),
           txt = sprintf("x%.1f\n%s", forage_ratio_1995_2004,
                         ifelse(is.na(years_to_50pct_from_1993), ">132", years_to_50pct_from_1993)))
pal_out <- c("recovers quickly (<= 20 yr)" = "#56B4E9", "decades-long transient" = "#E69F00",
             "alternative state exists, not reached" = "#CC79A7", "alternative state reached" = "#D55E00")
pA <- ggplot(ok, aes(lab, rf, fill = outcome)) + geom_tile(colour = "white") +
    geom_text(aes(label = txt), size = 2.6, lineheight = 0.85) +
    scale_fill_manual(values = pal_out, drop = FALSE) +
    labs(x = "Early-life vulnerability s (baseline forage share of cod 1 mg-1 g deaths)",
         y = "Forage reproduction level (boom magnitude)", fill = NULL,
         title = "a  What it would take (cell: forage boom 1995-2004 / 1980-89; years from 1993 to 50 % SSB)") +
    theme_paper() + theme(legend.position = "bottom")
oo <- oat |> filter(!is.na(outcome)) |>
    mutate(lab = ifelse(is.na(value), parameter, paste(parameter, value)),
           yrs = ifelse(is.na(years_to_50pct_from_1993), 132, years_to_50pct_from_1993))
pB <- ggplot(oo, aes(reorder(lab, yrs), yrs, fill = outcome)) + geom_col() + coord_flip() +
    scale_fill_manual(values = pal_out, guide = "none") + geom_hline(yintercept = 32, linetype = "dotted") +
    labs(x = NULL, y = "Years from 1993 to 50 % SSB (132 = not by 2125)",
         title = "c  Cod reproduction level and resource productivity (main s)") + theme_paper()
pC <- ggplot(oo, aes(reorder(lab, yrs), invasion_rate, fill = outcome)) + geom_col() + coord_flip() +
    scale_fill_manual(values = pal_out, guide = "none") + geom_hline(yintercept = 0) +
    labs(x = NULL, y = expression("Invasion rate of rare cod (yr"^-1*")"), title = "d  Invasion rate") + theme_paper()
pD <- ok |> ggplot(aes(lab, rf, fill = B_years_to_50pct_after_2025)) + geom_tile(colour = "white") +
    geom_text(aes(label = ifelse(is.na(B_years_to_50pct_after_2025), ">100", B_years_to_50pct_after_2025)), size = 2.8) +
    scale_fill_viridis_c(direction = -1, na.value = "grey60") +
    labs(x = "s (baseline forage share of cod 1 mg-1 g deaths)", y = "Forage reproduction level",
         fill = "Years", title = "b  Years from 2025 to 50 % SSB after run B (adult M 0.8 in 1990-2025, then baseline)") +
    theme_paper()
save_fig(pA / pD / (pB | pC) + plot_layout(heights = c(1.3, 1.1, 1)), "fig5_sensitivity", width = 12, height = 14)
cat("05_sensitivity.R done\n")
