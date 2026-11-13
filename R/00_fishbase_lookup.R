# 00_fishbase_lookup.R
# ---------------------------------------------------------------------------
# Download life-history records from FishBase (via rfishbase) for the species
# in the eastern Scotian Shelf model and cache them as CSV in data/fishbase/.
#
# This is the only script that needs internet access. The model scripts
# (01_...) read the hand-assembled table data/species_params.csv, whose values
# were chosen with these records (and the literature) at hand; the cached CSVs
# document what FishBase offered. Re-running this script is optional.
# ---------------------------------------------------------------------------
suppressMessages({
    library(rfishbase)
    library(dplyr)
})

out_dir <- file.path("data", "fishbase")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

spp <- c(Cod = "Gadus morhua",
         Haddock = "Melanogrammus aeglefinus",
         `Silver hake` = "Merluccius bilinearis",
         `American plaice` = "Hippoglossoides platessoides",
         Herring = "Clupea harengus",
         `Sand lance` = "Ammodytes dubius",
         Capelin = "Mallotus villosus")

g <- popgrowth(spp) |>
    select(Species, Sex, Loo, Type, K, to, Winfinity, tmax, tm, M, Lm,
           Locality, YearStart, YearEnd, Temperature)
lw <- length_weight(spp) |>
    select(Species, Sex, LengthMin, LengthMax, Type, a, b,
           CoeffDetermination, Number, Locality)
mat <- maturity(spp) |>
    select(Species, Sex, AgeMatMin, AgeMatMin2, tm, Lm, LengthMatMin,
           Locality)

write.csv(g, file.path(out_dir, "popgrowth.csv"), row.names = FALSE)
write.csv(lw, file.path(out_dir, "length_weight.csv"), row.names = FALSE)
write.csv(mat, file.path(out_dir, "maturity.csv"), row.names = FALSE)

# Summary restricted to NW Atlantic records (Canada / Gulf of Maine /
# Scotian Shelf / Georges Bank / Newfoundland) where these exist
nwa <- "Scotian|Nova Scotia|Canada|Gulf of Maine|Georges|Newfoundland|Labrador|St. Lawrence|Fundy|NAFO|New England|Sable|Banquereau|USA"
summ <- g |>
    mutate(nwa = grepl(nwa, Locality, ignore.case = TRUE)) |>
    group_by(Species, nwa) |>
    summarise(n = n(),
              Loo_median = median(Loo, na.rm = TRUE),
              K_median = median(K, na.rm = TRUE),
              Lm_median = median(Lm, na.rm = TRUE),
              .groups = "drop")
write.csv(summ, file.path(out_dir, "popgrowth_summary.csv"), row.names = FALSE)
print(summ, n = 50)
