# How much faster is fleet than the IBM per simulated year, and how does that
# depend on transmission, population size and what is deployed?
#
#   Rscript validations/02-scenarios/speed.R                    # a quarter of an hour, one core, idle machine
#   CMP_TABLE_ONLY=1 Rscript validations/02-scenarios/speed.R   # seconds: the table from results/speed.csv
#
# One run of each model per cell of a small factorial: EIR 3, 20 and 120 (the
# levels the shape claims are carried at), the IBM at 10,000, 30,000 and 50,000
# people, and two settings -- nothing deployed and no seasonality, and a
# seasonal programme with case management, bed nets, indoor spraying, SMC and
# RTS,S, all running from the first day. fleet's cost does not depend on the
# population (benchmark.R's population table), so fleet is run once per EIR
# and setting: six fleet cells and eighteen IBM runs, no replicates.
#
# Every run is timed alone, one after another on one core, over ten years from
# set_equilibrium()'s seed, as the whole call a user makes: run_simulation()
# for the IBM, run_simulation_ode() for fleet, which builds its inputs, runs and
# renders its outputs. fleet's figure is the fastest of five repeats, as in
# benchmark.R, because anything else on the machine can only add time and a
# fleet run is cheap enough to repeat. The IBM's is its single run, whose ten
# years already average 3,650 days of work. Both render the EIR grid's output
# bands.
#
# Writes results/speed.csv, its provenance results/speed.json, and the table
# the speed claim shows on the evidence page, vignettes/tab_speed.md.

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
if (requireNamespace("pkgload", quietly = TRUE) &&
    file.exists(file.path(ROOT, "DESCRIPTION"))) {
  suppressMessages(pkgload::load_all(ROOT, quiet = TRUE))
} else {
  suppressMessages(library(fleetcheck))
}
log_msg <- function(...) cat(sprintf("[%s] %s\n", format(Sys.time(), "%H:%M:%S"), sprintf(...)))

## the EIR grid's output bands, set_bands(), and nothing else from it
source(file.path(ROOT, "validations", "_shared", "scenarios.R"))
if (SP != "pf") stop("speed.R times P. falciparum; unset CMP_PARASITE.", call. = FALSE)

DDIR <- fc_results("02-scenarios")
TAB <- file.path(ROOT, "vignettes", "tab_speed.md")
YEARS <- 10L
EIRS <- PROFILE_EIR
POPS <- c(1e4, 3e4, 5e4)
N_REP_FLEET <- 5L
## CMP_SMOKE=1 -> one year, one population, one fleet repeat, into results/smoke/:
## a check that every cell builds and runs, never the claim's table
if (SMOKE) {
  YEARS <- 1L; POPS <- 1e4; N_REP_FLEET <- 1L
  DDIR <- file.path(DDIR, "smoke"); TAB <- file.path(DDIR, "tab_speed.md")
  dir.create(DDIR, showWarnings = FALSE, recursive = TRUE)
}
SETTINGS <- c(none = "nothing deployed, no seasonality",
              programme = "seasonal; case management, bed nets, IRS, SMC and RTS,S")

## ---- the two settings ----------------------------------------------------------------
## The programme runs from the first day, so every timed year carries it:
## AL for 60% of clinical cases; bed nets (80%) and IRS (80%) every three
## years; SMC with SP-AQ, four monthly rounds a year to 3 months-5 years at 90%;
## RTS,S through EPI at 5 months, 90%, with a booster.
programme <- function(p) {
  n <- ceiling(YEARS / 3); ts <- 1 + (seq_len(n) - 1) * 3 * 365
  m <- function(v) matrix(v, nrow = n, ncol = 1)
  p <- set_drugs(p, list(AL_params, SP_AQ_params))
  p <- set_clinical_treatment(p, drug = 1, timesteps = 1, coverages = 0.6)
  p <- set_bednets(p, timesteps = ts, coverages = rep(0.8, n), retention = 5 * 365,
                   dn0 = matrix(0.387, n), rn = matrix(0.563, n), rnm = matrix(0.24, n),
                   gamman = rep(2.64 * 365, n))
  p <- set_spraying(p, timesteps = ts, coverages = rep(0.8, n),
                    ls_theta = m(2.025), ls_gamma = m(-0.009), ks_theta = m(-2.222),
                    ks_gamma = m(0.008), ms_theta = m(-1.232), ms_gamma = m(-0.009))
  rounds <- as.vector(sapply(seq_len(YEARS) - 1L, function(y) y * 365 + 200 + c(0, 30, 60, 90)))
  p <- set_smc(p, drug = 2, timesteps = rounds, coverages = rep(0.9, length(rounds)),
               min_ages = rep(round(0.25 * 365), length(rounds)),
               max_ages = rep(round(5 * 365), length(rounds)))
  set_pev_epi(p, profile = rtss_profile, timesteps = 1, coverages = 0.9, min_wait = 0,
              age = 5 * 30, booster_spacing = 12 * 30, booster_coverage = matrix(0.8),
              booster_profile = list(rtss_booster_profile))
}
build <- function(setting, E, pop) {
  ov <- list(human_population = pop)
  if (setting == "programme") ov <- c(ov, list(model_seasonality = TRUE), SEASON)
  p <- set_bands(get_parameters(ov))
  if (setting == "programme") p <- programme(p)
  set_equilibrium(p, init_EIR = E)
}

