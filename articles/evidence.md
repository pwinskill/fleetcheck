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

pass — LM prevalence in 2-10 year olds tracks the IBM across
transmission intensity.

tier 2 · `validations/02-scenarios`

![LM prevalence in 2-10 year olds tracks the IBM across transmission
intensity.](cmp_eir_pfpr_2_10.png)

## clinical-allage-eir

pass — All-age clinical incidence tracks the IBM across transmission
intensity.

tier 2 · `validations/02-scenarios`

![All-age clinical incidence tracks the IBM across transmission
intensity.](cmp_eir_clin_all.png)

## clinical-under5-eir

pass — Under-5 clinical incidence tracks the IBM across transmission
intensity.

tier 2 · `validations/02-scenarios`

fleet sits within 1.3% of the IBM median at every EIR on the grid.

![Under-5 clinical incidence tracks the IBM across transmission
intensity.](cmp_eir_clin_0_5.png)

## severe-allage-eir

pass — All-age severe incidence tracks the IBM across transmission
intensity.

tier 2 · `validations/02-scenarios`

Severe incidence has the widest replicate spread of any outcome here,
15.4% of the median, which is what sets the twenty-replicate count: ten
put the 10th and 90th percentiles at the extremes of the sample and
understate the band by about a tenth. A band test is blind to a small
offset repeated at every point, and fleet sits a little below the IBM at
every EIR above 1. Do not read that deficit as a model property to
correct for. Severe incidence carries a discretisation bias of about -6%
on the default grid, the same sign and size, and refining the grid takes
the offset through zero. How much of the deficit is the grid and how
much is the mean field is not resolved here.

![All-age severe incidence tracks the IBM across transmission
intensity.](cmp_eir_sev_all.png)

## age-profile-clinical

FAIL — The age distribution of clinical incidence tracks the IBM.

tier 2 · `validations/02-scenarios`

One band is outside: 40-60 y at EIR 20, by 7.7%, holding 1.7% of
clinical episodes. At EIR 3 and EIR 120 every band is inside. Two errors
are in play and only one is the grid’s, which validations/age-grid/run.R
separates. fleet’s departure from its own converged profile falls 4.5%
to 2.3% to 1.1% to 0.6% as the group count doubles, a ratio of 2.0 and
clean first order: discretisation is removable. Its departure from the
IBM over the same grids falls 7.7% to 5.3% to 4.6% to 4.3% and levels
off. Where the groups are placed removes more than how many there are –
an equal-width grid at this cost is four times as far from the converged
profile. What remains is the mean field itself. fleet carries one
immunity value per stratum, so it evaluates each immunity-dependent
probability at the mean immunity of people who, in the IBM, have
different infection histories at the same age. Averaging a convex
function over that spread is biased, and the spread is between
individuals rather than across an age group, so no age grid touches it.
The claim is carried as a failure while a band is outside, rather than
widening the criterion to fit.

![The age distribution of clinical incidence tracks the
IBM.](cmp_age_clin.png)

## age-profile-severe

pass — The age distribution of severe incidence tracks the IBM.

tier 2 · `validations/02-scenarios`

The claim rests on the bands below age 5, where 88% of severe episodes
fall and the IBM’s replicate range is 22% of its median. Above age 30
that range reaches 246%, so agreement there is not evidence of much.

![The age distribution of severe incidence tracks the
IBM.](cmp_age_sev.png)

## intervention-impact

pass — The modelled impact of each intervention matches the IBM.

tier 2 · `validations/02-scenarios`

Impact is a ratio of two runs sharing an age grid, so grid
discretisation largely divides out: a wholesale change of the grid
leaves the worst excursion here unchanged. Perennial chemoprevention is
the one intervention whose delivery the two models cannot share. The IBM
doses each child on reaching a dose age; fleet, having no individuals to
trigger on, approximates that as monthly pulses over a 30-day band at
each dose age. Each child receives exactly one dose per band, but LATE:
the band runs from the dose age rather than straddling it, so the mean
age at dosing is 8 to 21 days past the trigger. Infant clinical risk is
rising steeply there, so this overstates PMC’s infant benefit by roughly
a tenth. Centring the band would fix it and would move every number in
this claim, so it is recorded rather than done. The two EPI doses 28
days apart are also closer together than one age group is wide, so fleet
cannot resolve them as separate events. The window is the three years
after deployment, which for chemoprevention is the protective phase, and
the scenario horizon stops at six. Run on past it and fleet develops a
rebound: protected infants reach older ages with less immunity, and
all-age severe incidence ends up above the no-PMC arm. The size depends
strongly on transmission – about -0.5% at EIR 3, +2% at EIR 20 and +8%
at EIR 120 – so no single figure describes it. The IBM rows committed
here cannot settle whether it agrees: they cover six post-deployment
years, where fleet’s rebound has barely started, and their replicate
band on all-age severe is about +-13%, far wider than the effect. A
longer horizon and more replicates would be needed to test it at all.

