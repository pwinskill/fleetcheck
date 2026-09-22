# Standardised departure from a set of replicates

The headroom figure the band test cannot report: four claims read
"inside at 6 of 6" while sitting at 0.34, 0.59, 0.61 and 0.73 standard
deviations.

## Usage

``` r
band_z(value, x)
```

## Arguments

- value:

  numeric, the candidate value.

- x:

  numeric, the replicate values for the same cell.

## Value

the signed departure in replicate standard deviations, `NA` when the
replicates carry no spread.
