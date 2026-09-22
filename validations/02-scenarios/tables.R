# The numbers quoted in vignettes/comparison.Rmd, computed from the saved CSVs.
#
#   Rscript validations/02-scenarios/tables.R          # writes validations/02-scenarios/results/tables.md
#   CMP_SMOKE=1 Rscript validations/02-scenarios/tables.R
#
# Markdown tables + one-line statistics, so the article's figures and its prose
# come from the same data. Paste from tables.md; do not hand-edit numbers.

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

## Neither scenarios.R nor theme.R. This script reads the saved CSVs and prints
## markdown: it drew nothing and ran nothing, but sourcing those two attached
## malariasimulation, ggplot2 and patchwork and probed the system fonts before
## printing a table.
SMOKE <- nzchar(Sys.getenv("CMP_SMOKE"))
DDIR  <- file.path(ROOT, "validations", "02-scenarios", "results"); if (SMOKE) { DDIR <- file.path(DDIR, "smoke"); BURN_Y <- 1L }
rd <- function(part) read.csv(file.path(DDIR, paste0("rep_", part, ".csv")), stringsAsFactors = FALSE)
eq <- rd("eq"); age <- rd("age"); monthly <- rd("monthly"); doy <- rd("doy"); timing <- rd("timing")

out <- character()
say <- function(fmt, ...) out <<- c(out, if (...length()) sprintf(fmt, ...) else fmt)  # literal when no args
md_table <- function(df) {
  df[] <- lapply(df, as.character)
  say(paste0("| ", paste(names(df), collapse = " | "), " |"))
  say(paste0("|", paste(rep(" --- ", ncol(df)), collapse = "|"), "|"))
  for (i in seq_len(nrow(df))) say(paste0("| ", paste(df[i, ], collapse = " | "), " |"))
  say("")
}
## Band edges come from the package replicate_band(), so a table and a figure
## cannot report different intervals for the same cell. The .1/.9 arguments are
## kept because that is still the interval being named -- it is now read from
## every replicate rather than from two order statistics.
band_edge <- function(v, p) { b <- replicate_band(v); if (p < 0.5) b$lower else b$upper }
med_rng <- function(v, fmt = "%.3f") sprintf(paste0(fmt, " (", fmt, "\u2013", fmt, ")"), median(v), band_edge(v, .1), band_edge(v, .9))
pct <- function(x, d = 0) sprintf(paste0("%.", d, "f%%"), 100 * x)

## ---- 1. EIR grid --------------------------------------------------------------
say("## Equilibrium vs EIR (final 3 years)\n")
e <- eq %>% filter(grepl("^eir_", scenario)) %>% mutate(EIR = as.numeric(sub("eir_", "", scenario)))
ei <- e %>% filter(model == "IBM") %>% group_by(EIR) %>%
  summarise(`IBM realised EIR` = sprintf("%.1f", median(eir_realised)),
            `IBM PfPR (2-10)` = med_rng(pfpr_2_10),
            `IBM clinical (0-5, per child-year)` = med_rng(clin_0_5, "%.2f"),
            pf_i = median(pfpr_2_10), cl_i = median(clin_0_5), .groups = "drop")
eo <- e %>% filter(model == "fleet") %>% transmute(EIR, `fleet realised EIR` = sprintf("%.1f", eir_realised),
  `fleet PfPR (2-10)` = sprintf("%.3f", pfpr_2_10), `fleet clinical` = sprintf("%.2f", clin_0_5),
  pf_o = pfpr_2_10, cl_o = clin_0_5)
et <- left_join(ei, eo, by = "EIR") %>% arrange(EIR)
md_table(et %>% transmute(`init EIR` = EIR, `IBM realised EIR`, `fleet realised EIR`,
                          `IBM PfPR (2-10)`, `fleet PfPR (2-10)`,
                          `IBM clinical (0-5, per child-year)`, `fleet clinical`))
say("max |fleet - IBM median| PfPR(2-10): %.3f (at EIR %s); clinical incidence relative difference range: %s to %s\n",
    max(abs(et$pf_o - et$pf_i)), et$EIR[which.max(abs(et$pf_o - et$pf_i))],
    pct(min(et$cl_o / et$cl_i - 1), 1), pct(max(et$cl_o / et$cl_i - 1), 1))
