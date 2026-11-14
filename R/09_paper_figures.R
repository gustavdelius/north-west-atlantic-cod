# 09_paper_figures.R
# ---------------------------------------------------------------------------
# Main-text figures for the manuscript (paper/manuscript.tex), redrawn from the
# CSV files that R/01-07 wrote to results/. No model is built, run or changed
# here: every number plotted is read from results/*.csv, plus two observed
# series (summer RV survey biomass and survey-based cod SSB) read from
# literature/data/ and results/observed_cod_ssb.csv.
#
# Figures are sized for a 180 mm (7.1 in) printed width with a 9 pt base font,
# so that the smallest text is >= 7 pt (CJFAS figure guidance). Okabe-Ito
# colours for categories, viridis for ordered quantities.
#
# Outputs: paper/figures/fig1_baseline, fig2_hindcast, fig3_pathways,
#          fig5_what_it_would_take, fig6_forage_fishing, fig7_adult_mortality
#          (PDF + 300 dpi PNG). Figure 4 of the paper reuses
#          figures/fig3_bistability.pdf unchanged.
# Run from the repository root: Rscript R/09_paper_figures.R
# ---------------------------------------------------------------------------
suppressPackageStartupMessages({
    library(ggplot2); library(patchwork); library(dplyr); library(tidyr)
})
OUT <- "paper/figures"
dir.create(OUT, showWarnings = FALSE, recursive = TRUE)
rd <- function(f) read.csv(file.path("results", f), stringsAsFactors = FALSE, check.names = FALSE)

KT_PER_GM2 <- 110                       # 1 g m^-2 = 110 kt over 1.1e5 km^2 (R/functions.R)
FORAGE <- c("Herring", "Sand lance", "Capelin")
OTHER_GF <- c("Haddock", "Silver hake", "American plaice")
SP_ORDER <- c("Cod", OTHER_GF, FORAGE)
# AFS-style capitalised common names for display
SP_LABEL <- c(Cod = "Atlantic Cod", Haddock = "Haddock", `Silver hake` = "Silver Hake",
              `American plaice` = "American Plaice", Herring = "Atlantic Herring",
              `Sand lance` = "Northern Sand Lance", Capelin = "Capelin", Resource = "Resource")
SP_COL <- c("Atlantic Cod" = "#000000", "Haddock" = "#E69F00", "Silver Hake" = "#56B4E9",
            "American Plaice" = "#009E73", "Atlantic Herring" = "#0072B2",
            "Northern Sand Lance" = "#D55E00", "Capelin" = "#CC79A7", "Resource" = "#999999")

theme_fig <- function(base_size = 9) {
    theme_bw(base_size = base_size) +
        theme(panel.grid.minor = element_blank(),
              plot.title = element_text(size = base_size, face = "bold", hjust = 0),
              plot.title.position = "plot",
              legend.key.width = unit(1.3, "lines"),
              legend.text = element_text(size = base_size - 1),
              legend.title = element_text(size = base_size - 1),
              axis.text = element_text(size = base_size - 1.5, colour = "grey20"),
              strip.background = element_rect(fill = "grey92", colour = NA),
              strip.text = element_text(size = base_size - 1))
}
save_both <- function(p, name, width = 7.1, height = 6) {
    ggsave(file.path(OUT, paste0(name, ".pdf")), p, width = width, height = height)
    ggsave(file.path(OUT, paste0(name, ".png")), p, width = width, height = height, dpi = 300)
    invisible(p)
}

calib <- rd("baseline_calibration.csv")
base_ssb <- calib$ssb_model_gm2[calib$species == "Cod"]               # model 1980-85 cod SSB (g m^-2)
base_forage <- sum(calib$total_biomass_model_gm2[calib$species %in% FORAGE])

