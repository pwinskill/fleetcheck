# The README badge row

The one badge worth having here reports the register, so it is generated
from the register rather than typed: a hand-written "all claims pass"
that outlived the failure it was written for is the exact drift this
project exists to stop.

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

  as returned by
  [`read_claims()`](https://pwinskill.github.io/fleetcheck/reference/read_claims.md).

- repo:

  `owner/name` on GitHub.

- site:

  the published site, used as the claims badge's target.

## Value

a character vector of markdown lines, one badge each.

## Details

The static badges are emitted here too, rather than left in the markdown
around a generated block, because a marker line splits a markdown
paragraph. Badges written either side of one render as two rows with a
gap between them.
