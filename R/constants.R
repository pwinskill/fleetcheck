# Constants shared by every comparison script: paths, and the scenario settings
# that must be identical across them.
#
# Split out of theme.R so the scripts that do not draw anything -- the 25-minute
# IBM run and the drift check -- do not have to load ggplot2, patchwork, ragg and
# systemfonts just to read POP and EIR_GRID. That keeps the drift check's CI
# dependency list to fleet, malariasimulation, digest and jsonlite, which is both
# faster and one less thing to break when a plotting package changes.
#
# These are exported. Every runner script bootstraps with pkgload::load_all()
# where it can and `library(fleetcheck)` where it cannot, and load_all() makes
# internal objects visible while library() does not -- so before they were
# exported the fallback branch was dead code that would have failed on the first
# mention of POP. The scripts run against an installed package now.

#' Shared scenario constants
#'
#' The settings every comparison script has to agree on, in one place so they
#' cannot drift apart between the script that runs the IBM and the script that
#' plots the result.
#'
#' \describe{
#'   \item{`VDIR()`}{directory holding the optional site-file validation
#'     results, which live in their own checkout beside this one. Override with
#'     the `FLEET_VALIDATE` environment variable. The site figure and its table
#'     are skipped when it is absent.}
#'   \item{`BURN_Y`}{IBM burn-in years before observation or intervention.}
#'   \item{`POP`}{IBM human population.}
#'   \item{`N_REP`}{IBM replicates per scenario.}
#'   \item{`AGE_EDGES`}{age-profile band edges, in years.}
#'   \item{`SEASON`}{Fourier coefficients for the seasonal rainfall profile.}
#'   \item{`EIR_GRID`}{the transmission-intensity grid.}
#'   \item{`EIR_REF`}{reference EIR for age profiles and interventions.}
#'   \item{`PROFILE_EIR`}{the low / reference / high transmission levels that
#'     shape claims are carried at.}
#'   \item{`INT_LABELS`, `TS_LABELS`}{display labels, in display order.}
#'   \item{`EIR_GRID_PV`, `EIR_REF_PV`, `PROFILE_EIR_PV`, `INT_LABELS_PV`}{the
#'     same for the P. vivax suite, which runs on its own lower grid and without
#'     chemoprevention or vaccines.}
#'   \item{`TS_YEARS`, `TS_NET_EVERY`}{long-horizon programme timings.}
#' }
#'
#' @name scenario-constants
#' @rdname scenario-constants
#' @export
VDIR <- function() Sys.getenv("FLEET_VALIDATE",
                              file.path(dirname(fc_root()), "fleet_validate"))

## ---- shared scenario constants (must match run_replicates.R) ----------------
#' @rdname scenario-constants
#' @export
BURN_Y   <- 30L                 # IBM burn-in years before observation / intervention
#' @rdname scenario-constants
#' @export
POP      <- 10000L              # IBM population
#' @rdname scenario-constants
#' @export
N_REP    <- 20L                  # IBM replicates per scenario. Was 10, which put
                               # the 10th and 90th percentiles at essentially the
                               # min and max of the sample -- the least stable
                               # statistics available -- while three claims in the
                               # register turn on excursions of 0.1 to 0.4% from
                               # those very edges.
#' @rdname scenario-constants
#' @export
AGE_EDGES <- c(0, 1, 2, 3, 5, 7, 10, 15, 20, 30, 40, 60, 85)   # age-profile bands, years
#' @rdname scenario-constants
#' @export
SEASON   <- list(g0 = 0.285, g = c(-0.33, -0.13, 0.052), h = c(-0.35, 0.020, 0.10))
#' @rdname scenario-constants
#' @export
EIR_GRID <- c(1, 3, 10, 20, 50, 120)
#' @rdname scenario-constants
#' @export
EIR_REF  <- 20                  # reference transmission for age profiles + interventions

## The transmission levels every shape claim is carried at. One definition, used
## by the age profiles and by the intervention impacts, because a claim about
## how a shape tracks the IBM is only as good as the range of transmission it
## was tested over -- and two different ranges would make the two families of
## claim incomparable.
#' @rdname scenario-constants
#' @export
PROFILE_EIR <- c(3, EIR_REF, 120)

