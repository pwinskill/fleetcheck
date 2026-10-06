# Validation evidence: P. falciparum

How closely does `fleet` reproduce `malariasimulation` for *P.
falciparum*? Each claim below states the criterion that decides it, the
value measured against that criterion, and a verdict. The order runs
from transmission through clinical and severe burden to their age
distributions, then interventions, real settings and the parameter
posterior, with the demographic, performance and numerical checks that
underwrite them at the end. The *P. vivax* claims are on [a page of
their
own](https://pwinskill.github.io/fleetcheck/articles/evidence-vivax.md).

Every section is generated from `claims.yml`, so this page cannot
disagree with the register, and the register cannot be changed without
the page following.

**12 claims — 0 failing, 0 untested, 1 open, 11 pass.**

| claim | tier | criterion | measured | verdict |
|----|----|----|----|----|
| [`prevalence-eir`](#prevalence-eir) | 2 | inside the IBM replicate band at every EIR on the grid | inside at 6 of 6; largest departure 1.1% of the IBM median, at EIR 3 | pass |
| [`clinical-allage-eir`](#clinical-allage-eir) | 2 | inside the IBM replicate band at every EIR on the grid | inside at 6 of 6; largest departure 1.8% of the IBM median, at EIR 1, and within 1.5% from EIR 3 up | pass |
| [`clinical-under5-eir`](#clinical-under5-eir) | 2 | inside the IBM replicate band at every EIR on the grid | inside at 6 of 6; largest departure 1.1% of the IBM median, at EIR 120 | pass |
| [`severe-allage-eir`](#severe-allage-eir) | 2 | inside the IBM replicate band at every EIR on the grid | inside at 6 of 6; largest departure 2.2% of the IBM median, at EIR 120 | pass |
| [`age-profile-clinical`](#age-profile-clinical) | 2 | inside the IBM replicate band in every age band carrying at least 5% of clinical episodes, at EIR 3, 20 and 120 | inside at 25 of 25 tested bands across the three EIRs, holding 94% of episodes; largest departure 1.24 replicate SD, in the 3-5 y band at EIR 120 | pass |
| [`age-profile-severe`](#age-profile-severe) | 2 | inside the IBM replicate band in every age band carrying at least 5% of severe episodes, at EIR 3, 20 and 120 | inside at 16 of 16 tested bands across the three EIRs, holding 94% of episodes; largest departure 0.78 replicate SD, in the 1-2 y band at EIR 20 | pass |
| [`intervention-impact`](#intervention-impact) | 2 | outside the IBM replicate band in no greater a share of cells than the best held-out IBM replicate, over every intervention and outcome at EIR 3, 20 and 120 (SMC in a seasonal setting, since it is a seasonal intervention) | fleet outside in 2.8% of 72 cells, against 9.7% for the closest of the twenty IBM replicates and 20.1% for the median one | pass |
| [`real-settings-correlation`](#real-settings-correlation) | 3 | r \> 0.95 and \|slope - 1\| \< 0.10 on both clinical and severe incidence | clinical r 0.983 slope 0.983; severe r 0.958 slope 0.927, over 451,008 sub-site-months in 1,392 sub-sites of 63 countries | pass |
| [`parameter-draws`](#parameter-draws) | 2 | each draw’s change from the default parameters inside the IBM replicate band of that change, for eight posterior draws chosen at EIR 20 to span all-age clinical and severe incidence, at EIR 3, 20 and 120, on LM prevalence 2-10, clinical incidence under 5 and at all ages, and severe incidence at all ages | inside at 96 of 96; largest departure 0.66 replicate SD, all-age severe incidence at draw 260 and EIR 120; fleet’s changes against the IBM’s slope 1.01, r 0.997; against the IBM’s mean changes, severe incidence is off by 1.7 points RMS beyond the IBM’s noise (p \< 0.001), prevalence and clinical incidence are not | open |
| [`population-age-structure`](#population-age-structure) | 2 | inside the IBM replicate band in every age band below 60 years, on shares renormalised to the 0-60 population | inside at 11 of 11; largest departure 1.3% of the IBM median | pass |
| [`speed`](#speed) | 2 | at least 10x faster than the IBM on the same scenario set | 44x on cost per simulated year; 19.9 CPU-hours for the IBM against 82 s for fleet | pass |
| [`seed-stability`](#seed-stability) | 1 | PfPR(2-10) departs from its seeded value by less than 1% over 15 years at EIR 20 | 0.35% maximum excursion; flat to 0.007% over the last five years | pass |

## prevalence-eir

pass — LM prevalence in 2-10 year olds tracks the IBM across
transmission intensity.

**Criterion:** inside the IBM replicate band at every EIR on the grid  
**Measured:** inside at 6 of 6; largest departure 1.1% of the IBM
median, at EIR 3

tier 2 · `validations/02-scenarios`

[![LM prevalence in 2-10 year olds tracks the IBM across transmission
intensity. Verdict:
pass.](cmp_eir_pfpr_2_10.png)](https://pwinskill.github.io/fleetcheck/articles/cmp_eir_pfpr_2_10.png)

## clinical-allage-eir

pass — All-age clinical incidence tracks the IBM across transmission
intensity.

**Criterion:** inside the IBM replicate band at every EIR on the grid  
**Measured:** inside at 6 of 6; largest departure 1.8% of the IBM
median, at EIR 1, and within 1.5% from EIR 3 up

tier 2 · `validations/02-scenarios`

[![All-age clinical incidence tracks the IBM across transmission
intensity. Verdict:
pass.](cmp_eir_clin_all.png)](https://pwinskill.github.io/fleetcheck/articles/cmp_eir_clin_all.png)

The age grid’s first-order discretisation error grows with transmission:
on the default 118 groups fleet runs 0.4% to 1.5% below the IBM median
from EIR 10 up, furthest at EIR 120. A coarser grid runs lower:
default_age_lower(n_group = 53), at under half the cost, puts fleet 3.1%
and 4.1% below the IBM median at EIR 50 and 120, outside the band.
validations/age-grid measures the grid’s share.

## clinical-under5-eir

pass — Under-5 clinical incidence tracks the IBM across transmission
intensity.

**Criterion:** inside the IBM replicate band at every EIR on the grid  
**Measured:** inside at 6 of 6; largest departure 1.1% of the IBM
median, at EIR 120

tier 2 · `validations/02-scenarios`

[![Under-5 clinical incidence tracks the IBM across transmission
intensity. Verdict:
pass.](cmp_eir_clin_0_5.png)](https://pwinskill.github.io/fleetcheck/articles/cmp_eir_clin_0_5.png)

On 53 age groups fleet runs 3.9% below the IBM median at EIR 120,
outside the band; see clinical-allage-eir.

## severe-allage-eir

pass — All-age severe incidence tracks the IBM across transmission
intensity.

**Criterion:** inside the IBM replicate band at every EIR on the grid  
**Measured:** inside at 6 of 6; largest departure 2.2% of the IBM
median, at EIR 120

tier 2 · `validations/02-scenarios`

[![All-age severe incidence tracks the IBM across transmission
intensity. Verdict:
pass.](cmp_eir_sev_all.png)](https://pwinskill.github.io/fleetcheck/articles/cmp_eir_sev_all.png)

Severe incidence is where the age grid shows most: theta sits on the
convex tail of its Hill function from early childhood, and a group’s
severe incidence is evaluated at its mean immunity, so the error is
first order in the group width. On the default 118 groups fleet runs
0.7% to 2.2% below the IBM median from EIR 3 to 120, growing with
transmission as the grid’s error does; on 53 groups, from 2.5% at EIR 3
to 6.8% at EIR 120. Severe has the widest replicate spread here, which
is what sets the twenty-replicate count; a band test cannot see an
offset repeated at every point, which is why the offsets are given.

## age-profile-clinical

pass — The age distribution of clinical incidence tracks the IBM.

**Criterion:** inside the IBM replicate band in every age band carrying
at least 5% of clinical episodes, at EIR 3, 20 and 120  
**Measured:** inside at 25 of 25 tested bands across the three EIRs,
holding 94% of episodes; largest departure 1.24 replicate SD, in the 3-5
y band at EIR 120

tier 2 · `validations/02-scenarios`

[![The age distribution of clinical incidence tracks the IBM. Verdict:
pass.](cmp_age_clin.png)](https://pwinskill.github.io/fleetcheck/articles/cmp_age_clin.png)

No untested band is outside either. This is the claim that sets the
default age grid: 118 groups is the smallest on which it passes, with
the 3-5 y band at EIR 120 inside by 0.04 replicate SD. On 53 age groups
6 of the tested bands fall outside, young children at high transmission
with fleet low: the grid’s first-order discretisation error, which
validations/age-grid measures (see clinical-allage-eir). What the burden
floor costs: a defect confined to the oldest ages would not be caught
here.

## age-profile-severe

pass — The age distribution of severe incidence tracks the IBM.

**Criterion:** inside the IBM replicate band in every age band carrying
at least 5% of severe episodes, at EIR 3, 20 and 120  
**Measured:** inside at 16 of 16 tested bands across the three EIRs,
holding 94% of episodes; largest departure 0.78 replicate SD, in the 1-2
y band at EIR 20

tier 2 · `validations/02-scenarios`

[![The age distribution of severe incidence tracks the IBM. Verdict:
pass.](cmp_age_sev.png)](https://pwinskill.github.io/fleetcheck/articles/cmp_age_sev.png)

The burden floor is doing little here: no untested band is outside the
band either. Most of what the floor excludes is above age 30, where the
IBM’s replicate spread is several times its median and agreement is not
evidence of much.

## intervention-impact

pass — The modelled impact of each intervention matches the IBM.

**Criterion:** outside the IBM replicate band in no greater a share of
cells than the best held-out IBM replicate, over every intervention and
outcome at EIR 3, 20 and 120 (SMC in a seasonal setting, since it is a
seasonal intervention)  
**Measured:** fleet outside in 2.8% of 72 cells, against 9.7% for the
closest of the twenty IBM replicates and 20.1% for the median one

tier 2 · `validations/02-scenarios`

[![The modelled impact of each intervention matches the IBM. Verdict:
pass.](cmp_int_impact.png)](https://pwinskill.github.io/fleetcheck/articles/cmp_int_impact.png)

The bar is taken from the IBM because at 72 cells a fixed one cannot be:
a 1.28 SD band leaves a fifth of cells outside by construction, and no
replicate is inside all 72. fleet is outside less often than any of the
twenty. Where fleet does sit outside, the size is small in both senses.
It is outside in two cells, both bed nets, on prevalence at EIR 20 and
120; on all-age clinical incidence at EIR 120 it sits 0.01 points
inside. The worst is prevalence at EIR 120, where the IBM’s bed nets cut
PfPR(2-10) by 27.5% and fleet’s by 25.4%: 2.1 percentage points of the
reduction, 7.7% of the effect, the mark of population-averaged nets,
which lose the correlation of each person’s protection across bites. The
typical gap does not grow with transmission – a median of 0.39, 0.37 and
0.49 percentage points at EIR 3, 20 and 120. Impact is a ratio of two
runs sharing an age grid, so grid discretisation largely divides out:
over twice the groups, 53 to 118, moved the worst excursion by 0.08
points. SMC sends the clinical and detectable cases it treats through
the treated state first, as the IBM does, so prevalence in the dosed
band falls over the Tr stay rather than overnight; its protection is
complete while it lasts, where the IBM’s is partial and fades. Perennial
chemoprevention is the one intervention whose delivery the models cannot
share. The IBM doses each child on reaching a dose age; fleet
approximates that as monthly pulses over a 30-day band, which doses 8 to
21 days late and overstates the infant benefit by about a tenth. The
window is the three years after deployment. Over the arms’ last three
years, against the three before deployment, PMC changes all-age severe
incidence in fleet by -1.1% at EIR 3, +1.7% at EIR 20 and +7.6% at EIR
120: the rebound of delayed immunity, pushing severe disease from
infancy into the second and third years of life. The IBM’s medians have
the same sign at all three (-5.2%, +3.1%, +4.2%), inside replicate bands
too wide to say more.

## real-settings-correlation

pass — Agreement holds across real transmission settings, not just
synthetic scenarios.

**Criterion:** r \> 0.95 and \|slope - 1\| \< 0.10 on both clinical and
severe incidence  
**Measured:** clinical r 0.983 slope 0.983; severe r 0.958 slope 0.927,
over 451,008 sub-site-months in 1,392 sub-sites of 63 countries

tier 3 · `validations/03-real-settings`

[![Agreement holds across real transmission settings, not just synthetic
scenarios. Verdict:
pass.](cmp_core_sites.png)](https://pwinskill.github.io/fleetcheck/articles/cmp_core_sites.png)

r and slope test whether fleet tracks the IBM, not whether it sits on
top of it. Pooled over every sub-site-month fleet runs 7.0% above the
IBM on both clinical and severe incidence, and the excess sits at low
transmission: clinical incidence runs +191% below pf EIR 0.1 and +66%
from 0.1 to 1, falling to -0.6% at 120 and above. 18% of sub-sites sit
below EIR 1, outside any tier-2 claim, and the excess there is not
explained. Guinea-Bissau’s 18 sub-sites, whose IBM runs are anomalous,
sit at +106%. fleet ran every one of the 1,392 sub-sites with P.
falciparum transmission; none is dropped. Monthly, and P. falciparum
only on both arms: annual means can hide a seasonal mismatch, and the
shipped diagnostics carry vivax rows that inflate the baseline where pf
transmission is low.

## parameter-draws

open — The change a posterior parameter draw makes to prevalence,
clinical and severe incidence matches the IBM’s.

**Criterion:** each draw’s change from the default parameters inside the
IBM replicate band of that change, for eight posterior draws chosen at
EIR 20 to span all-age clinical and severe incidence, at EIR 3, 20 and
120, on LM prevalence 2-10, clinical incidence under 5 and at all ages,
and severe incidence at all ages  
**Measured:** inside at 96 of 96; largest departure 0.66 replicate SD,
all-age severe incidence at draw 260 and EIR 120; fleet’s changes
against the IBM’s slope 1.01, r 0.997; against the IBM’s mean changes,
severe incidence is off by 1.7 points RMS beyond the IBM’s noise (p \<
0.001), prevalence and clinical incidence are not

tier 2 · `validations/04-parameter-draws`

[![The change a posterior parameter draw makes to prevalence, clinical
and severe incidence matches the IBM's. Verdict:
open.](cmp_draws.png)](https://pwinskill.github.io/fleetcheck/articles/cmp_draws.png)

set_parameter_draw() replaces 32 core parameters with one of 1,000 draws
from the model fit’s joint posterior. The IBM’s band is the spread of
the change over every pairing of a replicate at the draw with one at the
default parameters (20 x 20); those default-parameter runs are the EIR
grid’s own, so the claim needs no other IBM runs. A ratio of two runs
divides out an offset common to both, as intervention impact does. The
band, the noise of a single pair of runs, reaches about four and a half
standard errors of the IBM’s mean change either side, so it catches
gross errors only. Against the mean changes and their standard errors,
prevalence and clinical incidence agree with the IBM (chi-squared p 0.12
to 0.77 over each outcome’s 24 cells) and severe incidence does not (p =
3e-8): six of the 96 cells sit more than two standard errors from the
IBM, all with fleet low. That is why the claim is open.
validations/04-parameter-draws/diagnose.R finds the cause in uv, the
refractory period between boosts of severe-disease immunity. At the
default parameters with uv alone changed, fleet’s all-age severe
incidence at EIR 120 sits 2.9% below the IBM’s mean at uv 1.67 days,
0.6% below at the default 11.4, and 6.7% above at 35 (5.3 standard
errors), extrapolated to a converged age grid. fleet evaluates severe
risk at a cell’s mean immunity, with no immunity offset where the IBM
adds 0.5 to each person’s. That matches the IBM at the default
parameters, but not as uv changes how widely immunity spreads within a
cell. Not tested: the other 990 draws, EIR below 3, seasonality,
interventions under a draw, and vivax draws. Chosen at EIR 20, the eight
draws span the 4th to 87th percentiles of fleet’s severe incidence at
EIR 120, and only about the 15th to 80th of prevalence at any EIR. The
infectivity parameters (cd, cu, gamma1) act on the mosquitoes, which
set_equilibrium() rescales to hold the EIR, so this design cannot test
them. fleet runs all 1,000 draws at EIR 3, 20 and 120, including the two
with the highest b0, draws 410 and 464 (0.96 and 0.99).

## population-age-structure

pass — The population age structure matches the IBM’s.

**Criterion:** inside the IBM replicate band in every age band below 60
years, on shares renormalised to the 0-60 population  
**Measured:** inside at 11 of 11; largest departure 1.3% of the IBM
median

tier 2 · `validations/02-scenarios`

[![The population age structure matches the IBM's. Verdict:
pass.](cmp_core_pop_age.png)](https://pwinskill.github.io/fleetcheck/articles/cmp_core_pop_age.png)

The 0-60 restriction is a rendering convention, not a model difference:
fleet’s oldest group is absorbing and open-ended above 80, and a
rendering band that reaches into it is given all of it, so fleet’s 60-85
share is 41% higher by construction. Agreement at this level depends on
the ageing rate being exponentially fitted, r = mu/expm1(mu\*width),
exact at the seed and an approximation under time-varying demography.

## speed

pass — fleet is fast enough to be worth using in place of the IBM.

**Criterion:** at least 10x faster than the IBM on the same scenario
set  
**Measured:** 44x on cost per simulated year; 19.9 CPU-hours for the IBM
against 82 s for fleet

tier 2 · `validations/02-scenarios`

*No figure: the numbers above decide this claim.*

Each fleet figure is one complete run_simulation_ode() call – inputs,
seed, the run and its outputs – on one core; the IBM’s are its runs on a
worker pool. One fleet run stands in for the IBM’s twenty replicates of
10,000 people, and its cost does not grow with the population. On one
laptop core a run takes about 0.6 s per 10 simulated years, 1.7 to 2.3 s
for 30. The age grid sets fleet’s cost, roughly in proportion to its
groups: a 30-year run takes 0.7 s on the 53 of default_age_lower(n_group
= 53).

## seed-stability

pass — An undisturbed run holds the equilibrium it was seeded at.

**Criterion:** PfPR(2-10) departs from its seeded value by less than 1%
over 15 years at EIR 20  
**Measured:** 0.35% maximum excursion; flat to 0.007% over the last five
years

tier 1 · `validations/01-seed-stability`

*No figure: the numbers above decide this claim.*

The seed is malariaEquilibrium’s continuous-time solution, not fleet’s
own fixed point on the daily clock, so the run moves off it and settles
0.26% below it. The claim is about prevalence: incidence relaxes
further, under-5 clinical incidence by -0.1% at EIR 1, +1.7% at EIR 20
and +6.0% at EIR 120, nine-tenths of it within five years, so a
comparison of incidence levels wants a burn-in (every tier-2 scenario
has thirty years), as the IBM’s does.
validations/01-seed-stability/run.R reproduces the prevalence figures.

## What “tier” means

What it costs to reproduce a result is a property of that result, so it
is recorded against every claim rather than stated once in prose.

| tier | cost    | who can reproduce it                                |
|------|---------|-----------------------------------------------------|
| 0    | seconds | anyone, from the committed summaries                |
| 1    | minutes | anyone; re-runs `fleet` only                        |
| 2    | ~2 h    | anyone with about ten cores                         |
| 3    | ~30 min | four cores, and inputs that are not redistributable |

Tier 3 is the 63-country site-file comparison. **Its figures and
statistics are public; the site files behind them are not.** The
constraint is the inputs rather than the compute: the sweep re-runs
`fleet` only, because the IBM arm is the pre-run diagnostic shipped with
each site file, so thirty minutes on four cores refreshes it. But the
site files are not redistributable, so nobody outside the project can
repeat it. That is a limitation of this evidence, not a property of the
result, and `validations/03-real-settings/example-one-site.R` runs the
same pipeline on a single sub-site for anyone who has one site file.
