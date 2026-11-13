# functions.R  (model version 2, the main model)
# ---------------------------------------------------------------------------
# Reusable functions for the eastern Scotian Shelf (NAFO 4VsW) cod model, v2.
# v1 (naive calibration) lives in R/v1/ and is kept unchanged for reference.
#
# Differences from v1 (see results/SUMMARY.md for justification):
#  * resource abundance and productivity constrained by independent
#    zooplankton biomass and P/B on the Scotian Shelf (Bundy 2004):
#    kappa = 2.5, r_pp = 1;
#  * community-wide background mortality of eggs, larvae and small juveniles
#    (Peterson & Wroblewski 1984 size-mortality relation, tapered above 1 g),
#    so that most egg-to-juvenile mortality is explicit rather than hidden in
#    erepro; cod and other groundfish recruitment emerges from it with low
#    Beverton-Holt reproduction levels;
#  * forage-fish reproduction level low (cf. Adekoya et al. 2026: R_max ~8x),
#    calibrated so that the hindcast reproduces the observed forage boom;
#  * one gear per groundfish species, so haddock, silver hake and plaice can
#    follow their observed declines through fishing.
#
# The central function is run_scenario(): it projects a MizerParams object from
# a given initial state under per-gear effort trajectories and returns a tidy
# data frame. It has no side effects, so it can be called in parallel.
#
# Units: g m^-2 of shelf, years. 1 g m^-2 = 110 kt over 1.1e5 km^2.
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
    library(mizer)
})

SHELF_AREA_KM2 <- 1.1e5
gm2_to_kt <- function(x) x * SHELF_AREA_KM2 * 1e6 / 1e9   # g/m2 -> kt

FORAGE <- c("Herring", "Sand lance", "Capelin")
OTHER_GF <- c("Haddock", "Silver hake", "American plaice")
GROUNDFISH <- c("Cod", OTHER_GF)
GEARS <- c("cod", "haddock", "silver_hake", "plaice", "pelagic")
GF_GEARS <- c(Haddock = "haddock", `Silver hake` = "silver_hake", `American plaice` = "plaice")
DATA_DIR <- "data/v2"

SPECIES_COLOURS <- c(
    "Cod" = "#000000", "Haddock" = "#E69F00", "Silver hake" = "#56B4E9",
    "American plaice" = "#009E73", "Herring" = "#0072B2", "Sand lance" = "#D55E00",
    "Capelin" = "#CC79A7", "Forage fish" = "#D55E00", "Other groundfish" = "#E69F00",
    "Resource" = "#999999")

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

#' Default (main) model configuration
default_config <- function() {
    list(
        kappa = 3,                # resource coefficient: matches Scotian Shelf zooplankton biomass
        kappa_path = 3,           # continuation path (calibration starts at kappa = 3)
        r_pp = 1,                 # resource replenishment used during calibration (w^-1/3)
        rr_coef = 1.41,           # final resource P/B = rr_coef * w^rr_exp, fitted to Bundy (2004):
        rr_exp = -0.22,           #   8.4 /yr at 0.3 mg (copepods), 3.04 /yr at 30 mg (euphausiids)
        s_egg = 1,                # forage -> cod interaction (1 = purely size-based)
        repro_cod = 0.1,          # Beverton-Holt reproduction level, cod
        repro_groundfish = 0.1,   # haddock, silver hake, plaice
        repro_forage = 0.125,     # herring, sand lance, capelin (recalibrated in 01)
        background = TRUE,        # early-life background mortality (unmodelled predators)
        bg_MG = 0.5,              # mortality : specific-growth ratio of the background (Z/G)
        bg_taper_w = 1,           # g; background mortality tapers off above ~1 g
        no_w = 120,
        effort = c(cod = 0.40, haddock = 0.30, silver_hake = 0.30, plaice = 0.30, pelagic = 0.10),
        biomass_tol = 0.03,
        max_iter = 20)
}

#' Set the data-constrained resource replenishment rate (P/B by size),
#' rebalancing the capacity so that the steady state is unchanged
set_resource_rate <- function(params, cfg = default_config()) {
    rr <- cfg$rr_coef * params@w_full^cfg$rr_exp
    setResource(params, resource_rate = rr)
}

