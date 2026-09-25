# Verdicts are emitted as HTML spans, not as markdown emphasis, because four
# states need four distinct treatments and CSS cannot read the text of
# a cell. A span with a class gives the stylesheet the hook: red for a failure,
# green for a pass, amber for an untested claim.
#
# This degrades rather than breaks where the class is ignored. On GitHub the
# markdown renderer strips the attribute but keeps the element and its text, so
# it still reads FAIL / pass / UNTESTED; in a terminal, scoreboard() prints its
# own plain-text version and never sees this.
VERDICT <- c(
  pass       = '<span class="verdict pass">pass</span>',
  open       = '<span class="verdict open">open</span>',
  fail       = '<span class="verdict fail">FAIL</span>',
  undeclared = '<span class="verdict untested">UNTESTED</span>')

#' A verdict as its HTML lozenge
#'
#' Exported so the evidence article does not keep a second copy of the map. It
#' did, in different case, so the same claim read `pass` in the scoreboard and
#' `PASS` in its own section -- and the quiet-pass / shouted-FAIL contrast, which
#' is how the table shows what needs attention, was flattened in the sections.
#'
#' @param status one of `pass`, `open`, `fail`, `undeclared`.
#' @return one span per status.
#' @export
verdict_html <- function(status) {
  bad <- setdiff(status, names(VERDICT))
  if (length(bad)) stop("unknown status: ", paste(unique(bad), collapse = ", "))
  unname(VERDICT[status])
}

# One headline, used by every rendered form so they cannot come to differ.
headline_md <- function(claims) {
  s <- claims_summary(claims)
  sprintf("**%d claims \u2014 %d failing, %d untested, %d open, %d pass.**",
          nrow(claims), s$fail, s$undeclared, s$open, s$pass)
}

# Register order is display order everywhere. The claims are written in the
# order they are meant to be read -- transmission, clinical burden, severe
# burden, how each is distributed by age, interventions, real settings, then the
# checks that support all of it -- so re-sorting by status here would put the
# list, the table and the article's sections in three different orders from the
# register all three are generated from.
claim_link <- function(claims, link_prefix)
  if (is.null(link_prefix)) sprintf("`%s`", claims$id) else
    sprintf("[`%s`](%s#%s)", claims$id, link_prefix, claims$id)

#' The evidence article a claim is presented on
#'
#' Each parasite has an evidence page of its own, so a reader after the vivax
#' results does not scroll past eleven falciparum claims to reach them, and the
#' two sets of verdicts are never read as one.
#'
#' @param parasite character vector of `"falciparum"` or `"vivax"`, as
#'   [read_claims()] returns it.
#' @return the article's file name for each element.
#' @export
evidence_page <- function(parasite)
  ifelse(parasite == "vivax", "evidence-vivax.html", "evidence.html")

