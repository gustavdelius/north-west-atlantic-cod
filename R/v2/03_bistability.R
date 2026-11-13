# 03_bistability.R  (v2)
# ---------------------------------------------------------------------------
# Acceptance test 3 (key test): are there two attractors at cod F = 0?
#   (a) identical parameters and efforts (cod F = 0; other gears at their
#       post-1993 levels), two initial states: the 1980-85 baseline
#       (cod-dominated) and the observed-like 2000 state (02);
#       500-year projections.
#   (b) invasion test: the community with cod exactly absent is brought to
#       equilibrium, cod is reintroduced at 1e-6 of its baseline abundance and
#       its per-capita growth rate is measured. A negative rate means the
#       cod-free state is an attractor (alternative stable state).
#   (c) hysteresis: equilibrium cod SSB as cod F is swept up from 0 to 2 and
#       back down, each step continued from the previous equilibrium (in the
#       decreasing sweep cod is floored at 1e-3 of baseline biomass, see below).
#
# Outputs
#   results/bistability_trajectories.csv, results/bistability_invasion.csv,
#   results/hysteresis.csv, results/bistability_summary.csv
#   figures/fig3_bistability.(png|pdf)
# ---------------------------------------------------------------------------
source("R/v2/functions.R")
suppressPackageStartupMessages({
    library(ggplot2); library(patchwork); library(dplyr); library(tidyr); library(parallel)
})
options(mizer_info_level = 0)
params <- readParams("models/v2/baseline_params.rds")
# "Collapsed" initial state: the observed-like post-collapse community of
# 2000 from the cod-forced calibration hindcast (models/collapsed_state_params.rds;
# cod ~0.1 of the 1980s, forage-fish boom, other groundfish reduced).
collapsed <- readParams("models/v2/collapsed_state_params.rds")
base_ssb <- getSSB(params)[["Cod"]]
base_forage <- sum(getBiomass(params)[FORAGE])
mor <- moratorium_effort()
e0 <- mor; e0["cod"] <- 0

# (a) two initial states, identical parameters and effort ----------------------
runs <- mclapply(list(baseline = NULL, collapsed = collapsed), function(init) {
    run_scenario(params, e0, years = c(0, 500), initial = init)
}, mc.cores = 2)
traj <- bind_rows(lapply(names(runs), function(n) mutate(runs[[n]], start = n)))
write.csv(traj, "results/v2/bistability_trajectories.csv", row.names = FALSE)
end_state <- traj |> filter(year == 500, species != "Resource") |>
    select(start, species, biomass) |> pivot_wider(names_from = start, values_from = biomass)
print(end_state)
# rate of change of cod SSB over the last 100 years of each run
late_rate <- traj |> filter(species == "Cod", year >= 400) |> group_by(start) |>
    summarise(cod_ssb_end = last(ssb), rel_rate_last100 = coef(lm(log(ssb) ~ year))[2])
print(late_rate)

# (b) invasion test ------------------------------------------------------------
it <- invasion_test(params, e0)
C <- it$cod_free; pc <- C$params; inv <- it$inv; lam <- it$rate
k_free <- prerecruit_budget(pc, "Cod", 0.001, 1); k_base <- prerecruit_budget(params, "Cod", 0.001, 1)
invasion <- data.frame(
    quantity = c("cod_free_equilibrium_years", "cod_free_converged",
                 "forage_biomass_cod_free_rel_baseline",
                 "cod_invasion_growth_rate_per_yr",
                 "forage_kill_fraction_cod_1mg_1g_baseline",
                 "forage_kill_fraction_cod_1mg_1g_cod_free",
                 "cod_survival_1mg_1g_baseline", "cod_survival_1mg_1g_cod_free"),
    value = c(C$years, C$converged, sum(C$biomass[FORAGE]) / base_forage, lam,
              k_base$fraction_killed[k_base$source == "forage"],
              k_free$fraction_killed[k_free$source == "forage"],
              k_base$survival[1], k_free$survival[1]))
cf <- data.frame(quantity = paste0("cod_free_biomass_rel_", names(C$biomass)),
                 value = as.numeric(C$biomass / getBiomass(params)))
invasion <- rbind(invasion, cf)
write.csv(invasion, "results/v2/bistability_invasion.csv", row.names = FALSE)
print(invasion)

