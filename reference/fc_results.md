# Path to a validation's results directory

Path to a validation's results directory

## Usage

``` r
fc_results(validation, ...)
```

## Arguments

- validation:

  Directory name under `validations/`, for example `"02-scenarios"`.

- ...:

  Path components below `results/`.

## Value

A path under
[`fc_root()`](https://pwinskill.github.io/fleetcheck/reference/fc_root.md).
Its existence is not checked.