## ---- timing ------------------------------------------------------------------------
## Each cell is timed twice: over one day, which is the start-up -- fleet
## building its inputs and seeding, the IBM creating its people -- and over the
## full horizon. The per-year cost is the difference over the years between
## them, so the table reads the same whatever horizon a user runs; the
## start-ups are in results/speed.csv and the table's caption.
time_fleet <- function(p, days) min(vapply(seq_len(N_REP_FLEET), function(k) {
  gc(verbose = FALSE)
  system.time(invisible(fleet::run_simulation_ode(timesteps = days, parameters = p)))[["elapsed"]]
}, numeric(1)))
time_ibm <- function(p, days) {
  gc(verbose = FALSE); set.seed(1000L)
  system.time(invisible(run_simulation(timesteps = days, parameters = p)))[["elapsed"]]
}

## the processor's marketed name, which is what a reader can compare with theirs
cpu_name <- function() {
  try1 <- function(expr) tryCatch(trimws(expr), error = function(e) "", warning = function(w) "")
  nm <- switch(Sys.info()[["sysname"]],
    Windows = try1(system2("powershell", c("-NoProfile", "-Command",
                                           shQuote("(Get-CimInstance Win32_Processor).Name")),
                           stdout = TRUE, stderr = FALSE)[1]),
    Darwin = try1(system2("sysctl", c("-n", "machdep.cpu.brand_string"), stdout = TRUE)[1]),
    Linux = try1(sub(".*: ", "", grep("^model name", readLines("/proc/cpuinfo"), value = TRUE)[1])),
    "")
  if (is.na(nm) || !nzchar(nm)) Sys.getenv("PROCESSOR_IDENTIFIER", Sys.info()[["machine"]]) else
    gsub("\\((R|TM)\\)", "", nm)
}

## CMP_TABLE_ONLY=1 -> no timing: the table from the committed results/speed.csv
if (nzchar(Sys.getenv("CMP_TABLE_ONLY"))) {
  speed <- read.csv(file.path(DDIR, "speed.csv"), stringsAsFactors = FALSE)
  cpu <- jsonlite::read_json(file.path(DDIR, "speed.json"))$cpu
  YEARS <- unique(speed$years); POPS <- sort(unique(speed$pop[!is.na(speed$pop)]))
} else {
rows <- list()
for (s in names(SETTINGS)) for (E in EIRS) {
  p <- build(s, E, POPS[1])
  t0 <- time_fleet(p, 1L); t1 <- time_fleet(p, YEARS * 365)
  rows[[length(rows) + 1L]] <- data.frame(setting = s, eir = E, model = "fleet", pop = NA,
                                          years = YEARS, start_s = t0, total_s = t1)
  log_msg("fleet  %-9s EIR %-4g            start %5.2f s, %2d years %7.2f s", s, E, t0, YEARS, t1)
  for (n in POPS) {
    p <- build(s, E, n)
    t0 <- time_ibm(p, 1L); t1 <- time_ibm(p, YEARS * 365)
    rows[[length(rows) + 1L]] <- data.frame(setting = s, eir = E, model = "IBM", pop = n,
                                            years = YEARS, start_s = t0, total_s = t1)
    log_msg("IBM    %-9s EIR %-4g pop %6d start %5.2f s, %2d years %7.1f s", s, E, n, t0, YEARS, t1)
  }
}
speed <- do.call(rbind, rows)
speed$s_per_year <- (speed$total_s - speed$start_s) / (speed$years - 1 / 365)
fl <- speed[speed$model == "fleet", c("setting", "eir", "s_per_year")]
speed <- merge(speed, setNames(fl, c("setting", "eir", "fleet_s_per_year")), by = c("setting", "eir"))
speed$speedup <- ifelse(speed$model == "IBM", speed$s_per_year / speed$fleet_s_per_year, NA)
speed <- speed[order(match(speed$setting, names(SETTINGS)), speed$eir, speed$model != "fleet", speed$pop),
               c("setting", "eir", "model", "pop", "years", "start_s", "total_s", "s_per_year",
                 "speedup")]
write.csv(round_sig(speed, 4), file.path(DDIR, "speed.csv"), row.names = FALSE)
cpu <- cpu_name()
jsonlite::write_json(stamp(years = YEARS, eir = EIRS, populations = POPS,
                           fleet_repeats = N_REP_FLEET, cpu = cpu,
                           cores = parallel::detectCores(), settings = as.list(SETTINGS)),
                     file.path(DDIR, "speed.json"), auto_unbox = TRUE, pretty = TRUE)
}

