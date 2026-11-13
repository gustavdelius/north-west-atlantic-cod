# 07_adult_mortality_alternative.R
# ---------------------------------------------------------------------------
# Alternative hypothesis (Swain & Mohn 2012; Trzcinski et al. 2006; Mohn &
# Rowe 2012): cod failed to recover because natural mortality of adult cod
# rose to ~0.6-1.1 yr^-1 after 1990 (grey seals and unexplained causes), not
# because of recruitment failure.
#
# This is NOT one of the fishing-only scenarios of tests 2-4: it changes a
# parameter (external mortality of cod >= 35 cm) from 1990 onward. It is run
# to show how the forage-fishing result behaves under that alternative.
#   * 1970-1989: baseline model, historical effort.
#   * 1990 onward: external mortality of cod >= 35 cm raised so that its total
#     natural mortality (external + predation) is M_ADULT = 0.8 yr^-1
#     (mean ESS VPA M for ages 5+ 1990-2004 = 0.8; Mohn & Rowe 2012, as read
#     by the literature agent; literature/empirical_targets.md section 2d).
#   * 2026-2125: forage-fishing programmes as in 04, with M_ADULT kept at 0.8
#     ("seal regime persists") or reset to the baseline in 2026 ("M returns").
# Outputs: results/alt_adult_M.csv, results/alt_adult_M_metrics.csv,
#          figures/fig6_adult_mortality.(png|pdf)
# ---------------------------------------------------------------------------
source("R/v1/functions.R")
suppressPackageStartupMessages({
    library(ggplot2); library(patchwork); library(dplyr); library(parallel)
})
options(mizer_info_level = 0)
params <- readParams("models/v1/baseline_params.rds")
base_ssb <- getSSB(params)[["Cod"]]
base_forage <- sum(getBiomass(params)[FORAGE])
eh <- read_effort_history()
mor <- moratorium_effort(eh)
M_ADULT <- 0.8
L_ADULT <- 35   # cm

# parameters with elevated adult cod mortality
sp <- species_params(params)
w_adult <- sp["Cod", "a"] * L_ADULT^sp["Cod", "b"]
pm <- getPredMort(params)["Cod", ]
em <- ext_mort(params)
big <- w(params) >= w_adult
em["Cod", big] <- pmax(em["Cod", big], M_ADULT - pm[big])
params_M <- params
ext_mort(params_M) <- em          # direct setter: freezes this array (intended)

eh1 <- eh[eh$year < 1990, ]
eh2 <- eh[eh$year >= 1990, ]
h1 <- run_scenario(params, eh1, years = c(1970, 1990), return_sim = TRUE)
h2 <- run_scenario(params_M, eh2, years = c(1990, 2025), initial = h1$sim, return_sim = TRUE)
hind <- bind_rows(h1$data, filter(h2$data, year > 1990))

programmes <- expand.grid(F_forage = c(0.1, 0.5, 1.0, 2.0), D = c(10, 30, 100),
                          M_after_2025 = c("elevated", "baseline"), stringsAsFactors = FALSE)
programmes <- programmes[!(programmes$F_forage == 0.1 & programmes$D != 10), ]
runs <- mclapply(seq_len(nrow(programmes)), function(i) {
    pr <- programmes[i, ]
    pp <- if (pr$M_after_2025 == "elevated") params_M else params
    eff <- data.frame(year = c(2026, min(2026 + pr$D, 2125)), cod = mor[["cod"]],
                      groundfish = mor[["groundfish"]],
                      pelagic = c(pr$F_forage, if (pr$D >= 99) pr$F_forage else mor[["pelagic"]]))
    df <- run_scenario(pp, eff, years = c(2026, 2125), initial = h2$sim)
    cod <- df[df$species == "Cod", ]
    rec <- cod$year[cod$ssb >= 0.5 * base_ssb]
    list(df = mutate(df, F_forage = pr$F_forage, D = pr$D, M_after_2025 = pr$M_after_2025),
         m = data.frame(pr, years_to_50pct = if (length(rec)) min(rec) - 2026 else NA,
                        cod_ssb_2050_rel = cod$ssb[cod$year == 2050] / base_ssb,
                        cod_ssb_2125_rel = cod$ssb[cod$year == 2125] / base_ssb))
}, mc.cores = min(8, parallel::detectCores()))
met <- bind_rows(lapply(runs, `[[`, "m"))
alt <- bind_rows(mutate(hind, F_forage = NA, D = NA, M_after_2025 = "hindcast"),
                 bind_rows(lapply(runs, `[[`, "df")))
write.csv(alt, "results/v1/alt_adult_M.csv", row.names = FALSE)
hm <- recovery_metrics(hind, base_ssb, base_forage)
met$hindcast_ssb_2025_rel <- hm$ssb_2025_rel
met$hindcast_forage_max_rel <- hm$forage_max_rel_1993_2025
write.csv(met, "results/v1/alt_adult_M_metrics.csv", row.names = FALSE)
print(hm); print(met)

# compare with the main hindcast (fishing-only explanation)
main <- read.csv("results/v1/hindcast.csv") |> filter(variant == "bycatch", year <= 2025)
cmp <- bind_rows(mutate(filter(main, species == "Cod"), model = "main (M unchanged)"),
                 mutate(filter(hind, species == "Cod"), model = sprintf("adult M = %.1f from 1990", M_ADULT)))
obs <- read.csv("results/v1/observed_cod_ssb.csv")
pA <- ggplot(cmp, aes(year, ssb / base_ssb, colour = model)) + geom_line(linewidth = 0.8) +
    geom_point(data = obs, aes(year, ssb_rel), inherit.aes = FALSE, colour = "#0072B2", size = 1.3) +
    scale_y_log10() + geom_vline(xintercept = 1993.7, linetype = "dotted") +
    scale_colour_manual(values = c("#000000", "#CC79A7")) +
    labs(x = NULL, y = "Cod SSB relative to baseline", colour = NULL,
         title = "a  Hindcast with and without elevated adult M (points: survey)") +
    theme_paper() + theme(legend.position = c(0.3, 0.2))
sel <- alt |> filter(species == "Cod", M_after_2025 != "hindcast", D %in% c(10, 100))
pB <- ggplot(sel, aes(year, ssb / base_ssb, colour = factor(F_forage),
                      linetype = factor(D))) + geom_line() + scale_y_log10() +
    facet_wrap(~ M_after_2025, labeller = labeller(M_after_2025 = c(
        elevated = "adult M stays at 0.8", baseline = "adult M returns to baseline in 2026"))) +
    scale_colour_viridis_d(option = "plasma", end = 0.85) +
    labs(x = NULL, y = "Cod SSB relative to baseline", colour = expression(F[forage]),
         linetype = "Duration (yr)", title = "b  Forage fishing from 2026 under the alternative") +
    theme_paper()
save_fig(pA / pB, "fig6_adult_mortality", width = 10, height = 8)
cat("07_adult_mortality_alternative.R done\n")
