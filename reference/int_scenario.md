# Intervention scenario names across the transmission grid

Each intervention is run at every EIR in
[PROFILE_EIR](https://pwinskill.github.io/fleetcheck/reference/scenario-constants.md).
The run at `EIR_REF` keeps the bare name, so the scenario names that
predate the grid still mean what they meant; the others carry an
`_e<EIR>` suffix.

## Usage

``` r
int_scenario(intervention, eir, ref = EIR_REF)

int_parts(scenario, ref = EIR_REF)
```

## Arguments

- intervention:

  one of `names(INT_LABELS)`.

- eir:

  transmission intensity.

- ref:

  the reference EIR whose runs carry the bare name:
  [EIR_REF](https://pwinskill.github.io/fleetcheck/reference/scenario-constants.md)
  for the falciparum suite,
  [EIR_REF_PV](https://pwinskill.github.io/fleetcheck/reference/scenario-constants.md)
  for the vivax one.

- scenario:

  scenario names, as they appear in the saved CSVs.

## Value

`int_scenario()` a character vector of scenario names; `int_parts()` a
data frame with `intervention` and `eir` columns.

## Details

The convention is here, rather than written out in the runner and again
in the renderer, because those two files never load each other: the
runner needs malariasimulation attached and the renderer refuses to
require it. Two copies of a naming rule that cannot be checked against
each other is how a figure comes to plot a scenario the runner never
produced.

## Examples

``` r
int_scenario("nets", PROFILE_EIR)
#> [1] "nets_e3"   "nets"      "nets_e120"
int_parts(c("nets", "nets_e3", "nets_e120"))
#>   intervention eir
#> 1         nets  20
#> 2         nets   3
#> 3         nets 120
```
