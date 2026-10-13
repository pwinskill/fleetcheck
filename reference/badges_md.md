# Render the README badge row

The CI and pkgdown workflow badges, one claims badge per parasite, and
the lifecycle and licence badges. A claims badge counts claims by
verdict and links to that parasite's evidence article. It is green when
every claim passes, yellow when any is open or untested and none fails,
and orange when any fails. A register with no vivax claims gets a single
badge labelled "claims".

## Usage

``` r
badges_md(
  claims = read_claims(),
  repo = "pwinskill/fleetcheck",
  site = "https://pwinskill.github.io/fleetcheck/"
)
```

## Arguments

- claims:

  Data frame returned by
  [`read_claims()`](https://pwinskill.github.io/fleetcheck/reference/read_claims.md).

- repo:

  GitHub repository, as `"owner/name"`.

- site:

  URL of the published site, with a trailing slash.

## Value

A character vector of markdown lines, one badge each.
