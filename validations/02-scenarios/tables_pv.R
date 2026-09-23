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
md_table(rt %>% transmute(Scenario = sub("\n.*", "", INT_LABELS_PV[as.character(intervention)]),
                          EIR = eir, Outcome = as.character(metric),
                          `IBM reduction (replicate band)` = sprintf("%s (%s–%s)", pct(mid), pct(lo), pct(hi)),
                          `fleet reduction` = pct(fleet)))
wi <- which.max(abs(rt$fleet - rt$mid))
say("largest |fleet - IBM median| gap: %.1f pp (%s, EIR %g, %s); fleet inside the replicate band in %d of %d cells\n",
    100 * abs(rt$fleet - rt$mid)[wi], rt$intervention[wi], rt$eir[wi], rt$metric[wi],
    sum(rt$fleet >= rt$lo & rt$fleet <= rt$hi), nrow(rt))
orm <- red %>% mutate(cell = paste(intervention, eir, metric)) %>%
  filter(model == "IBM") %>% select(rep, cell, reduction) %>%
  tidyr::pivot_wider(names_from = cell, values_from = reduction) %>% arrange(rep)
fl <- red %>% filter(model == "fleet") %>% mutate(cell = paste(intervention, eir, metric))
orr <- outside_rates(as.matrix(orm[, -1]), fl$reduction[match(setdiff(names(orm), "rep"), fl$cell)])
say("outside the replicate band: fleet %.1f%% of cells; held-out IBM replicates %.1f%% to %.1f%% (best %.1f%%)\n",
    100 * orr$candidate, 100 * min(orr$held_out), 100 * max(orr$held_out), 100 * min(orr$held_out))
say("  verdict: %s\n", if (orr$candidate <= min(orr$held_out)) "pass" else "FAIL")

## ---- 5. cost ---------------------------------------------------------------------
say("## Run time per simulated year\n")
tm <- timing %>% group_by(model) %>% summarise(s_per_year = median(elapsed_s / years), .groups = "drop")
for (i in seq_len(nrow(tm))) say("%s: %.2f s per simulated year (median over runs)\n", tm$model[i], tm$s_per_year[i])

writeLines(out, file.path(DDIR, "tables.md"))
cat(out, sep = "\n")
