# run_all.R -- reproduce every result and figure from the repository root:
#   Rscript R/v1/run_all.R   (v1 = naive calibration, kept for reference)
# 00_fishbase_lookup.R needs internet access and only refreshes the cached
# FishBase extracts in data/fishbase/; it is not needed to reproduce results.
# Approximate run times on 8 cores: 01 ~30 min (calibration), 02 ~2 min,
# 03 ~10 min, 04 ~5 min, 05 ~60-90 min (recalibrates variants; cached in
# models/sensitivity/), 06 ~40 min (rebuilds the model on a finer grid),
# 04b ~3 min (needs the s_egg = 100 variant cached by 05), 07 ~3 min.
scripts <- c("R/v1/01_build_model.R", "R/v1/02_collapse_moratorium.R", "R/v1/03_bistability.R",
             "R/v1/04_forage_fishing_recovery.R", "R/v1/05_sensitivity.R",
             "R/v1/04b_forage_fishing_strong_variant.R", "R/v1/06_numerical_checks.R",
             "R/v1/07_adult_mortality_alternative.R")
for (s in scripts) {
    cat("\n==========", s, "==========\n")
    t0 <- Sys.time()
    status <- system2("Rscript", s)
    cat(sprintf("%s finished with status %d in %.1f min\n", s, status,
                as.numeric(difftime(Sys.time(), t0, units = "mins"))))
    if (status != 0) stop("Script failed: ", s)
}
