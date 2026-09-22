# How a replicate band and a burden floor are defined

`BAND_K` is 1.28 because +-1.28 standard deviations is the 10-90%
interval of a normal: the band means the same thing it always did, it is
just estimated from all the replicates instead of from two order
statistics. Measured over the 91 tier-2 cells, the percentile band moves
more under a jackknife (0.074 against 0.072 standard deviations) and is
about 10% narrower than the interval it estimates, because sample
percentiles from twenty points are biased inward. Its width also drifts
with the replicate count – 2.06, 2.24, 2.32 at n = 8, 14, 20 – where
this one holds at 2.49, 2.54, 2.56.

## Usage

``` r
BAND_K

BURDEN_MIN
```

## Format

numeric.

An object of class `numeric` of length 1.

## Details

`BURDEN_MIN` is the share of an outcome a cell must carry to be tested.
A claim about how a burden is distributed is not informative about bands
that carry almost none of it, and those bands carry the most replicate
noise. At 5% the tested cells still hold 94% of episodes. The cost is
real and is recorded against the claims that use it: a defect confined
to the oldest ages would not be caught.
