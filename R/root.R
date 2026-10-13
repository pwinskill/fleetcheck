#' Locate the fleetcheck checkout
#'
#' Returns the `FLEETCHECK_ROOT` environment variable if it is set, for a job
#' that runs from outside the checkout. Otherwise searches `start` and each
#' parent directory for a `DESCRIPTION` file for the fleetcheck package. The
#' root is resolved when called, not when the package loads.
#'
#' @param start Directory to search upward from.
#' @return The absolute path of the checkout. It is an error if none is found.
#' @export
fc_root <- function(start = getwd()) {
  env <- Sys.getenv("FLEETCHECK_ROOT")
  if (nzchar(env)) return(normalizePath(env, "/", mustWork = FALSE))
  d <- normalizePath(start, "/", mustWork = FALSE)
  repeat {
    if (file.exists(file.path(d, "DESCRIPTION")) &&
        any(grepl("^Package: *fleetcheck",
                  readLines(file.path(d, "DESCRIPTION"), warn = FALSE))))
      return(d)
    up <- dirname(d)
    if (identical(up, d))
      stop("fleetcheck root not found above ", start,
           ". Set FLEETCHECK_ROOT, or run from inside the checkout.")
    d <- up
  }
}

#' Path to a validation's results directory
#'
#' @param validation Directory name under `validations/`, for example
#'   `"02-scenarios"`.
#' @param ... Path components below `results/`.
#' @return A path under [fc_root()]. Its existence is not checked.
#' @export
fc_results <- function(validation, ...) {
  file.path(fc_root(), "validations", validation, "results", ...)
}
