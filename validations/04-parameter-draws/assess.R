# Does a parameter draw move fleet's outcomes the way it moves the IBM's?
#
#   Rscript validations/04-parameter-draws/assess.R                # two minutes: re-runs fleet only
#   CMP_STRICT=1 Rscript validations/04-parameter-draws/assess.R   # also fail if any number moved
#
# The claim is about the response: the change each draw makes to an outcome,
# relative to the default parameters at the same EIR, in each model. fleet's
# change is the ratio of its two runs. The IBM's band is the spread of the same
# ratio between one replicate at the draw and one at the default parameters,
# over every such pair: 20 x 20 = 400 ratios, median +/- 1.28 SD (the register's
# replicate band). The replicates are not paired by seed: a draw changes the
# dynamics from the first day, so same-seed runs are independent. A ratio of two
# runs on one age grid divides out fleet's fixed offsets, which the EIR claims
# report, as in the intervention-impact claim.
#
# The band is the noise floor of a single IBM pair, and it is wide: about four
# and a half standard errors of the IBM's mean change either side. It is the
# criterion, a screen for gross errors. Beside it, and not scored, each outcome
# gets the test the band cannot make: fleet's 24 changes against the IBM's mean
# changes and their standard errors, as a chi-squared, with the IBM's error in
# excess of its noise, root mean square.
#
# The IBM's default-parameter runs are validations/02-scenarios' eir_3, eir_20
# and eir_120: the same scenarios with more rendering bands, which change no
# dynamics. Reading them costs no IBM runs; section 0 checks that they are those
# scenarios, current, and made as this suite's rows were.
#
# Each draw's level -- fleet against the IBM's band for the draw itself -- is
# reported beside the response but not scored.
#
# The IBM does not depend on fleet, so its committed rows stay valid for any
# fleet-side change, and this re-runs fleet only, as
# validations/02-scenarios/assess.R does. Writes results/draws_cells.csv, one row
# per draw, EIR and outcome, which render.R draws -- only when section 0 passes.
#
# Exit 0 = the claim holds. Exit 1 = a change outside its band or not scored,
# IBM rows that no longer describe the scenarios, or, under CMP_STRICT, any
# movement at all. Under CMP_SMOKE (one draw, a four-year horizon, two IBM
# replicates against validations/02-scenarios' one) the verdict only warns:
# a band of two ratios is a check that the code runs, not evidence.

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
suppressMessages(library(malariasimulation))
log_msg <- function(...) cat(sprintf("[%s] %s\n", format(Sys.time(), "%H:%M:%S"), sprintf(...)))
if (requireNamespace("pkgload", quietly = TRUE) &&
    file.exists(file.path(ROOT, "DESCRIPTION"))) {
  suppressMessages(pkgload::load_all(ROOT, quiet = TRUE))
} else {
  suppressMessages(library(fleetcheck))
}
if (utils::packageVersion("fleet") < "0.0.0.9004")
  stop("fleet ", utils::packageVersion("fleet"), " predates 0.0.0.9004, which reads ",
       "a draw's iv0; install a current fleet.", call. = FALSE)

## the scenario builder, run_fleet() and the digest helpers run.R used
source(file.path(ROOT, "validations", "_shared", "scenarios.R"))
if (SP != "pf")
  stop("the parameter-draws claim is P. falciparum only; unset CMP_PARASITE.", call. = FALSE)

DDIR <- fc_results("04-parameter-draws")
D02 <- fc_results("02-scenarios")              # the IBM's default-parameter runs
draws <- read.csv(file.path(DDIR, "draws.csv"), stringsAsFactors = FALSE)
f_ref <- file.path(DDIR, "refused.csv")
refused <- if (file.exists(f_ref)) read.csv(f_ref, stringsAsFactors = FALSE) else NULL
if (SMOKE) {
  draws <- draws[1, ]; DDIR <- file.path(DDIR, "smoke"); D02 <- file.path(D02, "smoke")
  if (!file.exists(file.path(D02, "rep_eq.csv")))
    stop("CMP_SMOKE needs validations/02-scenarios' smoke rows for the default parameters: ",
         "run CMP_SMOKE=1 Rscript validations/02-scenarios/run.R first.", call. = FALSE)
}
STRICT <- nzchar(Sys.getenv("CMP_STRICT"))
MET <- c(pfpr_2_10 = "LM prevalence, 2-10", clin_0_5 = "clinical, 0-5",
         clin_all = "clinical, all ages", sev_all = "severe, all ages")
