# 04_forage_fishing_recovery.R  (v3)
# ---------------------------------------------------------------------------
# Acceptance test 4 (v3): from the modelled 2025 state of the documented-F
# hindcast (models/collapsed_2025_params.rds, written by 02), raise the
# forage-fish (pelagic) effort to F_forage for D years from 2026, then return
# it to the status quo (0.1); cod stays at its moratorium bycatch F (0.02),
# the other groundfish gears at their moratorium levels. Only fishing effort
# differs between runs. Outputs per run: years to 50 % and 100 % of baseline
# cod SSB, whether recovery persists to 2125 (SSB >= 50 % in every year of
# the last 30), minimum forage biomass, forage and cod yields.
# Thresholds: for each D the smallest F_forage that gives persistent
# recovery, and for each F_forage the shortest D.
# Trade-off: constant-F_forage equilibria (cod F 0.02 and reopened at 0.40):
# cod SSB, cod food, growth, early-life survival, forage and cod yields.
#
# Outputs
#   results/forage_fishing_grid.csv, results/forage_fishing_thresholds.csv,
#   results/forage_fishing_trajectories.csv, results/forage_fishing_equilibria.csv
#   figures/fig4_forage_fishing.(png|pdf)
# ---------------------------------------------------------------------------
source("R/functions.R")
suppressPackageStartupMessages({
    library(ggplot2); library(patchwork); library(dplyr); library(tidyr); library(parallel)
})
options(mizer_info_level = 0)
params <- readParams("models/baseline_params.rds")
collapsed <- readParams("models/collapsed_2025_params.rds")
base_ssb <- getSSB(params)[["Cod"]]
base_forage <- sum(getBiomass(params)[FORAGE])
mor <- moratorium_effort()
NCORES <- min(8, parallel::detectCores())
END <- 2125

F_grid <- c(0.1, 0.25, 0.5, 0.75, 1.0, 1.5, 2.0, 3.0)
D_grid <- c(5, 10, 15, 20, 30, END - 2026 + 1)          # last = permanent
grid <- expand.grid(F_forage = F_grid, D = D_grid)
grid <- grid[!(grid$F_forage == 0.1 & grid$D != 5), ]   # status quo once

one_run <- function(Ff, D) {
    eff <- as.data.frame(rbind(mor, mor)); eff$year <- c(2026, 2026 + D)
    eff$pelagic <- c(Ff, mor[["pelagic"]])
    df <- run_scenario(params, eff, years = c(2026, END), initial = collapsed)
    cod <- df[df$species == "Cod", ]
    fy <- aggregate(yield ~ year, data = df[df$species %in% FORAGE, ], sum)
    fb <- aggregate(biomass ~ year, data = df[df$species %in% FORAGE, ], sum)
    rec <- cod$year[cod$ssb >= 0.5 * base_ssb]
    rec_full <- cod$year[cod$ssb >= base_ssb]
    last30 <- cod$ssb[cod$year > END - 30]
    during <- fy$year >= 2026 & fy$year < 2026 + D
    list(df = mutate(df, F_forage = Ff, D = D),
         metrics = data.frame(
             F_forage = Ff, D = D, permanent = D >= END - 2026 + 1,
             years_to_50pct = if (length(rec)) min(rec) - 2026 else NA,
             years_to_100pct = if (length(rec_full)) min(rec_full) - 2026 else NA,
             persistent_recovery = all(last30 >= 0.5 * base_ssb),
             cod_ssb_end_programme_rel = cod$ssb[cod$year == min(2026 + D, END)] / base_ssb,
             cod_ssb_2085_rel = cod$ssb[cod$year == 2085] / base_ssb,
             cod_ssb_2125_rel = cod$ssb[cod$year == END] / base_ssb,
             forage_min_rel = min(fb$biomass) / base_forage,
             forage_2125_rel = fb$biomass[fb$year == END] / base_forage,
             forage_yield_during_kt_per_yr = gm2_to_kt(mean(fy$yield[during])),
             forage_yield_2026_2085_kt = gm2_to_kt(sum(fy$yield[fy$year <= 2085])),
             cod_yield_2026_2085_kt = gm2_to_kt(sum(cod$yield[cod$year <= 2085]))))
}
res <- mclapply(seq_len(nrow(grid)), function(i) one_run(grid$F_forage[i], grid$D[i]),
                mc.cores = NCORES)