## ---- the table the speed claim shows --------------------------------------------------
## seconds per simulated year, and each IBM cell's multiple of fleet's
fmt_s <- function(x) ifelse(x < 0.1, sprintf("%.3f s", x), ifelse(x < 10, sprintf("%.2f s", x), sprintf("%.1f s", x)))
fmt_x <- function(x) sprintf("%s×", formatC(round(x), big.mark = ",", format = "d"))
tab <- do.call(rbind, lapply(split(speed, list(speed$setting, speed$eir), drop = TRUE), function(d) {
  f <- d[d$model == "fleet", ]; i <- d[d$model == "IBM", ]; i <- i[order(i$pop), ]
  data.frame(setting = f$setting, eir = f$eir, fleet = fmt_s(f$s_per_year),
             t(setNames(sprintf("%s (%s)", fmt_s(i$s_per_year), fmt_x(i$speedup)),
                        sprintf("IBM, %s people", formatC(i$pop, big.mark = ",", format = "d")))),
             check.names = FALSE, stringsAsFactors = FALSE)
}))
tab <- tab[order(match(tab$setting, names(SETTINGS)), tab$eir), ]
tab$setting <- ifelse(duplicated(tab$setting), "", c(none = "nothing deployed",
                                                     programme = "seasonal programme")[tab$setting])
names(tab)[1:2] <- c("setting", "EIR")
## two significant figures, trailing zero kept: 3.0 to 3.6 s
rng <- function(x) {
  f <- function(v) formatC(signif(v, 2), digits = 2, format = "fg", flag = "#")
  a <- f(min(x)); b <- f(max(x))
  if (a == b) paste(a, "s") else paste(a, "to", b, "s")
}
people <- function(n) formatC(n, big.mark = ",", format = "d")
ibm_start <- if (length(POPS) > 1)
  sprintf("the IBM's %s at %s people and %s at %s",
          rng(speed$start_s[speed$model == "IBM" & speed$pop == min(POPS)]), people(min(POPS)),
          rng(speed$start_s[speed$model == "IBM" & speed$pop == max(POPS)]), people(max(POPS))) else
  sprintf("the IBM's %s at %s people",
          rng(speed$start_s[speed$model == "IBM"]), people(POPS))
md <- c(sprintf(paste("Seconds per simulated year, one run of each model alone on one core (%s),",
                      "over %d years from set_equilibrium()'s seed, start-up excluded: fleet's takes",
                      "%s, %s. In brackets, the IBM's multiple of fleet's time; fleet's cost does not",
                      "depend on the population. The seasonal programme is case management, bed nets,",
                      "indoor spraying, SMC and RTS,S, running from the first day.",
                      "`validations/02-scenarios/speed.R` makes this table."),
                cpu, YEARS, rng(speed$start_s[speed$model == "fleet"]), ibm_start),
        "",
        paste0("| ", paste(names(tab), collapse = " | "), " |"),
        paste0("|", paste(c(":--", "--:", rep("--:", ncol(tab) - 2)), collapse = "|"), "|"),
        apply(tab, 1, function(r) paste0("| ", paste(r, collapse = " | "), " |")))
writeLines(md, TAB, useBytes = TRUE)
cat(md, sep = "\n")
