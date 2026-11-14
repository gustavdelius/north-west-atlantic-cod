# 06_numerical_checks.R  (v3)
# ---------------------------------------------------------------------------
# Numerical robustness of the key v3 results, recomputed with
#   (a) dt = 0.025 instead of 0.1, (b) TR-BDF2 time stepping, and
#   (c) a 200-bin size grid (model rebuilt from the calibrated parameters on
#       the finer grid and recalibrated to the same targets at the same s with
#       calibrate_v3n(); cached in models/sensitivity/no_w_200.rds).
# Key results: documented-F hindcast (run A: cod and forage ratios, cod 2025),
# run B (adult M 0.8 in 1990-2025) and the years to 50 % of baseline cod SSB
# after 2025, a 10-year forage-fishing programme (F 1.0) from that state, and
# the cod invasion rate at F = 0.
# Outputs: results/numerical_checks.csv, results/numerical_checks_traj.csv,
#          figures/figS1_numerical_checks.(png|pdf)
# ---------------------------------------------------------------------------
source("R/functions.R")
suppressPackageStartupMessages({ library(ggplot2); library(dplyr); library(parallel) })
options(mizer_info_level = 0)
params <- readParams("models/baseline_params.rds")
eh <- read_effort_history()
mor <- moratorium_effort(eh)
e0 <- mor; e0["cod"] <- 0
dir.create("models/sensitivity", showWarnings = FALSE, recursive = TRUE)

ffine <- "models/sensitivity/no_w_200.rds"
if (!file.exists(ffine)) saveParams(rebuild_on_grid(params, 200), ffine)
pfine <- readParams(ffine)
reproduction_level(pfine) <- reproduction_level(params)

key_run <- function(p, dt, method) {
    base_ssb <- getSSB(p)[["Cod"]]
    hA <- run_scenario(p, eh, years = c(1970, 2025), dt = dt, method = method)
    h1 <- run_scenario(p, eh[eh$year < 1990, ], years = c(1970, 1990), dt = dt, method = method, return_sim = TRUE)
    h2 <- run_scenario(elevate_M(p), eh[eh$year >= 1990, ], years = c(1990, 2025), initial = h1$sim,
                       dt = dt, method = method, return_sim = TRUE)
    rB <- run_scenario(p, mor, years = c(2025, 2125), initial = h2$sim, dt = dt, method = method)
    eff <- as.data.frame(rbind(mor, mor)); eff$year <- c(2025, 2035); eff$pelagic <- c(1.0, mor[["pelagic"]])
    rF <- run_scenario(p, eff, years = c(2025, 2125), initial = h2$sim, dt = dt, method = method)
    it <- invasion_test(p, e0, dt = dt, method = method)
    fit <- invasion_fit(it$inv, getBiomass(p)[["Cod"]])
    y50 <- function(d) { cod <- d[d$species == "Cod", ]; r <- cod$year[cod$ssb >= 0.5 * base_ssb]
        if (length(r)) min(r) - 2025 else NA }
    codA <- hA[hA$species == "Cod", ]
    list(df = bind_rows(mutate(hA, run = "A"), mutate(bind_rows(h2$data, rB), run = "B"),
                        mutate(rF, run = "B + forage F 1.0 for 10 yr")),
         m = data.frame(no_w = length(w(p)), dt = dt, method = method,
                        max_biomass_error = max(abs(biomass_error(p))),
                        A_cod_ratio_1995_2004 = period_ratio(hA, "Cod"),
                        A_forage_ratio_1995_2004 = period_ratio(hA, FORAGE),
                        A_cod_ssb_2025_rel = codA$ssb[codA$year == 2025] / base_ssb,
                        B_cod_ratio_1995_2004 = period_ratio(bind_rows(h1$data, h2$data), "Cod"),
                        B_years_to_50pct_after_2025 = y50(rB),
                        B_forage_F1_10yr_years_to_50pct = y50(rF),
                        invasion_rate = fit$rate, invasion_fit_r2 = fit$r2))
}
cases <- list(reference = list(p = params, dt = 0.1, method = "euler"),
              dt_0.025 = list(p = params, dt = 0.025, method = "euler"),
              tr_bdf2 = list(p = params, dt = 0.1, method = "tr_bdf2"),
              no_w_200 = list(p = pfine, dt = 0.1, method = "euler"))
runs <- mclapply(cases, function(cc) key_run(cc$p, cc$dt, cc$method), mc.cores = 4)
out <- bind_rows(lapply(names(runs), function(n) cbind(case = n, runs[[n]]$m)))
write.csv(out, "results/numerical_checks.csv", row.names = FALSE)
print(out)
traj <- bind_rows(lapply(names(runs), function(n) {
    p <- cases[[n]]$p
    runs[[n]]$df |> filter(species == "Cod") |> mutate(case = n, ssb_rel = ssb / getSSB(p)[["Cod"]])
}))
write.csv(traj, "results/numerical_checks_traj.csv", row.names = FALSE)
pS <- ggplot(traj, aes(year, ssb_rel, colour = case, linetype = run)) + geom_line(linewidth = 0.7) +
    scale_y_log10() + geom_vline(xintercept = 1993.7, linetype = "dotted") +
    scale_colour_manual(values = c(reference = "#000000", dt_0.025 = "#0072B2",
                                   tr_bdf2 = "#009E73", no_w_200 = "#D55E00")) +
    labs(x = NULL, y = "Cod SSB relative to baseline", colour = NULL, linetype = NULL,
         title = "Numerical robustness: hindcasts A and B and a forage-fishing programme") + theme_paper()
save_fig(pS, "figS1_numerical_checks", width = 9, height = 5)
cat("06_numerical_checks.R done\n")
