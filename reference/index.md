# Package index

## Claims register

Read, summarise and check `claims.yml`.

- [`read_claims()`](https://pwinskill.github.io/fleetcheck/reference/read_claims.md)
  : Read the claims register
- [`find_claims()`](https://pwinskill.github.io/fleetcheck/reference/find_claims.md)
  : Locate the claims register
- [`claims_summary()`](https://pwinskill.github.io/fleetcheck/reference/claims_summary.md)
  : Count claims by verdict
- [`scoreboard()`](https://pwinskill.github.io/fleetcheck/reference/scoreboard.md)
  : Format the register as plain text
- [`check_claims()`](https://pwinskill.github.io/fleetcheck/reference/check_claims.md)
  : Fail if any claim has regressed

## Rendering the register

Markdown and HTML for the README, the home page and the evidence
articles.

- [`claims_list_md()`](https://pwinskill.github.io/fleetcheck/reference/claims_list_md.md)
  : Render the register as a numbered list
- [`scoreboard_md()`](https://pwinskill.github.io/fleetcheck/reference/scoreboard_md.md)
  : Render the register as a markdown table
- [`claim_sections_md()`](https://pwinskill.github.io/fleetcheck/reference/claim_sections_md.md)
  : Render one evidence-article section per claim
- [`badges_md()`](https://pwinskill.github.io/fleetcheck/reference/badges_md.md)
  : Render the README badge row
- [`verdict_html()`](https://pwinskill.github.io/fleetcheck/reference/verdict_html.md)
  : Format verdicts as HTML spans
- [`evidence_page()`](https://pwinskill.github.io/fleetcheck/reference/evidence_page.md)
  : Evidence article for each parasite
- [`md_cell()`](https://pwinskill.github.io/fleetcheck/reference/md_cell.md)
  : Escape text for a markdown table cell
- [`replace_block()`](https://pwinskill.github.io/fleetcheck/reference/replace_block.md)
  : Replace the text between marker comments

## Comparison statistics

Every statistic quoted in the evidence, defined once and unit-tested.

- [`agreement()`](https://pwinskill.github.io/fleetcheck/reference/agreement.md)
  : Agreement between two models on the same quantity
- [`BAND_K`](https://pwinskill.github.io/fleetcheck/reference/comparison-settings.md)
  [`BURDEN_MIN`](https://pwinskill.github.io/fleetcheck/reference/comparison-settings.md)
  : Replicate band width and burden floor
- [`replicate_band()`](https://pwinskill.github.io/fleetcheck/reference/replicate_band.md)
  : Replicate band for one cell
- [`band_z()`](https://pwinskill.github.io/fleetcheck/reference/band_z.md)
  : Standardised departure from a set of replicates
- [`outside_rates()`](https://pwinskill.github.io/fleetcheck/reference/outside_rates.md)
  : Out-of-band rates for a candidate and for held-out replicates
- [`band_position()`](https://pwinskill.github.io/fleetcheck/reference/band_position.md)
  [`inside_band()`](https://pwinskill.github.io/fleetcheck/reference/band_position.md)
  : Position of a value relative to a band
- [`band_summary()`](https://pwinskill.github.io/fleetcheck/reference/band_summary.md)
  : Summarise a set of band comparisons

## Provenance and paths

- [`stamp()`](https://pwinskill.github.io/fleetcheck/reference/stamp.md)
  : Record what produced a result
- [`round_sig()`](https://pwinskill.github.io/fleetcheck/reference/round_sig.md)
  : Round the numeric columns of a data frame
- [`fc_root()`](https://pwinskill.github.io/fleetcheck/reference/fc_root.md)
  : Locate the fleetcheck checkout
- [`fc_results()`](https://pwinskill.github.io/fleetcheck/reference/fc_results.md)
  : Path to a validation's results directory

## Scenario constants

Settings shared by the comparison scripts. Exported so the scripts also
run against an installed package, not only under `pkgload::load_all()`.

- [`VDIR()`](https://pwinskill.github.io/fleetcheck/reference/scenario-constants.md)
  [`BURN_Y`](https://pwinskill.github.io/fleetcheck/reference/scenario-constants.md)
  [`POP`](https://pwinskill.github.io/fleetcheck/reference/scenario-constants.md)
  [`N_REP`](https://pwinskill.github.io/fleetcheck/reference/scenario-constants.md)
  [`AGE_EDGES`](https://pwinskill.github.io/fleetcheck/reference/scenario-constants.md)
  [`SEASON`](https://pwinskill.github.io/fleetcheck/reference/scenario-constants.md)
  [`EIR_GRID`](https://pwinskill.github.io/fleetcheck/reference/scenario-constants.md)
  [`EIR_REF`](https://pwinskill.github.io/fleetcheck/reference/scenario-constants.md)
  [`PROFILE_EIR`](https://pwinskill.github.io/fleetcheck/reference/scenario-constants.md)
  [`EIR_GRID_PV`](https://pwinskill.github.io/fleetcheck/reference/scenario-constants.md)
  [`EIR_REF_PV`](https://pwinskill.github.io/fleetcheck/reference/scenario-constants.md)
  [`PROFILE_EIR_PV`](https://pwinskill.github.io/fleetcheck/reference/scenario-constants.md)
  [`INT_LABELS_PV`](https://pwinskill.github.io/fleetcheck/reference/scenario-constants.md)
  [`INT_LABELS`](https://pwinskill.github.io/fleetcheck/reference/scenario-constants.md)
  [`TS_LABELS`](https://pwinskill.github.io/fleetcheck/reference/scenario-constants.md)
  [`TS_YEARS`](https://pwinskill.github.io/fleetcheck/reference/scenario-constants.md)
  [`TS_NET_EVERY`](https://pwinskill.github.io/fleetcheck/reference/scenario-constants.md)
  : Shared scenario constants
- [`int_scenario()`](https://pwinskill.github.io/fleetcheck/reference/int_scenario.md)
  [`int_parts()`](https://pwinskill.github.io/fleetcheck/reference/int_scenario.md)
  : Intervention scenario names across the transmission grid
