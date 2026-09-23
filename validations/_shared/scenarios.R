# Scenario definitions and the shared per-run summariser.
#
# Sourced by BOTH run_replicates.R (which runs them through both models and
# writes the CSVs) and check_drift.R (which re-runs fleet only and compares
# against the committed reference). They live here so a drift check cannot
# silently test a different set of scenarios from the one the reference was
# built on -- and so sourcing the scenarios does not start a 25-minute run.
#
# Expects ROOT and theme.R's constants to be in scope already.

SMOKE <- nzchar(Sys.getenv("CMP_SMOKE"))

## ---- which parasite ------------------------------------------------------------
## CMP_PARASITE=pv selects the P. vivax suite: its own scenario file, its own
## summary columns, results in results/pv/. Everything else -- replicates,
## bands, digests, the summariser's pooling -- is shared, so the two suites
## cannot drift apart in how they are measured.
SP <- Sys.getenv("CMP_PARASITE", "pf")
if (!SP %in% c("pf", "pv"))
  stop("CMP_PARASITE must be 'pf' or 'pv', not '", SP, "'.", call. = FALSE)
PARASITE <- c(pf = "falciparum", pv = "vivax")[[SP]]

## ---- shared parameter scaffolding -------------------------------------------
band_lo <- head(AGE_EDGES, -1) * 365; band_hi <- tail(AGE_EDGES, -1) * 365
tag_of  <- function(lo, hi) paste0(round(lo), "_", round(hi))
AGE_TAGS <- tag_of(band_lo, band_hi)

## rendering ranges: every scenario gets the three defaults (LM prevalence 2-10y,
## clinical and severe incidence 0-5y); the reference scenario adds the
## age-profile bands to all three families. Vivax has no severe disease, and
## malariasimulation renders none for it, so a vivax list gets no severe bands.
set_bands <- function(p, age_profile = FALSE) {
  add <- function(lo, hi) if (age_profile) list(c(band_lo, lo), c(band_hi, hi)) else list(lo, hi)
  r <- add(730, 3650)
  p$prevalence_rendering_min_ages <- r[[1]]; p$prevalence_rendering_max_ages <- r[[2]]
  ## both incidence families over under-5 AND all ages: the impact figure reports
  ## the burden a programme actually carries as well as the young-child burden
  r <- add(c(0, 0), c(1825, 36500))
  p$clinical_incidence_rendering_min_ages <- r[[1]]; p$clinical_incidence_rendering_max_ages <- r[[2]]
  if (p$parasite != "vivax") {
    p$severe_incidence_rendering_min_ages <- r[[1]]; p$severe_incidence_rendering_max_ages <- r[[2]]
  }
  p
}

## ---- scenarios, one file per parasite -------------------------------------------
## Each defines base_params() and fills `scenarios`, a list of
## list(p = parameters, eir = init_EIR, years = horizon).
## Two literal source() calls rather than one built from SP, so that the static
## check in tests/testthat/test-validations.R can see which files this includes.
scenarios <- list()
if (SP == "pf") {
  source(file.path(ROOT, "validations", "_shared", "scenarios_pf.R"), local = TRUE)
} else {
  source(file.path(ROOT, "validations", "_shared", "scenarios_pv.R"), local = TRUE)
}

## CMP_ONLY=a,b -> run just those scenarios and merge their rows into the existing CSVs
ONLY <- Filter(nzchar, strsplit(Sys.getenv("CMP_ONLY"), ",")[[1]])
## the digest must describe the WHOLE scenario set, not whichever subset this
## invocation happens to run -- otherwise every CMP_ONLY run reports the
## reference as stale when nothing has changed
SCENARIOS_ALL <- scenarios
if (length(ONLY)) { stopifnot(all(ONLY %in% names(scenarios))); scenarios <- scenarios[ONLY] }

if (SMOKE) scenarios <- lapply(scenarios, function(s) { s$years <- 4L; s })

