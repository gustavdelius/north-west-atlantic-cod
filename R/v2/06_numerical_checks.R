# 06_numerical_checks.R  (v2)
# ---------------------------------------------------------------------------
# Numerical robustness of the key v2 results: the cod-forced calibration
# hindcast (forage boom), the real moratorium from the observed-like 2000
# state (run B), and the cod invasion rate at F = 0, recomputed with
#   (a) dt = 0.025 instead of 0.1, (b) TR-BDF2 time stepping, and
#   (c) a 200-bin size grid (model rebuilt and recalibrated with no_w = 200;
#       cached in models/sensitivity/fine_grid_no_w200.rds).
# Outputs: results/numerical_checks.csv, results/numerical_checks_traj.csv,
#          figures/figS1_numerical_checks.(png|pdf)
# ---------------------------------------------------------------------------
source("R/v2/functions.R")
suppressPackageStartupMessages({ library(ggplot2); library(dplyr); library(parallel) })
options(mizer_info_level = 0)
params <- readParams("models/v2/baseline_params.rds")
eh <- read_effort_history()
ehf <- read_effort_history(file.path(DATA_DIR, "effort_history_codforced.csv"))
mor <- moratorium_effort(eh)
e0 <- mor; e0["cod"] <- 0

ffine <- "models/v2/sensitivity/fine_grid_no_w200.rds"
if (!file.exists(ffine)) {
    cfg <- default_config(); cfg$no_w <- 200
    saveParams(build_model(cfg, verbose = FALSE), ffine)
}
pfine <- readParams(ffine)
# same reproduction levels as the main model (incl. the calibrated forage level)
reproduction_level(pfine) <- reproduction_level(params)

key_run <- function(p, dt, method) {
    hf <- run_scenario(p, ehf, years = c(1970, 2004), dt = dt, method = method, return_sim = TRUE)
    p2000 <- getParams(hf$sim, time_range = 2000)
    dB <- run_scenario(p, mor, years = c(2000, 2150), initial = p2000, dt = dt, method = method)
    pf <- p; n <- initialN(pf); n["Cod", ] <- 0; initialN(pf) <- n
    C <- equilibrate(pf, e0, t_max = 400, t_check = 25, tol = 5e-4, floor = 1e-14, dt = dt)
    pc <- C$params; n <- initialN(pc); n["Cod", ] <- initialN(p)["Cod", ] * 1e-6; initialN(pc) <- n
    e <- initial_effort(p); e[names(e0)] <- e0
    inv <- project(pc, effort = e, t_max = 150, dt = dt, method = method, progress_bar = FALSE)
    base_ssb <- getSSB(p)[["Cod"]]
    cod <- dB[dB$species == "Cod", ]
    rec <- cod$year[cod$ssb >= 0.5 * base_ssb]
    list(df = bind_rows(mutate(hf$data, run = "calibration"), mutate(dB, run = "B")),
         m = data.frame(no_w = length(w(p)), dt = dt, method = method,
                        max_biomass_error = max(abs(biomass_error(p))),
                        forage_ratio_1995_2004 = period_ratio(hf$data, FORAGE),
                        cod_survival_1mg_1g_boom = prerecruit_budget(p2000, "Cod", 0.001, 1)$survival[1],
                        B_years_to_50pct_from_1993 = if (length(rec)) min(rec) - 1993 else NA,
                        B_cod_ssb_2025_rel = cod$ssb[cod$year == 2025] / base_ssb,
                        invasion_rate = invasion_rate(inv, getBiomass(p)[["Cod"]])))
}
cases <- list(reference = list(p = params, dt = 0.1, method = "euler"),
              dt_0.025 = list(p = params, dt = 0.025, method = "euler"),
              tr_bdf2 = list(p = params, dt = 0.1, method = "tr_bdf2"),
              no_w_200 = list(p = pfine, dt = 0.1, method = "euler"))
runs <- mclapply(cases, function(cc) key_run(cc$p, cc$dt, cc$method), mc.cores = 4)
out <- bind_rows(lapply(names(runs), function(n) cbind(case = n, runs[[n]]$m)))
write.csv(out, "results/v2/numerical_checks.csv", row.names = FALSE)
print(out)
traj <- bind_rows(lapply(names(runs), function(n) {
    p <- cases[[n]]$p
    runs[[n]]$df |> filter(species == "Cod") |> mutate(case = n, ssb_rel = ssb / getSSB(p)[["Cod"]])
}))
write.csv(traj, "results/v2/numerical_checks_traj.csv", row.names = FALSE)
pS <- ggplot(traj, aes(year, ssb_rel, colour = case, linetype = run)) + geom_line(linewidth = 0.7) +
    scale_y_log10() + geom_vline(xintercept = 1993.7, linetype = "dotted") +
    scale_colour_manual(values = c(reference = "#000000", dt_0.025 = "#0072B2",
                                   tr_bdf2 = "#009E73", no_w_200 = "#D55E00")) +
    labs(x = NULL, y = "Cod SSB relative to baseline", colour = NULL, linetype = NULL,
         title = "Numerical robustness: calibration hindcast and moratorium from 2000") + theme_paper()
save_fig(pS, "figS1_numerical_checks", width = 8, height = 4.5)
cat("06_numerical_checks.R done\n")
