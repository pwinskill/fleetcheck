# Run every comparison scenario through BOTH models and save tidy CSVs.
#
#   Rscript validations/02-scenarios/run.R          # ~2 h on 10 workers (see cost note)
#   Rscript validations/02-scenarios/render.R          # seconds: figures from the CSVs
#   CMP_ONLY=nets,smc Rscript validations/02-scenarios/run.R   # re-run a subset, merge into the CSVs
#
# The IBM (malariasimulation) is run N_REP times per scenario with different
# seeds, in parallel on a PSOCK cluster, and summarised per replicate; fleet is
# run once (it is deterministic). Both get the SAME parameter list, with the
# rendering bands set once so their output columns line up exactly.
#
# Every scenario is burned in BURN_Y years in the IBM so it reaches its own
# stochastic steady state; fleet is seeded at the malariaEquilibrium fixed point
# and integrated over the same horizon so both are on a common clock.
#
# Cost note: the IBM's per-band rendering dominates its run time at 10k people
# (~2.5 s per simulated year with the three default ranges, ~5 s with the 12-band
# age profile added to every family), so only the reference scenario carries the
# age-profile bands. Jobs are load-balanced, longest first.

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
DDIR <- file.path(ROOT, "validations", "02-scenarios", "results"); dir.create(DDIR, showWarnings = FALSE)
N_WORKERS <- 10L
## CMP_SMOKE=1 -> a few-minute end-to-end check: 4-year horizon, one replicate,
## interventions at year 1 so every builder actually fires, output to validations/02-scenarios/results/smoke/.
SMOKE <- nzchar(Sys.getenv("CMP_SMOKE"))
if (SMOKE) { N_REP <- 1L; N_WORKERS <- 3L; BURN_Y <- 1L
  DDIR <- file.path(DDIR, "smoke"); dir.create(DDIR, showWarnings = FALSE) }
PROG <- file.path(DDIR, "progress.log"); if (file.exists(PROG)) invisible(file.remove(PROG))
log_msg <- function(...) cat(sprintf("[%s] %s\n", format(Sys.time(), "%H:%M:%S"),
                                     sprintf(...)))

## Scenario definitions and the shared summariser. Kept in their own file so the
## drift check can reach them without starting a run.

## CMP_FLEET_ONLY=1 -> re-run only fleet (the IBM rows are kept): for a fleet-side
## model change, when the IBM results are unaffected
FLEET_ONLY <- nzchar(Sys.getenv("CMP_FLEET_ONLY"))


## ---- run fleet (deterministic, seconds) --------------------------------------
ode <- run_fleet()

## ---- run the IBM replicates in parallel --------------------------------------
ibm <- list()
if (!FLEET_ONLY) {
jobs <- expand.grid(scenario = names(scenarios), rep = seq_len(N_REP),
                    stringsAsFactors = FALSE)
## rough cost in default-band sim-years, so the load balancer starts the longest jobs first
jobs$cost <- vapply(jobs$scenario, function(nm) scenarios[[nm]]$years *
  (if (length(scenarios[[nm]]$p$prevalence_rendering_min_ages) > 1) 2 else 1), numeric(1))
jobs <- jobs[order(-jobs$cost, jobs$rep), ]; rownames(jobs) <- NULL
log_msg("IBM: %d runs (%d scenarios x %d reps) on %d workers; ~%.0f min at 2.5 s per sim-year",
        nrow(jobs), length(scenarios), N_REP, N_WORKERS, sum(jobs$cost) * 2.5 / N_WORKERS / 60)
cl <- parallel::makeCluster(N_WORKERS)
## workers do not inherit .libPaths(), so hand them the parent's rather than
## hardcoding one: whatever library this session is using, they use too
.libs <- .libPaths()
parallel::clusterExport(cl, c("jobs", "scenarios", "summarise_run", "tag_parts", "band_lo",
                              "band_hi", "AGE_TAGS", "POP", "BURN_Y", "PROG", ".libs"))
invisible(parallel::clusterEvalQ(cl, {
  .libPaths(.libs)
  suppressMessages(library(malariasimulation))
}))
t0 <- Sys.time()
ibm <- parallel::parLapplyLB(cl, seq_len(nrow(jobs)), function(j) {
  nm <- jobs$scenario[j]; k <- jobs$rep[j]; s <- scenarios[[nm]]
  set.seed(1000L + 7L * k)
  el <- system.time(out <- run_simulation(timesteps = s$years * 365, parameters = s$p))[["elapsed"]]
  r <- summarise_run(out, s$years)
  r$timing <- data.frame(years = s$years, elapsed_s = el)
  cat(sprintf("[%s] %-10s rep %d  %5.1f min\n", format(Sys.time(), "%H:%M:%S"), nm, k, el / 60),
      file = PROG, append = TRUE)
  tag_parts(r, nm, "IBM", k)
}, chunk.size = 1L)
parallel::stopCluster(cl)
log_msg("IBM done in %.1f min", as.numeric(Sys.time() - t0, units = "mins"))
}

