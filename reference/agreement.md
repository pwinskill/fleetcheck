# Agreement between two models on the same quantity

Agreement between two models on the same quantity

## Usage

``` r
agreement(reference, candidate, na.rm = TRUE)
```

## Arguments

- reference:

  Numeric vector from the reference model (the IBM).

- candidate:

  Numeric vector from the model under test (`fleet`), the same length as
  `reference`.

- na.rm:

  If `TRUE`, drop pairs in which either value is not finite.

## Value

A one-row data frame with columns `n`, `cor`, `rmse`, `bias`, `rel_bias`
and `slope`. `bias` is the mean signed difference, in the units of the
quantity; `rel_bias` is `bias` divided by the mean of `reference`, so
0.087 means the candidate runs 8.7% high. `slope` is the OLS slope of
`candidate` on `reference`, which can disagree with `rel_bias`: a slope
of 1 with a positive bias is a constant offset, and a slope above 1 with
zero bias is a fan. With fewer than two pairs every statistic is `NA`,
and `cor` is `NA` when either input has no variance.
