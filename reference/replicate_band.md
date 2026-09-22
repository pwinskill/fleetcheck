# The band a set of replicates produces

The band a set of replicates produces

## Usage

``` r
replicate_band(x, k = BAND_K, na.rm = TRUE)
```

## Arguments

- x:

  numeric, the replicate values for one cell.

- k:

  half-width in standard deviations; see
  [BAND_K](https://pwinskill.github.io/fleetcheck/reference/comparison-settings.md).

- na.rm:

  drop missing replicates.

## Value

a one-row data frame with `centre`, `scale`, `lower` and `upper`. The
centre is the median, which is what the figures draw and what survives
the skew in cells holding few episodes; over the cells that carry the
claims the median and the mean agree to 0.02 standard deviations.
