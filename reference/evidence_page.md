# Evidence article for each parasite

Each parasite has its own evidence article, so the two sets of verdicts
are never read as one.

## Usage

``` r
evidence_page(parasite)
```

## Arguments

- parasite:

  Character vector of `"falciparum"` or `"vivax"`, as in the `parasite`
  column returned by
  [`read_claims()`](https://pwinskill.github.io/fleetcheck/reference/read_claims.md).

## Value

A character vector of article file names: `"evidence-vivax.html"` for
`"vivax"` and `"evidence.html"` for anything else.
