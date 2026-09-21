# Validation evidence

How closely does `fleet` reproduce `malariasimulation`? Each claim below
states the criterion that decides it, the value measured against that
criterion, and a verdict. The order runs from transmission through
clinical and severe burden to their age distributions, then
interventions and real settings, with the demographic, performance and
numerical checks that underwrite them at the end.

Every section is generated from `claims.yml`, so this page cannot
disagree with the register, and the register cannot be changed without
the page following.

**11 claims — 1 failing, 0 untested, 0 open, 10 pass.**

| claim | tier | criterion | measured | verdict |
|----|----|----|----|----|
| [`prevalence-eir`](#prevalence-eir) | 2 | inside the IBM 10-90% replicate band at every EIR on the grid | inside at 6 of 6; largest departure 0.94% of the IBM median | pass |
| [`clinical-allage-eir`](#clinical-allage-eir) | 2 | inside the IBM 10-90% replicate band at every EIR on the grid | inside at 6 of 6 | pass |
| [`clinical-under5-eir`](#clinical-under5-eir) | 2 | inside the IBM 10-90% replicate band at every EIR on the grid | inside at 6 of 6 | pass |
| [`severe-allage-eir`](#severe-allage-eir) | 2 | inside the IBM 10-90% replicate band at every EIR on the grid | inside at 6 of 6 | pass |
| [`age-profile-clinical`](#age-profile-clinical) | 2 | inside the IBM 10-90% replicate band in every age band, at EIR 3, 20 and 120 | inside at 35 of 36 bands across the three EIRs – 12 of 12 at EIR 3, 11 of 12 at EIR 20, 12 of 12 at EIR 120; largest departure 7.7% of the IBM median | FAIL |
| [`age-profile-severe`](#age-profile-severe) | 2 | inside the IBM 10-90% replicate band in every age band with non-zero IBM incidence, at EIR 3, 20 and 120 | inside at 31 of 31 bands across the three EIRs; largest departure 83% of the IBM median, in a band an order of magnitude wider than that | pass |
| [`intervention-impact`](#intervention-impact) | 2 | within 0.6 percentage points of the IBM replicate band on every outcome | inside the band on 22 of 24; worst excursion 0.36 percentage points | pass |
| [`real-settings-correlation`](#real-settings-correlation) | 3 | r \> 0.95 and \|slope - 1\| \< 0.10 on both clinical and severe incidence | clinical r 0.983 slope 0.996; severe r 0.959 slope 0.929, over 450,684 sub-site-months in 1,391 sub-sites of 63 countries | pass |
| [`population-age-structure`](#population-age-structure) | 2 | inside the IBM 10-90% replicate band in every age band below 60 years, on shares renormalised to the 0-60 population | inside at 11 of 11; largest departure 1.3% of the IBM median | pass |
| [`speed`](#speed) | 2 | at least 10x faster than the IBM on the same scenario set | 20x on cost per simulated year; 12.4 CPU-hours for the IBM against 110 s for fleet | pass |
| [`seed-stability`](#seed-stability) | 1 | PfPR(2-10) departs from its seeded value by less than 1% over 15 years at EIR 20 | 0.28% maximum excursion; flat to 0.02% over the last five years | pass |

## prevalence-eir

PASS — LM prevalence in 2-10 year olds tracks the IBM across
transmission intensity.

tier 2 · `validations/02-scenarios`

![LM prevalence in 2-10 year olds tracks the IBM across transmission
intensity.](cmp_eir_pfpr_2_10.png)

## clinical-allage-eir

PASS — All-age clinical incidence tracks the IBM across transmission
intensity.

tier 2 · `validations/02-scenarios`

![All-age clinical incidence tracks the IBM across transmission
intensity.](cmp_eir_clin_all.png)

## clinical-under5-eir

PASS — Under-5 clinical incidence tracks the IBM across transmission
intensity.

tier 2 · `validations/02-scenarios`

fleet sits within 1.3% of the IBM median at every EIR on the grid.

![Under-5 clinical incidence tracks the IBM across transmission
intensity.](cmp_eir_clin_0_5.png)

## severe-allage-eir

PASS — All-age severe incidence tracks the IBM across transmission
intensity.

tier 2 · `validations/02-scenarios`

Severe incidence has the widest replicate spread of any outcome here,
15.4% of the median, which is what sets the twenty-replicate count: ten
put the 10th and 90th percentiles at the extremes of the sample and
understate the band by about a tenth. A band test is blind to a small
offset repeated at every point, and fleet sits a little below the IBM at
every EIR above 1.

![All-age severe incidence tracks the IBM across transmission
intensity.](cmp_eir_sev_all.png)

## age-profile-clinical

FAIL — The age distribution of clinical incidence tracks the IBM.

tier 2 · `validations/02-scenarios`

One band is outside: 40-60 y at EIR 20, by 7.7%, holding 1.7% of
clinical episodes. At EIR 3 and EIR 120 every band is inside. What is
left is not discretisation, and no age grid removes it. Refining the
grid drives the departure to a limit rather than to zero – past about
200 age groups it grows again – because fleet evaluates each
immunity-dependent probability once per age group, at that group’s mean
immunity, and averaging a convex function that way is biased however
finely age is resolved. Where the groups are placed matters more than
how many there are. The claim is carried as a failure while a band is
outside, rather than widening the criterion to fit.

![The age distribution of clinical incidence tracks the
IBM.](cmp_age_clin.png)

## age-profile-severe

PASS — The age distribution of severe incidence tracks the IBM.

tier 2 · `validations/02-scenarios`

The claim rests on the bands below age 5, where 88% of severe episodes
fall and the IBM’s replicate range is 22% of its median. Above age 30
that range reaches 246%, so agreement there is not evidence of much.

![The age distribution of severe incidence tracks the
IBM.](cmp_age_sev.png)

## intervention-impact

PASS — The modelled impact of each intervention matches the IBM.

tier 2 · `validations/02-scenarios`

Impact is a ratio of two runs sharing an age grid, so grid
discretisation largely divides out: a wholesale change of the grid
leaves the worst excursion here unchanged. Perennial chemoprevention is
the one intervention whose delivery the two models cannot share. The IBM
doses each child on reaching a dose age; fleet, having no individuals to
trigger on, approximates that as monthly pulses over a 30-day band at
each dose age. The window is the three years after deployment, which for
chemoprevention is the protective phase. At equilibrium fifteen years
on, fleet has all-age severe incidence 2% higher with PMC than without,
as protected infants reach older ages with less immunity. That rebound
is outside what this claim tests.

![The modelled impact of each intervention matches the
IBM.](cmp_int_impact.png)

## real-settings-correlation

PASS — Agreement holds across real transmission settings, not just
synthetic scenarios.

tier 3 · `validations/03-real-settings`

r and slope test whether fleet TRACKS the IBM across the sub-sites, not
whether it sits on top of it. It runs 8.2% above on clinical incidence
and 6.9% above on severe, an excess near zero at high transmission with
low treatment coverage that grows as either moves, and that is not
explained. Severe is the weaker of the two: its slope, 0.929, is the
closest anything in this register comes to the 0.10 tolerance.
Guinea-Bissau is a separate, localised failure. Across its 18 sub-sites
fleet runs 108% above the IBM at r 0.635, and it holds 17 of the 30
largest absolute discrepancies. It is not the source of the general
excess: dropping it moves the overall figure only from 8.2% to 7.5%, and
takes clinical slope to 1.000. `diagnose.R` ranks every sub-site and
draws its series. The comparison is monthly. Averaging to annual means
once made a real seasonal-amplitude mismatch look like agreement. Both
arms are P. falciparum only. The shipped diagnostics carry vivax rows
too, and including them inflates the baseline where pf transmission is
low.

![Agreement holds across real transmission settings, not just synthetic
scenarios.](cmp_core_sites.png)

## population-age-structure

PASS — The population age structure matches the IBM’s.

tier 2 · `validations/02-scenarios`

The 0-60 restriction is a rendering convention, not a model difference:
fleet’s oldest age group is absorbing and open-ended above 80, and the
renderer assigns an open-ended group wholly to the band containing its
lower edge, so fleet’s 60-85 band holds everyone over 80 and its share
there is 41% higher by construction. Agreement at this level depends on
the ageing rate being exponentially fitted, r = mu/expm1(mu*width),
which makes each band’s stationary ratio exactly exp(-mu*width) instead
of the 1/(1+mu\*width) a plain linear chain gives.

![The population age structure matches the IBM's.](cmp_core_pop_age.png)

## speed

PASS — fleet is fast enough to be worth using in place of the IBM.

tier 2 · `validations/02-scenarios`

*No figure: this claim is a single number rather than a relationship
across a range, and a chart of one number carries less than the number.*

## seed-stability

PASS — An undisturbed run holds the equilibrium it was seeded at.

tier 1 · `validations/01-seed-stability`

*No figure: this claim is a single number rather than a relationship
across a range, and a chart of one number carries less than the number.*

## What “tier” means

What it costs to reproduce a result is a property of that result, so it
is recorded against every claim rather than stated once in prose.

| tier | cost    | who can reproduce it                                     |
|------|---------|----------------------------------------------------------|
| 0    | seconds | anyone, from the committed summaries                     |
| 1    | ~2 min  | anyone; re-runs `fleet` only                             |
| 2    | ~25 min | anyone with about ten cores                              |
| 3    | ~40 min | about ten cores, and inputs that are not redistributable |

Tier 3 is the 63-country site-file comparison. **Its figures and
statistics are public; the site files behind them are not.** The
constraint is the inputs rather than the compute: the sweep re-runs
`fleet` only, because the IBM arm is the pre-run diagnostic shipped with
each site file, so forty minutes on ten cores refreshes it. But the site
files are not redistributable, so nobody outside the project can repeat
it. That is a limitation of this evidence, not a property of the result,
and `validations/03-real-settings/example-one-site.R` runs the same
pipeline on a single sub-site for anyone who has one site file.
