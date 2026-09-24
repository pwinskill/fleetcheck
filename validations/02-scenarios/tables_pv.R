# The numbers the P. vivax claims quote, computed from the vivax suite's CSVs.
#
#   Rscript validations/02-scenarios/tables_pv.R    # writes results/pv/tables.md
#
# The vivax counterpart of tables.R, with the same criteria -- the replicate
# band, the burden floor for distribution claims, the held-out replicate for
# intervention impact -- over vivax's outcomes: LM prevalence in 2-10 year olds
# (PvPR), clinical incidence, relapse incidence, and the share carrying
# hypnozoites. No severe: malariasimulation has no vivax severe disease.

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

SMOKE <- nzchar(Sys.getenv("CMP_SMOKE"))
DDIR <- file.path(ROOT, "validations", "02-scenarios", "results", "pv")
if (SMOKE) { DDIR <- file.path(DDIR, "smoke"); BURN_Y <- 1L }
rd <- function(part) read.csv(file.path(DDIR, paste0("rep_", part, ".csv")), stringsAsFactors = FALSE)
eq <- rd("eq"); age <- rd("age"); monthly <- rd("monthly"); timing <- rd("timing")

out <- character()
say <- function(fmt, ...) out <<- c(out, if (...length()) sprintf(fmt, ...) else fmt)
md_table <- function(df) {
  df[] <- lapply(df, as.character)
  say(paste0("| ", paste(names(df), collapse = " | "), " |"))
  say(paste0("|", paste(rep(" --- ", ncol(df)), collapse = "|"), "|"))
  for (i in seq_len(nrow(df))) say(paste0("| ", paste(df[i, ], collapse = " | "), " |"))
  say("")
}
band_edge <- function(v, p) { b <- replicate_band(v); if (p < 0.5) b$lower else b$upper }
med_rng <- function(v, fmt = "%.3f")
  sprintf(paste0(fmt, " (", fmt, "–", fmt, ")"), median(v), band_edge(v, .1), band_edge(v, .9))
pct <- function(x, d = 0) sprintf(paste0("%.", d, "f%%"), 100 * x)

MET <- c(pvpr_2_10 = "PvPR 2-10 (LM)", pcr_2_10 = "PCR prevalence 2-10",
         clin_0_5 = "clinical, 0-5", clin_all = "clinical, all ages",
         relapse_all = "relapses, all ages", hyp_all = "carrying hypnozoites")
SCORED <- c("pvpr_2_10", "clin_0_5", "clin_all", "relapse_all", "hyp_all")
## intervention impact is scored on the four burden outcomes; carriage is a
## mechanism, not a burden a programme is judged on
IMPACT <- c("pvpr_2_10", "clin_0_5", "clin_all", "relapse_all")

## ---- 1. the transmission grid -------------------------------------------------
say("# P. vivax\n")
say("## Equilibrium vs EIR (final 3 years)\n")
e <- eq %>% filter(grepl("^eir_", scenario)) %>% mutate(EIR = as.numeric(sub("eir_", "", scenario)))
grid <- lapply(names(MET), function(m) {
  i <- e %>% filter(model == "IBM") %>% group_by(EIR) %>%
    summarise(med = median(.data[[m]]), lo = band_edge(.data[[m]], .1),
              hi = band_edge(.data[[m]], .9), .groups = "drop")
  o <- e %>% filter(model == "fleet") %>% transmute(EIR, fleet = .data[[m]])
  left_join(i, o, by = "EIR") %>% mutate(metric = m, inside = fleet >= lo & fleet <= hi,
                                         rel = fleet / med - 1)
}) %>% bind_rows() %>% arrange(metric, EIR)
md_table(grid %>% filter(metric %in% SCORED) %>%
           transmute(Outcome = MET[metric], EIR,
                     `IBM (replicate band)` = sprintf("%.4g (%.4g–%.4g)", med, lo, hi),
                     fleet = sprintf("%.4g", fleet), `fleet / IBM` = sprintf("%+.1f%%", 100 * rel),
                     inside = ifelse(inside, "yes", "no")))
