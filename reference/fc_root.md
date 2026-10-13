# Locate the fleetcheck checkout

Returns the `FLEETCHECK_ROOT` environment variable if it is set, for a
job that runs from outside the checkout. Otherwise searches `start` and
each parent directory for a `DESCRIPTION` file for the fleetcheck
package. The root is resolved when called, not when the package loads.

## Usage

``` r
fc_root(start = getwd())
```

## Arguments

- start:

  Directory to search upward from.

## Value

The absolute path of the checkout. It is an error if none is found.
