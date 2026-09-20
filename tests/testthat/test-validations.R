# Nothing tested `validations/` at all, and a rewiring pass silently deleted the
# `source()` line that defines run_fleet(), scenarios and AGE_TAGS from four of
# the five scripts. Everything still parsed, the package still loaded, and the
# suite stayed green; it took a ninety-second smoke run to find it.
#
# This is the cheap static half of that smoke run. It cannot run the scripts --
# they need malariasimulation and about twenty-five minutes -- but it can check
# that every project symbol a script mentions is one that something the script
# loads actually defines. That is exactly the failure above, and it needs no
# packages beyond codetools, so it runs in the tier-0 CI job.
#
# Only *project* symbols are checked: fleetcheck's exports, and the definitions
# in validations/_shared. Package functions and dplyr's bare column names are
# left alone, which is what keeps this free of false positives.

vdir <- testthat::test_path("..", "..", "validations")

# `validations/` is .Rbuildignore'd, so under R CMD check it is not there at
# all and this whole file has nothing to look at. That is a real absence rather
# than a passing check, so every test below says so out loud instead of quietly
# finding zero scripts and agreeing with itself. CI runs devtools::test() on the
# source tree, where they all run.
have_validations <- dir.exists(vdir)
needs_source_tree <- function()
  testthat::skip_if_not(have_validations,
                        "validations/ is not in the built package")

# Top-level names a file binds, and the globals it refers to. Wrapping the
# script in a function body is what makes findGlobals() usable on a script: the
# script's own top-level assignments become locals, so they drop out of the
# global set, which is the right answer here -- a script provides its own.
script_symbols <- function(path) {
  exprs <- parse(path, keep.source = FALSE)
  f <- eval(call("function", NULL, as.call(c(as.name("{"), as.list(exprs)))))
  g <- codetools::findGlobals(f, merge = TRUE)
  assigned <- unlist(lapply(exprs, function(e)
    if (is.call(e) && length(e) >= 2L &&
        as.character(e[[1L]]) %in% c("<-", "=", "<<-") && is.name(e[[2L]]))
      as.character(e[[2L]])))
  list(uses = g, defines = unique(c(assigned, character())))
}

# which _shared files a script sources, by the filename in the source() call
sourced_shared <- function(path) {
  txt <- readLines(path, warn = FALSE)
  hits <- regmatches(txt, gregexpr('"[A-Za-z0-9_]+\\.R"', txt))
  on_source <- grepl("source\\(", txt)
  unique(gsub('"', "", unlist(hits[on_source])))
}

shared_files <- if (have_validations)
  list.files(file.path(vdir, "_shared"), "\\.R$", full.names = TRUE) else character()
shared <- stats::setNames(lapply(shared_files, script_symbols),
                          basename(shared_files))
runners <- if (have_validations)
  setdiff(list.files(vdir, "\\.R$", recursive = TRUE, full.names = TRUE),
          shared_files) else character()

test_that("there are validation scripts to check", {
  needs_source_tree()
  expect_gt(length(runners), 0)
  expect_gt(length(shared_files), 0)
})

test_that("every project symbol a runner uses is one it has loaded", {
  needs_source_tree()
  pkg <- getNamespaceExports("fleetcheck")
  universe <- unique(c(pkg, unlist(lapply(shared, `[[`, "defines"))))

  for (path in runners) {
    s <- script_symbols(path)
    from <- sourced_shared(path)
    available <- unique(c(pkg, s$defines,
                          unlist(lapply(shared[from], `[[`, "defines"))))
    missing <- setdiff(intersect(s$uses, universe), available)
    expect_equal(missing, character(0),
                 info = sprintf("%s uses %s but sources only %s",
                                basename(path), paste(missing, collapse = ", "),
                                paste(from, collapse = ", ")))
  }
})

test_that("the shared files get their own project symbols from the package", {
  needs_source_tree()
  pkg <- getNamespaceExports("fleetcheck")
  universe <- unique(c(pkg, unlist(lapply(shared, `[[`, "defines"))))
  for (nm in names(shared)) {
    s <- shared[[nm]]
    from <- sourced_shared(file.path(vdir, "_shared", nm))
    available <- unique(c(pkg, s$defines,
                          unlist(lapply(shared[from], `[[`, "defines"))))
    expect_equal(setdiff(intersect(s$uses, universe), available), character(0),
                 info = sprintf("_shared/%s", nm))
  }
})

test_that("nothing is sourced that is never used", {
  needs_source_tree()
  # The converse of the check above, and it found three: render.R, tables.R and
  # benchmark.R each sourced scenarios.R, and tables.R sourced theme.R as well,
  # while referring to nothing either file defines. Sourcing scenarios.R builds
  # every malariasimulation parameter list in it at load time, so redrawing a
  # figure needed an IBM install it never called.
  #
  # If a shared file is ever added that is sourced for a side effect rather than
  # for what it defines, this is the test that will complain about it.
  for (path in runners) {
    s <- script_symbols(path)
    for (nm in sourced_shared(path)) {
      used <- intersect(s$uses, setdiff(shared[[nm]]$defines, s$defines))
      expect_gt(length(used), 0)
    }
  }
})

test_that("every runner loads the package one way or another", {
  needs_source_tree()
  # the check above is only meaningful if the script really does get fleetcheck's
  # exports; a script that loaded neither would pass it vacuously
  for (path in runners) {
    txt <- paste(readLines(path, warn = FALSE), collapse = "\n")
    expect_true(grepl("pkgload::load_all", txt, fixed = TRUE) ||
                  grepl("library(fleetcheck)", txt, fixed = TRUE),
                info = basename(path))
  }
})

test_that("the scripts agree with the register about where evidence lives", {
  needs_source_tree()
  cl <- read_claims(find_claims())
  # every `evidence:` path in the register must exist, or the site links a
  # reader to a directory that is not there
  for (e in unique(cl$evidence))
    expect_true(dir.exists(testthat::test_path("..", "..", e)), info = e)
})