# ---------------------------------------------------------------------------
# Figure 1: the calibrated 1980-85 steady state
# ---------------------------------------------------------------------------
pA <- calib |> transmute(species, Target = biomass_observed_gm2 * KT_PER_GM2,
                         Model = biomass_model_gm2 * KT_PER_GM2) |>
    pivot_longer(-species, names_to = "source", values_to = "kt") |>
    mutate(species = factor(SP_LABEL[species], levels = rev(SP_LABEL[SP_ORDER])),
           source = factor(source, levels = c("Model", "Target"))) |>
    ggplot(aes(kt, species, fill = source)) +
    geom_col(position = position_dodge(width = 0.8), width = 0.75) +
    scale_fill_manual(values = c(Target = "grey65", Model = "#0072B2"), name = NULL,
                      breaks = c("Target", "Model")) +
    labs(y = NULL, x = "Biomass above survey size cut-off (kt)", title = "(a) Calibration targets, 1980-85") +
    theme_fig() + theme(legend.position = "bottom")

gr <- rd("baseline_growth.csv") |> filter(age <= 12) |>
    mutate(species = factor(SP_LABEL[species], levels = SP_LABEL[SP_ORDER]),
           source = ifelse(source == "model", "Model", "von Bertalanffy (FishBase)"))
pB <- ggplot(gr, aes(age, w, colour = species, linetype = source)) + geom_line(linewidth = 0.5) +
    scale_y_log10(labels = function(x) format(x, scientific = FALSE, drop0trailing = TRUE, big.mark = ",")) +
    scale_colour_manual(values = SP_COL, name = NULL) +
    scale_linetype_manual(values = c(Model = "solid", "von Bertalanffy (FishBase)" = "dashed"), name = NULL) +
    labs(x = "Age (years)", y = "Body mass (g)", title = "(b) Growth") +
    guides(colour = "none") +
    theme_fig() + theme(legend.position = "bottom")

mc <- rd("baseline_cod_mortality.csv") |> filter(w <= 15000) |> select(-growth) |>
    pivot_longer(-w, names_to = "source", values_to = "m") |> filter(m > 1e-3) |>
    mutate(source = recode(source, background = "Background (early life)", forage = "Forage fish",
                           groundfish = "Groundfish (incl. cod)", fishing = "Fishing (F = 0.4)",
                           other_external = "Other external"))
pC <- ggplot(mc, aes(w, m, colour = source)) + geom_line(linewidth = 0.7) +
    scale_x_log10(breaks = 10^seq(-3, 4, 1), labels = c("0.001", "", "0.1", "", "10", "", "1000", "")) +
    scale_y_log10(breaks = 10^seq(-3, 1, 1), labels = c("0.001", "0.01", "0.1", "1", "10")) +
    scale_colour_manual(values = c("Background (early life)" = "grey50", "Forage fish" = "#D55E00",
                                   "Groundfish (incl. cod)" = "#0072B2", "Fishing (F = 0.4)" = "black",
                                   "Other external" = "#CC79A7"), name = NULL) +
    labs(x = "Cod body mass (g)", y = expression("Mortality rate (yr"^-1*")"),
         title = "(c) Mortality of Atlantic Cod by source") +
    guides(colour = guide_legend(ncol = 2)) +
    theme_fig() + theme(legend.position = "bottom", legend.key.height = unit(0.7, "lines"))

spec <- rd("baseline_spectra.csv") |> filter(biomass_per_logw > 1e-4) |>
    mutate(species = factor(SP_LABEL[species], levels = SP_LABEL[c(SP_ORDER, "Resource")]))
pD <- ggplot(spec, aes(w, biomass_per_logw, colour = species)) + geom_line(linewidth = 0.6) +
    scale_x_log10(breaks = 10^seq(-6, 4, 2), labels = c("1e-6", "1e-4", "0.01", "1", "100", "1e4")) +
    scale_y_log10(breaks = 10^seq(-4, 0, 1), labels = c("1e-4", "0.001", "0.01", "0.1", "1")) +
    scale_colour_manual(values = SP_COL, name = NULL) +
    labs(x = "Body mass (g)", y = expression("Biomass density (g m"^-2*" per ln w)"),
         title = "(d) Size spectra (colours also apply to b)") +
    guides(colour = guide_legend(ncol = 2)) +
    theme_fig() + theme(legend.position = "bottom", legend.key.height = unit(0.7, "lines"))
