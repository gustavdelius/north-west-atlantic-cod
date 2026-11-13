# 04b_forage_fishing_strong_variant.R
# ---------------------------------------------------------------------------
# Diagnostic companion to 04: in the main model cod has already recovered by
# 2026, so a forage-fishing programme cannot speed recovery. Here the same
# programmes are run in the only sensitivity variant whose moratorium fails
# for > 30 years: s_egg = 100 (forage fish -> cod interaction 100, i.e.
# forage fish kill ~87% of cod eggs/larvae at the 1980-85 baseline, far above
# empirical estimates; see SUMMARY.md). This shows what forage fishing would
# do IF the egg-predation mechanism were that strong. Requires the variant
# model cached by 05_sensitivity.R (models/sensitivity/s_egg_100.rds).
# Outputs: results/forage_fishing_grid_s100.csv,
#          results/forage_fishing_trajectories_s100.csv,
#          figures/fig4b_forage_fishing_strong_variant.(png|pdf)
# ---------------------------------------------------------------------------
source("R/v1/functions.R")
suppressPackageStartupMessages({
    library(ggplot2); library(patchwork); library(dplyr); library(parallel)
})
options(mizer_info_level = 0)
f <- "models/v1/sensitivity/s_egg_100.rds"
if (!file.exists(f)) stop("Run R/05_sensitivity.R first (it caches ", f, ")")
p <- readParams(f)
base_ssb <- getSSB(p)[["Cod"]]
base_forage <- sum(getBiomass(p)[FORAGE])
eh <- read_effort_history()
mor <- moratorium_effort(eh)
h <- run_scenario(p, eh, years = c(1970, 2025), return_sim = TRUE)

grid <- expand.grid(F_forage = c(0.1, 0.25, 0.5, 1, 2), D = c(5, 10, 20, 40))
grid <- grid[!(grid$F_forage == 0.1 & grid$D != 5), ]
res <- mclapply(seq_len(nrow(grid)), function(i) {
    Ff <- grid$F_forage[i]; D <- grid$D[i]
    eff <- data.frame(year = c(2026, 2026 + D), cod = mor[["cod"]],
                      groundfish = mor[["groundfish"]], pelagic = c(Ff, mor[["pelagic"]]))
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
write.csv(met, "results/v1/forage_fishing_grid_s100.csv", row.names = FALSE)
print(met)
traj <- bind_rows(lapply(res, `[[`, "df"))
write.csv(traj |> filter(species %in% c("Cod", FORAGE)),
          "results/v1/forage_fishing_trajectories_s100.csv", row.names = FALSE)

pA <- traj |> filter(species == "Cod", D == 10 | F_forage == 0.1) |>
    ggplot(aes(year, ssb / base_ssb, colour = F_forage, group = F_forage)) +
    geom_line(linewidth = 0.7) + scale_y_log10() +
    scale_colour_viridis_c(option = "plasma", end = 0.9, trans = "log10") +
    geom_hline(yintercept = 0.5, linetype = "dotted") +
    annotate("rect", xmin = 2026, xmax = 2036, ymin = 0, ymax = Inf, alpha = 0.1) +
    labs(x = NULL, y = "Cod SSB relative to baseline", colour = expression(F[forage]),
         title = "a  Variant s_egg = 100: 10-yr programmes") + theme_paper()
pB <- met |> filter(F_forage > 0.1) |>
    ggplot(aes(factor(F_forage), factor(D), fill = years_to_50pct)) + geom_tile(colour = "white") +
    geom_text(aes(label = ifelse(is.na(years_to_50pct), "none", years_to_50pct)), size = 3) +
    scale_fill_viridis_c(direction = -1, na.value = "grey85") +
    labs(x = expression("Forage-fish F during programme (yr"^-1*")"), y = "Duration D (years)",
         fill = "Years to\n50% SSB", title = sprintf("b  Years to 50%% SSB (status quo %s)", sq)) +
    theme_paper()
save_fig(pA | pB, "fig4b_forage_fishing_strong_variant", width = 11, height = 4.5)
cat("04b_forage_fishing_strong_variant.R done\n")
