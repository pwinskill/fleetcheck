test_that("md_cell survives the things a human writes in a criterion", {
  # this is a real criterion from the register: the pipes would otherwise split
  # the row into extra columns and the table would render as nonsense
  expect_equal(md_cell("r > 0.95 and |slope - 1| < 0.10"),
               "r > 0.95 and \\|slope - 1\\| < 0.10")
  expect_equal(md_cell("a\nb"), "a b")
  expect_equal(md_cell("a\r\n\r\nb"), "a b")
  expect_equal(md_cell("nothing to escape"), "nothing to escape")
})

test_that("every scoreboard row has the same number of columns", {
  cl <- read_claims(testthat::test_path("..", "..", "claims.yml"))
  md <- scoreboard_md(cl)
  rows <- grep("^\\|", md, value = TRUE)
  # count unescaped pipes only
  n <- vapply(rows, function(r)
    lengths(regmatches(r, gregexpr("(?<!\\\\)\\|", r, perl = TRUE))), integer(1))
  expect_true(all(n == n[1]),
              info = paste("ragged rows:", paste(which(n != n[1]), collapse = ", ")))
  expect_equal(length(rows), nrow(cl) + 2L)   # header + separator + one per claim
})

test_that("the scoreboard leads with what is unresolved", {
  cl <- read_claims(testthat::test_path("..", "..", "claims.yml"))
  md <- scoreboard_md(cl)
  body <- grep("^\\| `", md, value = TRUE)
  skip_if(length(body) < 2, "need at least two claims")
  # anything failing must appear above anything passing
  fail_at <- grep("FAIL", body)
  pass_at <- grep("\\*\\*pass\\*\\*", body)
  if (length(fail_at) && length(pass_at)) expect_lt(max(fail_at), min(pass_at))
})

test_that("replace_block is idempotent and insists on its markers", {
  p <- withr::local_tempfile(fileext = ".md")
  writeLines(c("top", "<!-- BEGIN x -->", "stale", "<!-- END x -->", "bottom"), p)

  expect_true(replace_block(p, "x", "fresh"))
  expect_false(replace_block(p, "x", "fresh"))      # second run changes nothing
  got <- readLines(p)
  expect_true("fresh" %in% got)
  expect_false("stale" %in% got)
  expect_true(all(c("top", "bottom") %in% got))     # content outside is untouched

  expect_error(replace_block(p, "absent", "x"), "not found")
})

test_that("a staleness check does not modify the file it is checking", {
  p <- withr::local_tempfile(fileext = ".md")
  writeLines(c("<!-- BEGIN x -->", "stale", "<!-- END x -->"), p)
  before <- readLines(p)

  expect_true(replace_block(p, "x", "fresh", write = FALSE))
  expect_identical(readLines(p), before)

  expect_true(replace_block(p, "x", "fresh", write = TRUE))
  expect_false(identical(readLines(p), before))
})
