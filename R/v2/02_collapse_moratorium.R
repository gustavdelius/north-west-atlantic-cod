# 02_collapse_moratorium.R  (v2)
# ---------------------------------------------------------------------------
# Acceptance test 2 for v2, plus the pathway analysis (coordinator item D).
#
#  (1) Calibration hindcast ("cod forced"): historical efforts with cod kept on
#      its observed path after 1993 (data/v2/effort_history_codforced.csv).
#      Its 2000 state is the model's version of the observed post-collapse
#      community (cod ~0.1, forage boom, groundfish ~0.5 of the 1980s); it is
#      saved as models/collapsed_state_params.rds and used as the "collapsed"
#      initial state in tests 3-4.
#  (2) Moratorium test A: the real moratorium (cod F 0.02 from 1994) from 1970
#      (data/v2/effort_history.csv), to 2125.
#  (3) Moratorium test B: the real moratorium from the observed-like 2000
#      state (initial state = (1)), to 2125.
#  (4) Pathways: cod pre-recruit budgets, feeding level and growth in the
#      baseline vs the boom (2000) state; rate-based decomposition of the
#      change in survival into "more predation" and "slower growth"; and
#      diagnostic runs from the 2000 state with (a) forage predation on cod
#      switched off, (b) plankton depletion switched off (resource held at its
#      baseline abundance), (c) both. The diagnostic runs change parameters
#      and are NOT management scenarios.
# Outputs: results/hindcast*.csv, results/pathways*.csv,
#   models/collapsed_state_params.rds, figures/fig2_collapse_moratorium.*,
#   figures/fig2b_pathways.*
# ---------------------------------------------------------------------------
source("R/v2/functions.R")
suppressPackageStartupMessages({
    library(ggplot2); library(patchwork); library(dplyr); library(tidyr); library(parallel)
})
options(mizer_info_level = 0)
params <- readParams("models/v2/baseline_params.rds")
base_ssb <- getSSB(params)[["Cod"]]
base_forage <- sum(getBiomass(params)[FORAGE])
eh <- read_effort_history()
ehf <- read_effort_history(file.path(DATA_DIR, "effort_history_codforced.csv"))
mor <- moratorium_effort(eh)
cont <- function(e, from_sim, start, end) {
    ext <- e[nrow(e), ]; ext$year <- start
    run_scenario(params, ext, years = c(start, end), initial = from_sim)
}

# (1) calibration hindcast with cod forced
hf <- run_scenario(params, ehf, years = c(1970, 2025), return_sim = TRUE)
p2000 <- getParams(hf$sim, time_range = 2000)
initial_effort(p2000) <- moratorium_effort(ehf)
saveParams(setMetadata(p2000, title = "4VsW model v2: observed-like post-collapse state (year 2000)",
                       description = "State in 2000 of the cod-forced calibration hindcast (cod ~0.1 of the 1980s, forage-fish boom); same parameters as models/baseline_params.rds."),
           "models/v2/collapsed_state_params.rds")
# (2) real moratorium from 1970
hA <- run_scenario(params, eh, years = c(1970, 2025), return_sim = TRUE)
dA <- bind_rows(hA$data, filter(cont(eh, hA$sim, 2025, 2125), year > 2025))
# (3) real moratorium from the observed-like 2000 state
dB <- run_scenario(params, mor, years = c(2000, 2125), initial = p2000)
hind <- bind_rows(mutate(bind_rows(hf$data, filter(cont(ehf, hf$sim, 2025, 2125), year > 2025)),
                         run = "calibration: cod forced on observed path"),
                  mutate(dA, run = "A: moratorium from 1970"),
                  mutate(dB, run = "B: moratorium from observed 2000 state"))
write.csv(hind, "results/v2/hindcast.csv", row.names = FALSE)

obs <- read.csv("literature/data/cod_4VsW_assessment.csv", comment.char = "#")
obs_rel <- obs |> mutate(ssb_rel = SSB_t / mean(SSB_t[year %in% 1980:1985]))
write.csv(obs_rel[, c("year", "SSB_t", "ssb_rel")], "results/v2/observed_cod_ssb.csv", row.names = FALSE)

ratios <- function(df) c(cod = period_ratio(df, "Cod"), haddock = period_ratio(df, "Haddock"),
                         silver_hake = period_ratio(df, "Silver hake"),
                         plaice = period_ratio(df, "American plaice"),
                         herring = period_ratio(df, "Herring"), forage = period_ratio(df, FORAGE),
                         forage_2005_12 = period_ratio(df, FORAGE, num = 2005:2012),
                         pelagic_demersal_1980_85 = NA, pelagic_demersal_1995_2000 = NA)
