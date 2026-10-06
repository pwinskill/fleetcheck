# What makes fleet's severe-incidence response depend on the draw?
#
#   Rscript validations/04-parameter-draws/diagnose.R   # about fifteen minutes on 4 workers
#
# assess.R finds fleet's severe-incidence changes further from the IBM's than
# the IBM's noise allows, though inside its replicate band, and the gaps
# largest at the draws whose refractory period for boosting severe-disease
# immunity (uv) is shortest. One mechanism fits: the IBM's severe probability is
# each person's own, a convex function of their immunity, while fleet evaluates
# it at the mean immunity of the cell, which leaves out the spread of immunity
# within a cell. A refractory period spaces a person's boosts out, so the
# shorter it is the less regular the boosts and the wider the spread. fleet's
# falciparum immunity offset of zero, where the IBM adds 0.5, makes up for the
# spread at the default parameters; a parameter that changes the spread moves
# fleet off the IBM.
#
# This tests that directly, at the default parameters with uv alone changed: to
# the shortest and the longest uv among the eight draws (1.67 and 35.0 days,
# against 11.43), at EIR 120, where the gaps are largest. 20 IBM replicates of
# each with run.R's seeds -- 40 IBM runs; the default's are validations/
# 02-scenarios' eir_120 rows -- and fleet on the default 118 age groups and on
# 354, extrapolated to a converged grid from the two (the grid's error is first
# order in the group width). If the spread is the mechanism, fleet runs low
# against the IBM at the short uv and high at the long one, with nothing else
# changed; no other parameter moves, and the grid's error is the same sign at
# all three.
#
# Writes results/diagnose_uv.csv and its provenance, results/diagnose_uv.json.

## No absolute paths anywhere in here. FLEET_LIB is prepended to the library
## path, for installations that do not pick up R_LIBS_USER (the Windows-arm64
## setup this was developed on); the libraries already on the path are kept. ROOT
## is found by walking up to the DESCRIPTION, so this runs from any working
## directory and on anyone's checkout, whether via Rscript or source().
if (nzchar(.l <- Sys.getenv("FLEET_LIB"))) .libPaths(c(.l, .libPaths()))
.f <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))
ROOT <- if (length(.f)) normalizePath(dirname(.f), "/") else getwd()
while (!file.exists(file.path(ROOT, "DESCRIPTION")) && dirname(ROOT) != ROOT)
  ROOT <- dirname(ROOT)
if (!file.exists(file.path(ROOT, "DESCRIPTION")))
  stop("run this from inside the fleetcheck checkout (no DESCRIPTION found above ", getwd(), ")")
Sys.setenv(FLEETCHECK_ROOT = ROOT)
suppressMessages(library(malariasimulation))
if (requireNamespace("pkgload", quietly = TRUE) &&
    file.exists(file.path(ROOT, "DESCRIPTION"))) {
  suppressMessages(pkgload::load_all(ROOT, quiet = TRUE))
} else {
  suppressMessages(library(fleetcheck))
}
log_msg <- function(...) cat(sprintf("[%s] %s\n", format(Sys.time(), "%H:%M:%S"), sprintf(...)))
if (utils::packageVersion("fleet") < "0.0.0.9004")
  stop("fleet ", utils::packageVersion("fleet"), " predates 0.0.0.9004, which reads ",
       "a draw's iv0; install a current fleet.", call. = FALSE)
source(file.path(ROOT, "validations", "_shared", "scenarios.R"))
if (SP != "pf")
  stop("the parameter-draws claim is P. falciparum only; unset CMP_PARASITE.", call. = FALSE)

DDIR <- fc_results("04-parameter-draws")
N_WORKERS <- as.integer(Sys.getenv("CMP_WORKERS", "4"))
E <- 120
UV <- c(1.67, 35.0)                           # the shortest and longest uv among the draws
probes <- c(list(default = draw_scenario(0, E)),
            stats::setNames(lapply(UV, function(u) draw_scenario(0, E, uv = u)),
                            sprintf("uv_%g", UV)))

