# Which parameter draws the parameter-draws claim tests.
#
#   Rscript validations/04-parameter-draws/select.R        # about five minutes, fleet only
#
# set_parameter_draw() swaps in one of 1,000 draws of the core parameters from the
# model fit's joint posterior. Testing all of them against the IBM would cost a
# thousand IBM sweeps, so the claim tests draws that span what the posterior does
# to the burden: fleet is run at every draw, at EIR 20, and the draws nearest the
# 5th, 25th, 75th and 95th percentiles of all-age clinical and of all-age severe
# incidence are kept -- the corners of the posterior, where a parameter fleet
# handled wrongly, or an approximation whose error grows with a parameter, would
# show. The median draw is what every other claim already runs.
#
# The selection is on fleet's outputs, which is a design choice and not part of
# the test: the test is fleet against the IBM at the draws chosen. Each run is a
# year from set_equilibrium()'s seed, not a settled equilibrium; the ranking is
# what matters, and it is the same on settled runs.
#
# The same sweep at EIR 3 and 120 says how much of the posterior the eight draws
# span where they were not chosen, and what the posterior's spread is:
#   results/draws.csv            the draws chosen, which run.R reads
#   results/fleet_sweep.csv      every draw at EIR 3, 20 and 120
#   results/draws_coverage.csv   each chosen draw's percentile, by EIR and outcome
#   results/refused.csv          the draws fleet will not run, with its reason
#
# The IBM rows in results/ belong to the draws in draws.csv, so this refuses to
# change that file once it exists: a re-run must reproduce it, or be asked to
# replace it with CMP_RESELECT=1, after which run.R has to be run again.

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
## fc_root() and fc_results() resolve from here, not from the working directory
Sys.setenv(FLEETCHECK_ROOT = ROOT)
suppressMessages({library(malariasimulation); library(fleet)})
suppressMessages(pkgload::load_all(ROOT, quiet = TRUE))
## 0.0.0.9004 follows a draw's iv0; an older fleet takes malariaEquilibrium's
## default for it and moves severe incidence by up to 60% at some draws
if (utils::packageVersion("fleet") < "0.0.0.9004")
  stop("fleet ", utils::packageVersion("fleet"), " predates 0.0.0.9004, which reads ",
       "a draw's iv0; install a current fleet.", call. = FALSE)

DDIR <- fc_results("04-parameter-draws"); dir.create(DDIR, showWarnings = FALSE, recursive = TRUE)
N_WORKERS <- as.integer(Sys.getenv("CMP_WORKERS", "4"))
log_msg <- function(...) cat(sprintf("[%s] %s\n", format(Sys.time(), "%H:%M:%S"), sprintf(...)))
MET <- c("pfpr_2_10", "clin_0_5", "clin_all", "sev_all")
EIRS <- c(3, 20, 120)

## fleet at one draw and EIR: a year from the seed, its mean. Only fleet's
## daily-clock refusal is recorded as a refusal: fleet checks before it runs
## that no age group can lose more than it holds in a day, bounding a day's
## infections by b0, so a draw with b0 near 1 fails that check on the default
## grid. Any other error is a fault, and stops the sweep.
one_draw <- function(d, E) {
  p <- get_parameters(list(clinical_incidence_rendering_min_ages = c(0, 0),
                           clinical_incidence_rendering_max_ages = c(1825, 36500),
                           severe_incidence_rendering_min_ages = 0,
                           severe_incidence_rendering_max_ages = 36500))
  p <- set_equilibrium(set_parameter_draw(p, d), init_EIR = E)
  rate <- function(o, num, den, per = 365) mean(o[[num]] / o[[den]]) * per
  tryCatch({
    o <- fleet::run_simulation_ode(timesteps = 365, parameters = p)
    data.frame(draw = d, eir = E, b0 = p$b0,
               pfpr_2_10 = mean(o$n_detect_lm_730_3650 / o$n_age_730_3650),
               clin_0_5 = rate(o, "n_inc_clinical_0_1825", "n_age_0_1825"),
               clin_all = rate(o, "n_inc_clinical_0_36500", "n_age_0_36500"),
               sev_all = rate(o, "n_inc_severe_0_36500", "n_age_0_36500", 365 * 1000),
               refused = NA_character_)
  }, error = function(e) {
    if (!grepl("too narrow for the daily clock", conditionMessage(e))) stop(e)
    data.frame(draw = d, eir = E, b0 = p$b0, pfpr_2_10 = NA_real_, clin_0_5 = NA_real_,
               clin_all = NA_real_, sev_all = NA_real_, refused = conditionMessage(e))
  })
}
jobs <- expand.grid(draw = 1:1000, eir = EIRS)
log_msg("fleet at all 1,000 draws, EIR %s, on %d workers", paste(EIRS, collapse = ", "), N_WORKERS)
cl <- parallel::makeCluster(N_WORKERS)
.libs <- .libPaths()
parallel::clusterExport(cl, c("one_draw", "jobs", ".libs"))
invisible(parallel::clusterEvalQ(cl, {
  .libPaths(.libs); suppressMessages(library(malariasimulation))
}))
sweep <- do.call(rbind, parallel::parLapplyLB(cl, seq_len(nrow(jobs)),
                                              function(i) one_draw(jobs$draw[i], jobs$eir[i])))
