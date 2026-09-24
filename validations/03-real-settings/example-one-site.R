#!/usr/bin/env Rscript
## A worked example: ONE sub-site, both models, end to end.
##
##   Rscript validations/03-real-settings/example-one-site.R BFA
##   Rscript validations/03-real-settings/example-one-site.R BFA "Sahel" rural
##   FLEET_VALIDATE=/path/to/site/files Rscript ... example-one-site.R BFA
##
## The full tier-3 run is 63 countries and 1,392 sub-sites, and it needs the
## malariaverse site files, which are not
## redistributable. This is the same pipeline applied to a single sub-site, so it
## finishes in a couple of minutes on a laptop and can be read in one sitting.
## If you have one site file, you can run it.
##
## It differs from the production harness in one deliberate way. The real run
## compares `fleet` against PRE-RUN malariasimulation diagnostics shipped
## alongside the site files (`calibration_epi_output/<ISO>_diagnostic_epi.rds`),
## because re-running the IBM for 1,392 sub-sites would need a cluster. Here the
## IBM is run live on the same parameter list, so the example needs nothing but
## the one site file and shows both halves of the comparison being produced. The
## numbers are therefore a single stochastic realisation, not the median of
## replicates the register's claims rest on -- see the note at the end.
##
## Needs: site, malariasimulation, postie, fleet, dplyr.

suppressMessages({
  library(site); library(malariasimulation); library(postie); library(dplyr)
})
if (nzchar(.l <- Sys.getenv("FLEET_LIB"))) .libPaths(c(.l, .libPaths()))

## Find the checkout root by walking up to the DESCRIPTION, so this runs from
## any working directory, and load fleetcheck from it. In this repository
## fleetcheck is usually not installed -- it is loaded with pkgload -- so a bare
## requireNamespace() check would quietly skip the agreement statistics below,
## which are the point of the exercise.
.f <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))
ROOT <- if (length(.f)) normalizePath(dirname(.f), "/") else getwd()
while (!file.exists(file.path(ROOT, "DESCRIPTION")) && dirname(ROOT) != ROOT)
  ROOT <- dirname(ROOT)
if (requireNamespace("pkgload", quietly = TRUE) &&
    file.exists(file.path(ROOT, "DESCRIPTION"))) {
  suppressMessages(pkgload::load_all(ROOT, quiet = TRUE))
} else {
  suppressMessages(library(fleetcheck))
}

args <- commandArgs(TRUE)
ISO <- if (length(args) >= 1) args[[1]] else "BFA"
WANT_NAME <- if (length(args) >= 2) args[[2]] else NULL
WANT_UR <- if (length(args) >= 3) args[[3]] else NULL
POP <- 5000        # people in the IBM. Higher is less noisy and slower.
say <- function(...) cat(sprintf(...), "\n", sep = "")

## ---- 1. find the site files -------------------------------------------------
## They live in their own checkout, not in this repository. FLEET_VALIDATE points
## at it; the default is a sibling directory, which is how the harness is set up.
VDIR <- Sys.getenv("FLEET_VALIDATE", file.path(dirname(getwd()), "fleet_validate"))
f <- file.path(VDIR, "sites", paste0(ISO, ".RDS"))
if (!file.exists(f)) {
  stop("no site file at ", f, "\n",
       "  The malariaverse site files are not redistributable and are not in this\n",
       "  repository. Point FLEET_VALIDATE at a checkout that has them:\n",
       "    FLEET_VALIDATE=/path/to/fleet_validate Rscript ",
       "validations/03-real-settings/example-one-site.R ", ISO, call. = FALSE)
}
site_all <- readRDS(f)
say("site file: %s  (%d sub-sites)", f, nrow(site_all$sites))

## ---- 2. pick ONE sub-site ---------------------------------------------------
## A site file holds every admin-1 x urban/rural combination in the country.
## subset_site() cuts it down to one, carrying every table with it.
rows <- site_all$sites
if (!is.null(WANT_NAME)) rows <- rows[rows$name_1 == WANT_NAME, , drop = FALSE]
if (!is.null(WANT_UR))   rows <- rows[rows$urban_rural == WANT_UR, , drop = FALSE]
if (!nrow(rows)) stop("no sub-site matches ", WANT_NAME, " / ", WANT_UR, call. = FALSE)

s1 <- NULL
for (i in seq_len(nrow(rows))) {
  cand <- try(site::subset_site(site_all, rows[i, ]), silent = TRUE)
  if (inherits(cand, "try-error")) next
  e <- cand$eir$eir[cand$eir$sp == "pf"]
  ## P. falciparum only, and only where there is transmission to compare
  if (length(e) == 1 && is.finite(e) && e > 0) { s1 <- cand; break }
}
if (is.null(s1)) stop("no sub-site here has a usable P. falciparum EIR", call. = FALSE)
EIR <- s1$eir$eir[s1$eir$sp == "pf"]
say("sub-site:  %s / %s / %s    pf EIR %.1f", s1$sites$iso3c, s1$sites$name_1,
    s1$sites$urban_rural, EIR)