in_band <- e %>% filter(model == "IBM") %>% group_by(EIR) %>%
  summarise(lo = band_edge(pfpr_2_10, .1), hi = band_edge(pfpr_2_10, .9), lo_c = band_edge(clin_0_5, .1), hi_c = band_edge(clin_0_5, .9), .groups = "drop") %>%
  left_join(eo, by = "EIR") %>% mutate(in_p = pf_o >= lo & pf_o <= hi, in_c = cl_o >= lo_c & cl_o <= hi_c)
say("fleet inside the IBM replicate band: PfPR at %d of %d EIRs; clinical at %d of %d\n",
    sum(in_band$in_p), nrow(in_band), sum(in_band$in_c), nrow(in_band))

## the same grid over the all-ages outcomes. These carry the shape of the
## relationship rather than its level: all-age clinical flattens far sooner than
## the under-5 rate, and severe incidence turns over entirely.
ai <- e %>% filter(model == "IBM") %>% group_by(EIR) %>%
  summarise(`IBM clinical (all ages, per person-year)` = med_rng(clin_all, "%.3f"),
            `IBM severe (all ages, per 1,000 person-years)` = med_rng(sev_all, "%.2f"),
            lo_c = band_edge(clin_all, .1), hi_c = band_edge(clin_all, .9),
            lo_s = band_edge(sev_all, .1), hi_s = band_edge(sev_all, .9),
            cl_i = median(clin_all), sv_i = median(sev_all), .groups = "drop")
ao <- e %>% filter(model == "fleet") %>%
  transmute(EIR, `fleet clinical` = sprintf("%.3f", clin_all),
            `fleet severe` = sprintf("%.2f", sev_all), cl_o = clin_all, sv_o = sev_all)
at <- left_join(ai, ao, by = "EIR") %>% arrange(EIR) %>%
  mutate(in_c = cl_o >= lo_c & cl_o <= hi_c, in_s = sv_o >= lo_s & sv_o <= hi_s)
md_table(at %>% transmute(`init EIR` = EIR, `IBM clinical (all ages, per person-year)`,
                          `fleet clinical`, `IBM severe (all ages, per 1,000 person-years)`,
                          `fleet severe`))
say("all-ages relative difference: clinical %s to %s, severe %s to %s\n",
    pct(min(at$cl_o / at$cl_i - 1), 1), pct(max(at$cl_o / at$cl_i - 1), 1),
    pct(min(at$sv_o / at$sv_i - 1), 1), pct(max(at$sv_o / at$sv_i - 1), 1))
say("fleet inside the IBM replicate band: all-age clinical at %d of %d EIRs; all-age severe at %d of %d\n",
    sum(at$in_c), nrow(at), sum(at$in_s), nrow(at))
say("fold change across the grid (fleet): clinical 0-5 %.1fx, clinical all ages %.1fx; severe all ages peaks at EIR %s\n",
    max(et$cl_o) / min(et$cl_o), max(at$cl_o) / min(at$cl_o), at$EIR[which.max(at$sv_o)])

## ---- 2. age profile -----------------------------------------------------------
say("## Age profile at EIR %s\n", EIR_REF)
a <- age %>% filter(scenario == paste0("eir_", EIR_REF))
ai <- a %>% filter(model == "IBM") %>% group_by(age_lo, age_hi, age_mid) %>%
  summarise(prev_i = median(prev), clin_i = median(clin), sev_i = median(sev),
            prev_lo = band_edge(prev, .1), prev_hi = band_edge(prev, .9), sev_lo = band_edge(sev, .1), sev_hi = band_edge(sev, .9), .groups = "drop")
ao <- a %>% filter(model == "fleet") %>% select(age_mid, prev_o = prev, clin_o = clin, sev_o = sev)
at <- left_join(ai, ao, by = "age_mid") %>% arrange(age_lo)
md_table(at %>% transmute(`age band (y)` = sprintf("%g\u2013%g", age_lo, age_hi),
                          `IBM prevalence` = sprintf("%.3f", prev_i), `fleet prevalence` = sprintf("%.3f", prev_o),
                          `IBM clinical` = sprintf("%.2f", clin_i), `fleet clinical` = sprintf("%.2f", clin_o),
                          `IBM severe /1000` = sprintf("%.1f", sev_i), `fleet severe /1000` = sprintf("%.1f", sev_o)))
