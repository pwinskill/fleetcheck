# Locate the claims register

Walks up from `start` looking for `claims.yml`, then falls back to the
copy shipped inside the installed package. The fallback is not a nicety:
the register is `.Rbuildignore`d, so under `R CMD check` the source copy
is not there at all, and without this every test that reads it fails
while
[`devtools::test()`](https://devtools.r-lib.org/reference/test.html) in
the source tree passes. Same shape as the incident this project exists
to document – a green suite over a broken artefact.

## Usage

``` r
find_claims(start = getwd())
```

## Arguments

- start:

  directory to search upward from.

## Value

a path to a readable `claims.yml`.
