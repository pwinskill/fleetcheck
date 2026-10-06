# 04-parameter-draws

When a parameter draw moves an outcome in the IBM, does it move it the same way
in fleet?

```
Rscript validations/04-parameter-draws/select.R     # which draws: about five minutes, fleet only
Rscript validations/04-parameter-draws/run.R        # both models: about two hours on 4 workers
Rscript validations/04-parameter-draws/assess.R     # two minutes: fleet against the committed IBM rows
Rscript validations/04-parameter-draws/render.R     # seconds: the figure
Rscript validations/04-parameter-draws/diagnose.R   # the severe-incidence probe: fifteen minutes
```

`malariasimulation::set_parameter_draw()` replaces 32 of the core parameters
with one of 1,000 draws from the joint posterior of the model fit: the duration
of sub-patent infection, the immunity parameters, the infection, disease and
severe-disease Hill functions, and the infectivity of each state. Every other
claim in the register runs at the default parameters. This one asks whether a
draw does the same thing to the outcomes in both models.

**Which draws.** `select.R` runs fleet at all 1,000 draws for a year from the
seed, at EIR 3, 20 and 120. At EIR 20 it keeps the draws nearest the 5th, 25th,
75th and 95th percentiles of all-age clinical incidence, and the same for
all-age severe incidence: eight draws, in `results/draws.csv`. Choosing on the
burden puts the test where the posterior moves the outcomes most. Choosing on
fleet's outputs rather than the IBM's is a design choice, not part of the
test. `results/draws_coverage.csv` gives each draw's percentile at every EIR
and outcome. Chosen at EIR 20, the eight span less of the posterior elsewhere,
and less of prevalence, which they were not chosen on. Once `draws.csv` exists,
`select.R` refuses to change it unless `CMP_RESELECT=1` is set, because the IBM
rows belong to those draws.

**The runs.** `run.R` runs each draw at EIR 3, 20 and 120 exactly as the EIR
grid in `validations/02-scenarios` is run: the same base parameter list, the
draw applied before `set_equilibrium()`, the same 30-year burn-in and
three-year window, 20 IBM replicates of 10,000 people, and the same summariser.
fleet is also run at the default parameters. The IBM is not, because those runs
already exist: the EIR grid's own `eir_3`, `eir_20` and `eir_120` rows in
`02-scenarios`. The only difference is extra rendering bands, which change no
dynamics. `assess.R` checks that the scenarios match apart from rendering, that
both suites' rows were made with the same replicates, population, burn-in and
malariasimulation, and that both are current.

**The test.** The claim is about the response: the change each draw makes to
an outcome, relative to the default parameters at the same EIR.
- fleet's change is the ratio of its two runs.
- The IBM's band is the spread of that ratio between one replicate at the draw
  and one at the default parameters, over every such pair (20 × 20 = 400),
  taken as median ± 1.28 SD.
- Replicates are not paired by seed. A draw changes the dynamics from the first
  day, so same-seed runs are independent.
- fleet's change must sit inside the band on four outcomes: LM prevalence at
  2–10, clinical incidence under 5 and at all ages, and severe incidence at all
  ages. That is 96 cells, eight draws by three EIRs by four outcomes, written to
  `results/draws_cells.csv`.

As in the intervention-impact claim, a ratio of two runs on one age grid cancels
fleet's fixed offsets, which the EIR claims report. An offset that varies with
the draw does not cancel, and the response test is meant to catch it.

**What the band cannot see.** The band is the noise of a single pair of IBM
replicates, so it is wide: about four and a half standard errors of the IBM's
mean change on either side. It catches gross errors. Beside it, and not scored,
`assess.R` tests each outcome's 24 changes against the IBM's mean changes and
their standard errors. It uses a chi-squared on the log ratios, with a
covariance that carries the default-parameter runs all eight draws share. It
also gives fleet's error beyond the IBM's noise, as a root mean square.
Each draw's level, fleet against the IBM's band for the draw itself, is
reported in the same way.

**The severe-incidence probe.** `diagnose.R` runs the default parameters with a
single parameter changed: uv, the refractory period between boosts of
severe-disease immunity. It sets uv to the shortest and longest values among
the draws, at EIR 120. That is 20 IBM replicates of each, 40 runs, with fleet on
the default and a refined age grid. It tests one explanation of the
severe-incidence gap: the spread of severe-disease immunity within a cell, which
fleet does not carry for P. falciparum. Results are in
`results/diagnose_uv.csv`.

**Draws fleet refuses.** Before a run, fleet checks that no age group can lose
more people in a day than it holds. That check bounds a day's infections by
`b0`, as if everyone were bitten every day. At a `b0` above about 0.94, that
bound plus the ageing out of the default grid's 16.6-day infant groups exceeds
1, and fleet stops, naming the group. The bound tightens as the grid is
refined. Two of the 1,000 draws are refused this way on the default grid.
`select.R` lists them, with their `b0`, in `results/refused.csv`, and they are
not candidates.

**Smoke.** `CMP_SMOKE=1` runs one draw, two IBM replicates, a four-year horizon,
into `results/smoke/`. `assess.R` and `render.R` follow it under the same flag.
`assess.R` then needs `02-scenarios`' own smoke rows for the default parameters,
from `CMP_SMOKE=1 Rscript validations/02-scenarios/run.R`.

## Files

| File | What it does |
| --- | --- |
| `select.R` | fleet at all 1,000 draws at EIR 3, 20 and 120. Writes `results/draws.csv` (the eight chosen, at EIR 20), `results/fleet_sweep.csv`, `results/draws_coverage.csv` and `results/refused.csv`. Requires fleet 0.0.0.9004 or later. |
| `run.R` | Both models at each draw and EIR, and fleet at the default parameters. Writes `results/rep_eq.csv`, `results/rep_timing.csv`, `results/ibm_reference.json` and `results/fleet_reference.json`. `CMP_WORKERS` sets the pool (4 by default). `CMP_FLEET_ONLY=1` refreshes fleet's rows and keeps the IBM's. |
| `assess.R` | Re-runs fleet against the committed IBM rows: its own, and the default-parameter rows in `02-scenarios`. Reports movement, the claim, the power test and the levels, and writes `results/draws_cells.csv` when the reference checks pass. Exits 1 if a change falls outside its band or cannot be scored, if the IBM rows are stale or do not match, or (`CMP_STRICT=1`) if anything moved. |
| `render.R` | Draws `cmp_draws.png` from `results/draws_cells.csv`. |
| `diagnose.R` | The severe-incidence probe. Writes `results/diagnose_uv.csv` and `results/diagnose_uv.json`. |

The scenario builder, `draw_scenario()`, and the summariser are the shared ones
in `validations/_shared/scenarios.R`.
