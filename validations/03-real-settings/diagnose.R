#!/usr/bin/env Rscript
## Where does tier 3 disagree, and by how much?
##
##   Rscript validations/03-real-settings/diagnose.R
##
## `assess.R` gives the two numbers the register quotes. This gives the 1,391
## sub-sites behind them: every one's monthly clinical series, IBM against fleet,
## as a multi-page PDF, plus an index saying which page each is on.
##
## It exists for the one thing the register leaves open -- fleet runs about 8%
## above the IBM across the site files and that is not explained. A correlation
## cannot say which sub-sites carry the excess; this can.
##
## Triage is BURDEN-AWARE, which is the whole design. At the elimination fringe,
## where incidence is ~1e-3, the fleet/IBM ratio explodes on a trivial absolute
## difference, so ranking by ratio alone fills the front of the document with
## noise and buries any real high-burden problem. Three blocks, in order:
##
##   1. worst agreement among sub-sites carrying material burden
##   2. largest ABSOLUTE discrepancy, which is what case counts feel
##   3. every sub-site, by country, so any one can be found
##
## Output goes to results/ and is not committed: the PDF is ~6 MB, redrawn in a
## couple of minutes from results/raw/, and it is a working document rather than
## evidence.

if (nzchar(.l <- Sys.getenv("FLEET_LIB"))) .libPaths(c(.l, .libPaths()))
.f <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))
ROOT <- if (length(.f)) normalizePath(dirname(.f), "/") else getwd()
while (!file.exists(file.path(ROOT, "DESCRIPTION")) && dirname(ROOT) != ROOT)
  ROOT <- dirname(ROOT)
suppressMessages(pkgload::load_all(ROOT, quiet = TRUE))
suppressMessages({library(dplyr); library(tidyr); library(ggplot2)})
source(file.path(ROOT, "validations", "03-real-settings", "sites_lib.R"))

DDIR <- fc_results("03-real-settings")
OUT  <- file.path(DDIR, "diagnostic_timeseries.pdf")
PER_PAGE <- 12L
N_WORST  <- 48L
MIN_BURDEN <- 0.05                      # IBM cases/person/yr to count as material

d <- read_all_compare(file.path(DDIR, "raw"))
d$site <- paste(d$iso3c, d$name_1, d$urban_rural, sep = "_")
d$time <- d$year + (d$month - 0.5) / 12
d <- d[is.finite(d$ms_clinical) & is.finite(d$fleet_clinical), ]
cat(sprintf("%s sub-site-months, %d sub-sites, %d countries\n",
            format(nrow(d), big.mark = ","), length(unique(d$site)),
            length(unique(d$iso3c))))

## ---- per-site agreement --------------------------------------------------------
per <- d |> group_by(iso3c, name_1, urban_rural, site) |>
  summarise(n = n(), ibm = mean(ms_clinical), fleet = mean(fleet_clinical),
            bias = mean(fleet_clinical - ms_clinical),
            ratio = ifelse(mean(ms_clinical) > 0,
                           mean(fleet_clinical) / mean(ms_clinical), NA_real_),
            r = suppressWarnings(stats::cor(ms_clinical, fleet_clinical)),
            .groups = "drop") |>
  mutate(logdev = abs(log(pmax(ratio, 1e-6))),
         badness = ifelse(is.na(r), logdev, logdev + 2 * (1 - pmin(pmax(r, 0), 1))))
## the strip label carries what you need to judge a panel without leaving it
per$lab <- sprintf("%s %s %s\nr=%.2f  fleet/IBM=%.2f", per$iso3c, per$name_1,
                   per$urban_rural, per$r, per$ratio)

worst     <- per |> filter(ibm >= MIN_BURDEN) |> arrange(desc(badness)) |> head(N_WORST)
worst_abs <- per |> arrange(desc(abs(bias))) |> head(24L)
by_country <- per |> arrange(iso3c, name_1, urban_rural)

chunk <- function(v, k) split(v, ceiling(seq_along(v) / k))
pg_worst <- chunk(worst$site, PER_PAGE)
pg_abs   <- chunk(worst_abs$site, PER_PAGE)
pg_all   <- chunk(by_country$site, PER_PAGE)
pages <- c(pg_worst, pg_abs, pg_all)
sections <- c(
  rep(sprintf("WORST AGREEMENT (burden >= %.2f/person/yr)", MIN_BURDEN), length(pg_worst)),
  rep("LARGEST ABSOLUTE DISCREPANCY", length(pg_abs)),
  rep("ALL SUB-SITES (by country)", length(pg_all)))
cat(sprintf("1 summary page + %d panel pages, %d per page\n", length(pages), PER_PAGE))

theme_d <- theme_bw(base_size = 8) +
  theme(strip.text = element_text(size = 6.2, lineheight = 1.05),
        panel.grid.minor = element_blank(), legend.position = "top",
        plot.title = element_text(face = "bold", size = 11),
        plot.caption = element_text(hjust = 0, colour = "grey40", size = 7))
lab_map <- stats::setNames(per$lab, per$site)

