# Escape text for a markdown table cell

Escapes `|`, which would otherwise split the row (as in the criterion
`|slope - 1| < 0.10`), and replaces line breaks with a space.

## Usage

``` r
md_cell(x)
```

## Arguments

- x:

  Character vector.

## Value

`x`, escaped.