metrics <- bind_rows(lapply(res, `[[`, "metrics"))
sq <- metrics$years_to_50pct[metrics$F_forage == 0.1]
metrics$years_saved_vs_status_quo <- if (is.na(sq)) NA else sq - metrics$years_to_50pct
write.csv(metrics, "results/forage_fishing_grid.csv", row.names = FALSE)
print(metrics)
ok <- function(x) !is.na(x$years_to_50pct) & x$persistent_recovery
thrD <- metrics |> filter(F_forage > 0.1) |> group_by(D) |>
    summarise(min_F_for_persistent_recovery = if (any(ok(cur_data()))) min(F_forage[ok(cur_data())]) else NA,
              .groups = "drop")
thrF <- metrics |> filter(F_forage > 0.1) |> group_by(F_forage) |>
    summarise(min_D_for_persistent_recovery = if (any(ok(cur_data()))) min(D[ok(cur_data())]) else NA,
              .groups = "drop")
thr <- bind_rows(mutate(thrD, kind = "by duration"), mutate(thrF, kind = "by forage F"))
write.csv(thr, "results/forage_fishing_thresholds.csv", row.names = FALSE)
print(thr)
traj <- bind_rows(lapply(res, `[[`, "df")) |>
    filter(D %in% c(10, 20, END - 2026 + 1) | F_forage == 0.1, !grepl("Resource", species))
write.csv(traj, "results/forage_fishing_trajectories.csv", row.names = FALSE)

# --- constant forage-F equilibria (trade-off) ----------------------------------------
eqF <- c(0, 0.1, 0.25, 0.5, 0.75, 1, 1.5, 2, 3)
eq_runs <- mclapply(eqF, function(Ff) {
    out <- list()
    for (cF in c(mor[["cod"]], default_config()$effort[["cod"]])) {
        e <- mor; e["cod"] <- cF; e["pelagic"] <- Ff
        for (start in c("baseline", "collapsed")) {
            init <- if (start == "baseline") NULL else collapsed
            eq <- equilibrate(params, e, initial = init, t_max = 500, t_check = 25, tol = 5e-4)
            p <- eq$params; initial_effort(p) <- e
            fl <- getFeedingLevel(p)["Cod", ]; ww <- w(p)
            gc <- getGrowthCurves(p, species = "Cod", max_age = 10)
            bud <- prerecruit_budget(p, "Cod", 0.001, 1)
            out[[length(out) + 1]] <- data.frame(
                F_forage = Ff, F_cod = cF, start = start, converged = eq$converged,
                cod_ssb_rel = getSSB(p)[["Cod"]] / base_ssb,
                forage_biomass_rel = sum(eq$biomass[FORAGE]) / base_forage,
                other_groundfish_rel = sum(eq$biomass[OTHER_GF]) / sum(getBiomass(params)[OTHER_GF]),
                forage_yield_kt = gm2_to_kt(sum(getYield(p)[FORAGE])),
                cod_yield_kt = gm2_to_kt(getYield(p)[["Cod"]]),
                cod_feeding_level_1kg = fl[which.min(abs(ww - 1000))],
                cod_feeding_level_100g = fl[which.min(abs(ww - 100))],
                cod_weight_age5_g = approx(as.numeric(colnames(gc)), gc[1, ], xout = 5)$y,
                fraction_cod_1mg_1g_eaten_by_forage = bud$fraction_killed[bud$source == "forage"],
                cod_survival_1mg_1g = bud$survival[1])
        }
    }
    bind_rows(out)
}, mc.cores = NCORES)
eqdf <- bind_rows(eq_runs)
write.csv(eqdf, "results/forage_fishing_equilibria.csv", row.names = FALSE)
print(eqdf)

