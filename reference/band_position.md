# Position of a value relative to a band

`band_position()` measures how far a value lies outside a band;
`inside_band()` tests whether it lies inside.

## Usage

``` r
band_position(value, lower, upper)

inside_band(value, lower, upper)
```

## Arguments

- value:

  Numeric vector of candidate values.

- lower, upper:

  Numeric vectors of band edges, the same length as `value`, for example
  from
  [`replicate_band()`](https://pwinskill.github.io/fleetcheck/reference/replicate_band.md).
  It is an error if `lower` exceeds `upper`.

## Value

`band_position()`: 0 where `value` is inside the band (edges included),
and otherwise the signed distance outside as a fraction of the edge
crossed, so -0.0024 means 0.24% below the lower edge. `inside_band()`: a
logical vector.
