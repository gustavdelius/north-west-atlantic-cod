# functions.R
# ---------------------------------------------------------------------------
# Reusable functions for the eastern Scotian Shelf (NAFO 4VsW) cod model.
#
# The central function is run_scenario(): it projects a MizerParams object from
# a given initial state under per-gear effort trajectories and returns a tidy
# data frame of yearly biomass, SSB, yield and fishing mortality by species.
# It has no side effects (no files written, no global state changed), so it can
# be called in parallel for grids of policy scenarios.
#
# Units: grams per square metre (g m^-2) of shelf area, years.
# 1 g m^-2 over the 4VsW shelf area of 1.1e5 km^2 (DFO 2010) is 110 kt
# (see data/species_params_sources.md for the area and its uncertainty).
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
    library(mizer)
})

# Shelf area used to convert g m^-2 to tonnes (assumption, see sources file)
SHELF_AREA_KM2 <- 1.1e5
gm2_to_kt <- function(x) x * SHELF_AREA_KM2 * 1e6 / 1e9   # g/m2 -> kt

FORAGE <- c("Herring", "Sand lance", "Capelin")
GROUNDFISH <- c("Cod", "Haddock", "Silver hake", "American plaice")
GEARS <- c("cod", "groundfish", "pelagic")

# Colour-blind-safe palette (Okabe-Ito) for species, used in all figures
SPECIES_COLOURS <- c(
    "Cod" = "#000000",
    "Haddock" = "#E69F00",
    "Silver hake" = "#56B4E9",
    "American plaice" = "#009E73",
    "Herring" = "#0072B2",
    "Sand lance" = "#D55E00",
    "Capelin" = "#CC79A7",
    "Forage fish" = "#D55E00",
    "Resource" = "#999999")

# ---------------------------------------------------------------------------
# Model construction and calibration
# ---------------------------------------------------------------------------

#' Default model configuration. Every non-default choice is documented in
#' results/SUMMARY.md and data/species_params_sources.md.
default_config <- function() {
    list(
        kappa = 1.4,              # resource coefficient (g m^-2 at 1 g, per g^(1-lambda))
        kappa_path = c(3, 1.7),   # continuation path to kappa (calibration is robust at 3)
        r_pp = 2,                 # resource replenishment coefficient (yr^-1 g^(1/3))
        s_egg = 1,                # forage -> cod interaction (egg/larval predation selectivity)
        repro_cod = 0.5,          # Beverton-Holt reproduction level of cod
        repro_groundfish = 0.75,  # reproduction level of haddock, silver hake, plaice
        repro_forage = 0.5,       # reproduction level of herring, sand lance, capelin
        no_w = 120,               # number of consumer size bins
        effort = c(cod = 0.40, groundfish = 0.30, pelagic = 0.10),
        biomass_tol = 0.03,       # relative tolerance for matching observed biomass
        max_iter = 12)
}

#' Named vector of Beverton-Holt reproduction levels from a configuration
repro_levels <- function(cfg, species) {
    rl <- setNames(rep(cfg$repro_groundfish, length(species)), species)
    rl[intersect(FORAGE, species)] <- cfg$repro_forage
    rl["Cod"] <- cfg$repro_cod
    rl
}

read_inputs <- function(dir = "data") {
    sp <- read.csv(file.path(dir, "species_params.csv"), stringsAsFactors = FALSE)
    gp <- read.csv(file.path(dir, "gear_params.csv"), stringsAsFactors = FALSE)
    im <- as.matrix(read.csv(file.path(dir, "interaction_matrix.csv"),
                             row.names = 1, check.names = FALSE))
    list(sp = sp, gp = gp, im = im)
}

#' One round of: steady state (Newton, falling back to projection) with
#' reproduction and resource held, then report the convergence.
tune_ss <- function(params) {
    p2 <- tryCatch(suppressWarnings(tuneSteadyState(params, solver = "newton")),
                   error = function(e) NULL)
    if (is.null(p2) || !identical(attr(p2, "convergence")$attractor, "fixed_point")) {
        p2 <- tuneSteadyState(params, t_max = 500)
    }
    p2
}

#' matchGrowth() keeping biomass, falling back to keeping the egg density if
#' the single-species steady state of some species cannot be rescaled (this
#' happens erratically on intermediate calibration states, see
#' notes/mizer-issues.md); the biomass is then re-matched by the caller.
safe_match_growth <- function(params) {
    ok <- function(p) !is.null(p) && all(is.finite(initialN(p))) &&
        all(is.finite(suppressWarnings(age_mat(p))))
    for (keep in c("biomass", "egg")) {
        p2 <- tryCatch(matchGrowth(params, keep = keep), error = function(e) NULL)
        if (ok(p2)) return(p2)
    }
    params
}

