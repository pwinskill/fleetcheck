#!/usr/bin/env Rscript
## Regenerate every rendered copy of the claims register from claims.yml.
##
##   Rscript report/make_scoreboard.R
##   Rscript report/make_scoreboard.R --check    # exit 1 if anything is stale
##
## CI runs the --check form, so a verdict cannot be changed in the register
## without the rendered copies following, and cannot be changed in a rendered
## copy at all.

args <- commandArgs(TRUE)
check_only <- "--check" %in% args

if (requireNamespace("pkgload", quietly = TRUE)) {
  suppressMessages(pkgload::load_all(quiet = TRUE))
} else {
  suppressMessages(library(fleetcheck))
}

root <- fc_root()
claims <- read_claims(file.path(root, "claims.yml"))

## Two renderings, with different link targets.
##
## README.md is read on GitHub, where a relative `articles/...` path resolves to
## nothing, so its links are absolute to the published site.
##
## pkgdown/index.md becomes the site home page -- pkgdown prefers it over
## README.md -- and its links are relative, so they work in a local build, in a
## PR preview, and on a fork, none of which are the published host. The first
## version of this pointed at report/index.md, which pkgdown never reads and
## which did not exist, so it was skipped every run and all eleven links on the
## home page were absolute to a host that 404s.
targets <- list(
  list(path = file.path(root, "README.md"),
       block = "scoreboard",
       lines = scoreboard_md(
         claims,
         link_prefix = "https://pwinskill.github.io/fleetcheck/articles/evidence.html")),
  list(path = file.path(root, "pkgdown", "index.md"),
       block = "scoreboard",
       lines = scoreboard_md(claims, link_prefix = "articles/evidence.html"))
)

## The register also lives at inst/claims.yml so that an installed package can
## find it. It is a copy, and a copy with nothing keeping it in step is the exact
## failure this project argues against, so it is regenerated here and checked
## here too.
inst <- file.path(root, "inst", "claims.yml")
src <- readLines(file.path(root, "claims.yml"), warn = FALSE)
inst_stale <- !file.exists(inst) || !identical(readLines(inst, warn = FALSE), src)

changed <- character()
for (t in targets) {
  if (!file.exists(t$path))
    stop("target does not exist: ", t$path,
         "\nA missing target used to be skipped with a message, which made this ",
         "script pass while rendering nothing.", call. = FALSE)
  if (replace_block(t$path, t$block, t$lines, write = !check_only))
    changed <- c(changed, basename(t$path))
}
if (inst_stale) {
  changed <- c(changed, "inst/claims.yml")
  if (!check_only) writeLines(src, inst)
}

writeLines(scoreboard(claims))

if (length(changed)) {
  msg <- paste("stale:", paste(changed, collapse = ", "))
  if (check_only)
    stop(msg, "\nRun report/make_scoreboard.R and commit the result.", call. = FALSE)
  message("regenerated: ", paste(changed, collapse = ", "))
} else {
  message("rendered copies already current")
}
