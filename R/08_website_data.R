# 08_website_data.R  (v3)
# ---------------------------------------------------------------------------
# Assembles website/data/site_data.json for the policy explorer page
# (website/build.py turns it into website/index.html and website/page.html).
#
# What it does
#  1. Observed series (literature/data/): cod landings 1958-2002, survey-based
#     cod SSB 1970-2002, DFO summer RV survey biomass indices 1970-2018
#     (cod; forage fish = herring + sand lance + capelin) and Sable Island grey
#     seal pup production. Observations only; nothing is modelled here.
#  2. Hindcast lines (results/alt_adult_M_factorial_traj.csv, written by 07):
#     documented fishing only (= run A of 02) and documented fishing plus adult
#     cod M 0.8 from 1990 (= run B of 02), each with the forage mechanism on
#     (s = 20, main model) and off (s = 1 from 1990, diagnostic).
#  3. Explorer grid (NEW RUNS): starting state x adult cod M x forage-fish F x
#     programme duration, 150 years each. Set up exactly as in
#       04  (from models/collapsed_2025_params.rds),
#       04b (from models/alternative_state_params.rds),
#       04c (imposed survey-like state: baseline spectra x survey ratios),
#       07  (adult cod M stays at 0.8: elevate_M() applied to the baseline
#            parameters, the labelled alternative).
#     Forage (pelagic) F is raised to F_forage for D years from year 0, then
#     returned to 0.1; cod F 0.02 (bycatch) and the other groundfish gears at
#     their moratorium levels throughout. Runs differ ONLY in fishing effort,
#     initial state and the labelled adult-M alternative.
#  4. Conditional "what it would take" map (NEW RUNS): imposed survey-like
#     starting states as in 04c, crossed over cod depletion (0.1-0.1 % of the
#     1980s level) x forage boom (x1-x16) x the assumption strength s, using
#     the recalibrated s variants of 05 (models/sensitivity/s_*.rds and the
#     main model for s = 20). Moratorium effort, baseline adult M, 150 years.
#     Varying s is the sensitivity analysis itself (as in 05), not a scenario.
#  5. The documented-fishing sensitivity map of 05 (results/sensitivity_map.csv).
#  6. Facts used in the page text, each traced to a results/ or literature/ file.
#  7. Sanity checks of the new runs against results/ (website/data/sanity_checks.csv).
#
# New runs are cached in website/data/cache/runs.rds; delete it (or set
# REBUILD=1) to recompute (~10-20 min on 4 cores). NCORES env var sets cores.
# Run from the repository root:  Rscript R/08_website_data.R
# Does not modify any existing file in R/, results/, figures/, models/, data/.
# ---------------------------------------------------------------------------
source("R/functions.R")
suppressPackageStartupMessages({ library(dplyr); library(parallel); library(jsonlite) })
options(mizer_info_level = 0)

OUT_DIR <- "website/data"
CACHE <- file.path(OUT_DIR, "cache", "runs.rds")
dir.create(dirname(CACHE), showWarnings = FALSE, recursive = TRUE)
NCORES <- as.integer(Sys.getenv("NCORES", "4"))
END <- 150
T_KEEP <- c(0:30, seq(32, 60, 2), seq(65, END, 5))   # years stored for the explorer charts

params <- readParams("models/baseline_params.rds")
collapsed <- readParams("models/collapsed_2025_params.rds")
alt <- readParams("models/alternative_state_params.rds")
base_ssb <- getSSB(params)[["Cod"]]
base_forage <- sum(getBiomass(params)[FORAGE])
base_ogf <- sum(getBiomass(params)[OTHER_GF])
mor <- moratorium_effort()
pM <- elevate_M(params)                       # as in 07: adult cod (>= 35 cm) M 0.8

#' Imposed survey-like start, as start_state() in 04c (for any calibrated p)
start_state <- function(p, cod_factor, boom = 7.87) {
    fac <- c(Cod = cod_factor, Haddock = 0.61, `Silver hake` = 0.60, `American plaice` = 0.45,
             Herring = boom, `Sand lance` = boom, Capelin = boom)
    n <- initialN(p)
    for (sp in names(fac)) n[sp, ] <- n[sp, ] * fac[[sp]]
    initialN(p) <- n
    p
}

STARTS <- list(depleted_2025 = collapsed, alt_state = alt,
               boom_cod10 = start_state(params, 0.10), boom_cod04 = start_state(params, 0.04),
               boom_cod01 = start_state(params, 0.01))
M_PARAMS <- list(baseline = params, elevated = pM)
F_grid <- c(0.1, 0.25, 0.5, 0.75, 1.0, 1.5, 2.0, 3.0)
D_grid <- c(5, 10, 15, 20, 30, END)                  # END = permanent