for (m in names(MET)) {
  g <- grid[grid$metric == m, ]
  say("%s: inside the replicate band at %d of %d EIRs; largest |fleet/IBM - 1| %.1f%%%s\n",
      MET[[m]], sum(g$inside), nrow(g), 100 * max(abs(g$rel)),
      if (m %in% SCORED) "" else " (reported, not scored)")
}

## ---- 1b. how far each model moves from the shared seed -------------------------
## Both models start from malariaEquilibriumVivax's solution at the scenario's
## EIR. That is neither model's own fixed point -- the IBM's stochastic steady
## state and fleet's daily competing hazards both differ from it -- so there is
## no criterion here, only how far each moves: the first 30-day bin against the
## rest of the first 15 years, and against the final three.
say("## Drift from the seed at EIR %s (PvPR 2-10, 30-day bins)\n", EIR_REF_PV)
sd0 <- monthly %>% filter(scenario == paste0("eir_", EIR_REF_PV)) %>%
  group_by(model, year) %>% summarise(v = median(pvpr_2_10), .groups = "drop")
for (m in c("IBM", "fleet")) {
  d <- sd0 %>% filter(model == m) %>% arrange(year)
  s0 <- d$v[1]; fin <- mean(d$v[d$year >= max(d$year) - 3 + 1e-9])
  say("%s: first bin %.4f; largest departure in the first 15 years %+.1f%%; final three years %+.1f%%\n",
      m, s0, 100 * (d$v[d$year < 15][which.max(abs(d$v[d$year < 15] / s0 - 1))] / s0 - 1),
      100 * (fin / s0 - 1))
}

## ---- 2. the age profile of clinical incidence ---------------------------------
say("## Age-profile claim, scored over EIR %s\n", paste(PROFILE_EIR_PV, collapse = ", "))
ap <- age %>% filter(scenario %in% paste0("eir_", PROFILE_EIR_PV))
cells <- ap %>% filter(model == "IBM") %>% group_by(scenario, age_lo, age_hi) %>%
  summarise(centre = replicate_band(clin)$centre, lo = replicate_band(clin)$lower,
            hi = replicate_band(clin)$upper, sd = stats::sd(clin),
            episodes = median(clin * pop_frac), .groups = "drop") %>%
  left_join(ap %>% filter(model == "fleet") %>% transmute(scenario, age_lo, fleet = clin),
            by = c("scenario", "age_lo")) %>%
  group_by(scenario) %>% mutate(share = episodes / sum(episodes)) %>% ungroup() %>%
  filter(centre > 0, sd > 0) %>%
  mutate(z = (fleet - centre) / sd, tested = share >= BURDEN_MIN)
tst <- cells %>% filter(tested)
say("vivax age-profile-clinical: %d of %d cells carry at least %g%% of clinical episodes and are tested; they hold %.0f%% of all episodes\n",
    nrow(tst), nrow(cells), 100 * BURDEN_MIN, 100 * sum(tst$episodes) / sum(cells$episodes))
say("  inside the replicate band: %d of %d; max |z| %.2f (%s, %g-%gy)\n",
    sum(tst$fleet >= tst$lo & tst$fleet <= tst$hi), nrow(tst), max(abs(tst$z)),
    sub("eir_", "EIR ", tst$scenario[which.max(abs(tst$z))]),
    tst$age_lo[which.max(abs(tst$z))], tst$age_hi[which.max(abs(tst$z))])
unt <- cells %>% filter(!tested, abs(z) >= BAND_K) %>% arrange(desc(abs(z)))
say("  not tested and outside the band: %s\n", if (!nrow(unt)) "none" else
    paste(sprintf("%s %g-%gy (|z| %.2f, %.1f%% of episodes)", sub("eir_", "EIR ", unt$scenario),
                  unt$age_lo, unt$age_hi, abs(unt$z), 100 * unt$share), collapse = "; "))