pd_ratio <- function(df, yrs) {
    x <- df[df$year %in% yrs, ]
    sum(x$biomass[x$species %in% FORAGE]) / sum(x$biomass[x$species %in% GROUNDFISH])
}
met <- bind_rows(lapply(split(hind, hind$run), function(df) {
    r <- ratios(df)
    r["pelagic_demersal_1980_85"] <- pd_ratio(df, 1980:1985)
    r["pelagic_demersal_1995_2000"] <- pd_ratio(df, 1995:2000)
    start <- min(df$year)
    m <- recovery_metrics(df, base_ssb, base_forage, t0 = max(1993, start))
    cbind(run = df$run[1], as.data.frame(t(r)), m)
}))
met <- bind_rows(met, data.frame(run = "observed (survey; Bundy 2004 for P:D)", cod = 0.10, haddock = 0.61,
                                 silver_hake = 0.60, plaice = 0.45, herring = 6.55, forage = 7.87,
                                 forage_2005_12 = 4.11, pelagic_demersal_1980_85 = 0.3,
                                 pelagic_demersal_1995_2000 = 3.0))
write.csv(met, "results/v2/hindcast_metrics.csv", row.names = FALSE)
print(met)

# (4) pathways ---------------------------------------------------------------------
pb <- params; pB <- p2000
budget_rows <- bind_rows(lapply(c(1, 10), function(wh) bind_rows(
    mutate(prerecruit_budget(pb, "Cod", 0.001, wh), state = "baseline 1980-85"),
    mutate(prerecruit_budget(pB, "Cod", 0.001, wh), state = "boom 2000"))))
write.csv(budget_rows, "results/v2/pathways_cod_prerecruit_budget.csv", row.names = FALSE)
print(budget_rows)
# rate-based decomposition: survival 1 mg -> w_hi with each combination of
# mortality and growth from the two states
mcb <- mort_components(pb, "Cod"); mcB <- mort_components(pB, "Cod")
surv <- function(mc, g, wh) prerecruit_budget(pb, "Cod", 0.001, wh, mc = mc, growth = g)$survival[1]
decomp <- bind_rows(lapply(c(1, 10), function(wh) data.frame(
    w_hi = wh,
    baseline = surv(mcb, mcb$growth, wh),
    boom_mortality_only = surv(mcB, mcb$growth, wh),
    boom_growth_only = surv(mcb, mcB$growth, wh),
    boom_both = surv(mcB, mcB$growth, wh))))
decomp <- decomp |> mutate(ratio_both = boom_both / baseline,
                           ratio_mortality = boom_mortality_only / baseline,
                           ratio_growth = boom_growth_only / baseline)
write.csv(decomp, "results/v2/pathways_survival_decomposition.csv", row.names = FALSE)
print(decomp)
ws <- w(pb)
fgr <- data.frame(w = ws,
                  feeding_baseline = as.numeric(getFeedingLevel(pb)["Cod", ]),
                  feeding_boom = as.numeric(getFeedingLevel(pB)["Cod", ]),
                  growth_baseline = mcb$growth, growth_boom = mcB$growth,
                  forage_mort_baseline = mcb$forage, forage_mort_boom = mcB$forage,
                  total_mort_baseline = rowSums(mcb[, 2:6]), total_mort_boom = rowSums(mcB[, 2:6]))
write.csv(fgr, "results/v2/pathways_cod_feeding_growth.csv", row.names = FALSE)
rlv <- data.frame(w = c(1e-5, 1e-4, 1e-3, 1e-2, 0.1, 1, 5),
                  level_baseline = resource_level_at(pb), level_boom = resource_level_at(pB),
                  share_eaten_baseline = resource_consumption_share(pb),
                  share_eaten_boom = resource_consumption_share(pB))
write.csv(rlv, "results/v2/pathways_resource_level.csv", row.names = FALSE)
print(rlv)

# diagnostic runs from the 2000 state
diag_params <- list(
    full = params,
    no_forage_predation_on_cod = { p <- params; im <- interaction_matrix(p); im[FORAGE, "Cod"] <- 0
                                   interaction_matrix(p) <- im; p },
    no_plankton_depletion = setResource(params, resource_dynamics = "resource_constant"),
    neither = { p <- setResource(params, resource_dynamics = "resource_constant")
                im <- interaction_matrix(p); im[FORAGE, "Cod"] <- 0; interaction_matrix(p) <- im; p })
