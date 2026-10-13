# Out-of-band rates for a candidate and for held-out replicates

"Inside the band in every cell" is a workable bar over six cells, where
a genuine replicate clears it about a quarter of the time, but not over
72: a 1.28 SD band leaves a fifth of cells outside by construction, and
no replicate clears it. This takes the bar from the IBM instead. Each
replicate is held out and scored against the others, and the candidate
is scored against the same reduced sets, so a claim can ask whether the
candidate is outside less often than the best held-out replicate. That
is stricter than treating the candidate as one more replicate: a
deterministic model that tracks the centre should be outside far less
often than a replicate, which scatters around it.

## Usage

``` r
outside_rates(replicates, candidate, k = BAND_K)
```

## Arguments

- replicates:

  Matrix with replicates in rows and cells in columns; at least three
  rows.

- candidate:

  Numeric vector of deterministic values, one per cell.

- k:

  Half-width in standard deviations; see
  [BAND_K](https://pwinskill.github.io/fleetcheck/reference/comparison-settings.md).

## Value

A list with `candidate`, the median over held-out sets of the fraction
of cells in which the candidate is outside the band, and `held_out`, the
fraction for each replicate scored against the others. Cells in which
the replicates have no spread, or any value is not finite, are dropped.
