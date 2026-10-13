# Record what produced a result

Every result written by fleetcheck's validation scripts carries a stamp.
Commits are read from the `RemoteSha` or `GithubSHA1` field that
`remotes`, `pak` and `devtools` write when installing from GitHub; a
package installed from a local source tree has neither, so its commit is
`NA` and `fleet`'s `Built` field shows when and on what it was built.

## Usage

``` r
stamp(...)
```

## Arguments

- ...:

  Extra named fields to record, such as replicate counts, grids or input
  versions.

## Value

A named list, suitable for writing as JSON beside the result: `taken`
(the time), `fleet`, `fleet_sha`, `fleet_built`, `malariasimulation`,
`malariasimulation_sha`, `postie` (versions and seven-character
commits), `R`, `platform`, `fleetcheck_sha` (the checkout's commit),
then the fields in `...`. Anything unavailable is `NA`.