diag_runs <- mclapply(names(diag_params), function(n) {
    p <- diag_params[[n]]
    p0 <- p2000
    if (n %in% c("no_plankton_depletion", "neither")) {
        # hold the resource at its baseline (1980-85) abundance
        initialNResource(p0) <- initialNResource(params)
    }
    mutate(run_scenario(p, mor, years = c(2000, 2125), initial = p0), diagnostic = n)
}, mc.cores = 4)
diag_df <- bind_rows(diag_runs)
write.csv(diag_df |> filter(species %in% c("Cod", FORAGE, OTHER_GF)),
          "results/v2/pathways_diagnostic_runs.csv", row.names = FALSE)
diag_met <- diag_df |> group_by(diagnostic) |> group_modify(~ {
    cod <- .x[.x$species == "Cod", ]
    rec <- cod$year[cod$ssb >= 0.5 * base_ssb]
    data.frame(years_to_50pct_from_2000 = if (length(rec)) min(rec) - 2000 else NA,
               cod_ssb_2025_rel = cod$ssb[cod$year == 2025] / base_ssb,
               cod_ssb_2125_rel = cod$ssb[cod$year == 2125] / base_ssb)
})
write.csv(diag_met, "results/v2/pathways_diagnostic_metrics.csv", row.names = FALSE)
print(diag_met)

# --- Figure 2: hindcast --------------------------------------------------------------
pal_run <- c("calibration: cod forced on observed path" = "grey50",
             "A: moratorium from 1970" = "#000000", "B: moratorium from observed 2000 state" = "#D55E00")
# the cod-forced calibration run is only meaningful over the calibration years
hind_plot <- hind |> filter(!(run == "calibration: cod forced on observed path" & year > 2012))
pA <- hind_plot |> filter(species == "Cod", year <= 2060) |>
    ggplot(aes(year, ssb / base_ssb, colour = run)) + geom_line(linewidth = 0.8) +
    geom_point(data = obs_rel, aes(year, ssb_rel), inherit.aes = FALSE, colour = "#0072B2", size = 1.3) +
    geom_vline(xintercept = 1993.7, linetype = "dotted") + scale_y_log10() +
    coord_cartesian(ylim = c(1e-3, 10)) + scale_colour_manual(values = pal_run) +
    labs(x = NULL, y = "Cod SSB relative to baseline", colour = NULL,
         title = "a  Cod SSB (points: survey SSB / 1980-85 mean)") +
    theme_paper() + theme(legend.position = "bottom", legend.direction = "vertical")
grp <- hind_plot |> filter(year <= 2060, !grepl("Resource", species)) |>
    mutate(group = ifelse(species %in% FORAGE, "Forage fish", ifelse(species == "Cod", "Cod", "Other groundfish"))) |>
    group_by(run, year, group) |> summarise(biomass = sum(biomass), .groups = "drop") |>
    group_by(run, group) |> mutate(rel = biomass / biomass[year == min(year)])
base_grp <- c(Cod = getBiomass(params)[["Cod"]], `Forage fish` = base_forage,
              `Other groundfish` = sum(getBiomass(params)[OTHER_GF]))
grp$rel <- grp$biomass / base_grp[grp$group]
pB <- ggplot(grp, aes(year, rel, colour = group, linetype = run)) + geom_line(linewidth = 0.7) +
    geom_vline(xintercept = 1993.7, linetype = "dotted") + scale_y_log10() +
    scale_colour_manual(values = SPECIES_COLOURS[c("Cod", "Forage fish", "Other groundfish")]) +
    scale_linetype_manual(values = c("calibration: cod forced on observed path" = "dotted",
                                     "A: moratorium from 1970" = "solid",
                                     "B: moratorium from observed 2000 state" = "dashed"), guide = "none") +
    labs(x = NULL, y = "Biomass relative to baseline", colour = NULL,
         title = "b  Groups (dotted: calibration, solid: A, dashed: B)") + theme_paper()
srv <- read.csv("literature/data/ess_rv_biomass_not_qadj_derived.csv", comment.char = "#", check.names = FALSE)
srv_long <- data.frame(year = srv$year,
                       Cod = srv[["ATLANTIC COD"]], Haddock = srv[["HADDOCK"]],
                       `Silver hake` = srv[["SILVER HAKE"]], `American plaice` = srv[["AMERICAN PLAICE"]],
                       `Forage fish` = srv[["ATLANTIC HERRING"]] + srv[["NORTHERN SAND LANCE"]] + srv[["CAPELIN"]],
                       check.names = FALSE) |>
    pivot_longer(-year, names_to = "species", values_to = "b") |>
    group_by(species) |> mutate(rel = b / mean(b[year %in% 1980:1989]))