fig1 <- (pA | pB) / (pC | pD)
save_both(fig1, "fig1_baseline", width = 7.1, height = 7.4)

# ---------------------------------------------------------------------------
# Figure 2: hindcasts with documented fishing (A, A0) and with elevated adult
# cod M (B) against survey observations
# ---------------------------------------------------------------------------
RUNS <- c("A: documented F, bycatch 0.02 from 1994" = "A: documented F",
          "A0: documented F, cod F = 0 from 1994" = "A0: documented F, cod F = 0 after 1993",
          "B (alternative): A + adult cod M 0.8 in 1990-2025" = "B: A + adult cod M 0.8 in 1990-2025")
RUN_COL <- setNames(c("#000000", "#0072B2", "#CC79A7"), RUNS)
hind <- rd("hindcast.csv") |> filter(run %in% names(RUNS)) |> mutate(run = factor(RUNS[run], levels = RUNS))
obs_ssb <- rd("observed_cod_ssb.csv")
codh <- hind |> filter(species == "Cod", year <= 2060)
p2a <- ggplot(codh, aes(year, ssb / base_ssb, colour = run)) +
    geom_hline(yintercept = 1, colour = "grey70", linewidth = 0.3) +
    geom_vline(xintercept = 1993.7, linetype = "dotted") +
    geom_line(linewidth = 0.7) +
    geom_point(data = obs_ssb, aes(year, ssb_rel), inherit.aes = FALSE, shape = 21, fill = "white",
               colour = "grey25", size = 1.3) +
    scale_y_log10(breaks = 10^seq(-4, 1), labels = c("0.0001", "0.001", "0.01", "0.1", "1", "10")) +
    scale_colour_manual(values = RUN_COL, name = NULL) +
    coord_cartesian(ylim = c(1e-4, 12)) +
    labs(x = NULL, y = "Cod SSB / 1980-85", title = "(a) Atlantic Cod spawning stock biomass") +
    theme_fig() + theme(legend.position = "bottom")

srv <- read.csv("literature/data/ess_rv_biomass_not_qadj_derived.csv", comment.char = "#", check.names = FALSE)
srv_f <- data.frame(year = srv$year, b = srv[["ATLANTIC HERRING"]] + srv[["NORTHERN SAND LANCE"]] + srv[["CAPELIN"]]) |>
    mutate(rel = b / mean(b[year %in% 1980:1989]))
modf <- hind |> filter(species %in% FORAGE, year <= 2025, run != RUNS[2]) |> group_by(run, year) |>
    summarise(b = sum(biomass), .groups = "drop") |> group_by(run) |>
    mutate(rel = b / mean(b[year %in% 1980:1989]))
p2b <- ggplot(modf, aes(year, rel, colour = run)) +
    geom_hline(yintercept = 1, colour = "grey70", linewidth = 0.3) +
    geom_vline(xintercept = 1993.7, linetype = "dotted") +
    geom_point(data = filter(srv_f, rel > 0), aes(year, rel), inherit.aes = FALSE, shape = 21,
               fill = "white", colour = "grey25", size = 1.3) +
    geom_line(linewidth = 0.7) +
    scale_y_log10(breaks = c(0.01, 0.1, 1, 10), labels = c("0.01", "0.1", "1", "10")) +
    scale_colour_manual(values = RUN_COL, guide = "none") +
    coord_cartesian(ylim = c(0.01, 30)) +
    labs(x = NULL, y = "Forage-fish biomass / 1980-89", title = "(b) Forage-fish biomass") +
    theme_fig()