repro_levels <- function(cfg, species) {
    rl <- setNames(rep(cfg$repro_groundfish, length(species)), species)
    rl[intersect(FORAGE, species)] <- cfg$repro_forage
    rl["Cod"] <- cfg$repro_cod
    rl
}

read_inputs <- function(dir = DATA_DIR) {
    sp <- read.csv(file.path(dir, "species_params.csv"), stringsAsFactors = FALSE)
    gp <- read.csv(file.path(dir, "gear_params.csv"), stringsAsFactors = FALSE)
    im <- as.matrix(read.csv(file.path(dir, "interaction_matrix.csv"),
                             row.names = 1, check.names = FALSE))
    list(sp = sp, gp = gp, im = im)
}

#' Background (unmodelled-predator) mortality of early life stages, per year.
#'
#' Eggs, larvae and small juveniles of every species die at a rate equal to
#' bg_MG times their reference specific growth rate, g_ref(w)/w = alpha f0 h
#' w^(n-1) - ks w^(p-1) (growth at the target feeding level f0, before
#' reproduction), multiplied by 1 / (1 + (w / w_taper)^2) so that it applies
#' to early life only. A mortality-to-growth ratio Z/G of order 1 is typical
#' of marine fish larvae (Houde 1997; Beyer 1989). The array is computed from
#' the species parameters and then held fixed, so slower realised growth
#' (e.g. when plankton is depleted) lengthens exposure to it.
background_mort_array <- function(params, cfg) {
    w <- w(params); sp <- species_params(params)
    nsp <- nrow(sp)
    if (!isTRUE(cfg$background)) return(matrix(0, nsp, length(w)))
    f0 <- if (!is.null(sp$f0)) sp$f0 else rep(0.6, nsp)
    f0[is.na(f0)] <- 0.6
    out <- t(sapply(seq_len(nsp), function(i) {
        gref <- sp$alpha[i] * f0[i] * sp$h[i] * w^(sp$n[i] - 1) - sp$ks[i] * w^(sp$p[i] - 1) -
            ifelse(is.na(sp$k[i]), 0, sp$k[i])
        cfg$bg_MG * pmax(gref, 0) / (1 + (w / cfg$bg_taper_w)^2)
    }))
    dimnames(out) <- list(sp = sp$species, w = signif(w, 3))
    out
}

#' External mortality array: species z0 plus the background mortality
ext_mort_array <- function(params, cfg) {
    w <- w(params)
    z0 <- species_params(params)$z0
    em <- ext_mort(params)
    em[] <- outer(z0, rep(1, length(w))) + background_mort_array(params, cfg)
    em
}

#' Recompute the background mortality after growth parameters changed
refresh_bg <- function(params, cfg) {
    ext_mort(params) <- ext_mort_array(params, cfg)
    params
}

# ---------------------------------------------------------------------------
# Calibration helpers (as in v1, with safeguards)
# ---------------------------------------------------------------------------

tune_ss <- function(params) {
    p2 <- tryCatch(suppressWarnings(tuneSteadyState(params, solver = "newton")),
                   error = function(e) NULL)
    if (is.null(p2) || !identical(attr(p2, "convergence")$attractor, "fixed_point")) {
        p2 <- tuneSteadyState(params, t_max = 500)
    }
    p2
}

safe_match_growth <- function(params) {
    ok <- function(p) !is.null(p) && all(is.finite(initialN(p))) &&
        all(is.finite(suppressWarnings(age_mat(p))))
    for (keep in c("biomass", "egg")) {
        p2 <- tryCatch(matchGrowth(params, keep = keep), error = function(e) NULL)
        if (ok(p2)) return(p2)
    }
    params
}

safe_sss <- function(params) {
    for (keep in c("biomass", "egg")) {
        p2 <- tryCatch(steadySingleSpecies(params, keep = keep), error = function(e) NULL)
        if (!is.null(p2) && all(is.finite(initialN(p2)))) return(p2)
    }
    params
}

