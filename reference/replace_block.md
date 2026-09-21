# Replace a marked block in a file

Rewrites whatever sits between `<!-- BEGIN name -->` and
`<!-- END name -->`. The markers stay, so the file can be regenerated
any number of times and a CI job can fail when the tree comes out dirty.

## Usage

``` r
replace_block(path, name, lines, write = TRUE)
```

## Arguments

- path:

  file to edit.

- name:

  marker name.

- lines:

  replacement content.

- write:

  actually write. `FALSE` reports what would change and leaves the file
  alone — which is what a staleness check needs. The first version of
  this wrote before it reported, so running the check dirtied the very
  tree it was checking, and a failing CI job left the working copy
  modified.

## Value

`TRUE` if the file changed, or would have.
