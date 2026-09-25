# Tier 3 — real transmission settings

The 63-country site-file comparison: `fleet` against `malariasimulation` across
every admin-1 × urban/rural sub-site in the malariaverse site files. **1,392
sub-sites, 451,008 sub-site-months, 2000–2026**, monthly and *P. falciparum*
only on both sides.

One claim in the register rests on it, `real-settings-correlation`, marked
`tier: 3` because reproducing it needs inputs that cannot be redistributed. A
*P. vivax* arm runs beside it ([below](#the-p-vivax-arm)); its results are not in
the register yet.

## What you can and cannot run

**The figures and statistics are public and committed. The runs behind them are
not.** The site files are not redistributable. So this directory cannot hand you
the tier-3 result; it can show you exactly how the result is made, and let you
reproduce the *method* on any single sub-site you have a site file for. With the
site files, the sweep re-runs `fleet` only, about twenty minutes on four cores.

`example-one-site.R` is that: the same pipeline, one sub-site, about two minutes.

```bash
# with the site files in a sibling checkout (the default layout)
Rscript validations/03-real-settings/example-one-site.R BFA

# or point at them explicitly, and pick the sub-site
FLEET_VALIDATE=/path/to/fleet_validate \
  Rscript validations/03-real-settings/example-one-site.R BFA "Sahel" rural
```

If you have no site file it stops with a message telling you so, rather than
failing somewhere confusing later.

### What it prints

Burkina Faso, Sahel rural, pf EIR 208, 5,000 people, 2000-2026:

```
site file: .../sites/BFA.RDS  (26 sub-sites)
sub-site:  BFA / Sahel / rural    pf EIR 208.4
parameters: 9855 timesteps (27 years), 3 mosquito species, population 5,000
fleet:     2.3 s
IBM:       0.9 min (one replicate, seed 1)
compared:  324 sub-site-months

                   n        r    slope   rel bias
clinical         324    0.998    0.931      -5.6%
severe           324    0.901    0.766      -7.4%
```

One sub-site against one IBM replicate is a check that the pipeline runs, not
evidence about the model. Do not read a single sub-site's bias against the
sweep's: the excess varies by two orders of magnitude with transmission
intensity, so whether one site looks close says nothing.

## The flow, step by step

The script is commented at each step; this is the shape of it.

| step | what happens | why it matters |
| --- | --- | --- |
| 1 | find the site file, `<ISO>.RDS` | not in this repository; `FLEET_VALIDATE` says where |
| 2 | `site::subset_site()` to ONE admin-1 × urban/rural | a site file holds the whole country; a run is one sub-site |
| 3 | ITN usage → model distribution | the file records nets *used*, the model wants nets *handed out* |
| 4 | `site::site_parameters()` | turns the site's interventions, demography, vectors and seasonality into one `malariasimulation` parameter list |
| 5 | `set_equilibrium(p, init_EIR = <the site's pf EIR>)` | **both** models seed off this one list, so neither can drift from the other's setup |
| 6 | `fleet::run_simulation_ode()` | under a second |
| 7 | `malariasimulation::run_simulation()` | minutes, one replicate |
| 8 | `postie::get_rates()` on both, pooled monthly | one reduction, applied identically to both |
| 9 | `fleetcheck::agreement()` | the register's own definition of r, slope and relative bias |

Three details in there are load-bearing.

**Monthly, not annual.** Intra-annual variation is large, and averaging it away
can make a real seasonal-amplitude mismatch look like agreement.

**One parasite on both sides.** The pre-run IBM outputs carry both *P.
falciparum* and *P. vivax* rows. Summing over both inflates the baseline with
vivax, which is negligible where pf transmission is high and dominates at low pf
EIR, where it looks like a `fleet` seasonality mismatch. So each arm compares one
parasite: the falciparum arm the pf rows against a falciparum `fleet` run, and
the vivax arm the pv rows against a vivax one.

**`postie::get_rates()` is not raw output.** It converts counts to
per-person-year rates by age band *and* downscales severe disease by treatment
coverage, `severe × (1 − 0.42·ft) / 0.958`. Clinical is not scaled. Both models
go through the same call here, so the scaling cancels in the comparison — but it
is applied, and severe incidence out of this pipeline is not the model's raw
severe count.

## How the example differs from the production run

One deliberate difference. The real sweep compares `fleet` against **pre-run**
IBM diagnostics shipped with the site files
(`calibration_epi_output/<ISO>_diagnostic_epi.rds`); re-running the IBM for
1,392 sub-sites is what would need a cluster, and nothing here does it. The
example runs the IBM live on the same parameter list instead, so it needs
nothing but the one site file and shows both halves actually being produced.

What the two share: both run `fleet` at its default settings, so a sub-site's
`fleet` numbers here are the sweep's.

The consequence: the example is **one stochastic realisation at 5,000 people**,
not the median of replicates. Read the shape, not the third decimal. Its output
is written to `results/example_*.csv` and is gitignored — it is a demonstration,
not evidence.

## Running it

The sweep runs **fleet only**, and not as an option. The IBM arm is the pre-run
diagnostic shipped with each site file, so there is no second model to run and
nothing that needs a cluster: the full 63 countries take about twenty minutes on
four cores. That is why a fleet-side change can be re-measured here directly.

```bash
FLEET_VALIDATE=/path/to/site-files Rscript validations/03-real-settings/run.R
Rscript validations/03-real-settings/assess.R
```

`run.R` puts each country in its own subprocess from a worker pool, so a crash
in one is logged and the rest are unaffected, and it is resumable -- a country
whose result exists is skipped. `CMP_ONLY=BFA,GHA` runs a subset;
`FLEET_WORKERS=4` shrinks the pool. Raw per-country output lands in
`results/raw/` and is not committed. `assess.R` turns it into the two summaries
that are -- `stats_monthly.csv` and `per_site_monthly.csv` -- plus a provenance
stamp recording the fleet version, the age grid and the mosquito sub-step count
the numbers were measured at. It counts the sub-sites a complete sweep should
hold from the site files themselves, so a country that produced nothing shows
up as missing rather than silently absent. Countries with no *P. falciparum*
sub-site at all are reported as such by `run.R` and are outside the comparison.

Statistics come from `fleetcheck::agreement()`, the same definition every other
claim in the register uses.

## The *P. vivax* arm

```bash
FLEET_VALIDATE=/path/to/site-files CMP_PARASITE=pv Rscript validations/03-real-settings/run.R
CMP_PARASITE=pv Rscript validations/03-real-settings/assess.R
```

The same pipeline, for the countries whose site files carry vivax transmission:
each sub-site's `site_parameters(parasite = "vivax")` list, seeded at its vivax
EIR, against the pv rows of the shipped diagnostic. Results land in
`results/pv/`, beside falciparum's and never mixed with them. Three things
differ.

- **Up to ten sub-sites per country**, spread evenly across the country's vivax
  EIR range, rather than every one: a vivax run of `fleet` costs about twenty
  times a falciparum run. `assess.R` counts against the sub-sites a sweep should
  hold under that rule, so a country that produced nothing still shows as
  missing.
- **Clinical incidence only.** `malariasimulation` has no vivax severe disease,
  so severe is identically zero on both arms and carries no information.
  `postie::get_rates()` requires severe columns all the same, so the vivax
  outputs are given zero ones before it is called; its severe scaling then has
  nothing to act on.
- **The IBM's relapse gating.** `malariasimulation` 3.0.0 evaluates vivax
  relapses only on days when at least one person is bitten. A day that bites
  nobody is rare in a site run until vector control drives transmission down;
  where such days come, the IBM loses relapses that `fleet` keeps. The
  diagnostics carry that defect; `fleet` does not copy it.
