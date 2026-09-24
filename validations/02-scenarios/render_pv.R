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
  "IBM: %d stochastic replicates of %s people, %d-year burn-in; line/point = median, band/bar = median ± 1.28 SD.",
  "fleet: one deterministic run seeded at the IBM's equilibrium."), n_rep, format(POP, big.mark = ","), BURN_Y)

## ---- 1. equilibrium vs EIR -----------------------------------------------------
EIR_MET <- list(
  list(key = "pvpr_2_10", lab = "LM prevalence, ages 2–10", pct = TRUE),
  list(key = "clin_0_5", lab = "clinical episodes per child-year, ages 0–5"),
  list(key = "clin_all", lab = "clinical episodes per person-year, all ages"),
  list(key = "relapse_all", lab = "relapses per person-year, all ages"))
## Hypnozoite carriage is a claim of its own, so it gets a figure of its own, but
## stays out of the 2x2, which shows the burden a programme is judged on.
EIR_ONE <- list(list(key = "hyp_all", lab = "share carrying hypnozoites, all ages", pct = TRUE))
e_long <- eq %>% filter(grepl("^eir_", scenario)) %>%
  mutate(init_EIR = as.numeric(sub("eir_", "", scenario))) %>%
  select(init_EIR, model, rep, all_of(vapply(c(EIR_MET, EIR_ONE), `[[`, "", "key"))) %>%
  pivot_longer(-c(init_EIR, model, rep), names_to = "metric", values_to = "y")
ibm_e <- e_long %>% filter(model == "IBM") %>% group_by(metric) %>%
  group_modify(~ envelope(.x, by = "init_EIR")) %>% ungroup()
ode_e <- e_long %>% filter(model == "fleet") %>% rename(mid = y)
panel_eir <- function(metric_id, ylab) {
  gi <- filter(ibm_e, metric == metric_id); go <- filter(ode_e, metric == metric_id)
  ggplot() +
    geom_linerange(data = gi, aes(init_EIR, ymin = lo, ymax = hi, colour = model),
                   linewidth = 0.7, alpha = 0.55, show.legend = FALSE) +
    geom_line(data = go, aes(init_EIR, mid, colour = model, linetype = model), linewidth = 0.8) +
    geom_line(data = gi, aes(init_EIR, mid, colour = model, linetype = model), linewidth = 0.8) +
    geom_point(data = gi, aes(init_EIR, mid, colour = model, shape = model, fill = model),
               size = 2.6, stroke = 0.5) +
    geom_point(data = go, aes(init_EIR, mid, colour = model, shape = model, fill = model),
               size = 2.6, stroke = 0.5) +
    scale_x_log10(breaks = EIR_GRID_PV, minor_breaks = NULL) +
    scale_models() + guide_models() +
    labs(x = "EIR (infectious bites per adult per year)", y = ylab) +
    theme_cmp()
}
panel_one <- function(m) {
  panel_eir(m$key, m$lab) +
    if (isTRUE(m$pct)) scale_y_continuous(limits = c(0, NA), labels = scales::percent,
                                          expand = expansion(mult = c(0, 0.06)))
    else scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.06)))
}
ps <- lapply(seq_along(EIR_MET), function(i) {
  p <- panel_one(EIR_MET[[i]])
  if (i <= 2) p + labs(x = NULL) else p
})
g <- patchwork::wrap_plots(ps, ncol = 2) + plot_layout(guides = "collect") +
  plot_annotation(
    title = "P. vivax: core transmission relationships at equilibrium",
    subtitle = "The same vivax parameter list through both models, across a 100-fold range of transmission intensity",
    caption = cap("x = the EIR passed to set_equilibrium().", ibm_note),
    theme = theme_cmp()) &
  theme(legend.position = "top", legend.justification = "left")
