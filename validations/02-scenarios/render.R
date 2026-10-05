# Build every comparison figure from the saved CSVs (no model runs).
#
#   Rscript validations/02-scenarios/render.R                 # figures -> man/figures + vignettes
#   CMP_SMOKE=1 Rscript validations/02-scenarios/render.R     # from validations/02-scenarios/results/smoke -> validations/02-scenarios/results/plots/smoke
#
# Writes cmp_*.png. All visual decisions live in theme.R; this file only shapes
# data and composes panels. Figures:
#   core_eir       four equilibrium relationships vs EIR (2x2)
#   eir_*          each of the four alone, beside its test: one per EIR claim
#   age_clin/_sev  clinical and severe incidence by age band, three EIRs
#   core_pop_age   the population age structure and its test
#   core_demography custom demography: age structure and age-prevalence
#   core_seasonal  the settled annual cycle: prevalence and clinical incidence
#   core_sites     63-country monthly comparison (from fleet_validate results)
#   int_timeseries five interventions x {prevalence, clinical}, time series
#   programme_ts   five long-horizon programmes x four outcomes, 15 years
#   int_impact     % reduction per intervention, IBM (replicate range) vs fleet

## No absolute paths anywhere in here. FLEET_LIB is prepended to the library
## path, for installations that do not pick up R_LIBS_USER (the Windows-arm64
## setup this was developed on); the libraries already on the path are kept, so a
## FLEET_LIB holding only some of the dependencies still works. Leave it unset and
## your normal library is used. ROOT is found by walking up to the DESCRIPTION, so
## these scripts run from any working directory and on anyone's checkout, whether
## via Rscript or source().
if (nzchar(.l <- Sys.getenv("FLEET_LIB"))) .libPaths(c(.l, .libPaths()))
.f <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))
ROOT <- if (length(.f)) normalizePath(dirname(.f), "/") else getwd()
while (!file.exists(file.path(ROOT, "DESCRIPTION")) && dirname(ROOT) != ROOT)
  ROOT <- dirname(ROOT)
if (!file.exists(file.path(ROOT, "DESCRIPTION")))
  stop("run this from inside the fleet checkout (no DESCRIPTION found above ", getwd(), ")")
suppressMessages({library(dplyr); library(tidyr)})
## The constants are package code in R/ and arrive with the package.
if (requireNamespace("pkgload", quietly = TRUE) &&
    file.exists(file.path(ROOT, "DESCRIPTION"))) {
  suppressMessages(pkgload::load_all(ROOT, quiet = TRUE))
} else {
  suppressMessages(library(fleetcheck))
}

## No scenarios.R here, and so no malariasimulation. This script reads the saved
## CSVs and draws; it referred to nothing scenarios.R defines, but sourcing it
## built every malariasimulation parameter list in the file at load time and
## made an unrelated package a hard requirement for redrawing a figure.
## Plot theme: runner code. It attaches ggplot2 and patchwork and probes the
## system fonts, none of which a package may do at load time, and none of which
## the light CI job installs. Sourced by the two scripts that draw.
source(file.path(ROOT, "validations", "_shared", "theme.R"))
SMOKE <- nzchar(Sys.getenv("CMP_SMOKE"))
DDIR  <- file.path(ROOT, "validations", "02-scenarios", "results")
if (SMOKE) {                                   # smoke data must never overwrite the real figures
  BURN_Y <- 1L; DDIR <- file.path(DDIR, "smoke")
  out_dir <- file.path(ROOT, "validations", "02-scenarios", "results", "plots", "smoke")
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  save_fig <- function(g, name, width, height, dpi = 200)
    ggsave(file.path(out_dir, paste0("cmp_", name, ".png")), g, width = width,
           height = height, dpi = dpi, device = ragg::agg_png, bg = SURFACE)
}
rd <- function(part) read.csv(file.path(DDIR, paste0("rep_", part, ".csv")), stringsAsFactors = FALSE)
eq <- rd("eq"); age <- rd("age"); monthly <- rd("monthly"); doy <- rd("doy"); timing <- rd("timing")
n_rep <- max(eq$rep)
ibm_note <- sprintf(paste(
  "Both models start from set_equilibrium()'s seed and run the same %d-year burn-in.",
  "IBM: %d stochastic replicates of %s people; line or point = median, shaded band or bar = its replicate band, median \u00b1 1.28 SD, the 10\u201390%% interval read from every replicate.",
  "fleet: one deterministic run."), BURN_Y, n_rep, format(POP, big.mark = ","))
