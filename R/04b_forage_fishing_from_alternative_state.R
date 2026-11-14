# 04b_forage_fishing_from_alternative_state.R  (v3)
# ---------------------------------------------------------------------------
# Test 4 from the model's own alternative stable state. 03 finds that with
# s = 20 the cod-free community (forage fish ~x19, all groundfish absent) at
# cod F = 0 cannot be invaded by rare cod (growth rate < 0). Here that state
# is the starting point, with cod AND the other three groundfish reintroduced
# at 1e-3 of their baseline biomass (baseline size structure). Parameters are
# the baseline ones; only the initial state and fishing effort differ from the
# other scenarios. Forage-fish F is raised to F_forage for D years from year
# 0, then returned to 0.1; cod F = 0.02 (bycatch), other groundfish gears at
# their moratorium levels. Does cod recover, how fast, and does it persist?
# Outputs: results/forage_fishing_alt_state_grid.csv,
#          results/forage_fishing_alt_state_trajectories.csv,
#          figures/fig4b_forage_fishing_alt_state.(png|pdf)
# ---------------------------------------------------------------------------
source("R/functions.R")
suppressPackageStartupMessages({
    library(ggplot2); library(patchwork); library(dplyr); library(tidyr); library(parallel)
})
options(mizer_info_level = 0)
params <- readParams("models/baseline_params.rds")
base_ssb <- getSSB(params)[["Cod"]]
base_forage <- sum(getBiomass(params)[FORAGE])
mor <- moratorium_effort()
e0 <- mor; e0["cod"] <- 0
NCORES <- min(8, parallel::detectCores())
END <- 150

# cod-free and groundfish-free attractor (as in the invasion test of 03)
pf <- params; n <- initialN(pf); n["Cod", ] <- 0; initialN(pf) <- n
C <- equilibrate(pf, e0, t_max = 400, t_check = 25, tol = 5e-4, floor = 1e-14)
alt <- C$params
n <- initialN(alt)
for (sp in GROUNDFISH) n[sp, ] <- initialN(params)[sp, ] * 1e-3
initialN(alt) <- n
initial_effort(alt) <- mor
saveParams(setMetadata(alt, title = "4VsW model v3: alternative stable state (cod-free, forage-dominated) with groundfish reintroduced at 1e-3",
                       description = "Baseline parameters; state from equilibrate() at cod F = 0."),
           "models/alternative_state_params.rds")
cat("alternative state: forage biomass rel. baseline", sum(getBiomass(alt)[FORAGE]) / base_forage, "\n")

F_grid <- c(0.1, 0.25, 0.5, 0.75, 1.0, 1.5, 2.0, 3.0)
D_grid <- c(5, 10, 15, 20, 30, END)
grid <- expand.grid(F_forage = F_grid, D = D_grid)
grid <- grid[!(grid$F_forage == 0.1 & grid$D != 5), ]
one_run <- function(Ff, D) {
    eff <- as.data.frame(rbind(mor, mor)); eff$year <- c(0, D)
    eff$pelagic <- c(Ff, mor[["pelagic"]])
    df <- run_scenario(params, eff, years = c(0, END), initial = alt)
    cod <- df[df$species == "Cod", ]
    fb <- aggregate(biomass ~ year, data = df[df$species %in% FORAGE, ], sum)
    fy <- aggregate(yield ~ year, data = df[df$species %in% FORAGE, ], sum)
    gf <- aggregate(biomass ~ year, data = df[df$species %in% OTHER_GF, ], sum)
    rec <- cod$year[cod$ssb >= 0.5 * base_ssb]
    list(df = mutate(df, F_forage = Ff, D = D),
         metrics = data.frame(F_forage = Ff, D = D, permanent = D >= END,
                              years_to_50pct = if (length(rec)) min(rec) else NA,
                              persistent_recovery = all(cod$ssb[cod$year > END - 30] >= 0.5 * base_ssb),
                              cod_ssb_end_rel = cod$ssb[cod$year == END] / base_ssb,
                              cod_ssb_after_programme_rel = cod$ssb[cod$year == min(D, END)] / base_ssb,
                              other_groundfish_end_rel = gf$biomass[gf$year == END] / sum(getBiomass(params)[OTHER_GF]),
                              forage_min_rel = min(fb$biomass) / base_forage,
                              forage_end_rel = fb$biomass[fb$year == END] / base_forage,
                              forage_yield_during_kt_per_yr = gm2_to_kt(mean(fy$yield[fy$year < D])),
                              cod_yield_first_60yr_kt = gm2_to_kt(sum(cod$yield[cod$year < 60]))))
}
res <- mclapply(seq_len(nrow(grid)), function(i) one_run(grid$F_forage[i], grid$D[i]), mc.cores = NCORES)
metrics <- bind_rows(lapply(res, `[[`, "metrics"))
write.csv(metrics, "results/forage_fishing_alt_state_grid.csv", row.names = FALSE)
print(metrics)
traj <- bind_rows(lapply(res, `[[`, "df")) |> filter(D %in% c(10, 30) | F_forage == 0.1, !grepl("Resource", species))
write.csv(traj, "results/forage_fishing_alt_state_trajectories.csv", row.names = FALSE)

lab_D <- function(D) ifelse(D >= END, "permanent", as.character(D))
gm <- metrics |> filter(F_forage > 0.1) |>
    mutate(Dl = factor(lab_D(D), levels = lab_D(D_grid)),
           txt = ifelse(is.na(years_to_50pct), "none", ifelse(persistent_recovery, years_to_50pct,
                                                               paste0(years_to_50pct, "*"))))
sq <- metrics$years_to_50pct[metrics$F_forage == 0.1]
pA <- traj |> filter(species == "Cod", D == 10 | F_forage == 0.1) |>
    ggplot(aes(year, ssb / base_ssb, colour = F_forage, group = F_forage)) + geom_line(linewidth = 0.7) +
    scale_y_log10() + scale_colour_viridis_c(option = "plasma", end = 0.9, trans = "log10") +
    geom_hline(yintercept = c(0.5, 1), linetype = "dotted") +
    annotate("rect", xmin = 0, xmax = 10, ymin = 0, ymax = Inf, alpha = 0.1) +
    labs(x = "Years from the alternative state", y = "Cod SSB relative to baseline",
         colour = expression(F[forage]), title = "a  Cod after 10 years of forage fishing") + theme_paper()
pB <- ggplot(gm, aes(factor(F_forage), Dl, fill = years_to_50pct)) + geom_tile(colour = "white") +
    geom_text(aes(label = txt), size = 3) +
    scale_fill_viridis_c(direction = -1, na.value = "grey85") +
    labs(x = expression("Forage-fish F during programme (yr"^-1*")"), y = "Duration D (years)",
         fill = "Years to\n50% SSB",
         title = sprintf("b  Years to 50 %% SSB (*: not persistent; status quo: %s)",
                         ifelse(is.na(sq), "none", paste(sq, "yr")))) + theme_paper()
save_fig(pA | pB, "fig4b_forage_fishing_alt_state", width = 12, height = 4.8)
cat("04b_forage_fishing_from_alternative_state.R done\n")