say("")
md_table(cells %>% arrange(scenario, age_lo) %>%
           transmute(EIR = sub("eir_", "", scenario), `age band (y)` = sprintf("%g–%g", age_lo, age_hi),
                     `IBM (replicate band)` = sprintf("%.3f (%.3f–%.3f)", centre, lo, hi),
                     fleet = sprintf("%.3f", fleet), z = sprintf("%+.2f", z),
                     `share of episodes` = pct(share, 1), tested = ifelse(tested, "yes", "no")))

## ---- 3. custom demography --------------------------------------------------------
if ("demography" %in% age$scenario) {
  say("## Custom demography at EIR %s\n", EIR_REF_PV)
  dm <- age %>% filter(scenario == "demography")
  di <- dm %>% filter(model == "IBM") %>% group_by(age_lo, age_hi, age_mid) %>%
    summarise(pf_i = median(pop_frac), pr_i = median(prev), .groups = "drop")
  do <- dm %>% filter(model == "fleet") %>% select(age_mid, pf_o = pop_frac, pr_o = prev)
  dt <- left_join(di, do, by = "age_mid") %>% arrange(age_lo)
  md_table(dt %>% transmute(`age band (y)` = sprintf("%g-%g", age_lo, age_hi),
                            `IBM population share` = pct(pf_i, 1), `fleet population share` = pct(pf_o, 1),
                            `IBM PvPR` = sprintf("%.3f", pr_i), `fleet PvPR` = sprintf("%.3f", pr_o)))
  say("max |share diff| %.2f pp; max |prevalence diff| %.3f\n",
      100 * max(abs(dt$pf_o - dt$pf_i)), max(abs(dt$pr_o - dt$pr_i)))
}

## ---- 3b. population age structure -------------------------------------------------
## As for falciparum: shares renormalised to the 0-60 population, since fleet's
## oldest group is absorbing and open-ended and the renderer puts it wholly in the
## band holding its lower edge.
say("## Population age structure at EIR %s (shares of the 0-60 population)\n", EIR_REF_PV)
pa <- age %>% filter(scenario == paste0("eir_", EIR_REF_PV), age_hi <= 60) %>%
  group_by(model, rep) %>% mutate(share = pop_frac / sum(pop_frac)) %>% ungroup()
pst <- pa %>% filter(model == "IBM") %>% group_by(age_lo, age_hi) %>%
  summarise(centre = replicate_band(share)$centre, lo = replicate_band(share)$lower,
            hi = replicate_band(share)$upper, .groups = "drop") %>%
  left_join(pa %>% filter(model == "fleet") %>% select(age_lo, fleet = share), by = "age_lo") %>%
  mutate(inside = fleet >= lo & fleet <= hi, rel = fleet / centre - 1) %>% arrange(age_lo)
md_table(pst %>% transmute(`age band (y)` = sprintf("%g–%g", age_lo, age_hi),
                           `IBM share (replicate band)` = sprintf("%s (%s–%s)", pct(centre, 2), pct(lo, 2), pct(hi, 2)),
                           `fleet share` = pct(fleet, 2), `fleet / IBM` = sprintf("%+.1f%%", 100 * rel),
                           inside = ifelse(inside, "yes", "no")))
say("vivax population-age-structure: inside at %d of %d bands below 60 y; largest departure %.1f%% of the IBM median (%g-%gy)\n",
    sum(pst$inside), nrow(pst), 100 * max(abs(pst$rel)),
    pst$age_lo[which.max(abs(pst$rel))], pst$age_hi[which.max(abs(pst$rel))])

## ---- 4. intervention impact -----------------------------------------------------
say("## Intervention impact (3 years after vs 3 years before), EIR %s\n",
    paste(PROFILE_EIR_PV, collapse = ", "))
