# The parameter-draws claim quotes validations/04-parameter-draws/results, and
# nothing re-runs a model to check it. This is the tier-0 check that the
# register says what the committed evidence says, and that the evidence has the
# shape the suite promises. validations/ is .Rbuildignore'd, so under R CMD check
# there is nothing here to look at, and the tests say so rather than pass.

res <- testthat::test_path("..", "..", "validations", "04-parameter-draws", "results")
needs_results <- function() {
  testthat::skip_if_not(dir.exists(res), "validations/ is not in the built package")
  testthat::skip_if_not_installed("jsonlite")
}
rd <- function(f) utils::read.csv(file.path(res, f), stringsAsFactors = FALSE)
the_claim <- function() {
  cl <- read_claims(find_claims(testthat::test_path("..", "..")))
  cl[cl$id == "parameter-draws", ]
}

test_that("every cell is there and scored, over every pair of replicates", {
  needs_results()
  cells <- rd("draws_cells.csv"); draws <- rd("draws.csv")
  ref <- jsonlite::read_json(file.path(res, "ibm_reference.json"), simplifyVector = TRUE)
  expect_equal(nrow(cells), nrow(draws) * length(ref$eir) * 4L)
  expect_setequal(unique(cells$draw), draws$draw)
  expect_false(anyNA(cells[c("ibm_change", "ibm_change_lower", "ibm_change_upper",
                             "fleet_change", "change_inside")]))
  # every replicate at the draw over every one at the default parameters
  expect_true(all(cells$n_ratios == ref$n_rep^2))
  expect_identical(as.integer(ref$draws), as.integer(draws$draw))
})

test_that("the register quotes the committed cells", {
  needs_results()
  cl <- the_claim(); cells <- rd("draws_cells.csv")
  expect_equal(nrow(cl), 1L)
  m <- regmatches(cl$measured, regexec("inside at ([0-9]+) of ([0-9]+)", cl$measured))[[1]]
  expect_equal(as.integer(m[2]), sum(cells$change_inside))
  expect_equal(as.integer(m[3]), nrow(cells))
  z <- regmatches(cl$measured, regexec("largest departure ([0-9.]+) replicate SD", cl$measured))[[1]]
  expect_equal(as.numeric(z[2]), round(max(abs(cells$change_z)), 2))
  # the criterion is met exactly when every cell is inside; `open` is met too
  expect_equal(cl$status %in% c("pass", "open"), all(cells$change_inside))
})

test_that("the refused draws are the ones the sweep could not run, and none was chosen", {
  needs_results()
  sweep <- rd("fleet_sweep.csv"); refused <- rd("refused.csv"); draws <- rd("draws.csv")
  expect_setequal(paste(refused$draw, refused$eir),
                  with(sweep[is.na(sweep$clin_all), ], paste(draw, eir)))
  expect_false(any(draws$draw %in% refused$draw))
  for (d in unique(refused$draw)) expect_match(the_claim()$note, as.character(d), fixed = TRUE)
})

test_that("each chosen draw sits at its percentile of the sweep", {
  needs_results()
  sweep <- rd("fleet_sweep.csv"); draws <- rd("draws.csv")
  ran <- sweep[sweep$eir == 20 & !sweep$draw %in% sweep$draw[is.na(sweep$clin_all)], ]
  # one distinct draw for each outcome and percentile select.R chooses on
  expect_setequal(paste(draws$chosen_for, draws$quantile),
                  paste(rep(c("clin_all", "sev_all"), each = 4), c(0.05, 0.25, 0.75, 0.95)))
  expect_equal(anyDuplicated(draws$draw), 0L)
  # each within select.R's PICK_TOL, a quarter of a percentile point, of its
  # target among the draws fleet runs, and carrying the sweep's values
  for (i in seq_len(nrow(draws))) {
    v <- ran[[draws$chosen_for[i]]]
    row <- ran[ran$draw == draws$draw[i], ]
    expect_equal(nrow(row), 1L)
    expect_lte(abs(100 * mean(v <= row[[draws$chosen_for[i]]]) - 100 * draws$quantile[i]), 0.25)
    expect_equal(unlist(row[c("b0", "clin_all", "sev_all")]),
                 unlist(draws[i, c("b0", "clin_all", "sev_all")]), ignore_attr = TRUE)
  }
})