PREV_LAB <- "LM prevalence, ages 2\u201310"
CLIN_LAB <- "clinical episodes per child-year, ages 0\u20135"

## ============================================================================
## 1. core_eir -- four equilibrium relationships vs EIR
## ============================================================================
## no panel titles here: the y axis already names the outcome and its age band,
## so a title on top of it can only restate it or editorialise. The shape of each
## curve is what the panel is for, and the article says what to make of it.
EIR_MET <- list(
  list(key = "pfpr_2_10", lab = PREV_LAB, pct = TRUE, name = "LM prevalence, ages 2–10"),
  list(key = "clin_0_5", lab = CLIN_LAB, name = "clinical incidence, ages 0–5"),
  list(key = "clin_all", lab = "clinical episodes per person-year, all ages",
       name = "clinical incidence, all ages"),
  list(key = "sev_all", lab = "severe episodes per 1,000 person-years, all ages",
       name = "severe incidence, all ages"))
e_long <- eq %>% filter(grepl("^eir_", scenario)) %>%
  mutate(init_EIR = as.numeric(sub("eir_", "", scenario))) %>%
  select(init_EIR, model, rep, all_of(vapply(EIR_MET, `[[`, "", "key"))) %>%
  pivot_longer(-c(init_EIR, model, rep), names_to = "metric", values_to = "y")
ibm_e <- e_long %>% filter(model == "IBM") %>% group_by(metric) %>%
  group_modify(~ envelope(.x, by = "init_EIR")) %>% ungroup()
ode_e <- e_long %>% filter(model == "fleet") %>% rename(mid = y)

eir_parts <- function(m) list(gi = filter(ibm_e, metric == m$key), go = filter(ode_e, metric == m$key))
ps <- lapply(seq_along(EIR_MET), function(i) {
  m <- EIR_MET[[i]]; e <- eir_parts(m)
  p <- panel_eir_curve(e$gi, e$go, EIR_GRID, m$lab, isTRUE(m$pct))
  ## the x axis is the same in all four; name it once, on the bottom row
  if (i <= 2) p + labs(x = NULL) else p
})
## one collected legend for the whole figure, not a legend sitting inside panel 1:
## with no panel titles left to anchor the eye, a legend in one panel pushes that
## panel's plot area down and the top row stops lining up
g <- patchwork::wrap_plots(ps, ncol = 2) + plot_layout(guides = "collect", axis_titles = "collect") +
  plot_annotation(
    title = "P. falciparum: core transmission relationships at equilibrium",
    subtitle = subt("The same parameter list through both models, across a 120-fold range of transmission intensity."),
    caption = cap("Each model's realised EIR is reported in the article.", ibm_note),
    theme = theme_cmp()) &
  theme(legend.position = "top", legend.justification = "left")
save_fig(g, "core_eir", width = 10, height = 9)

## Each panel is also saved alone, because each is the evidence for a DIFFERENT
## claim in the register: prevalence-eir, clinical-under5-eir, clinical-allage-eir
## and severe-allage-eir. Showing the same four-panel figure against all four
## would not be evidence for any one of them.
for (m in EIR_MET) {
  e <- eir_parts(m)
  save_fig(fig_eir_claim(e$gi, e$go, EIR_GRID, m$lab, isTRUE(m$pct),
                         sprintf("P. falciparum: %s, across transmission intensity", m$name),
                         cap(ibm_note, DEV_NOTE, fig_width = 11)),
           paste0("eir_", m$key), width = 11, height = 5.6)
}

## ============================================================================
## 2. age_clin / age_sev -- one figure per outcome, across transmission
## ============================================================================
## One figure per outcome, because each is the evidence for a DIFFERENT claim:
## a reader looking at age-profile-clinical should not have to find the clinical
## panel among three. And across low, reference and high EIR rather than at the
## reference alone -- the age profile's whole point is that it MOVES with
## transmission, and one EIR cannot show that.
##
## No interpretive panel titles. The axes say what is plotted and the claim says
## what to make of it; a title asserting "disease concentrates in the young" is
## the figure arguing with the reader instead of showing them.
age_eirs <- sort(unique(as.numeric(sub("^eir_", "",
  grep("^eir_", unique(age$scenario), value = TRUE)))))
ap <- age %>% filter(scenario %in% paste0("eir_", age_eirs)) %>%
  mutate(eir = factor(sprintf("EIR %g", as.numeric(sub("^eir_", "", scenario))),
                      levels = sprintf("EIR %g", age_eirs)))
