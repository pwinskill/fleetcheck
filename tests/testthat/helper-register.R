# A register built to order, so the tests do not depend on what the real one
# happens to contain.
#
# Two of the register tests used to read `claims.yml` and then skip, because
# nothing in it fails and nothing in it is `open`. That left `check_claims()` --
# the function CI relies on to catch a regression -- with no coverage at all,
# and left the "unresolved sorts above resolved" test running zero expectations.
# A test that skips on the happy path only ever runs when it is too late.

#' Write a claims register and return its path.
#'
#' @param ... one list per claim, each overriding the template below.
write_register <- function(..., envir = parent.frame()) {
  claims <- list(...)
  tmpl <- list(id = "x", claim = "a claim.", criterion = "a criterion",
               declared = "retrospective", tier = 1L, evidence = "validations/00",
               measured = "a number", status = "pass")
  yml <- vapply(seq_along(claims), function(i) {
    cl <- utils::modifyList(tmpl, claims[[i]])
    fields <- vapply(names(cl), function(nm) {
      v <- cl[[nm]]
      # a NULL override means "omit this field", which is how the missing-field
      # path is exercised
      if (is.null(v)) "" else sprintf("  %s: %s\n", nm, format_yaml(v))
    }, character(1))
    paste0("- ", sub("^  ", "", paste(fields, collapse = "")))
  }, character(1))
  p <- withr::local_tempfile(fileext = ".yml", .local_envir = envir)
  writeLines(paste(yml, collapse = "\n"), p)
  p
}

format_yaml <- function(v) {
  if (is.numeric(v)) return(as.character(v))
  # quoted, so a criterion containing a colon or a pipe stays one scalar
  paste0('"', gsub('"', '\\\\"', v), '"')
}