#' The evidence article's section for each claim
#'
#' A heading, the verdict and the claim, the criterion that decides it and what
#' was measured against it, what the result cost to produce and where its code
#' is, the one figure that is evidence for the claim, and the note. Both
#' evidence articles render their sections with this, so the two cannot drift
#' apart in how a claim is presented. The criterion and the measurement are
#' repeated from the table because a README link lands on the section, and a
#' note written against them reads as nonsense without them.
#'
#' A figure the register declares but the build does not have is shown as
#' missing, loudly, rather than passed off as a claim with no figure.
#'
#' The figure is written as an `<img>` rather than `![alt](src)`: pandoc turns a
#' markdown image into a `<figure>` and prints the alt text as a caption, which
#' put the claim on screen a second time directly under the heading that had
#' just said it. The alt text is the claim and its verdict, because an empty alt
#' tells a screen reader the image is decorative, on a page whose entire content
#' is evidence, and the claim alone would state as true what may have failed.
#' Width and height are given so the browser reserves the space before the image
#' arrives; without them a deep link to a claim, which is how the README and the
#' front page arrive, jumps to a position that then moves as the images load.
#'
#' @param claims as returned by [read_claims()], filtered to the page's claims.
#' @param fig_dir where the figures are, relative to the article.
#' @return a character vector of markdown lines.
#' @export
claim_sections_md <- function(claims, fig_dir = ".") {
  out <- character()
  for (i in seq_len(nrow(claims))) {
    cl <- claims[i, ]
    out <- c(out, sprintf("## %s {#%s}", cl$id, cl$id), "",
             sprintf("%s &mdash; %s", verdict_html(cl$status), cl$claim), "",
             sprintf("**Criterion:** %s  \n**Measured:** %s", cl$criterion, cl$measured), "",
             sprintf('<p class="claim-meta">tier %d &middot; <code>%s</code></p>',
                     cl$tier, cl$evidence), "")
    fig <- cl$figure
    has_fig <- nzchar(fig) && !fig %in% c("NA", "~")
    src <- if (identical(fig_dir, ".")) fig else file.path(fig_dir, fig)
    word <- c(pass = "pass", open = "open", fail = "fail", undeclared = "untested")[[cl$status]]
    if (has_fig && file.exists(src)) {
      d <- if (requireNamespace("png", quietly = TRUE))
        tryCatch(dim(png::readPNG(src)), error = function(e) NULL)
      alt <- gsub('"', "&quot;", sprintf("%s Verdict: %s.", cl$claim, word), fixed = TRUE)
      out <- c(out, sprintf('<a href="%s"><img src="%s"%s alt="%s"></a>', src, src,
                            if (length(d) >= 2) sprintf(' width="%d" height="%d"', d[2], d[1]) else "",
                            alt), "")
    } else if (has_fig) {
      warning("claim ", cl$id, ": figure ", fig, " is declared but missing", call. = FALSE)
      out <- c(out, sprintf(paste('<p class="figure-missing"><strong>Figure missing:</strong>',
                                  '<code>%s</code> is declared for this claim but is not in',
                                  'this build.</p>'), fig), "")
    } else {
      out <- c(out, "*No figure: the numbers above decide this claim.*", "")
    }
    if (nzchar(cl$note)) out <- c(out, cl$note, "")
  }
  out
}

#' The register as a numbered list
#'
#' What README and the site's front page carry. A reader arriving there wants to
#' know what was compared and how it came out; the criterion each claim was
#' judged against and the number that met it are a level of detail below that,
#' and they live in the table on the evidence page. Printing both put every one
#' of those sentences on the site twice.
#'
#' @inheritParams scoreboard_md
#' @return a character vector of markdown lines.
#' @export
claims_list_md <- function(claims = read_claims(), link_prefix = NULL) {
  # One list per parasite, each with its own headline: the two registers ask the
  # same questions in the same words, and one list over both would read as
  # contradicting itself wherever the verdicts differ.
  par <- if (is.null(claims$parasite)) rep("falciparum", nrow(claims)) else claims$parasite
  sps <- intersect(c("falciparum", "vivax"), par)
  out <- character()
  for (sp in sps) {
    keep <- par == sp
    cl <- claims[keep, , drop = FALSE]
    lp <- if (length(link_prefix) > 1) link_prefix[keep] else link_prefix
    out <- c(out, if (length(sps) > 1) c(sprintf("### *P. %s*", sp), ""),
             headline_md(cl), "",
             sprintf("%d. %s %s &mdash; %s", seq_len(nrow(cl)), VERDICT[cl$status],
                     claim_link(cl, lp), cl$claim),
             if (sp != utils::tail(sps, 1)) "")
  }
  out
}