lab_a <- c(clin = "clinical episodes per person-year",
           sev = "severe episodes per 1,000 person-years")

## the panel is shared with render_pv.R: panel_outcome() in validations/_shared/theme.R

## Width follows the number of panels: only some EIR scenarios carry the 12-band
## age profile, because it roughly doubles the IBM's rendering cost.
n_ap <- length(age_eirs)
fw <- 2.0 + 3.0 * n_ap
eir_list <- function(e) sub(", ([^,]*)$", " and \\1", paste(e, collapse = ", "))

g <- panel_outcome(ap, "clin", lab_a[["clin"]]) + plot_annotation(
  title = "P. falciparum: clinical incidence by age band",
  subtitle = subt(sprintf("Final three years of each run, at EIR %s.", eir_list(age_eirs))),
  caption = cap(BAND_NOTE, ibm_note),
  theme = theme_cmp())
save_fig(g, "age_clin", width = fw, height = 5.8)

g <- panel_outcome(ap, "sev", lab_a[["sev"]]) + plot_annotation(
  title = "P. falciparum: severe incidence by age band",
  subtitle = subt("Severe disease in a narrow age band is the rarest thing either model counts, so the IBM's band is very wide above age 5."),
  caption = cap(BAND_NOTE, ibm_note),
  theme = theme_cmp())
save_fig(g, "age_sev", width = fw, height = 5.8)

## ============================================================================
## 2a. core_pop_age -- the POPULATION age structure, default demography
## ============================================================================
## Evidence for population-age-structure, which is about the denominator and
## nothing else. It had been illustrated with the age-profile figure, which
## shows prevalence and incidence by age -- a different quantity entirely. The
## figure is fig_pop_age() in theme.R, shared with render_pv.R.
g <- fig_pop_age(
  age %>% filter(scenario == paste0("eir_", EIR_REF)),
  title = sprintf("P. falciparum: population age structure at EIR %s", EIR_REF),
  subtitle = subt("The denominator every per-capita rate is divided by, compared on its own terms. Default demography: a constant death rate, so the pyramid is close to exponential."),
  caption = cap(POP_NOTE, ibm_note))
save_fig(g, "core_pop_age", width = 11, height = 5.8)

## ============================================================================
## 2b. core_demography -- custom demography: age structure and age-prevalence
## ============================================================================
## Band by band, as every other age figure: the axes name both panels, so
## neither carries a title, and one legend serves the two.
if ("demography" %in% age$scenario) {
  d <- age %>% filter(scenario == "demography") %>% mutate(dens = pop_frac / (age_hi - age_lo))
  sd <- band_summary(d, "dens"); sp <- band_summary(d, "prev")
  ## the top band's shares are not like for like, for the reason fig_pop_age() gives
  n <- nlevels(sd$gi$band)
  g <- (panel_bands(sd$gi, sd$go, POP_DENS_LAB, pct = TRUE, shade = data.frame(x = n)) +
          not_comparable(n) |
        panel_bands(sp$gi, sp$go, "LM prevalence", pct = TRUE)) +
    plot_layout(guides = "collect", axis_titles = "collect") +
    plot_annotation(
      title = sprintf("P. falciparum: custom demography at EIR %s, with high infant and elderly mortality", EIR_REF),
      subtitle = subt("set_demography() with age-specific death rates from 4.8% per year in infancy to 12% per year over 80; fleet derives its equilibrium age structure from the same schedule."),
      caption = cap("Population shares are per band divided by band width, so bands of different width are comparable; the bands cover ages 0–85.", ibm_note),
      theme = theme_cmp()) &
    theme(legend.position = "top", legend.justification = "left")
  save_fig(g, "core_demography", width = 10, height = 5.6)
}

## ============================================================================
## 3. core_seasonal -- the settled annual cycle
## ============================================================================
s <- doy %>% filter(scenario == "seasonal") %>%
  pivot_longer(c(pfpr_2_10, clin_0_5), names_to = "metric", values_to = "y")
ibm_s <- s %>% filter(model == "IBM") %>% group_by(metric) %>%
  group_modify(~ envelope(.x, by = "doy")) %>% ungroup()
