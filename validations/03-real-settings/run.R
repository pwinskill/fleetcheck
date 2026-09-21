#!/usr/bin/env Rscript
## Tier 3: fleet against malariasimulation across every pf sub-site in the
## malariaverse site files.
##
##   FLEET_VALIDATE=/path/to/site-files Rscript validations/03-real-settings/run.R
##   FLEET_VALIDATE=... CMP_ONLY=BFA,GHA Rscript .../run.R   # a few countries
##   FLEET_WORKERS=4 Rscript .../run.R                        # smaller pool
##
## THIS RUNS FLEET ONLY, and not as an option. The IBM side is the pre-run
## diagnostic shipped with each site file (calibration_epi_output/<ISO>_diagnostic_epi.rds),
## which is what makes a refresh affordable: re-running the IBM for 1,391
## sub-sites is the part that would need a cluster, and nothing here does it. So
## a fleet-side change is re-measured by re-running this, and the IBM arm cannot
## drift while that happens.
##
## Each country runs in its own callr subprocess from a worker pool, so a
## segfault in one country is logged and the rest are unaffected, and the run is
## resumable: a country whose result already exists is skipped. Delete
## results/raw/ to force a full re-run.
##
## Raw per-country output goes to results/raw/ and is NOT committed, per the
## rule this project applies everywhere: only summaries and stamps. Run
## assess.R afterwards to turn it into the committed statistics.

if (nzchar(.l <- Sys.getenv("FLEET_LIB"))) .libPaths(c(.l, .libPaths()))
.f <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))
ROOT <- if (length(.f)) normalizePath(dirname(.f), "/") else getwd()
while (!file.exists(file.path(ROOT, "DESCRIPTION")) && dirname(ROOT) != ROOT)
  ROOT <- dirname(ROOT)
if (!file.exists(file.path(ROOT, "DESCRIPTION")))
  stop("run this from inside the fleetcheck checkout (no DESCRIPTION found above ",
       getwd(), ")", call. = FALSE)
suppressMessages(pkgload::load_all(ROOT, quiet = TRUE))
source(file.path(ROOT, "validations", "03-real-settings", "sites_lib.R"))

## fc_results() rather than a path built here, so the one definition of where a
## tier's results live is the package's
RAW <- fc_results("03-real-settings", "raw")
dir.create(RAW, showWarnings = FALSE, recursive = TRUE)
log_msg <- function(...) cat(sprintf("[%s] %s\n", format(Sys.time(), "%H:%M:%S"),
                                     sprintf(...)))

iso <- site_isos()
only <- Filter(nzchar, strsplit(Sys.getenv("CMP_ONLY"), ",")[[1]])
if (length(only)) {
  unknown <- setdiff(only, iso)
  if (length(unknown))
    stop("CMP_ONLY names no site file: ", paste(unknown, collapse = ", "), call. = FALSE)
  iso <- only
}
done <- sub("_compare[.]rds$", "", basename(Sys.glob(file.path(RAW, "*_compare.rds"))))
todo <- setdiff(iso, done)
log_msg("%d countries: %d already done, %d to run", length(iso), length(iso) - length(todo),
        length(todo))
if (!length(todo)) {
  log_msg("nothing to do. Delete %s to force a re-run.", RAW)
  quit(status = 0)
}

W <- suppressWarnings(as.integer(Sys.getenv("FLEET_WORKERS")))
if (is.na(W) || W < 1L) {
  n <- parallel::detectCores(logical = TRUE)   # NA on some platforms
  W <- if (is.na(n)) 2L else max(1L, min(10L, n - 2L))
}
log_msg("pool of %d workers; fleet only, the IBM arm is the shipped diagnostic", W)

t0 <- Sys.time()
queue <- todo; running <- list(); failed <- character()
finished <- 0L
logfile <- function(nm) file.path(RAW, paste0(nm, ".log"))
repeat {
  while (length(running) < W && length(queue)) {
    nm <- queue[1]; queue <- queue[-1]
    running[[nm]] <- callr::r_bg(
      function(root, iso, out) {
        source(file.path(root, "validations", "03-real-settings", "sites_lib.R"))
        r <- run_country(iso)
        ## write to a temporary name and rename, so a worker killed mid-write
        ## cannot leave a truncated file that the resume glob counts as done
        if (!is.null(r)) { saveRDS(r, paste0(out, ".part")); file.rename(paste0(out, ".part"), out) }
        !is.null(r)
      },
      args = list(root = ROOT, iso = nm, out = file.path(RAW, paste0(nm, "_compare.rds"))),
      ## A FILE, not a pipe. With stdout = "|" nothing drains the pipe, so once
      ## a worker has written ~64 KB the OS buffer fills, the child blocks
      ## mid-write, is_alive() stays TRUE and the pool hangs for ever with no
      ## timeout. A large country runs 100+ sub-sites through five packages that
      ## message() freely, so that is reachable. A file has no such limit, and it
      ## also keeps the traceback of a failed country instead of discarding it
      ## into a pipe nothing reads.
      supervise = TRUE, stdout = logfile(nm), stderr = "2>&1")
  }
  if (!length(running)) break
  Sys.sleep(0.5)
  for (nm in names(running)) {
    p <- running[[nm]]
    if (p$is_alive()) next
    ok <- tryCatch(isTRUE(p$get_result()), error = function(e) FALSE)
    finished <- finished + 1L
    if (!ok) failed <- c(failed, nm)
    log_msg("%-4s %-4s  (%d/%d)", nm, if (ok) "ok" else "FAIL", finished, length(todo))
    ## a failure is only useful with its reason attached
    if (!ok && file.exists(logfile(nm))) {
      tail_lines <- utils::tail(readLines(logfile(nm), warn = FALSE), 6L)
      if (length(tail_lines)) cat(paste0("       | ", tail_lines, "\n"), sep = "")
    }
    running[[nm]] <- NULL
  }
}
log_msg("done in %.1f min; %d failed%s", as.numeric(Sys.time() - t0, units = "mins"),
        length(failed), if (length(failed)) paste0(": ", paste(failed, collapse = ", ")) else "")
log_msg("now run validations/03-real-settings/assess.R")