save_fig(g, "pv_eir", width = 10, height = 9)
## each panel alone too, because each is the evidence for a different claim
for (m in c(EIR_MET, EIR_ONE)) {
  one <- panel_one(m) + labs(x = "EIR passed to set_equilibrium()") +
    plot_annotation(caption = cap(ibm_note, fig_width = 6.2), theme = theme_cmp()) &
    theme(legend.position = "top", legend.justification = "left")
  save_fig(one, paste0("pv_eir_", m$key), width = 6.2, height = 4.4)
}

## ---- 2. age profiles -------------------------------------------------------------
a_long <- age %>% filter(scenario %in% paste0("eir_", PROFILE_EIR_PV)) %>%
  mutate(eir = factor(sprintf("EIR %s", sub("eir_", "", scenario)),
                      levels = sprintf("EIR %g", PROFILE_EIR_PV))) %>%
  select(eir, age_mid, model, rep, prev, clin) %>%
  pivot_longer(c(prev, clin), names_to = "metric", values_to = "y")
ibm_a <- a_long %>% filter(model == "IBM") %>% group_by(eir, metric) %>%
  group_modify(~ envelope(.x, by = "age_mid")) %>% ungroup()
ode_a <- a_long %>% filter(model == "fleet") %>% rename(mid = y)
panel_age <- function(metric_id, ylab, pct = FALSE) {
  gi <- filter(ibm_a, metric == metric_id); go <- filter(ode_a, metric == metric_id)
  ggplot() +
    geom_ribbon(data = gi, aes(age_mid, ymin = lo, ymax = hi, fill = model), alpha = ENV_ALPHA,
                show.legend = FALSE) +
    geom_line(data = go, aes(age_mid, mid, colour = model, linetype = model), linewidth = 0.8) +
    geom_line(data = gi, aes(age_mid, mid, colour = model, linetype = model), linewidth = 0.8) +
    facet_wrap(~ eir, nrow = 1) +
    scale_x_sqrt(breaks = c(1, 5, 10, 20, 40, 60, 85)) +
    (if (pct) scale_y_continuous(labels = scales::percent, limits = c(0, NA))
     else scale_y_continuous(limits = c(0, NA))) +
    scale_models(shapes = FALSE) + guide_models() +
    labs(x = "age (years, square-root scale)", y = ylab) +
    theme_cmp()
}
g <- (panel_age("prev", "LM prevalence", pct = TRUE) + labs(x = NULL)) /
  panel_age("clin", "clinical episodes per person-year") +
  plot_layout(guides = "collect") +
  plot_annotation(
    title = "P. vivax: age profiles at three transmission levels",
    subtitle = "LM prevalence and clinical incidence by age band, final three years of each run",
    caption = cap(ibm_note), theme = theme_cmp()) &
  theme(legend.position = "top", legend.justification = "left")
save_fig(g, "pv_age", width = 11, height = 8)
## clinical alone: the evidence for age-profile-clinical, which says nothing
## about prevalence
g <- panel_age("clin", "clinical episodes per person-year") +
  plot_annotation(
    title = "P. vivax: the age distribution of clinical incidence",
    subtitle = "Clinical episodes per person-year by age band, final three years of each run, at three transmission levels",
    caption = cap(ibm_note), theme = theme_cmp()) &
  theme(legend.position = "top", legend.justification = "left")
save_fig(g, "pv_age_clin", width = 11, height = 4.6)

## ---- 2b. population age structure ---------------------------------------------
## Evidence for population-age-structure under vivax: the vivax block ages and
## dies through compartments of its own, so its denominator is checked on its
## own terms, as render.R does for falciparum. Shares per year of age; the top
## band is fleet's absorbing open-ended group and not comparable; the test
## renormalises to the 0-60 population.
pa <- age %>% filter(scenario == paste0("eir_", EIR_REF_PV))
.labs <- pa %>% distinct(age_lo, age_hi) %>% arrange(age_lo) %>%
  transmute(l = sprintf("%g-%g", age_lo, age_hi)) %>% pull(l)
