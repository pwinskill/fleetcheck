# Tier 2 — scenario comparison: `fleet` against the IBM

Runs every comparison scenario through **both** models on the *same* parameter
list. The IBM (`malariasimulation`) is run as `N_REP` stochastic replicates per
scenario (10,000 people, 30-year burn-in) in parallel; `fleet` is run once,
seeded at the `malariaEquilibrium` fixed point. Rendering age bands are set once
on the shared parameter list so both models emit identical `n_detect_lm_*` /
`n_age_*` / `n_inc_*` columns, and one summariser reduces both.

This is the tier that is complete. Everything in the repository README's
"Running it yourself", steps 4 to 6, exercises the scripts here.

## Files

| File | What it does |
| --- | --- |
| `assess.R` | **The one to run often.** Re-runs `fleet` only (~2 min) against the committed IBM rows. Reports movement and agreement separately; exits non-zero on lost agreement. |
| `run.R` | Runs `fleet` and the IBM replicates on a PSOCK cluster; writes `results/rep_{eq,age,monthly,doy,timing}.csv` and `results/ibm_reference.json`. Ten workers by default; `CMP_WORKERS=4` sets fewer. |
| `render.R` | Draws every `cmp_*.png` from the saved CSVs (no model runs) into `man/figures/` and `vignettes/`. |
| `tables.R` | The numbers quoted in the articles, as markdown in `results/tables.md`. |
| `benchmark.R` | Indicative `fleet` run times; writes `results/timing.csv`. ~6 min. |
| `results/` | The committed summaries and their provenance stamps. |

Shared code lives outside this directory. The scenario definitions, `run_fleet()`
and the shared summariser are in `validations/_shared/scenarios.R`; the plot
theme is in `validations/_shared/theme.R`. Both are *runner* code, not package
code: they attach `malariasimulation` and the plotting stack at load time, which
a package may not do. The constants every script must agree on — `BURN_Y`,
`POP`, `N_REP`, `EIR_GRID`, the age bands, the intervention labels — are package
code in `R/constants.R` and are exported, so a script gets them from
`fleetcheck` rather than by sourcing a path.

## Checking a change: don't re-run the IBM

The IBM does not depend on `fleet`, so its committed rows stay valid for any
`fleet`-side change. Re-run `fleet` alone and compare:

```bash
Rscript validations/02-scenarios/assess.R                      # ~2 min, exits 1 on lost agreement
CMP_ONLY=eir_20,smc Rscript validations/02-scenarios/assess.R  # a subset, ~20 s
CMP_STRICT=1 Rscript validations/02-scenarios/assess.R         # also fail if ANY value moved
```

It answers two questions separately, because they mean different things.
**Did anything move?** `fleet` now against `fleet`'s committed rows: a moved
number is not automatically wrong — a deliberate model fix moves numbers — but it
must be seen, and silent movement is how a regression ships. **Is the match still
good?** `fleet` now against the committed IBM medians and 10–90% bands, at the
thresholds the register's claims rest on. Only the second one fails the run by
default.

If the movement was intended, refresh the committed `fleet` rows without touching
the IBM:

```bash
CMP_FLEET_ONLY=1 Rscript validations/02-scenarios/run.R   # ~1 min
```

## When the IBM *does* need re-running

Only when the reference itself goes stale, which `assess.R` tells you about
rather than leaving you to remember. `results/ibm_reference.json` records the
date, the `malariasimulation` version, `N_REP`/`POP`/burn-in, and a digest of the
scenario definitions (every parameter that differs from a bare
`get_parameters()`, plus each EIR and horizon). The check warns when the
installed `malariasimulation` or the scenario digest no longer matches.

## Full re-run

Smoke first — every scenario end to end at a 4-year horizon with one replicate,
about two minutes, into `results/smoke/`, which is gitignored and cannot touch
the committed results:

```bash
CMP_SMOKE=1 Rscript validations/02-scenarios/run.R
```

Then:

```bash
Rscript validations/02-scenarios/run.R      # ~25 min on 10 workers; re-stamps ibm_reference.json
Rscript validations/02-scenarios/render.R   # seconds
Rscript validations/02-scenarios/tables.R   # seconds
Rscript report/make_scoreboard.R            # if any measured value in claims.yml changed
```

No paths are hardcoded: each script finds the checkout root by walking up to the
`DESCRIPTION`, so it runs from any working directory, via `Rscript` or `source()`.
The repository README lists every environment variable.

## Design notes

- **Replicates, not a realisation.** The IBM is always drawn as the median of its
  replicates with a 10–90% band; a single noisy run would misstate both the
  agreement and the disagreement.
- **Pooled rates.** Prevalence and incidence are pooled as `sum(cases) /
  sum(person-time)` over each window, never as a mean of per-day ratios.
- **Fair EIR axis.** The IBM's `EIR_<species>` is total infectious bites per day;
  `/ population * 365` recovers `fleet`'s per-adult-per-year convention.
- **Rendering cost.** The IBM's per-band output rendering dominates its run time,
  so only the reference (EIR 20) and demography scenarios carry the 12-band age
  profile; every other scenario renders just the default 2–10 y prevalence and
  0–5 y incidence bands.
- **Stored precision.** `run.R` rounds to six significant figures as it writes,
  except `rep_eq.csv`, which `assess.R` asserts against at 1e-6.
- **Greyscale/CVD-safe figures.** Colour, line type and point shape all encode
  the model; text never wears a series colour.
