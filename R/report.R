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

# Exported so the evidence article does not keep a second copy of the map. It
# once did, in different case, so a claim read `pass` in the scoreboard and
# `PASS` in its own section, which flattened the lower-case pass / upper-case
# FAIL contrast the table relies on.

#' Format verdicts as HTML spans
#'
#' Each span has class `verdict` and a class for the status, which the site's
#' stylesheet colours. The text is `pass`, `open`, `FAIL` or `UNTESTED`, so the
#' verdict remains readable where the class is ignored.
#'
#' @param status Character vector of statuses: `"pass"`, `"open"`, `"fail"` or
#'   `"undeclared"`. Any other value is an error.
#' @return A character vector with one span per element of `status`.
#' @export
verdict_html <- function(status) {
  bad <- setdiff(status, names(VERDICT))
  if (length(bad)) stop("unknown status: ", paste(unique(bad), collapse = ", "))
  unname(VERDICT[status])
}

# One headline, used by every rendered form so they cannot come to differ.
headline_md <- function(claims) {
  s <- claims_summary(claims)
  sprintf("**%d claims: %d failing, %d untested, %d open, %d pass.**",
          nrow(claims), s$fail, s$undeclared, s$open, s$pass)
}

# Register order is display order everywhere. The claims are written in the
# order they are meant to be read -- transmission, clinical burden, severe
# burden, how each is distributed by age, interventions, real settings, the
# parameter posterior, then the checks that support all of it -- so re-sorting
# by status here would put the list, the table and the article's sections in
# three different orders from the register all three are generated from.
claim_link <- function(claims, link_prefix)
  if (is.null(link_prefix)) sprintf("`%s`", claims$id) else
    sprintf("[`%s`](%s#%s)", claims$id, link_prefix, claims$id)

#' Evidence article for each parasite
#'
#' Each parasite has its own evidence article, so the two sets of verdicts are
#' never read as one.
#'
#' @param parasite Character vector of `"falciparum"` or `"vivax"`, as in the
#'   `parasite` column returned by [read_claims()].
#' @return A character vector of article file names: `"evidence-vivax.html"`
#'   for `"vivax"` and `"evidence.html"` for anything else.
#' @export
evidence_page <- function(parasite)
  ifelse(parasite == "vivax", "evidence-vivax.html", "evidence.html")

# Design notes for claim_sections_md():
#
# The criterion and the measurement are repeated from the table because links
# from the README land on the section, and a note written against them reads as
# nonsense without them.
#
# The figure is written as an `<img>` rather than `![alt](src)`: pandoc turns a
# markdown image into a `<figure>` and prints the alt text as a caption, which
# put the claim on screen a second time directly under its heading. The alt text
# is the claim and its verdict: an empty alt tells a screen reader the image is
# decorative, and the claim alone would state as true what may have failed.
# Width and height are given so the browser reserves the space before the image
# arrives; without them a deep link to a claim jumps to a position that then
# moves as the images load.

#' Render one evidence-article section per claim
#'
#' Each section has a level-2 heading whose anchor is the claim id, followed by
#' the verdict and the claim, the criterion and measured value, the tier and
#' evidence directory, the claim's figure, its table if it declares one, and its
#' note. Both evidence articles use this, so they present claims identically.
#'
#' A figure is written as an HTML `<img>` whose alt text is the claim and its
#' verdict, with its width and height when the png package can read it. A
#' declared figure or table that is not in `fig_dir` is shown as missing, with a
#' warning. A claim with neither says that the numbers above decide it.
#'
#' @param claims Data frame returned by [read_claims()], filtered to the
#'   article's claims.
#' @param fig_dir Directory holding the figures and tables, relative to the
#'   article.
#' @return A character vector of markdown lines.
#' @export
claim_sections_md <- function(claims, fig_dir = ".") {
  out <- character()
  for (i in seq_len(nrow(claims))) {
    cl <- claims[i, ]
    out <- c(out, sprintf("## %s {#%s}", cl$id, cl$id), "",
             sprintf("%s %s", verdict_html(cl$status), cl$claim), "",
             sprintf("**Criterion:** %s  \n**Measured:** %s", cl$criterion, cl$measured), "",
             sprintf('<p class="claim-meta">tier %d &middot; <code>%s</code></p>',
                     cl$tier, cl$evidence), "")
    fig <- cl$figure
    has_fig <- nzchar(fig) && !fig %in% c("NA", "~")
    src <- if (identical(fig_dir, ".")) fig else file.path(fig_dir, fig)
    tab <- if (is.null(cl$table)) "" else cl$table
    has_tab <- !is.na(tab) && nzchar(tab) && !tab %in% c("NA", "~")
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
    } else if (!has_tab) {
      out <- c(out, "*No figure: the numbers above decide this claim.*", "")
    }
    if (has_tab) {
      tsrc <- if (identical(fig_dir, ".")) tab else file.path(fig_dir, tab)
      if (file.exists(tsrc)) {
        out <- c(out, readLines(tsrc, warn = FALSE, encoding = "UTF-8"), "")
      } else {
        warning("claim ", cl$id, ": table ", tab, " is declared but missing", call. = FALSE)
        out <- c(out, sprintf(paste('<p class="figure-missing"><strong>Table missing:</strong>',
                                    '<code>%s</code> is declared for this claim but is not in',
                                    'this build.</p>'), tab), "")
      }
    }
    if (nzchar(cl$note)) out <- c(out, cl$note, "")
  }
  out
}