pa <- pa %>% mutate(dens = 100 * pop_frac / (age_hi - age_lo),
                    band = factor(sprintf("%g-%g", age_lo, age_hi), levels = .labs))
pa_b <- bind_rows(
  pa %>% filter(model == "IBM") %>% group_by(band) %>%
    summarise(mid = replicate_band(dens)$centre, lo = replicate_band(dens)$lower,
              hi = replicate_band(dens)$upper, .groups = "drop") %>% mutate(model = "IBM"),
  pa %>% filter(model == "fleet") %>%
    transmute(band, mid = dens, lo = NA_real_, hi = NA_real_, model = "fleet")) %>%
  mutate(model = factor(model, levels = c("IBM", "fleet")))
p_struct <- ggplot(pa_b, aes(band, mid, fill = model, colour = model)) +
  annotate("rect", xmin = nlevels(pa_b$band) - 0.5, xmax = nlevels(pa_b$band) + 0.5,
           ymin = -Inf, ymax = Inf, fill = MUTED, alpha = 0.10) +
  geom_col(position = position_dodge(width = 0.72), width = 0.66, linewidth = 0.4) +
  geom_linerange(aes(ymin = lo, ymax = hi), position = position_dodge(width = 0.72),
                 colour = INK, linewidth = 0.5, na.rm = TRUE) +
  scale_fill_manual(values = c(IBM = "#F3B3A9", fleet = "#B3ADEA"), name = NULL) +
  scale_colour_manual(values = COL, name = NULL) +
  scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.14))) +
  annotate("text", x = nlevels(pa_b$band) + 0.45, y = Inf, vjust = 1.3, hjust = 1,
           size = 2.6, lineheight = 0.95, colour = INK2, label = "not\ncomparable") +
  labs(x = "age band (years)", y = "% of the population per year of age",
       title = "The age pyramid, band by band") +
  theme_cmp() +
  theme(legend.position = "top", legend.justification = "left",
        axis.text.x = element_text(angle = 45, hjust = 1, size = rel(0.85)))
rn <- function(d) d %>% filter(age_hi <= 60) %>% mutate(share = pop_frac / sum(pop_frac))
dev <- pa %>% filter(model == "fleet") %>% rn() %>% select(band, share) %>%
  inner_join(pa %>% filter(model == "IBM") %>% group_by(rep) %>% group_modify(~ rn(.x)) %>%
               ungroup() %>% group_by(band) %>%
               summarise(mid = replicate_band(share)$centre, lo = replicate_band(share)$lower,
                         hi = replicate_band(share)$upper, .groups = "drop"), by = "band") %>%
  mutate(rel = 100 * (share / mid - 1), tol_lo = 100 * (lo / mid - 1),
         tol_hi = 100 * (hi / mid - 1), miss = share < lo | share > hi)
p_dev <- ggplot(dev, aes(band, rel)) +
  geom_rect(aes(xmin = as.numeric(band) - 0.45, xmax = as.numeric(band) + 0.45,
                ymin = tol_lo, ymax = tol_hi), fill = MUTED, alpha = 0.22) +
  geom_hline(yintercept = 0, colour = AXIS, linewidth = 0.5) +
  geom_col(aes(fill = miss), width = 0.5, show.legend = FALSE) +
  scale_fill_manual(values = c(`FALSE` = COL[["fleet"]], `TRUE` = REF)) +
  labs(x = "age band (years)", y = "fleet vs the IBM median (%)",
       title = "Where it sits inside the IBM's own spread",
       subtitle = cap(sprintf("grey = the IBM replicate band; %d of %d bands inside it",
                              sum(!dev$miss), nrow(dev)), fig_width = 5)) +
  theme_cmp() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = rel(0.85)))
