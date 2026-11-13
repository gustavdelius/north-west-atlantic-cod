# 04b_forage_fishing_strong_variant.R  (v2)
# ---------------------------------------------------------------------------
# Diagnostic companion to 04: in the main v2 model cod has recovered by 2026,
# so forage fishing cannot speed recovery. Here the same programmes are run
# with the forage -> cod interaction s_egg = 20 (see 05: the smallest tested
# value for which the moratorium fails for > 30 years). The main model is NOT
# recalibrated for this (its 1980s cod state is not sustained at s_egg = 20,
# see SUMMARY), so this is a what-if from the observed-like 2000 state.
# Outputs: results/forage_fishing_grid_s20.csv,
#          results/forage_fishing_trajectories_s20.csv,
#          figures/fig4b_forage_fishing_strong_variant.(png|pdf)
# ---------------------------------------------------------------------------
source("R/v2/functions.R")
suppressPackageStartupMessages({
    library(ggplot2); library(patchwork); library(dplyr); library(parallel)
})
options(mizer_info_level = 0)
S_EGG <- 20
p <- readParams("models/v2/baseline_params.rds")
im <- interaction_matrix(p); im[FORAGE, "Cod"] <- S_EGG; interaction_matrix(p) <- im
base_ssb <- getSSB(p)[["Cod"]]
base_forage <- sum(getBiomass(p)[FORAGE])
eh <- read_effort_history()
mor <- moratorium_effort(eh)
p2000 <- readParams("models/v2/collapsed_state_params.rds")
h <- run_scenario(p, mor, years = c(2000, 2025), initial = p2000, return_sim = TRUE)

grid <- expand.grid(F_forage = c(0.1, 0.25, 0.5, 1, 2), D = c(5, 10, 20, 40))
grid <- grid[!(grid$F_forage == 0.1 & grid$D != 5), ]
res <- mclapply(seq_len(nrow(grid)), function(i) {
    Ff <- grid$F_forage[i]; D <- grid$D[i]
    eff <- as.data.frame(rbind(mor, mor)); eff$year <- c(2026, 2026 + D)
    eff$pelagic <- c(Ff, mor[["pelagic"]])
    df <- run_scenario(p, eff, years = c(2026, 2200), initial = h$sim)
    cod <- df[df$species == "Cod", ]
    fo <- aggregate(biomass ~ year, data = df[df$species %in% FORAGE, ], sum)
    fy <- aggregate(yield ~ year, data = df[df$species %in% FORAGE, ], sum)
    rec <- cod$year[cod$ssb >= 0.5 * base_ssb]
    list(df = mutate(df, F_forage = Ff, D = D),
         m = data.frame(F_forage = Ff, D = D,
                        years_to_50pct = if (length(rec)) min(rec) - 2026 else NA,
                        cod_ssb_end_programme_rel = cod$ssb[cod$year == 2026 + D] / base_ssb,
                        cod_ssb_2100_rel = cod$ssb[cod$year == 2100] / base_ssb,
                        cod_ssb_2200_rel = cod$ssb[cod$year == 2200] / base_ssb,
                        forage_min_rel = min(fo$biomass) / base_forage,
                        forage_yield_cumulative_kt = gm2_to_kt(sum(fy$yield[fy$year < 2026 + D]))))
}, mc.cores = min(8, parallel::detectCores()))
met <- bind_rows(lapply(res, `[[`, "m"))
sq <- met$years_to_50pct[met$F_forage == 0.1]
met$years_saved_vs_status_quo <- sq - met$years_to_50pct
write.csv(met, "results/v2/forage_fishing_grid_s20.csv", row.names = FALSE)
print(met)
traj <- bind_rows(lapply(res, `[[`, "df"))
write.csv(traj |> filter(species %in% c("Cod", FORAGE)),
          "results/v2/forage_fishing_trajectories_s20.csv", row.names = FALSE)

pA <- traj |> filter(species == "Cod", D == 10 | F_forage == 0.1) |>
    ggplot(aes(year, ssb / base_ssb, colour = F_forage, group = F_forage)) +
    geom_line(linewidth = 0.7) + scale_y_log10() +
    scale_colour_viridis_c(option = "plasma", end = 0.9, trans = "log10") +
    geom_hline(yintercept = 0.5, linetype = "dotted") +
    annotate("rect", xmin = 2026, xmax = 2036, ymin = 0, ymax = Inf, alpha = 0.1) +
    labs(x = NULL, y = "Cod SSB relative to baseline", colour = expression(F[forage]),
         title = "a  What-if s_egg = 20: 10-yr programmes") + theme_paper()
pB <- met |> filter(F_forage > 0.1) |>
    ggplot(aes(factor(F_forage), factor(D), fill = years_to_50pct)) + geom_tile(colour = "white") +
    geom_text(aes(label = ifelse(is.na(years_to_50pct), "none", years_to_50pct)), size = 3) +
    scale_fill_viridis_c(direction = -1, na.value = "grey85") +
    labs(x = expression("Forage-fish F during programme (yr"^-1*")"), y = "Duration D (years)",
         fill = "Years to\n50% SSB", title = sprintf("b  Years to 50%% SSB (status quo %s)", sq)) +
    theme_paper()
save_fig(pA | pB, "fig4b_forage_fishing_strong_variant", width = 11, height = 4.5)
cat("04b_forage_fishing_strong_variant.R done\n")