#' Intervention scenario names across the transmission grid
#'
#' Each intervention is run at every EIR in [PROFILE_EIR]. The run at `EIR_REF`
#' keeps the bare name, so the scenario names that predate the grid still mean
#' what they meant; the others carry an `_e<EIR>` suffix.
#'
#' The convention is here, rather than written out in the runner and again in
#' the renderer, because those two files never load each other: the runner needs
#' malariasimulation attached and the renderer refuses to require it. Two copies
#' of a naming rule that cannot be checked against each other is how a figure
#' comes to plot a scenario the runner never produced.
#'
#' @param intervention one of `names(INT_LABELS)`.
#' @param eir transmission intensity.
#' @param scenario scenario names, as they appear in the saved CSVs.
#' @return `int_scenario()` a character vector of scenario names;
#'   `int_parts()` a data frame with `intervention` and `eir` columns.
#' @examples
#' int_scenario("nets", PROFILE_EIR)
#' int_parts(c("nets", "nets_e3", "nets_e120"))
#' @export
int_scenario <- function(intervention, eir, ref = EIR_REF) {
  ## Recycle explicitly. ifelse() returns the shape of its TEST, so with a
  ## vector of interventions and one EIR it silently returns a single name --
  ## and the renderer then drew one intervention where it meant six, without
  ## erroring. Both arguments vectorise here, or neither does.
  if (!length(intervention) || !length(eir)) return(character(0))
  n <- max(length(intervention), length(eir))
  intervention <- rep_len(intervention, n)
  eir <- rep_len(eir, n)
  ifelse(eir == ref, intervention, paste0(intervention, "_e", eir))
}

#' @rdname int_scenario
#' @param ref the reference EIR whose runs carry the bare name: [EIR_REF] for
#'   the falciparum suite, [EIR_REF_PV] for the vivax one.
#' @export
int_parts <- function(scenario, ref = EIR_REF) {
  has <- grepl("_e[0-9.]+$", scenario)
  data.frame(intervention = sub("_e[0-9.]+$", "", scenario),
             eir = ifelse(has, suppressWarnings(as.numeric(sub("^.*_e", "", scenario))),
                          ref),
             stringsAsFactors = FALSE)
}

## ---- the P. vivax suite (CMP_PARASITE=pv) -------------------------------------
## Its own grid, because vivax transmission lives lower: at EIR 0.3, 1, 3, 10 and
## 30 fleet's LM prevalence in 2-10 year olds is about 1%, 4%, 9%, 17% and 26%,
## which spans the site files' calibrated vivax EIRs (0.1-4.5) and goes on to the
## high end. No SMC, PMC or vaccine: malariasimulation cannot run chemoprevention
## under vivax, and its vaccines carry no vivax calibration.
#' @rdname scenario-constants
#' @export
EIR_GRID_PV <- c(0.3, 1, 3, 10, 30)
#' @rdname scenario-constants
#' @export
EIR_REF_PV <- 3
#' @rdname scenario-constants
#' @export
PROFILE_EIR_PV <- c(1, EIR_REF_PV, 10)
#' @rdname scenario-constants
#' @export
INT_LABELS_PV <- c(
  treatment   = "Treatment scale-up\nchloroquine, 20% → 60% of cases",
  primaquine  = "Radical cure\nCQ + primaquine at 60%",
  tafenoquine = "Radical cure\nCQ + tafenoquine at 60%",
  irs         = "Indoor residual spraying\n80% coverage, annual",
  nets        = "Bed-net campaign\n80% coverage, one round")

## intervention scenario labels, in display order (highest expected impact last)
#' @rdname scenario-constants
#' @export
INT_LABELS <- c(
  pmc       = "Perennial chemoprevention\nSP-AQ at 10 wk, 14 wk, 9 mo",
  treatment = "Treatment scale-up\n20% \u2192 60% of clinical cases",
  pev       = "RTS,S via EPI\n90% at 5 months, booster",
  smc       = "Seasonal SMC\n4 rounds/yr, ages 0.25\u20135",
  irs       = "Indoor residual spraying\n80% coverage, annual",
  nets      = "Bed-net campaign\n80% coverage, one round")

## long-horizon programme scenarios (ts_*), in tier order: nothing, one thing,
## everything. All EIR 20 seasonal with 20% baseline case management, so each row
## is the row above it with one more thing added.
## kept short on purpose: these are row strips down the left of a 4-column
## figure, and every character of label is width taken from the panels
#' @rdname scenario-constants
#' @export
TS_LABELS <- c(
  ts_none  = "No\ninterventions",
  ts_nets  = "Bed nets\n5 campaigns",
  ts_smc   = "Seasonal\nSMC",
  ts_treat = "Case\nmanagement",
  ts_all   = "All three\ntogether")
#' @rdname scenario-constants
#' @export
TS_YEARS <- 15L                 # years followed past deployment
#' @rdname scenario-constants
#' @export
TS_NET_EVERY <- 3L              # years between net campaigns
