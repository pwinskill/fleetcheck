# P. vivax scenario definitions, sourced by scenarios.R when CMP_PARASITE=pv.
# Each returns list(p = parameters, eir = init_EIR, years = horizon).
#
# The falciparum suite's shape on vivax's own grid (EIR_GRID_PV), with the
# interventions malariasimulation can run under vivax. SMC and PMC are absent
# because malariasimulation fails on chemoprevention under vivax; RTS,S because
# its vaccine parameters carry no vivax calibration. In their place, vivax's own
# lever: radical cure, with primaquine and with tafenoquine, whose longer
# liver-stage protection is the difference between them.

base_params <- function(seasonal = FALSE, age_profile = FALSE) {
  ov <- list(human_population = POP)
  if (seasonal) ov <- c(ov, list(model_seasonality = TRUE), SEASON)
  set_bands(get_parameters(ov, parasite = "vivax"), age_profile)
}

Y_INT <- BURN_Y * 365                       # intervention start (day)
scenarios <- list()

## the transmission grid, age-profile bands at PROFILE_EIR_PV
for (E in EIR_GRID_PV) scenarios[[paste0("eir_", E)]] <- list(
  p = set_equilibrium(base_params(age_profile = (E %in% PROFILE_EIR_PV)), init_EIR = E),
  eir = E, years = BURN_Y + 3L)

scenarios$seasonal <- list(
  p = set_equilibrium(base_params(seasonal = TRUE), init_EIR = EIR_REF_PV),
  eir = EIR_REF_PV, years = BURN_Y + 3L)

## ---- interventions, each across PROFILE_EIR_PV -------------------------------
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

## Blood-stage treatment alone: chloroquine at 20% of clinical cases through the
## burn-in, 60% from deployment.
int_builders$treatment <- function(E) {
  p <- set_drugs(base_params(), list(CQ_params_vivax))
  p <- set_clinical_treatment(p, drug = 1, timesteps = c(1, Y_INT), coverages = c(0.2, 0.6))
  list(p = set_equilibrium(p, init_EIR = E), eir = E, years = BURN_Y + 6L)
}

## Radical cure: the same 20% chloroquine burn-in, then 60% of cases on
## chloroquine plus a liver-stage drug. The first-line switch is a drug change
## at deployment -- chloroquine's coverage falls to 0 as the combination's rises
## to 60% -- which both models follow as a schedule.
radical_cure <- function(E, combo) {
  p <- set_drugs(base_params(), list(CQ_params_vivax, combo))
  p <- set_clinical_treatment(p, drug = 1, timesteps = c(1, Y_INT), coverages = c(0.2, 0))
  p <- set_clinical_treatment(p, drug = 2, timesteps = c(1, Y_INT), coverages = c(0, 0.6))
  list(p = set_equilibrium(p, init_EIR = E), eir = E, years = BURN_Y + 6L)
}
int_builders$primaquine  <- function(E) radical_cure(E, CQ_PQ_params_vivax)
int_builders$tafenoquine <- function(E) radical_cure(E, CQ_TQ_params_vivax)

stopifnot(setequal(names(int_builders), names(INT_LABELS_PV)))
for (.nm in names(int_builders))
  for (.E in PROFILE_EIR_PV)
    scenarios[[int_scenario(.nm, .E, ref = EIR_REF_PV)]] <- int_builders[[.nm]](.E)
rm(.nm, .E)

## custom demography, as for falciparum: high infant and elderly mortality
scenarios$demography <- local({
  dr <- c(0.048, 0.007, 0.003, 0.004, 0.008, 0.020, 0.050, 0.120) / 365
  ag <- round(c(1, 5, 10, 20, 40, 60, 80, 100) * 365)
  p <- set_demography(base_params(age_profile = TRUE), agegroups = ag, timesteps = 0,
                      deathrates = matrix(dr, nrow = 1))
  list(p = set_equilibrium(p, init_EIR = EIR_REF_PV), eir = EIR_REF_PV, years = BURN_Y + 3L)
})
