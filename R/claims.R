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
  out <- do.call(rbind, lapply(raw, function(x) data.frame(
    id        = field(x, "id"),
    claim     = field(x, "claim"),
    criterion = field(x, "criterion"),
    declared  = field(x, "declared", "unknown"),
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
  if (anyDuplicated(out$id)) stop("duplicate claim id")
  out
}

find_claims <- function(start = getwd()) {
  d <- normalizePath(start, "/", mustWork = FALSE)
  repeat {
    p <- file.path(d, "claims.yml")
    if (file.exists(p)) return(p)
    up <- dirname(d)
    if (identical(up, d)) stop("claims.yml not found above ", start)
    d <- up
  }
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
  mark <- c(pass = "PASS", open = "OPEN", fail = "FAIL", undeclared = "----")
  ord <- order(match(claims$status, c("fail", "undeclared", "open", "pass")))
  lines <- sprintf("  %-4s  t%-2s  %-26s  %s",
                   mark[claims$status[ord]], claims$tier[ord],
                   claims$id[ord], claims$measured[ord])
  c(sprintf("%d claims: %d pass, %d open, %d fail, %d with no criterion declared",
            nrow(claims), s$pass, s$open, s$fail, s$undeclared),
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
  undocumented <- allow_fail[
    !nzchar(claims$note[match(allow_fail, claims$id)]) |
      is.na(match(allow_fail, claims$id))]
  if (length(undocumented))
    stop("allow_fail entries with no note, or no such claim: ",
         paste(undocumented, collapse = ", "))
  if (length(unexpected))
    stop("claims failing and not in allow_fail: ",
         paste(unexpected, collapse = ", "))
  invisible(claims)
}
