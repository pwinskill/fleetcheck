#' Agreement between two models on the same quantity
#'
#' Every comparison statistic quoted anywhere in this project comes from here.
#' That is the point of the file: the severe-immunity figures in `fleet`'s own
#' documentation drifted apart because the same quantity was derived twice in
#' two articles, and both derivations turned out to be wrong. One definition,
#' unit-tested, imported everywhere.
#'
#' @param reference numeric, the model being compared against (the IBM).
#' @param candidate numeric, the model under test (fleet). Same length.
#' @param na.rm drop pairs where either value is missing.
#' @return a one-row data frame: n, cor, rmse, bias, rel_bias, slope.
#'   `bias` is the mean signed difference in the units of the quantity;
#'   `rel_bias` is that divided by the mean of `reference`, so +0.087 means
#'   the candidate runs 8.7% high. `slope` is the OLS slope of candidate on
#'   reference, which is not the same statement as `rel_bias` and can disagree
#'   with it: a slope of 1 with a positive bias is a constant offset, a slope
#'   above 1 with zero bias is a fan.
#' @export
agreement <- function(reference, candidate, na.rm = TRUE) {
  stopifnot(is.numeric(reference), is.numeric(candidate),
            length(reference) == length(candidate))
  if (na.rm) {
    keep <- is.finite(reference) & is.finite(candidate)
    reference <- reference[keep]
    candidate <- candidate[keep]
  }
  n <- length(reference)
  if (n < 2L) {
    return(data.frame(n = n, cor = NA_real_, rmse = NA_real_, bias = NA_real_,
                      rel_bias = NA_real_, slope = NA_real_))
  }
  d <- candidate - reference
  mr <- mean(reference)
  data.frame(
    n        = n,
    # zero variance in either arm is a degenerate comparison, not an error: the
    # contract is to return NA for it, and cor()'s warning is then just noise
    cor      = suppressWarnings(stats::cor(reference, candidate)),
    rmse     = sqrt(mean(d^2)),
    bias     = mean(d),
    # guarded for na.rm = FALSE, where mr is NA and a bare if() errors
    rel_bias = if (is.na(mr) || mr == 0) NA_real_ else mean(d) / mr,
    slope    = unname(stats::coef(stats::lm(candidate ~ reference))[2L])
  )
}

#' How a replicate band and a burden floor are defined
#'
#' `BAND_K` is 1.28 because +-1.28 standard deviations is the 10-90% interval of
#' a normal: the band means the same thing it always did, it is just estimated
#' from all the replicates instead of from two order statistics. Measured over
#' the 91 tier-2 cells, the percentile band moves more under a jackknife (0.074
#' against 0.072 standard deviations) and is about 10% narrower than the
#' interval it estimates, because sample percentiles from twenty points are
#' biased inward. Its width also drifts with the replicate count -- 2.06, 2.24,
#' 2.32 at n = 8, 14, 20 -- where this one holds at 2.49, 2.54, 2.56.
#'
#' `BURDEN_MIN` is the share of an outcome a cell must carry to be tested. A
#' claim about how a burden is distributed is not informative about bands that
#' carry almost none of it, and those bands carry the most replicate noise. At
#' 5% the tested cells still hold 94% of episodes. The cost is real and is
#' recorded against the claims that use it: a defect confined to the oldest ages
#' would not be caught.
#'
#' @format numeric.
#' @name comparison-settings
#' @rdname comparison-settings
#' @export
BAND_K <- 1.28

#' @rdname comparison-settings
#' @export
BURDEN_MIN <- 0.05

#' The band a set of replicates produces
#'
#' @param x numeric, the replicate values for one cell.
#' @param k half-width in standard deviations; see [BAND_K].
#' @param na.rm drop missing replicates.
#' @return a one-row data frame with `centre`, `scale`, `lower` and `upper`.
#'   The centre is the median, which is what the figures draw and what survives
#'   the skew in cells holding few episodes; over the cells that carry the
#'   claims the median and the mean agree to 0.02 standard deviations.
#' @export
replicate_band <- function(x, k = BAND_K, na.rm = TRUE) {
  stopifnot(is.numeric(x), length(k) == 1L, is.numeric(k), is.finite(k), k > 0)
  if (na.rm) x <- x[is.finite(x)]
  if (length(x) < 2L)
    return(data.frame(centre = NA_real_, scale = NA_real_,
                      lower = NA_real_, upper = NA_real_))
  centre <- stats::median(x); scale <- stats::sd(x)
  data.frame(centre = centre, scale = scale,
             lower = centre - k * scale, upper = centre + k * scale)
}

#' Standardised departure from a set of replicates
#'
#' The headroom figure the band test cannot report: four claims read "inside at
#' 6 of 6" while sitting at 0.34, 0.59, 0.61 and 0.73 standard deviations.
#'
#' @param value numeric, the candidate value.
#' @param x numeric, the replicate values for the same cell.
#' @return the signed departure in replicate standard deviations, `NA` when the
#'   replicates carry no spread.
#' @export
band_z <- function(value, x) {
  b <- replicate_band(x)
  if (is.na(b$scale) || b$scale == 0) return(NA_real_)
  (value - b$centre) / b$scale
}

#' Where a value sits relative to a replicate band
#'
#' The IBM is stochastic, so the question is never "are the two numbers equal"
#' but "is the deterministic one inside the spread the stochastic one produces".
#' Returns 0 when inside, and otherwise the signed distance outside expressed as
#' a fraction of the edge it crossed -- so -0.0024 reads as "0.24% below the
#' lower edge", which is how the results are quoted.
#'
#' @param value numeric, the candidate value.
#' @param lower,upper numeric, the band edges (e.g. 10th and 90th percentiles).
#' @export
band_position <- function(value, lower, upper) {
  stopifnot(length(value) == length(lower), length(value) == length(upper))
  if (any(lower > upper, na.rm = TRUE)) stop("lower edge above upper edge")
  ifelse(value >= lower & value <= upper, 0,
         ifelse(value < lower, (value - lower) / abs(lower),
                (value - upper) / abs(upper)))
}

#' @rdname band_position
#' @export
inside_band <- function(value, lower, upper) {
  band_position(value, lower, upper) == 0
}

#' Summarise a set of band comparisons as a criterion outcome
#'
#' @param value,lower,upper as for [band_position()].
#' @return a list with `n`, `n_inside`, and `worst`, the largest excursion.
#' @export
band_summary <- function(value, lower, upper) {
  pos <- band_position(value, lower, upper)
  # an NA band edge is a live possibility -- the edges come from quantile()
  # over replicates -- so it must not turn all() into NA and error
  ok <- !is.na(pos)
  list(n = length(pos),
       n_inside = sum(pos == 0, na.rm = TRUE),
       n_missing = sum(!ok),
       worst = if (!any(ok)) NA_real_ else if (all(pos[ok] == 0)) 0 else
         pos[ok][which.max(abs(pos[ok]))])
}
