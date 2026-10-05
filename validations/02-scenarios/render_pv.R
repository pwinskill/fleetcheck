# The P. vivax comparison figures, from the vivax suite's CSVs (no model runs).
#
#   Rscript validations/02-scenarios/render_pv.R       # -> man/figures and vignettes
#
# The vivax counterpart of render.R, in the same house style (theme.R):
#   pv_eir         four equilibrium relationships vs EIR (2x2)
#   pv_eir_*       each of those alone, and hypnozoite carriage, one per claim
#   pv_age         age profiles of LM prevalence and clinical incidence at EIR 1, 3, 10
#   pv_age_clin    the clinical age profile alone
#   pv_pop_age     population age structure at EIR_REF_PV
#   pv_int_impact  % reduction per intervention, IBM (replicate band) vs fleet

if (nzchar(.l <- Sys.getenv("FLEET_LIB"))) .libPaths(c(.l, .libPaths()))
.f <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))
ROOT <- if (length(.f)) normalizePath(dirname(.f), "/") else getwd()
while (!file.exists(file.path(ROOT, "DESCRIPTION")) && dirname(ROOT) != ROOT)
  ROOT <- dirname(ROOT)
if (!file.exists(file.path(ROOT, "DESCRIPTION")))
  stop("run this from inside the fleetcheck checkout (no DESCRIPTION found above ", getwd(), ")")
suppressMessages({library(dplyr); library(tidyr)})
if (requireNamespace("pkgload", quietly = TRUE)) {
  suppressMessages(pkgload::load_all(ROOT, quiet = TRUE))
} else {
  suppressMessages(library(fleetcheck))
}
source(file.path(ROOT, "validations", "_shared", "theme.R"))

SMOKE <- nzchar(Sys.getenv("CMP_SMOKE"))
DDIR <- file.path(ROOT, "validations", "02-scenarios", "results", "pv")
if (SMOKE) {                                   # smoke data must never overwrite the real figures
  BURN_Y <- 1L; DDIR <- file.path(DDIR, "smoke")
  out_dir <- file.path(ROOT, "validations", "02-scenarios", "results", "plots", "smoke")
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  save_fig <- function(g, name, width, height, dpi = 200)
    ggsave(file.path(out_dir, paste0("cmp_", name, ".png")), g, width = width,
           height = height, dpi = dpi, device = ragg::agg_png, bg = SURFACE)
}
rd <- function(part) read.csv(file.path(DDIR, paste0("rep_", part, ".csv")), stringsAsFactors = FALSE)
eq <- rd("eq"); age <- rd("age"); monthly <- rd("monthly")
n_rep <- max(eq$rep)
ibm_note <- sprintf(paste(
  "Both models start from set_equilibrium()'s seed and run the same %d-year burn-in.",
  "IBM: %d stochastic replicates of %s people; line or point = median, shaded band or bar = its replicate band, median \u00b1 1.28 SD, the 10\u201390%% interval read from every replicate.",
  "fleet: one deterministic run."), BURN_Y, n_rep, format(POP, big.mark = ","))

## ---- 1. equilibrium vs EIR -----------------------------------------------------
EIR_MET <- list(
  list(key = "pvpr_2_10", lab = "LM prevalence, ages 2–10", pct = TRUE,
       name = "LM prevalence, ages 2–10"),
  list(key = "clin_0_5", lab = "clinical episodes per child-year, ages 0–5",
       name = "clinical incidence, ages 0–5"),
  list(key = "clin_all", lab = "clinical episodes per person-year, all ages",
       name = "clinical incidence, all ages"),
  list(key = "relapse_all", lab = "relapses per person-year, all ages",
       name = "relapse incidence, all ages"))
## Hypnozoite carriage is a claim of its own, so it gets a figure of its own, but
## stays out of the 2x2, which shows the burden a programme is judged on.
EIR_ONE <- list(list(key = "hyp_all", lab = "share carrying hypnozoites, all ages", pct = TRUE,
                     name = "hypnozoite carriage, all ages"))
e_long <- eq %>% filter(grepl("^eir_", scenario)) %>%
  mutate(init_EIR = as.numeric(sub("eir_", "", scenario))) %>%
  select(init_EIR, model, rep, all_of(vapply(c(EIR_MET, EIR_ONE), `[[`, "", "key"))) %>%
  pivot_longer(-c(init_EIR, model, rep), names_to = "metric", values_to = "y")
ibm_e <- e_long %>% filter(model == "IBM") %>% group_by(metric) %>%
  group_modify(~ envelope(.x, by = "init_EIR")) %>% ungroup()
ode_e <- e_long %>% filter(model == "fleet") %>% rename(mid = y)
eir_parts <- function(m) list(gi = filter(ibm_e, metric == m$key), go = filter(ode_e, metric == m$key))
ps <- lapply(seq_along(EIR_MET), function(i) {
  m <- EIR_MET[[i]]; e <- eir_parts(m)
  p <- panel_eir_curve(e$gi, e$go, EIR_GRID_PV, m$lab, isTRUE(m$pct))
  if (i <= 2) p + labs(x = NULL) else p
})
g <- patchwork::wrap_plots(ps, ncol = 2) + plot_layout(guides = "collect", axis_titles = "collect") +
  plot_annotation(
    title = "P. vivax: core transmission relationships at equilibrium",
    subtitle = subt("The same vivax parameter list through both models, across a 100-fold range of transmission intensity."),
    caption = cap(ibm_note),
    theme = theme_cmp()) &
  theme(legend.position = "top", legend.justification = "left")
