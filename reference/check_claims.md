# Fail if the register has regressed

For CI. `undeclared` does not fail – a claim with no criterion is a gap
in the register, not a regression – but it is always reported, so the
count cannot quietly grow.

## Usage

``` r
check_claims(claims = read_claims(), allow_fail = character())
```

## Arguments

- claims:

  as returned by
  [`read_claims()`](https://pwinskill.github.io/fleetcheck/reference/read_claims.md).

- allow_fail:

  claim ids whose failure is known and accepted, each of which must
  carry a `note` explaining why it is tolerated.
