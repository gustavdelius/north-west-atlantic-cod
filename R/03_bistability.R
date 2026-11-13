# 03_bistability.R  (v3)
# ---------------------------------------------------------------------------
# Acceptance test 3 (key test): are there two attractors?
#   (a) identical parameters and efforts (cod F = 0; other gears at their
#       moratorium levels), two initial states: the 1980-85 baseline
#       (cod-dominated) and the modelled 2025 state of the documented-F
#       hindcast (02); 500-year projections.
#   (b) invasion test: the community with cod exactly absent is brought to
#       equilibrium, cod is reintroduced at 1e-6 of its baseline abundance and
#       its per-capita growth rate is fitted on the rare phase (from year 10
#       until cod passes 1e-3 of baseline biomass; R^2 and window reported).
#       A negative rate means the cod-free state is an attractor.
#   (c) hysteresis: equilibrium cod SSB as cod F is swept up from 0 to 2 and
#       back down, each step continued from the previous equilibrium (in the
#       decreasing sweep cod is floored at 1e-3 of baseline biomass so that
#       numerical extinction cannot masquerade as hysteresis).
#
# Outputs
#   results/bistability_trajectories.csv, results/bistability_invasion.csv,
#   results/hysteresis.csv, results/bistability_summary.csv
#   figures/fig3_bistability.(png|pdf)
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
e0 <- mor; e0["cod"] <- 0

# (a) two initial states, identical parameters and effort ----------------------
runs <- mclapply(list(baseline = NULL, collapsed = collapsed), function(init) {
    run_scenario(params, e0, years = c(0, 500), initial = init)
}, mc.cores = 2)
traj <- bind_rows(lapply(names(runs), function(n) mutate(runs[[n]], start = n)))
write.csv(traj, "results/bistability_trajectories.csv", row.names = FALSE)
end_state <- traj |> filter(year == 500, !grepl("Resource", species)) |>
    select(start, species, biomass) |> pivot_wider(names_from = start, values_from = biomass)
print(end_state)
late_rate <- traj |> filter(species == "Cod", year >= 400) |> group_by(start) |>
    summarise(cod_ssb_end = last(ssb), rel_rate_last100 = coef(lm(log(ssb) ~ year))[2])
print(late_rate)
yrs50 <- traj |> filter(species == "Cod", start == "collapsed") |>
    summarise(y = { i <- which(ssb >= 0.5 * base_ssb); if (length(i)) min(year[i]) else NA })

# (b) invasion test ------------------------------------------------------------
it <- invasion_test(params, e0)
C <- it$cod_free; pc <- C$params; inv <- it$inv
fit <- invasion_fit(inv, getBiomass(params)[["Cod"]])
lam <- fit$rate
k_free <- prerecruit_budget(pc, "Cod", 0.001, 1); k_base <- prerecruit_budget(params, "Cod", 0.001, 1)
invasion <- data.frame(
    quantity = c("cod_free_equilibrium_years", "cod_free_converged",
                 "forage_biomass_cod_free_rel_baseline",
                 "cod_invasion_growth_rate_per_yr", "invasion_fit_r2",
                 "invasion_fit_window_start_yr", "invasion_fit_window_end_yr",
                 "forage_kill_fraction_cod_1mg_1g_baseline",
                 "forage_kill_fraction_cod_1mg_1g_cod_free",
                 "cod_survival_1mg_1g_baseline", "cod_survival_1mg_1g_cod_free"),
    value = c(C$years, C$converged, sum(C$biomass[FORAGE]) / base_forage, lam, fit$r2,
              fit$t_start, fit$t_end,
              k_base$fraction_killed[k_base$source == "forage"],
              k_free$fraction_killed[k_free$source == "forage"],
              k_base$survival[1], k_free$survival[1]))
cf <- data.frame(quantity = paste0("cod_free_biomass_rel_", names(C$biomass)),
                 value = as.numeric(C$biomass / getBiomass(params)))
invasion <- rbind(invasion, cf)
write.csv(invasion, "results/bistability_invasion.csv", row.names = FALSE)
print(invasion)

# (c) hysteresis sweep ----------------------------------------------------------
F_up <- seq(0, 2, by = 0.1)
COD_FLOOR <- 1e-3
floor_cod <- function(p) {
    b <- getBiomass(p)[["Cod"]]; b0 <- getBiomass(params)[["Cod"]]
    if (b < COD_FLOOR * b0) {
        n <- initialN(p); n["Cod", ] <- initialN(params)["Cod", ] * COD_FLOOR
        initialN(p) <- n
    }
    p
}
sweep_F <- function(Fs, start_params, floor = FALSE) {
    p <- start_params
    out <- vector("list", length(Fs))
    for (i in seq_along(Fs)) {
        e <- e0; e["cod"] <- Fs[i]
        if (floor) p <- floor_cod(p)
        b_start <- getBiomass(p)[["Cod"]]
        eq <- equilibrate(p, e, t_max = 400, t_check = 25, tol = 5e-4)
        p <- eq$params
        initial_effort(p) <- e
        out[[i]] <- data.frame(F_cod = Fs[i], years = eq$years, converged = eq$converged,
                               cod_ssb = getSSB(p)[["Cod"]], cod_biomass = eq$biomass[["Cod"]],
                               forage_biomass = sum(eq$biomass[FORAGE]),
                               other_groundfish = sum(eq$biomass[OTHER_GF]),
                               cod_yield = getYield(p)[["Cod"]],
                               cod_biomass_start = b_start)
    }
    list(df = bind_rows(out), end = p)
}
up <- sweep_F(F_up, params)
down <- sweep_F(rev(F_up), up$end, floor = TRUE)
hyst <- bind_rows(mutate(up$df, direction = "increasing F"),
                  mutate(down$df, direction = "decreasing F"))
