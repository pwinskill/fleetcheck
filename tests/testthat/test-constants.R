test_that("int_scenario and int_parts are inverses across the grid", {
  # The runner names the rows with int_scenario(); the renderer reads them back
  # with int_parts(). Those two files never load each other -- one needs
  # malariasimulation attached, the other refuses to require it -- so nothing
  # but this test holds the convention together.
  for (nm in names(INT_LABELS)) {
    s <- int_scenario(nm, PROFILE_EIR)
    expect_equal(length(s), length(PROFILE_EIR))
    expect_false(anyDuplicated(s) > 0)
    p <- int_parts(s)
    expect_equal(p$intervention, rep(nm, length(PROFILE_EIR)))
    expect_equal(p$eir, PROFILE_EIR)
  }
})

test_that("int_scenario vectorises over BOTH arguments", {
  # The renderer asks for every intervention at one EIR; the runner asks for one
  # intervention at one EIR. ifelse() returns the shape of its test, so the
  # first form silently returned a single name and the impact figure drew one
  # intervention where it meant six -- no error, just a quieter figure.
  expect_equal(int_scenario(names(INT_LABELS), 3),
               paste0(names(INT_LABELS), "_e3"))
  expect_equal(int_scenario(names(INT_LABELS), EIR_REF), names(INT_LABELS))
  expect_length(int_scenario(names(INT_LABELS), 120), length(INT_LABELS))
  # every cell of the grid, built the way the renderer builds it
  all_scen <- unlist(lapply(PROFILE_EIR, function(E) int_scenario(names(INT_LABELS), E)))
  expect_length(all_scen, length(INT_LABELS) * length(PROFILE_EIR))
  expect_false(anyDuplicated(all_scen) > 0)
  expect_equal(int_scenario(character(0), 3), character(0))
})

test_that("the reference arm keeps its bare name", {
  # The rows committed before the grid existed are named `nets`, `irs` and so
  # on. Renaming them would have meant re-running every intervention at the one
  # EIR they were already measured at.
  expect_equal(int_scenario("nets", EIR_REF), "nets")
  expect_equal(int_scenario("nets", 3), "nets_e3")
  expect_equal(int_parts("nets")$eir, EIR_REF)
})

test_that("int_parts leaves the non-intervention scenario names alone", {
  # `eir_3` has a digit after an underscore but no `_e` before it, which an
  # over-eager pattern would read as intervention "eir" at EIR 3.
  s <- c("eir_3", "eir_120", "seasonal", "demography", "ts_none", "ts_all")
  p <- int_parts(s)
  expect_equal(p$intervention, s)
  expect_true(all(p$eir == EIR_REF))
})

test_that("PROFILE_EIR is the shared low / reference / high grid", {
  expect_true(EIR_REF %in% PROFILE_EIR)
  expect_equal(PROFILE_EIR, sort(PROFILE_EIR))
  expect_true(all(PROFILE_EIR %in% EIR_GRID))
})

test_that("badges_md reports the register it was given", {
  cl <- read_claims(write_register(
    list(id = "a"), list(id = "b"), list(id = "c", status = "fail")))
  b <- badges_md(cl, repo = "o/r", site = "https://example.org/")
  expect_length(b, 5L)
  expect_true(any(grepl("2%20pass%2C%201%20fail", b, fixed = TRUE)))
  expect_true(any(grepl("-orange.svg", b, fixed = TRUE)))
  expect_true(any(grepl("https://example.org/articles/evidence.html", b, fixed = TRUE)))
  expect_true(any(grepl("o/r/actions/workflows/check.yaml", b, fixed = TRUE)))
})

test_that("badges_md gives vivax its own badge, and keeps it off falciparum's", {
  cl <- read_claims(write_register(
    list(id = "a"), list(id = "b"),
    list(id = "v1", parasite = "vivax", status = "fail")))
  b <- badges_md(cl, repo = "o/r", site = "https://example.org/")
  expect_length(b, 6L)
  pf <- b[grepl("^\\[!\\[Claims:", b)]
  pv <- b[grepl("^\\[!\\[Vivax claims:", b)]
  expect_length(pf, 1L); expect_length(pv, 1L)
  # the vivax failure turns the vivax badge amber and leaves falciparum green
  expect_true(grepl("2%20pass-brightgreen.svg", pf, fixed = TRUE))
  expect_true(grepl("0%20pass%2C%201%20fail-orange.svg", pv, fixed = TRUE))
  # a register with no vivax claims has no vivax badge
  expect_false(any(grepl("Vivax", badges_md(read_claims(write_register(list(id = "a"))),
                                            repo = "o/r", site = "https://example.org/"))))
})

test_that("read_claims knows only the two parasites", {
  expect_equal(read_claims(write_register(list(id = "a")))$parasite, "falciparum")
  expect_error(read_claims(write_register(list(id = "a", parasite = "ovale"))),
               "unknown parasite")
})

test_that("the vivax grid is its own, and names its interventions the same way", {
  expect_true(EIR_REF_PV %in% PROFILE_EIR_PV)
  expect_true(all(PROFILE_EIR_PV %in% EIR_GRID_PV))
  expect_equal(int_scenario("nets", PROFILE_EIR_PV, ref = EIR_REF_PV),
               c("nets_e1", "nets", "nets_e10"))
  expect_equal(int_parts(c("nets_e1", "nets"), ref = EIR_REF_PV)$eir, c(1, EIR_REF_PV))
  # no chemoprevention or vaccine: malariasimulation cannot run them under vivax
  expect_false(any(c("smc", "pmc", "pev") %in% names(INT_LABELS_PV)))
})

test_that("badges_md goes green only when nothing is outstanding", {
  green <- badges_md(read_claims(write_register(list(id = "a"), list(id = "b"))),
                     repo = "o/r", site = "https://example.org/")
  expect_true(any(grepl("-brightgreen.svg", green, fixed = TRUE)))

  # an untested claim is not a failure, but it is not a clean sheet either
  amber <- badges_md(read_claims(write_register(
    list(id = "a"),
    list(id = "b", status = "undeclared", criterion = "NONE DECLARED"))),
    repo = "o/r", site = "https://example.org/")
  expect_true(any(grepl("-yellow.svg", amber, fixed = TRUE)))
  expect_true(any(grepl("1%20untested", amber, fixed = TRUE)))
})
