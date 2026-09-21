# Where a value sits relative to a replicate band

The IBM is stochastic, so the question is never "are the two numbers
equal" but "is the deterministic one inside the spread the stochastic
one produces". Returns 0 when inside, and otherwise the signed distance
outside expressed as a fraction of the edge it crossed – so -0.0024
reads as "0.24% below the lower edge", which is how the results are
quoted.

## Usage

``` r
band_position(value, lower, upper)

inside_band(value, lower, upper)
```

## Arguments

- value:

  numeric, the candidate value.

- lower, upper:

  numeric, the band edges (e.g. 10th and 90th percentiles).
