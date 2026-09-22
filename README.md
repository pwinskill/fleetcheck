# fleetcheck <img src="man/figures/logo.png" align="right" width="30%" alt="fleetcheck hex logo: a mosquito trailing light over a network of connected points, with a green tick" />

<!-- BEGIN badges -->

[![check](https://github.com/pwinskill/fleetcheck/actions/workflows/check.yaml/badge.svg)](https://github.com/pwinskill/fleetcheck/actions/workflows/check.yaml)
[![pkgdown](https://github.com/pwinskill/fleetcheck/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/pwinskill/fleetcheck/actions/workflows/pkgdown.yaml)
[![Claims: 9 pass, 2 fail](https://img.shields.io/badge/claims-9%20pass%2C%202%20fail-orange.svg)](https://pwinskill.github.io/fleetcheck/articles/evidence.html)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/pwinskill/fleetcheck/blob/main/LICENSE)

<!-- END badges -->

> How closely does [`fleet`](https://github.com/pwinskill/fleet) reproduce
> [`malariasimulation`](https://github.com/mrc-ide/malariasimulation)?

**This measures agreement between two models, not agreement with data.** It is a
twin-fidelity check. `fleet` inherits its epidemiological standing from the IBM,
and inherits it only as far as the gap measured here is small relative to the
IBM's own uncertainty. Nothing on this page is validation against observation.

## The register

Every claim `fleet` makes about agreeing with the IBM lives in
[`claims.yml`](https://github.com/pwinskill/fleetcheck/blob/main/claims.yml), with the criterion that decides it, the measured
value, and a verdict. The register is the point of the repository: a reader
should meet the verdict before the figures, not be left to infer it from a wall
of plots.

<!-- BEGIN scoreboard -->

**11 claims — 2 failing, 0 untested, 0 open, 9 pass.**

1. <span class="verdict pass">pass</span> [`prevalence-eir`](https://pwinskill.github.io/fleetcheck/articles/evidence.html#prevalence-eir) &mdash; LM prevalence in 2-10 year olds tracks the IBM across transmission intensity.
2. <span class="verdict pass">pass</span> [`clinical-allage-eir`](https://pwinskill.github.io/fleetcheck/articles/evidence.html#clinical-allage-eir) &mdash; All-age clinical incidence tracks the IBM across transmission intensity.
3. <span class="verdict pass">pass</span> [`clinical-under5-eir`](https://pwinskill.github.io/fleetcheck/articles/evidence.html#clinical-under5-eir) &mdash; Under-5 clinical incidence tracks the IBM across transmission intensity.
4. <span class="verdict pass">pass</span> [`severe-allage-eir`](https://pwinskill.github.io/fleetcheck/articles/evidence.html#severe-allage-eir) &mdash; All-age severe incidence tracks the IBM across transmission intensity.
5. <span class="verdict fail">FAIL</span> [`age-profile-clinical`](https://pwinskill.github.io/fleetcheck/articles/evidence.html#age-profile-clinical) &mdash; The age distribution of clinical incidence tracks the IBM.
6. <span class="verdict pass">pass</span> [`age-profile-severe`](https://pwinskill.github.io/fleetcheck/articles/evidence.html#age-profile-severe) &mdash; The age distribution of severe incidence tracks the IBM.
7. <span class="verdict fail">FAIL</span> [`intervention-impact`](https://pwinskill.github.io/fleetcheck/articles/evidence.html#intervention-impact) &mdash; The modelled impact of each intervention matches the IBM.
8. <span class="verdict pass">pass</span> [`real-settings-correlation`](https://pwinskill.github.io/fleetcheck/articles/evidence.html#real-settings-correlation) &mdash; Agreement holds across real transmission settings, not just synthetic scenarios.
9. <span class="verdict pass">pass</span> [`population-age-structure`](https://pwinskill.github.io/fleetcheck/articles/evidence.html#population-age-structure) &mdash; The population age structure matches the IBM's.
10. <span class="verdict pass">pass</span> [`speed`](https://pwinskill.github.io/fleetcheck/articles/evidence.html#speed) &mdash; fleet is fast enough to be worth using in place of the IBM.
11. <span class="verdict pass">pass</span> [`seed-stability`](https://pwinskill.github.io/fleetcheck/articles/evidence.html#seed-stability) &mdash; An undisturbed run holds the equilibrium it was seeded at.

<!-- END scoreboard -->

The criterion each claim was judged against, the number measured against it, and
the figure it rests on are on the
[evidence page](https://pwinskill.github.io/fleetcheck/articles/evidence.html),
one section per claim.

Regenerated from [`claims.yml`](https://github.com/pwinskill/fleetcheck/blob/main/claims.yml) by `report/make_scoreboard.R`; CI fails if it is
stale. From R, `fleetcheck::scoreboard()` and `fleetcheck::read_claims()` give
the same thing as data rather than as a page.

`check_claims()` fails in CI on anything failing that is not listed in
`allow_fail`, and an `allow_fail` entry with no explanatory note is itself an
error: a tolerated failure has to say why it is tolerated.

**These claims ask whether `fleet` tracks the IBM** — shape, direction, and
agreement inside the IBM's own stochastic spread. A mean-field model and an
individual-based one sit a few per cent apart for structural reasons; where that
matters it is noted against the claim it bears on.

A criterion is drawn from the mechanism rather than from the observed number:
*inside the IBM replicate band*, because that band is the noise floor a
deterministic model should land inside, not *at five of six EIRs* because five
is what happened.

## Tiers

What it costs to reproduce a result is a property of the result, so it is
recorded against every claim rather than mentioned in prose.

| tier | cost | who can reproduce it |
| --- | --- | --- |
| 0 | seconds | anyone, from committed summaries |
| 1 | ~2 min | anyone; re-runs `fleet` only |
| 2 | ~2 h | anyone with about 10 cores |
| 3 | ~40 min | ~10 cores, and inputs that are not redistributable |

Tier 3 is the 63-country site-file comparison. **Its figures and statistics are
public; the site files behind them are not.** The code that produces them is
here and can be read, audited and run — the constraint is the inputs, not the
compute. It re-runs `fleet` only, because the IBM arm is the pre-run diagnostic
shipped with each site file, so forty minutes on ten cores refreshes it.
`validations/03-real-settings/example-one-site.R` demonstrates the same pipeline
on a single sub-site for anyone who has one site file.

## Running it yourself

Every command below is run **from the root of this repository**. No script has a
hardcoded path — each finds the checkout by walking up to the `DESCRIPTION` — so
they work from any working directory and on anyone's machine.

Work down the list. Each step is useful on its own, and the later ones cost more.

### 1. Get the code

```bash
git clone https://github.com/pwinskill/fleetcheck.git
cd fleetcheck
```

### 2. Install what you need for the tier you want

**Tier 0 only** (read the verdicts, check the register is consistent — no models
run, a few seconds):

```r
install.packages(c("yaml", "pkgload", "devtools"))
```

**Tier 1 and 2** (re-run the models) additionally need `fleet`, the IBM, and the
output post-processor. `fleet` pulls `odin2`, `dust2`, `monty` and
`malariaEquilibrium` with it, and compiles C++, so allow some time:

```r
install.packages("remotes")
remotes::install_github("pwinskill/fleet")
remotes::install_github("mrc-ide/malariasimulation")
remotes::install_github("mrc-ide/postie")
remotes::install_deps(dependencies = TRUE)
```

### 3. Read the verdicts without running anything — tier 0, seconds

```bash
Rscript -e 'pkgload::load_all(quiet = TRUE); writeLines(scoreboard())'
```

This prints the same list as the top of this page, straight from `claims.yml`.
To check the register is internally consistent and that nothing has regressed —
which is what CI does:

```bash
Rscript -e 'devtools::test()'
Rscript report/make_scoreboard.R --check
Rscript -e 'pkgload::load_all(quiet = TRUE); check_claims()'
```

### 4. Check whether a change to `fleet` has moved anything — tier 1, ~2 min

**This is the one to run often.** It re-runs `fleet` alone against the committed
IBM rows. The IBM does not depend on `fleet`, so its rows stay valid for any
`fleet`-side change and there is no reason to spend two hours re-running it.

```bash
Rscript validations/02-scenarios/assess.R
```

It answers two questions separately, because they mean different things. *Did
anything move?* — `fleet` now against `fleet`'s committed rows. *Is the match
still good?* — `fleet` now against the IBM medians and 10–90% bands, at the
thresholds the claims rest on. Only the second fails the run by default. It
exits non-zero on drift, so it works in CI.

```bash
CMP_ONLY=eir_20,smc Rscript validations/02-scenarios/assess.R   # a subset, ~20 s
CMP_STRICT=1 Rscript validations/02-scenarios/assess.R          # also fail if ANY number moved
```

### 5. Re-run the whole comparison — tier 2, ~2 h on 10 cores

Try the smoke path first. It runs every scenario end to end at a 4-year horizon
with one replicate, in about two minutes, and writes to
`validations/02-scenarios/results/smoke/` so it cannot touch the committed
results:

```bash
CMP_SMOKE=1 Rscript validations/02-scenarios/run.R
```

Then the real thing. It runs the IBM `N_REP` times per scenario on a PSOCK
cluster (`N_WORKERS`, set at the top of `run.R`) and re-stamps
`ibm_reference.json`:

```bash
Rscript validations/02-scenarios/run.R
```

If you changed `fleet` and only need `fleet`'s rows refreshed, keep the IBM's:

```bash
CMP_FLEET_ONLY=1 Rscript validations/02-scenarios/run.R   # ~1 min
```

### 6. Redraw the figures and tables — seconds

```bash
Rscript validations/02-scenarios/render.R   # cmp_*.png -> man/figures/ and vignettes/
Rscript validations/02-scenarios/tables.R   # -> validations/02-scenarios/results/tables.md
```

`render.R` does not redraw the 63-country site-file panel: that is a snapshot
from a run this repository cannot repeat (see tier 3 below). `CMP_REFRESH_SITES=1`
re-takes it, and needs the validation results present.

### 7. Update the register, then regenerate every rendered copy of it

Edit `claims.yml` — the criterion, the measured value, the verdict — and then:

```bash
Rscript report/make_scoreboard.R
```

That rewrites the register list in `README.md`, in `pkgdown/index.md` and in
`inst/claims.yml` from the register. Never edit those copies by hand: CI runs the
same script with `--check` and fails if they do not match.

### 8. Rebuild the site

```bash
Rscript -e 'pkgdown::build_site()'
```

### What the environment variables do

| variable | what it does |
| --- | --- |
| `CMP_SMOKE=1` | 4-year, 1-replicate end-to-end check into `results/smoke/` |
| `CMP_ONLY=a,b` | run or check only these scenarios, merging into the existing CSVs |
| `CMP_FLEET_ONLY=1` | re-run `fleet`'s rows only, keeping the committed IBM rows |
| `CMP_STRICT=1` | make `assess.R` fail on *any* movement, not just on lost agreement |
| `CMP_REFRESH_SITES=1` | re-take the tier-3 site snapshot from a local validation checkout |
| `FLEET_VALIDATE` | where those site-file results live (default: `../fleet_validate`) |
| `FLEET_LIB` | an extra library path, prepended — for installs that miss `R_LIBS_USER` |
| `FLEETCHECK_ROOT` | the checkout root, for a cluster job that runs from elsewhere |

### What you need inputs for

**Tier 3, the 63-country site-file comparison, runs from this repository — but
only if you have the malariaverse site files, which are not redistributable.**
The constraint is the inputs, not the compute: the sweep re-runs `fleet` alone,
because the IBM arm is the pre-run diagnostic shipped with each site file, so it
is about forty minutes on ten cores.

```bash
FLEET_VALIDATE=/path/to/site-files Rscript validations/03-real-settings/run.R
Rscript validations/03-real-settings/assess.R
```

Its figures and statistics are public and committed here; the runs behind them
are not. `claims.yml` marks those claims `tier: 3` so the cost is attached to the
claim rather than buried in prose.

Without the site files you can still run the *method*, on any one sub-site you
have a file for.
`validations/03-real-settings/example-one-site.R` is the same pipeline — subset
the site file, convert ITN usage to a distribution, build the parameter list,
seed both models off it, reduce both through `postie`, and score with the same
`agreement()` the register uses — applied to a single sub-site in about two
minutes:

```bash
FLEET_VALIDATE=/path/to/fleet_validate   Rscript validations/03-real-settings/example-one-site.R BFA
```

`validations/03-real-settings/README.md` walks through each step and says which
details are load-bearing. Read the shape of the output rather than its third
decimal: one sub-site against one IBM replicate is a check that the pipeline
runs, not evidence about the model.

Tier 2, in `validations/02-scenarios/`, is complete, and is what steps 4 to 6
exercise. `validations/01-seed-stability/` is still a **stub** — a README and an
empty `results/` — so `seed-stability` is the one claim in the register whose
measured value no script here reproduces.

## Layout

```
R/            metrics, provenance, the claims register  (tested)
validations/  one directory per body of evidence
report/       the site: scoreboard first, evidence behind it
claims.yml    the register
```

`R/metrics.R` holds every comparison statistic, defined once and unit-tested.
That is not ceremony: `fleet`'s own documentation once carried two derivations
of the same immunity figures, in two articles, and both were wrong. One
definition, imported everywhere, tested.

`R/provenance.R` stamps every result with the `fleet` and `malariasimulation`
versions, the commits they were installed from, the R version and the date, and
holds the rounding rule the stored summaries are written under. It exists because the
provenance used to be inverted: the 25-minute comparison recorded the IBM
version, the replicate count and a digest of the scenarios, while the site-file
sweep — which needs inputs nobody outside the project has — recorded only a
date. The tier that is hardest to re-run is the one that most needs to say what
made it, and its stamp now carries the `fleet` version and the age grid too.

## Status

The register, the tested metrics layer and **tier 2** are in place: the scenario
comparison in `validations/02-scenarios/` runs end to end, has a two-minute
smoke path, and is what CI checks. **Tier 3** runs from here too — `run.R`,
`assess.R` and `diagnose.R` — given the site files it cannot ship. Tier 1 is
still a stub, so `seed-stability` is the one claim in the register whose
measured value no script here reproduces; porting it is the outstanding work.
