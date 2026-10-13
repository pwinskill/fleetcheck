# Format the register as plain text

A line of counts by verdict, then one line per claim giving its verdict,
tier, id and measured value. Claims are in register order, not sorted by
verdict.

## Usage

``` r
scoreboard(claims = read_claims())
```

## Arguments

- claims:

  Data frame returned by
  [`read_claims()`](https://pwinskill.github.io/fleetcheck/reference/read_claims.md).

## Value

A character vector of lines, for
[`writeLines()`](https://rdrr.io/r/base/writeLines.html).
