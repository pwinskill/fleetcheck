# Make a string safe inside a markdown table cell

A criterion is written for a human, so it can contain anything – and one
of them is `|slope - 1| < 0.10`, whose pipes silently split the row into
extra columns. Newlines do the same to the table.

## Usage

``` r
md_cell(x)
```

## Arguments

- x:

  character vector.
