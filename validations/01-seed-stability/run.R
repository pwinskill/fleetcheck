#!/usr/bin/env Rscript
## Does an undisturbed run hold the equilibrium it was seeded at?
##
##   Rscript validations/01-seed-stability/run.R      # seconds, fleet only
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
  last_five_year_range = (max(last5) - min(last5)) / pr[1])
jsonlite::write_json(res, file.path(DDIR, "seed_stability.json"), auto_unbox = TRUE,
                     pretty = TRUE, digits = 8)

cat(sprintf(paste0("seed-stability at EIR %g over %d years: PfPR(2-10) seeded at %.4f; ",
                   "largest departure %.2f%%, %+.2f%% at the end, flat to %.3f%% over the ",
                   "last five years\n"),
            EIR, YEARS, pr[1], 100 * res$max_excursion, 100 * res$final_departure,
            100 * res$last_five_year_range))
cat(sprintf("  verdict (criterion: under 1%%): %s\n",
            if (res$max_excursion < 0.01) "pass" else "FAIL"))
