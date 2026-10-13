# Format verdicts as HTML spans

Each span has class `verdict` and a class for the status, which the
site's stylesheet colours. The text is `pass`, `open`, `FAIL` or
`UNTESTED`, so the verdict remains readable where the class is ignored.

## Usage

``` r
verdict_html(status)
```

## Arguments

- status:

  Character vector of statuses: `"pass"`, `"open"`, `"fail"` or
  `"undeclared"`. Any other value is an error.

## Value

A character vector with one span per element of `status`.
