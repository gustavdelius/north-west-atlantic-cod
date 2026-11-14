# 04c_observed_like_start.R  (v3)
# ---------------------------------------------------------------------------
# Conditional test: IF the community had reached the observed post-collapse
# composition, would s = 20 hold cod down? The model does not produce that
# community from documented fishing (02), so it is imposed as an initial
# state: the 1980-85 baseline spectra scaled by the survey ratios
# 1995-2004 / 1980-89 (cod 0.10, haddock 0.61, silver hake 0.60, plaice 0.45,
# each forage species x7.87); cod also at 0.04 (survey SSB in 1997-2002 was
# ~0.04 of 1980-85) and 0.01. Baseline
# parameters and moratorium efforts (cod F 0.02); only the initial state
# differs. Compared with the same start under s = 1 (diagnostic), and with
# forage-fishing programmes (F 0.5 and 1.0 for 10 years).
# Outputs: results/observed_like_start.csv, results/observed_like_start_traj.csv,
#          figures/fig4c_observed_like_start.(png|pdf)
# ---------------------------------------------------------------------------
source("R/functions.R")
suppressPackageStartupMessages({ library(ggplot2); library(dplyr); library(parallel) })
options(mizer_info_level = 0)
params <- readParams("models/baseline_params.rds")
base_ssb <- getSSB(params)[["Cod"]]
base_forage <- sum(getBiomass(params)[FORAGE])
mor <- moratorium_effort()
END <- 150

start_state <- function(cod_factor) {
    fac <- c(Cod = cod_factor, Haddock = 0.61, `Silver hake` = 0.60, `American plaice` = 0.45,
             Herring = 7.87, `Sand lance` = 7.87, Capelin = 7.87)
    p <- params; n <- initialN(p)
    for (sp in names(fac)) n[sp, ] <- n[sp, ] * fac[[sp]]
    initialN(p) <- n
    p
}
cases <- expand.grid(cod_start = c(0.10, 0.04, 0.01), s = c("20 (main)", "1 (diagnostic)"),
                     F_forage = c(0.1, 0.5, 1.0), stringsAsFactors = FALSE)
cases <- cases[!(cases$s != "20 (main)" & cases$F_forage != 0.1), ]
runs <- mclapply(seq_len(nrow(cases)), function(i) {
    cc <- cases[i, ]
    p <- if (cc$s == "20 (main)") params else s_off(params)
    eff <- as.data.frame(rbind(mor, mor)); eff$year <- c(0, 10); eff$pelagic <- c(cc$F_forage, mor[["pelagic"]])
    df <- run_scenario(p, eff, years = c(0, END), initial = start_state(cc$cod_start))
    cod <- df[df$species == "Cod", ]
    rec <- cod$year[cod$ssb >= 0.5 * base_ssb]
    fb <- aggregate(biomass ~ year, data = df[df$species %in% FORAGE, ], sum)
    list(df = cbind(df, cc),
         m = cbind(cc, data.frame(years_to_50pct = if (length(rec)) min(rec) else NA,
                                  persistent_recovery = all(cod$ssb[cod$year > END - 30] >= 0.5 * base_ssb),
                                  cod_ssb_min_rel = min(cod$ssb) / base_ssb,
                                  cod_ssb_end_rel = cod$ssb[cod$year == END] / base_ssb,
                                  forage_rel_year10 = fb$biomass[fb$year == 10] / base_forage)))
}, mc.cores = min(8, detectCores()))
m <- bind_rows(lapply(runs, `[[`, "m"))
write.csv(m, "results/observed_like_start.csv", row.names = FALSE)
print(m)
traj <- bind_rows(lapply(runs, `[[`, "df")) |> filter(species %in% c("Cod", FORAGE))
write.csv(traj, "results/observed_like_start_traj.csv", row.names = FALSE)
pl <- traj |> filter(species == "Cod") |>
    mutate(case = sprintf("cod start %.2f, s %s, forage F %.1f (10 yr)", cod_start, s, F_forage)) |>
    ggplot(aes(year, ssb / base_ssb, colour = case)) + geom_line(linewidth = 0.7) + scale_y_log10() +
    geom_hline(yintercept = 0.5, linetype = "dotted") +
    scale_colour_viridis_d(end = 0.9) +
    labs(x = "Years from the imposed observed-like state", y = "Cod SSB relative to baseline", colour = NULL,
         title = "Cod from an imposed observed-like post-collapse community (forage x7.9)") +
    theme_paper() + theme(legend.position = "right")
save_fig(pl, "fig4c_observed_like_start", width = 11, height = 5)
cat("04c_observed_like_start.R done\n")
