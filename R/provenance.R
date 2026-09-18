#' Stamp an output with what produced it
#'
#' Every result written by this project carries one of these. It exists because
#' `fleet`'s own snapshots had the provenance inverted: the 25-minute comparison
#' recorded the malariasimulation version, the R version, the replicate count
#' and a digest of the scenarios, while the seven-hour site-file run -- the one
#' nobody can repeat -- recorded only a date and a fleet version. The tier that
#' cannot be re-run is the tier that most needs to say what made it.
#'
#' @param ... extra fields to record (replicate counts, grids, input versions).
#' @return a named list, safe to write as JSON alongside the result.
#' @export
stamp <- function(...) {
  pkg_version <- function(p) {
    v <- tryCatch(as.character(utils::packageVersion(p)), error = function(e) NA_character_)
    if (is.na(v)) NA_character_ else v
  }
  c(list(
    taken             = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
    fleet             = pkg_version("fleet"),
    fleet_sha         = git_sha(system.file(package = "fleet")),
    malariasimulation = pkg_version("malariasimulation"),
    postie            = pkg_version("postie"),
    R                 = paste(R.version$major, R.version$minor, sep = "."),
    platform          = R.version$platform,
    fleetcheck_sha    = git_sha(".")
  ), list(...))
}

git_sha <- function(path = ".") {
  if (!nzchar(path) || !dir.exists(path)) return(NA_character_)
  out <- suppressWarnings(tryCatch(
    system2("git", c("-C", shQuote(path), "rev-parse", "--short", "HEAD"),
            stdout = TRUE, stderr = FALSE),
    error = function(e) NA_character_))
  if (length(out) != 1L || !nzchar(out)) NA_character_ else out
}

#' Write a result and its stamp together
#'
#' @param x a data frame of results.
#' @param dir directory to write into.
#' @param name base name, without extension.
#' @param ... extra provenance fields, passed to [stamp()].
#' @export
write_result <- function(x, dir, name, ...) {
  dir.create(dir, showWarnings = FALSE, recursive = TRUE)
  csv <- file.path(dir, paste0(name, ".csv"))
  # Simulation output is quoted to three or four significant figures anywhere it
  # is reported, and stored at fifteen. Rounding the stored copy took fleet's
  # own monthly file from 10.2 MB to 1.7 MB gzipped with nothing lost. Anything
  # a tolerance is asserted against should be written with `digits = NULL`.
  utils::write.csv(round_sig(x), csv, row.names = FALSE)
  jsonlite::write_json(stamp(...), file.path(dir, paste0(name, ".stamp.json")),
                       auto_unbox = TRUE, pretty = TRUE)
  invisible(csv)
}

round_sig <- function(x, digits = 6) {
  if (is.null(digits)) return(x)
  num <- vapply(x, is.numeric, logical(1))
  x[num] <- lapply(x[num], signif, digits = digits)
  x
}