#' Metrics and stored trajectories of one run (df from run_scenario, years 0..END)
summarise_run <- function(df, D, b_ssb, b_forage, b_ogf) {
    cod <- df[df$species == "Cod", ]
    agg <- function(sp, v) { x <- aggregate(df[df$species %in% sp, v], list(year = df$year[df$species %in% sp]), sum); x$x }
    yrs <- sort(unique(cod$year))
    fb <- agg(FORAGE, "biomass"); fy <- agg(FORAGE, "yield"); gf <- agg(OTHER_GF, "biomass")
    ssb <- cod$ssb[order(cod$year)]; cy <- cod$yield[order(cod$year)]
    rec <- yrs[ssb >= 0.5 * b_ssb]; rec100 <- yrs[ssb >= b_ssb]
    in_prog <- yrs <= min(D, END)
    during <- yrs < D
    list(
        metrics = data.frame(
            years_to_50pct = if (length(rec)) min(rec) else NA,
            years_to_100pct = if (length(rec100)) min(rec100) else NA,
            persistent_recovery = all(ssb[yrs > END - 30] >= 0.5 * b_ssb),
            cod_ssb_end_rel = ssb[yrs == END] / b_ssb,
            cod_ssb_start_rel = ssb[yrs == 0] / b_ssb,
            cod_ssb_t24_rel = ssb[yrs == 24] / b_ssb,
            forage_start_rel = fb[yrs == 0] / b_forage,
            forage_min_programme_rel = min(fb[in_prog]) / b_forage,
            forage_end_programme_rel = fb[yrs == min(D, END)] / b_forage,
            forage_min_all_rel = min(fb) / b_forage,
            forage_end_rel = fb[yrs == END] / b_forage,
            forage_yield_during_kt_per_yr = gm2_to_kt(mean(fy[during])),
            forage_yield_during_total_kt = gm2_to_kt(sum(fy[during])),
            cod_yield_first_60yr_kt = gm2_to_kt(sum(cy[yrs < 60])),
            other_groundfish_end_rel = gf[yrs == END] / b_ogf),
        traj = data.frame(year = yrs, cod_ssb_rel = ssb / b_ssb, forage_rel = fb / b_forage,
                          forage_yield_kt = gm2_to_kt(fy), cod_yield_kt = gm2_to_kt(cy)))
}

one_explorer_run <- function(start, M, Ff, D) {
    eff <- as.data.frame(rbind(mor, mor)); eff$year <- c(0, D)
    eff$pelagic <- c(Ff, mor[["pelagic"]])
    df <- run_scenario(M_PARAMS[[M]], eff, years = c(0, END), initial = STARTS[[start]])
    s <- summarise_run(df, D, base_ssb, base_forage, base_ogf)
    s$metrics <- cbind(data.frame(start = start, M = M, F_forage = Ff, D = D), s$metrics)
    s$traj <- cbind(data.frame(start = start, M = M, F_forage = Ff, D = D), s$traj)
    s
}

# --- conditional map: s variants x boom x cod depletion -----------------------------
S_VARIANTS <- c(1, 5, 10, 20, 40)
s_params <- function(s) if (s == 20) params else readParams(sprintf("models/sensitivity/s_%g.rds", s))
MAP_BOOM <- c(1, 2, 4, 7.87, 16)
MAP_COD <- c(0.10, 0.04, 0.02, 0.01, 0.005, 0.001)

one_map_run <- function(s, boom, cod_start) {
    p <- s_params(s)
    b_ssb <- getSSB(p)[["Cod"]]; b_forage <- sum(getBiomass(p)[FORAGE]); b_ogf <- sum(getBiomass(p)[OTHER_GF])
    df <- run_scenario(p, mor, years = c(0, END), initial = start_state(p, cod_start, boom))
    s_out <- summarise_run(df, 0, b_ssb, b_forage, b_ogf)$metrics
    data.frame(s = s, boom = boom, cod_start = cod_start,
               years_to_50pct = s_out$years_to_50pct, persistent_recovery = s_out$persistent_recovery,
               cod_ssb_end_rel = s_out$cod_ssb_end_rel, forage_end_rel = s_out$forage_end_rel)
}

forage_share <- function(p) {          # as in 05
    b <- prerecruit_budget(p, "Cod", 0.001, 1)
    b$fraction_killed[b$source == "forage"] / b$fraction_killed[b$source == "total"]
}

