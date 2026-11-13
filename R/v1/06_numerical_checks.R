# 06_numerical_checks.R
# ---------------------------------------------------------------------------
# Numerical robustness of the key scenario (1970-2025 hindcast followed by
# 100 years at moratorium efforts): rerun with
#   (a) a 4x smaller time step (dt = 0.025 instead of 0.1),
#   (b) the second-order TR-BDF2 time stepper,
#   (c) a finer size grid (no_w = 200 instead of 120; model rebuilt and
#       recalibrated to the same targets on that grid),
# and compare the conclusions (collapse depth, forage increase, recovery
# time, cod invasion rate at F = 0).
# Outputs: results/numerical_checks.csv, results/numerical_checks_traj.csv,
#          models/sensitivity/fine_grid_no_w200.rds,
#          figures/figS1_numerical_checks.(png|pdf)
# ---------------------------------------------------------------------------
source("R/v1/functions.R")
suppressPackageStartupMessages({
    library(ggplot2); library(dplyr); library(parallel)
})
options(mizer_info_level = 0)
dir.create("models/v1/sensitivity", showWarnings = FALSE, recursive = TRUE)
params <- readParams("models/v1/baseline_params.rds")
eh <- read_effort_history()
mor <- moratorium_effort(eh)
e0 <- c(cod = 0, groundfish = mor[["groundfish"]], pelagic = mor[["pelagic"]])

ffine <- "models/v1/sensitivity/fine_grid_no_w200.rds"
if (file.exists(ffine)) {
    pfine <- readParams(ffine)
} else {
    cfg <- default_config(); cfg$no_w <- 200
    pfine <- build_model(cfg, verbose = FALSE)
    saveParams(pfine, ffine)
}

key_run <- function(p, dt = 0.1, method = "euler") {
    h <- run_scenario(p, eh, years = c(1970, 2025), dt = dt, method = method, return_sim = TRUE)
    ext <- eh[nrow(eh), ]; ext$year <- 2025
    h2 <- run_scenario(p, ext, years = c(2025, 2125), initial = h$sim, dt = dt, method = method)
    df <- bind_rows(h$data, filter(h2, year > 2025))
    # invasion rate of rare cod into the cod-free community at F = 0
    pf <- p; n <- initialN(pf); n["Cod", ] <- 0; initialN(pf) <- n
    C <- equilibrate(pf, e0, t_max = 400, t_check = 25, tol = 5e-4, floor = 1e-14, dt = dt)
    pc <- C$params; n <- initialN(pc); n["Cod", ] <- initialN(p)["Cod", ] * 1e-6; initialN(pc) <- n
    inv <- project(pc, effort = e0, t_max = 60, dt = dt, method = method, progress_bar = FALSE)
    list(df = df, lam = log_growth_rate(inv, years = 30))
}
cases <- list(
    reference = list(p = params, dt = 0.1, method = "euler"),
    dt_0.025 = list(p = params, dt = 0.025, method = "euler"),
    tr_bdf2 = list(p = params, dt = 0.1, method = "tr_bdf2"),
    no_w_200 = list(p = pfine, dt = 0.1, method = "euler"))
runs <- mclapply(cases, function(cc) key_run(cc$p, cc$dt, cc$method), mc.cores = 4)
out <- bind_rows(lapply(names(runs), function(n) {
    p <- cases[[n]]$p
    m <- recovery_metrics(runs[[n]]$df, getSSB(p)[["Cod"]], sum(getBiomass(p)[FORAGE]))
    cbind(case = n, no_w = length(w(p)), dt = cases[[n]]$dt, method = cases[[n]]$method,
          baseline_cod_ssb = getSSB(p)[["Cod"]], invasion_rate = runs[[n]]$lam, m)
}))
write.csv(out, "results/v1/numerical_checks.csv", row.names = FALSE)
print(out)
traj <- bind_rows(lapply(names(runs), function(n) {
    p <- cases[[n]]$p
    runs[[n]]$df |> filter(species %in% c("Cod", FORAGE)) |>
        mutate(case = n, ssb_rel = ssb / getSSB(p)[["Cod"]])
}))
write.csv(traj, "results/v1/numerical_checks_traj.csv", row.names = FALSE)
pS <- traj |> filter(species == "Cod") |>
    ggplot(aes(year, ssb_rel, colour = case, linetype = case)) + geom_line(linewidth = 0.7) +
    scale_y_log10() + geom_vline(xintercept = 1993.7, linetype = "dotted") +
    scale_colour_manual(values = c(reference = "#000000", dt_0.025 = "#0072B2",
                                   tr_bdf2 = "#009E73", no_w_200 = "#D55E00")) +
    labs(x = NULL, y = "Cod SSB relative to baseline", colour = NULL, linetype = NULL,
         title = "Numerical robustness of the hindcast + moratorium scenario") + theme_paper()
save_fig(pS, "figS1_numerical_checks", width = 8, height = 4.5)
cat("06_numerical_checks.R done\n")
