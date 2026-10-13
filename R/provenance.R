# fleet's own snapshots once had their provenance inverted: the 25-minute
# comparison recorded the malariasimulation version, the R version, the
# replicate count and a digest of the scenarios, while the seven-hour site-file
# run, the one nobody can repeat, recorded only a date and a fleet version. The
# tier that cannot be re-run is the one that most needs to say what made it.

#' Record what produced a result
#'
#' Every result written by fleetcheck's validation scripts carries a stamp.
#' Commits are read from the `RemoteSha` or `GithubSHA1` field that `remotes`,
#' `pak` and `devtools` write when installing from GitHub; a package installed
#' from a local source tree has neither, so its commit is `NA` and `fleet`'s
#' `Built` field shows when and on what it was built.
#'
#' @param ... Extra named fields to record, such as replicate counts, grids or
#'   input versions.
#' @return A named list, suitable for writing as JSON beside the result:
#'   `taken` (the time), `fleet`, `fleet_sha`, `fleet_built`,
#'   `malariasimulation`, `malariasimulation_sha`, `postie` (versions and
#'   seven-character commits), `R`, `platform`, `fleetcheck_sha` (the
#'   checkout's commit), then the fields in `...`. Anything unavailable is `NA`.
#' @export
stamp <- function(...) {
  pkg_version <- function(p) {
    v <- tryCatch(as.character(utils::packageVersion(p)), error = function(e) NA_character_)
    if (is.na(v)) NA_character_ else v
  }
  c(list(
    taken             = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
    fleet             = pkg_version("fleet"),
    fleet_sha         = pkg_sha("fleet"),
    fleet_built       = pkg_field("fleet", "Built"),
    malariasimulation = pkg_version("malariasimulation"),
    malariasimulation_sha = pkg_sha("malariasimulation"),
    postie            = pkg_version("postie"),
    R                 = paste(R.version$major, R.version$minor, sep = "."),
    platform          = R.version$platform,
    # fc_root(), not "." -- these scripts are run from anywhere
    fleetcheck_sha    = git_sha(tryCatch(fc_root(), error = function(e) ""))
  ), list(...))
}

pkg_field <- function(p, field) {
  v <- tryCatch(utils::packageDescription(p)[[field]], error = function(e) NULL)
  if (is.null(v) || !nzchar(v)) NA_character_ else as.character(v)
}

# The commit an installed package was built from.
#
# This used to be git_sha(system.file(package = "fleet")), which cannot ever
# return anything: an installed package directory is not a git checkout, so the
# field was structurally NA in every stamp ever written while looking like a
# recorded fact. `remotes`, `pak` and `devtools::install_github()` all write the
# commit into the DESCRIPTION, under two different names depending on vintage,
# and that is the only place it exists once a package is installed. A package
# installed from a local source tree has neither, and then NA is the true
# answer rather than an artefact of asking the wrong question -- `Built` is
# recorded alongside so that case still says when and on what.
pkg_sha <- function(p) {
  for (f in c("RemoteSha", "GithubSHA1")) {
    v <- pkg_field(p, f)
    if (!is.na(v)) return(substr(v, 1, 7))
  }
  NA_character_
}

git_sha <- function(path = ".") {
  if (!nzchar(path) || !dir.exists(path)) return(NA_character_)
  out <- suppressWarnings(tryCatch(
    system2("git", c("-C", shQuote(path), "rev-parse", "--short", "HEAD"),
            stdout = TRUE, stderr = FALSE),
    error = function(e) NA_character_))
  if (length(out) != 1L || !nzchar(out)) NA_character_ else out
}

# Called where the files are written, not applied once by hand afterwards. It
# was applied by hand once: the next run of run.R wrote full precision again and
# rep_monthly.csv went back from 6.4 MB to 19.9 MB without anything noticing.

#' Round the numeric columns of a data frame
#'
#' The validation scripts call this as they write their summaries. Simulation
#' output is quoted to three or four significant figures, so storing fifteen
#' adds size and no information.
#'
#' @param x A data frame.
#' @param digits Significant figures, or `NULL` to return `x` unchanged, as
#'   files that a tolerance is asserted against need.
#' @return `x` with its numeric columns rounded with [signif()].
#' @export
round_sig <- function(x, digits = 6) {
  if (is.null(digits)) return(x)
  num <- vapply(x, is.numeric, logical(1))
  x[num] <- lapply(x[num], signif, digits = digits)
  x
}