if (file.exists(CACHE) && Sys.getenv("REBUILD") != "1") {
    cat("Using cached runs:", CACHE, "\n")
    cache <- readRDS(CACHE)
} else {
    t0 <- Sys.time()
    grid <- expand.grid(F_forage = F_grid, D = D_grid, M = names(M_PARAMS), start = names(STARTS),
                        stringsAsFactors = FALSE)
    grid <- grid[!(grid$F_forage == 0.1 & grid$D != 5), ]       # status quo once per start x M
    cat(nrow(grid), "explorer runs on", NCORES, "cores\n")
    ex <- mclapply(seq_len(nrow(grid)), function(i)
        tryCatch(one_explorer_run(grid$start[i], grid$M[i], grid$F_forage[i], grid$D[i]),
                 error = function(e) list(error = conditionMessage(e), row = grid[i, ])),
        mc.cores = NCORES)
    bad <- vapply(ex, function(x) !is.null(x$error), logical(1))
    if (any(bad)) { print(ex[bad]); stop("explorer runs failed") }
    cat(sprintf("explorer runs done in %.1f min\n", as.numeric(difftime(Sys.time(), t0, units = "mins"))))
    mgrid <- expand.grid(s = S_VARIANTS, boom = MAP_BOOM, cod_start = MAP_COD)
    mp <- mclapply(seq_len(nrow(mgrid)), function(i)
        tryCatch(one_map_run(mgrid$s[i], mgrid$boom[i], mgrid$cod_start[i]),
                 error = function(e) data.frame(s = mgrid$s[i], boom = mgrid$boom[i],
                                                cod_start = mgrid$cod_start[i], error = conditionMessage(e))),
        mc.cores = NCORES)
    shares <- data.frame(s = S_VARIANTS, forage_share = vapply(S_VARIANTS, function(s) forage_share(s_params(s)), 1))
    cache <- list(metrics = bind_rows(lapply(ex, `[[`, "metrics")),
                  traj = bind_rows(lapply(ex, `[[`, "traj")),
                  map = bind_rows(mp), shares = shares,
                  created = format(Sys.time()), mizer = as.character(packageVersion("mizer")))
    saveRDS(cache, CACHE)
    cat(sprintf("all new runs done in %.1f min\n", as.numeric(difftime(Sys.time(), t0, units = "mins"))))
}
met <- cache$metrics; traj <- cache$traj; map <- cache$map
if (!is.null(map$error) && any(!is.na(map$error))) { print(map[!is.na(map$error), ]); stop("map runs failed") }

# --- sanity checks against existing results -------------------------------------------
chk <- list()
add_chk <- function(check, key, metric, existing, new) {
    chk[[length(chk) + 1]] <<- data.frame(check = check, case = key, metric = metric,
                                          existing = as.numeric(existing), new = as.numeric(new))
}
get_new <- function(start, M, Ff, D) {
    D2 <- if (Ff == 0.1) 5 else D
    met[met$start == start & met$M == M & met$F_forage == Ff & met$D == D2, ]
}
ffg <- read.csv("results/forage_fishing_grid.csv")              # 04: depleted 2025, M baseline
for (i in seq_len(nrow(ffg))) {
    r <- ffg[i, ]; D <- if (r$permanent) END else r$D
    n <- get_new("depleted_2025", "baseline", r$F_forage, D)
    key <- sprintf("F %.2f, D %s", r$F_forage, if (r$permanent) "permanent" else r$D)
    add_chk("04 depleted 2025 state", key, "years_to_50pct", r$years_to_50pct, n$years_to_50pct)
    add_chk("04 depleted 2025 state", key, "years_to_100pct", r$years_to_100pct, n$years_to_100pct)
    if (!r$permanent) add_chk("04 depleted 2025 state", key, "forage_yield_during_kt_per_yr",
                              r$forage_yield_during_kt_per_yr, n$forage_yield_during_kt_per_yr)
}
alt_g <- read.csv("results/forage_fishing_alt_state_grid.csv")  # 04b: alternative state
for (i in seq_len(nrow(alt_g))) {
    r <- alt_g[i, ]; n <- get_new("alt_state", "baseline", r$F_forage, r$D)
    key <- sprintf("F %.2f, D %s", r$F_forage, if (r$permanent) "permanent" else r$D)
    add_chk("04b alternative state", key, "years_to_50pct", r$years_to_50pct, n$years_to_50pct)
    add_chk("04b alternative state", key, "persistent_recovery", r$persistent_recovery, n$persistent_recovery)
    add_chk("04b alternative state", key, "cod_ssb_end_rel", r$cod_ssb_end_rel, n$cod_ssb_end_rel)
    add_chk("04b alternative state", key, "forage_yield_during_kt_per_yr", r$forage_yield_during_kt_per_yr,
            n$forage_yield_during_kt_per_yr)
}
ols <- read.csv("results/observed_like_start.csv")               # 04c: imposed survey-like start
ols <- ols[ols$s == "20 (main)", ]
sid <- c(`0.1` = "boom_cod10", `0.04` = "boom_cod04", `0.01` = "boom_cod01")
for (i in seq_len(nrow(ols))) {
    r <- ols[i, ]; n <- get_new(sid[[as.character(r$cod_start)]], "baseline", r$F_forage, 10)
    key <- sprintf("cod start %.2f, F %.1f for 10 yr", r$cod_start, r$F_forage)
    add_chk("04c survey-like start", key, "years_to_50pct", r$years_to_50pct, n$years_to_50pct)
    add_chk("04c survey-like start", key, "persistent_recovery", r$persistent_recovery, n$persistent_recovery)
    add_chk("04c survey-like start", key, "cod_ssb_end_rel", r$cod_ssb_end_rel, n$cod_ssb_end_rel)
    if (r$F_forage == 0.1) {
        m <- map[map$s == 20 & map$boom == 7.87 & abs(map$cod_start - r$cod_start) < 1e-9, ]
        add_chk("04c vs conditional map (s 20, boom 7.87)", key, "years_to_50pct", r$years_to_50pct, m$years_to_50pct)
        add_chk("04c vs conditional map (s 20, boom 7.87)", key, "persistent_recovery", r$persistent_recovery,
                m$persistent_recovery)
    }
}
amf <- read.csv("results/alt_adult_M_forage_fishing.csv")       # 07: adult M stays / returns
for (i in seq_len(nrow(amf))) {
    r <- amf[i, ]; M <- if (r$M_after_2025 == "stays 0.8") "elevated" else "baseline"
    n <- get_new("depleted_2025", M, r$F_forage, r$D)
    key <- sprintf("M %s, F %.1f, D %d", r$M_after_2025, r$F_forage, r$D)
    add_chk("07 adult M", key, "years_to_50pct", r$years_to_50pct, n$years_to_50pct)
    add_chk("07 adult M", key, "cod_ssb_2050_rel (t = 24)", r$cod_ssb_2050_rel, n$cod_ssb_t24_rel)
}
chk <- bind_rows(chk)
chk$abs_diff <- abs(chk$new - chk$existing)
chk$rel_diff <- ifelse(is.finite(chk$existing) & abs(chk$existing) > 0, chk$abs_diff / abs(chk$existing), NA)
chk$agree <- with(chk, (is.na(existing) & is.na(new)) |
                      (!is.na(existing) & !is.na(new) &
                           ifelse(grepl("persistent", metric), abs_diff == 0,
                                  ifelse(grepl("years", metric), abs_diff <= 1,
                                         rel_diff <= 0.02 | abs_diff < 1e-6))))
