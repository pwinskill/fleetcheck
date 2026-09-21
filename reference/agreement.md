# Agreement between two models on the same quantity

Every comparison statistic quoted anywhere in this project comes from
here. That is the point of the file: the severe-immunity figures in
`fleet`'s own documentation drifted apart because the same quantity was
derived twice in two articles, and both derivations turned out to be
wrong. One definition, unit-tested, imported everywhere.

## Usage

``` r
agreement(reference, candidate, na.rm = TRUE)
```

## Arguments

- reference:

  numeric, the model being compared against (the IBM).

- candidate:

  numeric, the model under test (fleet). Same length.

- na.rm:

  drop pairs where either value is missing.

## Value

a one-row data frame: n, cor, rmse, bias, rel_bias, slope. `bias` is the
mean signed difference in the units of the quantity; `rel_bias` is that
divided by the mean of `reference`, so +0.087 means the candidate runs
8.7% high. `slope` is the OLS slope of candidate on reference, which is
not the same statement as `rel_bias` and can disagree with it: a slope
of 1 with a positive bias is a constant offset, a slope above 1 with
zero bias is a fan.
