# The speed claim quotes validations/02-scenarios/results/speed.csv, and
# nothing re-times a model to check it. This is the tier-0 check that the
# register says what the committed timings say. validations/ is
# .Rbuildignore'd, so under R CMD check there is nothing here to look at, and
# the test says so rather than pass.

speed_csv <- testthat::test_path("..", "..", "validations", "02-scenarios", "results", "speed.csv")

test_that("the speed claim quotes the committed timings, and is scored on them", {
  testthat::skip_if_not(file.exists(speed_csv), "validations/ is not in the built package")
  s <- utils::read.csv(speed_csv, stringsAsFactors = FALSE)
  i <- s[s$model == "IBM" & s$pop == 1e4, ]
  # every EIR and setting the criterion names, at 10,000 people
  expect_setequal(paste(i$setting, i$eir), paste(rep(c("none", "programme"), each = 3), c(3, 20, 120)))
  cl <- read_claims(find_claims(testthat::test_path("..", "..")))
  cl <- cl[cl$id == "speed", ]
  m <- regmatches(cl$measured, regexec("([0-9]+)x to ([0-9]+)x per simulated year at 10,000",
                                       cl$measured))[[1]]
  expect_equal(as.numeric(m[2:3]), round(range(i$speedup)))
  # the bar is met in every cell, not on average
  expect_equal(cl$status, if (min(i$speedup) >= 10) "pass" else "fail")
})
