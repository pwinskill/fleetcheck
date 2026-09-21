# Round the numeric columns of a data frame

Simulation output is quoted to three or four significant figures
anywhere it is reported and was stored at fifteen, which is most of the
size of the committed summaries and none of the information in them.

## Usage

``` r
round_sig(x, digits = 6)
```

## Arguments

- x:

  a data frame.

- digits:

  significant figures, or `NULL` to leave `x` alone – which is what
  anything a tolerance is asserted against needs.

## Value

`x` with its numeric columns rounded.

## Details

This is exported and called at the point the files are written, not
applied once by hand afterwards. It was applied by hand once: the next
run of `run.R` wrote full precision again and `rep_monthly.csv` went
back from 6.4 MB to 19.9 MB without anything noticing. A rule about
stored precision has to live in the code that stores it.