write.csv(chk, file.path(OUT_DIR, "sanity_checks.csv"), row.names = FALSE)
cat(sprintf("Sanity checks: %d of %d agree\n", sum(chk$agree, na.rm = TRUE), nrow(chk)))
if (any(!chk$agree)) { cat("MISMATCHES:\n"); print(chk[!chk$agree, ]) }

# --- 1. observed series -----------------------------------------------------------------
rd <- function(f) read.csv(f, comment.char = "#", check.names = FALSE)
lnd <- rd("literature/data/cod_4VsW_landings_1958_2002.csv")
ass <- rd("literature/data/cod_4VsW_assessment.csv")
srv <- rd("literature/data/ess_rv_biomass_not_qadj_derived.csv")
seal <- rd("literature/data/grey_seal_sable_pups.csv")
srv_forage <- srv[["ATLANTIC HERRING"]] + srv[["NORTHERN SAND LANCE"]] + srv[["CAPELIN"]]
rel80 <- function(x, yr = srv$year) x / mean(x[yr %in% 1980:1989])
periods <- list(`1970-79` = 1970:1979, `1980-89` = 1980:1989, `1995-2004` = 1995:2004,
                `2005-12` = 2005:2012, `2013-18` = 2013:2018)
pratio <- function(x) sapply(periods, function(p) mean(x[srv$year %in% p]) / mean(x[srv$year %in% 1980:1989]))
survey_periods <- data.frame(period = names(periods),
                             start = sapply(periods, min), end = sapply(periods, max),
                             cod = pratio(srv[["ATLANTIC COD"]]), forage = pratio(srv_forage),
                             haddock = pratio(srv[["HADDOCK"]]), silver_hake = pratio(srv[["SILVER HAKE"]]),
                             plaice = pratio(srv[["AMERICAN PLAICE"]]), herring = pratio(srv[["ATLANTIC HERRING"]]),
                             row.names = NULL)
ssb_rel <- ass$SSB_t / mean(ass$SSB_t[ass$year %in% 1980:1985])
seal_ok <- !is.na(seal$sable_pups)

# --- 2. hindcast lines ------------------------------------------------------------------
fac <- read.csv("results/alt_adult_M_factorial_traj.csv")
fac <- fac[fac$year <= 2025, ]
hind_line <- function(M, mech) {
    x <- fac[fac$M == M & fac$forage_mechanism == mech, ]
    cod <- x[x$species == "Cod", ]; cod <- cod[order(cod$year), ]
    fb <- aggregate(biomass ~ year, data = x[x$species %in% FORAGE, ], sum)
    list(cod_ssb_rel = signif(cod$ssb / base_ssb, 3), forage_rel = signif(fb$biomass / base_forage, 3))
}
hyears <- sort(unique(fac$year))
hfac <- read.csv("results/alt_adult_M_factorial.csv")
hmet <- read.csv("results/hindcast_metrics.csv")

# --- 4/5. maps -------------------------------------------------------------------------
smap <- read.csv("results/sensitivity_map.csv")
map_class <- function(y50, persistent) {
    ifelse(!persistent, "stuck",
           ifelse(is.na(y50), "stuck", ifelse(y50 <= 10, "fast", ifelse(y50 <= 30, "slow", "very_slow"))))
}
map$outcome <- map_class(map$years_to_50pct, map$persistent_recovery)
map <- left_join(map, cache$shares, by = "s")
smap_share <- smap |> group_by(s) |> summarise(share = first(forage_share_cod_deaths_baseline))
chk_share <- left_join(cache$shares, smap_share, by = "s")
cat("Forage share of cod 1 mg-1 g deaths, new vs results/sensitivity_map.csv:\n"); print(chk_share)
# stability of each s variant's 1980s state at the main forage reproduction level (from 05)
rf_main <- reproduction_level(params)[["Herring"]]
map_stab <- smap[abs(smap$repro_forage - rf_main) < 1e-6 & smap$s %in% S_VARIANTS, c("s", "baseline_eigenvalue")]
map_stab <- map_stab[match(S_VARIANTS, map_stab$s), ]
map_stuck_n <- function(s) sum(map$outcome == "stuck" & map$s == s)