#' Damped version of matchBiomasses(): scale each species' abundance by
#' (observed / modelled)^damp (damp = 1 is matchBiomasses()).
match_biomass_damped <- function(params, damp = 0.5) {
    sp <- species_params(params)
    b <- getBiomass(params, min_w = sp$biomass_cutoff)
    fac <- (sp$biomass_observed / b)^damp
    fac[!is.finite(fac)] <- 1
    n <- initialN(params)
    n[] <- sweep(unclass(n), 1, fac, "*")
    initialN(params) <- n
    params
}

biomass_error <- function(params) {
    sp <- species_params(params)
    b <- getBiomass(params, min_w = sp$biomass_cutoff)
    (b - sp$biomass_observed) / sp$biomass_observed
}

#' Build and calibrate the baseline (1980-85) steady state
#'
#' As v1 (`R/v1/functions.R`), plus the background early-life mortality,
#' which is set as an external-mortality array right after construction (and
#' therefore frozen; matchGrowth() does not touch it).
build_model <- function(cfg = default_config(), dir = DATA_DIR, verbose = TRUE) {
    old <- options(mizer_info_level = 0); on.exit(options(old))
    defaults_edition(3)
    inp <- read_inputs(dir)
    sp <- inp$sp
    sp$latin <- NULL; sp$group <- NULL
    im <- inp$im[sp$species, sp$species]
    im[FORAGE, "Cod"] <- cfg$s_egg
    k0 <- cfg$kappa_path[1]
    params <- newMultispeciesParams(sp, interaction = im, gear_params = inp$gp,
                                    no_w = cfg$no_w, kappa = k0,
                                    resource_rate = cfg$r_pp, initial_effort = 0)
    params <- refresh_bg(params, cfg)
    for (i in 1:3) {
        p2 <- safe_sss(refresh_bg(safe_match_growth(params), cfg))
        if (!all(is.finite(suppressWarnings(age_mat(p2))))) break
        params <- p2
    }
    initial_effort(params) <- cfg$effort
    params <- safe_sss(params)
    params <- tune_ss(params)
    reproduction_level(params) <- repro_levels(cfg, sp$species)
    kold <- k0
    for (k in c(cfg$kappa_path[-1], cfg$kappa)) {
        if (k != kold) {
            given_species_params(params)$gamma <- species_params(params)$gamma * kold / k
            initialNResource(params) <- initialNResource(params) * k / kold
            resource_params(params)$kappa <- k
            kold <- k
        }
        for (i in 1:3) {
            params <- tune_ss(params)
            params <- matchBiomasses(params)
            params <- refresh_bg(safe_match_growth(params), cfg)
        }
        params <- tune_ss(params)
        if (verbose) cat(sprintf("kappa %.2f: max |biomass error| %.3f\n", k,
                                 max(abs(biomass_error(params)))))
    }
    best <- params; best_err <- max(abs(biomass_error(params)))
    cur <- params; damp <- 1
    for (i in seq_len(cfg$max_iter)) {
        if (best_err < cfg$biomass_tol) break
        params <- match_biomass_damped(cur, damp)
        params <- refresh_bg(safe_match_growth(params), cfg)
        params <- tune_ss(params)
        err <- max(abs(biomass_error(params)))
        ok <- identical(attr(params, "convergence")$attractor, "fixed_point") &&
            all(species_params(params)$erepro < 1) && is.finite(err)
        if (verbose) cat(sprintf("  round %d (damp %.2f): max |error| %.3f, attractor %s, max erepro %.3g\n",
                                 i, damp, err, attr(params, "convergence")$attractor,
                                 max(species_params(params)$erepro)))
        if (ok) {
            cur <- params
            if (err < best_err) { best <- params; best_err <- err }
        } else {
            cur <- best; damp <- damp / 2      # step failed: retry from the best state, smaller step
        }
    }
    params <- best
    conv <- attr(params, "convergence")
    reproduction_level(params) <- repro_levels(cfg, sp$species)
    attr(params, "convergence") <- conv
    if (verbose) cat(sprintf("final: %d iterations, max |biomass error| %.3f, attractor %s\n",
                             i, max(abs(biomass_error(params))), conv$attractor))
    params
}