## solver output is deterministic, so this is a floating-point floor, not a budget
MOVE_TOL <- 1e-6

draw_scen <- list(); ref_scen <- list()
for (E in PROFILE_EIR) ref_scen[[draw_scenario_name(0, E)]] <- draw_scenario(0, E)
for (d in draws$draw) for (E in PROFILE_EIR)
  draw_scen[[draw_scenario_name(d, E)]] <- draw_scenario(d, E)
## the EIR grid's names for the IBM's default-parameter rows
ref_02 <- sprintf("eir_%g", PROFILE_EIR)

fail <- character(); warn <- character()
rule <- function(t) cat("\n", t, "\n", strrep("-", nchar(t)), "\n", sep = "")

## ---- 0. are the IBM rows the ones these scenarios need? -----------------------------
rule("Reference")
read_ref <- function(f, what) {
  if (file.exists(f)) return(jsonlite::read_json(f, simplifyVector = TRUE))
  m <- sprintf("no %s: the %s have no provenance.", f, what)
  if (SMOKE) warn <<- c(warn, m) else fail <<- c(fail, m)
  NULL
}
check_digests <- function(ref, mine, what) {
  if (is.null(ref)) return(invisible())
  cat(sprintf("  %s: generated %s, malariasimulation %s, %d replicates\n", what,
              ref$generated, ref$malariasimulation, ref$n_rep))
  if (!identical(ref$malariasimulation, as.character(utils::packageVersion("malariasimulation"))))
    fail <<- c(fail, sprintf("malariasimulation has changed since the %s were made (%s -> %s).",
                             what, ref$malariasimulation, utils::packageVersion("malariasimulation")))
  never <- setdiff(names(mine), names(ref$scenario_digests))
  stale <- setdiff(names(mine)[vapply(names(mine), function(n)
    !identical(unlist(ref$scenario_digests[[n]]), unname(mine[[n]])), logical(1))], never)
  if (length(never))
    fail <<- c(fail, sprintf("%d scenario(s) have no IBM rows (%s): re-run validations/04-parameter-draws/run.R.",
                             length(never), paste(never, collapse = ", ")))
  if (length(stale))
    fail <<- c(fail, sprintf("%d scenario(s) differ from the ones the %s were made from: %s.",
                             length(stale), what, paste(stale, collapse = ", ")))
  if (!length(never) && !length(stale))
    cat(sprintf("    %d of %d scenario digests current\n", length(mine), length(mine)))
}
ref04 <- read_ref(file.path(DDIR, "ibm_reference.json"), "IBM rows at the draws")
ref02 <- read_ref(file.path(D02, "ibm_reference.json"), "IBM rows at the default parameters")
check_digests(ref04, scenario_digests_each(draw_scen), "IBM rows at the draws")
check_digests(ref02, scenario_digests_each()[ref_02], "IBM rows at the default parameters (02-scenarios)")
## The default-parameter rows have to be the scenario fleet's default arm is:
## the same list but for rendering, the same horizon, made the same way
for (i in seq_along(PROFILE_EIR)) {
  a <- SCENARIOS_ALL[[ref_02[i]]]; b <- ref_scen[[i]]
  keys <- union(names(a$p), names(b$p))
  diff_k <- keys[!vapply(keys, function(k) identical(a$p[[k]], b$p[[k]]), logical(1))]
  diff_k <- diff_k[!grepl("_rendering_", diff_k)]
  if (length(diff_k) || !identical(a$eir, b$eir) || !identical(a$years, b$years))
    fail <- c(fail, sprintf("validations/02-scenarios' %s is not the default-parameter scenario at EIR %g (%s).",
                             ref_02[i], PROFILE_EIR[i],
                             paste(c(diff_k, if (!identical(a$years, b$years)) "years"), collapse = ", ")))
}
if (!is.null(ref04) && !is.null(ref02))
  for (k in c("n_rep", "population", "burn_in_years", "malariasimulation"))
    if (!identical(ref04[[k]], ref02[[k]]))
      fail <- c(fail, sprintf("the two suites' IBM rows differ in %s (%s here, %s in 02-scenarios).",
                              k, ref04[[k]], ref02[[k]]))
