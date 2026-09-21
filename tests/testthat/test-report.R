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
  cl <- read_claims(find_claims())
  md <- scoreboard_md(cl)
  rows <- grep("^\\|", md, value = TRUE)
  # count unescaped pipes only
  n <- vapply(rows, function(r)
    lengths(regmatches(r, gregexpr("(?<!\\\\)\\|", r, perl = TRUE))), integer(1))
  expect_true(all(n == n[1]),
              info = paste("ragged rows:", paste(which(n != n[1]), collapse = ", ")))
  expect_equal(length(rows), nrow(cl) + 2L)   # header + separator + one per claim
})

test_that("the scoreboard is in register order and is not re-sorted by status", {
  # The register is written in the order the claims are meant to be read, so
  # the order is a fact about the register and belongs to it. An earlier
  # version sorted unresolved claims to the top here, which meant the table,
  # the article's sections and claims.yml itself could all be in three
  # different orders.
  ids <- c("passing", "untested", "opened", "broken")
  cl <- read_claims(write_register(
    list(id = "passing",  status = "pass"),
    list(id = "untested", status = "undeclared", declared = "none",
         criterion = "NONE DECLARED"),
    list(id = "opened",   status = "open"),
    list(id = "broken",   status = "fail")))
  body <- grep("^\\| `", scoreboard_md(cl), value = TRUE)

  expect_equal(length(body), 4L)
  expect_equal(sub("^\\| `([^`]+)`.*", "\\1", body), ids)
  # the terminal form reads from the same register and must not diverge
  expect_equal(sub("^\\s+\\S+\\s+\\S+\\s+(\\S+).*", "\\1", scoreboard(cl)[-(1:2)]),
               ids)
})

test_that("an unresolved verdict is not set in a lighter type than a pass", {
  # Nothing re-sorts the rows, so the verdict column is the only thing that
  # tells a reader which claims are unresolved. An earlier version set `pass`
  # in bold and `undeclared` in grey italic, which made the one that needed
  # attention read as a footnote.
  cl <- read_claims(write_register(
    list(id = "passing",  status = "pass"),
    list(id = "untested", status = "undeclared", declared = "none",
         criterion = "NONE DECLARED"),
    list(id = "broken",   status = "fail")))
  md <- scoreboard_md(cl)
  verdict <- function(id) cell(md, id, 1)   # the verdict is the last column

  expect_equal(verdict("broken"), '<span class="verdict fail">FAIL</span>')
  expect_equal(verdict("untested"), '<span class="verdict untested">UNTESTED</span>')
  expect_equal(verdict("passing"), '<span class="verdict pass">pass</span>')
  # and the summary counts in the same order the rows are in
  expect_match(md[1], "^\\*\\*3 claims — 1 failing, 1 untested, 0 open, 1 pass\\.\\*\\*$")
  # Colour is a stylesheet's job and must never be the only signal: each verdict
  # carries its own word, so the column survives greyscale, a terminal, and
  # GitHub, which strips the class and keeps the text.
  word <- function(id) sub(".*>([A-Za-z]+)<.*", "\\1", verdict(id))
  expect_equal(c(word("broken"), word("untested"), word("passing")),
               c("FAIL", "UNTESTED", "pass"))
})

test_that("the list says what was compared and how it came out, and no more", {
  # README and the front page carry the list; the criterion and the measurement
  # are the evidence page's table, and printing both put every one of those
  # sentences on the site twice.
  cl <- read_claims(write_register(
    list(id = "one", status = "fail", claim = "One tracks the IBM.",
         criterion = "a criterion", measured = "a measurement"),
    list(id = "two", status = "pass", claim = "Two tracks the IBM.")))
  md <- claims_list_md(cl)
  items <- grep("^[0-9]+[.]", md, value = TRUE)

  expect_equal(length(items), 2L)
  expect_match(items[1], "^1[.] ")
  expect_match(items[1], "verdict fail")
  expect_match(items[1], "One tracks the IBM.", fixed = TRUE)
  expect_false(any(grepl("a criterion|a measurement", md)))
  # the headline is the one the table carries, computed once
  expect_equal(md[1], scoreboard_md(cl)[1])
  # register order, not status order
  expect_equal(sub(".*`([^`]+)`.*", "\\1", items), c("one", "two"))
})

test_that("link_prefix distinguishes no link, a same-page anchor and a site URL", {
  cl <- read_claims(write_register(list(id = "only")))
  row <- function(...) grep("^\\| ", scoreboard_md(cl, ...), value = TRUE)[3]

  expect_match(row(), "^\\| `only` \\|", fixed = FALSE)
  # "" is the evidence article linking to anchors on itself -- the one copy of
  # the scoreboard that used to have no links at all
  expect_match(row(link_prefix = ""), "[`only`](#only)", fixed = TRUE)
  expect_match(row(link_prefix = "evidence.html"),
               "[`only`](evidence.html#only)", fixed = TRUE)
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
