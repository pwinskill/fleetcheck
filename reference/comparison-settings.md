# Replicate band width and burden floor

`BAND_K` (1.28) is the half-width of the IBM replicate band in standard
deviations. Plus or minus 1.28 standard deviations is the 10-90%
interval of a normal distribution, so the band estimates the interval
the claims name from every replicate rather than from two order
statistics. Measured over the 91 tier-2 cells, the percentile band moves
more under a jackknife (0.074 against 0.072 standard deviations) and is
about 10% narrower than the interval it estimates, because sample
percentiles from twenty points are biased inward. Its width also drifts
with the replicate count (2.06, 2.24 and 2.32 at n = 8, 14 and 20) where
this band holds at 2.49, 2.54 and 2.56.

## Usage

``` r
BAND_K

BURDEN_MIN
```

## Format

A numeric scalar.

An object of class `numeric` of length 1.

## Details

`BURDEN_MIN` (0.05) is the share of an outcome a cell must carry to be
tested by a claim about how that outcome is distributed. Cells carrying
almost none of it say little about the distribution and carry the most
replicate noise. At 5% the tested cells still hold 94% of episodes; the
cost, recorded against the claims that use it, is that a defect confined
to the oldest ages would not be caught.