ref_ok <- !length(fail)

## ---- re-run fleet against the frozen IBM rows -----------------------------------------
rule("Re-running fleet")
new_eq <- do.call(rbind, lapply(run_fleet(c(ref_scen, draw_scen)), `[[`, "eq"))
old <- read.csv(file.path(DDIR, "rep_eq.csv"), stringsAsFactors = FALSE)
o02 <- read.csv(file.path(D02, "rep_eq.csv"), stringsAsFactors = FALSE)

## ---- 1. did anything move? ----------------------------------------------------------
rule("1. Movement against the committed fleet rows")
cmp <- merge(new_eq[, c("scenario", names(MET))], old[old$model == "fleet", c("scenario", names(MET))],
             by = "scenario", suffixes = c(".new", ".old"))
moved <- do.call(rbind, lapply(names(MET), function(m) {
  a <- cmp[[paste0(m, ".new")]]; b <- cmp[[paste0(m, ".old")]]
  rel <- ifelse(abs(b) > 0, abs(a / b - 1), NA_real_)
  k <- which(!is.na(rel) & rel > MOVE_TOL)
  if (length(k)) data.frame(scenario = cmp$scenario[k], outcome = MET[[m]],
                            committed = b[k], now = a[k], rel = rel[k])
}))
unmatched <- setdiff(new_eq$scenario, cmp$scenario)
if (length(unmatched))
  cat(sprintf("  no committed fleet rows for %s\n", paste(unmatched, collapse = ", ")))
if (is.null(moved)) {
  cat(sprintf("  nothing moved: %d committed scenarios reproduce to 1e-6.\n", nrow(cmp)))
} else {
  moved <- moved[order(-moved$rel), ]
  cat(sprintf("  %d of %d values moved; the largest:\n\n", nrow(moved), nrow(cmp) * length(MET)))
  for (i in seq_len(min(nrow(moved), 15))) with(moved[i, ], cat(sprintf(
    "    %-20s %-20s %12.5g %12.5g %+8.2f%%\n", scenario, outcome, committed, now, 100 * rel)))
  cat("\n  If intended, refresh fleet's rows with\n",
      "  CMP_FLEET_ONLY=1 Rscript validations/04-parameter-draws/run.R\n", sep = "")
}
if (STRICT && (!is.null(moved) || length(unmatched)))
  fail <- c(fail, sprintf("%d values moved or uncommitted (CMP_STRICT)",
                          NROW(moved) + length(unmatched)))

## ---- 2. does the claim hold? ---------------------------------------------------------
rule("2. Each draw's change from the default parameters, fleet against the IBM")
ibm <- old[old$model == "IBM", ]
ibm0 <- o02[o02$model == "IBM" & o02$scenario %in% ref_02, ]
n_exp <- c(if (is.null(ref04)) NA else ref04$n_rep, if (is.null(ref02)) NA else ref02$n_rep)
## the IBM arms' log-mean variances, for the standard errors of the mean change
lvar <- function(x) stats::var(x) / (length(x) * mean(x)^2)
cells <- do.call(rbind, lapply(names(draw_scen), function(nm) {
  s <- draw_scen[[nm]]
  g <- ibm[ibm$scenario == nm, ]
  g0 <- ibm0[ibm0$scenario == sprintf("eir_%g", s$eir), ]
  for (x in list(g, g0)) if (anyDuplicated(x$rep)) stop("duplicate IBM replicates in ", nm)
  if ((!is.na(n_exp[1]) && nrow(g) != n_exp[1]) || (!is.na(n_exp[2]) && nrow(g0) != n_exp[2]))
    stop(sprintf("%s has %d IBM replicates at the draw and %d at the default parameters; expected %s",
                 nm, nrow(g), nrow(g0), paste(n_exp, collapse = " and ")), call. = FALSE)
  f <- new_eq[new_eq$scenario == nm, ]
  f0 <- new_eq[new_eq$scenario == draw_scenario_name(0, s$eir), ]
  do.call(rbind, lapply(names(MET), function(m) {
    ## every replicate at the draw over every replicate at the default parameters
    ch <- as.vector(outer(g[[m]], g0[[m]], "/")) - 1
    bc <- replicate_band(ch); fc <- f[[m]] / f0[[m]] - 1
    mc <- mean(g[[m]]) / mean(g0[[m]]) - 1
    se <- (1 + mc) * sqrt(lvar(g[[m]]) + lvar(g0[[m]]))
    bl <- replicate_band(g[[m]]); fl <- f[[m]]
    data.frame(draw = s$draw, eir = s$eir, metric = m, n_ratios = sum(is.finite(ch)),
               ibm_change = bc$centre, ibm_change_lower = bc$lower,
               ibm_change_upper = bc$upper, fleet_change = fc, change_z = band_z(fc, ch),
               change_inside = inside_band(fc, bc$lower, bc$upper),
               ibm_mean_change = mc, ibm_mean_change_se = se, change_z_se = (fc - mc) / se,
               ibm_median = bl$centre, ibm_lower = bl$lower, ibm_upper = bl$upper,
               fleet = fl, level_z = band_z(fl, g[[m]]),
               level_inside = inside_band(fl, bl$lower, bl$upper),
               lv_draw = lvar(g[[m]]), lv_default = lvar(g0[[m]]))
  }))
}))
cells <- merge(draws[, c("draw", "chosen_for", "quantile")], cells, by = "draw")
cells <- cells[order(cells$chosen_for, cells$quantile, cells$eir, match(cells$metric, names(MET))), ]

