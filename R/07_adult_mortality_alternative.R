# 07_adult_mortality_alternative.R  (v3)
# ---------------------------------------------------------------------------
# Alternative / complementary hypothesis: natural mortality of adult cod
# (>= 35 cm) rose to ~0.8 /yr from 1990 (grey seals and unexplained causes;
# VPA M ages 5+ mean 0.8 for 1990-2004, Mohn & Rowe 2012; Trzcinski et al.
# 2006). This changes a parameter over time and is therefore an ALTERNATIVE
# scenario, not one of the fishing-only scenarios.
#  (1) 2x2 factorial hindcast 1970-2085 with the documented efforts:
#      adult M {baseline, 0.8 from 1990} x forage mechanism {on = main s,
#      off = s set to 1 (purely size-based) from 1990; a diagnostic}.
#      Apportions the cod collapse / non-recovery and the forage boom
#      between the two mechanisms.
#  (2) Forage-fishing programmes from 2026 when adult M stays at 0.8, and
#      when it returns to baseline in 2026.
# Outputs: results/alt_adult_M_factorial.csv, results/alt_adult_M_factorial_traj.csv,
#          results/alt_adult_M_forage_fishing.csv, figures/fig6_adult_mortality.*
# ---------------------------------------------------------------------------
source("R/functions.R")
suppressPackageStartupMessages({ library(ggplot2); library(patchwork); library(dplyr); library(parallel) })
options(mizer_info_level = 0)
params <- readParams("models/baseline_params.rds")
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
s_off <- function(p) { im <- interaction_matrix(p); im[FORAGE, GROUNDFISH] <- 1
    interaction_matrix(p) <- im; p }

combos <- expand.grid(M = c("baseline", "elevated"), forage_mechanism = c("on", "off"),
                      stringsAsFactors = FALSE)
eh1 <- eh[eh$year < 1990, ]; eh2 <- eh[eh$year >= 1990, ]
h1 <- run_scenario(params, eh1, years = c(1970, 1990), return_sim = TRUE)
runs <- mclapply(seq_len(nrow(combos)), function(i) {
    cc <- combos[i, ]
    p2 <- params
    if (cc$M == "elevated") p2 <- elevate_M(p2)
    if (cc$forage_mechanism == "off") p2 <- s_off(p2)
    h2 <- run_scenario(p2, eh2, years = c(1990, 2025), initial = h1$sim, return_sim = TRUE)
    h3 <- run_scenario(p2, mor, years = c(2025, 2085), initial = h2$sim)
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
             cod_ssb_2085_rel = cod$ssb[cod$year == 2085] / base_ssb,
             years_to_50pct_from_1993 = m$years_to_recover50)))
}, mc.cores = 4)
fac <- bind_rows(lapply(runs, `[[`, "m"))
write.csv(fac, "results/alt_adult_M_factorial.csv", row.names = FALSE)
print(fac)
traj <- bind_rows(lapply(runs, `[[`, "df")) |> filter(species %in% c("Cod", FORAGE))
write.csv(traj, "results/alt_adult_M_factorial_traj.csv", row.names = FALSE)

# (2) forage fishing under elevated M (forage mechanism on) ----------------------------
pM <- elevate_M(params)
h2 <- run_scenario(pM, eh2, years = c(1990, 2025), initial = h1$sim, return_sim = TRUE)
prog <- expand.grid(F_forage = c(0.1, 0.5, 1, 2), D = c(10, 30),
                    M_after_2025 = c("stays 0.8", "returns to baseline"), stringsAsFactors = FALSE)
prog <- prog[!(prog$F_forage == 0.1 & prog$D != 10), ]
ff <- mclapply(seq_len(nrow(prog)), function(i) {
    pr <- prog[i, ]
    pp <- if (pr$M_after_2025 == "stays 0.8") pM else params
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
write.csv(ffd, "results/alt_adult_M_forage_fishing.csv", row.names = FALSE)
print(ffd)

# --- Figure 6 -------------------------------------------------------------------
obs <- read.csv("results/observed_cod_ssb.csv")
tc <- traj |> filter(species == "Cod")
pA <- ggplot(tc, aes(year, ssb / base_ssb, colour = M, linetype = forage_mechanism)) +
    geom_line(linewidth = 0.7) +
    geom_point(data = obs, aes(year, ssb_rel), inherit.aes = FALSE, colour = "#0072B2", size = 1.2) +
    scale_y_log10() + geom_vline(xintercept = 1993.7, linetype = "dotted") +
    scale_colour_manual(values = c(baseline = "#000000", elevated = "#CC79A7"), name = "Adult M from 1990") +
    scale_linetype_manual(values = c(on = "solid", off = "dashed"), name = "Forage mechanism (s)") +
    labs(x = NULL, y = "Cod SSB / baseline",
         title = "a  2x2 factorial hindcast (points: survey SSB / 1980-85)") + theme_paper()
tf <- traj |> filter(species %in% FORAGE) |> group_by(year, M, forage_mechanism) |>
    summarise(b = sum(biomass), .groups = "drop")
pB <- ggplot(tf, aes(year, b / base_forage, colour = M, linetype = forage_mechanism)) +
    geom_line(linewidth = 0.7) + scale_y_log10() +
    scale_colour_manual(values = c(baseline = "#000000", elevated = "#CC79A7"), guide = "none") +
    scale_linetype_manual(values = c(on = "solid", off = "dashed"), guide = "none") +
    labs(x = NULL, y = "Forage biomass / baseline", title = "b  Forage fish") + theme_paper()
pC <- ggplot(ffd, aes(F_forage, ifelse(is.na(years_to_50pct), 100, years_to_50pct),
                      colour = M_after_2025, shape = factor(D))) + geom_point(size = 2.5) + geom_line() +
    scale_colour_manual(values = c("stays 0.8" = "#CC79A7", "returns to baseline" = "#000000")) +
    labs(x = "Forage F from 2026", y = "Years from 2026 to 50 % SSB (100 = not by 2125)",
         colour = "Adult M after 2025", shape = "Duration", title = "c  Forage fishing under elevated adult M") +
    theme_paper()
save_fig(pA / (pB | pC), "fig6_adult_mortality", width = 12, height = 10)
cat("07_adult_mortality_alternative.R done\n")