met <- rd("hindcast_metrics.csv")
met$src <- ifelse(grepl("^observed", met$run), "Observed (summer survey)",
                  ifelse(met$run %in% names(RUNS), unname(RUNS[met$run]), NA))
rat <- met |> filter(src != RUNS[2]) |>
    select(src, Cod = cod, Haddock = haddock, `Silver Hake` = silver_hake, `American Plaice` = plaice,
           `Forage fish` = forage) |>
    pivot_longer(-src, names_to = "group", values_to = "ratio") |>
    mutate(group = factor(group, levels = c("Cod", "Haddock", "Silver Hake", "American Plaice", "Forage fish")),
           src = factor(src, levels = c("Observed (summer survey)", RUNS[1], RUNS[3])))
p2c <- ggplot(rat, aes(group, ratio, colour = src, shape = src)) +
    geom_hline(yintercept = 1, colour = "grey60", linewidth = 0.3) +
    geom_point(size = 2.4, position = position_dodge(width = 0.55), stroke = 0.9) +
    scale_y_log10(breaks = c(0.05, 0.1, 0.2, 0.5, 1, 2, 5, 10), labels = c("0.05", "0.1", "0.2", "0.5", "1", "2", "5", "10")) +
    scale_colour_manual(values = c("Observed (summer survey)" = "grey35", RUN_COL[c(1, 3)]), name = NULL) +
    scale_shape_manual(values = c("Observed (summer survey)" = 21, setNames(c(16, 17), RUNS[c(1, 3)])), name = NULL) +
    labs(x = NULL, y = "Biomass 1995-2004 / 1980-89", title = "(c) Post-collapse community, 1995-2004 relative to 1980-89") +
    theme_fig() + theme(legend.position = "bottom")
top2 <- (p2a | p2b) + plot_layout(guides = "collect") & theme(legend.position = "bottom")
fig2 <- top2 / p2c + plot_layout(heights = c(1.25, 1))
save_both(fig2, "fig2_hindcast", width = 7.1, height = 6.8)

# ---------------------------------------------------------------------------
# Figure 3: how strongly forage fish act on young cod (baseline, run B in
# 2000, cod-free alternative state) and what the pathways add to recovery
# ---------------------------------------------------------------------------
fg <- rd("pathways_cod_feeding_growth.csv") |> filter(w <= 10) |>
    select(w, `1980-85 baseline` = forage_mort_baseline, `Run B, 2000` = forage_mort_boom) |>
    pivot_longer(-w, names_to = "state", values_to = "m")
p3a <- ggplot(fg, aes(w, m, colour = state)) + geom_line(linewidth = 0.8) +
    scale_x_log10(breaks = c(0.001, 0.01, 0.1, 1, 10), labels = c("0.001", "0.01", "0.1", "1", "10")) +
    scale_colour_manual(values = c("1980-85 baseline" = "#0072B2", "Run B, 2000" = "#CC79A7"), name = NULL) +
    labs(x = "Cod body mass (g)", y = expression("Predation mortality by forage fish (yr"^-1*")"),
         title = "(a) Forage-fish predation on young cod") +
    theme_fig() + theme(legend.position = "inside", legend.position.inside = c(0.7, 0.8),
                        legend.background = element_rect(fill = "white", colour = NA))

bud <- rd("pathways_cod_prerecruit_budget.csv") |> filter(w_hi == 1)
inv <- rd("bistability_invasion.csv"); iv <- setNames(inv$value, inv$quantity)
surv <- data.frame(
    state = c("1980-85\nbaseline", "Run B,\n2000", "Cod-free\nalternative state"),
    survival = c(bud$survival[bud$state == "baseline 1980-85"][1], bud$survival[bud$state == "run B, 2000"][1],
                 iv[["cod_survival_1mg_1g_cod_free"]]),
    forage_kill = c(bud$fraction_killed[bud$state == "baseline 1980-85" & bud$source == "forage"],
                    bud$fraction_killed[bud$state == "run B, 2000" & bud$source == "forage"],
                    iv[["forage_kill_fraction_cod_1mg_1g_cod_free"]])) |>
    mutate(state = factor(state, levels = state),
           lab = sprintf("%s%%\n(forage fish kill %.0f%%)", formatC(100 * survival, format = "fg", digits = 2),
                         100 * forage_kill))