INT <- names(INT_LABELS_PV)
INT_SCEN <- unlist(lapply(PROFILE_EIR_PV, function(E) int_scenario(INT, E, ref = EIR_REF_PV)))
IMET <- MET[IMPACT]
with_parts <- function(d) bind_cols(d, int_parts(d$scenario, ref = EIR_REF_PV)) %>% select(-scenario)
red <- monthly %>% filter(scenario %in% INT_SCEN) %>%
  mutate(phase = case_when(year >= BURN_Y - 3 & year < BURN_Y ~ "pre",
                           year >= BURN_Y & year < BURN_Y + 3 ~ "post", TRUE ~ NA_character_)) %>%
  filter(!is.na(phase)) %>% group_by(scenario, model, rep, phase) %>%
  summarise(across(all_of(names(IMET)), mean), .groups = "drop") %>%
  pivot_longer(all_of(names(IMET)), names_to = "metric", values_to = "v") %>%
  pivot_wider(names_from = phase, values_from = v) %>%
  mutate(reduction = 1 - post / pre) %>% with_parts()
ri <- red %>% filter(model == "IBM") %>% group_by(intervention, eir, metric) %>%
  summarise(mid = median(reduction), lo = band_edge(reduction, .1), hi = band_edge(reduction, .9),
            .groups = "drop")
ro <- red %>% filter(model == "fleet") %>% transmute(intervention, eir, metric, fleet = reduction)
rt <- left_join(ri, ro, by = c("intervention", "eir", "metric")) %>%
  mutate(intervention = factor(intervention, levels = INT),
         metric = factor(metric, levels = names(IMET), labels = IMET)) %>%
  arrange(intervention, eir, metric)
## the whole label: its first line alone is "Radical cure" for both drugs
md_table(rt %>% transmute(Scenario = gsub("\n", ", ", INT_LABELS_PV[as.character(intervention)]),
                          EIR = eir, Outcome = as.character(metric),
                          `IBM reduction (replicate band)` = sprintf("%s (%s–%s)", pct(mid), pct(lo), pct(hi)),
                          `fleet reduction` = pct(fleet)))
wi <- which.max(abs(rt$fleet - rt$mid))
say("largest |fleet - IBM median| gap: %.1f pp (%s, EIR %g, %s); fleet inside the replicate band in %d of %d cells\n",
    100 * abs(rt$fleet - rt$mid)[wi], rt$intervention[wi], rt$eir[wi], rt$metric[wi],
    sum(rt$fleet >= rt$lo & rt$fleet <= rt$hi), nrow(rt))
score_cells <- function(r) {
  orm <- r %>% mutate(cell = paste(intervention, eir, metric)) %>%
    filter(model == "IBM") %>% select(rep, cell, reduction) %>%
    tidyr::pivot_wider(names_from = cell, values_from = reduction) %>% arrange(rep)
  fl <- r %>% filter(model == "fleet") %>% mutate(cell = paste(intervention, eir, metric))
  outside_rates(as.matrix(orm[, -1]), fl$reduction[match(setdiff(names(orm), "rep"), fl$cell)])
}
orr <- score_cells(red)
say("outside the replicate band: fleet %.1f%% of cells; held-out IBM replicates %.1f%% to %.1f%% (best %.1f%%, median %.1f%%)\n",
    100 * orr$candidate, 100 * min(orr$held_out), 100 * max(orr$held_out), 100 * min(orr$held_out),
    100 * median(orr$held_out))
say("  verdict: %s\n", if (orr$candidate <= min(orr$held_out)) "pass" else "FAIL")
## Where the IBM eliminated vivax: a 30-day bin in the window with no LM
## prevalence, no clinical case and no relapse. A 10,000-person IBM can fade out
## and a mean-field model cannot, so fleet's impact stops short wherever the
## IBM's reaches zero. Reported, and the score repeated without those scenarios;
## the verdict above stands on every cell.
fade <- monthly %>% filter(scenario %in% INT_SCEN, model == "IBM", year >= BURN_Y, year < BURN_Y + 3) %>%
  group_by(scenario, rep) %>%
  summarise(gone = any(pvpr_2_10 == 0 & clin_all == 0 & relapse_all == 0), .groups = "drop") %>%
  group_by(scenario) %>% summarise(n = sum(gone), .groups = "drop") %>% filter(n > 0)