mod_long <- hind |> filter(run == "calibration: cod forced on observed path", year <= 2012) |>
    mutate(species = ifelse(species %in% FORAGE, "Forage fish", species)) |>
    filter(species %in% unique(srv_long$species)) |>
    group_by(year, species) |> summarise(b = sum(biomass), .groups = "drop") |>
    group_by(species) |> mutate(rel = b / mean(b[year %in% 1980:1989]))
pC <- ggplot() + geom_point(data = srv_long, aes(year, rel), colour = "#0072B2", size = 0.8) +
    geom_line(data = mod_long, aes(year, rel)) + facet_wrap(~ species, scales = "free_y", nrow = 1) +
    scale_y_log10() + labs(x = NULL, y = "Biomass / 1980-89 mean",
                           title = "c  Calibration hindcast (line) vs summer survey (points)") + theme_paper()
resd <- hind_plot |> filter(grepl("Resource", species), year <= 2060) |>
    group_by(run, species) |> mutate(rel = biomass / biomass[year == min(year)])
pD <- ggplot(resd, aes(year, rel, colour = species, linetype = run)) + geom_line() +
    scale_linetype_manual(values = c("calibration: cod forced on observed path" = "dotted",
                                     "A: moratorium from 1970" = "solid",
                                     "B: moratorium from observed 2000 state" = "dashed"), guide = "none") +
    scale_colour_manual(values = c("Resource <1 mg" = "#009E73", "Resource 1-100 mg" = "#E69F00",
                                   "Resource 0.1-10 g" = "#56B4E9")) +
    labs(x = NULL, y = "Resource biomass / start of run", colour = NULL, title = "d  Plankton and benthos") +
    theme_paper()
save_fig((pA | pB) / pC / pD + plot_layout(heights = c(1.3, 0.8, 0.8)), "fig2_collapse_moratorium",
         width = 12, height = 13)

# --- Figure 2b: pathways ----------------------------------------------------------------
fl <- fgr |> filter(w <= 100) |> select(w, baseline = feeding_baseline, boom = feeding_boom) |>
    pivot_longer(-w, names_to = "state", values_to = "v")
gr <- fgr |> filter(w <= 100) |> transmute(w, baseline = growth_baseline / w, boom = growth_boom / w) |>
    pivot_longer(-w, names_to = "state", values_to = "v")
fm <- fgr |> filter(w <= 100) |> transmute(w, baseline = forage_mort_baseline, boom = forage_mort_boom) |>
    pivot_longer(-w, names_to = "state", values_to = "v")
col2 <- c(baseline = "#0072B2", boom = "#D55E00")
q1 <- ggplot(fl, aes(w, v, colour = state)) + geom_line() + scale_x_log10() + scale_colour_manual(values = col2) +
    labs(x = "Cod mass (g)", y = "Feeding level", colour = NULL, title = "a  Cod feeding level") + theme_paper()
q2 <- ggplot(gr, aes(w, v, colour = state)) + geom_line() + scale_x_log10() + scale_y_log10() +
    scale_colour_manual(values = col2, guide = "none") +
    labs(x = "Cod mass (g)", y = expression("Specific growth (yr"^-1*")"), title = "b  Cod growth") + theme_paper()
q3 <- ggplot(fm, aes(w, v, colour = state)) + geom_line() + scale_x_log10() +
    scale_colour_manual(values = col2, guide = "none") +
    labs(x = "Cod mass (g)", y = expression("Mortality by forage fish (yr"^-1*")"),
         title = "c  Forage-fish predation on cod") + theme_paper()
rlp <- rlv |> select(w, baseline = level_baseline, boom = level_boom) |>
    pivot_longer(-w, names_to = "state", values_to = "v")
q4 <- ggplot(rlp, aes(w, v, colour = state)) + geom_line() + geom_point() + scale_x_log10() +
    coord_cartesian(ylim = c(0, 1)) + scale_colour_manual(values = col2, guide = "none") +
    labs(x = "Resource mass (g)", y = "Resource level", title = "d  Resource depletion") + theme_paper()
q5 <- diag_df |> filter(species == "Cod") |>
    ggplot(aes(year, ssb / base_ssb, colour = diagnostic)) + geom_line(linewidth = 0.8) + scale_y_log10() +
    scale_colour_manual(values = c(full = "#000000", no_forage_predation_on_cod = "#D55E00",
                                   no_plankton_depletion = "#009E73", neither = "#CC79A7")) +
    geom_hline(yintercept = 0.5, linetype = "dotted") +
    labs(x = NULL, y = "Cod SSB / baseline", colour = "Diagnostic run",
         title = "e  Moratorium from the 2000 state with pathways switched off") + theme_paper()
save_fig((q1 | q2) / (q3 | q4) / q5, "fig2b_pathways", width = 11, height = 12)
cat("02_collapse_moratorium.R done\n")
