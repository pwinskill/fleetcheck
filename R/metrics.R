# Every comparison statistic quoted in this project comes from this file. The
# severe-immunity figures in fleet's own documentation once drifted apart
# because the same quantity was derived twice, in two articles, and both
# derivations were wrong. One definition, unit-tested, used everywhere.

#' Agreement between two models on the same quantity
#'
#' @param reference Numeric vector from the reference model (the IBM).
#' @param candidate Numeric vector from the model under test (`fleet`), the
#'   same length as `reference`.
#' @param na.rm If `TRUE`, drop pairs in which either value is not finite.
#' @return A one-row data frame with columns `n`, `cor`, `rmse`, `bias`,
#'   `rel_bias` and `slope`. `bias` is the mean signed difference, in the units
#'   of the quantity; `rel_bias` is `bias` divided by the mean of `reference`,
#'   so 0.087 means the candidate runs 8.7% high. `slope` is the OLS slope of
#'   `candidate` on `reference`, which can disagree with `rel_bias`: a slope of
#'   1 with a positive bias is a constant offset, and a slope above 1 with zero
#'   bias is a fan. With fewer than two pairs every statistic is `NA`, and `cor`
#'   is `NA` when either input has no variance.
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

#' Replicate band width and burden floor
#'
#' `BAND_K` (1.28) is the half-width of the IBM replicate band in standard
#' deviations. Plus or minus 1.28 standard deviations is the 10-90% interval of
#' a normal distribution, so the band estimates the interval the claims name
#' from every replicate rather than from two order statistics. Measured over the
#' 91 tier-2 cells, the percentile band moves more under a jackknife (0.074
#' against 0.072 standard deviations) and is about 10% narrower than the
#' interval it estimates, because sample percentiles from twenty points are
#' biased inward. Its width also drifts with the replicate count (2.06, 2.24 and
#' 2.32 at n = 8, 14 and 20) where this band holds at 2.49, 2.54 and 2.56.
#'
#' `BURDEN_MIN` (0.05) is the share of an outcome a cell must carry to be
#' tested by a claim about how that outcome is distributed. Cells carrying
#' almost none of it say little about the distribution and carry the most
#' replicate noise. At 5% the tested cells still hold 94% of episodes; the cost,
#' recorded against the claims that use it, is that a defect confined to the
#' oldest ages would not be caught.
#'
#' @format A numeric scalar.
#' @name comparison-settings
#' @rdname comparison-settings
#' @export
BAND_K <- 1.28

#' @rdname comparison-settings
#' @export
BURDEN_MIN <- 0.05

#' Replicate band for one cell
#'
#' @param x Numeric vector of replicate values for one cell.
#' @param k Half-width in standard deviations; see [BAND_K].
#' @param na.rm If `TRUE`, drop replicates that are not finite.
#' @return A one-row data frame with `centre` (the median), `scale` (the
#'   standard deviation), `lower` and `upper` (`centre` minus and plus `k *
#'   scale`). All are `NA` with fewer than two replicates. The median is used
#'   because it is what the figures draw and it is robust to the skew in cells
#'   holding few episodes; over the cells the claims rest on, median and mean
#'   agree to 0.02 standard deviations.
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

# The headroom a band test cannot report: four claims once read "inside at 6 of
# 6" while sitting at 0.34, 0.59, 0.61 and 0.73 standard deviations.

#' Standardised departure from a set of replicates
#'
#' @param value Candidate value, a numeric scalar.
#' @param x Numeric vector of replicate values for the same cell.
#' @return `value` minus the replicate median, in replicate standard
#'   deviations. `NA` when the replicates have no spread.
#' @export
band_z <- function(value, x) {
  b <- replicate_band(x)
  if (is.na(b$scale) || b$scale == 0) return(NA_real_)
  (value - b$centre) / b$scale
}

#' Out-of-band rates for a candidate and for held-out replicates
#'
#' "Inside the band in every cell" is a workable bar over six cells, where a
#' genuine replicate clears it about a quarter of the time, but not over 72: a
#' 1.28 SD band leaves a fifth of cells outside by construction, and no
#' replicate clears it. This takes the bar from the IBM instead. Each replicate
#' is held out and scored against the others, and the candidate is scored
#' against the same reduced sets, so a claim can ask whether the candidate is
#' outside less often than the best held-out replicate. That is stricter than
#' treating the candidate as one more replicate: a deterministic model that
#' tracks the centre should be outside far less often than a replicate, which
#' scatters around it.
#'
#' @param replicates Matrix with replicates in rows and cells in columns; at
#'   least three rows.
#' @param candidate Numeric vector of deterministic values, one per cell.
#' @param k Half-width in standard deviations; see [BAND_K].
#' @return A list with `candidate`, the median over held-out sets of the
#'   fraction of cells in which the candidate is outside the band, and
#'   `held_out`, the fraction for each replicate scored against the others.
#'   Cells in which the replicates have no spread, or any value is not finite,
#'   are dropped.
#' @export
outside_rates <- function(replicates, candidate, k = BAND_K) {
  replicates <- as.matrix(replicates)
  stopifnot(length(candidate) == ncol(replicates), nrow(replicates) >= 3L)
  ok <- apply(replicates, 2, function(v) all(is.finite(v)) && stats::sd(v) > 0) &
    is.finite(candidate)
  if (!any(ok))
    return(list(candidate = NA_real_, held_out = rep(NA_real_, nrow(replicates))))
  replicates <- replicates[, ok, drop = FALSE]; candidate <- candidate[ok]
  frac <- function(x, ref) {
    md <- apply(ref, 2, stats::median); s <- apply(ref, 2, stats::sd)
    mean(x < md - k * s | x > md + k * s)
  }
  ## Each replicate is scored against nineteen others, so the candidate is too
  ## -- once per held-out replicate. Scoring it against all twenty would give it
  ## a slightly wider band than its competitors get, and the comparison is
  ## between the two numbers.
  list(candidate = stats::median(vapply(seq_len(nrow(replicates)), function(i)
         frac(candidate, replicates[-i, , drop = FALSE]), 0)),
       held_out = vapply(seq_len(nrow(replicates)), function(i)
         frac(replicates[i, ], replicates[-i, , drop = FALSE]), 0))
}

#' Position of a value relative to a band
#'
#' `band_position()` measures how far a value lies outside a band;
#' `inside_band()` tests whether it lies inside.
#'
#' @param value Numeric vector of candidate values.
#' @param lower,upper Numeric vectors of band edges, the same length as
#'   `value`, for example from [replicate_band()]. It is an error if `lower`
#'   exceeds `upper`.
#' @return `band_position()`: 0 where `value` is inside the band (edges
#'   included), and otherwise the signed distance outside as a fraction of the
#'   edge crossed, so -0.0024 means 0.24% below the lower edge.
#'   `inside_band()`: a logical vector.
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

#' Summarise a set of band comparisons
#'
#' Scores the criterion "inside the IBM replicate band" over a set of cells.
#'
#' @inheritParams band_position
#' @return A list with `n`, the number of cells; `n_inside`, the number inside
#'   the band; `n_missing`, the number with a missing value or edge; and
#'   `worst`, the [band_position()] of largest magnitude (0 when every scored
#'   cell is inside, `NA` when none can be scored).
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
