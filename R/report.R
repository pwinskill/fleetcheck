#' The scoreboard as a markdown table
#'
#' Rendered into README.md and into the site's front page by
#' `report/make_scoreboard.R`, never typed by hand. A scoreboard maintained in
#' prose alongside a register in YAML is two copies of the same facts, and this
#' project exists partly because of what that did to `fleet`'s documentation.
#'
#' @param claims as returned by [read_claims()].
#' @param link_prefix prefix for the per-claim anchors, e.g. `"evidence.html"`.
#' @return a character vector of markdown lines.
#' @export
scoreboard_md <- function(claims = read_claims(), link_prefix = "") {
  badge <- c(pass = "**pass**", open = "open", fail = "**FAIL**",
             undeclared = "*no criterion*")
  # unresolved first: a reader should meet what is wrong before what is right
  ord <- order(match(claims$status, c("fail", "undeclared", "open", "pass")),
               claims$tier)
  cl <- claims[ord, ]
  id <- if (nzchar(link_prefix))
    sprintf("[`%s`](%s#%s)", cl$id, link_prefix, cl$id) else sprintf("`%s`", cl$id)

  s <- claims_summary(claims)
  c(sprintf("**%d claims — %d pass, %d open, %d failing, %d with no criterion declared.**",
            nrow(claims), s$pass, s$open, s$fail, s$undeclared),
    "",
    "| claim | tier | criterion | measured | verdict |",
    "| --- | --- | --- | --- | --- |",
    sprintf("| %s | %d | %s | %s | %s |",
            id, cl$tier, md_cell(cl$criterion), md_cell(cl$measured),
            badge[cl$status]))
}

#' Make a string safe inside a markdown table cell
#'
#' A criterion is written for a human, so it can contain anything -- and one of
#' them is `|slope - 1| < 0.10`, whose pipes silently split the row into extra
#' columns. Newlines do the same to the table.
#'
#' @param x character vector.
#' @export
md_cell <- function(x) {
  x <- gsub("|", "\\|", x, fixed = TRUE)
  gsub("[\r\n]+", " ", x)
}

#' Replace a marked block in a file
#'
#' Rewrites whatever sits between `<!-- BEGIN name -->` and `<!-- END name -->`.
#' The markers stay, so the file can be regenerated any number of times and a
#' CI job can fail when the tree comes out dirty.
#'
#' @param path file to edit.
#' @param name marker name.
#' @param lines replacement content.
#' @param write actually write. `FALSE` reports what would change and leaves the
#'   file alone — which is what a staleness check needs. The first version of
#'   this wrote before it reported, so running the check dirtied the very tree it
#'   was checking, and a failing CI job left the working copy modified.
#' @return `TRUE` if the file changed, or would have.
#' @export
replace_block <- function(path, name, lines, write = TRUE) {
  txt <- readLines(path, warn = FALSE)
  b <- grep(sprintf("<!-- BEGIN %s -->", name), txt, fixed = TRUE)
  e <- grep(sprintf("<!-- END %s -->", name), txt, fixed = TRUE)
  if (length(b) != 1L || length(e) != 1L || e <= b)
    stop("markers for '", name, "' not found exactly once, in order, in ", path)
  new <- c(txt[seq_len(b)], "", lines, "", txt[e:length(txt)])
  if (identical(new, txt)) return(FALSE)
  if (write) writeLines(new, path)
  TRUE
}