#' Render the register as a numbered list
#'
#' The form used in `README.md` and on the site's home page: verdict, id and
#' claim, in register order. The criterion and measured value are left to the
#' evidence articles. When the register holds claims for both parasites, each
#' parasite gets its own heading, count line and numbering.
#'
#' @inheritParams scoreboard_md
#' @return A character vector of markdown lines.
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
             sprintf("%d. %s %s: %s", seq_len(nrow(cl)), VERDICT[cl$status],
                     claim_link(cl, lp), cl$claim),
             if (sp != utils::tail(sps, 1)) "")
  }
  out
}

#' Render the register as a markdown table
#'
#' A count line followed by a table of id, tier, criterion, measured value and
#' verdict, one row per claim in register order. Each evidence article carries
#' this above its claim sections.
#'
#' @param claims Data frame returned by [read_claims()].
#' @param link_prefix Link target for each claim id, to which `#<id>` is
#'   appended: for example `"evidence.html"`, or `""` for an anchor on the same
#'   page. A single string or one per claim. `NULL` renders the ids as code
#'   without links.
#' @return A character vector of markdown lines.
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

#' Escape text for a markdown table cell
#'
#' Escapes `|`, which would otherwise split the row (as in the criterion
#' `|slope - 1| < 0.10`), and replaces line breaks with a space.
#'
#' @param x Character vector.
#' @return `x`, escaped.
#' @export
md_cell <- function(x) {
  x <- gsub("|", "\\|", x, fixed = TRUE)
  gsub("[\r\n]+", " ", x)
}

# The static badges are emitted here too, rather than left in the markdown
# around the generated block, because a marker line splits a markdown paragraph:
# badges on either side of one render as two rows with a gap between them.

#' Render the README badge row
#'
#' The CI and pkgdown workflow badges, one claims badge per parasite, and the
#' lifecycle and licence badges. A claims badge counts claims by verdict and
#' links to that parasite's evidence article. It is green when every claim
#' passes, yellow when any is open or untested and none fails, and orange when
#' any fails. A register with no vivax claims gets a single badge labelled
#' "claims".
#'
#' @param claims Data frame returned by [read_claims()].
#' @param repo GitHub repository, as `"owner/name"`.
#' @param site URL of the published site, with a trailing slash.
#' @return A character vector of markdown lines, one badge each.
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

#' Replace the text between marker comments
#'
#' Replaces the lines between `<!-- BEGIN name -->` and `<!-- END name -->`
#' with `lines`, surrounded by a blank line on each side. The markers are kept,
#' so repeated calls with the same `lines` leave the file unchanged.
#'
#' @param path Path to the file.
#' @param name Marker name. Each marker must occur exactly once, `BEGIN` before
#'   `END`, or the call is an error.
#' @param lines Character vector of replacement lines.
#' @param write If `FALSE`, report whether the file would change without
#'   writing it, as a staleness check needs.
#' @return `TRUE` if the file changed (or would change), otherwise `FALSE`.
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