write.csv(hyst, "results/hysteresis.csv", row.names = FALSE)
print(hyst)

hw <- hyst |> mutate(present = cod_ssb > 0.05 * base_ssb) |>
    select(F_cod, direction, present) |>
    pivot_wider(names_from = direction, values_from = present)
bistable_F <- hw$F_cod[hw$`increasing F` != hw$`decreasing F`]
summ <- data.frame(
    quantity = c("cod_ssb_end_from_baseline_rel", "cod_ssb_end_from_collapsed_rel",
                 "years_to_50pct_from_collapsed_2025_state_F0",
                 "two_distinct_attractors_at_F0", "cod_invasion_growth_rate_per_yr",
                 "invasion_fit_r2",
                 "hysteresis_F_range_min", "hysteresis_F_range_max"),
    value = c(late_rate$cod_ssb_end[late_rate$start == "baseline"] / base_ssb,
              late_rate$cod_ssb_end[late_rate$start == "collapsed"] / base_ssb,
              yrs50$y,
              abs(log(late_rate$cod_ssb_end[1] / late_rate$cod_ssb_end[2])) > log(2),
              lam, fit$r2,
              if (length(bistable_F)) min(bistable_F) else NA,
              if (length(bistable_F)) max(bistable_F) else NA))
write.csv(summ, "results/bistability_summary.csv", row.names = FALSE)
print(summ)

# --- Figure 3 -----------------------------------------------------------------
pal <- c(baseline = "#0072B2", collapsed = "#D55E00")
pA <- traj |> filter(species == "Cod") |>
    ggplot(aes(year, ssb / base_ssb, colour = start)) + geom_line(linewidth = 0.8) +
    scale_y_log10() + scale_colour_manual(values = pal,
                                          labels = c(baseline = "from 1980-85 baseline",
                                                     collapsed = "from modelled 2025 state")) +
    labs(x = "Years at cod F = 0", y = "Cod SSB relative to baseline", colour = "Initial state",
         title = "a  Same parameters, same effort, two starts") +
    theme_paper() + theme(legend.position = "inside", legend.position.inside = c(0.65, 0.25))
pB <- traj |> filter(species %in% FORAGE) |> group_by(start, year) |>
    summarise(b = sum(biomass), .groups = "drop") |>
    ggplot(aes(year, b / base_forage, colour = start)) + geom_line(linewidth = 0.8) +
    scale_colour_manual(values = pal, guide = "none") + scale_y_log10() +
    labs(x = "Years at cod F = 0", y = "Forage-fish biomass relative to baseline",
         title = "b  Forage fish") + theme_paper()
Binv <- getBiomass(inv)
invd <- data.frame(year = as.numeric(rownames(Binv)), Cod = as.numeric(Binv[, "Cod"]) / getBiomass(params)[["Cod"]])
x0 <- invd$year[which.min(abs(invd$year - fit$t_start))]
b_at <- invd$Cod[invd$year == x0]
fitline <- data.frame(year = c(fit$t_start, fit$t_end),
                      Cod = b_at * exp(lam * (c(fit$t_start, fit$t_end) - x0)))
pC <- ggplot(invd, aes(year, Cod)) + geom_line(linewidth = 0.8) +
    geom_line(data = fitline, colour = "#D55E00", linetype = "dashed", linewidth = 0.8) +
    geom_hline(yintercept = 1e-3, linetype = "dotted") + scale_y_log10() +
    labs(x = "Years after reintroduction", y = "Cod biomass relative to baseline",
         title = sprintf("c  Invasion of the cod-free state: %.3f / yr (fit, R2 %.2f)", lam, fit$r2)) +
    theme_paper()
pD <- ggplot(hyst, aes(F_cod, cod_ssb / base_ssb, shape = direction, linetype = direction)) +
    geom_line() + geom_point(size = 2) +
    scale_shape_manual(values = c("increasing F" = 16, "decreasing F" = 1)) +
    geom_vline(xintercept = default_config()$effort[["cod"]], linetype = "dotted") +
    labs(x = expression("Cod fishing mortality F (yr"^-1*")"), y = "Equilibrium cod SSB / baseline",
         shape = NULL, linetype = NULL, title = "d  Hysteresis test (other gears at moratorium levels)") +
    theme_paper() + theme(legend.position = "inside", legend.position.inside = c(0.75, 0.8))
fig3 <- (pA | pB) / (pC | pD)
save_fig(fig3, "fig3_bistability", width = 11, height = 8)
cat("03_bistability.R done\n")