## Fleet's changes against the IBM's mean changes, outcome by outcome: a
## chi-squared on the log ratios, whose covariance carries the default-parameter
## arm all eight draws at an EIR share, and the error beyond the IBM's noise.
chi2 <- function(x) {
  x <- x[is.finite(x$lv_draw) & is.finite(x$lv_default), ]
  if (!nrow(x)) return(c(chi2 = NA, df = NA, p = NA, excess_rms = NA))
  st <- 0; dd <- c(); vv <- c()
  for (E in unique(x$eir)) {
    y <- x[x$eir == E, ]
    dlt <- log1p(y$fleet_change) - log1p(y$ibm_mean_change)
    S <- diag(y$lv_draw, nrow(y)) + y$lv_default[1]
    st <- st + drop(t(dlt) %*% solve(S, dlt)); dd <- c(dd, dlt); vv <- c(vv, diag(S))
  }
  c(chi2 = st, df = length(dd), p = stats::pchisq(st, length(dd), lower.tail = FALSE),
    excess_rms = 100 * sqrt(max(0, mean(dd^2) - mean(vv))))
}
span <- function(v) if (any(is.finite(v))) range(v, na.rm = TRUE) else c(NA_real_, NA_real_)
gap <- cells$fleet_change - cells$ibm_change
cat(sprintf("    %-20s %13s %9s %7s %7s %8s %9s %9s\n", "outcome", "IBM changes", "max gap",
            "slope", "r", "outside", "chi2/df", "p"))
tests <- list()
for (m in names(MET)) {
  x <- cells[cells$metric == m, ]
  a <- agreement(x$ibm_change, x$fleet_change); r <- span(x$ibm_change); k <- chi2(x)
  tests[[m]] <- k
  cat(sprintf("    %-20s %+5.0f to %+3.0f%% %7.1f pt %7.3f %7.3f %4d of %d %9.2f %9.2g\n", MET[[m]],
              100 * r[1], 100 * r[2], 100 * max(span(abs(gap[cells$metric == m]))),
              a$slope, a$cor, sum(!x$change_inside, na.rm = TRUE), nrow(x),
              k[["chi2"]] / k[["df"]], k[["p"]]))
}
a <- agreement(cells$ibm_change, cells$fleet_change)
where <- function(r) sprintf("%s at draw %d, EIR %g", MET[[r$metric]], r$draw, r$eir)
cat(sprintf("\n  inside at %d of %d cells (%d draws x %d EIRs x %d outcomes)\n",
            sum(cells$change_inside, na.rm = TRUE), nrow(cells), nrow(draws),
            length(PROFILE_EIR), length(MET)))