## ---- fleet on two grids -------------------------------------------------------------
GRIDS <- c(118L, 354L)
fl <- do.call(rbind, lapply(names(probes), function(nm) {
  s <- probes[[nm]]
  v <- vapply(GRIDS, function(n) {
    o <- fleet::run_simulation_ode(s$years * 365, s$p,
                                   tuning = list(age_lower = fleet::default_age_lower(n_group = n)))
    summarise_run(o, s$years)$eq$sev_all
  }, numeric(1))
  data.frame(probe = nm, uv = s$p$uv, fleet_118 = v[1], fleet_354 = v[2],
             fleet_converged = v[2] + (v[2] - v[1]) / 2)
}))
log_msg("fleet done")

## ---- the IBM: 20 replicates of each probe; the default's are 02-scenarios' --------
jobs <- expand.grid(probe = names(probes)[-1], rep = seq_len(N_REP), stringsAsFactors = FALSE)
log_msg("%d IBM runs on %d workers", nrow(jobs), N_WORKERS)
cl <- parallel::makeCluster(N_WORKERS)
.libs <- .libPaths()
parallel::clusterExport(cl, c("jobs", "probes", "summarise_run", "summarise_run_pv",
                              "band_lo", "band_hi", "AGE_TAGS", "POP", "SP", ".libs"))
invisible(parallel::clusterEvalQ(cl, { .libPaths(.libs); suppressMessages(library(malariasimulation)) }))
ran <- parallel::parLapplyLB(cl, seq_len(nrow(jobs)), function(j) {
  s <- probes[[jobs$probe[j]]]; k <- jobs$rep[j]
  set.seed(1000L + 7L * k)
  out <- run_simulation(timesteps = s$years * 365, parameters = s$p)
  data.frame(probe = jobs$probe[j], rep = k, sev_all = summarise_run(out, s$years)$eq$sev_all)
}, chunk.size = 1L)
parallel::stopCluster(cl)
o02 <- read.csv(fc_results("02-scenarios", "rep_eq.csv"), stringsAsFactors = FALSE)
ibm <- rbind(do.call(rbind, ran),
             data.frame(probe = "default", rep = o02$rep[o02$model == "IBM" & o02$scenario == "eir_120"],
                        sev_all = o02$sev_all[o02$model == "IBM" & o02$scenario == "eir_120"]))
log_msg("IBM done")

## fleet against the IBM's mean (a mean field approximates the mean, not the
## median), in per cent and in standard errors of that mean
res <- merge(fl, do.call(rbind, lapply(split(ibm, ibm$probe), function(x)
  data.frame(probe = x$probe[1], n_rep = nrow(x), ibm_mean = mean(x$sev_all),
             ibm_se = stats::sd(x$sev_all) / sqrt(nrow(x)), ibm_median = stats::median(x$sev_all)))),
  by = "probe")
for (g in c("118", "converged")) {
  v <- res[[paste0("fleet_", g)]]
  res[[paste0("gap_", g, "_pct")]] <- 100 * (v / res$ibm_mean - 1)
  res[[paste0("gap_", g, "_se")]] <- (v - res$ibm_mean) / res$ibm_se
}
res <- res[order(res$uv), ]
write.csv(round_sig(res, 6), file.path(DDIR, "diagnose_uv.csv"), row.names = FALSE)
jsonlite::write_json(stamp(eir = E, uv = UV, n_rep = N_REP, grids = GRIDS,
                           seeds = "1000 + 7k, as run.R"),
                     file.path(DDIR, "diagnose_uv.json"), auto_unbox = TRUE, pretty = TRUE)
cat("\nall-age severe incidence at EIR 120, the default parameters with uv alone changed:\n")
for (i in seq_len(nrow(res))) with(res[i, ], cat(sprintf(
  "  uv %5.2f d   IBM %.3f (SE %.3f) per 1,000   fleet vs IBM mean: %+5.1f%% on 118 groups, %+5.1f%% converged (%+.1f SE)\n",
  uv, ibm_mean, ibm_se, gap_118_pct, gap_converged_pct, gap_converged_se)))