#' steadySingleSpecies() with the same safeguards
safe_sss <- function(params) {
    for (keep in c("biomass", "egg")) {
        p2 <- tryCatch(steadySingleSpecies(params, keep = keep), error = function(e) NULL)
        if (!is.null(p2) && all(is.finite(initialN(p2)))) return(p2)
    }
    params
}

#' Relative error of modelled vs observed biomass (above the cutoff)
biomass_error <- function(params) {
    sp <- species_params(params)
    b <- getBiomass(params, min_w = sp$biomass_cutoff)
    (b - sp$biomass_observed) / sp$biomass_observed
}

#' Build and calibrate the model
#'
#' 1. newMultispeciesParams() at a weakly coupled resource level
#'    (kappa_path[1]), single-species steady states, growth matched to age at
#'    maturity (matchGrowth).
#' 2. Continuation in the resource coefficient kappa down to cfg$kappa: at
#'    each step the search-volume coefficients are rescaled by kappa_old /
#'    kappa_new (so feeding levels are approximately preserved), the resource
#'    abundance by kappa_new / kappa_old, and the model is re-tuned.
#' 3. Iterate matchBiomasses / matchGrowth / tuneSteadyState until biomasses
#'    are within cfg$biomass_tol of the observations.
#' 4. Reproduction levels are set before the final loop and preserved by
#'    tuneSteadyState().
build_model <- function(cfg = default_config(), dir = "data", verbose = TRUE) {
    old <- options(mizer_info_level = 0); on.exit(options(old))
    defaults_edition(3)
    inp <- read_inputs(dir)
    sp <- inp$sp
    sp$latin <- NULL; sp$group <- NULL; sp$source_note <- NULL
    im <- inp$im[sp$species, sp$species]
    im[FORAGE, "Cod"] <- cfg$s_egg
    k0 <- cfg$kappa_path[1]
    params <- newMultispeciesParams(sp, interaction = im, gear_params = inp$gp,
                                    no_w = cfg$no_w, kappa = k0,
                                    resource_rate = cfg$r_pp,
                                    initial_effort = 0)
    # Single-species shapes and growth are first set up without fishing (this
    # initial stage is numerically fragile; see notes/mizer-issues.md), then
    # the baseline effort is switched on before the first multispecies tune.
    for (i in 1:3) {
        p2 <- safe_sss(safe_match_growth(params))
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
            resource_params(params)$kappa <- k   # bookkeeping; capacity rebalanced by tune
            kold <- k
        }
        for (i in 1:3) {
            params <- tune_ss(params)
            params <- matchBiomasses(params)
            params <- safe_match_growth(params)
        }
        params <- tune_ss(params)
        if (verbose) cat(sprintf("kappa %.2f: max |biomass error| %.3f\n", k,
                                 max(abs(biomass_error(params)))))
    }
    for (i in seq_len(cfg$max_iter)) {
        err <- biomass_error(params)
        if (max(abs(err)) < cfg$biomass_tol) break
        params <- matchBiomasses(params)
        params <- safe_match_growth(params)
        params <- tune_ss(params)
    }
    # matchBiomasses() re-derives the Beverton-Holt parameters and so moves the
    # reproduction levels; restore the configured ones (this leaves the steady
    # state unchanged and re-derives erepro and R_max).
    conv <- attr(params, "convergence")
    reproduction_level(params) <- repro_levels(cfg, sp$species)
    attr(params, "convergence") <- conv
    if (verbose) cat(sprintf("final: %d iterations, max |biomass error| %.3f, attractor %s\n",
                             i, max(abs(biomass_error(params))), conv$attractor))
    attr(params, "config") <- cfg
    params
}

# ---------------------------------------------------------------------------
# Effort trajectories
# ---------------------------------------------------------------------------

