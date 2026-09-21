# Package index

## The claims register

- [`read_claims()`](https://pwinskill.github.io/fleetcheck/reference/read_claims.md)
  : Read the claims register
- [`claims_summary()`](https://pwinskill.github.io/fleetcheck/reference/claims_summary.md)
  : Counts by verdict
- [`scoreboard()`](https://pwinskill.github.io/fleetcheck/reference/scoreboard.md)
  : The scoreboard, as printable text
- [`claims_list_md()`](https://pwinskill.github.io/fleetcheck/reference/claims_list_md.md)
  : The register as a numbered list
- [`scoreboard_md()`](https://pwinskill.github.io/fleetcheck/reference/scoreboard_md.md)
  : The register as a markdown table
- [`check_claims()`](https://pwinskill.github.io/fleetcheck/reference/check_claims.md)
  : Fail if the register has regressed

## Comparison statistics

Every statistic quoted anywhere in this project. Defined once and
unit-tested, because the alternative is what happened to fleet’s own
documentation: the same quantity derived twice, in two articles, wrong
both times.

- [`agreement()`](https://pwinskill.github.io/fleetcheck/reference/agreement.md)
  : Agreement between two models on the same quantity
- [`band_position()`](https://pwinskill.github.io/fleetcheck/reference/band_position.md)
  [`inside_band()`](https://pwinskill.github.io/fleetcheck/reference/band_position.md)
  : Where a value sits relative to a replicate band
- [`band_summary()`](https://pwinskill.github.io/fleetcheck/reference/band_summary.md)
  : Summarise a set of band comparisons as a criterion outcome

## Provenance and paths

- [`stamp()`](https://pwinskill.github.io/fleetcheck/reference/stamp.md)
  : Stamp an output with what produced it
- [`round_sig()`](https://pwinskill.github.io/fleetcheck/reference/round_sig.md)
  : Round the numeric columns of a data frame
- [`fc_root()`](https://pwinskill.github.io/fleetcheck/reference/fc_root.md)
  : The repository root
- [`fc_results()`](https://pwinskill.github.io/fleetcheck/reference/fc_results.md)
  : Where a validation keeps its committed results
- [`find_claims()`](https://pwinskill.github.io/fleetcheck/reference/find_claims.md)
  : Locate the claims register
- [`replace_block()`](https://pwinskill.github.io/fleetcheck/reference/replace_block.md)
  : Replace a marked block in a file
- [`md_cell()`](https://pwinskill.github.io/fleetcheck/reference/md_cell.md)
  : Make a string safe inside a markdown table cell

## Scenario constants

The settings the comparison scripts share. Exported so the scripts run
against an installed package and not only under pkgload::load_all().

- [`VDIR()`](https://pwinskill.github.io/fleetcheck/reference/scenario-constants.md)
  [`BURN_Y`](https://pwinskill.github.io/fleetcheck/reference/scenario-constants.md)
  [`POP`](https://pwinskill.github.io/fleetcheck/reference/scenario-constants.md)
  [`N_REP`](https://pwinskill.github.io/fleetcheck/reference/scenario-constants.md)
  [`AGE_EDGES`](https://pwinskill.github.io/fleetcheck/reference/scenario-constants.md)
  [`SEASON`](https://pwinskill.github.io/fleetcheck/reference/scenario-constants.md)
  [`EIR_GRID`](https://pwinskill.github.io/fleetcheck/reference/scenario-constants.md)
  [`EIR_REF`](https://pwinskill.github.io/fleetcheck/reference/scenario-constants.md)
  [`INT_LABELS`](https://pwinskill.github.io/fleetcheck/reference/scenario-constants.md)
  [`TS_LABELS`](https://pwinskill.github.io/fleetcheck/reference/scenario-constants.md)
  [`TS_YEARS`](https://pwinskill.github.io/fleetcheck/reference/scenario-constants.md)
  [`TS_NET_EVERY`](https://pwinskill.github.io/fleetcheck/reference/scenario-constants.md)
  : Shared scenario constants
