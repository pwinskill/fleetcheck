# Render the register as a markdown table

A count line followed by a table of id, tier, criterion, measured value
and verdict, one row per claim in register order. Each evidence article
carries this above its claim sections.

## Usage

``` r
scoreboard_md(claims = read_claims(), link_prefix = NULL)
```

## Arguments

- claims:

  Data frame returned by
  [`read_claims()`](https://pwinskill.github.io/fleetcheck/reference/read_claims.md).

- link_prefix:

  Link target for each claim id, to which `#<id>` is appended: for
  example `"evidence.html"`, or `""` for an anchor on the same page. A
  single string or one per claim. `NULL` renders the ids as code without
  links.

## Value

A character vector of markdown lines.