#' Change the forage -> cod interaction (s_egg) of a calibrated model and
#' re-calibrate the baseline to the same targets (reproduction levels kept).
retune_s_egg <- function(params, s_egg, n_iter = 8, tol = 0.03, cfg = default_config()) {
    old <- options(mizer_info_level = 0); on.exit(options(old))
    rl <- reproduction_level(params)
    im <- interaction_matrix(params); im[FORAGE, "Cod"] <- s_egg
    interaction_matrix(params) <- im
    params <- tune_ss(params)
    for (i in seq_len(n_iter)) {
        if (max(abs(biomass_error(params))) < tol) break
        params <- matchBiomasses(params)
        params <- refresh_bg(safe_match_growth(params), cfg)
        params <- tune_ss(params)
    }
    conv <- attr(params, "convergence")
    reproduction_level(params) <- rl
    attr(params, "convergence") <- conv
    params
}

# ---------------------------------------------------------------------------
# Effort trajectories and scenarios
# ---------------------------------------------------------------------------

#' Build a time x gear effort array (piecewise constant from each listed year)
effort_array <- function(effort, gears, years = NULL, default = NULL) {
    if (is.data.frame(effort)) {
        if (is.null(years)) years <- range(effort$year)
        yrs <- seq(years[1], years[2])
        arr <- matrix(NA_real_, nrow = length(yrs), ncol = length(gears),
                      dimnames = list(time = yrs, gear = gears))
        effort <- effort[order(effort$year), , drop = FALSE]
        idx <- findInterval(yrs, effort$year)
        if (any(idx == 0)) stop("effort data frame must start at or before ", years[1])
        for (g in gears) {
            if (g %in% names(effort)) arr[, g] <- effort[[g]][idx]
            else {
                if (is.null(default) || is.na(default[g])) stop("No effort for gear ", g)
                arr[, g] <- default[[g]]
            }
        }
    } else {
        if (is.null(years)) stop("`years` needed with a constant effort vector")
        yrs <- seq(years[1], years[2])
        e <- default
        if (is.null(e)) e <- setNames(rep(0, length(gears)), gears)
        e[names(effort)] <- effort
        arr <- matrix(rep(e[gears], each = length(yrs)), nrow = length(yrs),
                      dimnames = list(time = yrs, gear = gears))
    }
    arr
}

set_state <- function(params, initial = NULL) {
    if (is.null(initial)) return(params)
    if (inherits(initial, "MizerSim")) initial <- finalParams(initial)
    stopifnot(inherits(initial, "MizerParams"))
    initialN(params) <- initialN(initial)
    initialNResource(params) <- initialNResource(initial)
    params
}

#' Run a fishing scenario and return tidy yearly output
#'
#' @param params MizerParams with the model parameters (e.g. readParams("models/v2/baseline_params.rds")).
#' @param effort data frame with `year` and gear columns (cod, haddock,
#'   silver_hake, plaice, pelagic; piecewise constant from each listed year;
#'   missing gears held at initial_effort(params)), or a named constant vector
#'   (then give `years`).
#' @param years c(start, end).
#' @param initial NULL, a MizerParams or a MizerSim (its final state).
#' @return data frame: year, species, biomass, ssb, yield, F, n_juv, and three
#'   resource rows per year ("Resource <1 mg", "Resource 1-100 mg",
#'   "Resource 0.1-10 g"; biomass only). g m^-2 and g m^-2 yr^-1.
run_scenario <- function(params, effort, years = NULL, initial = NULL,
                         dt = 0.1, method = "euler", return_sim = FALSE) {
    gears <- names(initial_effort(params))
    arr <- effort_array(effort, gears = gears, years = years,
                        default = initial_effort(params))
    p <- set_state(params, initial)
    sim <- project(p, effort = arr, dt = dt, t_save = 1, method = method,
                   progress_bar = FALSE)
    df <- tidy_sim(sim)
    if (return_sim) return(list(data = df, sim = sim))
    df
}

RESOURCE_BANDS <- list(`Resource <1 mg` = c(0, 1e-3), `Resource 1-100 mg` = c(1e-3, 0.1),
                       `Resource 0.1-10 g` = c(0.1, 10))