# --- 6. facts (numbers quoted in the page text) -----------------------------------------
cq <- read.csv("results/calibration_quality.csv")
cqv <- function(pat) as.numeric(cq$value[grepl(pat, cq$criterion)][1])
bud <- read.csv("results/baseline_prerecruit_budget.csv")
inv <- read.csv("results/bistability_invasion.csv")
alt_g_t <- read.csv("results/forage_fishing_alt_state_grid.csv")
gm <- function(start, M, Ff, D) get_new(start, M, Ff, D)
sq_dep <- gm("depleted_2025", "baseline", 0.1, 5)
prog_dep <- met[met$start == "depleted_2025" & met$M == "baseline" & met$F_forage > 0.1, ]
dep_M <- met[met$start == "depleted_2025" & met$M == "elevated", ]
all_M <- met[met$M == "elevated", ]
alt_prog <- met[met$start == "alt_state" & met$M == "baseline" & met$F_forage > 0.1, ]
min_F_alt <- function(D) { x <- alt_prog[alt_prog$D == D & alt_prog$persistent_recovery, ]; if (nrow(x)) min(x$F_forage) else NA }
ols_all <- read.csv("results/observed_like_start.csv")
olsv <- function(cs, s, Ff, col = "years_to_50pct") ols_all[[col]][abs(ols_all$cod_start - cs) < 1e-9 & ols_all$s == s & ols_all$F_forage == Ff]
smap_rec <- smap[smap$recalibrated, ]
hA <- hmet[grepl("^A:", hmet$run), ]; hB <- hmet[grepl("^B", hmet$run), ]
facB_on <- hfac[hfac$M == "elevated" & hfac$forage_mechanism == "on", ]
facB_off <- hfac[hfac$M == "elevated" & hfac$forage_mechanism == "off", ]
seal_at <- function(y) seal$sable_pups[seal$year == y]
recov_alt <- alt_prog[alt_prog$persistent_recovery, ]
nck <- read.csv("results/numerical_checks.csv")
eqm <- read.csv("results/forage_fishing_equilibria.csv")       # 04: constant forage-F equilibria
eqm <- eqm[eqm$F_cod == mor[["cod"]] & eqm$start == "baseline", ]