yk <- at$age_hi <= 20                      # relative differences only where the rates are not tiny
say("max |fleet - IBM| prevalence across bands: %.3f; under-20 bands: clinical relative diff range %s to %s, severe relative diff range %s to %s; fleet severe inside IBM band in %d of %d bands\n",
    max(abs(at$prev_o - at$prev_i)), pct(min(at$clin_o[yk] / at$clin_i[yk] - 1), 1), pct(max(at$clin_o[yk] / at$clin_i[yk] - 1), 1),
    pct(min(at$sev_o[yk] / at$sev_i[yk] - 1), 0), pct(max(at$sev_o[yk] / at$sev_i[yk] - 1), 0),
    sum(at$sev_o >= at$sev_lo & at$sev_o <= at$sev_hi), nrow(at))

## ---- 2a. the age-profile claims, scored ---------------------------------------
## What age-profile-clinical and age-profile-severe are decided on, across all of
## PROFILE_EIR rather than the reference alone. Until this existed the register
## carried counts no script in the repository reproduced.
##
## Only cells carrying at least BURDEN_MIN of the outcome are tested: a claim
## about how a burden is distributed says little about bands holding almost none
## of it, and those bands carry the most replicate noise. The cost is stated
## against the claim -- a defect confined to the oldest ages would not be caught
## -- so the excluded cells are printed here rather than quietly dropped.
say("## Age-profile claims, scored over EIR %s\n",
    paste(PROFILE_EIR, collapse = ", "))
ap <- age %>% filter(scenario %in% paste0("eir_", PROFILE_EIR))
for (m in c("clin", "sev")) {
  cl <- paste0("age-profile-", if (m == "clin") "clinical" else "severe")
  cells <- ap %>% filter(model == "IBM") %>% group_by(scenario, age_lo, age_hi) %>%
    summarise(centre = replicate_band(.data[[m]])$centre,
              lo = replicate_band(.data[[m]])$lower,
              hi = replicate_band(.data[[m]])$upper,
              sd = stats::sd(.data[[m]]),
              episodes = median(.data[[m]] * pop_frac), .groups = "drop") %>%
    left_join(ap %>% filter(model == "fleet") %>%
                transmute(scenario, age_lo, fleet = .data[[m]]),
              by = c("scenario", "age_lo")) %>%
    group_by(scenario) %>% mutate(share = episodes / sum(episodes)) %>% ungroup() %>%
    ## severe incidence is zero in most replicates of the sparsest bands, where a
    ## band has no width and a standardised departure has no meaning
    filter(centre > 0, sd > 0) %>%
    mutate(z = (fleet - centre) / sd, tested = share >= BURDEN_MIN)
  tst <- cells %>% filter(tested)
  say("%s: %d of %d cells carry at least %g%% of the outcome and are tested; they hold %.0f%% of all episodes\n",
      cl, nrow(tst), nrow(cells), 100 * BURDEN_MIN,
      100 * sum(tst$episodes) / sum(cells$episodes))
  say("  inside the replicate band: %d of %d; max |z| %.2f (%s, %g-%gy)\n",
      sum(tst$fleet >= tst$lo & tst$fleet <= tst$hi), nrow(tst), max(abs(tst$z)),
      sub("eir_", "EIR ", tst$scenario[which.max(abs(tst$z))]),
      tst$age_lo[which.max(abs(tst$z))], tst$age_hi[which.max(abs(tst$z))])
  unt <- cells %>% filter(!tested, abs(z) >= BAND_K) %>% arrange(desc(abs(z)))
  say("  not tested and outside the band: %s\n", if (!nrow(unt)) "none" else
      paste(sprintf("%s %g-%gy (|z| %.2f, %.1f%% of episodes)",
                    sub("eir_", "EIR ", unt$scenario), unt$age_lo, unt$age_hi,
                    abs(unt$z), 100 * unt$share), collapse = "; "))
  say("")
}