save_fig(g, "pv_eir", width = 10, height = 9)
## each panel alone too, because each is the evidence for a different claim
for (m in c(EIR_MET, EIR_ONE)) {
  e <- eir_parts(m)
  save_fig(fig_eir_claim(e$gi, e$go, EIR_GRID_PV, m$lab, isTRUE(m$pct),
                         sprintf("P. vivax: %s, across transmission intensity", m$name),
                         cap(ibm_note, DEV_NOTE, fig_width = 11)),
           paste0("pv_eir_", m$key), width = 11, height = 5.6)
}

## ---- 2. age profiles -------------------------------------------------------------
## band by band, as falciparum's age figures: prevalence and clinical incidence
## at the three profile EIRs. No claim rests on this overview, so no band is shaded.
ap_pv <- age %>% filter(scenario %in% paste0("eir_", PROFILE_EIR_PV)) %>%
  mutate(eir = factor(sprintf("EIR %s", sub("eir_", "", scenario)),
                      levels = sprintf("EIR %g", PROFILE_EIR_PV)))
fw <- 2.0 + 3.0 * length(PROFILE_EIR_PV)
g <- (panel_outcome(ap_pv, "prev", "LM prevalence", pct = TRUE, scored = FALSE) + labs(x = NULL)) /
  panel_outcome(ap_pv, "clin", "clinical episodes per person-year", scored = FALSE) +
  plot_layout(guides = "collect") +
  plot_annotation(
    title = "P. vivax: age profiles at three transmission levels",
    subtitle = subt("LM prevalence and clinical incidence by age band, final three years of each run."),
    caption = cap("Bands are finer in childhood, so equal spacing here is not equal width in years.", ibm_note),
    theme = theme_cmp()) &
  theme(legend.position = "top", legend.justification = "left")
save_fig(g, "pv_age", width = fw, height = 9.5)
## clinical alone, with the bands the claim does not score shaded: the evidence
## for age-profile-clinical-pv, which says nothing about prevalence
g <- panel_outcome(ap_pv, "clin", "clinical episodes per person-year") +
  plot_annotation(
    title = "P. vivax: clinical incidence by age band",
    subtitle = subt("Final three years of each run, at EIR 1, 3 and 10."),
    caption = cap(BAND_NOTE, ibm_note), theme = theme_cmp())
save_fig(g, "pv_age_clin", width = fw, height = 5.8)

## ---- 2b. population age structure ---------------------------------------------
## Evidence for population-age-structure under vivax: the vivax block ages and
## dies through compartments of its own, so its denominator is checked on its
## own terms, as render.R does for falciparum. Shares per year of age; the top
## band is fleet's absorbing open-ended group and not comparable; the test
## renormalises to the 0-60 population.
g <- fig_pop_age(
  age %>% filter(scenario == paste0("eir_", EIR_REF_PV)),
  title = sprintf("P. vivax: population age structure at EIR %s", EIR_REF_PV),
  subtitle = subt("The denominator every per-capita rate is divided by, compared on its own terms. Default demography: a constant death rate, so the pyramid is close to exponential."),
  caption = cap(POP_NOTE, ibm_note))
save_fig(g, "pv_pop_age", width = 11, height = 5.8)

## ---- 3. intervention impact -----------------------------------------------------
INT <- names(INT_LABELS_PV)
MET_KEY <- c(pvpr_2_10 = "LM prevalence, ages 2–10",
             clin_0_5 = "clinical incidence, ages 0–5",
             clin_all = "clinical incidence, all ages",
             relapse_all = "relapse incidence, all ages")
INT_SCEN <- unlist(lapply(PROFILE_EIR_PV, function(E) int_scenario(INT, E, ref = EIR_REF_PV)))
EIR_LAB <- sprintf("EIR %g", PROFILE_EIR_PV)
red <- monthly %>% filter(scenario %in% INT_SCEN) %>%
  mutate(phase = case_when(year >= BURN_Y - 3 & year < BURN_Y ~ "pre",
                           year >= BURN_Y & year < BURN_Y + 3 ~ "post", TRUE ~ NA_character_)) %>%
  filter(!is.na(phase)) %>% group_by(scenario, model, rep, phase) %>%
  summarise(across(all_of(names(MET_KEY)), mean), .groups = "drop") %>%
  pivot_longer(all_of(names(MET_KEY)), names_to = "metric", values_to = "v") %>%
  pivot_wider(names_from = phase, values_from = v) %>%
  mutate(reduction = 1 - post / pre, metric = unname(MET_KEY[metric])) %>%
  select(scenario, model, rep, metric, reduction)