facts <- list(
    # observations
    landings_peak_kt = max(lnd$total_landings_t) / 1000,
    landings_peak_year = lnd$year[which.max(lnd$total_landings_t)],
    landings_1992_kt = lnd$total_landings_t[lnd$year == 1992] / 1000,
    landings_1993_kt = lnd$total_landings_t[lnd$year == 1993] / 1000,
    landings_1994_t = lnd$total_landings_t[lnd$year == 1994],
    landings_2002_t = lnd$total_landings_t[lnd$year == 2002],
    landings_1980s_mean_kt = mean(lnd$total_landings_t[lnd$year %in% 1980:1989]) / 1000,
    ssb_peak_kt = max(ass$SSB_t) / 1000, ssb_peak_year = ass$year[which.max(ass$SSB_t)],
    ssb_2002_kt = ass$SSB_t[ass$year == 2002] / 1000,
    ssb_decline_frac = 1 - ass$SSB_t[ass$year == 2002] / max(ass$SSB_t),
    ssb_1997_2002_rel = mean(ssb_rel[ass$year %in% 1997:2002]),
    survey_cod_1995_2004 = survey_periods$cod[survey_periods$period == "1995-2004"],
    survey_cod_2013_18 = survey_periods$cod[survey_periods$period == "2013-18"],
    survey_forage_1995_2004 = survey_periods$forage[survey_periods$period == "1995-2004"],
    survey_forage_2005_12 = survey_periods$forage[survey_periods$period == "2005-12"],
    survey_forage_2013_18 = survey_periods$forage[survey_periods$period == "2013-18"],
    survey_haddock_1995_2004 = survey_periods$haddock[survey_periods$period == "1995-2004"],
    survey_plaice_1995_2004 = survey_periods$plaice[survey_periods$period == "1995-2004"],
    survey_hake_1995_2004 = survey_periods$silver_hake[survey_periods$period == "1995-2004"],
    seal_pups_1980 = seal_at(1980), seal_pups_1993 = seal_at(1993), seal_pups_2016 = seal_at(2016),
    seal_pups_2021 = seal_at(2021),
    # constants quoted from literature/empirical_targets.md (not in literature/data/)
    rv_index_2023_t = 8212, rv_index_2024_t = 4691,          # dfo2025rvtrends Table 1 (empirical_targets.md 2b)
    adult_M_1990_2004 = 0.8,                                 # mohn2012laurentian (empirical_targets.md 2d)
    adult_M_normal = 0.2,                                    # mohn2012laurentian p. 2
    moratorium_year = 1993,
    # model set-up and calibration
    s_value = 20,
    forage_share_cod_deaths = bud$share_of_deaths[bud$species == "Cod" & bud$w_hi == 1 & bud$source == "forage"],
    model_cod_yield_kt = cqv("cod yield"), observed_landings_kt = 53.5,
    max_biomass_error = max(abs(as.numeric(cq$value[grepl("biomass error", cq$criterion)]))),
    base_cod_ssb_kt = gm2_to_kt(base_ssb),
    base_forage_kt = gm2_to_kt(base_forage),
    invasion_rate = inv$value[inv$quantity == "cod_invasion_growth_rate_per_yr"],
    alt_forage_cod_free = inv$value[inv$quantity == "forage_biomass_cod_free_rel_baseline"],
    # hindcast (results/hindcast_metrics.csv, alt_adult_M_factorial.csv)
    hindA_ssb_1993_rel = hA$ssb_min_rel, hindA_year_50 = hA$year_recover50,
    hindA_years_to_50 = hA$years_to_recover50,
    hindA_cod_ratio = hA$cod, hindA_forage_ratio = hA$forage,
    hindA_other_min = min(hA$haddock, hA$silver_hake, hA$plaice),
    hindA_other_max = max(hA$haddock, hA$silver_hake, hA$plaice),
    hindB_cod_ratio = hB$cod, hindB_forage_ratio = hB$forage, hindB_ssb_2025_rel = hB$ssb_2025_rel,
    hindB_mech_off_ssb_2000_02 = facB_off$cod_ssb_2000_02_rel_1980_85,
    hindB_mech_on_ssb_2000_02 = facB_on$cod_ssb_2000_02_rel_1980_85,
    hindB_mech_effect = 1 - facB_on$cod_ssb_2000_02_rel_1980_85 / facB_off$cod_ssb_2000_02_rel_1980_85,
    # explorer: depleted 2025 state (new runs; match results/forage_fishing_grid.csv)
    dep_sq_years = sq_dep$years_to_50pct,
    dep_prog_min_years = min(prog_dep$years_to_50pct), dep_prog_max_years = max(prog_dep$years_to_50pct),
    dep_delay_min = min(prog_dep$years_to_50pct) - sq_dep$years_to_50pct,
    dep_delay_max = max(prog_dep$years_to_50pct) - sq_dep$years_to_50pct,
    dep_start_cod_rel = sq_dep$cod_ssb_start_rel,
    dep_start_forage_rel = sq_dep$forage_start_rel,
    dep_M_any_recovery = any(!is.na(dep_M$years_to_50pct)),
    all_M_any_recovery = sum(!is.na(all_M$years_to_50pct) & all_M$persistent_recovery),
    all_M_n_runs = nrow(all_M),
    # alternative state
    alt_start_forage_rel = met$forage_start_rel[met$start == "alt_state"][1],
    alt_min_F_D5 = min_F_alt(5), alt_min_F_D10 = min_F_alt(10), alt_min_F_D15 = min_F_alt(15),
    alt_min_F_perm = min_F_alt(END),
    alt_rec_years_min = min(recov_alt$years_to_50pct), alt_rec_years_max = max(recov_alt$years_to_50pct[recov_alt$D < END]),
    alt_rec_cod_end_min = min(recov_alt$cod_ssb_end_rel), alt_rec_cod_end_max = max(recov_alt$cod_ssb_end_rel),
    alt_F05_D10_yield = gm("alt_state", "baseline", 0.5, 10)$forage_yield_during_kt_per_yr,
    alt_F1_D10_yield = gm("alt_state", "baseline", 1, 10)$forage_yield_during_kt_per_yr,
    # survey-like starts (04c)
    ols_cod10_years = olsv(0.1, "20 (main)", 0.1), ols_cod04_years = olsv(0.04, "20 (main)", 0.1),
    ols_cod01_peak_year = olsv(0.01, "20 (main)", 0.1),
    ols_cod01_end_rel = olsv(0.01, "20 (main)", 0.1, "cod_ssb_end_rel"),
    ols_cod01_F05_years = olsv(0.01, "20 (main)", 0.5), ols_cod01_F1_years = olsv(0.01, "20 (main)", 1),
    ols_cod01_s1_years = olsv(0.01, "1 (diagnostic)", 0.1),
    # sensitivity map (documented fishing)
    sens_max_boom = max(smap_rec$forage_ratio_1995_2004), sens_min_boom = min(smap_rec$forage_ratio_1995_2004),
    sens_max_years = max(smap_rec$years_to_50pct_from_1993),
    sens_share_min = min(smap_rec$forage_share_cod_deaths_baseline),
    sens_share_max = max(smap_rec$forage_share_cod_deaths_baseline),
    map_stuck_cells = sum(map$outcome == "stuck"), map_cells = nrow(map),
    map_cells_per_panel = length(MAP_BOOM) * length(MAP_COD),
    map_stuck_low_s = sum(map$outcome == "stuck" & map$s <= 10),
    map_stuck_s20 = map_stuck_n(20), map_stuck_s40 = map_stuck_n(40),
    map_share_s10 = cache$shares$forage_share[cache$shares$s == 10],
    map_share_s20 = cache$shares$forage_share[cache$shares$s == 20],
    map_share_s40 = cache$shares$forage_share[cache$shares$s == 40],
    map_s40_eigenvalue = map_stab$baseline_eigenvalue[map_stab$s == 40],
    map_s20_cod04_boom787_years = map$years_to_50pct[map$s == 20 & map$boom == 7.87 & map$cod_start == 0.04],
    map_s20_cod10_boom787_years = map$years_to_50pct[map$s == 20 & map$boom == 7.87 & map$cod_start == 0.10],
    sens_n_rec = nrow(smap_rec),
    sens_share_s80 = smap$forage_share_cod_deaths_baseline[smap$s == 80][1],
    sens_share_s160 = smap$forage_share_cod_deaths_baseline[smap$s == 160][1],
    # explanatory conversions and literature constants
    adult_M_frac_high = 1 - exp(-0.8), adult_M_frac_normal = 1 - exp(-0.2),   # share dying per year at M
    north_sea_herring_egg_max_pct = 0.19,      # daan1985predation (literature/counterarguments.md A3)
    seal_diet_sand_lance = 0.692,              # bowen1994offshore (literature/empirical_targets.md 4)
    status_quo_F = mor[["pelagic"]], cod_bycatch_F = mor[["cod"]],
    ssb_min_post1993_rel = min(ssb_rel[ass$year >= 1993]),
    cod_collapse_F_model = cqv("cod collapse F"),
    eq_cod_w5_sq_kg = eqm$cod_weight_age5_g[eqm$F_forage == 0.1] / 1000,
    eq_cod_w5_F1_kg = eqm$cod_weight_age5_g[eqm$F_forage == 1] / 1000,
    eq_cod_min = min(eqm$cod_ssb_rel), eq_cod_max = max(eqm$cod_ssb_rel),
    sanity_n = nrow(chk), sanity_agree = sum(chk$agree, na.rm = TRUE),
    mizer_version_text = cache$mizer,
    hindA_year_min = hA$year_min,
    cod_age_mat = cqv("age at maturity Cod"),
    adult_length_cm = 35,                      # l_adult default of elevate_M() in R/functions.R
    alt_reintro = 1e-3,                        # reintroduction level in R/04b_*
    cod_collapse_F_target = cq$target[grepl("cod collapse F", cq$criterion)][1],
    numcheck_max_shift_yr = max(abs(c(nck$B_years_to_50pct_after_2025 - nck$B_years_to_50pct_after_2025[nck$case == "reference"],
                                      nck$B_forage_F1_10yr_years_to_50pct - nck$B_forage_F1_10yr_years_to_50pct[nck$case == "reference"]))),
    dep_hardF_forage_low_max = max(met$forage_min_all_rel[met$start == "depleted_2025" & met$M == "baseline" &
                                                              met$F_forage >= 0.5 & met$D >= 10]),
    dep_sq_forage_low = sq_dep$forage_min_all_rel
)
facts <- lapply(facts, function(v) if (is.numeric(v)) signif(v, 4) else v)
fact_sources <- list(
    landings = "literature/data/cod_4VsW_landings_1958_2002.csv (Fanning et al. 2003, Table 1)",
    ssb = "literature/data/cod_4VsW_assessment.csv (Fanning et al. 2003, Table 13)",
    survey = "literature/data/ess_rv_biomass_not_qadj_derived.csv (derived, indicative)",
    seal = "literature/data/grey_seal_sable_pups.csv (Hammill et al. 2023, Table 4)",
    rv_index = "literature/empirical_targets.md section 2b (dfo2025rvtrends Table 1)",
    adult_M = "literature/empirical_targets.md section 2d (mohn2012laurentian)",
    calibration = "results/calibration_quality.csv, results/baseline_prerecruit_budget.csv",
    hindcast = "results/hindcast_metrics.csv, results/alt_adult_M_factorial.csv",
    explorer = "new runs of this script (website/data/cache/runs.rds), checked in sanity_checks.csv",
    alt_state = "new runs; identical setup to results/forage_fishing_alt_state_grid.csv",
    ols = "results/observed_like_start.csv",
    sens = "results/sensitivity_map.csv (recalibrated rows only)",
    invasion = "results/bistability_invasion.csv",
    equilibria = "results/forage_fishing_equilibria.csv (cod F 0.02, baseline start)",
    literature_constants = "north_sea_herring_egg_max_pct: literature/counterarguments.md A3 (daan1985predation); seal_diet_sand_lance: literature/empirical_targets.md 4 (bowen1994offshore)",
    conversions = "adult_M_frac_*: 1 - exp(-M), the share dying per year at natural mortality M with no fishing",
    numerical = "results/numerical_checks.csv (largest change in years to 50 % between numerical settings)")

