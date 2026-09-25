# 01-seed-stability

Does an undisturbed run hold the equilibrium it was seeded at?

```
Rscript validations/01-seed-stability/run.R      # a few minutes, fleet only
```

Default parameters, seeded by `set_equilibrium()` at EIR 20 and run for 15
years with nothing deployed. The seed is `malariaEquilibrium`'s continuous-time
solution, which is not exactly fleet's own fixed point, so the run moves off
it; the `seed-stability` claim bounds how far. `run.R` measures PfPR(2-10)'s
largest departure from its seeded value, its departure at the end, and its range
over the last five years, and writes them with a provenance stamp to
`results/seed_stability.json`, which is committed.

The same script runs a *P. vivax* list at EIR 0.3, 1, 3 and 10 for thirty years,
and the same at EIR 3 with `immunity_spread = FALSE`, and writes
`results/seed_stability_pv.json`. The vivax seed is neither model's fixed point
-- `malariaEquilibriumVivax` has no spread of immunity within a cell, which both
models build up -- so `seed-stability-pv` asks that each run settles, PvPR flat
to under 1% over its last five years, and reports how far it moved on
prevalence, clinical incidence and the realised EIR. The no-spread control is
the evidence for why: without the spread the run holds its seed.