p3b <- ggplot(surv, aes(state, survival)) +
    geom_segment(aes(xend = state, y = 1e-5, yend = survival), colour = "grey60", linewidth = 0.6) +
    geom_point(aes(colour = state), size = 3) +
    geom_text(aes(label = lab), vjust = -0.6, size = 2.6, lineheight = 0.9) +
    scale_colour_manual(values = c("#0072B2", "#CC79A7", "#D55E00"), guide = "none") +
    scale_y_log10(limits = c(1e-5, 0.3), breaks = c(1e-5, 1e-4, 1e-3, 1e-2, 1e-1),
                  labels = c("0.001%", "0.01%", "0.1%", "1%", "10%")) +
    labs(x = NULL, y = "Survival of cod from 1 mg to 1 g", title = "(b) Pre-recruit survival") +
    theme_fig() + theme(axis.text.x = element_text(size = 7))

dg <- rd("pathways_diagnostic_runs.csv") |> filter(species == "Cod") |>
    mutate(diagnostic = factor(recode(diagnostic, full = "Full model (s = 20)",
                                      no_vulnerability_factor = "s = 1 (no extra vulnerability)",
                                      no_plankton_depletion = "Resource held at baseline",
                                      neither = "Both switched off"),
                               levels = c("Full model (s = 20)", "s = 1 (no extra vulnerability)",
                                          "Resource held at baseline", "Both switched off")))
p3c <- ggplot(dg, aes(year, ssb / base_ssb, colour = diagnostic)) +
    geom_hline(yintercept = 0.5, linetype = "dotted") + geom_line(linewidth = 0.7) +
    scale_y_log10(breaks = 10^seq(-3, 1), labels = c("0.001", "0.01", "0.1", "1", "10")) +
    scale_colour_manual(values = c("#000000", "#D55E00", "#009E73", "#CC79A7"), name = NULL) +
    labs(x = NULL, y = "Cod SSB / 1980-85", title = "(c) Recovery from the collapsed 2025 state with pathways switched off") +
    theme_fig() + theme(legend.position = "inside", legend.position.inside = c(0.8, 0.3),
                        legend.background = element_rect(fill = "white", colour = NA))
fig3 <- (p3a | p3b) / p3c + plot_layout(heights = c(1, 0.9))
save_both(fig3, "fig3_pathways", width = 7.1, height = 6.4)

# ---------------------------------------------------------------------------
# Figure 5: what it would take
# ---------------------------------------------------------------------------
sm <- rd("sensitivity_map.csv")
lab_s <- sm |> group_by(s) |> summarise(share = first(forage_share_cod_deaths_baseline), rec = first(recalibrated)) |>
    mutate(lab = sprintf("s = %g\n%.1f%%%s", s, 100 * share, ifelse(rec, "", "\nnot recal.")))
sm <- sm |> left_join(select(lab_s, s, lab), by = "s") |>
    mutate(lab = factor(lab, levels = lab_s$lab[order(lab_s$s)]),
           rf = sprintf("%.2f", repro_forage), rf = ifelse(rf == "0.17", "0.17 (main)", rf),
           rf = factor(rf, levels = ifelse(sprintf("%.2f", sort(unique(repro_forage))) == "0.17", "0.17 (main)",
                                           sprintf("%.2f", sort(unique(repro_forage))))),
           outcome = recode(outcome, "recovers quickly (<= 20 yr)" = "Recovers within 20 years",
                            "alternative state exists, not reached" = "Alternative state exists, not reached",
                            "alternative state reached" = "Alternative state reached (baseline not sustained)"),
           txt = sprintf("x%.1f", forage_ratio_1995_2004))