## ---- 2b. custom demography ---------------------------------------------------
if ("demography" %in% age$scenario) {
  say("## Custom demography at EIR %s\n", EIR_REF)
  dm <- age %>% filter(scenario == "demography")
  di <- dm %>% filter(model == "IBM") %>% group_by(age_lo, age_hi, age_mid) %>%
    summarise(pf_i = median(pop_frac), pr_i = median(prev), .groups = "drop")
  do <- dm %>% filter(model == "fleet") %>% select(age_mid, pf_o = pop_frac, pr_o = prev)
  dt <- left_join(di, do, by = "age_mid") %>% arrange(age_lo)
  md_table(dt %>% transmute(`age band (y)` = sprintf("%g-%g", age_lo, age_hi),
                            `IBM population share` = pct(pf_i, 1), `fleet population share` = pct(pf_o, 1),
                            `IBM prevalence` = sprintf("%.3f", pr_i), `fleet prevalence` = sprintf("%.3f", pr_o)))
  u5 <- dt$age_hi <= 5
  say("under-5 share: IBM %s, fleet %s; max |share diff| %.2f pp; max |prevalence diff| %.3f\n",
      pct(sum(dt$pf_i[u5]), 1), pct(sum(dt$pf_o[u5]), 1), 100 * max(abs(dt$pf_o - dt$pf_i)),
      max(abs(dt$pr_o - dt$pr_i)))
}

## ---- 3. seasonal cycle --------------------------------------------------------
say("## Seasonal cycle (final year, weekly bins)\n")
s <- doy %>% filter(scenario == "seasonal")
si <- s %>% filter(model == "IBM") %>% group_by(doy) %>% summarise(p = median(pfpr_2_10), c = median(clin_0_5), .groups = "drop")
so <- s %>% filter(model == "fleet") %>% select(doy, p = pfpr_2_10, c = clin_0_5)
say("prevalence peak: IBM %.3f (day %d), fleet %.3f (day %d); trough: IBM %.3f (day %d), fleet %.3f (day %d)",
    max(si$p), round(si$doy[which.max(si$p)]), max(so$p), round(so$doy[which.max(so$p)]),
    min(si$p), round(si$doy[which.min(si$p)]), min(so$p), round(so$doy[which.min(so$p)]))
say("clinical peak (per child-year): IBM %.2f (day %d), fleet %.2f (day %d); annual mean clinical IBM %.2f fleet %.2f\n",
    max(si$c), round(si$doy[which.max(si$c)]), max(so$c), round(so$doy[which.max(so$c)]), mean(si$c), mean(so$c))
sea <- eq %>% filter(scenario == "seasonal")
say("seasonal realised EIR: IBM %.1f, fleet %.1f (target %s); annual PfPR IBM %s, fleet %.3f\n",
    median(sea$eir_realised[sea$model == "IBM"]), sea$eir_realised[sea$model == "fleet"], EIR_REF,
    med_rng(sea$pfpr_2_10[sea$model == "IBM"]), sea$pfpr_2_10[sea$model == "fleet"])

