# Round the numeric columns of a data frame

The validation scripts call this as they write their summaries.
Simulation output is quoted to three or four significant figures, so
storing fifteen adds size and no information.

## Usage

``` r
round_sig(x, digits = 6)
```

## Arguments

- x:

  A data frame.

- digits:

  Significant figures, or `NULL` to return `x` unchanged, as files that
  a tolerance is asserted against need.

## Value

`x` with its numeric columns rounded with
[`signif()`](https://rdrr.io/r/base/Round.html).