p5a <- ggplot(sm, aes(lab, rf, fill = outcome)) + geom_tile(colour = "white", linewidth = 0.6) +
    geom_text(aes(label = txt), size = 2.5) +
    scale_fill_manual(values = c("Recovers within 20 years" = "#BFDDF2",
                                 "Alternative state exists, not reached" = "#E8B4D3",
                                 "Alternative state reached (baseline not sustained)" = "#E69F00"), name = NULL,
                      breaks = c("Recovers within 20 years", "Alternative state exists, not reached",
                                 "Alternative state reached (baseline not sustained)")) +
    guides(fill = guide_legend(nrow = 2)) +
    labs(x = "Early-life vulnerability factor s (forage-fish share of cod deaths, 1 mg-1 g, at 1980-85 abundance)",
         y = "Forage reproduction level",
         title = "(a) Outcome of the documented-fishing hindcast (cell: forage boom 1995-2004 / 1980-89)") +
    theme_fig() + theme(legend.position = "bottom", panel.grid = element_blank(),
                        axis.text.x = element_text(size = 7, lineheight = 0.9))

ol <- rd("observed_like_start_traj.csv") |> filter(species == "Cod") |>
    mutate(case = case_when(s == "1 (diagnostic)" ~ "s = 1 (diagnostic), status quo",
                            F_forage == 0.1 ~ "s = 20, status quo (forage F 0.1)",
                            F_forage == 0.5 ~ "s = 20, forage F 0.5 for 10 years",
                            TRUE ~ "s = 20, forage F 1.0 for 10 years"),
           case = factor(case, levels = c("s = 20, status quo (forage F 0.1)", "s = 1 (diagnostic), status quo",
                                          "s = 20, forage F 0.5 for 10 years", "s = 20, forage F 1.0 for 10 years")),
           start = factor(sprintf("Cod starts at %.2f of 1980-85", cod_start),
                          levels = sprintf("Cod starts at %.2f of 1980-85", c(0.10, 0.04, 0.01))))
p5b <- ggplot(ol, aes(year, ssb / base_ssb, colour = case, linetype = case)) +
    geom_hline(yintercept = 0.5, linetype = "dotted") + geom_line(linewidth = 0.6) +
    facet_wrap(~ start, nrow = 1) +
    scale_y_log10(breaks = c(0.01, 0.1, 1, 10), labels = c("0.01", "0.1", "1", "10")) +
    scale_colour_manual(values = c("#000000", "#009E73", "#0072B2", "#D55E00"), name = NULL) +
    scale_linetype_manual(values = c("solid", "longdash", "solid", "solid"), name = NULL) +
    labs(x = "Years from the imposed post-collapse community (forage fish x7.9)", y = "Cod SSB / 1980-85",
         title = "(b) Conditional test: the observed post-collapse community imposed as initial state") +
    guides(colour = guide_legend(nrow = 2), linetype = guide_legend(nrow = 2)) +
    theme_fig() + theme(legend.position = "bottom")
fig5 <- p5a / p5b + plot_layout(heights = c(1.15, 1))
save_both(fig5, "fig5_what_it_would_take", width = 7.1, height = 7.6)

# ---------------------------------------------------------------------------
# Figure 6: forage fishing from the modelled collapsed state and from the
# model's alternative stable state
# ---------------------------------------------------------------------------
F_COL <- c("0.1" = "#000000", "0.25" = "#0D0887", "0.5" = "#7E03A8", "1" = "#CC4778", "3" = "#F89540")
lab_F <- function(f, D) ifelse(f == 0.1, "status quo (0.1)", sprintf("%g for 10 years", f))
tr1 <- rd("forage_fishing_trajectories.csv") |>
    filter(species == "Cod", (F_forage == 0.1) | (D == 10 & F_forage %in% c(0.25, 0.5, 1, 3))) |>
    mutate(t = year - 2026, Fl = factor(as.character(F_forage), levels = names(F_COL)))