red <- bind_cols(red, int_parts(red$scenario, ref = EIR_REF_PV)) %>% select(-scenario)
ibm_r <- red %>% filter(model == "IBM") %>% group_by(intervention, eir, metric) %>%
  summarise(mid = replicate_band(reduction)$centre, lo = replicate_band(reduction)$lower,
            hi = replicate_band(reduction)$upper, .groups = "drop") %>% mutate(model = "IBM")
ode_r <- red %>% filter(model == "fleet") %>%
  transmute(intervention, eir, metric, mid = reduction, model = "fleet")
both <- bind_rows(ibm_r, ode_r) %>%
  mutate(scenario = factor(intervention, levels = INT, labels = INT_LABELS_PV),
         metric = factor(metric, levels = unname(MET_KEY)),
         eir = factor(eir, levels = PROFILE_EIR_PV, labels = EIR_LAB)) %>%
  select(-intervention)
write.csv(dplyr::mutate(both, dplyr::across(where(is.numeric), ~ signif(.x, 10))),
          file.path(DDIR, "int_impact_summary.csv"), row.names = FALSE)
g <- fig_impact(both, INT_LABELS_PV,
  title = "P. vivax: intervention impact over the first three years, at three transmission levels",
  subtitle = subt("Each intervention deployed unchanged at EIR 1, 3 and 10, relative to",
                  "the three pre-deployment years of the same run. Radical cure switches",
                  "first-line treatment from 20% chloroquine to 60% chloroquine plus",
                  "primaquine or tafenoquine."),
  caption = cap(IMPACT_NOTE, "Plotted medians are in results/pv/int_impact_summary.csv. Under indoor",
                "residual spraying most of the gap is the IBM's: it evaluates relapses only on",
                "days when someone is bitten, and spraying makes biteless days common in a",
                "10,000-person run, so it loses relapses fleet keeps (intervention-impact-pv).",
                ibm_note))
save_fig(g, "pv_int_impact", width = 12, height = 11)

## ---- 4. real settings (a snapshot, as for falciparum) -----------------------------
## Drawn from the vivax tier-3 sweep, whose inputs are the restricted site files,
## so only on request, after running it:
##   FLEET_VALIDATE=... CMP_PARASITE=pv Rscript validations/03-real-settings/run.R
##   CMP_REFRESH_SITES=1 Rscript validations/02-scenarios/render_pv.R
raw <- fc_results("03-real-settings", "pv", "raw")
if (!nzchar(Sys.getenv("CMP_REFRESH_SITES"))) {
  message("pv_sites: keeping the committed snapshot (CMP_REFRESH_SITES=1 to re-draw it from ",
          raw, ")")
  raw <- ""
}
fs <- list.files(raw, pattern = "_compare[.]rds$", full.names = TRUE)
if (length(fs)) {
  Sys.setenv(CMP_PARASITE = "pv")
  source(file.path(ROOT, "validations", "03-real-settings", "sites_lib.R"))
  v <- bind_rows(lapply(fs, read_compare))
  st <- agreement(v$ms_clinical, v$fleet_clinical)
  d <- data.frame(x = v$ms_clinical, y = v$fleet_clinical) %>% filter(is.finite(x), is.finite(y))
  top <- unname(quantile(c(d$x, d$y), 0.999))
  g <- ggplot(d, aes(x, y)) +
    geom_hex(bins = 60) +
    geom_abline(slope = 1, intercept = 0, colour = REF, linewidth = 0.8, linetype = REF_LTY) +
    scale_fill_gradient(low = HEX_LOW, high = HEX_HIGH, transform = "log10",
                        name = "sub-site\nmonths", breaks = c(1, 10, 100, 1000, 10000),
                        labels = scales::label_comma()) +
    coord_equal(xlim = c(0, top), ylim = c(0, top), expand = FALSE) +
    labs(title = sprintf("P. vivax: site files, %s sub-site-months across %d countries",
                         format(st$n, big.mark = ","), length(unique(v$iso3c))),
         subtitle = sprintf("Monthly clinical incidence, all ages, %d–%d · r = %.3f · slope = %.3f · fleet − IBM on average %+.1f%% of the IBM mean",
                            min(v$year), max(v$year), st$cor, st$slope, 100 * st$rel_bias),
         x = "IBM (episodes per person-year)", y = "fleet (episodes per person-year)",
         caption = cap(paste("Dotted line = perfect agreement. The axes stop at the 99.9th",
                             "percentile of the values; r and slope are over all of them. Up to ten vivax sub-sites per",
                             "country, spread across its vivax EIR range, with their full",
                             "intervention histories. IBM values are the site files' own",
                             "calibration diagnostic runs (P. vivax rows); fleet was run here",
                             "from the same site_parameters(parasite = \"vivax\") lists."),
                       fig_width = 7.5)) +
    theme_cmp() + theme(legend.position = "right", legend.justification = "center",
                        legend.title = element_text(size = rel(0.8), colour = INK2),
                        panel.grid.major = element_blank())
  save_fig(g, "pv_sites", width = 7.5, height = 6.2)
}

cat("vivax figures written", if (SMOKE) "to validations/02-scenarios/results/plots/smoke" else
      "to man/figures and vignettes", "\n")
