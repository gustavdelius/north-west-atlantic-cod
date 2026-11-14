# functions.R  (model version 3, the main model)
# ---------------------------------------------------------------------------
# Reusable functions for the eastern Scotian Shelf (NAFO 4VsW) cod model, v3.
# v1 and v2 live in R/v1/ and R/v2/ and are kept unchanged for reference.
#
# v3 = v2 plus ONE explicit assumption under test: an early-life
# vulnerability factor s (s_egg) for predation by forage fish on the eggs,
# larvae and small juveniles of all four groundfish, relative to plankton of
# the same size (interaction-matrix entries forage -> groundfish = s). The
# 1980s baseline is recalibrated WITH that s (calibrate_v3()). s is not
# supported by data; it is the assumption whose consequences are tested.
#
# Inherited from v2 (see results/SUMMARY.md for justification):
#  * resource abundance (kappa = 3) and size-dependent productivity
#    (P/B = 1.41 w^-0.22 /yr) constrained by independent zooplankton biomass
#    and P/B on the Scotian Shelf (Bundy 2004);
#  * early-life background mortality from unmodelled predators, Z/G = 0.5
#    times each species' reference specific growth rate, tapered above 1 g,
#    so most egg-to-juvenile mortality is explicit rather than hidden in
#    erepro;
#  * low Beverton-Holt reproduction levels (0.1) for groundfish; forage-fish
#    reproduction level calibrated so that the documented-F hindcast
#    reproduces the observed forage boom;
#  * one gear per groundfish species plus one pelagic gear.
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
DATA_DIR <- "data/v3"

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
        kappa_path = 3,           # (no continuation)
        r_pp = 1,                 # resource replenishment used during calibration (w^-1/3)
        rr_coef = 1.41,           # final resource P/B = rr_coef * w^rr_exp, fitted to Bundy (2004):
        rr_exp = -0.22,           #   8.4 /yr at 0.3 mg (copepods), 3.04 /yr at 30 mg (euphausiids)
        s_egg = 20,               # ASSUMPTION UNDER TEST: forage -> groundfish early-life vulnerability
        s_prey = GROUNDFISH,      # groundfish whose early life stages it applies to
        repro_cod = 0.1,          # Beverton-Holt reproduction level, cod
        repro_groundfish = 0.1,   # haddock, silver hake, plaice
        repro_forage = 0.3,       # herring, sand lance, capelin (recalibrated to the boom in 01)
        background = TRUE,        # early-life background mortality (unmodelled predators)
        bg_MG = 0.5,              # mortality : specific-growth ratio of the background (Z/G)
        bg_taper_w = 1,           # g; background mortality tapers off above ~1 g
        no_w = 120,
        effort = c(cod = 0.40, haddock = 0.30, silver_hake = 0.30, plaice = 0.30, pelagic = 0.10),
        biomass_tol = 0.10,
        max_iter = 12,
        proj_rounds = 25)
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
    im[FORAGE, cfg$s_prey] <- cfg$s_egg
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
    im <- interaction_matrix(params); im[FORAGE, cfg$s_prey] <- s_egg
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

#' Refine a calibration by projecting the full dynamics (v3; superseded by
#' calibrate_v3n(): the full projection drifted for centuries and never settled)
#'
#' Each round: scale every species' abundance part of the way towards its
#' target (damped matchBiomasses), re-match growth to age at maturity,
#' re-derive the Beverton-Holt parameters at the configured reproduction
#' levels for that state, then project the full model (reproduction and
#' resource free) to its own steady state. Keeps the best steady state whose
#' erepro are all < 1. Avoids the jumps of the Newton solver seen in v2.
refine_by_projection <- function(params, cfg = default_config(), rounds = cfg$proj_rounds,
                                 damp = 0.7, t_max = 300, verbose = TRUE) {
    old <- options(mizer_info_level = 0); on.exit(options(old))
    sp_names <- species_params(params)$species
    rl <- repro_levels(cfg, sp_names)
    settle <- function(p) {
        q <- tryCatch(findSteadyState(p, solver = "project", t_max = t_max, dt = 0.1,
                                      progress_bar = FALSE),
                      error = function(e) NULL)
        q
    }
    cur <- settle(params)
    if (is.null(cur)) cur <- params
    score <- function(p) max(abs(biomass_error(p)))
    best <- cur; best_err <- score(cur)
    for (k in seq_len(rounds)) {
        p <- match_biomass_damped(cur, damp)
        p <- refresh_bg(safe_match_growth(p), cfg)
        reproduction_level(p) <- rl
        q <- settle(p)
        if (is.null(q)) { damp <- damp / 2; next }
        err <- score(q)
        ok <- identical(attr(q, "convergence")$attractor, "fixed_point") &&
            all(species_params(q)$erepro < 1) && is.finite(err)
        if (verbose) cat(sprintf("  projection round %d (damp %.2f): max |error| %.3f, attractor %s, max erepro %.3g\n",
                                 k, damp, err, attr(q, "convergence")$attractor,
                                 max(species_params(q)$erepro)))
        if (ok) {
            cur <- q
            if (err < best_err) { best <- q; best_err <- err }
            if (best_err < cfg$biomass_tol) break
        } else {
            cur <- best; damp <- damp / 2
        }
    }
    best
}

