# The scoreboard, as printable text

Claims are listed in register order, which is the order they are meant
to be read in: transmission, then clinical burden, then severe, then how
each is distributed by age, then interventions and real settings, and
the checks that support all of it last. What is unresolved is carried by
the count on the first line and by the verdict against each row, not by
moving rows about.

## Usage

``` r
scoreboard(claims = read_claims())
```

## Arguments

- claims:

  as returned by
  [`read_claims()`](https://pwinskill.github.io/fleetcheck/reference/read_claims.md).
