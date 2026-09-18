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
    rel_bias = if (mr == 0) NA_real_ else mean(d) / mr,
    slope    = unname(stats::coef(stats::lm(candidate ~ reference))[2L])
  )
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
  list(n = length(pos),
       n_inside = sum(pos == 0),
       worst = if (all(pos == 0)) 0 else pos[which.max(abs(pos))])
}
