#!/usr/bin/env Rscript
## Regenerate every rendered copy of the claims register, and the site's front
## page, from their single sources.
##
##   Rscript report/make_scoreboard.R
##   Rscript report/make_scoreboard.R --check    # exit 1 if anything is stale
##
## CI runs the --check form, so a verdict cannot be changed in the register
## without the rendered copies following, and cannot be changed in a rendered
## copy at all.
##
## There are two sources and three generated things:
##
##   claims.yml  -> the numbered register list inside README.md
##               -> inst/claims.yml, the copy an installed package can find
##   README.md   -> pkgdown/index.md, the site's front page
##
## The evidence article renders its own table from claims.yml at build time, so
## it is not generated here.
##
## README.md is the ONE place the landing-page prose is written. index.md used
## to be a second hand-maintained copy of it, and drifted: two corrections --
## `undeclared` to `UNTESTED`, and "two of the ten" to "three of the eleven" --
## were made in README.md and never reached the site, so the published front
## page went on showing the errors a review had already found. Generating it
## removes that whole class of bug, and `--check` in CI keeps it removed.

args <- commandArgs(TRUE)
check_only <- "--check" %in% args

if (requireNamespace("pkgload", quietly = TRUE)) {
  suppressMessages(pkgload::load_all(quiet = TRUE))
} else {
  suppressMessages(library(fleetcheck))
}

root <- fc_root()
claims <- read_claims(file.path(root, "claims.yml"))
SITE <- "https://pwinskill.github.io/fleetcheck/"

changed <- character()
note <- function(x) changed <<- c(changed, x)

## ---- 1. the scoreboard block in README.md -----------------------------------
## README.md is read on GitHub, where a relative `articles/...` path resolves to
## nothing, so its links are absolute to the published site.
readme <- file.path(root, "README.md")
if (!file.exists(readme))
  stop("README.md is missing. It is the source for pkgdown/index.md, so this ",
       "script cannot run without it.", call. = FALSE)
## The list, not the table: the table is the evidence page's, and carrying both
## put every criterion and every measurement on the site twice.
if (replace_block(readme, "scoreboard",
                  claims_list_md(claims, link_prefix = paste0(SITE, "articles/evidence.html")),
                  write = !check_only))
  note("README.md")

## ---- 2. pkgdown/index.md, generated from README.md --------------------------
## Same prose, different link targets. On the site a link to the site itself
## should be relative, so it works in a local build, in a PR preview and on a
## fork -- none of which are the published host. Links that point AWAY from the
## site, to GitHub, stay absolute, so only the site prefix is stripped.
index <- file.path(root, "pkgdown", "index.md")
src <- readLines(readme, warn = FALSE)
want <- c(
  "<!-- Generated from README.md by report/make_scoreboard.R. Do not edit. -->",
  "",
  gsub(SITE, "", src, fixed = TRUE))
if (!file.exists(index) || !identical(readLines(index, warn = FALSE), want)) {
  note("pkgdown/index.md")
  if (!check_only) {
    dir.create(dirname(index), showWarnings = FALSE, recursive = TRUE)
    writeLines(want, index)
  }
}

## ---- 3. inst/claims.yml -----------------------------------------------------
## The register also lives here so an installed package can find it. It is a
## copy, and a copy with nothing keeping it in step is the exact failure this
## project argues against, so it is regenerated here and checked here too.
inst <- file.path(root, "inst", "claims.yml")
yml <- readLines(file.path(root, "claims.yml"), warn = FALSE)
if (!file.exists(inst) || !identical(readLines(inst, warn = FALSE), yml)) {
  note("inst/claims.yml")
  if (!check_only) writeLines(yml, inst)
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
