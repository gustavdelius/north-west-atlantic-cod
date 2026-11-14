# run_all.R -- reproduce every v3 (main model) result and figure from the
# repository root:   Rscript R/run_all.R
# v1 and v2 (kept for reference) are reproduced with Rscript R/v1/run_all.R
# and Rscript R/v2/run_all.R.
# 00_fishbase_lookup.R needs internet access and only refreshes the cached
# FishBase extracts in data/fishbase/; it is not needed to reproduce results.
# Calibrations are cached in models/ (calibration_stage1.rds = the v2 build
# at s = 1; calibration_cache.rds = the v3 recalibration; sensitivity/*.rds)
# and the forage-level fit in results/hindcast_calibration.csv. Delete them,
# or set REBUILD=1 for 01, to recalibrate from scratch (stage 1 takes ~1 h;
# the v3 recalibration ~1 min; each s variant in 05 ~1-3 min).
scripts <- c("R/01_build_model.R", "R/02_collapse_moratorium.R", "R/03_bistability.R",
             "R/04_forage_fishing_recovery.R", "R/04b_forage_fishing_from_alternative_state.R",
             "R/04c_observed_like_start.R",
             "R/05_sensitivity.R",
             "R/06_numerical_checks.R", "R/07_adult_mortality_alternative.R")
if (file.exists("R/08_policy_grid.R")) scripts <- c(scripts, "R/08_policy_grid.R")
for (s in scripts) {
    cat("\n==========", s, "==========\n")
    t0 <- Sys.time()
    status <- system2("Rscript", s)
    cat(sprintf("%s finished with status %d in %.1f min\n", s, status,
                as.numeric(difftime(Sys.time(), t0, units = "mins"))))
    if (status != 0) stop("Script failed: ", s)
}
cat("run_all.R completed\n")