tr2 <- rd("forage_fishing_alt_state_trajectories.csv") |>
    filter(species == "Cod", (F_forage == 0.1) | (D == 10 & F_forage %in% c(0.25, 0.5, 1, 3))) |>
    mutate(t = year, Fl = factor(as.character(F_forage), levels = names(F_COL)))
F_LAB <- c("0.1" = "status quo (0.1)", "0.25" = "0.25 for 10 yr", "0.5" = "0.5 for 10 yr",
           "1" = "1 for 10 yr", "3" = "3 for 10 yr")
traj_plot <- function(d, title, ylim) {
    ggplot(d, aes(t, ssb / base_ssb, colour = Fl)) +
        annotate("rect", xmin = 0, xmax = 10, ymin = 0, ymax = Inf, alpha = 0.12) +
        geom_hline(yintercept = 0.5, linetype = "dotted") + geom_line(linewidth = 0.6) +
        scale_y_log10(breaks = 10^seq(-4, 1), labels = c("0.0001", "0.001", "0.01", "0.1", "1", "10")) +
        coord_cartesian(ylim = ylim) +
        scale_colour_manual(values = F_COL, labels = F_LAB, name = "Forage-fish F") +
        labs(x = "Years from start of programme", y = "Cod SSB / 1980-85", title = title) +
        theme_fig() + theme(legend.key.height = unit(0.8, "lines"))
}
p6a <- traj_plot(tr1, "(a) From the collapsed 2025 state", c(1e-4, 10))
p6c <- traj_plot(tr2, "(c) From the alternative stable state", c(1e-4, 10))
grid_plot <- function(g, Dmax, title) {
    g <- g |> filter(F_forage > 0.1) |>
        mutate(Dl = factor(ifelse(D >= Dmax, "perm.", as.character(D)), levels = c("5", "10", "15", "20", "30", "perm.")),
               txt = ifelse(is.na(years_to_50pct), "-",
                            ifelse(persistent_recovery, as.character(years_to_50pct), paste0(years_to_50pct, "*"))))
    ggplot(g, aes(factor(F_forage), Dl, fill = years_to_50pct)) + geom_tile(colour = "white") +
        geom_text(aes(label = txt), size = 2.5, colour = ifelse(!is.na(g$years_to_50pct) & g$years_to_50pct > 30, "white", "black")) +
        scale_fill_viridis_c(option = "viridis", direction = -1, na.value = "grey85", name = "Years to\n50% SSB",
                             limits = c(15, 45)) +
        labs(x = "Forage-fish F during programme", y = "Programme duration (years)", title = title) +
        theme_fig() + theme(panel.grid = element_blank(), legend.key.height = unit(1, "lines"))
}
g1 <- rd("forage_fishing_grid.csv")
g2 <- rd("forage_fishing_alt_state_grid.csv")
sq1 <- g1$years_to_50pct[g1$F_forage == 0.1]
p6b <- grid_plot(g1, 100, sprintf("(b) Years to 50%% SSB (status quo: %d)", sq1))
p6d <- grid_plot(g2, 150, "(d) Years to 50% SSB (status quo: none)")
fig6 <- (p6a | p6b) / (p6c | p6d) + plot_layout(guides = "collect")
save_both(fig6, "fig6_forage_fishing", width = 7.1, height = 6.2)

# ---------------------------------------------------------------------------
# Figure 7: elevated adult natural mortality of cod, 2 x 2 factorial
# ---------------------------------------------------------------------------
ft <- rd("alt_adult_M_factorial_traj.csv") |>
    mutate(combo = factor(sprintf("adult M %s, s = %s", ifelse(M == "baseline", "baseline", "0.8"),
                                  ifelse(forage_mechanism == "on", "20", "1")),
                          levels = c("adult M baseline, s = 20", "adult M baseline, s = 1",
                                     "adult M 0.8, s = 20", "adult M 0.8, s = 1")))
