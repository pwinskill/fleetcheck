## Tier 3 shared code: turning one malariaverse site file into a monthly
## fleet-vs-IBM comparison. Sourced by run.R, by assess.R and by each callr
## worker, which inherits nothing.
##
## Expects ROOT to be set by the caller.

`%||%` <- function(x, y) if (is.null(x)) y else x

suppressMessages({
  library(dplyr)
})

## ---- where the site files are -------------------------------------------------
## Not in this repository and not redistributable. FLEET_VALIDATE points at the
## directory holding sites/<ISO>.RDS and calibration_epi_output/<ISO>_diagnostic_epi.rds.
site_dir <- function() {
  d <- Sys.getenv("FLEET_VALIDATE")
  if (!nzchar(d))
    stop("FLEET_VALIDATE is not set. Tier 3 needs the malariaverse site files, which ",
         "are not in this repository and are not redistributable. Point it at the ",
         "directory holding sites/ and calibration_epi_output/:\n",
         "  FLEET_VALIDATE=/path/to/site-files Rscript validations/03-real-settings/run.R\n",
         "Without them, validations/03-real-settings/example-one-site.R shows the ",
         "method on a single sub-site.", call. = FALSE)
  d <- normalizePath(d, "/", mustWork = FALSE)
  for (sub in c("sites", "calibration_epi_output"))
    if (!dir.exists(file.path(d, sub)))
      stop("FLEET_VALIDATE=", d, " has no ", sub, "/ directory.", call. = FALSE)
  d
}

## ---- which parasite ------------------------------------------------------------
## CMP_PARASITE=pv runs the P. vivax arm: the site files' pv sub-sites and EIR, a
## vivax parameter list, and the pv rows of the shipped diagnostic. Everything
## else -- the sub-site loop, postie's buckets, the statistics -- is shared. Its
## results go to results/pv/, so the falciparum statistics are never touched.
tier3_sp <- function() {
  sp <- Sys.getenv("CMP_PARASITE", "pf")
  if (!sp %in% c("pf", "pv"))
    stop("CMP_PARASITE must be 'pf' or 'pv', not '", sp, "'.", call. = FALSE)
  sp
}
SP <- tier3_sp()
PARASITE <- c(pf = "falciparum", pv = "vivax")[[SP]]
tier3_results <- function(...) {
  if (SP == "pf") fc_results("03-real-settings", ...) else fc_results("03-real-settings", "pv", ...)
}

## Countries with BOTH a site file and a pre-run IBM diagnostic, and at least one
## sub-site of this parasite. A site file with no diagnostic has nothing to
## compare against, and silently running fleet over it would cost minutes and
## produce nothing; nor would a country with no transmission of this species.
site_isos <- function() {
  d <- site_dir()
  s <- sub("[.]RDS$", "", basename(Sys.glob(file.path(d, "sites", "*.RDS"))))
  i <- sub("_diagnostic_epi[.]rds$", "",
           basename(Sys.glob(file.path(d, "calibration_epi_output", "*_diagnostic_epi.rds"))))
  iso <- sort(intersect(s, i))
  has_sp <- vapply(iso, function(x) {
    e <- readRDS(file.path(d, "sites", paste0(x, ".RDS")))$eir
    any(e$sp == SP & e$eir > 0, na.rm = TRUE)
  }, logical(1))
  iso[has_sp]
}

load_fleet <- function() {
  if (nzchar(src <- Sys.getenv("FLEET_SRC"))) {
    suppressMessages(pkgload::load_all(src, quiet = TRUE))
  } else {
    suppressMessages(library(fleet))
  }
  invisible(TRUE)
}

## The site file records nets USED; the model wants nets HANDED OUT.
.munge_itn <- function(s1) {
  s1$interventions$itn$implementation$itn_input_dist <- site::site_usage_to_model_distribution(
    usage = s1$interventions$itn$use$itn_use,
    usage_year = s1$interventions$itn$use$year,
    usage_day_of_year = s1$interventions$itn$use$usage_day_of_year,
    distribution_year = s1$interventions$itn$implementation$year,
    distribution_day_of_year = s1$interventions$itn$implementation$distribution_day_of_year,
    distribution_lower = s1$interventions$itn$implementation$distribution_lower,
    distribution_upper = s1$interventions$itn$implementation$distribution_upper,
    net_loss_function = netz::net_loss_map,
    half_life = s1$interventions$itn$retention_half_life)
  s1
}

