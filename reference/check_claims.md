# Fail if any claim has regressed

Prints
[`scoreboard()`](https://pwinskill.github.io/fleetcheck/reference/scoreboard.md),
then signals an error if a claim with status `fail` is not in
`allow_fail`. An `undeclared` claim is a gap in the register rather than
a regression, so it is reported but does not fail. CI runs this.

## Usage

``` r
check_claims(claims = read_claims(), allow_fail = character())
```

## Arguments

- claims:

  Data frame returned by
  [`read_claims()`](https://pwinskill.github.io/fleetcheck/reference/read_claims.md).

- allow_fail:

  Ids of claims whose failure is accepted. Each must exist in the
  register and have a `note` explaining why, or the call is an error.

## Value

`claims`, invisibly.
