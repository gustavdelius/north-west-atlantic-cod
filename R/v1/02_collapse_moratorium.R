# 02_collapse_moratorium.R
# ---------------------------------------------------------------------------
# Acceptance test 2: from the 1980-85 baseline, apply the historical effort
# trajectory (data/effort_history.csv) 1970-2025, then continue the 2025
# moratorium efforts to 2125 to see whether and when cod recovers.
#
# Outputs
#   results/hindcast.csv           tidy yearly output 1970-2125, two variants:
#                                  "bycatch" (cod F = 0.02 from 1994) and
#                                  "zero_bycatch" (cod F = 0 from 1994)
#   results/hindcast_metrics.csv   collapse depth, forage increase, recovery time
#   results/hindcast_early_life.csv forage-fish kill of cod eggs/larvae by year
#   results/observed_cod_ssb.csv   survey SSB (Fanning et al. 2003) used in Fig. 2
#   models/collapsed_2025_params.rds  model state at the end of 2025 (saveParams)
#   figures/fig2_collapse_moratorium.(png|pdf)
# ---------------------------------------------------------------------------
source("R/v1/functions.R")
suppressPackageStartupMessages({
    library(ggplot2); library(patchwork); library(dplyr); library(tidyr)
})
options(mizer_info_level = 0)
params <- readParams("models/v1/baseline_params.rds")
base_ssb <- getSSB(params)[["Cod"]]
base_B <- getBiomass(params)
base_forage <- sum(base_B[FORAGE])

eh <- read_effort_history()
mor <- moratorium_effort(eh)
run_variant <- function(eh, label) {
    h <- run_scenario(params, eh, years = c(1970, 2025), return_sim = TRUE)
    ext <- eh[nrow(eh), ]
    ext$year <- 2025
    e2 <- run_scenario(params, ext, years = c(2025, 2125), initial = h$sim, return_sim = TRUE)
    df <- bind_rows(h$data, filter(e2$data, year > 2025)) |> mutate(variant = label)
    list(df = df, sim = h$sim, sim2 = e2$sim)
}
v1 <- run_variant(eh, "bycatch")
eh0 <- eh; eh0$cod[eh0$year >= 1994] <- 0
v0 <- run_variant(eh0, "zero_bycatch")
hind <- bind_rows(v1$df, v0$df)
write.csv(hind, "results/v1/hindcast.csv", row.names = FALSE)

saveParams(setMetadata(finalParams(v1$sim),
                       title = "4VsW model: state at end of 2025 after historical fishing",
                       description = "Same parameters as models/baseline_params.rds; state after the 1970-2025 hindcast (cod bycatch F = 0.02 from 1994)."),
           "models/v1/collapsed_2025_params.rds")

met <- bind_rows(
    cbind(variant = "bycatch", recovery_metrics(v1$df, base_ssb, base_forage)),
    cbind(variant = "zero_bycatch", recovery_metrics(v0$df, base_ssb, base_forage)))
# modelled vs observed decline: SSB 2000-02 relative to 1980-85
obs <- read.csv("literature/data/cod_4VsW_assessment.csv", comment.char = "#")
obs_rel <- obs |> mutate(ssb_rel = SSB_t / mean(SSB_t[year %in% 1980:1985]))
write.csv(obs_rel[, c("year", "SSB_t", "ssb_rel")], "results/v1/observed_cod_ssb.csv", row.names = FALSE)
mod_rel <- hind |> filter(species == "Cod", variant == "bycatch") |>
    mutate(ssb_rel = ssb / mean(ssb[year %in% 1980:1985]))
met$obs_ssb_2000_02_rel_1980_85 <- mean(obs_rel$ssb_rel[obs_rel$year %in% 2000:2002])
met$model_ssb_2000_02_rel_1980_85 <- c(
    mean(mod_rel$ssb_rel[mod_rel$year %in% 2000:2002]),
    with(hind |> filter(species == "Cod", variant == "zero_bycatch"),
         mean(ssb[year %in% 2000:2002]) / mean(ssb[year %in% 1980:1985])))
met$model_yield_1980_85_kt <- gm2_to_kt(mean(hind$yield[hind$species == "Cod" &
                                                      hind$variant == "bycatch" &
                                                      hind$year %in% 1980:1985]))
met$obs_landings_1980_85_kt <- 53.5
write.csv(met, "results/v1/hindcast_metrics.csv", row.names = FALSE)
print(met)

# forage-fish kill of cod eggs/larvae through time (bycatch variant)
yrs <- c(1975, 1985, 1990, 1993, 1995, 2000, 2005, 2010, 2015, 2025)
early <- lapply(yrs, function(y) {
    p <- getParams(v1$sim, time_range = y)
    k <- cod_early_forage_kill(p)
    data.frame(year = y, forage_kill_integral = k[["integral"]],
               forage_kill_fraction = k[["fraction"]],
               cod_larval_feeding_level = getFeedingLevel(p)["Cod", which.min(abs(w(p) - 0.01))])
}) |> bind_rows()
write.csv(early, "results/v1/hindcast_early_life.csv", row.names = FALSE)
print(early)

