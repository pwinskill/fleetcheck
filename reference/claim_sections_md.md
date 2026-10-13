# Render one evidence-article section per claim

Each section has a level-2 heading whose anchor is the claim id,
followed by the verdict and the claim, the criterion and measured value,
the tier and evidence directory, the claim's figure, its table if it
declares one, and its note. Both evidence articles use this, so they
present claims identically.

## Usage

``` r
claim_sections_md(claims, fig_dir = ".")
```

## Arguments

- claims:

  Data frame returned by
  [`read_claims()`](https://pwinskill.github.io/fleetcheck/reference/read_claims.md),
  filtered to the article's claims.

- fig_dir:

  Directory holding the figures and tables, relative to the article.

## Value

A character vector of markdown lines.

## Details

A figure is written as an HTML `<img>` whose alt text is the claim and
its verdict, with its width and height when the png package can read it.
A declared figure or table that is not in `fig_dir` is shown as missing,
with a warning. A claim with neither says that the numbers above decide
it.