## ---- 4. country site files (a SNAPSHOT) ---------------------------------------
## Read from a committed snapshot, not recomputed. The 63-country comparison is a
## ~7-hour run against the malariaverse site files, in a separate checkout that is
## not part of this repo, so it cannot be a step in the harness or in CI. Without
## the snapshot this section would simply vanish from tables.md on any machine
## lacking that checkout -- taking the article's numbers with it, and failing the
## figures CI job for a reason that has nothing to do with the model.
##
## CMP_REFRESH_SITES=1, with the validation results present, re-takes it.
`%||%` <- function(x, y) if (is.null(x)) y else x
site_f <- file.path(DDIR, "site_snapshot.json")
if (nzchar(Sys.getenv("CMP_REFRESH_SITES"))) {
  fs <- list.files(fc_results("03-real-settings", "raw"), pattern = "_compare[.]rds$", full.names = TRUE)
  if (!length(fs)) stop("CMP_REFRESH_SITES is set but there are no results in ", fc_results("03-real-settings", "raw"), " -- run validations/03-real-settings/run.R first.")
  ## read_compare() normalises the model columns to fleet_*: files written
  ## before the blink -> fleet rename carry them as mo_*, and reading raw
  ## readRDS() here is what broke when the sweep stopped writing both names.
  source(file.path(ROOT, "validations", "03-real-settings", "sites_lib.R"))
  v <- bind_rows(lapply(fs, read_compare))
  ## agreement() from the package; see the note in render.R about the two local
  ## copies this replaces. as.list() because the snapshot is JSON, not a frame.
  ag2 <- function(x, y) as.list(agreement(x, y))
  prev <- if (file.exists(site_f)) jsonlite::read_json(site_f, simplifyVector = TRUE) else list()

  ## Two provenances, and they are not the same one.
  ##
  ## `run` is the sweep itself: the fleet version and the date the per-country
  ## results were produced. `summarised` is this pass over those results, which
  ## is seconds and can happen at any later version. Collapsing them is how the
  ## snapshot came to claim the wrong thing: one stamp taken here records
  ## today's fleet while the numbers under it are whatever the sweep produced
  ## weeks ago.
  ##
  ## `run` is read from the sweep's own stamp, which run.R writes beside its
  ## results. It used to be carried forward here and changed by hand when the
  ## sweep was repeated, which is a manual step that gets forgotten: the
  ## snapshot went on reporting fleet 0.0.0.9000 for a run that had been
  ## repeated twice since.
  ref <- file.path(fc_results("03-real-settings"), "sites_reference.json")
  run <- if (file.exists(ref)) {
    r <- jsonlite::read_json(ref, simplifyVector = TRUE)
    list(taken = substr(r$generated, 1, 10), fleet = r$fleet,
         n_age_groups = r$n_age_groups)
  } else prev$run %||% list(taken = prev$taken, fleet = prev$fleet)
  snap <- list(
               run = run,
               summarised = stamp(files = length(fs)),
               note = paste(
                 "The 63-country site-file comparison. It re-runs fleet only --",
                 "the IBM arm is the pre-run diagnostic shipped with each site",
                 "file -- so it is about forty minutes on ten cores, but it needs",
                 "the malariaverse site files, which are not redistributable.",
                 "Re-take it with validations/03-real-settings/run.R followed by",
                 "CMP_REFRESH_SITES=1 on render.R and tables.R."),
               countries = length(unique(v$iso3c)),
               sub_sites = nrow(distinct(v, iso3c, name_1, urban_rural)),
               year_from = min(v$year), year_to = max(v$year),
               clinical = ag2(v$ms_clinical, v$fleet_clinical),
               severe = ag2(v$ms_severe, v$fleet_severe))
  jsonlite::write_json(snap, site_f, auto_unbox = TRUE, pretty = TRUE, digits = 6)
  message("re-took the site snapshot (", snap$countries, " countries)")
}
if (file.exists(site_f)) {
  sn <- jsonlite::read_json(site_f, simplifyVector = TRUE)
  agz <- function(z) sprintf("n = %s, r = %.3f, slope = %.3f, relative bias = %s",
                             format(z$n, big.mark = ","), z$cor, z$slope, pct(z$rel_bias, 1))
  say("## Country site files (run: %s, fleet %s; summarised %s)\n",
      sn$run$taken, sn$run$fleet, substr(sn$summarised$taken, 1, 10))
  say("countries: %d; sub-sites: %d; years %d\u2013%d", sn$countries, sn$sub_sites,
      sn$year_from, sn$year_to)
  say("clinical: %s", agz(sn$clinical))
  say("severe:   %s", agz(sn$severe))
  say("NOT refreshed by this harness or by CI: re-take with CMP_REFRESH_SITES=1 when the validation run is repeated\n")
}

## ---- 5. intervention impact ---------------------------------------------------
say("## Intervention impact: reduction over post-deployment years 0-3 vs pre-deployment years -3-0\n")
INT <- names(INT_LABELS)
## Every intervention at all three of PROFILE_EIR. Reporting only the reference
## arm here while the figure carried three would have left the claim's measured
## value counting a third of the cells the criterion names.
INT_SCEN <- unlist(lapply(PROFILE_EIR, function(E) int_scenario(INT, E)))
MET <- c(pfpr_2_10 = "PfPR 2-10", clin_0_5 = "clinical, 0-5",
         clin_all = "clinical, all ages", sev_all = "severe, all ages")
