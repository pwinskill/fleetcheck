# fleetcheck

[![check](https://github.com/pwinskill/fleetcheck/actions/workflows/check.yaml/badge.svg)](https://github.com/pwinskill/fleetcheck/actions/workflows/check.yaml)
[![pkgdown](https://github.com/pwinskill/fleetcheck/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/pwinskill/fleetcheck/actions/workflows/pkgdown.yaml)
[![Falciparum claims: 12
pass](https://img.shields.io/badge/falciparum%20claims-12%20pass-brightgreen.svg)](https://pwinskill.github.io/fleetcheck/articles/evidence.md)
[![Vivax claims: 8 pass, 2
fail](https://img.shields.io/badge/vivax%20claims-8%20pass%2C%202%20fail-orange.svg)](https://pwinskill.github.io/fleetcheck/articles/evidence-vivax.md)
[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![License:
MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/pwinskill/fleetcheck/blob/main/LICENSE)

fleetcheck measures how closely the
[`fleet`](https://github.com/pwinskill/fleet) mean-field model
reproduces the
[`malariasimulation`](https://github.com/mrc-ide/malariasimulation)
individual-based model (IBM) of *P. falciparum* and *P. vivax* malaria.

It is a twin-fidelity check: it measures agreement between two models,
not agreement with data. `fleet` inherits its epidemiological standing
from the IBM only as far as the gap measured here is small relative to
the IBM’s own uncertainty, and a faithful reproduction of the IBM
reproduces its biases too. Nothing here is validation against
observation.

## Claims register

Each claim `fleet` makes about agreeing with the IBM is recorded in
[`claims.yml`](https://github.com/pwinskill/fleetcheck/blob/main/claims.yml)
with the criterion that decides it, the value measured against that
criterion, and a verdict.

### *P. falciparum*

**12 claims: 0 failing, 0 untested, 0 open, 12 pass.**

1.  pass
    [`prevalence-eir`](https://pwinskill.github.io/fleetcheck/articles/evidence.html#prevalence-eir):
    LM prevalence in 2-10 year olds tracks the IBM across transmission
    intensity.
2.  pass
    [`clinical-allage-eir`](https://pwinskill.github.io/fleetcheck/articles/evidence.html#clinical-allage-eir):
    All-age clinical incidence tracks the IBM across transmission
    intensity.
3.  pass
    [`clinical-under5-eir`](https://pwinskill.github.io/fleetcheck/articles/evidence.html#clinical-under5-eir):
    Under-5 clinical incidence tracks the IBM across transmission
    intensity.
4.  pass
    [`severe-allage-eir`](https://pwinskill.github.io/fleetcheck/articles/evidence.html#severe-allage-eir):
    All-age severe incidence tracks the IBM across transmission
    intensity.
5.  pass
    [`age-profile-clinical`](https://pwinskill.github.io/fleetcheck/articles/evidence.html#age-profile-clinical):
    The age distribution of clinical incidence tracks the IBM.
6.  pass
    [`age-profile-severe`](https://pwinskill.github.io/fleetcheck/articles/evidence.html#age-profile-severe):
    The age distribution of severe incidence tracks the IBM.
7.  pass
    [`intervention-impact`](https://pwinskill.github.io/fleetcheck/articles/evidence.html#intervention-impact):
    The modelled impact of each intervention matches the IBM.
8.  pass
    [`real-settings-correlation`](https://pwinskill.github.io/fleetcheck/articles/evidence.html#real-settings-correlation):
    Agreement holds across real transmission settings, not just
    synthetic scenarios.
9.  pass
    [`parameter-draws`](https://pwinskill.github.io/fleetcheck/articles/evidence.html#parameter-draws):
    The change a posterior parameter draw makes to prevalence, clinical
    and severe incidence matches the IBM’s.
10. pass
    [`population-age-structure`](https://pwinskill.github.io/fleetcheck/articles/evidence.html#population-age-structure):
    The population age structure matches the IBM’s.
11. pass
    [`speed`](https://pwinskill.github.io/fleetcheck/articles/evidence.html#speed):
    fleet is fast enough to be worth using in place of the IBM.
12. pass
    [`seed-stability`](https://pwinskill.github.io/fleetcheck/articles/evidence.html#seed-stability):
    An undisturbed run holds the equilibrium it was seeded at.

### *P. vivax*

**10 claims: 2 failing, 0 untested, 0 open, 8 pass.**

1.  pass
    [`prevalence-eir-pv`](https://pwinskill.github.io/fleetcheck/articles/evidence-vivax.html#prevalence-eir-pv):
    LM prevalence in 2-10 year olds tracks the IBM across transmission
    intensity.
2.  pass
    [`clinical-allage-eir-pv`](https://pwinskill.github.io/fleetcheck/articles/evidence-vivax.html#clinical-allage-eir-pv):
    All-age clinical incidence tracks the IBM across transmission
    intensity.
3.  pass
    [`clinical-under5-eir-pv`](https://pwinskill.github.io/fleetcheck/articles/evidence-vivax.html#clinical-under5-eir-pv):
    Under-5 clinical incidence tracks the IBM across transmission
    intensity.
4.  pass
    [`relapse-allage-eir-pv`](https://pwinskill.github.io/fleetcheck/articles/evidence-vivax.html#relapse-allage-eir-pv):
    All-age relapse incidence tracks the IBM across transmission
    intensity.
5.  pass
    [`hypnozoite-carriage-eir-pv`](https://pwinskill.github.io/fleetcheck/articles/evidence-vivax.html#hypnozoite-carriage-eir-pv):
    The share of people carrying hypnozoites tracks the IBM across
    transmission intensity.
6.  pass
    [`age-profile-clinical-pv`](https://pwinskill.github.io/fleetcheck/articles/evidence-vivax.html#age-profile-clinical-pv):
    The age distribution of clinical incidence tracks the IBM.
7.  FAIL
    [`intervention-impact-pv`](https://pwinskill.github.io/fleetcheck/articles/evidence-vivax.html#intervention-impact-pv):
    The modelled impact of each intervention, radical cure included,
    matches the IBM.
8.  pass
    [`population-age-structure-pv`](https://pwinskill.github.io/fleetcheck/articles/evidence-vivax.html#population-age-structure-pv):
    The population age structure matches the IBM’s.
9.  FAIL
    [`speed-pv`](https://pwinskill.github.io/fleetcheck/articles/evidence-vivax.html#speed-pv):
    fleet is fast enough to be worth using in place of the IBM.
10. pass
    [`seed-stability-pv`](https://pwinskill.github.io/fleetcheck/articles/evidence-vivax.html#seed-stability-pv):
    An undisturbed run settles to a steady state, off the equilibrium it
    was seeded at, as the IBM’s does.

The criterion, measured value and figure for each claim are on the
evidence pages for [*P.
falciparum*](https://pwinskill.github.io/fleetcheck/articles/evidence.md)
and [*P.
vivax*](https://pwinskill.github.io/fleetcheck/articles/evidence-vivax.md).

The claims ask whether `fleet` tracks the IBM: shape, direction, and
agreement within the IBM’s own stochastic spread. A mean-field model and
an individual-based model sit a few per cent apart for structural
reasons; where that matters, it is noted against the claim it affects.

The list above is generated from `claims.yml` by
`report/make_scoreboard.R`.

## Installation

fleetcheck is not on CRAN. It is used from a clone of the repository:

``` bash
git clone https://github.com/pwinskill/fleetcheck.git
cd fleetcheck
```

Reading and checking the register needs only:

``` r

install.packages(c("yaml", "pkgload", "devtools"))
```

Re-running the models also needs `fleet`, `malariasimulation` and the
output post-processor `postie`. `fleet` compiles C++ and installs
`dust2`, `monty` and `malariaEquilibrium` with it.

``` r

install.packages("remotes")
remotes::install_github("pwinskill/fleet")
remotes::install_github("mrc-ide/malariasimulation")
remotes::install_github("mrc-ide/postie")
remotes::install_deps(dependencies = TRUE)
```

## Usage

From the repository root, read the register as text or as a data frame,
without running any model:

``` r

pkgload::load_all()
writeLines(scoreboard())
subset(read_claims(), status != "pass")
```

CI runs the unit tests, which include static checks of the validation
scripts, and checks that the rendered copies of the register match
`claims.yml` and that no claim has regressed. This takes seconds:

``` bash
Rscript -e 'devtools::test()'
Rscript report/make_scoreboard.R --check
Rscript -e 'pkgload::load_all(quiet = TRUE); check_claims()'
```

[`check_claims()`](https://pwinskill.github.io/fleetcheck/reference/check_claims.md)
fails on any failing claim not listed in its `allow_fail` argument, and
an `allow_fail` entry whose claim has no explanatory `note` is itself an
error.

After a change to `fleet`, re-run `fleet` alone against the committed
IBM results. This takes minutes and is the check to run most often:

``` bash
Rscript validations/02-scenarios/assess.R
```

[Methods](https://pwinskill.github.io/fleetcheck/articles/methods.md)
describes how claims are decided, and how to re-run each body of
evidence, redraw the figures and update the register.