## ---- one summariser for BOTH models ------------------------------------------
## Takes a wide daily output table and returns compact tidy pieces. The ODE table
## carries a day-0 seed row the IBM lacks; callers drop it first so both bin on
## days 1..N and monthly bins align. The age profile is only returned when the
## table carries the age-profile bands (the reference scenario).
summarise_run <- function(df, years, tags = AGE_TAGS) {
  if (SP == "pv") return(summarise_run_pv(df, years, tags))
  n <- nrow(df); day <- seq_len(n)
  pooled <- function(num, den, rows) sum(num[rows]) / sum(den[rows])
  rate   <- function(kind, tag, rows, per = 365)
    pooled(df[[paste0("n_inc_", kind, "_", tag)]], df[[paste0("n_age_", tag)]], rows) * per
  prev   <- function(tag, rows) pooled(df[[paste0("n_detect_lm_", tag)]], df[[paste0("n_age_", tag)]], rows)
  obs <- (n - 3 * 365 + 1):n                    # final three years
  ## equilibrium quantities over the observation window
  eq <- data.frame(
    pfpr_2_10 = prev("730_3650", obs), clin_0_5 = rate("clinical", "0_1825", obs),
    sev_0_5 = rate("severe", "0_1825", obs, 365 * 1000),
    clin_all = rate("clinical", "0_36500", obs),
    sev_all = rate("severe", "0_36500", obs, 365 * 1000))
  ## age profiles over the observation window (reference scenario only)
  age <- if (all(paste0("n_detect_lm_", tags) %in% names(df))) {
    n_band <- vapply(tags, function(tg) sum(df[[paste0("n_age_", tg)]][obs]), numeric(1))
    data.frame(
      age_lo = band_lo / 365, age_hi = band_hi / 365, age_mid = (band_lo + band_hi) / 2 / 365,
      pop_frac = n_band / sum(n_band),            # share of the 0-85 population in each band
      prev = vapply(tags, prev, numeric(1), rows = obs),
      clin = vapply(tags, rate, numeric(1), kind = "clinical", rows = obs),
      sev  = vapply(tags, rate, numeric(1), kind = "severe", rows = obs, per = 365 * 1000))
  }
  ## monthly series (30-day bins), pooled within each bin; `year` = bin start
  mon <- (day - 1) %/% 30
  mo <- function(f) as.numeric(tapply(day, mon, f))
  monthly <- data.frame(
    year = as.numeric(names(tapply(day, mon, length))) * 30 / 365,
    pfpr_2_10 = mo(function(ix) prev("730_3650", ix)),
    clin_0_5  = mo(function(ix) rate("clinical", "0_1825", ix)),
    sev_0_5   = mo(function(ix) rate("severe", "0_1825", ix, 365 * 1000)),
    clin_all  = mo(function(ix) rate("clinical", "0_36500", ix)),
    sev_all   = mo(function(ix) rate("severe", "0_36500", ix, 365 * 1000)))
  ## final-year day-of-year series (for the seasonal cycle), 7-day pooled bins
  fy <- (n - 365 + 1):n; wk <- (seq_along(fy) - 1) %/% 7
  doy <- data.frame(
    doy = as.numeric(tapply(seq_along(fy), wk, function(ix) mean(ix))),
    pfpr_2_10 = as.numeric(tapply(seq_along(fy), wk, function(ix) prev("730_3650", fy[ix]))),
    clin_0_5  = as.numeric(tapply(seq_along(fy), wk, function(ix) rate("clinical", "0_1825", fy[ix]))))
  ## realised EIR (IBM emits EIR_<species> as total bites; fleet emits per-adult-per-year)
  eir <- if (any(grepl("^EIR_", names(df)))) {
    ec <- grep("^EIR_", names(df), value = TRUE)
    sum(rowSums(df[obs, ec, drop = FALSE])) / length(obs) / POP * 365
  } else mean(df$EIR[obs])
  eq$eir_realised <- eir
  list(eq = eq, age = age, monthly = monthly, doy = doy)
}
## The vivax summary: the same pooling, windows and bins, over vivax's outputs.
## pvpr_2_10 is LM prevalence (vivax A is LM-detectable by definition, so this is
## D + Tr + A), pcr_2_10 adds U -- the sub-patent reservoir relapse keeps full --
## and the two vivax-only rates are all-age relapse incidence and the share
## carrying hypnozoites. No severe: malariasimulation has no vivax severe disease.
summarise_run_pv <- function(df, years, tags = AGE_TAGS) {
  n <- nrow(df); day <- seq_len(n)
  pooled <- function(num, den, rows) sum(num[rows]) / sum(den[rows])
  rate   <- function(tag, rows, per = 365)
    pooled(df[[paste0("n_inc_clinical_", tag)]], df[[paste0("n_age_", tag)]], rows) * per
  prev   <- function(tag, rows, kind = "lm")
    pooled(df[[paste0("n_detect_", kind, "_", tag)]], df[[paste0("n_age_", tag)]], rows)
  allage <- function(col, rows, per = 1) pooled(df[[col]], df$n_age_0_36500, rows) * per
  obs <- (n - 3 * 365 + 1):n                    # final three years
  eq <- data.frame(
    pvpr_2_10 = prev("730_3650", obs), pcr_2_10 = prev("730_3650", obs, "pcr"),
    clin_0_5 = rate("0_1825", obs), clin_all = rate("0_36500", obs),
    relapse_all = allage("n_relapses", obs, 365), hyp_all = allage("n_with_hypnozoites", obs))
  age <- if (all(paste0("n_detect_lm_", tags) %in% names(df))) {
    n_band <- vapply(tags, function(tg) sum(df[[paste0("n_age_", tg)]][obs]), numeric(1))
    data.frame(
      age_lo = band_lo / 365, age_hi = band_hi / 365, age_mid = (band_lo + band_hi) / 2 / 365,
      pop_frac = n_band / sum(n_band),
      prev = vapply(tags, prev, numeric(1), rows = obs),
      clin = vapply(tags, rate, numeric(1), rows = obs))
  }
  mon <- (day - 1) %/% 30
  mo <- function(f) as.numeric(tapply(day, mon, f))
  monthly <- data.frame(
    year = as.numeric(names(tapply(day, mon, length))) * 30 / 365,
    pvpr_2_10   = mo(function(ix) prev("730_3650", ix)),
    clin_0_5    = mo(function(ix) rate("0_1825", ix)),
    clin_all    = mo(function(ix) rate("0_36500", ix)),
    relapse_all = mo(function(ix) allage("n_relapses", ix, 365)))
  fy <- (n - 365 + 1):n; wk <- (seq_along(fy) - 1) %/% 7
  doy <- data.frame(
    doy = as.numeric(tapply(seq_along(fy), wk, function(ix) mean(ix))),
    pvpr_2_10 = as.numeric(tapply(seq_along(fy), wk, function(ix) prev("730_3650", fy[ix]))),
    clin_0_5  = as.numeric(tapply(seq_along(fy), wk, function(ix) rate("0_1825", fy[ix]))))
  eir <- if (any(grepl("^EIR_", names(df)))) {
    ec <- grep("^EIR_", names(df), value = TRUE)
    sum(rowSums(df[obs, ec, drop = FALSE])) / length(obs) / POP * 365
  } else mean(df$EIR[obs])
  eq$eir_realised <- eir
  list(eq = eq, age = age, monthly = monthly, doy = doy)
}