with_parts <- function(d) bind_cols(d, int_parts(d$scenario)) %>% select(-scenario)
red <- monthly %>% filter(scenario %in% INT_SCEN) %>%
  mutate(phase = case_when(year >= BURN_Y - 3 & year < BURN_Y ~ "pre",
                           year >= BURN_Y & year < BURN_Y + 3 ~ "post", TRUE ~ NA_character_)) %>%
  filter(!is.na(phase)) %>% group_by(scenario, model, rep, phase) %>%
  summarise(across(all_of(names(MET)), mean), .groups = "drop") %>%
  pivot_longer(all_of(names(MET)), names_to = "metric", values_to = "v") %>%
  pivot_wider(names_from = phase, values_from = v) %>%
  mutate(reduction = 1 - post / pre) %>% with_parts()
ri <- red %>% filter(model == "IBM") %>% group_by(intervention, eir, metric) %>%
  summarise(mid = median(reduction), lo = band_edge(reduction, .1), hi = band_edge(reduction, .9),
            .groups = "drop")
ro <- red %>% filter(model == "fleet") %>%
  transmute(intervention, eir, metric, fleet = reduction)
rt <- left_join(ri, ro, by = c("intervention", "eir", "metric")) %>%
  mutate(intervention = factor(intervention, levels = INT),
         metric = factor(metric, levels = names(MET), labels = MET)) %>%
  arrange(intervention, eir, metric)
md_table(rt %>% transmute(Scenario = sub("\n.*", "", INT_LABELS[as.character(intervention)]),
                          EIR = eir,
                          Outcome = as.character(metric),
                          `IBM reduction (replicate band)` =
                            sprintf("%s (%s\u2013%s)", pct(mid), pct(lo), pct(hi)),
                          `fleet reduction` = pct(fleet)))
wi <- which.max(abs(rt$fleet - rt$mid))
say("largest |fleet - IBM median| gap: %.1f pp (%s, EIR %g, %s); fleet inside the IBM replicate band in %d of %d scenario x EIR x outcome cells\n",
    100 * abs(rt$fleet - rt$mid)[wi], rt$intervention[wi], rt$eir[wi], rt$metric[wi],
    sum(rt$fleet >= rt$lo & rt$fleet <= rt$hi), nrow(rt))
## What the claim is decided on. Over 72 cells "inside every one" is a bar no
## IBM replicate clears, so the bar comes from the IBM: hold each replicate out,
## score it against the other 19, and compare how often fleet is outside against
## how often the BEST of them is.
orm <- red %>% mutate(cell = paste(intervention, eir, metric)) %>%
  filter(model == "IBM") %>% select(rep, cell, reduction) %>%
  tidyr::pivot_wider(names_from = cell, values_from = reduction) %>% arrange(rep)
fl <- red %>% filter(model == "fleet") %>%
  mutate(cell = paste(intervention, eir, metric))
orr <- outside_rates(as.matrix(orm[, -1]),
                     fl$reduction[match(setdiff(names(orm), "rep"), fl$cell)])
say("outside the replicate band: fleet %.1f%% of cells; held-out IBM replicates %.1f%% to %.1f%% (best %.1f%%)\n",
    100 * orr$candidate, 100 * min(orr$held_out), 100 * max(orr$held_out),
    100 * min(orr$held_out))
say("  verdict: %s\n", if (orr$candidate <= min(orr$held_out)) "pass" else "FAIL")
## Reported alongside, because it is what a reader wants to know even when it
## decides nothing: how far past the band the worst cell sits.
exc <- pmax(rt$lo - rt$fleet, rt$fleet - rt$hi, 0)
say("worst excursion past the band: %.2f pp (%s, EIR %g, %s)\n",
    100 * max(exc), rt$intervention[which.max(exc)], rt$eir[which.max(exc)],
    rt$metric[which.max(exc)])
## per-scenario post-deployment trajectory gap, years 0-6, as % of the IBM median (monthly, prevalence)
gap <- monthly %>% filter(scenario %in% INT_SCEN, year >= BURN_Y, year < BURN_Y + 6) %>%
  group_by(scenario, model, year) %>% summarise(p = median(pfpr_2_10), c = median(clin_0_5), .groups = "drop") %>%
  pivot_wider(names_from = model, values_from = c(p, c)) %>% with_parts() %>%
  group_by(intervention, eir) %>%
  summarise(`mean prevalence gap (fleet - IBM, pp)` = sprintf("%+.1f", 100 * mean(p_fleet - p_IBM)),
            `mean clinical gap (% of IBM)` = pct(mean(c_fleet - c_IBM) / mean(c_IBM), 1), .groups = "drop") %>%
  arrange(factor(intervention, levels = INT), eir)
