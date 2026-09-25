# Validation evidence: P. vivax

How closely does `fleet` reproduce `malariasimulation` for *P. vivax*?
The same questions as [for *P.
falciparum*](https://pwinskill.github.io/fleetcheck/articles/evidence.md),
for a `get_parameters(parasite = "vivax")` list: on vivax’s own
transmission grid, EIR 0.3 to 30, with radical cure, by primaquine and
by tafenoquine, in place of the chemoprevention `malariasimulation`
cannot run under vivax and the vaccine it has no vivax calibration for.
`malariasimulation`’s vivax model has no severe disease, so there are no
severe claims. Two claims are vivax’s own: relapse incidence and the
share of people carrying hypnozoites. The site-file comparison of tier 3
is not yet part of the vivax evidence.

One thing bears on the verdicts below. `malariasimulation` 3.0.0
evaluates vivax relapses only on days when at least one person is
bitten, so on a day with no infectious bite anywhere the IBM loses every
relapse, which `fleet` keeps. In the scenario suite’s 10,000-person runs
such days are common under indoor residual spraying, and below an EIR of
about 0.14 whatever is deployed; `intervention-impact-pv` sets out what
that does to the comparison.

Every section is generated from `claims.yml`, so this page cannot
disagree with the register, and the register cannot be changed without
the page following.

**10 claims — 2 failing, 0 untested, 0 open, 8 pass.**

| claim | tier | criterion | measured | verdict |
|----|----|----|----|----|
| [`prevalence-eir-pv`](#prevalence-eir-pv) | 2 | inside the IBM replicate band at every EIR on the grid | inside at 5 of 5; largest departure 1.8% of the IBM median, at EIR 3 | pass |
| [`clinical-allage-eir-pv`](#clinical-allage-eir-pv) | 2 | inside the IBM replicate band at every EIR on the grid | inside at 5 of 5; largest departure 1.7% of the IBM median, at EIR 1 | pass |
| [`clinical-under5-eir-pv`](#clinical-under5-eir-pv) | 2 | inside the IBM replicate band at every EIR on the grid | inside at 5 of 5; largest departure 1.9% of the IBM median, at EIR 0.3 | pass |
| [`relapse-allage-eir-pv`](#relapse-allage-eir-pv) | 2 | inside the IBM replicate band at every EIR on the grid | inside at 5 of 5; largest departure 3.2% of the IBM median, at EIR 0.3, and within 1.1% from EIR 1 up | pass |
| [`hypnozoite-carriage-eir-pv`](#hypnozoite-carriage-eir-pv) | 2 | inside the IBM replicate band at every EIR on the grid | inside at 5 of 5; largest departure 3.1% of the IBM median, at EIR 0.3, and within 0.8% from EIR 1 up | pass |
| [`age-profile-clinical-pv`](#age-profile-clinical-pv) | 2 | inside the IBM replicate band in every age band carrying at least 5% of clinical episodes, at EIR 1, 3 and 10 | inside at 23 of 23 tested bands across the three EIRs, holding 90% of episodes; largest departure 1.21 replicate SD, in the 3-5 y band at EIR 10 | pass |
| [`intervention-impact-pv`](#intervention-impact-pv) | 2 | outside the IBM replicate band in no greater a share of cells than the best held-out IBM replicate, over every intervention and outcome at EIR 1, 3 and 10 | fleet outside in 26.7% of 60 cells, against 8.3% for the closest of the twenty IBM replicates and 24.2% for the median one | FAIL |
| [`population-age-structure-pv`](#population-age-structure-pv) | 2 | inside the IBM replicate band in every age band below 60 years, on shares renormalised to the 0-60 population | inside at 11 of 11 at EIR 3; largest departure 2.1% of the IBM median | pass |
| [`speed-pv`](#speed-pv) | 2 | at least 10x faster than the IBM on the same scenario set | 0.41x on cost per simulated year; 9.5 CPU-hours for the IBM’s 440 runs against 69 minutes for fleet’s 22 | FAIL |
| [`seed-stability-pv`](#seed-stability-pv) | 1 | PvPR(2-10) flat to under 1% over the last five of 30 years, at EIR 0.3, 1, 3 and 10 | flat to 0.27% at EIR 0.3, 0.08% at 1, 0.007% at 3 and 0.001% at 10; settling 14%, 9%, 5% and 2% above the seeded PvPR | pass |

## prevalence-eir-pv

pass — LM prevalence in 2-10 year olds tracks the IBM across
transmission intensity.

**Criterion:** inside the IBM replicate band at every EIR on the grid  
**Measured:** inside at 5 of 5; largest departure 1.8% of the IBM
median, at EIR 3

tier 2 · `validations/02-scenarios`

[![LM prevalence in 2-10 year olds tracks the IBM across transmission
intensity. Verdict:
pass.](cmp_pv_eir_pvpr_2_10.png)](https://pwinskill.github.io/fleetcheck/articles/cmp_pv_eir_pvpr_2_10.png)

## clinical-allage-eir-pv

pass — All-age clinical incidence tracks the IBM across transmission
intensity.

**Criterion:** inside the IBM replicate band at every EIR on the grid  
**Measured:** inside at 5 of 5; largest departure 1.7% of the IBM
median, at EIR 1

tier 2 · `validations/02-scenarios`

[![All-age clinical incidence tracks the IBM across transmission
intensity. Verdict:
pass.](cmp_pv_eir_clin_all.png)](https://pwinskill.github.io/fleetcheck/articles/cmp_pv_eir_clin_all.png)

fleet sits 1.1 to 1.7% above the IBM median at every EIR from 1 up, a
small offset of one sign, inside the band throughout. Part of it is the
school-age excess of immunity sorting within cells, which fleet’s one
immunity distribution per cell does not carry (vignette(“model”, package
= “fleet”), V.7).

## clinical-under5-eir-pv

pass — Under-5 clinical incidence tracks the IBM across transmission
intensity.

**Criterion:** inside the IBM replicate band at every EIR on the grid  
**Measured:** inside at 5 of 5; largest departure 1.9% of the IBM
median, at EIR 0.3

tier 2 · `validations/02-scenarios`

[![Under-5 clinical incidence tracks the IBM across transmission
intensity. Verdict:
pass.](cmp_pv_eir_clin_0_5.png)](https://pwinskill.github.io/fleetcheck/articles/cmp_pv_eir_clin_0_5.png)

## relapse-allage-eir-pv

pass — All-age relapse incidence tracks the IBM across transmission
intensity.

**Criterion:** inside the IBM replicate band at every EIR on the grid  
**Measured:** inside at 5 of 5; largest departure 3.2% of the IBM
median, at EIR 0.3, and within 1.1% from EIR 1 up

tier 2 · `validations/02-scenarios`

[![All-age relapse incidence tracks the IBM across transmission
intensity. Verdict:
pass.](cmp_pv_eir_relapse_all.png)](https://pwinskill.github.io/fleetcheck/articles/cmp_pv_eir_relapse_all.png)

Relapses are counted over everyone and divided by the 0-100 band’s
population, which in the IBM leaves out its 0.7% over 100 and in fleet
holds everyone, so fleet reads about 0.7% low by construction; most of
its shortfall from EIR 1 up is that. Dividing both by the whole
population wants the IBM rows re-summarised, at the vivax suite’s next
IBM run.

## hypnozoite-carriage-eir-pv

pass — The share of people carrying hypnozoites tracks the IBM across
transmission intensity.

**Criterion:** inside the IBM replicate band at every EIR on the grid  
**Measured:** inside at 5 of 5; largest departure 3.1% of the IBM
median, at EIR 0.3, and within 0.8% from EIR 1 up

tier 2 · `validations/02-scenarios`

[![The share of people carrying hypnozoites tracks the IBM across
transmission intensity. Verdict:
pass.](cmp_pv_eir_hyp_all.png)](https://pwinskill.github.io/fleetcheck/articles/cmp_pv_eir_hyp_all.png)

At EIR 30 fleet is 0.76% below the IBM median, against a band 0.79%
wide, and nearly all of that is the denominator of
relapse-allage-eir-pv: carriage is counted over everyone and divided by
the 0-100 band, which in the IBM leaves out the 0.7% over 100.

## age-profile-clinical-pv

pass — The age distribution of clinical incidence tracks the IBM.

**Criterion:** inside the IBM replicate band in every age band carrying
at least 5% of clinical episodes, at EIR 1, 3 and 10  
**Measured:** inside at 23 of 23 tested bands across the three EIRs,
holding 90% of episodes; largest departure 1.21 replicate SD, in the 3-5
y band at EIR 10

tier 2 · `validations/02-scenarios`

[![The age distribution of clinical incidence tracks the IBM. Verdict:
pass.](cmp_pv_age_clin.png)](https://pwinskill.github.io/fleetcheck/articles/cmp_pv_age_clin.png)

No untested band is outside either. fleet sits above the IBM median in
most school-age bands, the offset of clinical-allage-eir-pv, where
immunity sorting within cells leaves the mean field a little high
(vignette(“model”, package = “fleet”), V.7).

## intervention-impact-pv

FAIL — The modelled impact of each intervention, radical cure included,
matches the IBM.

**Criterion:** outside the IBM replicate band in no greater a share of
cells than the best held-out IBM replicate, over every intervention and
outcome at EIR 1, 3 and 10  
**Measured:** fleet outside in 26.7% of 60 cells, against 8.3% for the
closest of the twenty IBM replicates and 24.2% for the median one

tier 2 · `validations/02-scenarios`

[![The modelled impact of each intervention, radical cure included,
matches the IBM. Verdict:
fail.](cmp_pv_int_impact.png)](https://pwinskill.github.io/fleetcheck/articles/cmp_pv_int_impact.png)

Twelve of the sixteen cells outside are indoor residual spraying, and
there most of the distance is a defect in malariasimulation 3.0.0. The
IBM evaluates vivax infections, relapses included, only on days when at
least one person receives an infectious bite: simulate_infection()
returns early on an empty bitten set, which is right for falciparum and
wrong for a relapse, which needs no bite. Spraying makes days with no
infectious bite across the whole 10,000-person population common, every
relapse is lost on them, and the IBM eliminates vivax – every replicate
at EIR 1 and 3, 13 of 20 at EIR 10 – where fleet, relapsing every day,
keeps it. The other four are bed nets at EIR 1, where the IBM’s nets cut
every outcome 6 to 9 points more than fleet’s: nets kill mosquitoes as
well as deflecting them, and at EIR 1 that leaves days with no
infectious bite too. A patched copy of malariasimulation that evaluates
relapses every day brought the IBM’s reductions under spraying at EIR 3
and 10 and under nets at EIR 1 within 2.5 points of fleet’s, from up to
20 points away; that check was made against fleet’s earlier,
continuous-time model and is not yet reproduced by a script here.
Without the spraying scenarios fleet is outside in 8.3% of 48 cells,
against 4.2% for the closest IBM replicate. Radical cure, by primaquine
and by tafenoquine, agrees inside the band in every cell, as do
treatment scale-up and bed nets at EIR 3 and 10.

## population-age-structure-pv

pass — The population age structure matches the IBM’s.

**Criterion:** inside the IBM replicate band in every age band below 60
years, on shares renormalised to the 0-60 population  
**Measured:** inside at 11 of 11 at EIR 3; largest departure 2.1% of the
IBM median

tier 2 · `validations/02-scenarios`

[![The population age structure matches the IBM's. Verdict:
pass.](cmp_pv_pop_age.png)](https://pwinskill.github.io/fleetcheck/articles/cmp_pv_pop_age.png)

The vivax population ages and dies through compartments of its own, so
its denominator is checked apart from falciparum’s, under the same 0-60
convention.

## speed-pv

FAIL — fleet is fast enough to be worth using in place of the IBM.

**Criterion:** at least 10x faster than the IBM on the same scenario
set  
**Measured:** 0.41x on cost per simulated year; 9.5 CPU-hours for the
IBM’s 440 runs against 69 minutes for fleet’s 22

tier 2 · `validations/02-scenarios`

*No figure: the numbers above decide this claim.*

Per run, vivax fleet is the slower model: 3.9 s per simulated year
against 2.1 s for a 10,000-person IBM run, both on a shared worker pool.
The hypnozoite dimension and the within-cell immunity spread make it
about twenty times a falciparum fleet run on the same 209-group grid,
while the IBM costs about the same for either parasite. One fleet run
still stands in for the twenty IBM replicates the comparison needs, and
fleet’s cost does not grow with population, so the IBM arm here cost 8.3
times fleet’s; but the criterion is per run, and per run fleet does not
meet it. On one laptop core a vivax run takes about 20 s per 10
simulated years, 50 s with primaquine radical cure and 85 s with
tafenoquine; a 53-group grid runs about four times as fast.

## seed-stability-pv

pass — An undisturbed run settles to a steady state, off the equilibrium
it was seeded at, as the IBM’s does.

**Criterion:** PvPR(2-10) flat to under 1% over the last five of 30
years, at EIR 0.3, 1, 3 and 10  
**Measured:** flat to 0.27% at EIR 0.3, 0.08% at 1, 0.007% at 3 and
0.001% at 10; settling 14%, 9%, 5% and 2% above the seeded PvPR

tier 1 · `validations/01-seed-stability`

*No figure: the numbers above decide this claim.*

The criterion is settling rather than holding the seed, because the
vivax seed is neither model’s fixed point. malariaEquilibriumVivax
solves each age, heterogeneity and batch cell with one immunity value,
where both models build up a spread of immunity within a cell from the
first day, and the vivax immunity curves are steep enough for that to
move everything: over the four EIRs fleet’s clinical incidence settles
15 to 21% above the seed and its realised EIR 4 to 17% above init_EIR,
PvPR overshooting first at the lowest EIRs (20.7% at EIR 0.3). The IBM
moves as far: in the tier-2 runs its realised EIR ends 18%, 13% and 8%
above init_EIR at EIR 0.3, 1 and 3, against fleet’s 17%, 13% and 9%. The
control says why: with immunity_spread = FALSE fleet holds its seed at
EIR 3 to within 1.3%. So every vivax comparison is made after a 30-year
burn-in in both models – long enough at EIR 0.3, where settling takes
over two decades – and a vivax run started from set_equilibrium() wants
one. validations/01-seed-stability/run.R reproduces the figures.

## What “tier” means

The same as [for *P.
falciparum*](https://pwinskill.github.io/fleetcheck/articles/evidence.html#what-tier-means):
what a result costs to reproduce, recorded against each claim. The costs
are vivax’s own.

| tier | cost          | who can reproduce it         |
|------|---------------|------------------------------|
| 1    | a few minutes | anyone; re-runs `fleet` only |
| 2    | about an hour | anyone with about ten cores  |