# --- encode explorer trajectories ------------------------------------------------------
enc_log <- function(x) as.integer(round(100 * log10(pmax(x, 1e-12))))   # 100 x log10, floor 1e-12
enc_kt <- function(x) { y <- signif(x, 3); y[abs(y) < 0.01] <- 0; y }
run_key <- function(start, M, Ff, D) sprintf("%s|%s|%g|%g", start, M, Ff, D)
runs <- list()
for (i in seq_len(nrow(met))) {
    m <- met[i, ]
    tr <- traj[traj$start == m$start & traj$M == m$M & traj$F_forage == m$F_forage & traj$D == m$D, ]
    tr <- tr[match(T_KEEP, tr$year), ]
    runs[[run_key(m$start, m$M, m$F_forage, m$D)]] <- list(
        y50 = m$years_to_50pct, y100 = m$years_to_100pct, persist = m$persistent_recovery,
        cod_end = signif(m$cod_ssb_end_rel, 3),
        f_min_prog = signif(m$forage_min_programme_rel, 3), f_min = signif(m$forage_min_all_rel, 3),
        f_end_prog = signif(m$forage_end_programme_rel, 3),
        f_end = signif(m$forage_end_rel, 3),
        fy_mean = signif(m$forage_yield_during_kt_per_yr, 3), fy_total = signif(m$forage_yield_during_total_kt, 3),
        cy60 = signif(m$cod_yield_first_60yr_kt, 3), ogf_end = signif(m$other_groundfish_end_rel, 3),
        cod = enc_log(tr$cod_ssb_rel), forage = enc_log(tr$forage_rel),
        fy = enc_kt(tr$forage_yield_kt), cy = enc_kt(tr$cod_yield_kt))
}