#' The register as a markdown table
#'
#' What the evidence article carries, above the section for each claim. This is
#' where the detail lives: the criterion, what was measured against it, and the
#' verdict. Rendered by `report/make_scoreboard.R` and by the
#' article itself, never typed by hand -- a scoreboard maintained in prose
#' alongside a register in YAML is two copies of the same facts, and this
#' project exists partly because of what that did to `fleet`'s documentation.
#'
#' @param claims as returned by [read_claims()].
#' @param link_prefix prefix for the per-claim anchors, e.g. `"evidence.html"`.
#'   `""` links to anchors on the same page, which is what the evidence article
#'   itself needs. `NULL` renders the ids as plain code, with no links at all.
#' @return a character vector of markdown lines.
#' @export
scoreboard_md <- function(claims = read_claims(), link_prefix = NULL) {
  c(headline_md(claims), "",
    "| claim | tier | criterion | measured | verdict |",
    "| --- | --- | --- | --- | --- |",
    sprintf("| %s | %d | %s | %s | %s |",
            claim_link(claims, link_prefix), claims$tier,
            md_cell(claims$criterion), md_cell(claims$measured),
            VERDICT[claims$status]))
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

#' The README badge row
#'
#' The one badge worth having here reports the register, so it is generated from
#' the register rather than typed: a hand-written "all claims pass" that outlived
#' the failure it was written for is the exact drift this project exists to stop.
#'
#' The static badges are emitted here too, rather than left in the markdown
#' around a generated block, because a marker line splits a markdown paragraph.
#' Badges written either side of one render as two rows with a gap between them.
#'
#' @param claims as returned by [read_claims()].
#' @param repo `owner/name` on GitHub.
#' @param site the published site, used as the claims badge's target.
#' @return a character vector of markdown lines, one badge each.
#' @export
badges_md <- function(claims = read_claims(),
                      repo = "pwinskill/fleetcheck",
                      site = "https://pwinskill.github.io/fleetcheck/") {
  # One claims badge per parasite, so a vivax result can never recolour the
  # falciparum badge, nor a falciparum one the vivax. With both on the register
  # each badge names its parasite; claims with no parasite field are falciparum.
  par <- if (is.null(claims$parasite)) rep("falciparum", nrow(claims)) else claims$parasite
  claim_msg <- function(cl) {
    s <- claims_summary(cl)
    bad <- s$fail + s$undeclared + s$open
    # Green only when there is nothing outstanding; red would overstate one
    # failing band in one age group as a broken comparison.
    colour <- if (s$fail > 0) "orange" else if (bad > 0) "yellow" else "brightgreen"
    parts <- c(sprintf("%d pass", s$pass),
               if (s$fail) sprintf("%d fail", s$fail),
               if (s$open) sprintf("%d open", s$open),
               if (s$undeclared) sprintf("%d untested", s$undeclared))
    list(msg = paste(parts, collapse = ", "), colour = colour)
  }
  pf <- claim_msg(claims[par == "falciparum", , drop = FALSE])
  pv <- if (any(par == "vivax")) claim_msg(claims[par == "vivax", , drop = FALSE])

  # shields.io: a literal dash is doubled, everything else percent-encoded.
  enc <- function(x) utils::URLencode(gsub("-", "--", x, fixed = TRUE), reserved = TRUE)
  shield <- function(label, message, col)
    sprintf("https://img.shields.io/badge/%s-%s-%s.svg",
            enc(label), enc(message), col)
  action <- function(wf)
    sprintf("https://github.com/%s/actions/workflows/%s.yaml", repo, wf)

  badge <- function(alt, img, href) sprintf("[![%s](%s)](%s)", alt, img, href)
  c(badge("check", paste0(action("check"), "/badge.svg"), action("check")),
    badge("pkgdown", paste0(action("pkgdown"), "/badge.svg"), action("pkgdown")),
    badge(paste0(if (is.null(pv)) "Claims: " else "Falciparum claims: ", pf$msg),
          shield(if (is.null(pv)) "claims" else "falciparum claims", pf$msg, pf$colour),
          paste0(site, "articles/evidence.html")),
    if (!is.null(pv))
      badge(paste0("Vivax claims: ", pv$msg), shield("vivax claims", pv$msg, pv$colour),
            paste0(site, "articles/", evidence_page("vivax"))),
    badge("Lifecycle: experimental",
          shield("lifecycle", "experimental", "orange"),
          "https://lifecycle.r-lib.org/articles/stages.html#experimental"),
    badge("License: MIT", shield("license", "MIT", "blue"),
          sprintf("https://github.com/%s/blob/main/LICENSE", repo)))
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