# --- Figure 4 -------------------------------------------------------------------------
lab_D <- function(D) ifelse(D >= END - 2026 + 1, "permanent", as.character(D))
sel <- traj |> filter(species == "Cod", D == 10 | F_forage == 0.1) |>
    mutate(label = ifelse(F_forage == 0.1, "status quo (0.1)", sprintf("%.2g for 10 yr", F_forage)))
pA <- ggplot(sel, aes(year, ssb / base_ssb, colour = F_forage, group = label)) +
    geom_line(linewidth = 0.7) + scale_y_log10() +
    scale_colour_viridis_c(option = "plasma", end = 0.9, trans = "log10") +
    geom_hline(yintercept = c(0.5, 1), linetype = "dotted") +
    annotate("rect", xmin = 2026, xmax = 2036, ymin = 0, ymax = Inf, alpha = 0.1) +
    labs(x = NULL, y = "Cod SSB relative to baseline", colour = expression(F[forage]),
         title = "a  Cod after 10 years of forage fishing") + theme_paper()
gm <- metrics |> filter(F_forage > 0.1) |>
    mutate(Dl = factor(lab_D(D), levels = lab_D(D_grid)),
           txt = ifelse(is.na(years_to_50pct), "none", ifelse(persistent_recovery, years_to_50pct,
                                                               paste0(years_to_50pct, "*"))))
pB <- ggplot(gm, aes(factor(F_forage), Dl, fill = years_to_50pct)) + geom_tile(colour = "white") +
    geom_text(aes(label = txt), size = 3) +
    scale_fill_viridis_c(option = "viridis", direction = -1, na.value = "grey85") +
    labs(x = expression("Forage-fish F during programme (yr"^-1*")"), y = "Duration D (years)",
         fill = "Years to\n50% SSB",
         title = sprintf("b  Recovery time (* = not persistent; status quo: %s)",
                         ifelse(is.na(sq), "none by 2125", paste(sq, "yr")))) +
    theme_paper()
eql <- eqdf |> mutate(cod_F = factor(F_cod), start = factor(start))
sc <- scale_colour_manual(values = c("#D55E00", "#0072B2"), name = expression(F[cod]))
pC <- ggplot(eql, aes(F_forage, cod_ssb_rel, colour = cod_F, linetype = start)) + geom_line() + geom_point() +
    sc + scale_y_log10() +
    labs(x = expression("Constant forage-fish F (yr"^-1*")"), y = "Equilibrium cod SSB / baseline",
         linetype = "Start", title = "c  Cod at equilibrium") + theme_paper()
pD <- ggplot(eql, aes(F_forage, cod_feeding_level_1kg, colour = cod_F, linetype = start)) + geom_line() + geom_point() +
    scale_colour_manual(values = c("#D55E00", "#0072B2"), guide = "none") + guides(linetype = "none") +
    labs(x = expression("Constant forage-fish F (yr"^-1*")"), y = "Feeding level of 1 kg cod",
         title = "d  Food for adult cod") + theme_paper()
pE <- ggplot(eql, aes(F_forage, forage_yield_kt, colour = cod_F, linetype = start)) + geom_line() + geom_point() +
    scale_colour_manual(values = c("#D55E00", "#0072B2"), guide = "none") + guides(linetype = "none") +
    labs(x = expression("Constant forage-fish F (yr"^-1*")"), y = "Forage-fish yield (kt / yr)",
         title = "e  Forage yield") + theme_paper()
pF <- ggplot(eql, aes(F_forage, cod_weight_age5_g / 1000, colour = cod_F, linetype = start)) + geom_line() + geom_point() +
    scale_colour_manual(values = c("#D55E00", "#0072B2"), guide = "none") + guides(linetype = "none") +
    labs(x = expression("Constant forage-fish F (yr"^-1*")"), y = "Cod weight at age 5 (kg)",
         title = "f  Cod growth") + theme_paper()
fig4 <- (pA | pB) / (pC | pD) / (pE | pF)
save_fig(fig4, "fig4_forage_fishing", width = 12, height = 11)
cat("04_forage_fishing_recovery.R done\n")