tag_parts <- function(r, nm, model, rep)
  lapply(r, function(x) if (is.null(x)) NULL else cbind(scenario = nm, model = model, rep = rep, x))

## ---- provenance ---------------------------------------------------------------
## A hash of what the IBM was actually run on. The committed IBM rows stay valid
## for any fleet-side change -- the IBM does not depend on fleet -- but they go
## stale the moment a scenario definition or malariasimulation itself changes.
## Without this there is no way to notice that, and a drift check would keep
## comparing against a reference built for different scenarios.
##
## Hashes the fields that actually reach the IBM: every parameter that differs
## from a bare get_parameters(), plus the EIR and horizon. Deliberately not the
## whole list, which carries defaults that shift between malariasimulation
## versions for reasons unrelated to these scenarios.
##
## Hashes TEXT, with serialize = FALSE, and that is the point. digest()'s default
## path serialises the object first, so the hash depends on R's binary
## serialisation format -- which varies with R version, platform and digest's own
## dynamic serializeVersion default, none of which say anything about whether a
## scenario changed. That made the digest a fingerprint of the machine rather than
## of the scenarios: it matched only on the machine that stamped the reference, so
## the check could never pass in CI (R 4.6.1 there against 4.5.2 here was enough).
## deparse() of the declared values is stable across both.
## Canonical text for ONE scenario: every parameter that differs from a bare
## get_parameters(), plus the EIR and horizon, as "key=value" lines.
.scen_lines <- function(s, base) {
  ## Round doubles before hashing. Every scenario is built through
  ## set_equilibrium(), which stores the output of a NUMERICAL equilibrium solve:
  ## total_M is 118499.32693250103 and init_foim 0.0078964152242594334 for eir_20,
  ## seventeen significant digits of it. Cross-platform floating point is not
  ## bit-identical, so those last digits differ between this machine and a Linux
  ## runner and the hash moved with them, reporting "the scenario definitions have
  ## changed" when nothing had. 12 significant digits is far tighter than any
  ## change worth catching and far looser than the noise. Recursive, because the
  ## values are nested (eq_params is a list of 56).
  rnd <- function(x) {
    if (is.list(x)) return(lapply(x, rnd))
    if (is.double(x)) return(signif(x, 12))
    x
  }
  ## explicit width.cutoff and control so a future change to deparse()'s defaults
  ## cannot silently move the hash
  dep <- function(x) paste(deparse(rnd(x), width.cutoff = 500L,
                                   control = c("keepNA", "keepInteger",
                                               "niceNames", "showAttributes")),
                           collapse = " ")
  changed <- Filter(function(k) !identical(s$p[[k]], base[[k]]), names(s$p))
  c(paste0("eir=", dep(s$eir)), paste0("years=", dep(s$years)),
    vapply(sort(changed), function(k) paste0(k, "=", dep(s$p[[k]])), character(1)))
}