#' Settle with births and resource pinned, project solver only (no Newton
#' jumps). Returns NULL if the run did not end on a fixed point.
tune_ss_project <- function(params, t_max = 400) {
    p2 <- tryCatch(suppressWarnings(tuneSteadyState(params, solver = "project", t_max = t_max,
                                                    progress_bar = FALSE)),
                   error = function(e) NULL)
    p2
}

#' Did tuneSteadyState() settle? Either a fixed point by its drift test, or
#' the search met its distance and drift tolerances with births and resource
#' pinned (after re-deriving erepro the instantaneous drift of the smallest
#' size classes can exceed 0.05/yr although a projection barely moves; the
#' final model is checked by projection in 01).
settled <- function(q) {
    !is.null(q) && (identical(attr(q, "convergence")$attractor, "fixed_point") ||
                        identical(attr(q, "convergence")$termination, "residual_tolerance"))
}

#' Match all biomasses simultaneously (v3)
#'
#' The species are strongly coupled (predation), so matchBiomasses() followed
#' by tuneSteadyState() overshoots and oscillates. Here the unknowns are the
#' log factors x by which each species' spectrum (and with R_max = Inf its
#' recruitment) is scaled before tuneSteadyState() re-settles the model with
#' recruitment and resource pinned; the residual is log(B / B_observed). The
#' system is solved by Newton's method with a finite-difference Jacobian and
#' step halving. Each evaluation is one tuneSteadyState(solver = "project").
solve_biomasses <- function(p0, iters = 8, tol = 0.02, h = 0.05, verbose = TRUE) {
    sp <- species_params(p0)
    target <- sp$biomass_observed
    eval_x <- function(x) {
        p <- p0
        n <- initialN(p); n[] <- sweep(unclass(n), 1, exp(x), "*"); initialN(p) <- n
        q <- tune_ss_project(p)
        if (!settled(q)) return(NULL)
        b <- getBiomass(q, min_w = sp$biomass_cutoff)
        r <- log(b / target)
        if (!all(is.finite(r))) return(NULL)
        list(q = q, r = r)
    }
    # start from the log mismatch of p0 itself (one matchBiomasses step)
    b0 <- getBiomass(p0, min_w = sp$biomass_cutoff)
    x <- -log(b0 / target)
    cur <- eval_x(x)
    if (is.null(cur)) { x <- 0 * x; cur <- eval_x(x) }
    if (is.null(cur)) stop("solve_biomasses: initial tuneSteadyState failed")
    nsp <- length(x)
    for (it in seq_len(iters)) {
        if (verbose) cat(sprintf("    newton %d: max |log error| %.3f | %s\n", it, max(abs(cur$r)),
                                 paste(round(cur$r, 3), collapse = " ")))
        if (max(abs(cur$r)) < tol) break
        J <- matrix(NA_real_, nsp, nsp)
        for (j in seq_len(nsp)) {
            xj <- x; xj[j] <- xj[j] + h
            ej <- eval_x(xj)
            J[, j] <- if (is.null(ej)) 0 else (ej$r - cur$r) / h
            if (is.null(ej)) J[j, j] <- 1
        }
        step <- tryCatch(-solve(J, cur$r), error = function(e) -cur$r)
        step <- step * min(1, 1.5 / max(abs(step)))     # trust region: at most x4.5 per step
        lam <- 1; acc <- FALSE
        while (lam > 0.05) {
            new <- eval_x(x + lam * step)
            if (!is.null(new) && sum(new$r^2) < sum(cur$r^2)) { acc <- TRUE; break }
            lam <- lam / 2
        }
        if (!acc) { if (verbose) cat("    newton: no descent step found\n"); break }
        x <- x + lam * step; cur <- new
    }
    out <- cur$q
    attr(out, "log_error") <- cur$r
    out
}

