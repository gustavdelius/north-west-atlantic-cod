# run_all.R -- reproduce every v2 (main model) result and figure from the
# repository root:   Rscript R/run_all.R
# v1 (the naive first calibration, kept for reference) is reproduced with
#   Rscript R/v1/run_all.R
# 00_fishbase_lookup.R needs internet access and only refreshes the cached
# FishBase extracts in data/fishbase/; it is not needed to reproduce results.
# Calibrations are cached in models/ (delete models/calibration_cache.rds,
# results/hindcast_calibration.csv and models/sensitivity/*.rds, or set the
# environment variable REBUILD=1, to recalibrate from scratch: ~1-2 h for 01,
# ~1 h for the 200-bin model in 06, ~1 h for the recalibrated variants in 05).
scripts <- c("R/v2/01_build_model.R", "R/v2/02_collapse_moratorium.R", "R/v2/03_bistability.R",
             "R/v2/04_forage_fishing_recovery.R", "R/v2/05_sensitivity.R",
             "R/v2/04b_forage_fishing_strong_variant.R",
             "R/v2/06_numerical_checks.R", "R/v2/07_adult_mortality_alternative.R")
for (s in scripts) {
    cat("\n==========", s, "==========\n")
    t0 <- Sys.time()
    status <- system2("Rscript", s)
    cat(sprintf("%s finished with status %d in %.1f min\n", s, status,
                as.numeric(difftime(Sys.time(), t0, units = "mins"))))
    if (status != 0) stop("Script failed: ", s)
}
