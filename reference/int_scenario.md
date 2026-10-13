# Intervention scenario names across the transmission grid

Each intervention is run at every EIR in
[PROFILE_EIR](https://pwinskill.github.io/fleetcheck/reference/scenario-constants.md).
The run at the reference EIR keeps the bare intervention name, so names
that predate the grid keep their meaning; the others carry an `_e<EIR>`
suffix. `int_scenario()` builds names and `int_parts()` splits them.

## Usage

``` r
int_scenario(intervention, eir, ref = EIR_REF)

int_parts(scenario, ref = EIR_REF)
```

## Arguments

- intervention:

  Intervention names, from `names(INT_LABELS)` or
  `names(INT_LABELS_PV)`.

- eir:

  Transmission intensities. `intervention` and `eir` are recycled to a
  common length.

- ref:

  Reference EIR, whose runs carry the bare name:
  [EIR_REF](https://pwinskill.github.io/fleetcheck/reference/scenario-constants.md)
  for the *P. falciparum* suite,
  [EIR_REF_PV](https://pwinskill.github.io/fleetcheck/reference/scenario-constants.md)
  for the *P. vivax* suite.

- scenario:

  Scenario names, as they appear in the saved CSVs.

## Value

`int_scenario()`: a character vector of scenario names. `int_parts()`: a
data frame with columns `intervention` and `eir`.

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
