# Two sets of tests here, and the split matters.
#
# The first set reads the real register -- via find_claims(), which falls back
# to the installed copy, because the source claims.yml is .Rbuildignore'd and is
# simply not there under R CMD check -- and asserts things about *this*
# project's register: that it parses, that every unresolved claim explains
# itself. Those are checks on the content.
#
# The second set builds registers to order and asserts things about the *code*:
# that a malformed register is rejected and that check_claims() fails when it
# should. Those used to read the real register too, and skipped, because nothing
# in it fails -- so the function CI depends on had no coverage.

test_that("the register parses and every claim is well formed", {
  cl <- read_claims(find_claims())

  # nzchar(NA) is TRUE, so `all(nzchar(x))` cannot see a missing field. Both
  # halves are needed.
  filled <- function(x) !is.na(x) & nzchar(x)

  expect_gt(nrow(cl), 0)
  expect_false(anyDuplicated(cl$id) > 0)
  expect_true(all(filled(cl$claim)))
  expect_true(all(filled(cl$criterion)))
  expect_true(all(filled(cl$measured)))
  expect_true(all(cl$status %in% c("pass", "fail", "open", "undeclared")))
  expect_true(all(cl$tier %in% 0:3))
  expect_true(all(cl$declared %in% c("in-advance", "retrospective", "none")))
})

test_that("a claim with no declared criterion says so in both fields", {
  cl <- read_claims(find_claims())
  none <- cl[cl$declared == "none", ]
  # these are gaps in the register, and must be visible as such rather than
  # quietly passing
  expect_gt(nrow(none), 0)
  expect_true(all(none$status == "undeclared"))
  expect_true(all(grepl("NONE DECLARED", none$criterion, fixed = TRUE)))
})

test_that("anything failing or undeclared carries an explanation", {
  cl <- read_claims(find_claims())
  needs_note <- cl[cl$status %in% c("fail", "undeclared", "open"), ]
  expect_true(all(nzchar(needs_note$note)),
              info = paste("no note:",
                           paste(needs_note$id[!nzchar(needs_note$note)],
                                 collapse = ", ")))
})


## ---- the reader rejects a malformed register --------------------------------

test_that("a blank or absent required field is an error, not a silent NA", {
  expect_error(read_claims(write_register(list(criterion = NULL))),
               "missing or blank")
  # present but empty: the case nzchar(NA) hid
  expect_error(read_claims(write_register(list(measured = ""))),
               "missing or blank")
  expect_error(read_claims(write_register(list(id = "  "))),
               "missing or blank")
})

test_that("the reader rejects contradictions rather than rendering them", {
  expect_error(read_claims(write_register(list(status = "probably fine"))),
               "unknown status")
  expect_error(read_claims(write_register(list(declared = "someday"))),
               "unknown `declared`")
  expect_error(read_claims(write_register(list(tier = 7))), "tier must be 0-3")
  expect_error(read_claims(write_register(list(id = "a"), list(id = "a"))),
               "duplicate claim id")
  # `declared: none` and `status: undeclared` are one fact written twice, and a
  # register that says one without the other is telling the reader two things
  expect_error(read_claims(write_register(list(declared = "none"))),
               "disagree")
  expect_error(read_claims(write_register(list(status = "undeclared"))),
               "disagree")
})

test_that("an empty register is an error rather than an empty pass", {
  p <- withr::local_tempfile(fileext = ".yml")
  writeLines("# nothing here", p)
  expect_error(read_claims(p), "parsed to nothing")
})


## ---- check_claims, on registers that actually fail --------------------------

test_that("check_claims fails on an unexpected failure", {
  cl <- read_claims(write_register(
    list(id = "broken",     status = "fail", note = "known, tracked in #12"),
    list(id = "alsobroken", status = "fail", note = "also known")))

  expect_error(capture.output(check_claims(cl)),
               "claims failing and not in allow_fail")
  # tolerating one failure does not tolerate the next one
  expect_error(capture.output(check_claims(cl, allow_fail = "broken")),
               "alsobroken")
})

test_that("tolerating a failure costs a written reason", {
  no_note <- read_claims(write_register(list(id = "broken", status = "fail")))
  expect_error(capture.output(check_claims(no_note, allow_fail = "broken")),
               "no note")

  with_note <- read_claims(write_register(
    list(id = "broken", status = "fail", note = "known, tracked in #12")))
  expect_silent(invisible(capture.output(
    check_claims(with_note, allow_fail = "broken"))))

  # an allow_fail entry naming a claim that does not exist is an error too:
  # otherwise a renamed claim silently stops being tolerated, or silently keeps
  # being tolerated under a name nothing checks
  expect_error(capture.output(
    check_claims(with_note, allow_fail = c("broken", "no-such-claim"))),
    "no such claim")
})

test_that("an undeclared claim is reported but does not fail CI", {
  cl <- read_claims(write_register(
    list(id = "untested", status = "undeclared", declared = "none",
         criterion = "NONE DECLARED")))
  out <- capture.output(check_claims(cl))
  expect_match(paste(out, collapse = " "), "UNTESTED")
  expect_match(paste(out, collapse = " "), "1 untested")
})