page_plot <- function(sites, title, sub) {
  g <- d |> filter(site %in% sites) |>
    select(site, time, IBM = ms_clinical, fleet = fleet_clinical) |>
    pivot_longer(c(IBM, fleet), names_to = "model", values_to = "clinical") |>
    mutate(site = factor(site, levels = sites),
           lab = factor(lab_map[as.character(site)], levels = lab_map[sites]))
  ggplot(g, aes(time, clinical, colour = model)) +
    geom_line(linewidth = 0.3) +
    ## the register's own series colours, so a panel here reads the same way as
    ## a panel in the committed figures
    scale_colour_manual(values = c(IBM = "#E5533F", fleet = "#4338CA"),
                        breaks = c("IBM", "fleet")) +
    facet_wrap(~lab, scales = "free_y", ncol = 3) +
    labs(title = title, subtitle = sub, x = NULL, colour = NULL,
         y = "clinical incidence (per person per year)",
         caption = "Monthly, all-age, P. falciparum only on both sides. r / ratio in each strip.") +
    theme_d
}

## cairo_pdf handles UTF-8 sub-site names (VNM's "Dak Nong" carries diacritics);
## the base pdf() device mangles them under a single-byte encoding.
if (capabilities("cairo")) {
  cairo_pdf(OUT, width = 11.7, height = 8.3, onefile = TRUE)   # A4 landscape
} else {
  pdf(OUT, width = 11.7, height = 8.3, onefile = TRUE)
}

st <- agreement(d$ms_clinical, d$fleet_clinical)
txt <- paste0(
  "fleet vs malariasimulation - monthly clinical incidence diagnostic\n\n",
  sprintf("%s sub-site-months | %d sub-sites | %d countries | %d-%d\n",
          format(nrow(d), big.mark = ","), length(unique(d$site)),
          length(unique(d$iso3c)), min(d$year), max(d$year)),
  sprintf("monthly clinical:  r = %.3f   slope = %.3f   relative bias = %+.1f%%\n",
          st$cor, st$slope, 100 * st$rel_bias),
  sprintf("per-site median r = %.3f   median fleet/IBM ratio = %.2f\n",
          stats::median(per$r, na.rm = TRUE), stats::median(per$ratio, na.rm = TRUE)),
  sprintf("sub-sites where fleet is higher: %d of %d\n",
          sum(per$ratio > 1, na.rm = TRUE), nrow(per)),
  "\nP. falciparum only on both sides.\n",
  sprintf("\nLayout:\n  pages 2-%d    worst agreement, burden >= %.2f/person/yr\n",
          1 + length(pg_worst), MIN_BURDEN),
  sprintf("  pages %d-%d  largest ABSOLUTE discrepancy\n",
          2 + length(pg_worst), 1 + length(pg_worst) + length(pg_abs)),
  sprintf("  pages %d+     every sub-site, by country\n",
          2 + length(pg_worst) + length(pg_abs)),
  "\nTriage is burden-aware: at the elimination fringe the fleet/IBM ratio explodes\n",
  "on a trivial absolute difference, so ranking by ratio alone surfaces only noise.\n",
  "diagnostic_index.csv gives per-site stats and the page each site is on.")
print(ggplot() + annotate("text", x = 0, y = 0, label = txt, hjust = 0, vjust = 0.5,
                          size = 3.6, family = "mono") +
        xlim(0, 1) + theme_void())

for (i in seq_along(pages)) {
  print(page_plot(pages[[i]],
                  sprintf("%s  -  page %d of %d", sections[i], i, length(pages)),
                  "IBM (coral) vs fleet (indigo)"))
  if (i %% 20 == 0) cat(sprintf("  ...%d/%d pages\n", i, length(pages)))
}
invisible(dev.off())

## ---- index: site -> page, worst first -------------------------------------------
pg <- data.frame(site = unlist(pages, use.names = FALSE),
                 pdf_page = rep(seq_along(pages) + 1L, lengths(pages))) |>
  group_by(site) |>
  summarise(pdf_pages = paste(sort(unique(pdf_page)), collapse = ";"), .groups = "drop")
idx <- per |> left_join(pg, by = "site") |> arrange(desc(badness)) |>
  select(site, iso3c, name_1, urban_rural, n, ibm, fleet, ratio, bias, r, pdf_pages)
write.csv(round_sig(as.data.frame(idx), 10),
          file.path(DDIR, "diagnostic_index.csv"), row.names = FALSE)

cat(sprintf("\nwritten: %s (%.1f MB)\n         %s\n", OUT, file.size(OUT) / 1e6,
            file.path(DDIR, "diagnostic_index.csv")))
show <- function(x) print(as.data.frame(x |> head(10) |>
  select(site, ibm, fleet, ratio, bias, r, pdf_pages) |>
  mutate(across(c(ibm, fleet, ratio, bias, r), \(v) round(v, 3)))), row.names = FALSE)
cat(sprintf("\nworst agreement with burden >= %.2f/person/yr:\n", MIN_BURDEN))
show(idx |> filter(ibm >= MIN_BURDEN))
cat("\nlargest absolute discrepancies:\n")
show(idx |> arrange(desc(abs(bias))))