ode_s <- s %>% filter(model == "fleet") %>% rename(mid = y)
mon_brk <- cumsum(c(0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30))[c(1, 4, 7, 10)] + 1
## the axes name both panels, so neither carries a title, and one legend serves both
panel_doy <- function(m, ylab, pct = FALSE) {
  gi <- filter(ibm_s, metric == m); go <- filter(ode_s, metric == m)
  ggplot() +
    geom_ribbon(data = gi, aes(doy, ymin = lo, ymax = hi, fill = model), alpha = ENV_ALPHA) +
    geom_line(data = go, aes(doy, mid, colour = model, linetype = model), linewidth = 0.75) +
    geom_line(data = gi, aes(doy, mid, colour = model, linetype = model), linewidth = 0.75) +
    scale_models(shapes = FALSE) + guide_models() +
    scale_x_continuous(breaks = mon_brk, labels = c("Jan", "Apr", "Jul", "Oct")) +
    y_from_zero(pct) +
    labs(x = NULL, y = ylab) + theme_cmp()
}
g <- (panel_doy("pfpr_2_10", PREV_LAB, TRUE) | panel_doy("clin_0_5", CLIN_LAB)) +
  plot_layout(guides = "collect") +
  plot_annotation(
    title = sprintf("P. falciparum: the settled seasonal cycle at EIR %s", EIR_REF),
    subtitle = subt("Final year of the run, weekly bins. Rainfall enters both models through the larval carrying capacity."),
    caption = cap("Seeded at the aseasonal equilibrium, the two models settle onto the same limit cycle during the burn-in.", ibm_note),
    theme = theme_cmp()) &
  theme(legend.position = "top", legend.justification = "left")
save_fig(g, "core_seasonal", width = 10, height = 5)

## ============================================================================
## 4. core_sites -- 63-country monthly comparison (a SNAPSHOT)
## ============================================================================
## The committed cmp_core_sites.png is a snapshot and is deliberately NOT redrawn
## on an ordinary render. Its inputs are the tier-3 sweep, which needs the
## malariaverse site files -- not redistributable, and not in this repo -- so on
## a machine without them this block would otherwise be skipped silently. That is
## fine for the figure, since the committed PNG survives, but leaves no record of
## the fact. Re-draw it deliberately, after running the sweep, alongside
## re-taking the statistics in tables.R:
##
##   FLEET_VALIDATE=... Rscript validations/03-real-settings/run.R
##
##   CMP_REFRESH_SITES=1 Rscript validations/02-scenarios/render.R
##   CMP_REFRESH_SITES=1 Rscript validations/02-scenarios/tables.R
raw <- fc_results("03-real-settings", "raw")
if (!nzchar(Sys.getenv("CMP_REFRESH_SITES"))) {
  message("core_sites: keeping the committed snapshot ",
          "(CMP_REFRESH_SITES=1 to re-draw it from ", raw, ")")
  raw <- ""                                    # skips the block below
}
fs <- list.files(raw, pattern = "_compare[.]rds$", full.names = TRUE)
if (length(fs)) {
  ## read_compare() normalises the model columns to fleet_*: files written
  ## before the blink -> fleet rename carry them as mo_*, and reading raw
  ## readRDS() here is what broke when the sweep stopped writing both names.
  source(file.path(ROOT, "validations", "03-real-settings", "sites_lib.R"))
  v <- bind_rows(lapply(fs, read_compare))
  ## agreement() from the package, not a local copy. There were two local
  ## copies -- this one and ag2() in tables.R -- computing the same four numbers
  ## from the same data for the same claim, and they had already diverged in
  ## naming: this one called mean(y - x) / mean(x) "bias" and printed it as a
  ## percentage of the IBM mean, which is what the other one called "rel_bias".
  ## Deriving one quantity twice is the thing this project exists to catch.
  st_c <- agreement(v$ms_clinical, v$fleet_clinical)
  st_s <- agreement(v$ms_severe, v$fleet_severe)
  ## one colour key for both panels, on top as every legend is: the two share
  ## their limits, so a cell of a given count is the same colour in each
  hex_max <- function(x, y) {
    d <- data.frame(x = x, y = y) %>% filter(is.finite(x), is.finite(y))
    max(layer_data(ggplot(d, aes(x, y)) + geom_hex(bins = 60))$count)
  }
  hex_lim <- c(1, max(hex_max(v$ms_clinical, v$fleet_clinical),
                      hex_max(1000 * v$ms_severe, 1000 * v$fleet_severe)))
  hexp <- function(x, y, st, unit, title) {
    d <- data.frame(x = x, y = y) %>% filter(is.finite(x), is.finite(y))
    top <- unname(quantile(c(d$x, d$y), 0.999))
    ggplot(d, aes(x, y)) +
      geom_hex(bins = 60) +
      geom_abline(slope = 1, intercept = 0, colour = REF, linewidth = 0.8,
                  linetype = REF_LTY) +
      ## The low end of the ramp is near-white on purpose. The counts are wildly
      ## skewed -- 52% of the hex cells carry 0.2% of the sub-site-months, while
      ## the top 5% of cells carry 90% of them -- so a saturated low end spends
      ## most of the plot's ink on almost none of the data and buries the 1:1
      ## ridge it is meant to show. Keeping log10 keeps the sparse cells visible
      ## (they are real, and the scatter is the point); making them faint stops
      ## them out-shouting the ridge.
      scale_fill_gradient(low = HEX_LOW, high = HEX_HIGH, transform = "log10",
                          limits = hex_lim, name = "sub-site-months",
                          breaks = c(1, 10, 100, 1000, 10000),
                          labels = scales::label_comma(),
                          guide = guide_colourbar(direction = "horizontal",
                                                  theme = theme(legend.key.width = unit(12, "lines"),
                                                                legend.key.height = unit(0.6, "lines")))) +
      coord_equal(xlim = c(0, top), ylim = c(0, top), expand = FALSE) +
      labs(title = title,
           subtitle = sprintf("r = %.3f \u00b7 slope = %.3f\nfleet \u2212 IBM on average: %+.1f%% of the IBM mean", st$cor, st$slope, 100 * st$rel_bias),
           x = sprintf("IBM (%s)", unit), y = sprintf("fleet (%s)", unit)) +
      theme_cmp() + theme_panel_title() + theme(panel.grid.major = element_blank())
  }
  g <- (hexp(v$ms_clinical, v$fleet_clinical, st_c, "episodes per person-year", "monthly clinical incidence") |
        hexp(1000 * v$ms_severe, 1000 * v$fleet_severe, st_s, "episodes per 1,000 person-years",
             "monthly severe incidence")) +
    plot_layout(guides = "collect") +
    plot_annotation(
      title = sprintf("P. falciparum: site files, %s sub-site-months across %d countries",
                      format(st_c$n, big.mark = ","), length(unique(v$iso3c))),
      subtitle = subt(sprintf("Every P. falciparum admin-1 \u00d7 urban/rural sub-site in the malariaverse site files, %d\u2013%d, with its full intervention history.",
                              min(v$year), max(v$year))),
      caption = cap("Dotted line = perfect agreement. All ages, P. falciparum only on both sides. Cell colour = number of sub-site-months (log scale); the axes stop at the 99.9th percentile of the values, and r and slope are over all of them. IBM values are the site files' own calibration diagnostic runs; fleet was run here from the same site_parameters() lists."),
      theme = theme_cmp()) &
    theme(legend.position = "top", legend.justification = "left",
          legend.title = element_text(size = rel(0.8), colour = INK2, vjust = 0.9))
  ## the panels are square, so the canvas is as wide as two of them: any wider
  ## and the whole figure sits indented from the others' left edge
  save_fig(g, "core_sites", width = 8.8, height = 6.3)
}