g <- (p_struct | p_dev) +
  plot_annotation(
    title = sprintf("P. vivax: population age structure at EIR %s", EIR_REF_PV),
    subtitle = cap("The denominator every per-capita rate is divided by, compared on its own terms. Default demography: a constant death rate, so the pyramid is close to exponential.", width = 125),
    caption = cap("Shares are divided by band width, so bands of unequal width are comparable. The right panel renormalises to the 0-60 population, as the claim's criterion does.", ibm_note),
    theme = theme_cmp())
save_fig(g, "pv_pop_age", width = 11, height = 5.2)

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
seg <- both %>% select(scenario, eir, metric, model, mid) %>%
  pivot_wider(names_from = model, values_from = mid)
xmin <- min(-0.04, floor(min(c(both$lo, both$mid), na.rm = TRUE) * 20) / 20 - 0.03)
g <- ggplot(both, aes(y = scenario)) +
  geom_vline(xintercept = 0, colour = AXIS, linewidth = 0.5) +
  geom_segment(data = seg, aes(x = IBM, xend = fleet, yend = scenario), colour = GRID,
               linewidth = 2.2, lineend = "round") +
  geom_linerange(data = filter(both, model == "IBM"), aes(xmin = lo, xmax = hi, colour = model),
                 linewidth = 0.9, alpha = 0.55) +
  geom_point(aes(x = mid, colour = model, shape = model, fill = model), size = 2.8, stroke = 0.6) +
  facet_grid(eir ~ metric) +
  scale_models(lines = FALSE) + guide_models() +
  scale_x_continuous(labels = scales::percent, breaks = seq(0, 1, 0.5),
                     minor_breaks = seq(-0.25, 1, 0.25), limits = c(xmin, 1.02),
                     expand = expansion(mult = 0.02)) +
  scale_y_discrete(limits = rev(unname(INT_LABELS_PV)), expand = expansion(add = 0.7)) +
  coord_cartesian(clip = "off") +
  labs(title = "P. vivax: intervention impact over the first three years, at three transmission levels",
       subtitle = cap(paste("Each intervention deployed unchanged at EIR 1, 3 and 10, relative to",
                            "the three pre-deployment years of the same run. Radical cure switches",
                            "first-line treatment from 20% chloroquine to 60% chloroquine plus",
                            "primaquine or tafenoquine. Circle = IBM median with replicate band;",
                            "triangle = fleet."), width = 128),
       x = "reduction relative to baseline", y = NULL,
       caption = cap("Plotted medians are in results/pv/int_impact_summary.csv.", ibm_note)) +
  theme_cmp() + theme(panel.grid.major.y = element_blank(), axis.line.x = element_blank(),
                      axis.text.y = element_text(size = rel(0.9), lineheight = 0.95, hjust = 1),
                      panel.spacing.x = unit(1.3, "lines"), panel.spacing.y = unit(1.3, "lines"))
save_fig(g, "pv_int_impact", width = 13.5, height = 9)

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
    geom_abline(slope = 1, intercept = 0, colour = REF, linewidth = 0.8, linetype = "22") +
    scale_fill_gradient(low = "#F4F6FE", high = "#171449", transform = "log10",
                        name = "sub-site\nmonths", breaks = c(1, 10, 100, 1000, 10000),
                        labels = scales::label_comma()) +
    coord_equal(xlim = c(0, top), ylim = c(0, top), expand = FALSE) +
    labs(title = sprintf("P. vivax site files: %s sub-site-months across %d countries",
                         format(st$n, big.mark = ","), length(unique(v$iso3c))),
         subtitle = sprintf("Monthly clinical incidence, all ages, %d–%d · r = %.2f · slope = %.2f · fleet − IBM on average %+.1f%% of the IBM mean",
                            min(v$year), max(v$year), st$cor, st$slope, 100 * st$rel_bias),
         x = "IBM (episodes per person-year)", y = "fleet (episodes per person-year)",
         caption = cap(paste("Dashed line = perfect agreement. Up to ten vivax sub-sites per",
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
