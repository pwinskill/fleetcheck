# 01-seed-stability

Does an undisturbed run hold the equilibrium it was seeded at?

```
Rscript validations/01-seed-stability/run.R      # seconds, fleet only
```

Default parameters, seeded by `set_equilibrium()` at EIR 20 and run for 15
years with nothing deployed. The seed is `malariaEquilibrium`'s continuous-time
solution, which is not exactly fleet's own fixed point, so the run moves off
it; the `seed-stability` claim bounds how far. `run.R` measures PfPR(2-10)'s
largest departure from its seeded value, its departure at the end, and its range
over the last five years, and writes them with a provenance stamp to
`results/seed_stability.json`, which is committed.
