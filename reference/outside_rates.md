# How often a candidate falls outside the replicate band, against the IBM

"Inside the band in every cell" is a sensible bar over six cells, where
a genuine replicate clears it about a quarter of the time. Over
seventy-two it is not: a 1.28-sd band leaves a fifth of cells outside by
construction, and no replicate clears it at all. The bar has to know how
many cells it is being applied to, so it is taken from the IBM: hold
each replicate out, score it against the other nineteen, and ask whether
fleet is outside less often than the best of them.

## Usage

``` r
outside_rates(replicates, candidate, k = BAND_K)
```

## Arguments

- replicates:

  a matrix, replicates in rows and cells in columns.

- candidate:

  the deterministic values, one per cell.

- k:

  half-width in standard deviations; see
  [BAND_K](https://pwinskill.github.io/fleetcheck/reference/comparison-settings.md).

## Value

a list with `candidate`, the fraction of cells the candidate falls
outside, and `held_out`, one such fraction per replicate scored against
the others. Cells where the replicates carry no spread are dropped.

## Details

This is not the same as letting fleet wander as freely as a replicate. A
replicate scatters around the centre; a deterministic model that tracks
the centre should be outside far less often, and the comparison is
against the best replicate rather than the typical one.