md_table(gap)

## ---- 5b. long-horizon programmes ----------------------------------------------
## Two robust statistics only. A relative per-month error is NOT reported here: in
## a seasonal setting the dry-season trough goes to within rounding of zero, so
## |fleet - IBM| / IBM reaches billions of percent on months carrying no burden.
## In-band fraction and the 15-year mean reduction both weight by magnitude and
## survive the trough.
if (all(names(TS_LABELS) %in% monthly$scenario)) {
  say("## Long-horizon programmes (%d years past deployment)\n", TS_YEARS)
  td <- monthly %>%
    filter(scenario %in% names(TS_LABELS), year >= BURN_Y, year <= BURN_Y + TS_YEARS) %>%
    select(scenario, model, rep, year, pfpr_2_10, clin_0_5, clin_all, sev_all) %>%
    tidyr::pivot_longer(-c(scenario, model, rep, year), names_to = "metric", values_to = "y")
  ti <- td %>% filter(model == "IBM") %>% group_by(scenario, metric, year) %>%
    summarise(ibm = median(y), lo = band_edge(y, .1), hi = band_edge(y, .9), .groups = "drop")
  tj <- inner_join(ti, td %>% filter(model == "fleet") %>%
                     select(scenario, metric, year, fleet = y),
                   by = c("scenario", "metric", "year"))
  md_table(tj %>% group_by(metric) %>%
    summarise(`scenario-months` = n(),
              `fleet inside the replicate band` = pct(mean(fleet >= lo & fleet <= hi)),
              .groups = "drop") %>% rename(outcome = metric))
  ## say() is literal when given no args, so this string takes single % signs
  say("(an 80% band contains a perfectly-tracking deterministic mean ~80% of the time, so ~80% is the target, not a ceiling)\n")

  tot <- tj %>% group_by(scenario, metric) %>%
    summarise(ibm = mean(ibm), fleet = mean(fleet), .groups = "drop")
  bse <- tot %>% filter(scenario == "ts_none") %>% select(metric, ibm0 = ibm, fleet0 = fleet)
  red <- tot %>% left_join(bse, by = "metric") %>% filter(scenario != "ts_none") %>%
    mutate(i = 1 - ibm / ibm0, o = 1 - fleet / fleet0)
  ## TS_LABELS carry a newline for the figure's row strips; a markdown cell cannot
  md_table(red %>% transmute(scenario = gsub("\n", " ", unname(TS_LABELS[scenario])), outcome = metric,
                             `IBM reduction` = pct(i), `fleet reduction` = pct(o),
                             `gap (pp)` = sprintf("%+.1f", 100 * (o - i))) %>%
             arrange(scenario, outcome))
  say("largest |fleet - IBM| gap in %d-year mean reduction: %.1f pp\n",
      TS_YEARS, max(abs(100 * (red$o - red$i))))
}

## ---- 6. timing ----------------------------------------------------------------
say("## Run time\n")
tm <- timing %>% group_by(model) %>%
  summarise(runs = n(), `s per simulated year` = sprintf("%.2f", sum(elapsed_s) / sum(years)),
            `mean run (s)` = sprintf("%.1f", mean(elapsed_s)), `mean horizon (y)` = sprintf("%.0f", mean(years)), .groups = "drop")
md_table(tm)
say("IBM total CPU: %.1f h across %d runs; fleet total: %.0f s across %d runs (IBM/fleet per-year ratio %.0fx)",
    sum(timing$elapsed_s[timing$model == "IBM"]) / 3600, sum(timing$model == "IBM"),
    sum(timing$elapsed_s[timing$model == "fleet"]), sum(timing$model == "fleet"),
    (sum(timing$elapsed_s[timing$model == "IBM"]) / sum(timing$years[timing$model == "IBM"])) /
      (sum(timing$elapsed_s[timing$model == "fleet"]) / sum(timing$years[timing$model == "fleet"])))

writeLines(out, file.path(DDIR, "tables.md"))
cat(out, sep = "\n")
