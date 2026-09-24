#!/usr/bin/env Rscript
## Turn the tier-3 sweep into the numbers the register quotes, and say whether
## the criterion is met.
##
##   Rscript validations/03-real-settings/assess.R
##
## Reads results/raw/*_compare.rds, which run.R writes and which is not
## committed, and writes the two summaries that are: the overall statistics and
## the per-sub-site table. Statistics come from fleetcheck::agreement(), the
## register's own definition, so this cannot quietly compute r a different way
## from every other claim.

if (nzchar(.l <- Sys.getenv("FLEET_LIB"))) .libPaths(c(.l, .libPaths()))
.f <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))
ROOT <- if (length(.f)) normalizePath(dirname(.f), "/") else getwd()
while (!file.exists(file.path(ROOT, "DESCRIPTION")) && dirname(ROOT) != ROOT)
  ROOT <- dirname(ROOT)
suppressMessages(pkgload::load_all(ROOT, quiet = TRUE))
source(file.path(ROOT, "validations", "03-real-settings", "sites_lib.R"))

DDIR <- fc_results("03-real-settings")
d <- read_all_compare(file.path(DDIR, "raw"))
attempted <- attr(d, "attempted"); solved <- attr(d, "solved")
d$site <- paste(d$iso3c, d$name_1, d$urban_rural, sep = "_")
## The same finite filter agreement() applies, applied once here, so the
## per-site table and the headline count the same rows. They did not: this file
## used raw cor()/mean()/n() while agreement() drops non-finite pairs first.
d <- d[is.finite(d$ms_clinical) & is.finite(d$fleet_clinical) &
         is.finite(d$ms_severe) & is.finite(d$fleet_severe), ]

cat(sprintf("%d countries, %d sub-sites, %s sub-site-months\n",
            length(unique(d$iso3c)), length(unique(d$site)),
            format(nrow(d), big.mark = ",")))
## What a complete sweep should hold, from the site files themselves when they are
## to hand: then a country that produced no result file at all is counted too.
if (nzchar(Sys.getenv("FLEET_VALIDATE"))) {
  expected <- expected_pf_subsites()
  attempted <- nrow(expected)
  solved <- sum(expected$site %in% d$site)
  gone <- expected[!expected$site %in% d$site, ]
  if (nrow(gone))
    cat(sprintf("missing: %s\n", paste(sprintf("%s (%d)", names(table(gone$iso3c)),
                                                as.integer(table(gone$iso3c))),
                                        collapse = ", ")))
}
## Sub-sites fleet could not solve are SELECTION, not noise: the ultra-low-EIR
## fringe is where fleet departs most from the IBM, so dropping them silently
## biases every statistic below toward agreement. Say how many.
if (!is.na(attempted) && attempted > 0L)
  cat(sprintf("fleet solved %d of %d sub-sites attempted (%d dropped)\n",
              solved, attempted, attempted - solved))

## ---- the statistics the register quotes ---------------------------------------
stats <- rbind(
  cbind(metric = "clinical", agreement(d$ms_clinical, d$fleet_clinical)),
  cbind(metric = "severe",   agreement(d$ms_severe,   d$fleet_severe)))
write.csv(round_sig(stats, 10), file.path(DDIR, "stats_monthly.csv"), row.names = FALSE)

per_site <- d |>
  dplyr::group_by(iso3c, site) |>
  dplyr::summarise(cor = suppressWarnings(stats::cor(ms_clinical, fleet_clinical)),
                   ibm = mean(ms_clinical), fleet = mean(fleet_clinical),
                   n = dplyr::n(), .groups = "drop")
write.csv(round_sig(as.data.frame(per_site), 10),
          file.path(DDIR, "per_site_monthly.csv"), row.names = FALSE)

## ---- provenance ---------------------------------------------------------------
## What produced these numbers. The age grid is in here because changing it is
## what made the previous tier-3 statistics stale, and nothing in the file said
## which grid they had been measured on.
stamp <- list(
  generated = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
  fleet = as.character(utils::packageVersion("fleet")),
  malariasimulation = as.character(utils::packageVersion("malariasimulation")),
  postie = as.character(utils::packageVersion("postie")),
  site = as.character(utils::packageVersion("site")),
  R = paste0(R.version$major, ".", R.version$minor),
  n_age_groups = length(fleet::default_age_lower()),
  ## the discretisation too: a statistic is not reproducible without it
  n_sub = fleet::ode_tuning()$n_sub,
  sub_sites_attempted = attempted, sub_sites_solved = solved,
  countries = length(unique(d$iso3c)), sub_sites = length(unique(d$site)),
  sub_site_months = nrow(d))
jsonlite::write_json(stamp, file.path(DDIR, "sites_reference.json"),
                     auto_unbox = TRUE, pretty = TRUE)

## ---- the verdict --------------------------------------------------------------
## real-settings-correlation: r > 0.95 and |slope - 1| < 0.10 on both outcomes.
R_MIN <- 0.95; SLOPE_TOL <- 0.10
cat("\nmonthly agreement, P. falciparum only on both sides\n")
cat(sprintf("  %-9s %8s %8s %9s %9s\n", "", "r", "slope", "rel bias", "verdict"))
ok <- TRUE
for (i in seq_len(nrow(stats))) {
  s <- stats[i, ]
  good <- is.finite(s$cor) && is.finite(s$slope) &&
    s$cor > R_MIN && abs(s$slope - 1) < SLOPE_TOL
  ok <- ok && good
  cat(sprintf("  %-9s %8.3f %8.3f %8.1f%% %9s\n", s$metric, s$cor, s$slope,
              100 * s$rel_bias, if (good) "ok" else "OUTSIDE"))
}
cat(sprintf("\ncriterion: r > %.2f and |slope - 1| < %.2f on both\n", R_MIN, SLOPE_TOL))
cat(sprintf("measured:  clinical r %.3f slope %.3f; severe r %.3f slope %.3f\n",
            stats$cor[1], stats$slope[1], stats$cor[2], stats$slope[2]))
cat(sprintf("age grid:  %d groups\n", stamp$n_age_groups))
if (ok) {
  cat("\nVerdict\n-------\n  Criterion met.\n")
} else {
  cat("\nVerdict\n-------\n  FAIL: outside the criterion.\n")
  quit(status = 1)
}