#' Rescale growth to age at maturity without touching the spectra
#'
#' Multiplies gamma, h, ks and k of each species by age_mat(model) /
#' age_mat(target). This is the rescaling matchGrowth() does (feeding level
#' unchanged, growth proportional to the factor) but without its final
#' steadySingleSpecies() call, which in this model produced degenerate
#' spectra (one species x20, others extinct). The background early-life
#' mortality is refreshed because it is tied to each species' growth.
scale_growth <- function(params, cfg = default_config()) {
    sp <- species_params(params)
    fac <- as.numeric(age_mat(params)) / sp$age_mat
    fac[!is.finite(fac)] <- 1
    for (col in c("gamma", "h", "ks", "k")) {
        if (!is.null(sp[[col]])) {
            v <- sp[[col]]; ok <- !is.na(v)
            v[ok] <- v[ok] * fac[ok]
            species_params(params)[[col]] <- v
        }
    }
    refresh_bg(params, cfg)
}

#' v3 calibration: Newton biomass matching alternated with growth rescaling
calibrate_v3n <- function(params, cfg = default_config(), outer = 3, s_path = cfg$s_egg,
                          tol = 0.02, growth_tol = 0.05, verbose = TRUE) {
    old <- options(mizer_info_level = 0); on.exit(options(old))
    sp_names <- species_params(params)$species
    suppressWarnings(reproduction_level(params) <- setNames(rep(0, length(sp_names)), sp_names))
    for (s in s_path) {
        im <- interaction_matrix(params); im[FORAGE, cfg$s_prey] <- s
        interaction_matrix(params) <- im
        q <- tune_ss_project(params); if (settled(q)) params <- q
        n_out <- if (s == tail(s_path, 1)) outer else 1
        for (o in seq_len(n_out)) {
            if (verbose) cat(sprintf("  s %g, outer round %d\n", s, o))
            params <- solve_biomasses(params, tol = tol, verbose = verbose)
            am_err <- as.numeric(age_mat(params)) / species_params(params)$age_mat - 1
            if (verbose) cat(sprintf("    erepro: %s\n    age_mat error: %s\n",
                                     paste(signif(species_params(params)$erepro, 2), collapse = " "),
                                     paste(round(am_err, 3), collapse = " ")))
            if (max(abs(am_err), na.rm = TRUE) < growth_tol) break
            q <- tune_ss_project(scale_growth(params, cfg))
            if (settled(q)) params <- q
        }
    }
    conv <- attr(params, "convergence")
    reproduction_level(params) <- repro_levels(cfg, sp_names)
    attr(params, "convergence") <- conv
    params
}

#' Rebuild a calibrated model on a different size grid (numerical check)
#'
#' New MizerParams from the calibrated species parameters, interaction
#' matrix, gears and resource (abundance interpolated onto the new grid),
#' then recalibrated to the same targets with calibrate_v3n() at the same s.
rebuild_on_grid <- function(params, no_w, cfg = default_config(), verbose = FALSE) {
    old <- options(mizer_info_level = 0); on.exit(options(old))
    defaults_edition(3)
    sp <- species_params(params)
    sp$R_max <- Inf
    rp <- resource_params(params)
    p <- newMultispeciesParams(sp, interaction = interaction_matrix(params), no_w = no_w,
                               min_w = min(w(params)), max_w = max(w(params)),
                               min_w_pp = min(params@w_full),
                               kappa = rp$kappa, n = rp$n, lambda = rp$lambda,
                               w_pp_cutoff = rp$w_pp_cutoff, resource_rate = cfg$r_pp,
                               gear_params = gear_params(params),
                               initial_effort = initial_effort(params))
    nr <- initialNResource(params); ok <- nr > 0
    nr_new <- exp(approx(log(params@w_full[ok]), log(nr[ok]), xout = log(p@w_full), rule = 2)$y)
    nr_new[p@w_full > max(params@w_full[ok])] <- 0
    initialNResource(p) <- nr_new
    p <- set_resource_rate(p, cfg)
    p <- refresh_bg(p, cfg)
    p <- safe_sss(p)
    s <- interaction_matrix(params)[FORAGE[1], "Cod"]
    p <- calibrate_v3n(p, cfg, outer = 3, s_path = s, verbose = verbose)
    reproduction_level(p) <- reproduction_level(params)
    p
}

