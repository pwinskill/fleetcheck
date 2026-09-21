# Has a change moved fleet, and is it still matching the IBM?
#
#   Rscript validations/02-scenarios/assess.R              # ~2 min
#   CMP_ONLY=eir_20,smc Rscript validations/02-scenarios/assess.R    # a subset, faster
#   CMP_STRICT=1 Rscript validations/02-scenarios/assess.R # also fail if ANY number moved
#
# The IBM does not depend on fleet, so its committed rows stay valid for any
# fleet-side change and there is no reason to re-run a 25-minute IBM sweep to
# find out whether the match still holds. This re-runs fleet only, against the
# frozen reference.
#
# Two questions, reported separately because they mean different things:
#
#   1. Did anything MOVE?  fleet now against fleet's committed rows. A moved
#      number is not automatically wrong -- a deliberate model fix moves numbers
#      -- but it must be SEEN. Silent movement is how a regression ships.
#   2. Is the match still GOOD?  fleet now against the committed IBM medians and
#      10-90% bands, at the thresholds the article's claims rest on. This is the
#      gate, and the only thing that fails the run by default.
#
# Exit 0 = still matching. Exit 1 = drift beyond threshold (or, under
# CMP_STRICT, any movement at all).

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
suppressMessages(library(malariasimulation))
log_msg <- function(...) cat(sprintf("[%s] %s\n", format(Sys.time(), "%H:%M:%S"), sprintf(...)))
## constants.R, scenarios.R and theme.R are package code in R/, so they arrive
## with the package rather than being sourced by path.
if (requireNamespace("pkgload", quietly = TRUE) &&
    file.exists(file.path(ROOT, "DESCRIPTION"))) {
  suppressMessages(pkgload::load_all(ROOT, quiet = TRUE))
} else {
  suppressMessages(library(fleetcheck))
}

## Scenario definitions, run_fleet() and the digest helpers. Runner code
## rather than package code: it builds malariasimulation parameter lists at
## the top level, so it needs that package attached and cannot load with
## fleetcheck. One copy, sourced by everything that needs it.
source(file.path(ROOT, "validations", "_shared", "scenarios.R"))

DDIR <- file.path(ROOT, "validations", "02-scenarios", "results")
STRICT <- nzchar(Sys.getenv("CMP_STRICT"))

## ---- thresholds ---------------------------------------------------------------
## `rel` is the largest tolerated |fleet / IBM median - 1| over the EIR grid, set
## from what the models achieve today with room to spare (currently 1.6%, 2.6%,
## 2.1% and 6.2% against the limits below).
##
## `out` is how many grid points may fall OUTSIDE the IBM's 10-90% replicate
## range -- a count of failures, not of successes, so CMP_ONLY can check a subset
## without the limit becoming unreachable. These are set AT today's values, with
## no slack: 0, 1, 1 and 2 of 6. That is deliberate rather than an oversight.
## fleet is deterministic and the IBM reference is frozen, so nothing here
## fluctuates; a point moving in or out of the band is a real change every time,
## and there is no noise for headroom to absorb. Loosen one only when you have
## decided the new value is correct, and say so in the commit.
##
## Severe is loosest on both because it is the rarest outcome and the noisiest in
## the IBM: see the article's Programmes section for the widths.
LIMITS <- list(
  pfpr_2_10 = list(rel = 0.02, out = 0L, label = "PfPR 2-10"),
  clin_0_5  = list(rel = 0.05, out = 1L, label = "clinical, 0-5"),
  clin_all  = list(rel = 0.05, out = 1L, label = "clinical, all ages"),
  sev_all   = list(rel = 0.10, out = 2L, label = "severe, all ages"))
## anything moving by more than this against the committed fleet rows is reported;
## solver output is deterministic, so this is a floating-point floor, not a budget
MOVE_TOL <- 1e-6

fail <- character(); warn <- character()
rule <- function(t) cat("\n", t, "\n", strrep("-", nchar(t)), "\n", sep = "")

