# Stamp an output with what produced it

Every result written by this project carries one of these. It exists
because `fleet`'s own snapshots had the provenance inverted: the
25-minute comparison recorded the malariasimulation version, the R
version, the replicate count and a digest of the scenarios, while the
seven-hour site-file run – the one nobody can repeat – recorded only a
date and a fleet version. The tier that cannot be re-run is the tier
that most needs to say what made it.

## Usage

``` r
stamp(...)
```

## Arguments

- ...:

  extra fields to record (replicate counts, grids, input versions).

## Value

a named list, safe to write as JSON alongside the result.