## ---- 3. build the parameter list --------------------------------------------
## ITN usage has to be converted to a model distribution first: the site file
## records what fraction of people USED a net, and the model wants how many nets
## were HANDED OUT. Skipping this silently under-protects the population.
itn <- s1$interventions$itn
s1$interventions$itn$implementation$itn_input_dist <-
  site::site_usage_to_model_distribution(
    usage = itn$use$itn_use, usage_year = itn$use$year,
    usage_day_of_year = itn$use$usage_day_of_year,
    distribution_year = itn$implementation$year,
    distribution_day_of_year = itn$implementation$distribution_day_of_year,
    distribution_lower = itn$implementation$distribution_lower,
    distribution_upper = itn$implementation$distribution_upper,
    net_loss_function = netz::net_loss_map, half_life = itn$retention_half_life)

p <- site::site_parameters(
  s1$interventions, s1$demography, s1$vectors, s1$seasonality,
  eir = EIR, start_year = 2000, end_year = 2026,
  overrides = list(human_population = POP))
say("parameters: %d timesteps (%.0f years), %d mosquito species, population %s",
    p$timesteps, p$timesteps / 365, length(p$species), format(POP, big.mark = ","))

## ---- 4. seed both models at the same equilibrium ----------------------------
## set_equilibrium() is how the IBM is seeded, and fleet reads init_EIR off the
## same list, so the two start from one definition rather than two.
p <- malariasimulation::set_equilibrium(p, init_EIR = EIR)

## ---- 5. run fleet (seconds) -------------------------------------------------
t0 <- Sys.time()
ode <- fleet::run_simulation_ode(timesteps = p$timesteps, parameters = p)
say("fleet:     %.1f s", as.numeric(Sys.time() - t0, units = "secs"))

## ---- 6. run the IBM on the SAME list (minutes) ------------------------------
t0 <- Sys.time()
set.seed(1)
ibm <- malariasimulation::run_simulation(timesteps = p$timesteps, parameters = p)
say("IBM:       %.1f min (one replicate, seed 1)", as.numeric(Sys.time() - t0, units = "mins"))

## ---- 7. reduce both the same way --------------------------------------------
## postie::get_rates() turns raw model output into per-person-year rates by age
## band, and applies the treatment-coverage downscaling of severe disease
## (severe x (1 - 0.42 ft) / 0.958). Both models go through it, so that scaling
## cancels in the comparison -- but it is applied, and these are not raw counts.
## Monthly, not annual: intra-annual variation is large, and averaging it away
## once made a seasonal-amplitude mismatch look like agreement.
monthly <- function(out, label) {
  suppressWarnings(postie::get_rates(out)) |>
    group_by(year, month) |>
    summarise(clinical = weighted.mean(clinical, person_days) * 365,
              severe   = weighted.mean(severe,   person_days) * 365,
              .groups = "drop") |>
    mutate(model = label)
}
cmp <- inner_join(
  monthly(ode, "fleet") |> rename(fleet_clinical = clinical, fleet_severe = severe) |> select(-model),
  monthly(ibm, "IBM")   |> rename(ibm_clinical   = clinical, ibm_severe   = severe) |> select(-model),
  by = c("year", "month"))
say("compared:  %d sub-site-months", nrow(cmp))

## ---- 8. the numbers the register would use ----------------------------------
## agreement() is the package's one definition of these statistics -- the same
## function the register's tier-3 claim is stated with, so this example and the
## real run cannot drift apart in how they compute r, slope and bias.
c_st <- agreement(reference = cmp$ibm_clinical, candidate = cmp$fleet_clinical)
s_st <- agreement(reference = cmp$ibm_severe,   candidate = cmp$fleet_severe)
say("")
say("            %8s %8s %8s %10s", "n", "r", "slope", "rel bias")
say("clinical    %8d %8.3f %8.3f %9.1f%%", c_st$n, c_st$cor, c_st$slope, 100 * c_st$rel_bias)
say("severe      %8d %8.3f %8.3f %9.1f%%", s_st$n, s_st$cor, s_st$slope, 100 * s_st$rel_bias)

out <- file.path(ROOT, "validations", "03-real-settings", "results",
                 sprintf("example_%s_%s_%s.csv", s1$sites$iso3c,
                         gsub("[^A-Za-z0-9]", "", s1$sites$name_1), s1$sites$urban_rural))
dir.create(dirname(out), showWarnings = FALSE, recursive = TRUE)
write.csv(cmp, out, row.names = FALSE)
say("")
say("wrote %s", out)
say("")
say("What this is NOT: the register's tier-3 claims come from 1,392 sub-sites")
say("compared against the site files' own calibration diagnostics, not from one")
say("sub-site against one IBM replicate. A single replicate at %s people carries", format(POP, big.mark = ","))
say("real stochastic noise, so read the shape here, not the third decimal.")