## site_parameters() builds the vivax list itself: its drugs padded to vivax's
## seven parameters with no radical cure, and SMC, PMC and vaccines left out,
## which malariasimulation cannot run under vivax either.
build_params <- function(s1) {
  s1 <- .munge_itn(s1)
  site::site_parameters(
    s1$interventions, s1$demography, s1$vectors, s1$seasonality,
    parasite = PARASITE, eir = s1$eir$eir[s1$eir$sp == SP],
    start_year = 2000, end_year = 2026,
    overrides = list(human_population = 1000))
}

## postie::get_rates() wants a severe column beside every clinical one. A vivax
## table has none -- malariasimulation renders no severe disease for vivax, and
## fleet renders what the IBM does -- so under vivax they are added here, as 0,
## on the clinical bands. A falciparum table is returned as it is.
with_zero_severe <- function(o) {
  if (SP != "pv") return(o)
  for (cl in grep("^n_inc_clinical_", names(o), value = TRUE)) {
    tag <- sub("^n_inc_clinical_", "", cl)
    o[[paste0("n_inc_severe_", tag)]] <- 0
    o[[paste0("p_inc_severe_", tag)]] <- 0
  }
  o
}

## One sub-site -> monthly all-age clinical and severe, per person per year, or
## NULL if it has no usable EIR for this parasite or fleet cannot solve it.
## Severe is identically 0 under vivax, on both arms.
##
## postie::get_rates() is used on both arms, so fleet's year/month buckets align
## with the IBM diagnostic (also postie-derived) and the person-day weighting
## over age bands gives all-age rates the same way on both sides.
fleet_monthly_subsite <- function(s1) {
  E <- s1$eir$eir[s1$eir$sp == SP]
  if (length(E) != 1 || is.na(E) || E <= 0) return(NULL)
  p <- suppressWarnings(build_params(s1))
  p <- suppressWarnings(malariasimulation::set_equilibrium(p, init_EIR = E))
  ## At fleet's default settings. A sub-site that errors is given up on rather
  ## than failing the country -- and a dropped sub-site is SELECTION, not a
  ## nuisance: the low-EIR fringe is where fleet departs most from the IBM, so
  ## dropping silently would bias every statistic toward agreement. run_country()
  ## counts the attempts and the returns so assess.R reports the difference.
  o <- suppressWarnings(tryCatch(
    fleet::run_simulation_ode(timesteps = p$timesteps, parameters = p),
    error = function(e) NULL))
  if (is.null(o)) return(NULL)
  suppressWarnings(postie::get_rates(with_zero_severe(o))) |>
    group_by(year, month) |>
    summarise(fleet_clinical = weighted.mean(clinical, person_days) * 365,
              fleet_severe   = weighted.mean(severe,   person_days) * 365, .groups = "drop") |>
    mutate(iso3c = s1$sites$iso3c, name_1 = s1$sites$name_1,
           urban_rural = s1$sites$urban_rural)
}

## The IBM arm: pre-run, shipped with the site files, never recomputed here.
##
## FILTER TO ONE PARASITE FIRST. The diagnostics carry both P. falciparum and
## P. vivax rows, and summing over both inflates the baseline with the other
## species: vivax's flatter seasonality, negligible where pf transmission is
## high and dominant at low pf EIR, was once the cause of an apparent fleet
## seasonal-amplitude mismatch at low-transmission sites. Each arm compares one
## species on both sides.
ibm_monthly <- function(iso) {
  readRDS(file.path(site_dir(), "calibration_epi_output",
                    paste0(iso, "_diagnostic_epi.rds"))) |>
    filter(sp == SP) |>
    group_by(iso3c, name_1, urban_rural, year, month) |>
    summarise(ms_clinical  = weighted.mean(clinical,  person_days) * 365,
              ms_severe    = weighted.mean(severe,    person_days) * 365,
              ms_mortality = weighted.mean(mortality, person_days) * 365,
              .groups = "drop")
}

## Vivax sub-sites per country, at most. Each country is represented by up to
## this many, chosen evenly across its vivax EIR range -- its lowest and highest
## always among them -- so the sample spans the transmission the claim is about
## rather than whichever sub-sites happen to come first. Falciparum is uncapped.
TIER3_MAX_SUBSITES_PV <- 10L

## The sub-sites of one country this arm runs: those with an EIR for this
## parasite (a sub-site with none has none of this species to model, so it is
## not attempted and does not count as one fleet dropped), capped under vivax.
tier3_subsites <- function(sf) {
  keys <- c("country", "iso3c", "name_1", "urban_rural")
  e <- sf$eir[sf$eir$sp == SP & !is.na(sf$eir$eir) & sf$eir$eir > 0, ]
  if (SP == "pv" && nrow(e) > TIER3_MAX_SUBSITES_PV) {
    e <- e[order(e$eir), ]
    e <- e[unique(round(seq(1, nrow(e), length.out = TIER3_MAX_SUBSITES_PV))), ]
  }
  as.data.frame(e[, keys])
}

