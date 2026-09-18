#!/usr/bin/env Rscript
## Regenerate every rendered copy of the claims register from claims.yml.
##
## Run after editing claims.yml. CI runs it too and fails if the tree comes out
## dirty, so a verdict cannot be changed in the register without the front page
## following, and cannot be changed on the front page at all.
##
##   Rscript report/make_scoreboard.R
##   Rscript report/make_scoreboard.R --check    # exit 1 if regeneration changes anything

args <- commandArgs(TRUE)
check_only <- "--check" %in% args

if (requireNamespace("pkgload", quietly = TRUE)) {
  suppressMessages(pkgload::load_all(quiet = TRUE))
} else {
  suppressMessages(library(fleetcheck))
}

root <- fc_root()
claims <- read_claims(file.path(root, "claims.yml"))

targets <- list(
  list(path = file.path(root, "README.md"),
       block = "scoreboard",
       lines = scoreboard_md(claims,
         link_prefix = "https://pwinskill.github.io/fleetcheck/articles/evidence.html")),
  list(path = file.path(root, "report", "index.md"),
       block = "scoreboard",
       lines = scoreboard_md(claims, link_prefix = "evidence.html"))
)

changed <- character()
for (t in targets) {
  if (!file.exists(t$path)) {
    message("skipping (not present yet): ", t$path)
    next
  }
  if (replace_block(t$path, t$block, t$lines, write = !check_only))
    changed <- c(changed, basename(t$path))
}

writeLines(scoreboard(claims))

if (length(changed)) {
  msg <- paste("regenerated:", paste(changed, collapse = ", "))
  if (check_only) {
    stop(msg, "\nclaims.yml has changed and the rendered copies were stale. ",
         "Run report/make_scoreboard.R and commit the result.", call. = FALSE)
  }
  message(msg)
} else {
  message("rendered copies already current")
}