#' v3 calibration loop (plain iteration; superseded by calibrate_v3n, which
#' converges where this oscillates)
#'
#' The standard mizer loop (matchBiomasses -> matchGrowth -> tuneSteadyState)
#' but with density-independent recruitment (R_max = Inf) while iterating.
#' tuneSteadyState() pins each species' recruitment at its current value; with
#' R_max = Inf that value scales exactly with the abundance factor applied by
#' matchBiomasses(), so the loop does not fight itself (in v2, with
#' reproduction level 0.1 during the loop, it oscillated). The project solver
#' is used throughout. At the end the Beverton-Holt density dependence is
#' imposed at the configured reproduction levels (reproduction_level<-), which
#' leaves the steady state unchanged. An optional `s_path` steps the
#' early-life vulnerability factor up gradually (continuation).
calibrate_v3 <- function(params, cfg = default_config(), rounds = 20, s_path = cfg$s_egg,
                         tol = 0.03, verbose = TRUE) {
    old <- options(mizer_info_level = 0); on.exit(options(old))
    sp_names <- species_params(params)$species
    suppressWarnings(reproduction_level(params) <- setNames(rep(0, length(sp_names)), sp_names))
    hist <- list()
    for (s in s_path) {
        im <- interaction_matrix(params); im[FORAGE, cfg$s_prey] <- s
        interaction_matrix(params) <- im
        q <- tune_ss_project(params)
        if (!is.null(q)) params <- q
        n_r <- if (s == tail(s_path, 1)) rounds else 3
        for (k in seq_len(n_r)) {
            p <- matchBiomasses(params)
            p <- refresh_bg(safe_match_growth(p), cfg)
            q <- tune_ss_project(p)
            if (is.null(q)) { if (verbose) cat("  tuneSteadyState failed\n"); break }
            params <- q
            err <- biomass_error(params)
            conv <- attr(params, "convergence")
            hist[[length(hist) + 1]] <- data.frame(s = s, round = k, species = sp_names,
                                                   error = as.numeric(err),
                                                   erepro = species_params(params)$erepro,
                                                   attractor = as.character(conv$attractor))
            if (verbose) cat(sprintf("  s %g round %d: max |error| %.3f, attractor %s, max erepro %.3g | %s\n",
                                     s, k, max(abs(err)), conv$attractor,
                                     max(species_params(params)$erepro),
                                     paste(round(err, 3), collapse = " ")))
            if (max(abs(err)) < tol && identical(conv$attractor, "fixed_point")) break
        }
    }
    conv <- attr(params, "convergence")
    reproduction_level(params) <- repro_levels(cfg, sp_names)
    attr(params, "convergence") <- conv
    attr(params, "calibration_history") <- do.call(rbind, hist)
    params
}