## ============================================================================
## 5. int_timeseries -- five interventions, prevalence + clinical incidence
## ============================================================================
INT <- names(INT_LABELS)
m <- monthly %>% filter(scenario %in% INT, year >= BURN_Y - 3, year < BURN_Y + 6) %>%
  select(scenario, model, rep, year, pfpr_2_10, clin_0_5) %>%
  pivot_longer(c(pfpr_2_10, clin_0_5), names_to = "metric", values_to = "y") %>%
  mutate(scenario = factor(scenario, levels = INT, labels = INT_LABELS),
         metric = factor(metric, levels = c("pfpr_2_10", "clin_0_5"), labels = c(PREV_LAB, CLIN_LAB)))
ibm_m <- m %>% filter(model == "IBM") %>% group_by(scenario, metric) %>%
  group_modify(~ envelope(.x, by = "year")) %>% ungroup()
ode_m <- m %>% filter(model == "fleet") %>% rename(mid = y)
smc_rounds <- data.frame(scenario = factor(INT_LABELS[["smc"]], levels = INT_LABELS),
                         x = as.vector(sapply(0:2, function(y) BURN_Y + y + (c(0, 30, 60, 90) + 200) / 365)))
onset_lab <- data.frame(scenario = factor(INT_LABELS[[INT[1]]], levels = INT_LABELS),
                        metric = factor(PREV_LAB, levels = c(PREV_LAB, CLIN_LAB)))