site <- list(
    meta = list(
        generated = format(Sys.time(), "%Y-%m-%d %H:%M"), model = "v3 (main model)",
        mizer_version = cache$mizer, script = "R/08_website_data.R",
        units = "Relative values are divided by the model's 1980-85 baseline (model) or the 1980s survey mean (observations). kt = thousand tonnes. Years from start of programme unless stated.",
        shelf_area_km2 = SHELF_AREA_KM2),
    facts = facts, fact_sources = fact_sources,
    observed = list(
        landings = list(year = lnd$year, kt = round(lnd$total_landings_t / 1000, 2)),
        ssb = list(year = ass$year, kt = round(ass$SSB_t / 1000, 2), rel = signif(ssb_rel, 3)),
        survey = list(year = srv$year, cod_rel = signif(rel80(srv[["ATLANTIC COD"]]), 3),
                      forage_rel = signif(rel80(srv_forage), 3)),
        survey_periods = lapply(seq_len(nrow(survey_periods)), function(i) {
            r <- survey_periods[i, ]; list(period = r$period, start = r$start, end = r$end,
                                           cod = signif(r$cod, 3), forage = signif(r$forage, 3),
                                           haddock = signif(r$haddock, 3), silver_hake = signif(r$silver_hake, 3),
                                           plaice = signif(r$plaice, 3), herring = signif(r$herring, 3)) }),
        seals = list(year = seal$year[seal_ok], sable_pups = seal$sable_pups[seal_ok])),
    hindcast = list(
        year = hyears,
        runs = list(
            fishing_only = hind_line("baseline", "on"), fishing_only_s1 = hind_line("baseline", "off"),
            high_M = hind_line("elevated", "on"), high_M_s1 = hind_line("elevated", "off"))),
    explorer = list(
        t = T_KEEP, F_levels = F_grid, D_levels = D_grid, permanent_D = END, horizon = END,
        status_quo_F = mor[["pelagic"]], cod_bycatch_F = mor[["cod"]],
        encoding = list(cod = "round(100*log10(cod SSB / 1980-85 baseline SSB)), floor -1200",
                        forage = "round(100*log10(forage biomass / 1980-85 baseline)), floor -1200",
                        fy = "forage-fish yield, kt per year", cy = "cod yield (bycatch), kt per year"),
        runs = runs),
    sensitivity_documented = lapply(seq_len(nrow(smap)), function(i) {
        r <- smap[i, ]
        list(s = r$s, recalibrated = r$recalibrated, share = signif(r$forage_share_cod_deaths_baseline, 3),
             repro_forage = signif(r$repro_forage, 3), boom = signif(r$forage_ratio_1995_2004, 3),
             years_to_50 = r$years_to_50pct_from_1993, outcome = r$outcome,
             invasion_rate = signif(r$invasion_rate, 3)) }),
    conditional_map = list(
        s = S_VARIANTS, share = signif(cache$shares$forage_share, 3), boom = MAP_BOOM, cod_start = MAP_COD,
        baseline_eigenvalue = signif(map_stab$baseline_eigenvalue, 3),
        baseline_stable = map_stab$baseline_eigenvalue < 0,
        cells = lapply(seq_len(nrow(map)), function(i) {
            r <- map[i, ]
            list(s = r$s, boom = r$boom, cod = r$cod_start, y50 = r$years_to_50pct,
                 persist = r$persistent_recovery, outcome = r$outcome,
                 cod_end = signif(r$cod_ssb_end_rel, 3)) })),
    sanity = list(n_checks = nrow(chk), n_agree = sum(chk$agree, na.rm = TRUE),
                  file = "website/data/sanity_checks.csv")
)
json <- toJSON(site, auto_unbox = TRUE, null = "null", na = "null", digits = NA)
writeLines(json, file.path(OUT_DIR, "site_data.json"))
cat(sprintf("Wrote %s (%.0f KB)\n", file.path(OUT_DIR, "site_data.json"),
            file.size(file.path(OUT_DIR, "site_data.json")) / 1024))
cat("08_website_data.R done\n")
