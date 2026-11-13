# 07_adult_mortality_alternative.R  (v2)
# ---------------------------------------------------------------------------
# Alternative / complementary hypothesis: natural mortality of adult cod rose
# to ~0.8 /yr after 1990 (grey seals and unexplained causes; Swain & Mohn 2012,
# Mohn & Rowe 2012). This changes a parameter over time and is therefore not
# one of the fishing-only scenarios.
#  (1) Factorial hindcast 1970-2060 with the real moratorium efforts:
#      adult M {baseline, 0.8 from 1990} x forage predation on cod {on, off}
#      x plankton depletion {on, off} (the "off" switches act from 1990 and
#      are diagnostics). This apportions the cod decline / non-recovery and
#      the forage boom between the seal and forage mechanisms.
#  (2) Forage-fishing programmes from 2026 under elevated adult M, with M
#      kept at 0.8 or returned to baseline in 2026.
# Outputs: results/alt_adult_M_factorial.csv, results/alt_adult_M_factorial_traj.csv,
#          results/alt_adult_M_forage_fishing.csv, figures/fig6_adult_mortality.*
# ---------------------------------------------------------------------------
source("R/v2/functions.R")
suppressPackageStartupMessages({ library(ggplot2); library(patchwork); library(dplyr); library(parallel) })
options(mizer_info_level = 0)
params <- readParams("models/v2/baseline_params.rds")
base_ssb <- getSSB(params)[["Cod"]]
base_forage <- sum(getBiomass(params)[FORAGE])
eh <- read_effort_history()
mor <- moratorium_effort(eh)
M_ADULT <- 0.8; L_ADULT <- 35

elevate_M <- function(p) {
    sp <- species_params(p)
    w_adult <- sp["Cod", "a"] * L_ADULT^sp["Cod", "b"]
    pm <- getPredMort(p)["Cod", ]
    em <- ext_mort(p)
    big <- w(p) >= w_adult
    em["Cod", big] <- pmax(em["Cod", big], M_ADULT - pm[big])
    ext_mort(p) <- em
    p
}
no_forage_pred <- function(p) { im <- interaction_matrix(p); im[FORAGE, "Cod"] <- 0
    interaction_matrix(p) <- im; p }
no_depletion <- function(p) setResource(p, resource_dynamics = "resource_constant")

combos <- expand.grid(M = c("baseline", "elevated"), forage_pred = c("on", "off"),
                      depletion = c("on", "off"), stringsAsFactors = FALSE)
eh1 <- eh[eh$year < 1990, ]; eh2 <- eh[eh$year >= 1990, ]
runs <- mclapply(seq_len(nrow(combos)), function(i) {
    cc <- combos[i, ]
    h1 <- run_scenario(params, eh1, years = c(1970, 1990), return_sim = TRUE)
    p2 <- params
    if (cc$M == "elevated") p2 <- elevate_M(p2)
    if (cc$forage_pred == "off") p2 <- no_forage_pred(p2)
    if (cc$depletion == "off") p2 <- no_depletion(p2)
    h2 <- run_scenario(p2, eh2, years = c(1990, 2025), initial = h1$sim, return_sim = TRUE)
    h3 <- run_scenario(p2, mor, years = c(2025, 2060), initial = h2$sim)
    df <- bind_rows(h1$data, filter(h2$data, year > 1990), filter(h3, year > 2025))
    m <- recovery_metrics(df, base_ssb, base_forage)
    cod <- df[df$species == "Cod", ]
    list(df = cbind(df, cc),
         m = cbind(cc, data.frame(
             cod_ssb_2000_02_rel_1980_85 = mean(cod$ssb[cod$year %in% 2000:2002]) /
                 mean(cod$ssb[cod$year %in% 1980:1985]),
             cod_survey_ratio_1995_2004 = period_ratio(df, "Cod"),
             forage_ratio_1995_2004 = period_ratio(df, FORAGE),
             forage_ratio_2005_2012 = period_ratio(df, FORAGE, num = 2005:2012),
             cod_ssb_2025_rel = m$ssb_2025_rel,
             cod_ssb_2060_rel = cod$ssb[cod$year == 2060] / base_ssb,
             years_to_50pct_from_1993 = m$years_to_recover50)))
}, mc.cores = min(8, detectCores()))
fac <- bind_rows(lapply(runs, `[[`, "m"))
write.csv(fac, "results/v2/alt_adult_M_factorial.csv", row.names = FALSE)
print(fac)
traj <- bind_rows(lapply(runs, `[[`, "df")) |> filter(species %in% c("Cod", FORAGE))
write.csv(traj, "results/v2/alt_adult_M_factorial_traj.csv", row.names = FALSE)