.txt_digest <- function(x) digest::digest(paste(x, collapse = "\n"),
                                          algo = "xxhash64", serialize = FALSE)

scenario_digest <- function(scen = SCENARIOS_ALL) {
  base <- get_parameters(parasite = PARASITE)
  nm <- sort(names(scen))
  .txt_digest(unlist(lapply(nm, function(n) c(paste0("[", n, "]"),
                                              .scen_lines(scen[[n]], base)))))
}

## Per-scenario and per-key digests. Committed alongside the aggregate so that a
## mismatch says WHICH scenario, and then which parameter, rather than only that
## something moved. That matters because the aggregate is the thing CI compares,
## and an aggregate mismatch with no breakdown is not actionable.
scenario_digests_each <- function(scen = SCENARIOS_ALL) {
  base <- get_parameters(parasite = PARASITE)
  nm <- sort(names(scen))
  stats::setNames(vapply(nm, function(n) .txt_digest(.scen_lines(scen[[n]], base)),
                         character(1)), nm)
}

scenario_key_digests <- function(s, base = get_parameters(parasite = PARASITE)) {
  ln <- .scen_lines(s, base)
  stats::setNames(vapply(ln, .txt_digest, character(1)), sub("=.*$", "", ln))
}


ibm_reference <- function() list(
  generated = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
  malariasimulation = as.character(utils::packageVersion("malariasimulation")),
  R = paste0(R.version$major, ".", R.version$minor),
  n_rep = N_REP, population = POP, burn_in_years = BURN_Y,
  scenarios = sort(names(SCENARIOS_ALL)), scenario_digest = scenario_digest(),
  scenario_digests = as.list(scenario_digests_each()))

## ---- running fleet -------------------------------------------------------------
## Shared so a drift check cannot accidentally run fleet differently from the way
## the committed reference was produced: same tuning, same horizons, same
## summariser, same day-0 row dropped.
## `workers` > 1 runs the scenarios on a PSOCK pool: a vivax scenario costs
## minutes rather than seconds, and the whole vivax set would take the best part
## of an hour one at a time.
run_fleet <- function(scen = scenarios, workers = 1L) {
  suppressMessages(library(fleet))
  log_msg("fleet: %d scenarios%s", length(scen),
          if (workers > 1L) sprintf(" on %d workers", workers) else "")
  one <- function(nm) {
    s <- scen[[nm]]
    el <- system.time(
      ## s$p already carries init_EIR: every scenario is built through
      ## set_equilibrium(), which is where fleet reads the target EIR from now.
      o <- fleet::run_simulation_ode(timesteps = s$years * 365, parameters = s$p,
                                     tuning = list(rtol = 1e-6, step_size_max = 10))
    )[["elapsed"]]
    r <- summarise_run(o[-1, ], s$years)          # drop the day-0 seed row
    r$timing <- data.frame(years = s$years, elapsed_s = el)
    tag_parts(r, nm, "fleet", 0L)
  }
  if (workers > 1L) {
    cl <- parallel::makeCluster(workers)
    on.exit(parallel::stopCluster(cl), add = TRUE)
    .libs <- .libPaths()
    parallel::clusterExport(cl, c("scen", "summarise_run", "summarise_run_pv", "tag_parts",
                                  "band_lo", "band_hi", "AGE_TAGS", "POP", "SP", ".libs"),
                            envir = environment())
    invisible(parallel::clusterEvalQ(cl, .libPaths(.libs)))
    ## longest first, so the pool is not left waiting on one long run at the end
    ord <- names(scen)[order(-vapply(scen, `[[`, numeric(1), "years"))]
    out <- parallel::parLapplyLB(cl, ord, one, chunk.size = 1L)
    names(out) <- ord
    out <- out[names(scen)]
  } else {
    out <- lapply(names(scen), one)
  }
  names(out) <- names(scen)
  log_msg("fleet done: %.1f s total", sum(vapply(out, function(o) o$timing$elapsed_s, numeric(1))))
  out
}
