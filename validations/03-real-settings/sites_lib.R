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

## Countries with BOTH a site file and a pre-run IBM diagnostic. A site file with
## no diagnostic has nothing to compare against, and silently running fleet over
## it would cost minutes and produce nothing.
site_isos <- function() {
  d <- site_dir()
  s <- sub("[.]RDS$", "", basename(Sys.glob(file.path(d, "sites", "*.RDS"))))
  i <- sub("_diagnostic_epi[.]rds$", "",
           basename(Sys.glob(file.path(d, "calibration_epi_output", "*_diagnostic_epi.rds"))))
  sort(intersect(s, i))
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

build_params <- function(s1) {
  s1 <- .munge_itn(s1)
  site::site_parameters(
    s1$interventions, s1$demography, s1$vectors, s1$seasonality,
    eir = s1$eir$eir[s1$eir$sp == "pf"], start_year = 2000, end_year = 2026,
    overrides = list(human_population = 1000))
}

## One sub-site -> monthly all-age clinical and severe, per person per year, or
## NULL if it has no usable pf EIR or fleet cannot solve it.
##
## postie::get_rates() is used on both arms, so fleet's year/month buckets align
## with the IBM diagnostic (also postie-derived) and the person-day weighting
## over age bands gives all-age rates the same way on both sides.
fleet_monthly_subsite <- function(s1) {
  E <- s1$eir$eir[s1$eir$sp == "pf"]
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
  suppressWarnings(postie::get_rates(o)) |>
    group_by(year, month) |>
    summarise(fleet_clinical = weighted.mean(clinical, person_days) * 365,
              fleet_severe   = weighted.mean(severe,   person_days) * 365, .groups = "drop") |>
    mutate(iso3c = s1$sites$iso3c, name_1 = s1$sites$name_1,
           urban_rural = s1$sites$urban_rural)
}

## The IBM arm: pre-run, shipped with the site files, never recomputed here.
##
## FILTER TO pf FIRST. The diagnostics carry both P. falciparum and P. vivax
## rows, and summing over both inflates the baseline with vivax, whose
## seasonality is flatter: negligible where pf transmission is high, dominant at
## low pf EIR. It was the cause of an apparent fleet seasonal-amplitude mismatch
## at low-transmission sites. fleet is falciparum-only, so the comparison is too.
ibm_monthly <- function(iso) {
  readRDS(file.path(site_dir(), "calibration_epi_output",
                    paste0(iso, "_diagnostic_epi.rds"))) |>
    filter(sp == "pf") |>
    group_by(iso3c, name_1, urban_rural, year, month) |>
    summarise(ms_clinical  = weighted.mean(clinical,  person_days) * 365,
              ms_severe    = weighted.mean(severe,    person_days) * 365,
              ms_mortality = weighted.mean(mortality, person_days) * 365,
              .groups = "drop")
}

## One country -> the joined monthly comparison over its pf sub-sites. NULL if
## every sub-site fleet was asked for failed; NA if the country has no
## P. falciparum sub-site at all, which is outside the comparison rather than a
## failure (the site files include purely P. vivax countries).
run_country <- function(iso) {
  load_fleet()
  sf <- readRDS(file.path(site_dir(), "sites", paste0(iso, ".RDS")))
  mo <- list(); attempted <- 0L
  for (i in seq_len(nrow(sf$sites))) {
    s1 <- tryCatch(
      site::subset_site(sf, sf$sites[i, c("country", "iso3c", "name_1", "urban_rural")]),
      error = function(e) NULL)
    if (is.null(s1)) next
    ## a sub-site with no P. falciparum transmission is outside the comparison,
    ## not a sub-site fleet failed on, so it is not counted as an attempt
    E <- s1$eir$eir[s1$eir$sp == "pf"]
    if (length(E) != 1 || is.na(E) || E <= 0) next
    attempted <- attempted + 1L
    r <- tryCatch(fleet_monthly_subsite(s1), error = function(e) NULL)
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

## Every sub-site with P. falciparum transmission in the site files: what a
## complete sweep must have run. Counted from the site files rather than from the
## workers' own tallies, so a country whose worker died, or whose every sub-site
## failed, shows up as attempted and missing instead of silently absent.
expected_pf_subsites <- function() {
  do.call(rbind, lapply(site_isos(), function(iso) {
    e <- as.data.frame(readRDS(file.path(site_dir(), "sites", paste0(iso, ".RDS")))$eir)
    e <- e[e$sp == "pf" & is.finite(e$eir) & e$eir > 0, , drop = FALSE]
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
