#!/usr/bin/env Rscript
## Does an undisturbed run hold the equilibrium it was seeded at?
##
##   Rscript validations/01-seed-stability/run.R      # a few minutes, fleet only
##
## The seed-stability claim: default parameters, seeded by set_equilibrium() at
## EIR 20, run for 15 years with nothing deployed. The seed is malariaEquilibrium's
## continuous-time solution, which is not exactly fleet's own fixed point, so the
## run moves off it; what the claim bounds is how far. Measured here on
## PfPR(2-10), the quantity the claim names: its largest departure from the
## seeded value, its departure at the end, and its range over the last five
## years, which says whether it has settled.
##
## fleet only: the claim is about fleet holding its own seed.

if (nzchar(.l <- Sys.getenv("FLEET_LIB"))) .libPaths(c(.l, .libPaths()))
.f <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))
ROOT <- if (length(.f)) normalizePath(dirname(.f), "/") else getwd()
while (!file.exists(file.path(ROOT, "DESCRIPTION")) && dirname(ROOT) != ROOT)
  ROOT <- dirname(ROOT)
suppressMessages({
  library(malariasimulation); library(fleet)
  pkgload::load_all(ROOT, quiet = TRUE)
})

DDIR <- fc_results("01-seed-stability"); dir.create(DDIR, showWarnings = FALSE, recursive = TRUE)
EIR <- 20; YEARS <- 15L

p <- get_parameters(list(prevalence_rendering_min_ages = 2 * 365,
                         prevalence_rendering_max_ages = 10 * 365))
p <- set_equilibrium(p, init_EIR = EIR)
o <- fleet::run_simulation_ode(timesteps = YEARS * 365, parameters = p)
pr <- o$n_detect_lm_730_3650 / o$n_age_730_3650   # row 1 is the seed (start of day 1)
last5 <- pr[o$timestep > (YEARS - 5) * 365]

res <- list(
  generated = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
  fleet = as.character(utils::packageVersion("fleet")),
  malariasimulation = as.character(utils::packageVersion("malariasimulation")),
  init_EIR = EIR, years = YEARS,
  seed_pfpr_2_10 = pr[1],
  max_excursion = max(abs(pr / pr[1] - 1)),
  final_departure = tail(pr, 1) / pr[1] - 1,
  # flatness: the range over the last five years, relative to their mean
  last_five_year_range = (max(last5) - min(last5)) / mean(last5))
jsonlite::write_json(res, file.path(DDIR, "seed_stability.json"), auto_unbox = TRUE,
                     pretty = TRUE, digits = 8)

cat(sprintf(paste0("seed-stability at EIR %g over %d years: PfPR(2-10) seeded at %.4f; ",
                   "largest departure %.2f%%, %+.2f%% at the end, flat to %.3f%% over the ",
                   "last five years\n"),
            EIR, YEARS, pr[1], 100 * res$max_excursion, 100 * res$final_departure,
            100 * res$last_five_year_range))
cat(sprintf("  verdict (criterion: under 1%%): %s\n",
            if (res$max_excursion < 0.01) "pass" else "FAIL"))

## ---- P. vivax --------------------------------------------------------------------
## The same question for a vivax list, over the vivax suite's grid, EIR 0.3 to
## 10. The vivax seed is malariaEquilibriumVivax's solution, which neither model
## holds: it has no spread of immunity within an age, heterogeneity and batch
## cell, which both the IBM and fleet build up from the first day, so both move
## off it, a long way (validations/02-scenarios carries the IBM's side). What
## this checks is that fleet's run SETTLES: PvPR(2-10) over the last five of
## thirty years, at each EIR. It also reports how far each run moves, on PvPR,
## all-age clinical incidence and the realised EIR, and the control that says
## why: with immunity_spread = FALSE the run holds its seed.
EIR_PV <- c(0.3, 1, 3, 10); YEARS_PV <- 30L
pv_run <- function(eir, spread = TRUE) {
  q <- get_parameters(list(prevalence_rendering_min_ages = 2 * 365,
                           prevalence_rendering_max_ages = 10 * 365,
                           clinical_incidence_rendering_min_ages = 0,
                           clinical_incidence_rendering_max_ages = 36499),
                      parasite = "vivax")
  if (!spread) q$immunity_spread <- FALSE
  q <- set_equilibrium(q, init_EIR = eir)
  ov <- fleet::run_simulation_ode(timesteps = YEARS_PV * 365, parameters = q)
  last <- ov$timestep > (YEARS_PV - 5) * 365
  one <- function(x) {
    x0 <- mean(x[seq_len(30)])                 # the first month, the seed's
    list(seed = x0, max_excursion = max(abs(x / x0 - 1)),
         final_departure = mean(x[ov$timestep > (YEARS_PV - 1) * 365]) / x0 - 1,
         last_five_year_range = (max(x[last]) - min(x[last])) / mean(x[last]))
  }
  list(init_EIR = eir, immunity_spread = spread,
       pvpr_2_10 = one(ov$n_detect_lm_730_3650 / ov$n_age_730_3650),
       clinical_all = one(ov$n_inc_clinical_0_36499 / ov$n_age_0_36499),
       realised_EIR = one(ov$EIR))
}
runs <- lapply(EIR_PV, pv_run)
control <- pv_run(3, spread = FALSE)
res_pv <- list(
  generated = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
  fleet = as.character(utils::packageVersion("fleet")),
  malariasimulation = as.character(utils::packageVersion("malariasimulation")),
  years = YEARS_PV, runs = runs, no_spread_control = control,
  worst_last_five_year_range = max(vapply(runs, function(r) r$pvpr_2_10$last_five_year_range,
                                          numeric(1))))
jsonlite::write_json(res_pv, file.path(DDIR, "seed_stability_pv.json"), auto_unbox = TRUE,
                     pretty = TRUE, digits = 8)
cat(sprintf("seed-stability-pv over %d years:\n", YEARS_PV))
for (r in c(runs, list(control))) {
  cat(sprintf(paste0("  EIR %4g%s: PvPR %+6.1f%% at the end (largest %5.1f%%), clinical %+6.1f%%, ",
                     "realised EIR %+6.1f%%; PvPR flat to %.3f%% over the last five years\n"),
              r$init_EIR, if (r$immunity_spread) "" else " (no spread)",
              100 * r$pvpr_2_10$final_departure, 100 * r$pvpr_2_10$max_excursion,
              100 * r$clinical_all$final_departure, 100 * r$realised_EIR$final_departure,
              100 * r$pvpr_2_10$last_five_year_range))
}
cat(sprintf("  verdict (criterion: settles, PvPR flat to under 1%% over the last five years at every EIR): %s\n",
            if (res_pv$worst_last_five_year_range < 0.01) "pass" else "FAIL"))
