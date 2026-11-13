# 04_forage_fishing_recovery.R  (v2)
# ---------------------------------------------------------------------------
# Acceptance test 4 (v2): from the 2025 state of the moratorium run that
# starts from the observed-like 2000 community (run B of 02), raise the
# forage-fish (pelagic) effort for D years from 2026, then return it to 0.1,
# keeping cod at its moratorium bycatch F (0.02) and the other groundfish
# gears at their calibrated post-1985 levels. Does cod recover, how fast, and
# does recovery persist? The starting state is saved as
# models/collapsed_2025_params.rds.
# Also: constant-F equilibria over a range of pelagic F to show the trade-off
# (cod food and growth, forage yield).
#
# Outputs
#   results/forage_fishing_grid.csv          metrics for every (F_forage, D)
#   results/forage_fishing_trajectories.csv  tidy yearly output, selected runs
#   results/forage_fishing_equilibria.csv    constant pelagic-F equilibria
#   models/collapsed_2025_params.rds
#   figures/fig4_forage_fishing.(png|pdf)
# ---------------------------------------------------------------------------
source("R/v2/functions.R")
suppressPackageStartupMessages({
    library(ggplot2); library(patchwork); library(dplyr); library(tidyr); library(parallel)
})
options(mizer_info_level = 0)
params <- readParams("models/v2/baseline_params.rds")
# Starting state: 2025 of the moratorium run that starts from the observed-like
# 2000 community (run B in 02): cod F 0.02 since 1994, other gears at their
# calibrated post-1985 levels.
p2000 <- readParams("models/v2/collapsed_state_params.rds")
collapsed <- finalParams(run_scenario(params, moratorium_effort(), years = c(2000, 2025),
                                      initial = p2000, return_sim = TRUE)$sim)
saveParams(collapsed, "models/v2/collapsed_2025_params.rds")
base_ssb <- getSSB(params)[["Cod"]]
base_forage <- sum(getBiomass(params)[FORAGE])
mor <- moratorium_effort()
NCORES <- min(8, parallel::detectCores())

F_grid <- c(0.1, 0.25, 0.5, 0.75, 1.0, 1.5, 2.0, 3.0)
D_grid <- c(5, 10, 15, 20, 30)
grid <- expand.grid(F_forage = F_grid, D = D_grid)
grid <- grid[!(grid$F_forage == 0.1 & grid$D != 5), ]   # status quo once

one_run <- function(Ff, D, end = 2125) {
    eff <- as.data.frame(rbind(mor, mor)); eff$year <- c(2026, 2026 + D)
    eff$pelagic <- c(Ff, mor[["pelagic"]])
    df <- run_scenario(params, eff, years = c(2026, end), initial = collapsed)
    cod <- df[df$species == "Cod", ]
    fy <- aggregate(yield ~ year, data = df[df$species %in% FORAGE, ], sum)
    rec <- cod$year[cod$ssb >= 0.5 * base_ssb]
    rec_full <- cod$year[cod$ssb >= base_ssb]
    list(df = mutate(df, F_forage = Ff, D = D),
         metrics = data.frame(
             F_forage = Ff, D = D,
             years_to_50pct = if (length(rec)) min(rec) - 2026 else NA,
             years_to_100pct = if (length(rec_full)) min(rec_full) - 2026 else NA,
             cod_ssb_end_fishing_rel = cod$ssb[cod$year == 2026 + D] / base_ssb,
             cod_ssb_2125_rel = cod$ssb[cod$year == end] / base_ssb,
             forage_min_rel = min(aggregate(biomass ~ year, data = df[df$species %in% FORAGE, ], sum)$biomass) / base_forage,
             forage_yield_during_kt_per_yr = gm2_to_kt(mean(fy$yield[fy$year >= 2026 & fy$year < 2026 + D])),
             forage_yield_cumulative_kt = gm2_to_kt(sum(fy$yield[fy$year >= 2026 & fy$year < 2026 + D]))))
}
res <- mclapply(seq_len(nrow(grid)), function(i) one_run(grid$F_forage[i], grid$D[i]),
                mc.cores = NCORES)
metrics <- bind_rows(lapply(res, `[[`, "metrics"))
sq <- metrics$years_to_50pct[metrics$F_forage == 0.1]
metrics$years_saved_vs_status_quo <- sq - metrics$years_to_50pct
write.csv(metrics, "results/v2/forage_fishing_grid.csv", row.names = FALSE)
print(metrics)
traj <- bind_rows(lapply(res, `[[`, "df")) |>
    filter(D %in% c(5, 10, 20) | F_forage == 0.1)
write.csv(traj, "results/v2/forage_fishing_trajectories.csv", row.names = FALSE)