## One column per outcome, each its own plot, as programme_ts: facet_grid frees y
## by ROW, and prevalence and clinical incidence share no scale -- in one grid the
## prevalence column sat squashed on the clinical axis, as a raw proportion.
it_col <- function(mlab, first, pct) {
  gi <- filter(ibm_m, metric == mlab); go <- filter(ode_m, metric == mlab)
  p <- ggplot() + campaign_rules(smc_rounds) + deploy_rule(BURN_Y)
  ## at the foot of the rule, where no series runs: prevalence sits near the top
  if (first) p <- p + geom_text(data = onset_lab, aes(x = BURN_Y, y = -Inf, label = "deployment"),
                                hjust = -0.08, vjust = -0.6, size = ANNOT_SIZE, colour = INK2,
                                family = FONT)
  p <- p +
    geom_ribbon(data = gi, aes(year, ymin = lo, ymax = hi, fill = model), alpha = ENV_ALPHA) +
    geom_line(data = go, aes(year, mid, colour = model, linetype = model), linewidth = 0.75) +
    geom_line(data = gi, aes(year, mid, colour = model, linetype = model), linewidth = 0.75) +
    facet_grid(scenario ~ metric, scales = "free_y", switch = "y",
               labeller = labeller(metric = label_wrap_gen(30))) +
    scale_models(shapes = FALSE) + guide_models() +
    scale_x_continuous(breaks = seq(BURN_Y - 3, BURN_Y + 6, 3), labels = lab_years(BURN_Y)) +
    y_from_zero(pct, headroom = 0.08) +
    labs(x = YEARS_LAB, y = NULL) + theme_cmp()
  if (first) p + theme(strip.text.y.left = element_text(angle = 0, hjust = 1, vjust = 1))
  else p + theme(strip.text.y = element_blank())
}
g <- (it_col(PREV_LAB, TRUE, TRUE) | it_col(CLIN_LAB, FALSE, FALSE)) +
  plot_layout(guides = "collect", axis_titles = "collect", widths = c(1, 1)) +
  plot_annotation(
    title = "P. falciparum: the same deployment through both models",
    subtitle = subt(sprintf("Monthly series, three years before to six after deployment, EIR %s. SMC: the same EIR in a seasonal setting, three years of rounds (marked). The other two transmission levels are in the impact figure.", EIR_REF)),
    caption = cap("Each row is one intervention layered on the same baseline with the ordinary malariasimulation set_*() builders.", ibm_note),
    theme = theme_cmp()) &
  theme(legend.position = "top", legend.justification = "left")
save_fig(g, "int_timeseries", width = 10, height = 12)

