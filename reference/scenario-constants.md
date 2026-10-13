# Shared scenario constants

Settings that every comparison script must agree on, defined once so the
script that runs the IBM and the script that plots the result cannot
differ.

## Usage

``` r
VDIR()

BURN_Y

POP

N_REP

AGE_EDGES

SEASON

EIR_GRID

EIR_REF

PROFILE_EIR

EIR_GRID_PV

EIR_REF_PV

PROFILE_EIR_PV

INT_LABELS_PV

INT_LABELS

TS_LABELS

TS_YEARS

TS_NET_EVERY
```

## Format

An object of class `integer` of length 1.

An object of class `integer` of length 1.

An object of class `integer` of length 1.

An object of class `numeric` of length 13.

An object of class `list` of length 3.

An object of class `numeric` of length 6.

An object of class `numeric` of length 1.

An object of class `numeric` of length 3.

An object of class `numeric` of length 5.

An object of class `numeric` of length 1.

An object of class `numeric` of length 3.

An object of class `character` of length 5.

An object of class `character` of length 6.

An object of class `character` of length 5.

An object of class `integer` of length 1.

An object of class `integer` of length 1.

## Details

- `VDIR()`:

  Directory holding the optional site-file validation results, in their
  own checkout beside this one (`../fleet_validate`). The
  `FLEET_VALIDATE` environment variable overrides it. The site figure
  and its table are skipped when the directory is absent.

- `BURN_Y`:

  IBM burn-in, in years, before observation or intervention.

- `POP`:

  IBM human population.

- `N_REP`:

  IBM replicates per scenario.

- `AGE_EDGES`:

  Age-profile band edges, in years.

- `SEASON`:

  Fourier coefficients of the seasonal rainfall profile.

- `EIR_GRID`:

  Transmission-intensity (EIR) grid.

- `EIR_REF`:

  Reference EIR for age profiles and interventions.

- `PROFILE_EIR`:

  Low, reference and high EIRs at which the age-profile and intervention
  claims are tested.

- `INT_LABELS`, `TS_LABELS`:

  Display labels, in display order.

- `EIR_GRID_PV`, `EIR_REF_PV`, `PROFILE_EIR_PV`, `INT_LABELS_PV`:

  The same for the *P. vivax* suite, which has its own lower grid and no
  chemoprevention or vaccines.

- `TS_YEARS`, `TS_NET_EVERY`:

  Years followed after deployment, and years between net campaigns, in
  the long-horizon programme scenarios.
