# The register as a numbered list

What README and the site's front page carry. A reader arriving there
wants to know what was compared and how it came out; the criterion each
claim was judged against and the number that met it are a level of
detail below that, and they live in the table on the evidence page.
Printing both put every one of those sentences on the site twice.

## Usage

``` r
claims_list_md(claims = read_claims(), link_prefix = NULL)
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
