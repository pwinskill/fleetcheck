# Summarise a set of band comparisons

Scores the criterion "inside the IBM replicate band" over a set of
cells.

## Usage

``` r
band_summary(value, lower, upper)
```

## Arguments

- value:

  Numeric vector of candidate values.

- lower, upper:

  Numeric vectors of band edges, the same length as `value`, for example
  from
  [`replicate_band()`](https://pwinskill.github.io/fleetcheck/reference/replicate_band.md).
  It is an error if `lower` exceeds `upper`.

## Value

A list with `n`, the number of cells; `n_inside`, the number inside the
band; `n_missing`, the number with a missing value or edge; and `worst`,
the
[`band_position()`](https://pwinskill.github.io/fleetcheck/reference/band_position.md)
of largest magnitude (0 when every scored cell is inside, `NA` when none
can be scored).
