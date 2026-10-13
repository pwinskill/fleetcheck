#' Read the claims register
#'
#' Parses `claims.yml` and validates it. Each claim must have a non-blank `id`,
#' `claim`, `criterion`, `measured`, `status` and `tier`. `status` must be
#' `pass`, `fail`, `open` or `undeclared`; `tier` an integer from 0 to 3; and
#' `parasite`, if given, `falciparum` or `vivax`. Ids must be unique, and an
#' `undeclared` claim must have `NONE DECLARED` in its criterion. A violation,
#' or an empty register, is an error.
#'
#' @param path Path to `claims.yml`.
#' @return A data frame with one row per claim, in register order, and columns
#'   `id`, `claim`, `criterion`, `tier` (integer), `evidence`, `figure`,
#'   `table`, `measured`, `status`, `note` and `parasite`. An absent `figure`,
#'   `table` or `note` is `""`, and an absent `parasite` is `"falciparum"`.
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
    # a markdown table shown under the figure, for numbers a figure would hide
    table     = field(x, "table", ""),
    measured  = field(x, "measured"),
    status    = field(x, "status"),
    note      = field(x, "note", ""),
    # which parasite the claim is about; absent means falciparum, which every
    # claim was before the vivax suite existed
    parasite  = field(x, "parasite", "falciparum"),
    stringsAsFactors = FALSE
  )))
  bad <- setdiff(out$status, c("pass", "fail", "open", "undeclared"))
  if (length(bad)) stop("unknown status: ", paste(unique(bad), collapse = ", "))
  bad <- setdiff(out$parasite, c("falciparum", "vivax"))
  if (length(bad)) stop("unknown parasite: ", paste(unique(bad), collapse = ", "))
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
#' Searches `start` and each parent directory for `claims.yml`, then falls back
#' to the copy installed with the package. The source copy is excluded by
#' `.Rbuildignore`, so under `R CMD check` the installed copy is the one found.
#'
#' @param start Directory to search upward from.
#' @return The path to `claims.yml`. It is an error if none is found.
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

#' Count claims by verdict
#'
#' @param claims Data frame returned by [read_claims()].
#' @return A named list of integer counts: `pass`, `open`, `fail` and
#'   `undeclared`.
#' @export
claims_summary <- function(claims = read_claims()) {
  levels <- c("pass", "open", "fail", "undeclared")
  tab <- table(factor(claims$status, levels = levels))
  as.list(tab)
}

#' Format the register as plain text
#'
#' A line of counts by verdict, then one line per claim giving its verdict,
#' tier, id and measured value. Claims are in register order, not sorted by
#' verdict.
#'
#' @param claims Data frame returned by [read_claims()].
#' @return A character vector of lines, for [writeLines()].
#' @export
scoreboard <- function(claims = read_claims()) {
  s <- claims_summary(claims)
  # `----` for undeclared made an untested claim look like an absent row rather
  # than an unresolved one; see the note in scoreboard_md()
  mark <- c(pass = "PASS", open = "OPEN", fail = "FAIL", undeclared = "UNTESTED")
  lines <- sprintf("  %-8s  t%-2s  %-26s  %s",
                   mark[claims$status], claims$tier,
                   claims$id, claims$measured)
  c(sprintf("%d claims: %d failing, %d untested (no criterion declared), %d open, %d pass",
            nrow(claims), s$fail, s$undeclared, s$open, s$pass),
    "", lines)
}

#' Fail if any claim has regressed
#'
#' Prints [scoreboard()], then signals an error if a claim with status `fail`
#' is not in `allow_fail`. An `undeclared` claim is a gap in the register rather
#' than a regression, so it is reported but does not fail. CI runs this.
#'
#' @param claims Data frame returned by [read_claims()].
#' @param allow_fail Ids of claims whose failure is accepted. Each must exist in
#'   the register and have a `note` explaining why, or the call is an error.
#' @return `claims`, invisibly.
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
