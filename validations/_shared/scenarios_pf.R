# P. falciparum scenario definitions, sourced by scenarios.R when CMP_PARASITE
# is pf (the default). Each returns list(p = parameters, eir = init_EIR,
# years = horizon). Moved here unchanged when the vivax suite arrived, so the
# scenario digest the committed IBM reference was stamped with still matches.

base_params <- function(seasonal = FALSE, age_profile = FALSE) {
  ov <- list(human_population = POP)
  if (seasonal) ov <- c(ov, list(model_seasonality = TRUE), SEASON)
  set_bands(get_parameters(ov), age_profile)
}

## ---- scenarios ---------------------------------------------------------------
## Each returns list(p = parameters, eir = init_EIR, years = horizon).
Y_INT <- BURN_Y * 365                       # intervention start (day)
scenarios <- list()

## Age-profile bands are carried at LOW, REFERENCE and HIGH transmission
## (PROFILE_EIR), not only at the reference. An age profile at one EIR cannot say
## whether the shape tracks the IBM as transmission changes, which is most of
## what an age profile is for -- the peak moves into older children as
## transmission falls. The bands roughly double the IBM's rendering cost, so they
## are on three scenarios rather than all six.
for (E in EIR_GRID) scenarios[[paste0("eir_", E)]] <- list(
  p = set_equilibrium(base_params(age_profile = (E %in% PROFILE_EIR)), init_EIR = E),
  eir = E, years = BURN_Y + 3L)

scenarios$seasonal <- list(
  p = set_equilibrium(base_params(seasonal = TRUE), init_EIR = EIR_REF),
  eir = EIR_REF, years = BURN_Y + 3L)

## ---- interventions, each across the transmission grid ------------------------
## Every intervention is deployed at all three of PROFILE_EIR, the same levels
## the age profiles are carried at, because impact is not a property of an
## intervention on its own. Across EIR 3 to 120 fleet's predicted reduction in
## all-age severe incidence falls from 81% to 17% for nets, RISES from 7% to 10%
## for RTS,S, and changes sign for perennial chemoprevention. A comparison made
## at a single EIR cannot see whether the IBM agrees about any of that, and a
## claim resting on one cannot say what it covers.
##
## The run at EIR_REF keeps the bare scenario name -- int_scenario() holds the
## convention -- so the rows already committed under `nets`, `irs` and the rest
## stay valid and only the two new arms have to be run.
int_builders <- list()

int_builders$nets <- function(E) {
  p <- set_bednets(base_params(), timesteps = Y_INT, coverages = 0.8,
                   retention = 5 * 365, dn0 = matrix(0.387), rn = matrix(0.563),
                   rnm = matrix(0.24), gamman = 2.64 * 365)
  list(p = set_equilibrium(p, init_EIR = E), eir = E, years = BURN_Y + 6L)
}

int_builders$irs <- function(E) {
  rounds <- Y_INT + c(0, 1, 2) * 365
  m <- function(v) matrix(v, nrow = length(rounds), ncol = 1)
  p <- set_spraying(base_params(), timesteps = rounds, coverages = rep(0.8, 3),
                    ls_theta = m(2.025), ls_gamma = m(-0.009),
                    ks_theta = m(-2.222), ks_gamma = m(0.008),
                    ms_theta = m(-1.232), ms_gamma = m(-0.009))
  list(p = set_equilibrium(p, init_EIR = E), eir = E, years = BURN_Y + 6L)
}

## The one seasonal intervention, so the one scenario built on a seasonal
## profile: four monthly rounds a year aligned to the peak, for three years.
## It sat at EIR 15 for no reason the repository records, which left it the only
## row of the impact figure that could not be read against the others.
int_builders$smc <- function(E) {
  p <- base_params(seasonal = TRUE)
  p <- set_drugs(p, list(SP_AQ_params))
  p <- set_clinical_treatment(p, drug = 1, timesteps = 1, coverages = 0.45)
  rounds <- as.vector(sapply(0:2, function(y) Y_INT + y * 365 + c(0, 30, 60, 90) + 200))
  p <- set_smc(p, drug = 1, timesteps = rounds, coverages = rep(0.9, length(rounds)),
               min_ages = rep(round(0.25 * 365), length(rounds)),
               max_ages = rep(round(5 * 365), length(rounds)))
  list(p = set_equilibrium(p, init_EIR = E), eir = E, years = BURN_Y + 3L)
}

int_builders$pev <- function(E) {
  p <- set_pev_epi(base_params(), profile = rtss_profile, timesteps = Y_INT,
                   coverages = 0.9, min_wait = 0, age = 5 * 30,
                   booster_spacing = 12 * 30, booster_coverage = matrix(0.8),
                   booster_profile = list(rtss_booster_profile))
  list(p = set_equilibrium(p, init_EIR = E), eir = E, years = BURN_Y + 6L)
}

