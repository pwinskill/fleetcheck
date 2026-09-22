# Shared scenario constants

The settings every comparison script has to agree on, in one place so
they cannot drift apart between the script that runs the IBM and the
script that plots the result.

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

An object of class `character` of length 6.

An object of class `character` of length 5.

An object of class `integer` of length 1.

An object of class `integer` of length 1.

## Details

- `VDIR()`:

  directory holding the optional site-file validation results, which
  live in their own checkout beside this one. Override with the
  `FLEET_VALIDATE` environment variable. The site figure and its table
  are skipped when it is absent.

- `BURN_Y`:

  IBM burn-in years before observation or intervention.

- `POP`:

  IBM human population.

- `N_REP`:

  IBM replicates per scenario.

- `AGE_EDGES`:

  age-profile band edges, in years.

- `SEASON`:

  Fourier coefficients for the seasonal rainfall profile.

- `EIR_GRID`:

  the transmission-intensity grid.

- `EIR_REF`:

  reference EIR for age profiles and interventions.

- `PROFILE_EIR`:

  the low / reference / high transmission levels that shape claims are
  carried at.

- `INT_LABELS`, `TS_LABELS`:

  display labels, in display order.

- `TS_YEARS`, `TS_NET_EVERY`:

  long-horizon programme timings.
