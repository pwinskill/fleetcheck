# Locate the claims register

Searches `start` and each parent directory for `claims.yml`, then falls
back to the copy installed with the package. The source copy is excluded
by `.Rbuildignore`, so under `R CMD check` the installed copy is the one
found.

## Usage

``` r
find_claims(start = getwd())
```

## Arguments

- start:

  Directory to search upward from.

## Value

The path to `claims.yml`. It is an error if none is found.
