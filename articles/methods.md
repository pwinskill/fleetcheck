# How it is produced

## What this measures, and what it does not

`fleetcheck` measures how closely
[`fleet`](https://pwinskill.github.io/fleet) reproduces
`malariasimulation`. **It is a twin-fidelity check, not validation
against data.** Every number here compares two models to each other;
none compares either to an observation.

That matters for how far the result carries. `fleet` inherits its
epidemiological standing from the IBM, and inherits it only as far as
the gap measured here is small relative to the IBM’s own uncertainty
against data. A result that reproduces the IBM faithfully reproduces its
biases too.

## Organised by claim

The unit is a claim, not a scenario. Each one carries the criterion that
decides it and a verdict, so a reader meets a decision rather than a
number to interpret. A claim can fail, and one currently does.

A criterion drawn from the mechanism is worth more than one drawn from
the result. *Inside the IBM replicate band*, because that band is the
noise floor a deterministic model ought to land inside; not *at five of
six EIRs*, because five is what happened to come out. The band also does
the right thing as the comparison gets harder: splitting the IBM by age
thins its counts and widens its own spread, so the test becomes
forgiving exactly where the yardstick becomes uncertain — and says so in
the measured value rather than hiding it.

## One definition of each statistic

`R/metrics.R` holds every comparison statistic used anywhere in the
project, unit-tested.
[`agreement()`](https://pwinskill.github.io/fleetcheck/reference/agreement.md)
returns `cor`, `rmse`, `bias`, `rel_bias` and `slope` together, because
a slope of 1 with a positive bias is a constant offset while a slope
above 1 with no bias is a fan, and quoting one of them alone hides which
you have.
[`band_summary()`](https://pwinskill.github.io/fleetcheck/reference/band_summary.md)
answers “inside the IBM replicate band”, which is the criterion eight
claims in the register are decided by.

This is not ceremony. `fleet`’s own documentation once carried two
independent derivations of the same immunity figures, in two different
articles, and both were wrong by 20 to 35%.

It was not true when it was first written here, either. The scripts each
carried their own copy: the site-file correlation was computed once in
`render.R` for the figure and again in `tables.R` for the table, and the
two had already drifted in naming — one called the mean relative
difference `bias` and the other `rel_bias` — while
[`agreement()`](https://pwinskill.github.io/fleetcheck/reference/agreement.md)
sat in the package unused. They call it now, and the numbers it returns
are identical to six significant figures, which is how the change was
checked.

## Provenance

[`stamp()`](https://pwinskill.github.io/fleetcheck/reference/stamp.md)
records, on every result: the `fleet` and `malariasimulation` versions
and the commits they were installed from, the R version, the platform,
the date, and whatever the run wants to add. A package installed from a
local source tree has no commit to record and the field is `null`;
`Built` is recorded beside it so that case still says when and on what.

It exists because the provenance used to be inverted. The 25-minute
comparison recorded the IBM version, the replicate count and a digest of
the scenario definitions; the seven-hour site-file run, which nobody can
repeat, recorded a date and a version of `fleet`. The tier that cannot
be re-run is the tier that most needs to say what made it.

The site-file snapshot carries two of these and they are not
interchangeable. `run` is the seven-hour comparison — the `fleet`
version its per-country results were produced at — and is only changed
when that run is actually repeated. `summarised` is the seconds-long
pass that turns those results into the four numbers on this site, and
can happen at any later version. A single stamp would report today’s
`fleet` over numbers from months ago.

## Stored precision

Simulation output is quoted to three or four significant figures
wherever it is reported, and was stored at fifteen. `run.R` rounds to
six as it writes, which takes `rep_monthly.csv` from 19.0 MB to 10.8 MB
with nothing lost that anyone reads.

One file keeps full precision: `rep_eq.csv`, which the drift check
asserts against at 1e-6, and which is 46 KB.

The rounding is applied at the point of writing rather than afterwards
because it was applied afterwards once. The next run of `run.R` wrote
full precision again, `rep_monthly.csv` went back to 19 MB, and the
commit went in without anything noticing. A rule about stored precision
has to live in the code that stores it, which is what
[`round_sig()`](https://pwinskill.github.io/fleetcheck/reference/round_sig.md)
is for.

## Reproducing a claim

``` r
# tier 0 and 1, seconds to minutes, no special hardware
Rscript validations/02-scenarios/assess.R

# tier 2, about two hours on ten cores
Rscript validations/02-scenarios/run.R

# a few-minute end-to-end check of the same path
CMP_SMOKE=1 Rscript validations/02-scenarios/run.R
```

The register itself is data, so it can be queried rather than read:

``` r

library(fleetcheck)
scoreboard()
subset(read_claims(), status != "pass")
```