cat(sprintf("  fleet's changes against the IBM's, all outcomes: slope %.3f, r %.4f\n", a$slope, a$cor))
if (any(is.finite(gap))) {
  w_z <- cells[which.max(abs(cells$change_z)), ]
  w_gap <- cells[which.max(abs(gap)), ]
  cat(sprintf("  largest departure %.2f replicate SD, %s\n", w_z$change_z, where(w_z)))
  cat(sprintf("  largest gap %.1f points (IBM %+.1f%%, fleet %+.1f%%), %s\n",
              100 * (w_gap$fleet_change - w_gap$ibm_change), 100 * w_gap$ibm_change,
              100 * w_gap$fleet_change, where(w_gap)))
  cat(sprintf("  beyond 2 standard errors of the IBM's mean change: %d of %d cells, fleet low in %d\n",
              sum(abs(cells$change_z_se) > 2, na.rm = TRUE), nrow(cells),
              sum(cells$change_z_se < -2, na.rm = TRUE)))
  for (m in names(MET)) if (is.finite(tests[[m]][["p"]]))
    cat(sprintf("    %-20s chi2 %.1f on %d df, p = %.2g; fleet's error beyond the IBM's noise %.1f points RMS\n",
                MET[[m]], tests[[m]][["chi2"]], tests[[m]][["df"]], tests[[m]][["p"]],
                tests[[m]][["excess_rms"]]))
}
out <- cells[!is.na(cells$change_inside) & !cells$change_inside, ]
if (nrow(out)) {
  cat("\n  outside the band:\n")
  for (i in seq_len(nrow(out))) with(out[i, ], cat(sprintf(
    "    draw %4d (%s, q%02.0f)  EIR %-4g %-20s fleet %+6.1f%%, IBM %+6.1f%% (%+.1f%% to %+.1f%%)\n",
    draw, chosen_for, 100 * quantile, eir, MET[[metric]], 100 * fleet_change,
    100 * ibm_change, 100 * ibm_change_lower, 100 * ibm_change_upper)))
  ## a smoke run's band is two ratios wide: a code-path check, not evidence
  m <- sprintf("%d of %d changes outside the IBM replicate band", nrow(out), nrow(cells))
  if (SMOKE) warn <- c(warn, m) else fail <- c(fail, m)
}
## an unscored cell is not a pass (a smoke run's single default replicate
## leaves the band on two ratios, which still scores)
if (anyNA(cells$change_inside)) {
  m <- sprintf("%d of %d cells have no replicate band, so the claim cannot be scored",
               sum(is.na(cells$change_inside)), nrow(cells))
  if (SMOKE) warn <- c(warn, m) else fail <- c(fail, m)
}

## ---- 3. the level at each draw, reported -------------------------------------------
rule("3. The level at each draw (reported, not scored)")
for (m in names(MET)) {
  x <- cells[cells$metric == m, ]
  rel <- span(100 * (x$fleet / x$ibm_median - 1))
  cat(sprintf("    %-20s fleet vs the IBM median %+5.1f%% to %+5.1f%%; outside the band at %d of %d\n",
              MET[[m]], rel[1], rel[2], sum(!x$level_inside, na.rm = TRUE), nrow(x)))
}
if (NROW(refused)) {
  r1 <- refused[!duplicated(refused$draw), ]          # a row per EIR it was refused at
  cat(sprintf("\n  fleet refuses %d of the 1,000 draws on its default age grid: %s (b0 %s)\n",
              nrow(r1), paste(r1$draw, collapse = ", "),
              paste(sprintf("%.3f", r1$b0), collapse = ", ")))
}

## the cells, for render.R and the register -- not over rows the reference has
## disowned
cells$lv_draw <- NULL; cells$lv_default <- NULL
if (ref_ok) {
  write.csv(round_sig(cells, 6), file.path(DDIR, "draws_cells.csv"), row.names = FALSE)
} else {
  cat("\n  results/draws_cells.csv left as it was: the reference checks failed.\n")
}

## ---- verdict -----------------------------------------------------------------------
rule("Verdict")
for (w in warn) cat("  WARNING: ", w, "\n", sep = "")
if (length(fail)) {
  for (f in fail) cat("  FAIL: ", f, "\n", sep = "")
  quit(status = 1)
}
cat("  The claim holds.", if (length(warn)) " (with warnings above)" else "", "\n", sep = "")
