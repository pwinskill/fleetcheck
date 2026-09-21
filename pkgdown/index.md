# fleetcheck

How closely does [`fleet`](https://github.com/pwinskill/fleet) reproduce
[`malariasimulation`](https://github.com/mrc-ide/malariasimulation)?

**This measures agreement between two models, not agreement with data.** It is a
twin-fidelity check. `fleet` inherits its epidemiological standing from the IBM,
and inherits it only as far as the gap measured here is small relative to the
IBM's own uncertainty. Nothing on this page is validation against observation.

## The register

Every claim `fleet` makes about agreeing with the IBM lives in
[`claims.yml`](https://github.com/pwinskill/fleetcheck/blob/main/claims.yml), with the criterion that decides it, the measured
value, and a verdict. The scoreboard is the point of the repository: a reader
should meet the verdict before the figures, not be left to infer it from eight
plots.

<!-- BEGIN scoreboard -->

**11 claims — 0 failing, 3 untested, 0 open, 8 pass.**

| claim | tier | criterion | measured | verdict |
| --- | --- | --- | --- | --- |
| [`severe-allage-bias`](articles/evidence.html#severe-allage-bias) | 2 | NONE DECLARED | fleet sits below the IBM median at all six EIRs, by 0.1% 2.7% 3.1% 2.8% 4.0% 3.5% at EIR 1 3 10 20 50 120 | **UNTESTED** |
| [`age-structure`](articles/evidence.html#age-structure) | 2 | NONE DECLARED | clinical within -11.5% to +11.8% under age 20; severe -21% to +11%, and -16% to -21% in three of the four 5-20 year bands | **UNTESTED** |
| [`real-settings-bias`](articles/evidence.html#real-settings-bias) | 3 | NONE DECLARED | +8.7% on clinical, +8.8% on severe, across 1391 sub-sites in 63 countries | **UNTESTED** |
| [`seed-stability`](articles/evidence.html#seed-stability) | 1 | PfPR(2-10) departs from its seeded value by less than 1% over 15 years at EIR 20 | 0.28% maximum excursion; flat to 0.02% over the last five years | pass |
| [`prevalence-eir`](articles/evidence.html#prevalence-eir) | 2 | inside the IBM 10-90% replicate band at every EIR on the grid | inside at 6 of 6; largest departure 0.94% of the IBM median | pass |
| [`clinical-under5-eir`](articles/evidence.html#clinical-under5-eir) | 2 | inside the IBM 10-90% replicate band at every EIR on the grid | inside at 6 of 6 | pass |
| [`clinical-allage-eir`](articles/evidence.html#clinical-allage-eir) | 2 | inside the IBM 10-90% replicate band at every EIR on the grid | inside at 6 of 6 | pass |
| [`severe-allage-eir`](articles/evidence.html#severe-allage-eir) | 2 | inside the IBM 10-90% replicate band at every EIR on the grid | inside at 6 of 6 | pass |
| [`intervention-impact`](articles/evidence.html#intervention-impact) | 2 | within 0.6 percentage points of the IBM replicate band on every outcome | inside the band on 18 of 20; worst excursion 0.36 percentage points | pass |
| [`speed`](articles/evidence.html#speed) | 2 | at least 10x faster than the IBM on the same scenario set | 19x on cost per simulated year; 10.7 CPU-hours for the IBM against 103 s for fleet | pass |
| [`real-settings-correlation`](articles/evidence.html#real-settings-correlation) | 3 | r > 0.95 and \|slope - 1\| < 0.10 on both clinical and severe incidence | clinical r 0.982 slope 0.997; severe r 0.958 slope 0.946 | pass |

<!-- END scoreboard -->

Regenerated from [`claims.yml`](https://github.com/pwinskill/fleetcheck/blob/main/claims.yml) by `report/make_scoreboard.R`; CI fails if it is
stale. From R, `fleetcheck::scoreboard()` and `fleetcheck::read_claims()` give
the same thing as data rather than as a page.

`check_claims()` fails in CI on anything failing that is not listed in
`allow_fail`, and an `allow_fail` entry with no explanatory note is itself an
error: a tolerated failure has to say why it is tolerated.

**A claim with no criterion is reported as `undeclared`, not as passing.** Two of
the ten are in that state, and one of them matters: `fleet` runs about 9% above
the IBM on clinical and severe incidence across 1,391 sub-sites, and nothing has
ever said what magnitude would be too much. It has been carried as a known
curiosity rather than as a failing test. Writing the criterion down forces the
question — is 9% acceptable for the uses `fleet` is intended for, and on what
argument? Until that is answered the claim is untested, not passed.

## Criteria were written retrospectively

For this first pass the criteria were set after the runs, which is weaker than
declaring them in advance, and each says so in its `declared:` field. They are
drawn from the mechanism rather than from the observed number — *inside the IBM
replicate band*, because that band is the noise floor a deterministic model
should land inside, not *at five of six EIRs* because five is what happened.
Anything added from here declares its criterion first.

## Tiers

What it costs to reproduce a result is a property of the result, so it is
recorded against every claim rather than mentioned in prose.

| tier | cost | who can reproduce it |
| --- | --- | --- |
| 0 | seconds | anyone, from committed summaries |
| 1 | ~2 min | anyone; re-runs `fleet` only |
| 2 | ~25 min | anyone with about 10 cores |
| 3 | ~7 h | cluster, and inputs that are not redistributable |

Tier 3 is the 63-country site-file comparison. **Its figures and statistics are
public; the underlying runs are not.** The code that produced them is here and
can be read and audited; re-running it needs the malariaverse site files and a
cluster. A smoke mode covering a handful of sites keeps that path demonstrably
runnable rather than left to rot.

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

This prints the same table as the top of this page, straight from `claims.yml`.
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
`fleet`-side change and there is no reason to spend 25 minutes re-running it.

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

### 5. Re-run the whole comparison — tier 2, ~25 min on 10 cores

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

That rewrites the scoreboard in `README.md`, in `pkgdown/index.md` and in
`inst/claims.yml` from the register. Never edit those tables by hand: CI runs the
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

### What you cannot run here

**Tier 3, the 63-country site-file comparison, is not reproducible from this
repository.** It needs the malariaverse site files, which are not
redistributable, and about seven hours on a cluster. Its figures and statistics
are public and committed here; the runs behind them are not. `claims.yml` marks
those claims `tier: 3` so the cost is attached to the claim rather than buried in
prose.

You can still run the *method*, on any one sub-site you have a site file for.
`validations/03-real-settings/example-one-site.R` is the same pipeline — subset
the site file, convert ITN usage to a distribution, build the parameter list,
seed both models off it, reduce both through `postie`, and score with the same
`agreement()` the register uses — applied to a single sub-site in about two
minutes:

```bash
FLEET_VALIDATE=/path/to/fleet_validate   Rscript validations/03-real-settings/example-one-site.R BFA
```

On Burkina Faso's Sahel rural sub-site that reports `r` 0.997 and +3.7% relative
bias on clinical, and `r` 0.903 and +8.5% on severe — against the +8.8% severe
excess the full run reports. `validations/03-real-settings/README.md` walks
through each step and says which details are load-bearing.

Tier 2, in `validations/02-scenarios/`, is complete, and is what steps 4 to 6
exercise. `validations/01-seed-stability/` is still a **stub** — a README and an
empty `results/` — and `validations/03-real-settings/` has the worked example
above but not the cluster sweep itself. The numbers those two tiers' claims
report were produced by the original harness in the `fleet` repository and by the
separate site-file checkout; porting them here is outstanding work.

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

`R/provenance.R` stamps every result with the `fleet` version and commit, the
`malariasimulation` version, the R version and the date. It exists because the
provenance used to be inverted — the 25-minute comparison recorded the IBM
version, the replicate count and a digest of the scenarios, while the seven-hour
run that nobody can repeat recorded only a date. The tier that cannot be re-run
is the tier that most needs to say what made it.

## Status

The register, the tested metrics layer and **tier 2** are in place: the scenario
comparison in `validations/02-scenarios/` runs end to end, has a two-minute
smoke path, and is what CI checks. Tiers 1 and 3 are stubs — a README and an
empty `results/` — and the numbers their claims report still come from the
original harness in the `fleet` repository and from the separate site-file
checkout. Porting those is the outstanding work.
