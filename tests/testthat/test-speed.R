# The two speed claims quote validations/02-scenarios/results/speed.csv (and
# results/pv/ for vivax), and nothing re-times a model to check them. This is
# the tier-0 check that the register says what the committed timings say.
# validations/ is .Rbuildignore'd, so under R CMD check there is nothing here to
# look at, and the tests say so rather than pass.

speed_results <- testthat::test_path("..", "..", "validations", "02-scenarios", "results")

## a multiple as the table quotes it: one decimal below 10, whole above
as_quoted <- function(x) ifelse(x < 9.95, round(x, 1), round(x))

check_speed_claim <- function(id, csv, eirs) {
  testthat::skip_if_not(file.exists(csv), "validations/ is not in the built package")
  s <- utils::read.csv(csv, stringsAsFactors = FALSE)
  i <- s[s$model == "IBM" & s$pop == 1e4, ]
  # every EIR and setting the criterion names, at 10,000 people
  expect_setequal(paste(i$setting, i$eir),
                  paste(rep(c("none", "programme"), each = 3), eirs))
  cl <- read_claims(find_claims(testthat::test_path("..", "..")))
  cl <- cl[cl$id == id, ]
  m <- regmatches(cl$measured, regexec("([0-9.]+)x to ([0-9.]+)x per simulated year at 10,000",
                                       cl$measured))[[1]]
  expect_equal(as.numeric(m[2:3]), as_quoted(range(i$speedup)), info = id)
  # the bar is met in every cell, not on average
  expect_equal(cl$status, if (min(i$speedup) >= 10) "pass" else "fail", info = id)
}

test_that("the speed claim quotes the committed timings, and is scored on them", {
  check_speed_claim("speed", file.path(speed_results, "speed.csv"), PROFILE_EIR)
})

test_that("the vivax speed claim quotes the committed timings, and is scored on them", {
  check_speed_claim("speed-pv", file.path(speed_results, "pv", "speed.csv"), PROFILE_EIR_PV)
})