# --- constant pelagic-F equilibria (trade-off) ------------------------------------
eqF <- c(0, 0.1, 0.25, 0.5, 0.75, 1, 1.5, 2, 3)
eq_runs <- mclapply(eqF, function(Ff) {
    out <- list()
    for (cF in c(mor[["cod"]], default_config()$effort[["cod"]])) {
        e <- mor; e["cod"] <- cF; e["pelagic"] <- Ff
        eq <- equilibrate(params, e, t_max = 400, t_check = 25, tol = 5e-4)
        p <- eq$params; initial_effort(p) <- e
        fl <- getFeedingLevel(p)["Cod", ]; ww <- w(p)
        gc <- getGrowthCurves(p, species = "Cod", max_age = 10)
        out[[length(out) + 1]] <- data.frame(
            F_forage = Ff, F_cod = cF, converged = eq$converged,
            cod_ssb_rel = getSSB(p)[["Cod"]] / base_ssb,
            forage_biomass_rel = sum(eq$biomass[FORAGE]) / base_forage,
            forage_yield_kt = gm2_to_kt(sum(getYield(p)[FORAGE])),
            cod_yield_kt = gm2_to_kt(getYield(p)[["Cod"]]),
            cod_feeding_level_1kg = fl[which.min(abs(ww - 1000))],
            cod_feeding_level_100g = fl[which.min(abs(ww - 100))],
            cod_weight_age5_g = approx(as.numeric(colnames(gc)), gc[1, ], xout = 5)$y,
            fraction_cod_1mg_1g_eaten_by_forage = {b <- prerecruit_budget(p, "Cod", 0.001, 1)
                b$fraction_killed[b$source == "forage"]},
            cod_survival_1mg_1g = prerecruit_budget(p, "Cod", 0.001, 1)$survival[1])
    }
    bind_rows(out)
}, mc.cores = NCORES)
eqdf <- bind_rows(eq_runs)
write.csv(eqdf, "results/v2/forage_fishing_equilibria.csv", row.names = FALSE)
print(eqdf)

# --- Figure 4 -------------------------------------------------------------------------
sel <- traj |> filter(species == "Cod", D == 10 | F_forage == 0.1) |>
    mutate(label = ifelse(F_forage == 0.1, "status quo (0.1)", sprintf("%.2g for 10 yr", F_forage)))
pA <- ggplot(sel, aes(year, ssb / base_ssb, colour = F_forage, group = label)) +
    geom_line(linewidth = 0.7) + scale_y_log10() +
    scale_colour_viridis_c(option = "plasma", end = 0.9, trans = "log10") +
    geom_hline(yintercept = c(0.5, 1), linetype = "dotted") +
    annotate("rect", xmin = 2026, xmax = 2036, ymin = 0, ymax = Inf, alpha = 0.1) +
    coord_cartesian(xlim = c(2026, 2100)) +
    labs(x = NULL, y = "Cod SSB relative to baseline", colour = expression(F[forage]),
         title = "a  Cod after 10 years of forage fishing") + theme_paper()
pB <- metrics |> filter(F_forage > 0.1) |>
    ggplot(aes(factor(F_forage), factor(D), fill = years_to_50pct)) + geom_tile(colour = "white") +
    geom_text(aes(label = ifelse(is.na(years_to_50pct), "none", years_to_50pct)), size = 3) +
    scale_fill_viridis_c(option = "viridis", direction = -1, na.value = "grey85") +
    labs(x = expression("Forage-fish F during programme (yr"^-1*")"), y = "Duration D (years)",
         fill = "Years to\n50% SSB",
         title = sprintf("b  Recovery time (status quo: %s yr)", ifelse(is.na(sq), "none", sq))) +
    theme_paper()
eql <- eqdf |> mutate(cod_F = factor(F_cod))
pC <- ggplot(eql, aes(F_forage, cod_ssb_rel, colour = cod_F)) + geom_line() + geom_point() +
    scale_colour_manual(values = c("#D55E00", "#0072B2"), name = expression(F[cod])) +
    labs(x = expression("Constant forage-fish F (yr"^-1*")"), y = "Equilibrium cod SSB / baseline",
         title = "c  Cod at equilibrium") + theme_paper()
pD <- ggplot(eql, aes(F_forage, cod_feeding_level_1kg, colour = cod_F)) + geom_line() + geom_point() +
    scale_colour_manual(values = c("#D55E00", "#0072B2"), guide = "none") +
    labs(x = expression("Constant forage-fish F (yr"^-1*")"), y = "Feeding level of 1 kg cod",
         title = "d  Food for adult cod") + theme_paper()
pE <- ggplot(eql, aes(F_forage, forage_yield_kt, colour = cod_F)) + geom_line() + geom_point() +
    scale_colour_manual(values = c("#D55E00", "#0072B2"), guide = "none") +
    labs(x = expression("Constant forage-fish F (yr"^-1*")"), y = "Forage-fish yield (kt / yr)",
         title = "e  Forage yield") + theme_paper()
pF <- ggplot(eql, aes(F_forage, cod_weight_age5_g / 1000, colour = cod_F)) + geom_line() + geom_point() +
    scale_colour_manual(values = c("#D55E00", "#0072B2"), guide = "none") +
    labs(x = expression("Constant forage-fish F (yr"^-1*")"), y = "Cod weight at age 5 (kg)",
         title = "f  Cod growth") + theme_paper()
fig4 <- (pA | pB) / (pC | pD) / (pE | pF)
save_fig(fig4, "fig4_forage_fishing", width = 11, height = 11)
cat("04_forage_fishing_recovery.R done\n")