## ---- combine and write -------------------------------------------------------
bind <- function(part) do.call(rbind, c(lapply(ode, `[[`, part), lapply(ibm, `[[`, part)))
for (part in c("eq", "age", "monthly", "doy", "timing")) {
  d <- bind(part); f <- file.path(DDIR, paste0("rep_", part, ".csv"))
  if ((length(ONLY) || FLEET_ONLY) && file.exists(f)) {   # partial run: replace just those rows
    old <- read.csv(f, stringsAsFactors = FALSE)
    ## `%in%` is NA-safe; `==` is not. An NA in `model` gives TRUE & NA = NA,
    ## !NA = NA, and `old[NA, ]` MATERIALISES a row of NAs -- the same poison
    ## row the guard below exists to prevent, regenerated one line above it.
    ## which() drops NA outright, so a malformed row is discarded rather than
    ## propagated.
    drop <- old$scenario %in% names(scenarios) &
      (if (FLEET_ONLY) !is.na(old$model) & old$model == "fleet" else TRUE)
    old <- old[which(!drop), ]
    ## A part can be EMPTY on either side. Only the scenarios carrying
    ## age-profile bands produce `age` rows, so CMP_ONLY=pmc produces none at
    ## all and bind() returns NULL; and `old` is empty whenever the run covers
    ## every scenario a part holds. `x[[nm]] <- NA` on a NULL builds a one-row
    ## list (which rbind appended as a row of NAs, under a scenario named NA,
    ## poisoning every subset of the file because `x[x$scenario == "eir_3", ]`
    ## matches NA and carries it along); on a zero-row frame it errors outright
    ## with "replacement has 1 row, data has 0" -- AFTER the two-hour sweep.
    if (is.null(d) || !nrow(d)) {
      d <- old
    } else if (!nrow(old)) {
      ## nothing to merge: d already carries every scenario this part holds
    } else {
      for (nm in setdiff(names(d), names(old))) old[[nm]] <- rep(NA, nrow(old))
      for (nm in setdiff(names(old), names(d))) d[[nm]] <- rep(NA, nrow(d))
      d <- rbind(old[names(d)], d)
    }
  }
  ## Six significant figures, except rep_eq.csv, which assess.R asserts against
  ## at 1e-6 and which is 46 KB anyway. Rounding is done HERE rather than by
  ## hand afterwards: it was done by hand once, and the next run of this script
  ## wrote full precision again and took rep_monthly.csv from 6.4 MB back to
  ## 19.9 MB with nothing noticing.
  write.csv(round_sig(d, if (part == "eq") NULL else 6), f, row.names = FALSE)
  log_msg("wrote rep_%s.csv (%d rows)", part, nrow(d))
}
## The IBM rows just changed, so stamp what produced them.
##
## The stamp is a PER-SCENARIO record, so a partial run updates the entries for
## the scenarios it actually refreshed and leaves the rest alone. It used to skip
## the stamp entirely, on the reasoning that "the existing stamp still describes
## the rest" -- true of the scenarios it did not touch, and false of the ones it
## did, whose rows were now newer than their stamped digest. assess.R then failed
## on scenarios it had just been handed fresh rows for, every time, which is
## worse than no check: a gate that cries wolf makes a real staleness invisible.
##
## The aggregate digest is only refreshed when the merged map turns out to be
## fully current. Writing the current aggregate after a partial refresh would
## claim the untouched rows had been rebuilt too.
##
## CMP_FLEET_ONLY touches no IBM rows at all, so it stamps nothing.
if (!FLEET_ONLY && !SMOKE) {
  p_ref <- file.path(DDIR, "ibm_reference.json")
  now <- ibm_reference()
  if (length(ONLY) && file.exists(p_ref)) {
    old <- jsonlite::read_json(p_ref)
    ## A partial refresh under a different IBM would leave the file describing
    ## two versions at once, and nothing downstream could tell which rows came
    ## from which. Refuse rather than record a version that is wrong for half
    ## the rows.
    if (!identical(old$malariasimulation, now$malariasimulation))
      stop("malariasimulation has changed since the committed IBM rows were made (",
           old$malariasimulation, " -> ", now$malariasimulation, "), so a partial ",
           "run would leave ibm_reference.json describing two versions at once. ",
           "Re-run the whole set without CMP_ONLY.", call. = FALSE)
    merged <- old$scenario_digests
    for (nm in ONLY) merged[[nm]] <- now$scenario_digests[[nm]]
    ## SORTED. scenario_digests_each() returns sorted names while `merged` keeps
    ## the old insertion order with new keys appended, and identical() compares
    ## list names IN ORDER -- so adding a scenario made `current` FALSE for ever,
    ## and the aggregate digest could never catch up again.
    merged <- merged[order(names(merged))]
    current <- identical(lapply(merged, unlist),
                         lapply(as.list(scenario_digests_each()), unname))
    now$scenario_digests <- merged
    ## derived from the map, not carried over: taking `scenarios` from `old`
    ## left a scenario present in the digests and absent from the list.
    now$scenarios        <- sort(names(merged))
    ## `%||%` is a package internal, not an export, so a runner cannot use it:
    ## it resolves under pkgload::load_all() and not under library(fleetcheck).
    keep <- function(a, b) if (is.null(a)) b else a
    now$generated        <- keep(old$generated, now$generated)  # the oldest rows
    ## n_rep / population describe rows this run did not touch, so they must not
    ## silently take today's values: changing N_REP and running CMP_ONLY would
    ## otherwise restamp the whole file, which is the staleness this file exists
    ## to catch.
    now$n_rep            <- keep(old$n_rep, now$n_rep)
    now$population       <- keep(old$population, now$population)
    if (!current) now$scenario_digest <- old$scenario_digest
  }
  jsonlite::write_json(now, p_ref, auto_unbox = TRUE, pretty = TRUE)
  log_msg("wrote ibm_reference.json (%s%d scenario digests)",
          if (length(ONLY)) sprintf("%d of ", length(ONLY)) else "",
          length(now$scenario_digests))
}
log_msg("ALL DONE")