![The modelled impact of each intervention matches the
IBM.](cmp_int_impact.png)

## real-settings-correlation

pass — Agreement holds across real transmission settings, not just
synthetic scenarios.

tier 3 · `validations/03-real-settings`

r and slope test whether fleet TRACKS the IBM across the sub-sites, not
whether it sits on top of it. A single excess figure should not be
quoted for the level, because it is a mean over a 75-fold transmission
gradient and varies by two orders of magnitude along it. By sub-site pf
EIR, clinical runs +190% below 0.1, +23% at 1-3, +4.3% at 20-50 and
+2.3% above 120; severe runs +152%, +17%, +1.3% and -0.5%. Severe
crosses zero at high transmission, which is what reconciles this claim
with severe-allage-eir, whose EIR grid starts at 1 and reports fleet a
little BELOW the IBM. 18% of sub-sites sit below EIR 1, outside the
range any tier-2 claim covers, and that is where the departure lives.
Severe is the weaker of the two: its slope, 0.929, is the closest
anything in this register comes to the 0.10 tolerance. The reference arm
is a single unreplicated IBM run, so ordinary least squares attenuates
that slope toward zero – the bias is in the direction of the finding.
Guinea-Bissau is a separate, localised failure rather than a piece of
the gradient above. Its 18 sub-sites run 108% above the IBM at a pooled
monthly r of 0.635, where the 553 non-GNB sub-sites carrying the same
burden run +11.8% at a per-site r of 0.991; 17 of its 18 sit above those
peers’ 90th percentile, and it holds 17 of the 30 largest absolute
discrepancies. diagnose.R ranks every sub-site and draws its series. The
comparison is monthly. Averaging to annual means once made a real
seasonal-amplitude mismatch look like agreement. Both arms are P.
falciparum only. The shipped diagnostics carry vivax rows too, and
including them inflates the baseline where pf transmission is low.

![Agreement holds across real transmission settings, not just synthetic
scenarios.](cmp_core_sites.png)

## population-age-structure

pass — The population age structure matches the IBM’s.

tier 2 · `validations/02-scenarios`

The 0-60 restriction is a rendering convention, not a model difference:
fleet’s oldest age group is absorbing and open-ended above 80, and the
renderer assigns an open-ended group wholly to the band containing its
lower edge, so fleet’s 60-85 band holds everyone over 80 and its share
there is 41% higher by construction. Agreement at this level depends on
the ageing rate being exponentially fitted, r = mu/expm1(mu*width),
which makes each band’s stationary ratio exactly exp(-mu*width) instead
of the 1/(1+mu\*width) a plain linear chain gives. The fit is exact at
the seed and an approximation afterwards, so its accuracy is conditional
on demography that is near stationary; the residual sits in the 80+
band, which this claim excludes anyway. A separate defect is not in this
claim’s scope but belongs on the record: maternal immunity is drawn from
the age group containing 20 years, which on the current grid is 20-22.5,
where the IBM uses 20-21. Older mothers carry more immunity, so infants
start with about 6.7% too much of it, decaying to nothing by age 1.
Pinning an anchor at 21 fixes it and moves every infant number, so it is
recorded rather than done.

![The population age structure matches the IBM's.](cmp_core_pop_age.png)

## speed

pass — fleet is fast enough to be worth using in place of the IBM.

tier 2 · `validations/02-scenarios`

*No figure: this claim is a single number rather than a relationship
across a range, and a chart of one number carries less than the number.*

## seed-stability

pass — An undisturbed run holds the equilibrium it was seeded at.

tier 1 · `validations/01-seed-stability`

The one claim here whose measured value no script in this repository
reproduces: validations/01-seed-stability/ is a stub. The figure comes
from a run made outside it, which is the arrangement the rest of the
register exists to avoid.

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