## Perennial malaria chemoprevention: SP-AQ delivered alongside the EPI contacts
## at ~10 weeks, ~14 weeks and ~9 months. Here to test the one intervention whose
## DELIVERY the two models disagree about by construction -- the IBM doses each
## child on reaching a dose age, and fleet, having no individuals to trigger on,
## approximates that as monthly pulses over a 30-day band at each dose age. Every
## other builder is a schedule both models can follow literally.
##
## Its effect is small on three of the four reported outcomes, which is the
## point: the interesting number is all-age severe incidence, where protecting
## infants delays immunity and fleet predicts an INCREASE. Whether the IBM agrees
## on the sign and size of that rebound is not something any other scenario asks,
## and the sign itself turns on transmission, which is why it is now asked three
## times.
int_builders$pmc <- function(E) {
  p <- set_drugs(base_params(), list(SP_AQ_params))
  p <- set_pmc(p, drug = 1, timesteps = Y_INT, coverages = 0.8,
               ages = round(c(10 * 7, 14 * 7, 9 * 30.4)))
  list(p = set_equilibrium(p, init_EIR = E), eir = E, years = BURN_Y + 6L)
}

int_builders$treatment <- function(E) {
  p <- set_drugs(base_params(), list(AL_params))
  p <- set_clinical_treatment(p, drug = 1, timesteps = c(1, Y_INT), coverages = c(0.2, 0.6))
  list(p = set_equilibrium(p, init_EIR = E), eir = E, years = BURN_Y + 6L)
}

stopifnot(setequal(names(int_builders), names(INT_LABELS)))
for (.nm in names(int_builders))
  for (.E in PROFILE_EIR)
    scenarios[[int_scenario(.nm, .E)]] <- int_builders[[.nm]](.E)
rm(.nm, .E)

## custom demography: high infant and elderly mortality, so the equilibrium age
## structure departs strongly from the default exponential one
scenarios$demography <- local({
  dr <- c(0.048, 0.007, 0.003, 0.004, 0.008, 0.020, 0.050, 0.120) / 365
  ag <- round(c(1, 5, 10, 20, 40, 60, 80, 100) * 365)
  p <- set_demography(base_params(age_profile = TRUE), agegroups = ag, timesteps = 0,
                      deathrates = matrix(dr, nrow = 1))
  list(p = set_equilibrium(p, init_EIR = EIR_REF), eir = EIR_REF, years = BURN_Y + 3L)
})

## ---- ts_*: long-horizon programme scenarios ---------------------------------
## The scenarios above each isolate ONE builder over 6 years, which is the right
## shape for attributing a difference but not for showing what a programme looks
## like. These five run 15 years past deployment in a seasonal setting so the
## repeated-campaign dynamics are visible -- five net distributions decaying and
## being replaced, SMC pulsing four times a year for fifteen years -- and they
## share a common no-intervention reference so the three tiers (nothing, one
## thing, everything) can be read against each other. All at EIR 20 seasonal, so
## every row of the figure is the same setting with more added to it.
TS_Y <- 15L
ts_base <- function() set_bands(get_parameters(c(list(human_population = POP),
                                                 list(model_seasonality = TRUE), SEASON)))
## nets every 3 years: 5 campaigns over the 15-year window
ts_net_rounds <- Y_INT + seq(0, by = 3 * 365, length.out = 5L)
ts_nets_on <- function(p) {
  n <- length(ts_net_rounds)
  set_bednets(p, timesteps = ts_net_rounds, coverages = rep(0.8, n),
              retention = 5 * 365, dn0 = matrix(rep(0.387, n)), rn = matrix(rep(0.563, n)),
              rnm = matrix(rep(0.24, n)), gamman = rep(2.64 * 365, n))
}
## SMC: 4 monthly rounds a year, every year of the window, peak-season aligned
ts_smc_rounds <- as.vector(sapply(seq_len(TS_Y) - 1L,
                                  function(y) Y_INT + y * 365 + c(0, 30, 60, 90) + 200))
ts_smc_on <- function(p) {
  n <- length(ts_smc_rounds)
  set_smc(p, drug = 1, timesteps = ts_smc_rounds, coverages = rep(0.9, n),
          min_ages = rep(round(0.25 * 365), n), max_ages = rep(round(5 * 365), n))
}
## case management: SP-AQ throughout (SMC needs a drug), scaled up at deployment
ts_treat_on <- function(p, hi = 0.6) set_clinical_treatment(
  set_drugs(p, list(SP_AQ_params)), drug = 1, timesteps = c(1, Y_INT), coverages = c(0.2, hi))
ts_drug_only <- function(p) set_clinical_treatment(
  set_drugs(p, list(SP_AQ_params)), drug = 1, timesteps = 1, coverages = 0.2)

ts_scen <- list(
  ts_none  = function() ts_drug_only(ts_base()),
  ts_nets  = function() ts_nets_on(ts_drug_only(ts_base())),
  ts_smc   = function() ts_smc_on(ts_drug_only(ts_base())),
  ts_treat = function() ts_treat_on(ts_base()),
  ts_all   = function() ts_smc_on(ts_nets_on(ts_treat_on(ts_base()))))
for (nm in names(ts_scen)) scenarios[[nm]] <- local({
  f <- ts_scen[[nm]]
  list(p = set_equilibrium(f(), init_EIR = EIR_REF), eir = EIR_REF, years = BURN_Y + TS_Y)
})