# (2) forage fishing under elevated M ------------------------------------------------
pM <- elevate_M(params)
h1 <- run_scenario(params, eh1, years = c(1970, 1990), return_sim = TRUE)
h2 <- run_scenario(pM, eh2, years = c(1990, 2025), initial = h1$sim, return_sim = TRUE)
prog <- expand.grid(F_forage = c(0.1, 0.5, 1, 2), D = c(10, 30),
                    M_after_2025 = c("elevated", "baseline"), stringsAsFactors = FALSE)
prog <- prog[!(prog$F_forage == 0.1 & prog$D != 10), ]
ff <- mclapply(seq_len(nrow(prog)), function(i) {
    pr <- prog[i, ]
    pp <- if (pr$M_after_2025 == "elevated") pM else params
    eff <- as.data.frame(rbind(mor, mor)); eff$year <- c(2026, 2026 + pr$D)
    eff$pelagic <- c(pr$F_forage, mor[["pelagic"]])
    df <- run_scenario(pp, eff, years = c(2026, 2125), initial = h2$sim)
    cod <- df[df$species == "Cod", ]
    rec <- cod$year[cod$ssb >= 0.5 * base_ssb]
    data.frame(pr, years_to_50pct = if (length(rec)) min(rec) - 2026 else NA,
               cod_ssb_2050_rel = cod$ssb[cod$year == 2050] / base_ssb,
               cod_ssb_2125_rel = cod$ssb[cod$year == 2125] / base_ssb)
}, mc.cores = min(8, detectCores()))
ffd <- bind_rows(ff)
write.csv(ffd, "results/v2/alt_adult_M_forage_fishing.csv", row.names = FALSE)
print(ffd)

# --- Figure 6 -------------------------------------------------------------------
obs <- read.csv("results/v2/observed_cod_ssb.csv")
tc <- traj |> filter(species == "Cod") |>
    mutate(label = paste0("M ", M, ", forage pred. ", forage_pred, ", depletion ", depletion))
pA <- ggplot(tc, aes(year, ssb / base_ssb, colour = M, linetype = interaction(forage_pred, depletion))) +
    geom_line(linewidth = 0.7) +
    geom_point(data = obs, aes(year, ssb_rel), inherit.aes = FALSE, colour = "#0072B2", size = 1.2) +
    scale_y_log10() + geom_vline(xintercept = 1993.7, linetype = "dotted") +
    scale_colour_manual(values = c(baseline = "#000000", elevated = "#CC79A7"), name = "Adult M") +
    labs(x = NULL, y = "Cod SSB / baseline", linetype = "forage pred. . depletion",
         title = "a  Factorial hindcast (points: survey SSB / 1980-85)") + theme_paper()
tf <- traj |> filter(species %in% FORAGE) |> group_by(year, M, forage_pred, depletion) |>
    summarise(b = sum(biomass), .groups = "drop")
pB <- ggplot(tf, aes(year, b / base_forage, colour = M, linetype = interaction(forage_pred, depletion))) +
    geom_line(linewidth = 0.7) + scale_y_log10() +
    scale_colour_manual(values = c(baseline = "#000000", elevated = "#CC79A7"), guide = "none") +
    labs(x = NULL, y = "Forage biomass / baseline", linetype = NULL, title = "b  Forage fish") + theme_paper()
pC <- ggplot(ffd, aes(F_forage, ifelse(is.na(years_to_50pct), 100, years_to_50pct),
                      colour = M_after_2025, shape = factor(D))) + geom_point(size = 2.5) + geom_line() +
    labs(x = "Forage F from 2026", y = "Years from 2026 to 50 % SSB (100 = not within 100 yr)",
         colour = "Adult M after 2025", shape = "Duration", title = "c  Forage fishing under elevated adult M") +
    theme_paper()
save_fig(pA / (pB | pC), "fig6_adult_mortality", width = 12, height = 10)
cat("07_adult_mortality_alternative.R done\n")