# (c) hysteresis sweep ----------------------------------------------------------
F_up <- seq(0, 2, by = 0.1)
# In the decreasing-F sweep cod is first floored at COD_FLOOR of its baseline
# biomass (spectrum shape of the baseline). Without a floor, cod driven to
# ~1e-80 at high F could not regrow within any finite run and the sweep would
# show spurious hysteresis caused by numerical extinction. A genuine
# alternative stable state pulls cod down again from the floor.
COD_FLOOR <- 1e-3
floor_cod <- function(p) {
    b <- getBiomass(p)[["Cod"]]; b0 <- getBiomass(params)[["Cod"]]
    if (b < COD_FLOOR * b0) {
        n <- initialN(p); n["Cod", ] <- initialN(params)["Cod", ] * COD_FLOOR
        initialN(p) <- n
    }
    p
}
sweep <- function(Fs, start_params, floor = FALSE) {
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
                               other_groundfish = sum(eq$biomass[c("Haddock", "Silver hake", "American plaice")]),
                               cod_yield = getYield(p)[["Cod"]],
                               cod_biomass_start = b_start)
    }
    list(df = bind_rows(out), end = p)
}
up <- sweep(F_up, params)
down <- sweep(rev(F_up), up$end, floor = TRUE)
hyst <- bind_rows(mutate(up$df, direction = "increasing F"),
                  mutate(down$df, direction = "decreasing F"))
write.csv(hyst, "results/v2/hysteresis.csv", row.names = FALSE)
print(hyst)

# cod counts as "present" at an equilibrium if its SSB exceeds 5% of baseline;
# the two sweeps disagree (hysteresis) where one has cod present and the other not
hw <- hyst |> mutate(present = cod_ssb > 0.05 * base_ssb) |>
    select(F_cod, direction, present) |>
    pivot_wider(names_from = direction, values_from = present)
bistable_F <- hw$F_cod[hw$`increasing F` != hw$`decreasing F`]
summ <- data.frame(
    quantity = c("cod_ssb_end_from_baseline_rel", "cod_ssb_end_from_collapsed_rel",
                 "two_distinct_attractors_at_F0", "cod_invasion_growth_rate_per_yr",
                 "hysteresis_F_range_min", "hysteresis_F_range_max"),
    value = c(late_rate$cod_ssb_end[late_rate$start == "baseline"] / base_ssb,
              late_rate$cod_ssb_end[late_rate$start == "collapsed"] / base_ssb,
              abs(log(late_rate$cod_ssb_end[1] / late_rate$cod_ssb_end[2])) > log(2),
              lam,
              if (length(bistable_F)) min(bistable_F) else NA,
              if (length(bistable_F)) max(bistable_F) else NA))
write.csv(summ, "results/v2/bistability_summary.csv", row.names = FALSE)
print(summ)

# --- Figure 3 -----------------------------------------------------------------
pA <- traj |> filter(species == "Cod") |>
    ggplot(aes(year, ssb / base_ssb, colour = start)) + geom_line(linewidth = 0.8) +
    scale_y_log10() + scale_colour_manual(values = c(baseline = "#0072B2", collapsed = "#D55E00"),
                                          labels = c(baseline = "from 1980-85 baseline",
                                                     collapsed = "from observed-like 2000 state")) +
    labs(x = "Years at cod F = 0", y = "Cod SSB relative to baseline", colour = "Initial state",
         title = "a  Same parameters, same effort, two starts") +
    theme_paper() + theme(legend.position = c(0.65, 0.25))
pB <- traj |> filter(species %in% FORAGE) |> group_by(start, year) |>
    summarise(b = sum(biomass), .groups = "drop") |>
    ggplot(aes(year, b / base_forage, colour = start)) + geom_line(linewidth = 0.8) +
    scale_colour_manual(values = c(baseline = "#0072B2", collapsed = "#D55E00"), guide = "none") +
    labs(x = "Years at cod F = 0", y = "Forage-fish biomass relative to baseline",
         title = "b  Forage fish") + theme_paper()
Binv <- getBiomass(inv)
pC <- data.frame(year = as.numeric(rownames(Binv)), Cod = as.numeric(Binv[, "Cod"])) |>
    ggplot(aes(year, Cod / getBiomass(params)[["Cod"]])) + geom_line(linewidth = 0.8) +
    scale_y_log10() +
    labs(x = "Years after reintroduction", y = "Cod biomass relative to baseline",
         title = sprintf("c  Invasion of the cod-free state: rate %.2f / yr", lam)) + theme_paper()
pD <- ggplot(hyst, aes(F_cod, cod_ssb / base_ssb, shape = direction, linetype = direction)) +
    geom_line() + geom_point(size = 2) +
    scale_shape_manual(values = c("increasing F" = 16, "decreasing F" = 1)) +
    geom_vline(xintercept = default_config()$effort[["cod"]], linetype = "dotted") +
    labs(x = expression("Cod fishing mortality F (yr"^-1*")"), y = "Equilibrium cod SSB / baseline",
         shape = NULL, linetype = NULL, title = "d  Hysteresis test") +
    theme_paper() + theme(legend.position = c(0.75, 0.8))
fig3 <- (pA | pB) / (pC | pD)
save_fig(fig3, "fig3_bistability", width = 11, height = 8)
cat("03_bistability.R done\n")