parallel::stopCluster(cl)

## the refused draws, and why: the claim reports them. fleet's falciparum check
## does not depend on the EIR, so EIR 20's are every EIR's.
refused <- sweep[sweep$eir == 20 & !is.na(sweep$refused), c("draw", "b0", "refused")]
log_msg("fleet refuses %d of 1,000 draws%s", nrow(refused),
        if (nrow(refused)) paste0(": ", paste(refused$draw, collapse = ", ")) else "")
ran20 <- sweep[sweep$eir == 20 & is.na(sweep$refused), ]

## the draws nearest each percentile at EIR 20, outcome by outcome, without repeats
QS <- c(0.05, 0.25, 0.75, 0.95)
pick <- data.frame()
for (m in c("clin_all", "sev_all")) for (q in QS) {
  target <- stats::quantile(ran20[[m]], q)
  left <- ran20[!ran20$draw %in% pick$draw, ]
  d <- left$draw[which.min(abs(left[[m]] - target))]
  pick <- rbind(pick, data.frame(draw = d, chosen_for = m, quantile = q))
}
pick <- merge(pick, ran20[c("draw", "b0", "clin_all", "sev_all")], by = "draw")
pick <- pick[order(pick$chosen_for, pick$quantile), ]
rownames(pick) <- NULL

## The IBM rows belong to the draws already chosen: keep them unless asked
f_draws <- file.path(DDIR, "draws.csv")
if (file.exists(f_draws) && !nzchar(Sys.getenv("CMP_RESELECT"))) {
  old <- read.csv(f_draws, stringsAsFactors = FALSE)
  if (!identical(as.integer(old$draw), as.integer(pick$draw)))
    stop("this sweep picks draws ", paste(pick$draw, collapse = ", "), " but results/draws.csv ",
         "holds ", paste(old$draw, collapse = ", "), ", whose IBM rows run.R made. Set ",
         "CMP_RESELECT=1 to replace them, then re-run run.R.", call. = FALSE)
}
write.csv(round_sig(pick, 6), f_draws, row.names = FALSE)
write.csv(round_sig(refused, 6), file.path(DDIR, "refused.csv"), row.names = FALSE)
write.csv(round_sig(sweep[c("draw", "eir", "b0", MET)], 6), file.path(DDIR, "fleet_sweep.csv"),
          row.names = FALSE)

## how much of the posterior the chosen draws span, at each EIR and outcome:
## each draw's percentile among the draws fleet ran there
ran <- sweep[is.na(sweep$refused), ]
cover <- do.call(rbind, lapply(EIRS, function(E) do.call(rbind, lapply(MET, function(m) {
  v <- ran[ran$eir == E, m]
  x <- ran[ran$eir == E & ran$draw %in% pick$draw, c("draw", m)]
  data.frame(eir = E, metric = m, draw = x$draw,
             percentile = vapply(x[[m]], function(z) 100 * mean(v <= z), numeric(1)))
}))))
write.csv(round_sig(cover, 4), file.path(DDIR, "draws_coverage.csv"), row.names = FALSE)

log_msg("draws: %s", paste(pick$draw, collapse = ", "))
print(pick, row.names = FALSE)
cat("\nthe posterior's spread in fleet (one-year runs over the draws it runs), and the\n",
    "percentiles of it the eight draws span:\n", sep = "")
for (E in EIRS) for (m in MET) {
  v <- ran[ran$eir == E, m]; q <- stats::quantile(v, c(0.05, 0.5, 0.95))
  pc <- range(cover$percentile[cover$eir == E & cover$metric == m])
  cat(sprintf("  EIR %-4g %-10s middle 90%% spans %3.0f%% of the median; draws span percentiles %.0f to %.0f\n",
              E, m, 100 * (q[[3]] - q[[1]]) / q[[2]], pc[1], pc[2]))
}