## ============================================================================
## 5b. programme_ts -- long-horizon programmes: nothing / one thing / everything
## ============================================================================
## Section 5 isolates one builder over 6 years, which is the shape for attributing
## a difference. This is the shape for seeing what a programme does: 15 years past
## deployment, seasonal, with the repeated-campaign dynamics visible. Four metrics
## get four SEPARATE faceted columns rather than one facet_grid, because
## facet_grid frees y by row and here the scales differ by COLUMN -- prevalence,
## two incidence families and severe share no axis.
TS <- names(TS_LABELS)
if (all(TS %in% monthly$scenario)) {
  TS_MET <- list(
    list(key = "pfpr_2_10", title = PREV_LAB, pct = TRUE),
    list(key = "clin_0_5",  title = CLIN_LAB),
    list(key = "clin_all",  title = "clinical episodes per person-year, all ages"),
    list(key = "sev_all",   title = "severe episodes per 1,000 person-years, all ages"))
  ts_long <- monthly %>%
    filter(scenario %in% TS, year >= BURN_Y - 2, year <= BURN_Y + TS_YEARS) %>%
    select(scenario, model, rep, year, all_of(vapply(TS_MET, `[[`, "", "key"))) %>%
    pivot_longer(-c(scenario, model, rep, year), names_to = "metric", values_to = "y") %>%
    mutate(scenario = factor(scenario, levels = TS, labels = TS_LABELS))
  ibm_t <- ts_long %>% filter(model == "IBM") %>% group_by(scenario, metric) %>%
    group_modify(~ envelope(.x, by = "year")) %>% ungroup()
  ode_t <- ts_long %>% filter(model == "fleet") %>% rename(mid = y)
  ## net distributions marked only in the two rows that have them -- the SMC
  ## pulses are 4 a year for 15 years and would be a picket fence, so those are
  ## left to show themselves in the clinical sawtooth
  net_x <- data.frame(
    scenario = factor(rep(TS_LABELS[c("ts_nets", "ts_all")], each = 5L),
                      levels = TS_LABELS),
    x = rep(BURN_Y + seq(0, by = TS_NET_EVERY, length.out = 5L), times = 2L))

  ## the column header is a facet strip, as every other figure's, so the legend
  ## sits above the headers rather than between them and the panels
  ts_col <- function(m, first) {
    gi <- filter(ibm_t, metric == m$key) %>% mutate(hdr = m$title)
    go <- filter(ode_t, metric == m$key) %>% mutate(hdr = m$title)
    p <- ggplot() +
      campaign_rules(net_x) + deploy_rule(BURN_Y) +
      geom_ribbon(data = gi, aes(year, ymin = lo, ymax = hi, fill = model), alpha = ENV_ALPHA) +
      geom_line(data = go, aes(year, mid, colour = model, linetype = model), linewidth = 0.6) +
      geom_line(data = gi, aes(year, mid, colour = model, linetype = model), linewidth = 0.6) +
      facet_grid(scenario ~ hdr, switch = "y", labeller = labeller(hdr = strip_lines)) +
      scale_models(shapes = FALSE) + guide_models() +
      scale_x_continuous(breaks = BURN_Y + seq(0, TS_YEARS, 5), labels = lab_years(BURN_Y)) +
      y_from_zero(isTRUE(m$pct), headroom = 0.08) +
      labs(x = YEARS_LAB, y = NULL) + theme_cmp()
    ## scenario strips on the leftmost column only; repeating them four times
    ## would cost a third of the width and say nothing new
    if (first) p + theme(strip.text.y.left = element_text(angle = 0, hjust = 1, vjust = 1))
    else p + theme(strip.text.y = element_blank())
  }
  ps <- lapply(seq_along(TS_MET), function(i) ts_col(TS_MET[[i]], i == 1L))
  g <- patchwork::wrap_plots(ps, nrow = 1, widths = c(1, 1, 1, 1)) +
    plot_layout(guides = "collect", axis_titles = "collect") +
    plot_annotation(
      title = "P. falciparum: programmes over fifteen years through both models",
      subtitle = subt(sprintf("Monthly series at EIR %s in a seasonal setting, from two years before deployment. Every row carries 20%% baseline case management; rows 2–4 add one intervention, row 5 adds all three. Grey rules mark the five net distributions.", EIR_REF)),
      caption = cap("The dashed rule is deployment. Nets: 80% coverage every 3 years, 5-year mean retention. SMC: 4 monthly rounds a year, ages 3 months to 5 years, 90% coverage. Case management: SP-AQ, coverage of clinical cases raised from 20% to 60%.",
                    "The IBM band is hard to resolve here — 15 years of monthly points is ~3 px per month — so its width is given instead: over the months carrying the top quartile of burden the replicate band is 26% of the panel peak for severe incidence, and 3–6% for the other three. Severe is the noisiest because a 30-day bin holds only ~20 severe episodes at the seasonal peak in a population of 10,000.",
                    ibm_note),
      theme = theme_cmp()) &
    theme(legend.position = "top", legend.justification = "left")
  save_fig(g, "programme_ts", width = 12, height = 12)
} else {
  message("programme_ts skipped: ts_* scenarios not in rep_monthly.csv")
}

## ============================================================================
## 6. int_impact -- % reduction over the first three years, IBM range vs fleet
## ============================================================================
## Four outcomes: the two young-child measures a trial would report, and the two
## all-age measures a programme carries. Severe is the noisiest of them in the
## IBM, which the replicate range shows honestly.
##
## Three transmission levels, not one. Impact is not a property of an
## intervention on its own: over PROFILE_EIR fleet's reduction in all-age severe
## incidence falls by a factor of five for nets, rises for RTS,S, and changes
## sign for perennial chemoprevention. A claim tested at a single EIR says
## nothing about the other two, and tests the two models where they are least
## likely to differ.
MET_KEY <- c(pfpr = "LM prevalence, ages 2\u201310",
             clin05 = "clinical incidence, ages 0\u20135",
             clinall = "clinical incidence, all ages",
             sevall = "severe incidence, all ages")
