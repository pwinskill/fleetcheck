# The repository root

The ported comparison code was written as scripts that a runner
[`source()`](https://rdrr.io/r/base/source.html)d after setting `ROOT`.
As package code there is no runner, so the root has to resolve when it
is *called* rather than when the package loads. This walks up from the
working directory looking for the DESCRIPTION, and honours
`FLEETCHECK_ROOT` when set — for a cluster job that runs from somewhere
else entirely.

## Usage

``` r
fc_root(start = getwd())
```

## Arguments

- start:

  directory to search upward from.

## Value

an absolute path.
