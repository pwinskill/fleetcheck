# The parameter-draws figure, from the saved cells (no model runs).
#
#   Rscript validations/04-parameter-draws/render.R              # -> man/figures + vignettes
#   CMP_SMOKE=1 Rscript validations/04-parameter-draws/render.R  # from results/smoke -> results/plots/smoke
#
# Reads results/draws_cells.csv, which assess.R writes. All visual decisions
# live in theme.R: this is the intervention-impact figure's layout, with each
# draw's change from the default parameters in place of an intervention's
# reduction.

## No absolute paths anywhere in here. FLEET_LIB is prepended to the library
## path, for installations that do not pick up R_LIBS_USER (the Windows-arm64
## setup this was developed on); the libraries already on the path are kept. ROOT
## is found by walking up to the DESCRIPTION, so this runs from any working
## directory and on anyone's checkout, whether via Rscript or source().
if (nzchar(.l <- Sys.getenv("FLEET_LIB"))) .libPaths(c(.l, .libPaths()))
.f <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))
ROOT <- if (length(.f)) normalizePath(dirname(.f), "/") else getwd()
while (!file.exists(file.path(ROOT, "DESCRIPTION")) && dirname(ROOT) != ROOT)
  ROOT <- dirname(ROOT)
if (!file.exists(file.path(ROOT, "DESCRIPTION")))
  stop("run this from inside the fleetcheck checkout (no DESCRIPTION found above ", getwd(), ")")
## fc_root() and fc_results() resolve from here, not from the working directory
Sys.setenv(FLEETCHECK_ROOT = ROOT)
if (requireNamespace("pkgload", quietly = TRUE) &&
    file.exists(file.path(ROOT, "DESCRIPTION"))) {
  suppressMessages(pkgload::load_all(ROOT, quiet = TRUE))
} else {
  suppressMessages(library(fleetcheck))
}
source(file.path(ROOT, "validations", "_shared", "theme.R"))

SMOKE <- nzchar(Sys.getenv("CMP_SMOKE"))
DDIR <- fc_results("04-parameter-draws")
out_dirs <- file.path(ROOT, c("man/figures", "vignettes"))
if (SMOKE) {                                   # smoke data must never overwrite the real figure
  BURN_Y <- 1L; DDIR <- file.path(DDIR, "smoke")
  out_dirs <- fc_results("04-parameter-draws", "plots", "smoke")
}
cells <- read.csv(file.path(DDIR, "draws_cells.csv"), stringsAsFactors = FALSE)
eq <- read.csv(file.path(DDIR, "rep_eq.csv"), stringsAsFactors = FALSE)
n_rep <- max(eq$rep[eq$model == "IBM"])
## a cell with no band is not drawn as anything: assess.R fails on it, and only
## a smoke run should get this far with one
if (!SMOKE && anyNA(cells[c("ibm_change", "ibm_change_lower", "ibm_change_upper", "fleet_change")]))
  stop("results/draws_cells.csv has cells with no band; assess.R should not have passed it.",
       call. = FALSE)

## one row per draw, named for the percentile of fleet's outcome at EIR 20 it
## was chosen at, the clinical draws above the severe ones with a gap between
OUTCOME <- c(clin_all = "clinical", sev_all = "severe")
ordinal <- function(q) {
  k <- 100 * q
  suf <- ifelse(k != round(k) | round(k) %% 100 %in% 11:13, "th",
                c("th", "st", "nd", "rd", rep("th", 6))[round(k) %% 10 + 1])
  paste0(format(k, trim = TRUE, drop0trailing = TRUE), suf)
}
eir_list <- function(e) sub(", ([^,]*)$", " and \\1", paste(e, collapse = ", "))
picks <- unique(cells[order(cells$chosen_for, cells$quantile), c("draw", "chosen_for", "quantile")])
picks$row <- sprintf("%s, %s percentile (draw %d)", OUTCOME[picks$chosen_for],
                     ordinal(picks$quantile), picks$draw)
rows <- unlist(lapply(split(picks$row, picks$chosen_for), function(r) c(r, " ")))
rows <- rows[-length(rows)]
MET_LAB <- c(pfpr_2_10 = "LM prevalence, ages 2–10",
             clin_0_5 = "clinical incidence, ages 0–5",
             clin_all = "clinical incidence, all ages",
             sev_all = "severe incidence, all ages")
EIRS <- sort(unique(cells$eir))

lab <- function(x) data.frame(scenario = picks$row[match(x$draw, picks$draw)],
                              eir = factor(sprintf("EIR %g", x$eir), levels = sprintf("EIR %g", EIRS)),
                              metric = factor(MET_LAB[x$metric], levels = MET_LAB))
both <- rbind(
  cbind(lab(cells), model = "IBM", mid = cells$ibm_change,
        lo = cells$ibm_change_lower, hi = cells$ibm_change_upper),
  cbind(lab(cells), model = "fleet", mid = cells$fleet_change, lo = NA_real_, hi = NA_real_))

n_words <- function(n) if (n <= 10) c("One", "Two", "Three", "Four", "Five", "Six", "Seven",
                                       "Eight", "Nine", "Ten")[n] else format(n)
g <- fig_impact(both, rows,
  title = "P. falciparum: what a parameter draw does to each outcome, in both models",
  subtitle = subt(sprintf(paste(
    "%s of malariasimulation's 1,000 posterior parameter draws at EIR %s, each shown as",
    "its change from the default parameters at the same EIR. Each row is named for the",
    "percentile of fleet's all-age clinical or severe incidence at EIR 20 it was chosen at."),
    n_words(nrow(picks)), eir_list(EIRS))),
  caption = cap(
    sprintf(paste("IBM: %d stochastic replicate%s of %s people at each draw and at the default",
                  "parameters; point = median, shaded bar = replicate band, median ± 1.28 SD of the",
                  "change between every replicate at the draw and every one at the default parameters.",
                  "fleet: one deterministic run at the draw over one at the default parameters."),
            n_rep, if (n_rep == 1) "" else "s", format(POP, big.mark = ",")),
    IMPACT_NOTE,
    sprintf(paste("Both models start from set_equilibrium()'s seed and run the same %d-year",
                  "burn-in; each outcome is the mean of the final three years."), BURN_Y),
    "Plotted values are in results/draws_cells.csv.",
    fig_width = 12),
  x_lab = "change from the default parameters (each outcome on its own scale)",
  x_scale = scale_x_continuous(labels = scales::label_percent(style_negative = "minus"),
                               breaks = breaks_few(), expand = expansion(mult = 0.08)),
  scales = "free_x")
save_fig(g, "draws", width = 12, height = 12.5, dirs = out_dirs)
cat("figure written to", paste(out_dirs, collapse = " and "), "\n")
