#' The scoreboard as a markdown table
#'
#' Rendered into README.md and into the site's front page by
#' `report/make_scoreboard.R`, never typed by hand. A scoreboard maintained in
#' prose alongside a register in YAML is two copies of the same facts, and this
#' project exists partly because of what that did to `fleet`'s documentation.
#'
#' @param claims as returned by [read_claims()].
#' @param link_prefix prefix for the per-claim anchors, e.g. `"evidence.html"`.
#'   `""` links to anchors on the same page, which is what the evidence article
#'   itself needs. `NULL` renders the ids as plain code, with no links at all.
#' @return a character vector of markdown lines.
#' @export
scoreboard_md <- function(claims = read_claims(), link_prefix = NULL) {
  # Verdicts are emitted as HTML spans, not as markdown emphasis, because three
  # states need three visually distinct treatments and CSS cannot read the text
  # of a cell. A span with a class gives the stylesheet the hook: red for a
  # failure, green for a pass, grey for an untested claim.
  #
  # This degrades rather than breaks where the class is ignored. On GitHub the
  # markdown renderer strips the attribute but keeps the element and its text,
  # so the column still reads FAIL / pass / UNTESTED; in a terminal,
  # scoreboard() prints its own plain-text version and never sees this.
  badge <- c(
    pass       = '<span class="verdict pass">pass</span>',
    open       = '<span class="verdict open">open</span>',
    fail       = '<span class="verdict fail">FAIL</span>',
    undeclared = '<span class="verdict untested">UNTESTED</span>')
  # unresolved first: a reader should meet what is wrong before what is right
  ord <- order(match(claims$status, c("fail", "undeclared", "open", "pass")),
               claims$tier)
  cl <- claims[ord, ]
  id <- if (is.null(link_prefix)) sprintf("`%s`", cl$id) else
    sprintf("[`%s`](%s#%s)", cl$id, link_prefix, cl$id)

  s <- claims_summary(claims)
  # counted in the order the rows are sorted in, most unresolved first
  c(sprintf("**%d claims \u2014 %d failing, %d untested, %d open, %d pass.**",
            nrow(claims), s$fail, s$undeclared, s$open, s$pass),
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
