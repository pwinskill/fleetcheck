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

**10 claims — 3 failing, 0 untested, 0 open, 7 pass.**

| claim | tier | criterion | measured | verdict |
|----|----|----|----|----|
| [`prevalence-eir-pv`](#prevalence-eir-pv) | 2 | inside the IBM replicate band at every EIR on the grid | inside at 5 of 5; largest departure 2.0% of the IBM median, at EIR 3 | pass |
| [`clinical-allage-eir-pv`](#clinical-allage-eir-pv) | 2 | inside the IBM replicate band at every EIR on the grid | inside at 5 of 5; largest departure 2.0% of the IBM median, at EIR 1 | pass |
| [`clinical-under5-eir-pv`](#clinical-under5-eir-pv) | 2 | inside the IBM replicate band at every EIR on the grid | inside at 5 of 5; largest departure 2.4% of the IBM median, at EIR 0.3 | pass |
| [`relapse-allage-eir-pv`](#relapse-allage-eir-pv) | 2 | inside the IBM replicate band at every EIR on the grid | inside at 5 of 5; largest departure 2.7% of the IBM median, at EIR 0.3, and within 0.8% from EIR 1 up | pass |
| [`hypnozoite-carriage-eir-pv`](#hypnozoite-carriage-eir-pv) | 2 | inside the IBM replicate band at every EIR on the grid | inside at 5 of 5; largest departure 2.6% of the IBM median, at EIR 0.3, and within 0.7% from EIR 1 up | pass |
| [`age-profile-clinical-pv`](#age-profile-clinical-pv) | 2 | inside the IBM replicate band in every age band carrying at least 5% of clinical episodes, at EIR 1, 3 and 10 | inside at 22 of 23 tested bands across the three EIRs, holding 90% of episodes; largest departure 1.30 replicate SD, in the 3-5 y band at EIR 10 | FAIL |
| [`intervention-impact-pv`](#intervention-impact-pv) | 2 | outside the IBM replicate band in no greater a share of cells than the best held-out IBM replicate, over every intervention and outcome at EIR 1, 3 and 10 | fleet outside in 26.7% of 60 cells, against 8.3% for the closest of the twenty IBM replicates and 24.2% for the median one | FAIL |
| [`population-age-structure-pv`](#population-age-structure-pv) | 2 | inside the IBM replicate band in every age band below 60 years, on shares renormalised to the 0-60 population | inside at 11 of 11 at EIR 3; largest departure 2.1% of the IBM median | pass |
| [`speed-pv`](#speed-pv) | 2 | at least 10x faster per simulated year than one IBM run of 10,000 people, each timed alone on one core, at EIR 1, 3 and 10, with nothing deployed and with a seasonal programme | 0.6x to 1.7x per simulated year at 10,000 people, 2.1x to 4.7x at 50,000; fleet 0.83 to 2.1 s per simulated year, the IBM 1.2 to 1.6 s at 10,000 people | FAIL |
| [`seed-stability-pv`](#seed-stability-pv) | 1 | PvPR(2-10) flat to under 1% over the last five of 30 years, at EIR 0.3, 1, 3 and 10 | flat to 0.27% at EIR 0.3, 0.09% at 1, 0.007% at 3 and 0.001% at 10; settling 15%, 10%, 6% and 3% above the seeded PvPR | pass |

## prevalence-eir-pv

pass — LM prevalence in 2-10 year olds tracks the IBM across
transmission intensity.

**Criterion:** inside the IBM replicate band at every EIR on the grid  
**Measured:** inside at 5 of 5; largest departure 2.0% of the IBM
median, at EIR 3

tier 2 · `validations/02-scenarios`

[![LM prevalence in 2-10 year olds tracks the IBM across transmission
intensity. Verdict:
pass.](cmp_pv_eir_pvpr_2_10.png)](https://pwinskill.github.io/fleetcheck/articles/cmp_pv_eir_pvpr_2_10.png)

## clinical-allage-eir-pv

pass — All-age clinical incidence tracks the IBM across transmission
intensity.

**Criterion:** inside the IBM replicate band at every EIR on the grid  
**Measured:** inside at 5 of 5; largest departure 2.0% of the IBM
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
**Measured:** inside at 5 of 5; largest departure 2.4% of the IBM
median, at EIR 0.3

tier 2 · `validations/02-scenarios`

[![Under-5 clinical incidence tracks the IBM across transmission
intensity. Verdict:
pass.](cmp_pv_eir_clin_0_5.png)](https://pwinskill.github.io/fleetcheck/articles/cmp_pv_eir_clin_0_5.png)

## relapse-allage-eir-pv

pass — All-age relapse incidence tracks the IBM across transmission
intensity.

**Criterion:** inside the IBM replicate band at every EIR on the grid  
**Measured:** inside at 5 of 5; largest departure 2.7% of the IBM
median, at EIR 0.3, and within 0.8% from EIR 1 up

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
**Measured:** inside at 5 of 5; largest departure 2.6% of the IBM
median, at EIR 0.3, and within 0.7% from EIR 1 up

tier 2 · `validations/02-scenarios`

[![The share of people carrying hypnozoites tracks the IBM across
transmission intensity. Verdict:
pass.](cmp_pv_eir_hyp_all.png)](https://pwinskill.github.io/fleetcheck/articles/cmp_pv_eir_hyp_all.png)

At EIR 30 fleet is 0.67% below the IBM median, against a band 0.79%
wide, and nearly all of that is the denominator of
relapse-allage-eir-pv: carriage is counted over everyone and divided by
the 0-100 band, which in the IBM leaves out the 0.7% over 100.

## age-profile-clinical-pv

FAIL — The age distribution of clinical incidence tracks the IBM.

**Criterion:** inside the IBM replicate band in every age band carrying
at least 5% of clinical episodes, at EIR 1, 3 and 10  
**Measured:** inside at 22 of 23 tested bands across the three EIRs,
holding 90% of episodes; largest departure 1.30 replicate SD, in the 3-5
y band at EIR 10

tier 2 · `validations/02-scenarios`

[![The age distribution of clinical incidence tracks the IBM. Verdict:
fail.](cmp_pv_age_clin.png)](https://pwinskill.github.io/fleetcheck/articles/cmp_pv_age_clin.png)

The one band outside is 3-5 y at EIR 10, where fleet’s 2.229 episodes
per child-year sit 4.3% above the IBM median of 2.137, 0.02 replicate SD
beyond the edge. Most of that is the offset of clinical-allage-eir-pv:
fleet sits above the IBM median in most school-age bands, where immunity
sorting within cells leaves the mean field a little high
(vignette(“model”, package = “fleet”), V.7). The rest is the age grid:
the default’s 118 groups, set by the falciparum claims, put 0.3% more on
that band than 209 groups did, where it passed at 1.21 SD. No untested
band is outside.

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

**Criterion:** at least 10x faster per simulated year than one IBM run
of 10,000 people, each timed alone on one core, at EIR 1, 3 and 10, with
nothing deployed and with a seasonal programme  
**Measured:** 0.6x to 1.7x per simulated year at 10,000 people, 2.1x to
4.7x at 50,000; fleet 0.83 to 2.1 s per simulated year, the IBM 1.2 to
1.6 s at 10,000 people

tier 2 · `validations/02-scenarios`

Seconds per simulated year; in brackets, the IBM’s multiple of fleet’s
time.

| setting            | EIR | fleet |  IBM 10,000 |  IBM 30,000 |  IBM 50,000 |
|:-------------------|----:|------:|------------:|------------:|------------:|
| nothing deployed   |   1 |  0.83 | 1.18 (1.4×) | 2.22 (2.7×) | 3.34 (4.0×) |
|                    |   3 |  0.94 | 1.44 (1.5×) | 2.63 (2.8×) | 3.70 (3.9×) |
|                    |  10 |  0.94 | 1.56 (1.7×) | 3.01 (3.2×) | 4.39 (4.7×) |
| seasonal programme |   1 |  1.97 | 1.38 (0.7×) | 2.71 (1.4×) | 4.49 (2.3×) |
|                    |   3 |  2.10 | 1.28 (0.6×) | 2.71 (1.3×) | 4.41 (2.1×) |
|                    |  10 |  2.05 | 1.17 (0.6×) | 3.48 (1.7×) | 5.13 (2.5×) |

One run of each model, alone on one core (Snapdragon X 12-core X1E80100
@ 3.40 GHz), over 10 years from set_equilibrium()’s seed, start-up
excluded: fleet’s takes 0.67 to 1.5 s, the IBM’s 3.5 to 3.9 s at 10,000
people and 7.7 to 8.4 s at 50,000. fleet’s cost does not depend on the
population. The seasonal programme is case management with chloroquine
and primaquine radical cure, bed nets and indoor spraying, running from
the first day. `CMP_PARASITE=pv validations/02-scenarios/speed.R` makes
this table.

Each run in the table starts from set_equilibrium()’s seed and is timed
alone, start-up apart. Each fleet figure is one complete
run_simulation_ode() call, the fastest of two. With nothing deployed a
vivax fleet run costs 10 to 12 times a falciparum one, for the
hypnozoite dimension and the within-cell immunity spread, and the
programme more than doubles it, mostly through primaquine radical cure’s
liver-stage levels. The IBM costs a little less for vivax than for
falciparum. So at 10,000 people fleet is 1.4 to 1.7 times faster with
nothing deployed, and slower than the IBM under the programme. Its cost
does not grow with the population, so at 50,000 people it is 2.1 to 4.7
times faster. One fleet run also stands in for the twenty replicates an
IBM comparison needs: across the vivax scenario suite, whose IBM runs
share a worker pool, the IBM takes 9.5 CPU-hours and fleet 26 minutes.

## seed-stability-pv

pass — An undisturbed run settles to a steady state, off the equilibrium
it was seeded at, as the IBM’s does.

**Criterion:** PvPR(2-10) flat to under 1% over the last five of 30
years, at EIR 0.3, 1, 3 and 10  
**Measured:** flat to 0.27% at EIR 0.3, 0.09% at 1, 0.007% at 3 and
0.001% at 10; settling 15%, 10%, 6% and 3% above the seeded PvPR

tier 1 · `validations/01-seed-stability`

*No figure: the numbers above decide this claim.*

The criterion is settling rather than holding the seed, because the
vivax seed is neither model’s fixed point. malariaEquilibriumVivax
solves each age, heterogeneity and batch cell with one immunity value,
where both models build up a spread of immunity within a cell from the
first day, and the vivax immunity curves are steep enough for that to
move everything: over the four EIRs fleet’s clinical incidence settles
16 to 22% above the seed and its realised EIR 5 to 18% above init_EIR,
PvPR overshooting first at the lowest EIRs (21.5% at EIR 0.3). The IBM
moves as far: in the tier-2 runs its realised EIR ends 18%, 13% and 8%
above init_EIR at EIR 0.3, 1 and 3, against fleet’s 18%, 14% and 9%. The
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
