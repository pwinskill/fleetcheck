#' Read the claims register
#'
#' @param path path to `claims.yml`.
#' @return a data frame, one row per claim.
#' @export
read_claims <- function(path = find_claims()) {
  raw <- yaml::read_yaml(path)
  field <- function(x, nm, default = NA_character_) {
    v <- x[[nm]]
    if (is.null(v)) default else trimws(as.character(v))
  }
  if (!length(raw))
    stop("claims.yml parsed to nothing. An empty register used to return NULL, ",
         "which made scoreboard() print one blank line and check_claims() pass ",
         "without checking anything.", call. = FALSE)
  # Present-but-empty counts as missing. `criterion:` with nothing after it
  # parses to NULL, which becomes NA, and nzchar(NA) is TRUE -- so the test that
  # checked every claim was "well formed" could not see a blank field at all.
  req <- c("id", "claim", "criterion", "measured", "status", "tier")
  for (i in seq_along(raw)) {
    filled <- vapply(req, function(nm) {
      v <- raw[[i]][[nm]]
      !is.null(v) && length(v) == 1L && !is.na(v) && nzchar(trimws(as.character(v)))
    }, logical(1))
    if (any(!filled))
      stop("claim ", i, " (", raw[[i]][["id"]] %||% "no id", ") is missing or ",
           "blank in: ", paste(req[!filled], collapse = ", "), call. = FALSE)
  }
  out <- do.call(rbind, lapply(raw, function(x) data.frame(
    id        = field(x, "id"),
    claim     = field(x, "claim"),
    criterion = field(x, "criterion"),
    tier      = suppressWarnings(as.integer(x[["tier"]])),
    evidence  = field(x, "evidence"),
    figure    = field(x, "figure", ""),
    measured  = field(x, "measured"),
    status    = field(x, "status"),
    note      = field(x, "note", ""),
    stringsAsFactors = FALSE
  )))
  bad <- setdiff(out$status, c("pass", "fail", "open", "undeclared"))
  if (length(bad)) stop("unknown status: ", paste(unique(bad), collapse = ", "))
  if (anyDuplicated(out$id)) stop("duplicate claim id: ", out$id[anyDuplicated(out$id)])

  if (any(is.na(out$tier) | out$tier < 0L | out$tier > 3L))
    stop("tier must be 0-3: ", paste(out$id[is.na(out$tier) | out$tier < 0L |
                                            out$tier > 3L], collapse = ", "))
  # An undeclared claim must say so where a reader looks, not only in a field.
  und <- out$status == "undeclared"
  if (any(und & !grepl("NONE DECLARED", out$criterion, fixed = TRUE)))
    stop("status `undeclared` but the criterion does not say NONE DECLARED: ",
         paste(out$id[und & !grepl("NONE DECLARED", out$criterion, fixed = TRUE)],
               collapse = ", "))
  out
}

`%||%` <- function(x, y) if (is.null(x)) y else x

#' Locate the claims register
#'
#' Walks up from `start` looking for `claims.yml`, then falls back to the copy
#' shipped inside the installed package. The fallback is not a nicety: the
#' register is `.Rbuildignore`d, so under `R CMD check` the source copy is not
#' there at all, and without this every test that reads it fails while
#' `devtools::test()` in the source tree passes. Same shape as the incident this
#' project exists to document -- a green suite over a broken artefact.
#'
#' @param start directory to search upward from.
#' @return a path to a readable `claims.yml`.
#' @export
find_claims <- function(start = getwd()) {
  d <- normalizePath(start, "/", mustWork = FALSE)
  repeat {
    p <- file.path(d, "claims.yml")
    if (file.exists(p)) return(p)
    up <- dirname(d)
    if (identical(up, d)) break
    d <- up
  }
  p <- system.file("claims.yml", package = "fleetcheck")
  if (nzchar(p) && file.exists(p)) return(p)
  stop("claims.yml not found above ", start,
       ", and none shipped with the installed package.", call. = FALSE)
}

#' Counts by verdict
#' @param claims as returned by [read_claims()].
#' @export
claims_summary <- function(claims = read_claims()) {
  levels <- c("pass", "open", "fail", "undeclared")
  tab <- table(factor(claims$status, levels = levels))
  as.list(tab)
}

#' The scoreboard, as printable text
#'
#' Deliberately leads with what is unresolved. A reader of a comparison page
#' should meet the verdict before the figures, not be left to infer it from
#' eight plots.
#'
#' @param claims as returned by [read_claims()].
#' @export
scoreboard <- function(claims = read_claims()) {
  s <- claims_summary(claims)
  # `----` for undeclared made an untested claim look like an absent row rather
  # than an unresolved one; see the note in scoreboard_md()
  mark <- c(pass = "PASS", open = "OPEN", fail = "FAIL", undeclared = "UNTESTED")
  ord <- order(match(claims$status, c("fail", "undeclared", "open", "pass")))
  lines <- sprintf("  %-8s  t%-2s  %-26s  %s",
                   mark[claims$status[ord]], claims$tier[ord],
                   claims$id[ord], claims$measured[ord])
  c(sprintf("%d claims: %d failing, %d untested (no criterion declared), %d open, %d pass",
            nrow(claims), s$fail, s$undeclared, s$open, s$pass),
    "", lines)
}

#' Fail if the register has regressed
#'
#' For CI. `undeclared` does not fail -- a claim with no criterion is a gap in
#' the register, not a regression -- but it is always reported, so the count
#' cannot quietly grow.
#'
#' @param claims as returned by [read_claims()].
#' @param allow_fail claim ids whose failure is known and accepted, each of
#'   which must carry a `note` explaining why it is tolerated.
#' @export
check_claims <- function(claims = read_claims(), allow_fail = character()) {
  writeLines(scoreboard(claims))
  failing <- claims[claims$status == "fail", ]
  unexpected <- setdiff(failing$id, allow_fail)
  # the two are separate mistakes and read as separate mistakes: a renamed claim
  # is not the same problem as an undocumented tolerance
  hit <- match(allow_fail, claims$id)
  absent <- allow_fail[is.na(hit)]
  if (length(absent))
    stop("allow_fail names no such claim: ", paste(absent, collapse = ", "))
  undocumented <- allow_fail[!nzchar(claims$note[hit])]
  if (length(undocumented))
    stop("allow_fail entries with no note explaining the tolerance: ",
         paste(undocumented, collapse = ", "))
  if (length(unexpected))
    stop("claims failing and not in allow_fail: ",
         paste(unexpected, collapse = ", "))
  invisible(claims)
}
