# Count claims by verdict

Count claims by verdict

## Usage

``` r
claims_summary(claims = read_claims())
```

## Arguments

- claims:

  Data frame returned by
  [`read_claims()`](https://pwinskill.github.io/fleetcheck/reference/read_claims.md).

## Value

A named list of integer counts: `pass`, `open`, `fail` and `undeclared`.