tidy_sim <- function(sim) {
    params <- getParams(sim)
    sp <- species_params(params)$species
    times <- getTimes(sim)
    B <- getBiomass(sim); S <- getSSB(sim); Y <- getYield(sim)
    Nj <- getN(sim, min_w = 1, max_w = 10)
    eff <- getEffort(sim)
    Q <- catchability(params)
    Fful <- eff %*% Q[colnames(eff), sp, drop = FALSE]
    out <- data.frame(
        year = rep(times, times = length(sp)), species = rep(sp, each = length(times)),
        biomass = as.vector(B[, sp]), ssb = as.vector(S[, sp]), yield = as.vector(Y[, sp]),
        F = as.vector(Fful[, sp]), n_juv = as.vector(Nj[, sp]), stringsAsFactors = FALSE)
    wf <- params@w_full; dwf <- params@dw_full
    nr <- NResource(sim)
    res <- lapply(names(RESOURCE_BANDS), function(b) {
        r <- RESOURCE_BANDS[[b]]; sel <- wf >= r[1] & wf < r[2]
        data.frame(year = times, species = b,
                   biomass = as.vector(nr[, sel, drop = FALSE] %*% (wf[sel] * dwf[sel])),
                   ssb = NA_real_, yield = NA_real_, F = NA_real_, n_juv = NA_real_)
    })
    rbind(out, do.call(rbind, res))
}

#' Project at constant effort until biomasses stop changing (no extinction stop)
equilibrate <- function(params, effort, initial = NULL, t_max = 600,
                        t_check = 20, tol = 1e-3, floor = 1e-8, dt = 0.1) {
    p <- set_state(params, initial)
    gears <- names(initial_effort(params))
    e <- initial_effort(params); e[names(effort)] <- effort
    t <- 0; hist <- list(); rate <- Inf
    repeat {
        sim <- project(p, effort = e[gears], t_max = t_check, dt = dt,
                       t_save = t_check / 4, progress_bar = FALSE)
        B <- getBiomass(sim)
        b0 <- B[1, ]; b1 <- B[nrow(B), ]
        ok <- pmin(b0, b1) > floor
        rate <- if (any(ok)) max(abs(log(b1[ok] / b0[ok]))) / t_check else 0
        t <- t + t_check
        hist[[length(hist) + 1]] <- data.frame(t = t, species = names(b1), biomass = b1)
        p <- finalParams(sim)
        if (rate < tol || t >= t_max) break
    }
    list(params = p, sim = sim, years = t, rate = rate, converged = rate < tol,
         biomass = getBiomass(p), history = do.call(rbind, hist))
}

log_growth_rate <- function(sim, species = "Cod", years = 50) {
    B <- getBiomass(sim)[, species]
    tt <- as.numeric(names(B))
    sel <- tt >= max(tt) - years
    unname(coef(lm(log(B[sel]) ~ tt[sel]))[2])
}

#' Cod-free community at given effort, and growth rate of reintroduced cod
#'
#' Cod is reintroduced at init_frac of its baseline abundance. The invasion
#' rate is the slope of log cod biomass while cod is still rare (below 1e-3
#' of its baseline biomass), from year 10 (after the initial transient of the
#' size structure) up to t_inv. If cod passes 1e-3 of baseline before enough
#' points, the rate is the mean slope from year 10 to the time it does.
invasion_test <- function(params, effort, t_max = 400, t_inv = 150, init_frac = 1e-6,
                          rare = 1e-3, t_skip = 10) {
    pf <- params; n <- initialN(pf); n["Cod", ] <- 0; initialN(pf) <- n
    C <- equilibrate(pf, effort, t_max = t_max, t_check = 25, tol = 5e-4, floor = 1e-14)
    pc <- C$params
    n <- initialN(pc); n["Cod", ] <- initialN(params)["Cod", ] * init_frac; initialN(pc) <- n
    e <- initial_effort(params); e[names(effort)] <- effort
    inv <- project(pc, effort = e, t_max = t_inv, progress_bar = FALSE)
    list(rate = invasion_rate(inv, getBiomass(params)[["Cod"]], rare, t_skip),
         cod_free = C, inv = inv)
}

