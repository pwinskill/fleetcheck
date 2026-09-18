#' The repository root
#'
#' The ported comparison code was written as scripts that a runner `source()`d
#' after setting `ROOT`. As package code there is no runner, so the root has to
#' resolve when it is *called* rather than when the package loads. This walks up
#' from the working directory looking for the DESCRIPTION, and honours
#' `FLEETCHECK_ROOT` when set — for a cluster job that runs from somewhere else
#' entirely.
#'
#' @param start directory to search upward from.
#' @return an absolute path.
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

#' Where a validation keeps its committed results
#'
#' @param validation directory name under `validations/`.
#' @param ... path components below `results/`.
#' @export
fc_results <- function(validation, ...) {
  file.path(fc_root(), "validations", validation, "results", ...)
}
