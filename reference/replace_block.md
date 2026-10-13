# Replace the text between marker comments

Replaces the lines between `<!-- BEGIN name -->` and `<!-- END name -->`
with `lines`, surrounded by a blank line on each side. The markers are
kept, so repeated calls with the same `lines` leave the file unchanged.

## Usage

``` r
replace_block(path, name, lines, write = TRUE)
```

## Arguments

- path:

  Path to the file.

- name:

  Marker name. Each marker must occur exactly once, `BEGIN` before
  `END`, or the call is an error.

- lines:

  Character vector of replacement lines.

- write:

  If `FALSE`, report whether the file would change without writing it,
  as a staleness check needs.

## Value

`TRUE` if the file changed (or would change), otherwise `FALSE`.