invasion_rate <- function(inv, base_biomass, rare = 1e-3, t_skip = 10) {
    B <- getBiomass(inv)[, "Cod"]; tt <- as.numeric(names(B)) - min(as.numeric(names(B)))
    hit <- which(B >= rare * base_biomass & tt >= t_skip)
    t_end <- if (length(hit)) tt[min(hit)] else max(tt)
    sel <- tt >= t_skip & tt <= t_end
    if (sum(sel) >= 3) unname(coef(lm(log(B[sel]) ~ tt[sel]))[2])
    else unname((log(B[tt == t_end]) - log(B[tt == t_skip])) / (t_end - t_skip))
}

# ---------------------------------------------------------------------------
# Diagnostics
# ---------------------------------------------------------------------------

pred_mort_by_predator <- function(params, prey = "Cod", ws = c(0.001, 0.01, 0.1, 1, 10, 100)) {
    w <- w(params)
    pr <- getPredRate(params)
    idx <- (length(params@w_full) - length(w) + 1):length(params@w_full)
    th <- interaction_matrix(params)
    out <- lapply(ws, function(x) {
        i <- which.min(abs(w - x))
        m <- th[, prey] * pr[, idx[i]]
        data.frame(prey = prey, w = w[i], predator = names(m), mortality = unname(m))
    })
    do.call(rbind, out)
}

#' Mortality rates of a species at every size, split by source (1/yr)
mort_components <- function(params, species = "Cod") {
    w <- w(params)
    pr <- getPredRate(params)
    idx <- (length(params@w_full) - length(w) + 1):length(params@w_full)
    th <- interaction_matrix(params)
    pm <- th[, species] * pr[, idx, drop = FALSE]          # predator x size
    em <- ext_mort(params)[species, ]
    bg <- em - species_params(params)[species, "z0"]
    data.frame(w = w,
               forage = colSums(pm[FORAGE, , drop = FALSE]),
               groundfish = colSums(pm[GROUNDFISH, , drop = FALSE]),
               background = pmin(bg, em),
               other_external = em - pmin(bg, em),
               fishing = as.numeric(getFMort(params)[species, ]),
               growth = as.numeric(getEGrowth(params)[species, ]))
}

attr_cfg <- function(params) {
    cfg <- attr(params, "config")
    if (is.null(cfg)) cfg <- default_config()
    cfg
}

#' Pre-recruit (egg/larva/juvenile) mortality budget of a species
#'
#' Follows a cohort from w_lo to w_hi with the growth and mortality rates of
#' the state stored in `params`. Returns the mortality integral by source
#' (int mu/g dw), survival, stage duration (yr), and the fraction of the
#' cohort killed by each source (int mu_k/g S(w) dw).
prerecruit_budget <- function(params, species = "Cod", w_lo = 0.001, w_hi = 1,
                              mc = NULL, growth = NULL) {
    if (is.null(mc)) mc <- mort_components(params, species)
    g <- if (is.null(growth)) mc$growth else growth
    sel <- mc$w >= w_lo & mc$w < w_hi & g > 0
    dw <- dw(params)[sel]; gs <- g[sel]
    src <- c("forage", "groundfish", "background", "other_external", "fishing")
    mu <- as.matrix(mc[sel, src])
    tot <- rowSums(mu)
    Ibin <- tot / gs * dw                      # mortality integral within each bin
    S_before <- exp(-c(0, head(cumsum(Ibin), -1)))
    dying <- S_before * (1 - exp(-Ibin))       # fraction of the cohort dying in each bin
    share <- mu / ifelse(tot > 0, tot, 1)      # share of each source within the bin
    killed <- colSums(share * dying)
    data.frame(w_lo = w_lo, w_hi = w_hi, source = c(src, "total"),
               integral = c(colSums(mu / gs * dw), sum(tot / gs * dw)),
               fraction_killed = c(killed, 1 - exp(-sum(tot / gs * dw))),
               survival = exp(-sum(tot / gs * dw)),
               duration_yr = sum(dw / gs))
}