## ---- 0. is the reference still describing these scenarios? ---------------------
rule("Reference")
ref_f <- file.path(DDIR, "ibm_reference.json")
if (!file.exists(ref_f)) {
  warn <- c(warn, "no ibm_reference.json: the committed IBM rows have no provenance. Re-run validations/02-scenarios/run.R to stamp one.")
  cat("  (absent)\n")
} else {
  ref <- jsonlite::read_json(ref_f, simplifyVector = TRUE)
  cat(sprintf("  IBM rows generated %s\n", ref$generated))
  cat(sprintf("  malariasimulation  %s (installed: %s)\n", ref$malariasimulation,
              as.character(utils::packageVersion("malariasimulation"))))
  cat(sprintf("  %d replicates of %s people, %d-year burn-in\n",
              ref$n_rep, format(ref$population, big.mark = ","), ref$burn_in_years))
  ## a FAIL, not a warning, for the same reason as the digest below: the whole
  ## design rests on the IBM rows staying valid while fleet changes. A different
  ## malariasimulation is a different IBM, so section 2 would be comparing fleet
  ## against a reference the current upstream would no longer produce -- and
  ## `fleet` exists to be a twin of one specific version. This is the condition
  ## the weekly run exists to catch, so it must be loud enough to stop the build.
  if (!identical(ref$malariasimulation, as.character(utils::packageVersion("malariasimulation"))))
    fail <- c(fail, sprintf("malariasimulation has changed since the IBM rows were made (%s -> %s), so the agreement below compares fleet against a reference the installed IBM would no longer reproduce. Re-run validations/02-scenarios/run.R (without CMP_FLEET_ONLY) to rebuild the IBM rows.",
                            ref$malariasimulation, utils::packageVersion("malariasimulation")))
  ## PER-SCENARIO, not aggregate. The question this gate has to answer is "were
  ## these IBM rows made from the scenario definition that is in the file now",
  ## and that is a question about each scenario separately. Gating on the
  ## aggregate could not distinguish a scenario that changed and was refreshed
  ## from one that changed and was not -- so after any CMP_ONLY run that altered
  ## a definition, which is the workflow the README recommends, it failed with
  ## nothing wrong. It stayed red through a correct refresh of eir_3 and eir_120
  ## while the other sixteen scenarios matched perfectly.
  mine <- scenario_digests_each()
  if (is.null(ref$scenario_digests)) {
    fail <- c(fail, "ibm_reference.json has no per-scenario digests, so there is no way to tell which scenarios' rows are current. Re-run validations/02-scenarios/run.R.")
    cat("  scenario digests   ABSENT\n")
  } else {
    shared <- intersect(names(ref$scenario_digests), names(mine))
    bad <- shared[vapply(shared, function(n)
      !identical(unlist(ref$scenario_digests[[n]]), unname(mine[[n]])), logical(1))]
    gone  <- setdiff(names(ref$scenario_digests), names(mine))
    new_s <- setdiff(names(mine), names(ref$scenario_digests))
    if (length(bad) || length(new_s)) {
      ## a FAIL, not a warning: for these scenarios section 2 below is comparing
      ## fleet-on-the-new-definition against IBM-on-the-old one, which is not a
      ## valid answer to "is the match still good" no matter what it prints
      fail <- c(fail, sprintf("%d scenario definition(s) have changed since their IBM rows were made (%s), so the agreement below compares fleet on the new definitions against the IBM on the old ones. Re-run validations/02-scenarios/run.R, or CMP_ONLY=%s for just these.",
                              length(bad) + length(new_s),
                              paste(c(bad, new_s), collapse = ", "),
                              paste(c(bad, new_s), collapse = ",")))
      if (length(bad))   cat("    stale scenarios:  ", paste(bad, collapse = ", "), "\n")
      if (length(new_s)) cat("    never run:        ", paste(new_s, collapse = ", "), "\n")
      ## For the offenders the per-key digests say WHICH parameter moved. An
      ## unlocalised mismatch is not actionable: it says something changed across
      ## fifty-odd parameters. Added after one took several CI runs to find.
      for (n in head(bad, 2L)) {
        cat(sprintf("    [%s] per-key digests:\n", n))
        kd <- scenario_key_digests(scenarios[[n]])
        for (k in names(kd)) cat(sprintf("      %-42s %s\n", k, kd[[k]]))
      }
    } else {
      cat(sprintf("  scenario digests   %d of %d current\n", length(shared), length(mine)))
    }
    ## A scenario dropped from the set is not a staleness: its rows are stale by
    ## definition, but nothing reads them any more. Worth saying, not worth
    ## failing on.
    if (length(gone))
      cat("    in the reference but no longer defined:", paste(gone, collapse = ", "), "\n")
  }
}

## ---- run fleet against the frozen reference -----------------------------------
rule("Re-running fleet")
new_eq <- do.call(rbind, lapply(run_fleet(), `[[`, "eq"))
old <- read.csv(file.path(DDIR, "rep_eq.csv"), stringsAsFactors = FALSE)
MET <- names(LIMITS)