#' Build a time x gear effort array for project()
#'
#' @param effort Either a data frame with a column `year` and one column per
#'   gear (piecewise constant: the value in year y applies from y to the next
#'   listed year), or a named numeric vector of constant efforts per gear.
#' @param years Integer vector c(start, end). Required when `effort` is a
#'   vector; otherwise defaults to the range of `effort$year`, extended to
#'   `end` if given.
#' @param gears Gear names of the model, in model order.
#' @param default Named vector of efforts for gears missing from `effort`.
#' @return A matrix with dimnames list(time = years, gear = gears), one row
#'   per year from start to end (the last row only marks the end time).
effort_array <- function(effort, gears, years = NULL, default = NULL) {
    if (is.data.frame(effort)) {
        if (is.null(years)) years <- range(effort$year)
        yrs <- seq(years[1], years[2])
        arr <- matrix(NA_real_, nrow = length(yrs), ncol = length(gears),
                      dimnames = list(time = yrs, gear = gears))
        effort <- effort[order(effort$year), , drop = FALSE]
        for (g in gears) {
            if (g %in% names(effort)) {
                # piecewise constant: value from the latest listed year <= y
                idx <- findInterval(yrs, effort$year)
                if (any(idx == 0)) stop("effort data frame must start at or before ", years[1])
                arr[, g] <- effort[[g]][idx]
            } else {
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

# ---------------------------------------------------------------------------
# Setting the initial state
# ---------------------------------------------------------------------------

#' Return `params` with its state (fish and resource) replaced by `initial`
#'
#' @param initial NULL (keep), a MizerParams (use its stored state) or a
#'   MizerSim (use its final state). Parameters are always taken from `params`.
set_state <- function(params, initial = NULL) {
    if (is.null(initial)) return(params)
    if (inherits(initial, "MizerSim")) initial <- finalParams(initial)
    stopifnot(inherits(initial, "MizerParams"))
    initialN(params) <- initialN(initial)
    initialNResource(params) <- initialNResource(initial)
    params
}

# ---------------------------------------------------------------------------
# The scenario runner
# ---------------------------------------------------------------------------

#' Run a fishing scenario and return tidy yearly output
#'
#' @param params MizerParams holding the model parameters (the baseline model).
#' @param effort Effort trajectory: a data frame with column `year` plus one
#'   column per gear (piecewise constant), or a named vector of constant
#'   efforts (then give `years`). Gears not given are held at
#'   `initial_effort(params)`.
#' @param years c(start, end) calendar years.
#' @param initial Initial state: NULL (state stored in params), a MizerParams
#'   or a MizerSim (its final state).
#' @param dt Time step (years).
#' @param method Time-stepping method passed to project().
#' @param return_sim If TRUE, return list(data = <tidy df>, sim = <MizerSim>).
#' @return A data frame with columns year, species, biomass, ssb, yield,
#'   F (fishing mortality on fully selected sizes, summed over gears),
#'   n_juv (number density of 1-10 g juveniles, m^-2) and, for species =
#'   "Resource", biomass of the plankton resource < 0.01 g. Biomass, SSB and
#'   yield are in g m^-2 and g m^-2 yr^-1.
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

#' Tidy yearly summary of a MizerSim (used by run_scenario)
tidy_sim <- function(sim) {
    params <- getParams(sim)
    sp <- species_params(params)$species
    times <- getTimes(sim)
    B <- getBiomass(sim)
    S <- getSSB(sim)
    Y <- getYield(sim)
    Nj <- getN(sim, min_w = 1, max_w = 10)
    eff <- getEffort(sim)
    Q <- catchability(params)                 # gear x species
    Fful <- eff %*% Q[colnames(eff), sp, drop = FALSE]   # time x species
    out <- data.frame(
        year = rep(times, times = length(sp)),
        species = rep(sp, each = length(times)),
        biomass = as.vector(B[, sp]),
        ssb = as.vector(S[, sp]),
        yield = as.vector(Y[, sp]),
        F = as.vector(Fful[, sp]),
        n_juv = as.vector(Nj[, sp]),
        stringsAsFactors = FALSE)
    # plankton resource biomass below 0.01 g
    wf <- params@w_full
    dwf <- params@dw_full
    sel <- wf < 0.01
    nr <- NResource(sim)
    res <- data.frame(year = times, species = "Resource",
                      biomass = as.vector(nr[, sel, drop = FALSE] %*% (wf[sel] * dwf[sel])),
                      ssb = NA_real_, yield = NA_real_, F = NA_real_, n_juv = NA_real_)
    rbind(out, res)
}

# ---------------------------------------------------------------------------
# Long-run equilibria
# ---------------------------------------------------------------------------

#' Project at constant effort until the biomasses stop changing
#'
#' Unlike projectUntilSettled() this does not stop when a species declines
#' towards zero, so a slowly collapsing species is followed until it has
#' either settled or reached `t_max`. Convergence criterion: over the last
#' `t_check` years the largest relative rate of change of any species'
#' biomass (computed on log biomass, ignoring species below `floor`) is below
#' `tol` per year.
#'
#' @return list(params = MizerParams holding the final state, sim = last
#'   chunk, years = years run, rate = final max relative rate of change,
#'   converged = logical, biomass = final biomass vector, history =
#'   data frame of biomass at every t_check years)
equilibrate <- function(params, effort, initial = NULL, t_max = 600,
                        t_check = 20, tol = 1e-3, floor = 1e-8, dt = 0.1) {
    p <- set_state(params, initial)
    gears <- names(initial_effort(params))
    e <- initial_effort(params)
    e[names(effort)] <- effort
    t <- 0
    hist <- list()
    rate <- Inf
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

#' Per-capita (log) growth rate of cod biomass over the last part of a run
#' Used to quantify whether the collapsed state is an attractor (negative
#' rate) or a slow transient (positive rate) when cod is very rare.
log_growth_rate <- function(sim, species = "Cod", years = 50) {
    B <- getBiomass(sim)[, species]
    tt <- as.numeric(names(B))
    sel <- tt >= max(tt) - years
    unname(coef(lm(log(B[sel]) ~ tt[sel]))[2])
}

# ---------------------------------------------------------------------------
# Diagnostics of a steady state
# ---------------------------------------------------------------------------

#' Predation mortality on prey species `prey` at sizes `ws`, split by predator
#' @return data frame prey_w x predator with mortality rates (1/yr)
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

#' Diet composition (proportions) of a predator averaged over a size range
diet_summary <- function(params, predator = "Cod", min_w = 500, max_w = 5000) {
    diet <- getDiet(params, proportion = TRUE)
    w <- w(params)
    sel <- w >= min_w & w <= max_w
    colMeans(diet[predator, sel, , drop = FALSE][1, , ])
}

#' Resource level (abundance / capacity) at chosen sizes
resource_level_at <- function(params, ws = c(1e-4, 1e-3, 1e-2, 0.1, 1)) {
    rl <- resource_level(params)
    wf <- params@w_full
    setNames(sapply(ws, function(x) rl[which.min(abs(wf - x))]), ws)
}

#' Fraction of cod eggs/larvae (1 mg to 0.1 g) killed by forage fish, and the
#' corresponding mortality integral, for the state stored in `params`.
cod_early_forage_kill <- function(params, w_lo = 0.001, w_hi = 0.1) {
    w <- w(params)
    pr <- getPredRate(params)
    idx <- (length(params@w_full) - length(w) + 1):length(params@w_full)
    th <- interaction_matrix(params)
    mf <- colSums(th[FORAGE, "Cod"] * pr[FORAGE, idx, drop = FALSE])
    g <- getEGrowth(params)["Cod", ]
    sel <- w >= w_lo & w <= w_hi & g > 0
    I <- sum(mf[sel] / g[sel] * params@dw[sel])
    c(integral = I, fraction = 1 - exp(-I))
}

# ---------------------------------------------------------------------------
# Historical scenario helpers
# ---------------------------------------------------------------------------

read_effort_history <- function(file = "data/effort_history.csv") {
    eh <- read.csv(file, stringsAsFactors = FALSE)
    eh[, c("year", GEARS)]
}

#' Constant moratorium effort = last row of the effort history
moratorium_effort <- function(eh = read_effort_history()) {
    unlist(eh[nrow(eh), GEARS])
}

#' Recovery metrics from a tidy scenario data frame
#'
#' @param df output of run_scenario() (may span many years)
#' @param base_ssb baseline (steady-state) cod SSB
#' @param base_forage baseline total forage biomass
#' @param t0 year from which recovery is counted (moratorium 1993)
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
        ssb_min_rel = after$ssb[min_i] / base_ssb,
        year_min = yr_min,
        ssb_2025_rel = cod$ssb[cod$year == 2025] / base_ssb,
        forage_max_rel_1993_2025 = max(fa$biomass) / base_forage,
        forage_2025_rel = forage$biomass[forage$year == 2025] / base_forage,
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

save_fig <- function(plot, name, width = 7, height = 5, dir = "figures/v1") {
    dir.create(dir, showWarnings = FALSE)
    ggplot2::ggsave(file.path(dir, paste0(name, ".png")), plot,
                    width = width, height = height, dpi = 300)
    ggplot2::ggsave(file.path(dir, paste0(name, ".pdf")), plot,
                    width = width, height = height)
    invisible(plot)
}
