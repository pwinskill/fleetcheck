# Tier 3 — real transmission settings

The 63-country site-file comparison: `fleet` against `malariasimulation` across
every admin-1 × urban/rural sub-site in the malariaverse site files. **1,391
sub-sites, 450,684 sub-site-months, 2000–2026**, monthly and *P. falciparum*
only on both sides.

Two claims in the register rest on it, `real-settings-correlation` and
`real-settings-bias`, and both are marked `tier: 3` because of what reproducing
them costs.

## What you can and cannot run

**The figures and statistics are public and committed. The runs behind them are
not.** The site files are not redistributable, and the full sweep is about seven
hours on a cluster. So this directory cannot hand you the tier-3 result; it can
show you exactly how the result is made, and let you reproduce the *method* on
any single sub-site you have a site file for.

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
fleet:     21.9 s
IBM:       1.0 min (one replicate, seed 1)
compared:  324 sub-site-months

                   n        r    slope   rel bias
clinical         324    0.997    1.009       3.7%
severe           324    0.903    0.884       8.5%
```

That severe bias of +8.5% is worth noticing: the full 1,391-sub-site run reports
+8.8%, and BFA's own median across its sub-sites is +8.9%. One sub-site against
one IBM replicate landing that close is a sanity check on the pipeline, not
independent evidence -- the same method on the same kind of input should give
the same kind of answer, and it does.

## The flow, step by step

The script is commented at each step; this is the shape of it.

| step | what happens | why it matters |
| --- | --- | --- |
| 1 | find the site file, `<ISO>.RDS` | not in this repository; `FLEET_VALIDATE` says where |
| 2 | `site::subset_site()` to ONE admin-1 × urban/rural | a site file holds the whole country; a run is one sub-site |
| 3 | ITN usage → model distribution | the file records nets *used*, the model wants nets *handed out* |
| 4 | `site::site_parameters()` | turns the site's interventions, demography, vectors and seasonality into one `malariasimulation` parameter list |
| 5 | `set_equilibrium(p, init_EIR = <the site's pf EIR>)` | **both** models seed off this one list, so neither can drift from the other's setup |
| 6 | `fleet::run_simulation_ode()` | seconds |
| 7 | `malariasimulation::run_simulation()` | minutes, one replicate |
| 8 | `postie::get_rates()` on both, pooled monthly | one reduction, applied identically to both |
| 9 | `fleetcheck::agreement()` | the register's own definition of r, slope and relative bias |

Two details in there are load-bearing and were both learned the hard way.

**Monthly, not annual.** Intra-annual variation is large; averaging it away once
made a real seasonal-amplitude mismatch look like agreement.

**P. falciparum only on both sides.** The pre-run IBM outputs carry both *P.
falciparum* and *P. vivax* rows. Summing over both inflates the baseline with
vivax, which is negligible where pf transmission is high and dominates at low pf
EIR — it was the cause of an apparent `fleet` seasonality mismatch at
low-transmission sites. `fleet` is falciparum-only, so the comparison must be.

**`postie::get_rates()` is not raw output.** It converts counts to
per-person-year rates by age band *and* downscales severe disease by treatment
coverage, `severe × (1 − 0.42·ft) / 0.958`. Clinical is not scaled. Both models
go through the same call here, so the scaling cancels in the comparison — but it
is applied, and severe incidence out of this pipeline is not the model's raw
severe count.

## How the example differs from the production run

One deliberate difference. The real sweep compares `fleet` against **pre-run**
IBM diagnostics shipped with the site files
(`calibration_epi_output/<ISO>_diagnostic_epi.rds`) — re-running the IBM for
1,391 sub-sites is the seven hours. The example runs the IBM live on the same
parameter list instead, so it needs nothing but the one site file and shows both
halves of the comparison actually being produced.

The consequence: the example is **one stochastic realisation at 5,000 people**,
not the median of replicates. Read the shape, not the third decimal. Its output
is written to `results/example_*.csv` and is gitignored — it is a demonstration,
not evidence.

## Status

This directory is otherwise a stub. `results/` is empty, and the numbers
`real-settings-correlation` and `real-settings-bias` report were produced by the
separate site-file harness, not from here. Porting the full run — as
`run.R` for the cluster sweep and `assess.R` for the measured values — is
outstanding.
