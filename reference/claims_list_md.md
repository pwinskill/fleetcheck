# Render the register as a numbered list

The form used in `README.md` and on the site's home page: verdict, id
and claim, in register order. The criterion and measured value are left
to the evidence articles. When the register holds claims for both
parasites, each parasite gets its own heading, count line and numbering.

## Usage

``` r
claims_list_md(claims = read_claims(), link_prefix = NULL)
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
