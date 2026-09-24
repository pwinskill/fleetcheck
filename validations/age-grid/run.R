#!/usr/bin/env Rscript
## How much of the age-profile departure is the grid, and how much is the model?
##
##   Rscript validations/age-grid/run.R            # under a minute, fleet only
##
## Two questions, and they are different:
##
##   1. Does fleet's own age profile converge as the grid is refined, and how
##      fast? Measured against a Richardson extrapolation of fleet itself, so
##      the IBM is not involved. This is DISCRETISATION and it is removable.
##   2. Does the departure from the IBM shrink at the same time? Measured
##      against the committed replicate medians. This is what the register's
##      age-profile claims are scored on.
##
## The two answers differ, and that difference is the point: the register used
## to attribute a persistent IBM gap to evaluating immunity at an age group's
## mean, which is an error that DOES vanish with refinement. This script is what
## distinguishes the two, and the numbers quoted in `fleet`'s NEWS and in
## `?default_age_lower` come from here rather than from a scratch file.
##
## fleet only: the IBM rows do not depend on the grid fleet runs on.

if (nzchar(.l <- Sys.getenv("FLEET_LIB"))) .libPaths(c(.l, .libPaths()))
.f <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))
ROOT <- if (length(.f)) normalizePath(dirname(.f), "/") else getwd()
while (!file.exists(file.path(ROOT, "DESCRIPTION")) && dirname(ROOT) != ROOT)
  ROOT <- dirname(ROOT)
suppressMessages({
  library(malariasimulation); library(fleet)
  pkgload::load_all(ROOT, quiet = TRUE)
})
source(file.path(ROOT, "validations", "_shared", "scenarios.R"))

DDIR <- fc_results("age-grid"); dir.create(DDIR, showWarnings = FALSE, recursive = TRUE)
SC <- "eir_20"
N_GROUPS <- c(53L, 105L, 209L, 417L)

## The old grid, kept verbatim, because "the new grid halves the error" is a
## comparison against something and that something has to be reproducible.
old_grid <- function(max_age = 80) c(
  seq(0, 1 - 1 / 12, by = 1 / 12), seq(1, 5 - 0.25, by = 0.25),
  seq(5, 15 - 1, by = 1), seq(15, max_age - 5, by = 5), max_age)
## Equal width over the same span, at the same cost: the control that says
## whether the GRADING matters or only the group count.
flat_grid <- function(n) c(seq(0, 80, length.out = n))

profile_on <- function(grid) {
  s <- scenarios[[SC]]
  o <- fleet::run_simulation_ode(timesteps = s$years * 365, parameters = s$p,
                                 tuning = list(age_lower = grid))
  summarise_run(o, s$years)$age
}

cat(sprintf("age-grid convergence, %s, fleet only\n\n", SC))
grids <- c(
  setNames(lapply(N_GROUPS, function(n) default_age_lower(n_group = n)),
           paste0("log", N_GROUPS)),
  list(old = old_grid(), flat = flat_grid(53L)))
prof <- lapply(grids, profile_on)
mids <- sort(unique(prof[[1]]$age_mid))
clin <- vapply(prof, function(p) p$clin[match(mids, p$age_mid)], numeric(length(mids)))

## Richardson limit from the two finest LOG grids, which are a clean factor of
## two apart: for a first-order scheme f_limit = 2*f(2h) - f(h) in the group
## count. Everything is scored against that, fleet against itself.
fine <- clin[, paste0("log", N_GROUPS[length(N_GROUPS)])]
prev <- clin[, paste0("log", N_GROUPS[length(N_GROUPS) - 1L])]
limit <- fine + (fine - prev)

err <- function(x) { d <- x / limit - 1; c(max = max(abs(d)), rms = sqrt(mean(d^2))) }
cat("departure from fleet's own grid-converged profile:\n")
cat(sprintf("  %-8s %6s  %8s %8s\n", "grid", "groups", "max", "rms"))
for (nm in colnames(clin)) {
  e <- err(clin[, nm])
  cat(sprintf("  %-8s %6d  %7.2f%% %7.2f%%\n", nm, length(grids[[nm]]),
              100 * e["max"], 100 * e["rms"]))
}

## Successive ratios: ~2 per doubling is first order, i.e. the error is
## removable and the grid is not the reason any IBM gap persists.
cat("\nerror ratio between successive log grids (2.0 = first order):\n")
for (i in seq_len(length(N_GROUPS) - 2L)) {
  a <- err(clin[, paste0("log", N_GROUPS[i])])["rms"]
  b <- err(clin[, paste0("log", N_GROUPS[i + 1L])])["rms"]
  cat(sprintf("  %d -> %d   %.2f\n", N_GROUPS[i], N_GROUPS[i + 1L], a / b))
}

## And the other question: does refining close the gap to the IBM?
a <- read.csv(fc_results("02-scenarios", "rep_age.csv"), stringsAsFactors = FALSE)
a <- a[!is.na(a$scenario) & a$scenario == SC & a$model == "IBM", ]
ibm <- vapply(mids, function(x) stats::median(a$clin[a$age_mid == x]), numeric(1))
cat("\ndeparture from the IBM median (same runs):\n")
cat(sprintf("  %-8s %8s %8s\n", "grid", "max", "rms"))
gap <- list()
for (nm in colnames(clin)) {
  d <- clin[, nm] / ibm - 1
  gap[[nm]] <- d
  cat(sprintf("  %-8s %7.1f%% %7.1f%%\n", nm, 100 * max(abs(d)), 100 * sqrt(mean(d^2))))
}

out <- data.frame(grid = rep(colnames(clin), each = length(mids)),
                  n_group = rep(vapply(grids, length, integer(1)), each = length(mids)),
                  age_lo = prof[[1]]$age_lo, age_hi = prof[[1]]$age_hi,
                  fleet = as.vector(clin), converged = rep(limit, ncol(clin)),
                  ibm = rep(ibm, ncol(clin)))
write.csv(round_sig(out, 10), file.path(DDIR, "convergence.csv"), row.names = FALSE)
jsonlite::write_json(list(generated = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
                          fleet = as.character(utils::packageVersion("fleet")),
                          scenario = SC, n_groups = N_GROUPS),
                     file.path(DDIR, "age_grid_reference.json"),
                     auto_unbox = TRUE, pretty = TRUE)
cat(sprintf("\nwritten: %s\n", file.path(DDIR, "convergence.csv")))
