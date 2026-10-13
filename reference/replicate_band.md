# Replicate band for one cell

Replicate band for one cell

## Usage

``` r
replicate_band(x, k = BAND_K, na.rm = TRUE)
```

## Arguments

- x:

  Numeric vector of replicate values for one cell.

- k:

  Half-width in standard deviations; see
  [BAND_K](https://pwinskill.github.io/fleetcheck/reference/comparison-settings.md).

- na.rm:

  If `TRUE`, drop replicates that are not finite.

## Value

A one-row data frame with `centre` (the median), `scale` (the standard
deviation), `lower` and `upper` (`centre` minus and plus `k * scale`).
All are `NA` with fewer than two replicates. The median is used because
it is what the figures draw and it is robust to the skew in cells
holding few episodes; over the cells the claims rest on, median and mean
agree to 0.02 standard deviations.