MET_R <- unname(MET_KEY)
INT_SCEN <- unlist(lapply(PROFILE_EIR, function(E) int_scenario(INT, E)))
EIR_LAB  <- sprintf("EIR %g", PROFILE_EIR)
red <- monthly %>% filter(scenario %in% INT_SCEN) %>%
  mutate(phase = case_when(year >= BURN_Y - 3 & year < BURN_Y ~ "pre",
                           year >= BURN_Y & year < BURN_Y + 3 ~ "post", TRUE ~ NA_character_)) %>%
  filter(!is.na(phase)) %>%
  group_by(scenario, model, rep, phase) %>%
  summarise(pfpr = mean(pfpr_2_10), clin05 = mean(clin_0_5),
            clinall = mean(clin_all), sevall = mean(sev_all), .groups = "drop") %>%
  pivot_longer(all_of(names(MET_KEY)), names_to = "metric", values_to = "v") %>%
  pivot_wider(names_from = phase, values_from = v) %>%
  mutate(reduction = 1 - post / pre,
         metric = unname(MET_KEY[metric])) %>%
  select(scenario, model, rep, metric, reduction)
## scenario -> (intervention, EIR). The convention is int_scenario()'s, in the
## package, so the renderer cannot drift from the runner that named the rows.
red <- bind_cols(red, int_parts(red$scenario)) %>% select(-scenario)
ibm_r <- red %>% filter(model == "IBM") %>% group_by(intervention, eir, metric) %>%
  summarise(mid = replicate_band(reduction)$centre, lo = replicate_band(reduction)$lower,
            hi = replicate_band(reduction)$upper, .groups = "drop") %>% mutate(model = "IBM")
ode_r <- red %>% filter(model == "fleet") %>%
  transmute(intervention, eir, metric, mid = reduction, model = "fleet")
both <- bind_rows(ibm_r, ode_r) %>%
  mutate(scenario = factor(intervention, levels = INT, labels = INT_LABELS),
         metric = factor(metric, levels = MET_R),
         eir = factor(eir, levels = PROFILE_EIR, labels = EIR_LAB)) %>%
  select(-intervention)
## Round before writing. This file is committed and CI byte-compares it against a
## fresh render, but the values come out of quantile() on different hardware, and
## cross-platform floating point is not bit-identical: a Linux runner reproduced
## 0.324024697880216 where this machine wrote ...217, one ulp, and the check
## failed on it. These are summary percentages for an article, so nothing needs
## more than a few significant figures; 10 is far beyond the reporting precision
## and far above the platform noise, which makes the artifact reproducible.
write.csv(dplyr::mutate(both, dplyr::across(where(is.numeric), ~ signif(.x, 10))),
          file.path(DDIR, "int_impact_summary.csv"), row.names = FALSE)
## The numeric columns that used to sit beside the panels are gone: at four
## outcomes by three transmission levels they are 144 numbers, which is a table
## and not a figure. int_impact_summary.csv carries them, and is committed. The
## figure is fig_impact() in theme.R, shared with render_pv.R.
g <- fig_impact(both, INT_LABELS,
  title = "P. falciparum: intervention impact over the first three years, at three transmission levels",
  subtitle = subt("Each intervention deployed unchanged at EIR 3, 20 and 120,",
                  "relative to the three pre-deployment years of the same run.",
                  "SMC is run in a seasonal setting, the other five without seasonality."),
  caption = cap(IMPACT_NOTE, "Plotted medians are in results/int_impact_summary.csv.",
                "Impact varies with transmission in both directions — nets and",
                "case management fall away as transmission rises, RTS,S and SMC",
                "strengthen — so a single figure per intervention would not be an",
                "effect size.", ibm_note))
save_fig(g, "int_impact", width = 12, height = 13)

## ---- console summary ---------------------------------------------------------
cat("figures written", if (SMOKE) "to validations/02-scenarios/results/plots/smoke" else "to man/figures and vignettes", "\n\n")
print(both %>% select(scenario, eir, metric, model, mid) %>% mutate(mid = round(mid, 3)) %>%
        pivot_wider(names_from = model, values_from = mid) %>% mutate(scenario = sub("\n.*", "", scenario)), n = 20)
cat("\nrealised EIR (final 3 years):\n")
print(eq %>% filter(grepl("^eir_", scenario)) %>% group_by(scenario, model) %>%
        summarise(eir = round(mean(eir_realised), 2), pfpr = round(mean(pfpr_2_10), 3), .groups = "drop") %>%
        pivot_wider(names_from = model, values_from = c(eir, pfpr)), n = 20)
cat("\nrun time:\n")
print(timing %>% group_by(model) %>%
        summarise(runs = n(), s_per_sim_year = round(sum(elapsed_s) / sum(years), 2),
                  mean_run_s = round(mean(elapsed_s), 1), .groups = "drop"))
