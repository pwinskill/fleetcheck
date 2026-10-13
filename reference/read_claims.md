# Read the claims register

Parses `claims.yml` and validates it. Each claim must have a non-blank
`id`, `claim`, `criterion`, `measured`, `status` and `tier`. `status`
must be `pass`, `fail`, `open` or `undeclared`; `tier` an integer from 0
to 3; and `parasite`, if given, `falciparum` or `vivax`. Ids must be
unique, and an `undeclared` claim must have `NONE DECLARED` in its
criterion. A violation, or an empty register, is an error.

## Usage

``` r
read_claims(path = find_claims())
```

## Arguments

- path:

  Path to `claims.yml`.

## Value

A data frame with one row per claim, in register order, and columns
`id`, `claim`, `criterion`, `tier` (integer), `evidence`, `figure`,
`table`, `measured`, `status`, `note` and `parasite`. An absent
`figure`, `table` or `note` is `""`, and an absent `parasite` is
`"falciparum"`.
