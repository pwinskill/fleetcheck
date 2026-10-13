# Standardised departure from a set of replicates

Standardised departure from a set of replicates

## Usage

``` r
band_z(value, x)
```

## Arguments

- value:

  Candidate value, a numeric scalar.

- x:

  Numeric vector of replicate values for the same cell.

## Value

`value` minus the replicate median, in replicate standard deviations.
`NA` when the replicates have no spread.