diet_summary <- function(params, predator = "Cod", min_w = 500, max_w = 5000) {
    diet <- getDiet(params, proportion = TRUE)
    w <- w(params)
    sel <- w >= min_w & w <= max_w
    colMeans(diet[predator, sel, , drop = FALSE][1, , ])
}

resource_level_at <- function(params, ws = c(1e-5, 1e-4, 1e-3, 1e-2, 0.1, 1, 5)) {
    rl <- resource_level(params)
    wf <- params@w_full
    setNames(sapply(ws, function(x) rl[which.min(abs(wf - x))]), ws)
}

#' Fraction of resource production at each size consumed by the fish
resource_consumption_share <- function(params, ws = c(1e-5, 1e-4, 1e-3, 1e-2, 0.1, 1, 5)) {
    mu <- getResourceMort(params)
    rr <- resource_rate(params)
    wf <- params@w_full
    # at a steady state production r(c - N) equals consumption mu N, so the
    # share of gross production r c taken by fish is mu / (r + mu)
    setNames(sapply(ws, function(x) { i <- which.min(abs(wf - x)); mu[i] / (rr[i] + mu[i]) }), ws)
}

# ---------------------------------------------------------------------------
# Historical scenario helpers
# ---------------------------------------------------------------------------

read_effort_history <- function(file = file.path(DATA_DIR, "effort_history.csv")) {
    eh <- read.csv(file, stringsAsFactors = FALSE)
    eh[, c("year", GEARS)]
}

moratorium_effort <- function(eh = read_effort_history()) unlist(eh[nrow(eh), GEARS])

#' Survey-style period ratios from a tidy scenario data frame
#' (mean biomass above the survey cut-off is approximated by total biomass)
period_ratio <- function(df, sp, num = 1995:2004, den = 1980:1989) {
    x <- aggregate(biomass ~ year, data = df[df$species %in% sp, ], sum)
    mean(x$biomass[x$year %in% num]) / mean(x$biomass[x$year %in% den])
}

recovery_metrics <- function(df, base_ssb, base_forage, t0 = 1993) {
    cod <- df[df$species == "Cod", ]
    forage <- aggregate(biomass ~ year, data = df[df$species %in% FORAGE, ], sum)
    after <- cod[cod$year >= t0, ]
    min_i <- which.min(after$ssb)
    yr_min <- after$year[min_i]
    rec50 <- after$year[after$year >= yr_min & after$ssb >= 0.5 * base_ssb]
    rec100 <- after$year[after$year >= yr_min & after$ssb >= base_ssb]
    fa <- forage[forage$year >= t0 & forage$year <= t0 + 32, ]
    data.frame(
        ssb_min_rel = after$ssb[min_i] / base_ssb, year_min = yr_min,
        ssb_2025_rel = if (2025 %in% cod$year) cod$ssb[cod$year == 2025] / base_ssb else NA,
        forage_max_rel_1993_2025 = max(fa$biomass) / base_forage,
        forage_2025_rel = if (2025 %in% forage$year) forage$biomass[forage$year == 2025] / base_forage else NA,
        year_recover50 = if (length(rec50)) min(rec50) else NA,
        year_recover100 = if (length(rec100)) min(rec100) else NA,
        years_to_recover50 = if (length(rec50)) min(rec50) - t0 else NA,
        last_year = max(df$year))
}

# ---------------------------------------------------------------------------
# Plot helpers
# ---------------------------------------------------------------------------

theme_paper <- function(base_size = 11) {
    ggplot2::theme_bw(base_size = base_size) +
        ggplot2::theme(panel.grid.minor = ggplot2::element_blank(),
                       strip.background = ggplot2::element_rect(fill = "grey92"),
                       legend.key.width = ggplot2::unit(1.4, "lines"))
}

save_fig <- function(plot, name, width = 7, height = 5, dir = "figures/v2") {
    dir.create(dir, showWarnings = FALSE)
    ggplot2::ggsave(file.path(dir, paste0(name, ".png")), plot, width = width, height = height, dpi = 300)
    ggplot2::ggsave(file.path(dir, paste0(name, ".pdf")), plot, width = width, height = height)
    invisible(plot)
}