say("IBM replicates that eliminated vivax within the window: %s\n", if (!nrow(fade)) "none" else
    paste(sprintf("%s %d of %d", fade$scenario, fade$n, max(red$rep)), collapse = "; "))
if (nrow(fade)) {
  kept <- red %>% filter(!paste(intervention, eir) %in%
                           with(int_parts(fade$scenario, ref = EIR_REF_PV), paste(intervention, eir)))
  ork <- score_cells(kept)
  say("  without them (%d cells): fleet outside %.1f%%; held-out IBM replicates %.1f%% to %.1f%% (median %.1f%%)\n",
      nrow(distinct(kept, intervention, eir, metric)), 100 * ork$candidate, 100 * min(ork$held_out),
      100 * max(ork$held_out), 100 * median(ork$held_out))
}

## ---- 4b. baseline levels, untreated and under chloroquine ------------------------
## A reduction is a ratio of two runs, which cancels an offset in level the two
## share. The pre-deployment years show the level itself: untreated in the bed-net
## scenarios, and after 30 years of 20% chloroquine in the treatment and
## radical-cure ones (whose burn-ins are the same schedule).
say("## Baseline level, final three pre-deployment years: fleet / IBM median - 1\n")
bl <- monthly %>% filter(scenario %in% INT_SCEN, year >= BURN_Y - 3, year < BURN_Y) %>%
  group_by(scenario, model, rep) %>%
  summarise(across(c(pvpr_2_10, clin_all), mean), .groups = "drop") %>%
  group_by(scenario, model) %>% summarise(across(c(pvpr_2_10, clin_all), median), .groups = "drop") %>%
  pivot_wider(names_from = model, values_from = c(pvpr_2_10, clin_all)) %>%
  with_parts() %>% filter(intervention %in% c("nets", "treatment", "primaquine")) %>%
  transmute(burn_in = c(nets = "untreated", treatment = "20% chloroquine",
                        primaquine = "20% chloroquine (radical-cure runs)")[intervention],
            EIR = eir, `PvPR 2-10` = sprintf("%+.1f%%", 100 * (pvpr_2_10_fleet / pvpr_2_10_IBM - 1)),
            `clinical, all ages` = sprintf("%+.1f%%", 100 * (clin_all_fleet / clin_all_IBM - 1))) %>%
  arrange(EIR, burn_in)
md_table(bl)

## ---- 5. cost ---------------------------------------------------------------------
say("## Run time per simulated year\n")
tm <- timing %>% group_by(model) %>% summarise(s_per_year = median(elapsed_s / years), .groups = "drop")
for (i in seq_len(nrow(tm))) say("%s: %.2f s per simulated year (median over runs)\n", tm$model[i], tm$s_per_year[i])
## the speed claim's figure, computed as tables.R does for falciparum: total
## cost per simulated year, IBM over fleet, both measured on the same worker pool
per_year <- function(m) sum(timing$elapsed_s[timing$model == m]) / sum(timing$years[timing$model == m])
say("IBM total CPU: %.1f h across %d runs; fleet total: %.0f s across %d runs (IBM/fleet per-year ratio %.2fx)\n",
    sum(timing$elapsed_s[timing$model == "IBM"]) / 3600, sum(timing$model == "IBM"),
    sum(timing$elapsed_s[timing$model == "fleet"]), sum(timing$model == "fleet"),
    per_year("IBM") / per_year("fleet"))

writeLines(out, file.path(DDIR, "tables.md"))
cat(out, sep = "\n")