## ---- 1. did anything move? ----------------------------------------------------
rule("1. Movement against the committed fleet rows")
ob <- old[old$model == "fleet", ]
cmp <- merge(new_eq[, c("scenario", MET)], ob[, c("scenario", MET)],
             by = "scenario", suffixes = c(".new", ".old"))
moved <- do.call(rbind, lapply(MET, function(m) {
  a <- cmp[[paste0(m, ".new")]]; b <- cmp[[paste0(m, ".old")]]
  rel <- ifelse(abs(b) > 0, abs(a / b - 1), NA_real_)
  k <- which(!is.na(rel) & rel > MOVE_TOL)
  if (!length(k)) NULL else
    data.frame(scenario = cmp$scenario[k], outcome = LIMITS[[m]]$label,
               committed = b[k], now = a[k], rel = rel[k])
}))
if (is.null(moved)) {
  cat("  nothing moved: every value reproduces the committed rows to 1e-6.\n")
} else {
  moved <- moved[order(-moved$rel), ]
  cat(sprintf("  %d of %d scenario x outcome values moved:\n\n", nrow(moved),
              nrow(cmp) * length(MET)))
  cat(sprintf("    %-12s %-20s %12s %12s %9s\n", "scenario", "outcome", "committed", "now", "change"))
  for (i in seq_len(min(nrow(moved), 25))) with(moved[i, ], cat(sprintf(
    "    %-12s %-20s %12.5g %12.5g %+8.2f%%\n", scenario, outcome, committed, now, 100 * rel)))
  if (nrow(moved) > 25) cat(sprintf("    ... and %d more\n", nrow(moved) - 25))
  cat("\n  Movement is not automatically wrong. If it was intended, refresh the\n",
      "  committed rows with CMP_FLEET_ONLY=1 Rscript validations/02-scenarios/run.R\n", sep = "")
  if (STRICT) fail <- c(fail, sprintf("%d values moved (CMP_STRICT)", nrow(moved)))
}

## ---- 2. is the match still good? ----------------------------------------------
rule("2. Agreement with the committed IBM reference")
e <- old[old$model == "IBM" & grepl("^eir_", old$scenario), ]
if (!nrow(e)) {
  warn <- c(warn, "no IBM rows for the EIR grid in rep_eq.csv; cannot check agreement.")
} else {
  cat(sprintf("    %-20s %10s %8s %15s %7s\n", "outcome", "max |rel|", "limit", "outside band", "limit"))
  for (m in MET) {
    lim <- LIMITS[[m]]
    st <- do.call(rbind, lapply(split(e, e$scenario), function(g) data.frame(
      scenario = g$scenario[1], med = median(g[[m]]),
      lo = quantile(g[[m]], .1), hi = quantile(g[[m]], .9))))
    st <- merge(st, new_eq[, c("scenario", m)], by = "scenario")
    v <- st[[m]]
    rel <- max(abs(v / st$med - 1))
    ## band_summary() from the package rather than `sum(v < lo | v > hi)` here.
    ## Same arithmetic, but "inside the IBM 10-90% replicate band" is the
    ## criterion four claims in the register are decided by, so it is defined
    ## once and unit-tested rather than re-spelled at each place that asks it.
    bs <- band_summary(v, st$lo, st$hi)
    outb <- bs$n - bs$n_inside
    bad <- rel > lim$rel || outb > lim$out
    cat(sprintf("    %-20s %9.1f%% %7.1f%% %9d of %-3d %6d  %s\n", lim$label,
                100 * rel, 100 * lim$rel, outb, nrow(st), lim$out,
                if (bad) "<-- DRIFT" else "ok"))
    if (bad) fail <- c(fail, sprintf("%s: max |rel| %.1f%% (limit %.1f%%), outside band %d of %d (limit %d)",
                                     lim$label, 100 * rel, 100 * lim$rel, outb, nrow(st), lim$out))
  }
}

## ---- verdict -------------------------------------------------------------------
rule("Verdict")
for (w in warn) cat("  WARNING: ", w, "\n", sep = "")
if (length(fail)) {
  for (f in fail) cat("  FAIL: ", f, "\n", sep = "")
  cat("\n  Drifted. Either the change is wrong, or the reference needs refreshing.\n")
  quit(status = 1)
}
cat("  Still matching.", if (length(warn)) " (with warnings above)" else "", "\n", sep = "")