# --- Figure 2 -----------------------------------------------------------------
eff_long <- effort_array(eh, gears = GEARS, years = c(1970, 2025)) |>
    as.data.frame() |> mutate(year = 1970:2025) |>
    pivot_longer(-year, names_to = "gear", values_to = "effort")
pA <- ggplot(eff_long, aes(year, effort, colour = gear)) + geom_step(linewidth = 0.8) +
    geom_vline(xintercept = 1993.7, linetype = "dotted") +
    scale_colour_manual(values = c(cod = "#000000", groundfish = "#E69F00", pelagic = "#D55E00")) +
    labs(x = NULL, y = expression("Fishing mortality (yr"^-1*")"), colour = "Gear",
         title = "a  Fishing effort (= F on fully selected sizes)") + theme_paper()
pB <- ggplot() +
    geom_line(data = filter(hind, species == "Cod", year <= 2060) |>
                  group_by(variant) |> mutate(ssb_rel = ssb / base_ssb),
              aes(year, ssb_rel, linetype = variant), linewidth = 0.8) +
    geom_point(data = obs_rel, aes(year, ssb_rel / mean(mod_rel$ssb_rel[mod_rel$year %in% 1980:1985])),
               colour = "#0072B2", size = 1.5) +
    geom_vline(xintercept = 1993.7, linetype = "dotted") +
    scale_y_log10() +
    scale_linetype_manual(values = c(bycatch = "solid", zero_bycatch = "dashed"),
                          labels = c(bycatch = "model, bycatch F = 0.02", zero_bycatch = "model, F = 0")) +
    labs(x = NULL, y = "Cod SSB relative to baseline", linetype = NULL,
         title = "b  Cod SSB: model (lines) and survey (points)") +
    theme_paper() + theme(legend.position = "bottom")
grp <- hind |> filter(variant == "bycatch", year <= 2060, species != "Resource") |>
    mutate(group = ifelse(species %in% FORAGE, "Forage fish", ifelse(species == "Cod", "Cod", "Other groundfish"))) |>
    group_by(year, group) |> summarise(biomass = sum(biomass), .groups = "drop") |>
    group_by(group) |> mutate(rel = biomass / biomass[year == 1970])
pC <- ggplot(grp, aes(year, rel, colour = group)) + geom_line(linewidth = 0.8) +
    geom_vline(xintercept = 1993.7, linetype = "dotted") + scale_y_log10() +
    scale_colour_manual(values = c(Cod = "#000000", "Forage fish" = "#D55E00", "Other groundfish" = "#E69F00")) +
    labs(x = NULL, y = "Biomass relative to baseline", colour = NULL,
         title = "c  Community response (bycatch variant)") + theme_paper()
spx <- hind |> filter(variant == "bycatch", year <= 2060, species %in% c(FORAGE, "Haddock", "Silver hake", "American plaice")) |>
    group_by(species) |> mutate(rel = biomass / biomass[year == 1970])
pD <- ggplot(spx, aes(year, rel, colour = species)) + geom_line(linewidth = 0.7) +
    geom_vline(xintercept = 1993.7, linetype = "dotted") + scale_y_log10() +
    scale_colour_manual(values = SPECIES_COLOURS) +
    labs(x = NULL, y = "Biomass relative to baseline", colour = NULL,
         title = "d  Individual species") + theme_paper()
pE <- ggplot(early, aes(year, 100 * forage_kill_fraction)) + geom_line() + geom_point() +
    geom_vline(xintercept = 1993.7, linetype = "dotted") +
    labs(x = NULL, y = "% of cod eggs/larvae eaten\nby forage fish (1 mg-0.1 g)",
         title = "e  Forage-fish predation on cod early life") + theme_paper()
pF <- hind |> filter(variant == "bycatch", species == "Cod") |>
    ggplot(aes(year, gm2_to_kt(yield))) + geom_line() +
    geom_point(data = read.csv("literature/data/cod_4VsW_landings_1958_2002.csv", comment.char = "#") |>
                   filter(year >= 1970),
               aes(year, total_landings_t / 1000), colour = "#0072B2", size = 1.2) +
    coord_cartesian(xlim = c(1970, 2025)) +
    labs(x = NULL, y = "Cod yield (kt)", title = "f  Cod yield: model (line), landings (points)") +
    theme_paper()
fig2 <- (pA | pB) / (pC | pD) / (pE | pF)
save_fig(fig2, "fig2_collapse_moratorium", width = 11, height = 11)
cat("02_collapse_moratorium.R done\n")
