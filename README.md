# fleetcheck

How closely does [`fleet`](https://github.com/pwinskill/fleet) reproduce
[`malariasimulation`](https://github.com/mrc-ide/malariasimulation)?

**This measures agreement between two models, not agreement with data.** It is a
twin-fidelity check. `fleet` inherits its epidemiological standing from the IBM,
and inherits it only as far as the gap measured here is small relative to the
IBM's own uncertainty. Nothing on this page is validation against observation.

## The register

Every claim `fleet` makes about agreeing with the IBM lives in
[`claims.yml`](claims.yml), with the criterion that decides it, the measured
value, and a verdict. The scoreboard is the point of the repository: a reader
should meet the verdict before the figures, not be left to infer it from eight
plots.

<!-- BEGIN scoreboard -->

**10 claims — 5 pass, 2 open, 1 failing, 2 with no criterion declared.**

| claim | tier | criterion | measured | verdict |
| --- | --- | --- | --- | --- |
| `severe-allage-eir` | 2 | inside the IBM 10-90% replicate band at every EIR on the grid | inside at 4 of 6; outside at EIR 20 and EIR 50, by 0.20% and 0.37% of the lower edge | **FAIL** |
| `age-structure` | 2 | NONE DECLARED | clinical within -4.9% to +2.6% under age 20; severe 15-25% low in the 5-20 year bands | *no criterion* |
| `real-settings-bias` | 3 | NONE DECLARED | +8.7% on clinical, +8.8% on severe, across 1391 sub-sites in 63 countries | *no criterion* |
| `clinical-under5-eir` | 2 | inside the IBM 10-90% replicate band at every EIR on the grid | inside at 5 of 6; 0.1% above the upper edge at EIR 120 | open |
| `clinical-allage-eir` | 2 | inside the IBM 10-90% replicate band at every EIR on the grid | inside at 5 of 6; 0.24% below the lower edge at EIR 50 | open |
| `seed-stability` | 1 | PfPR(2-10) departs from its seeded value by less than 1% over 15 years at EIR 20 | 0.28% maximum excursion; flat to 0.02% over the last five years | **pass** |
| `prevalence-eir` | 2 | inside the IBM 10-90% replicate band at every EIR on the grid | inside at 6 of 6; largest gap in PfPR 0.004 | **pass** |
| `intervention-impact` | 2 | within 0.6 percentage points of the IBM replicate band on every outcome | inside the band on 16 of 20; within 0.6 pp on the other four | **pass** |
| `speed` | 2 | at least 10x faster than the IBM on the same scenario set | 28x pooled; 9x to 113x per scenario, spread dominated by variation in the IBM's own cost | **pass** |
| `real-settings-correlation` | 3 | r > 0.95 and \|slope - 1\| < 0.10 on both clinical and severe incidence | clinical r 0.982 slope 0.997; severe r 0.958 slope 0.946 | **pass** |

<!-- END scoreboard -->

Regenerated from `claims.yml` by `report/make_scoreboard.R`; CI fails if it is
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

Skeleton. The register and the tested metrics layer are in place; the validation
runs are being ported from `fleet/comparison/` and the site-file harness.