#' Calibrate by projection, adjusting reproductive efficiency (v3; failed:
#' with R_max = Inf the free projection is winner-take-all, kept for the record)
#'
#' Recruitment is density-independent during calibration (R_max = Inf) and
#' each species' erepro is the knob: each round projects the full model to
#' its own steady state (t_max years) and multiplies erepro_i by
#' (target_i / B_i)^gain; growth is re-matched to age at maturity every
#' `growth_every` rounds. At the end Beverton-Holt density dependence is
#' imposed at the configured reproduction levels with setBevertonHolt(),
#' which leaves the steady state unchanged. Time-boxed by `rounds`; returns
#' the best state (all erepro < 1) and a history of the rounds.
calibrate_erepro_projection <- function(params, cfg = default_config(), rounds = 30,
                                        gain = 1.5, t_max = 400, growth_every = 5,
                                        verbose = TRUE) {
    old <- options(mizer_info_level = 0); on.exit(options(old))
    sp <- species_params(params)
    species_params(params)$R_max <- Inf
    best <- NULL; best_err <- Inf; hist <- list()
    p <- params
    for (k in seq_len(rounds)) {
        sim <- project(p, t_max = t_max, t_save = t_max / 4, progress_bar = FALSE)
        q <- finalParams(sim)
        B <- getBiomass(sim)
        drift <- max(abs(log(B[nrow(B), ] / B[nrow(B) - 1, ]))) / (t_max / 4)
        err <- biomass_error(q)
        e <- species_params(q)$erepro
        hist[[k]] <- data.frame(round = k, species = names(err), error = as.numeric(err),
                                erepro = e, drift = drift)
        me <- max(abs(err))
        if (verbose) cat(sprintf("  erepro round %d: max |error| %.3f, drift %.2g /yr, max erepro %.3g | %s\n",
                                 k, me, drift, max(e), paste(round(err, 2), collapse = " ")))
        if (all(e < 1) && drift < 0.01 && me < best_err) { best <- q; best_err <- me }
        if (best_err < cfg$biomass_tol) break
        fac <- pmin(pmax((1 / (1 + err))^gain, 0.2), 5)
        species_params(q)$erepro <- e * fac
        if (k %% growth_every == 0) q <- refresh_bg(safe_match_growth(q), cfg)
        p <- q
    }
    if (is.null(best)) best <- q
    reproduction_level(best) <- repro_levels(cfg, species_params(best)$species)
    attr(best, "calibration_history") <- do.call(rbind, hist)
    best
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
#' @param params MizerParams with the model parameters (e.g. readParams("models/baseline_params.rds")).
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
                        t_check = 20, tol = 1e-3, floor = 1e-8, dt = 0.1, method = "euler") {
    p <- set_state(params, initial)
    gears <- names(initial_effort(params))
    e <- initial_effort(params); e[names(effort)] <- effort
    t <- 0; hist <- list(); rate <- Inf
    repeat {
        sim <- project(p, effort = e[gears], t_max = t_check, dt = dt, method = method,
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
                          rare = 1e-3, t_skip = 10, dt = 0.1, method = "euler") {
    pf <- params; n <- initialN(pf); n["Cod", ] <- 0; initialN(pf) <- n
    C <- equilibrate(pf, effort, t_max = t_max, t_check = 25, tol = 5e-4, floor = 1e-14,
                     dt = dt, method = method)
    pc <- C$params
    n <- initialN(pc); n["Cod", ] <- initialN(params)["Cod", ] * init_frac; initialN(pc) <- n
    e <- initial_effort(params); e[names(effort)] <- effort
    inv <- project(pc, effort = e, t_max = t_inv, dt = dt, method = method, progress_bar = FALSE)
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

#' Invasion-rate fit with its diagnostics (rate, R^2, window, points)
invasion_fit <- function(inv, base_biomass, rare = 1e-3, t_skip = 10) {
    B <- getBiomass(inv)[, "Cod"]; tt <- as.numeric(names(B)) - min(as.numeric(names(B)))
    hit <- which(B >= rare * base_biomass & tt >= t_skip)
    t_end <- if (length(hit)) tt[min(hit)] else max(tt)
    sel <- tt >= t_skip & tt <= t_end
    if (sum(sel) < 3) return(data.frame(rate = invasion_rate(inv, base_biomass, rare, t_skip),
                                        r2 = NA, t_start = t_skip, t_end = t_end, n = sum(sel)))
    m <- lm(log(B[sel]) ~ tt[sel])
    data.frame(rate = unname(coef(m)[2]), r2 = summary(m)$r.squared,
               t_start = t_skip, t_end = t_end, n = sum(sel))
}

#' Equilibrium cod SSB over a range of cod F (other gears as in `effort`),
#' continued from the previous equilibrium (increasing F)
cod_F_sweep <- function(params, effort, Fs = seq(0.4, 1.6, by = 0.1), t_max = 300) {
    p <- params; out <- list()
    for (Fc in Fs) {
        e <- effort; e["cod"] <- Fc
        eq <- equilibrate(p, e, t_max = t_max, t_check = 25, tol = 5e-4)
        p <- eq$params; initial_effort(p) <- e
        out[[length(out) + 1]] <- data.frame(F_cod = Fc, converged = eq$converged,
                                             cod_ssb = getSSB(p)[["Cod"]],
                                             cod_yield = getYield(p)[["Cod"]])
    }
    do.call(rbind, out)
}

#' Alternative hypothesis: adult cod (>= l_adult cm) natural mortality raised
#' to M_adult (predation by fish species in the model is counted towards it;
#' the remainder is added as external mortality). Changes a parameter, so
#' runs using it are labelled as the elevated-adult-M alternative.
elevate_M <- function(p, M_adult = 0.8, l_adult = 35) {
    sp <- species_params(p)
    w_adult <- sp["Cod", "a"] * l_adult^sp["Cod", "b"]
    pm <- getPredMort(p)["Cod", ]
    em <- ext_mort(p)
    big <- w(p) >= w_adult
    em["Cod", big] <- pmax(em["Cod", big], M_adult - pm[big])
    ext_mort(p) <- em
    p
}

#' Switch the assumption under test off: forage -> groundfish interaction 1
s_off <- function(p) {
    im <- interaction_matrix(p); im[FORAGE, GROUNDFISH] <- 1; interaction_matrix(p) <- im; p
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

save_fig <- function(plot, name, width = 7, height = 5, dir = "figures") {
    dir.create(dir, showWarnings = FALSE)
    ggplot2::ggsave(file.path(dir, paste0(name, ".png")), plot, width = width, height = height, dpi = 300)
    ggplot2::ggsave(file.path(dir, paste0(name, ".pdf")), plot, width = width, height = height)
    invisible(plot)
}
