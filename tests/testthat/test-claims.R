test_that("the register parses and every claim is well formed", {
  cl <- read_claims(testthat::test_path("..", "..", "claims.yml"))

  expect_gt(nrow(cl), 0)
  expect_false(anyDuplicated(cl$id) > 0)
  expect_true(all(nzchar(cl$claim)))
  expect_true(all(nzchar(cl$criterion)))
  expect_true(all(nzchar(cl$measured)))
  expect_true(all(cl$status %in% c("pass", "fail", "open", "undeclared")))
  expect_true(all(cl$tier %in% 0:3))
  expect_true(all(cl$declared %in% c("in-advance", "retrospective", "none")))
})

test_that("a claim with no declared criterion says so in both fields", {
  cl <- read_claims(testthat::test_path("..", "..", "claims.yml"))
  none <- cl[cl$declared == "none", ]
  # these are gaps in the register, and must be visible as such rather than
  # quietly passing
  expect_true(all(none$status == "undeclared"))
  expect_true(all(grepl("NONE DECLARED", none$criterion, fixed = TRUE)))
})

test_that("anything failing or undeclared carries an explanation", {
  cl <- read_claims(testthat::test_path("..", "..", "claims.yml"))
  needs_note <- cl[cl$status %in% c("fail", "undeclared", "open"), ]
  expect_true(all(nzchar(needs_note$note)),
              info = paste("no note:",
                           paste(needs_note$id[!nzchar(needs_note$note)],
                                 collapse = ", ")))
})

test_that("check_claims fails on an unexpected failure and passes when allowed", {
  cl <- read_claims(testthat::test_path("..", "..", "claims.yml"))
  failing <- cl$id[cl$status == "fail"]
  skip_if(length(failing) == 0, "no failing claims to exercise")

  expect_error(check_claims(cl, allow_fail = character()))
  expect_silent({
    out <- capture.output(check_claims(cl, allow_fail = failing))
  })
  # an allow_fail entry that names nothing, or names a claim with no note, is
  # itself an error: you cannot tolerate a failure without saying why
  expect_error(check_claims(cl, allow_fail = c(failing, "no-such-claim")))
})
