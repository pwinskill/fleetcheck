# The register as a markdown table

What the evidence article carries, above the section for each claim.
This is where the detail lives: the criterion, what was measured against
it, and the verdict. Rendered by `report/make_scoreboard.R` and by the
article itself, never typed by hand – a scoreboard maintained in prose
alongside a register in YAML is two copies of the same facts, and this
project exists partly because of what that did to `fleet`'s
documentation.

## Usage

``` r
scoreboard_md(claims = read_claims(), link_prefix = NULL)
```

## Arguments

- claims:

  as returned by
  [`read_claims()`](https://pwinskill.github.io/fleetcheck/reference/read_claims.md).

- link_prefix:

  prefix for the per-claim anchors, e.g. `"evidence.html"`. `""` links
  to anchors on the same page, which is what the evidence article itself
  needs. `NULL` renders the ids as plain code, with no links at all.

## Value

a character vector of markdown lines.