CMB_COL <- c("adult M baseline, s = 20" = "#000000", "adult M baseline, s = 1" = "#000000",
             "adult M 0.8, s = 20" = "#CC79A7", "adult M 0.8, s = 1" = "#CC79A7")
CMB_LT <- c("adult M baseline, s = 20" = "solid", "adult M baseline, s = 1" = "dashed",
            "adult M 0.8, s = 20" = "solid", "adult M 0.8, s = 1" = "dashed")
p7a <- ft |> filter(species == "Cod", year <= 2025) |>
    ggplot(aes(year, ssb / base_ssb, colour = combo, linetype = combo)) +
    geom_vline(xintercept = 1993.7, linetype = "dotted") + geom_line(linewidth = 0.7) +
    geom_point(data = obs_ssb, aes(year, ssb_rel), inherit.aes = FALSE, shape = 21, fill = "white",
               colour = "grey25", size = 1.2) +
    scale_y_log10(breaks = 10^seq(-4, 1), labels = c("0.0001", "0.001", "0.01", "0.1", "1", "10")) +
    scale_colour_manual(values = CMB_COL, name = "From 1990") + scale_linetype_manual(values = CMB_LT, name = "From 1990") +
    labs(x = NULL, y = "Cod SSB / 1980-85", title = "(a) Atlantic Cod, 1970-2025") +
    guides(colour = guide_legend(nrow = 2), linetype = guide_legend(nrow = 2)) +
    theme_fig() + theme(legend.position = "bottom")
p7b <- ft |> filter(species %in% FORAGE, year <= 2025) |> group_by(year, combo) |>
    summarise(b = sum(biomass), .groups = "drop") |>
    ggplot(aes(year, b / base_forage, colour = combo, linetype = combo)) +
    geom_vline(xintercept = 1993.7, linetype = "dotted") + geom_line(linewidth = 0.7) +
    scale_colour_manual(values = CMB_COL, guide = "none") + scale_linetype_manual(values = CMB_LT, guide = "none") +
    labs(x = NULL, y = "Forage-fish biomass / 1980-85", title = "(b) Forage fish, 1970-2025") +
    theme_fig()
ff <- rd("alt_adult_M_forage_fishing.csv") |>
    mutate(M_after_2025 = factor(ifelse(M_after_2025 == "stays 0.8", "adult M stays 0.8", "adult M back to baseline"),
                                 levels = c("adult M back to baseline", "adult M stays 0.8")),
           Dl = paste(D, "years"),
           y = ifelse(is.na(years_to_50pct), 100, years_to_50pct))
p7c <- ggplot(ff, aes(F_forage, y, colour = M_after_2025, shape = Dl)) +
    geom_hline(yintercept = 100, colour = "grey80") +
    geom_point(size = 2.2, stroke = 0.8) +
    annotate("text", x = 1.05, y = 95, label = "no recovery by 2125", size = 2.6, colour = "#CC79A7") +
    scale_colour_manual(values = c("adult M back to baseline" = "#000000", "adult M stays 0.8" = "#CC79A7"),
                        name = "After 2025") +
    scale_shape_manual(values = c("10 years" = 16, "30 years" = 2), name = "Programme") +
    scale_x_continuous(breaks = c(0.1, 0.5, 1, 2)) +
    scale_y_continuous(limits = c(35, 102), breaks = seq(40, 100, 10)) +
    labs(x = "Forage-fish F from 2026 (0.1 = status quo)", y = "Years to 50% of 1980-85 SSB",
         title = "(c) Forage fishing after 2025") +
    theme_fig() + theme(legend.position = "right")
top7 <- (p7a | p7b) + plot_layout(guides = "collect") & theme(legend.position = "bottom")
fig7 <- top7 / p7c + plot_layout(heights = c(1.2, 1))
save_both(fig7, "fig7_adult_mortality", width = 7.1, height = 6.6)
cat("09_paper_figures.R done\n")