## One country -> the joined monthly comparison over its sub-sites of this
## parasite. NULL if every sub-site fleet was asked for failed; NA if the
## country has no sub-site of this parasite at all, which is outside the
## comparison rather than a failure (the site files include countries with only
## one of the two).
run_country <- function(iso) {
  load_fleet()
  sf <- readRDS(file.path(site_dir(), "sites", paste0(iso, ".RDS")))
  todo <- tier3_subsites(sf)
  mo <- list(); attempted <- 0L
  for (i in seq_len(nrow(todo))) {
    s1 <- tryCatch(site::subset_site(sf, todo[i, ]), error = function(e) NULL)
    if (is.null(s1)) next
    ## a sub-site with no transmission of this parasite is outside the
    ## comparison, not a sub-site fleet failed on, so it is not counted as an
    ## attempt
    E <- s1$eir$eir[s1$eir$sp == SP]
    if (length(E) != 1 || is.na(E) || E <= 0) next
    attempted <- attempted + 1L
    ## a sub-site fleet fails on is counted as dropped by assess.R; its reason
    ## goes to the country's log, where diagnosing it starts
    r <- tryCatch(fleet_monthly_subsite(s1), error = function(e) {
      message(sprintf("%s / %s / %s (%s EIR %.3g) failed: %s", iso, todo$name_1[i],
                      todo$urban_rural[i], SP, E, conditionMessage(e)))
      NULL
    })
    if (!is.null(r)) mo[[length(mo) + 1]] <- r
  }
  if (!attempted) return(NA)
  if (!length(mo)) return(NULL)
  ## na_matches = "never": dplyr joins NA to NA by default, so an unnamed
  ## admin-1 on both arms would match and fan out if more than one exists.
  out <- dplyr::inner_join(ibm_monthly(iso), dplyr::bind_rows(mo),
                           by = c("iso3c", "name_1", "urban_rural", "year", "month"),
                           na_matches = "never")
  ## how many sub-sites fleet was asked for against how many it returned: the
  ## difference is the silent selection assess.R has to report
  attr(out, "attempted") <- attempted
  attr(out, "solved") <- length(mo)
  out
}

## Every sub-site of this parasite the sweep runs (tier3_subsites(), so the
## vivax cap included): what a complete sweep must have run. Counted from the
## site files rather than from the workers' own tallies, so a country whose
## worker died, or whose every sub-site failed, shows up as attempted and
## missing instead of silently absent.
expected_subsites <- function() {
  do.call(rbind, lapply(site_isos(), function(iso) {
    e <- tier3_subsites(readRDS(file.path(site_dir(), "sites", paste0(iso, ".RDS"))))
    if (!nrow(e)) return(NULL)
    data.frame(iso3c = e$iso3c, site = paste(e$iso3c, e$name_1, e$urban_rural, sep = "_"))
  }))
}

## ---- reading results back -----------------------------------------------------
## Files written before the blink -> fleet rename carry the model columns as
## mo_clinical / mo_severe. Normalising per file means a results directory
## holding a mix binds cleanly instead of producing two half-NA column pairs.
read_compare <- function(f) {
  x <- readRDS(f)
  for (m in c("clinical", "severe", "mortality")) {
    new <- paste0("fleet_", m); old <- paste0("mo_", m)
    if (!new %in% names(x) && old %in% names(x)) x[[new]] <- x[[old]]
    x[[old]] <- NULL
  }
  x
}

read_all_compare <- function(dir) {
  ## attributes do not survive bind_rows(), so total them first
  files <- list.files(dir, pattern = "_compare[.]rds$", full.names = TRUE)
  if (!length(files))
    stop("no *_compare.rds in ", dir, " -- run validations/03-real-settings/run.R first.",
         call. = FALSE)
  parts <- lapply(files, read_compare)
  out <- dplyr::bind_rows(parts)
  attr(out, "attempted") <- sum(vapply(parts, function(x) attr(x, "attempted") %||% NA_integer_, integer(1)), na.rm = TRUE)
  attr(out, "solved") <- sum(vapply(parts, function(x) attr(x, "solved") %||% NA_integer_, integer(1)), na.rm = TRUE)
  out
}
