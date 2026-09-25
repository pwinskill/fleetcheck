# House style for the fleet-vs-malariasimulation comparison figures.
#
# Sourced by run.R (live) and render.R (re-render from saved
# CSVs), so the two never drift. Everything visual lives here: palette, theme,
# series scales, and the small helpers every figure shares.
#
# Design rules (see the dataviz method the figures were built against):
#   * Two series, IBM vs fleet, encoded THREE ways -- colour, line type, point
#     shape -- so every panel reads in greyscale and under colour-vision
#     deficiency. Palette validated: indigo/coral pass CVD dE 27 (protan) and
#     normal-vision dE 38; both >= 3:1 on white.
#   * The IBM is stochastic. It is drawn as the median of N replicates with its
#     replicate band (median +/- 1.28 SD) at ~15% opacity, never as one noisy
#     realisation.
#   * LAYER ORDER: where the two series overlap -- which, when the models agree,
#     is everywhere -- the mark that hides less goes on top. So the IBM's dashed
#     median draws OVER fleet's solid line (the solid shows through the gaps, so
#     both read), while fleet's hollow point draws OVER the IBM's filled one.
#     The envelope always sits at the bottom. Get this backwards and agreement
#     looks like a single series.
#   * Thin marks, hairline SOLID gridlines one step off the surface, no panel
#     border, legend at the top, titles left-aligned. Text never wears a series
#     colour.
#   * One y-axis per panel. Two measures = two panels (patchwork), never a dual axis.

## paths and the shared scenario constants; visuals only from here down

suppressMessages({library(ggplot2); library(patchwork)})

## ---- palette (site colours: _pkgdown.yml primary / danger) ------------------
COL <- c(IBM = "#E5533F", fleet = "#4338CA")
LTY <- c(IBM = "22",      fleet = "solid")        # dashed / solid
SHP <- c(IBM = 21,        fleet = 24)             # filled circle / triangle
INK   <- "#111827"; INK2 <- "#52514E"; MUTED <- "#898781"
## reference lines (1:1 agreement). Orange, because it is hue-opposed to the
## indigo hex ramp and is NOT a series colour, so it can never be read as a
## model. Hue contrast is what carries it: at 4.2:1 on white it reads on the
## pale fills, and against the deep indigo core the opposed hue does the work.
REF   <- "#D94801"
GRID  <- "#E5E7EB"; AXIS <- "#C9CCD1"; SURFACE <- "#FFFFFF"
## light tints of the two series, for bars, and the site-file hexbins' ramp:
## near-white at the sparse end so the 1:1 ridge carries the ink
TINT <- c(IBM = "#F3B3A9", fleet = "#B3ADEA")
HEX_LOW <- "#F4F6FE"; HEX_HIGH <- "#171449"
ENV_ALPHA <- 0.16                                 # IBM envelope wash

FONT <- if ("Segoe UI" %in% systemfonts::system_fonts()$family) "Segoe UI" else "sans"

theme_cmp <- function(base_size = 13) {
  theme_minimal(base_size = base_size, base_family = FONT) +
    theme(
      text = element_text(colour = INK),
      plot.title = element_text(face = "bold", size = rel(1.15), hjust = 0,
                                margin = margin(b = 4)),
      plot.subtitle = element_text(colour = INK2, size = rel(0.95), hjust = 0,
                                   margin = margin(b = 10)),
      plot.caption = element_text(colour = MUTED, size = rel(0.78), hjust = 0,
                                  margin = margin(t = 10)),
      plot.title.position = "plot", plot.caption.position = "plot",
      panel.grid.major = element_line(colour = GRID, linewidth = 0.4),
      panel.grid.minor = element_blank(),
      axis.line.x = element_line(colour = AXIS, linewidth = 0.4),
      axis.ticks = element_blank(),
      axis.title = element_text(colour = INK2, size = rel(0.9)),
      axis.text = element_text(colour = INK2, size = rel(0.85)),
      legend.position = "top", legend.justification = "left",
      legend.title = element_blank(), legend.key.width = unit(1.6, "lines"),
      legend.margin = margin(0, 0, 0, 0), legend.box.spacing = unit(6, "pt"),
      strip.text = element_text(face = "bold", colour = INK, hjust = 0,
                                size = rel(0.95), margin = margin(b = 6)),
      strip.background = element_blank(), strip.placement = "outside",
      plot.background = element_rect(fill = SURFACE, colour = NA),
      panel.spacing = unit(1.4, "lines"),
      plot.margin = margin(10, 14, 8, 10)
    )
}

## series scales -- every panel that draws both models uses exactly these
## fleet's point is hollow -- filled with the surface -- so where it sits on the
## IBM's filled one both read, as the layer-order rule above intends; the fill
## joins the legend so its keys show the markers the panels draw
scale_models <- function(shapes = TRUE, lines = TRUE) {
  s <- list(scale_colour_manual(values = COL, breaks = c("IBM", "fleet")),
            scale_fill_manual(values = c(IBM = COL[["IBM"]], fleet = SURFACE),
                              breaks = c("IBM", "fleet")),
            labs(colour = NULL, linetype = NULL, shape = NULL, fill = NULL))
  if (lines)  s <- c(s, list(scale_linetype_manual(values = LTY, breaks = c("IBM", "fleet"))))
  if (shapes) s <- c(s, list(scale_shape_manual(values = SHP, breaks = c("IBM", "fleet"))))
  s
}
## a legend that shows line + point together, in the same order everywhere
guide_models <- function() guides(
  colour = guide_legend(override.aes = list(linewidth = 0.9, size = 2.6)))
## Captions do not wrap on their own, so they are folded here -- and how many
## characters fit is a property of the DEVICE, not a constant. The default was a
## bare 135, tuned for the 10-inch figures, while the four single-outcome EIR
## panels are saved at 6.2 inches: their caption was folded a third wider than
## the panel and ran off both edges. Pass fig_width, or width to set the
## character count directly, which is what the hand-tuned subtitles do.
cap <- function(..., fig_width = 10, width = round(13.5 * fig_width))
  paste(strwrap(paste(...), width = width), collapse = "\n")

## ---- data helpers -----------------------------------------------------------
## IBM replicate summary per x, for a value column. The band is the package's
## replicate_band(), so the figures draw the interval the criteria are decided
## on rather than a second one that resembles it.
envelope <- function(d, by, value = "y") {
  stopifnot(all(c(by, "rep", value) %in% names(d)))
  d <- d[is.finite(d[[value]]), ]
  agg <- function(f) aggregate(d[[value]], d[by], f)
  out <- agg(stats::median); names(out)[ncol(out)] <- "mid"
  col <- length(by) + 1L
  out$mid <- agg(function(v) replicate_band(v)$centre)[[col]]
  out$lo  <- agg(function(v) replicate_band(v)$lower)[[col]]
  out$hi  <- agg(function(v) replicate_band(v)$upper)[[col]]
  out$model <- "IBM"
  out
}

## ---- shared claim panels ------------------------------------------------------
## The age-profile panel both parasites' age-profile claims rest on. x is the age
## BAND, not a continuous age, for three reasons, and the last is the important
## one. The bands are unequal -- one year wide in infancy, twenty-five at the top
## -- so a continuous axis gives a quarter of its width to the last band. On a
## linear age axis both outcomes are flat and near zero above age 20, so most of
## the panel carried no information. And the criterion is band by band: drawing
## bands as bands means the reader sees exactly what is being tested, whether
## fleet is inside the IBM's range HERE. Bands carrying less than BURDEN_MIN of
## the outcome are drawn but not scored, and shaded, so the figure and the
## criterion say the same thing.
## `ap` has one row per model, replicate, transmission level (`eir`, a factor)
## and age band (`age_lo`, `age_hi`, `pop_frac`), and the outcome column `m`.
panel_outcome <- function(ap, m, ylab) {
  d <- dplyr::rename(ap, y = !!m)
  bl <- dplyr::arrange(dplyr::distinct(d, age_lo, age_hi), age_lo)
  lv <- sprintf("%g-%g", bl$age_lo, bl$age_hi)
  d$band <- factor(sprintf("%g-%g", d$age_lo, d$age_hi), levels = lv)
  gi <- d[d$model == "IBM", ] |> dplyr::group_by(eir, band) |>
    dplyr::summarise(mid = replicate_band(y)$centre, lo = replicate_band(y)$lower,
                     hi = replicate_band(y)$upper, .groups = "drop") |>
    dplyr::mutate(model = "IBM")
  go <- d[d$model == "fleet", ] |> dplyr::transmute(eir, band, mid = y, model = "fleet")
  untested <- d[d$model == "IBM", ] |> dplyr::group_by(eir, band) |>
    dplyr::summarise(ep = stats::median(y * pop_frac), .groups = "drop") |>
    dplyr::group_by(eir) |> dplyr::mutate(share = ep / sum(ep)) |> dplyr::ungroup() |>
    dplyr::filter(share < BURDEN_MIN) |> dplyr::mutate(x = as.numeric(band))
  ggplot(mapping = aes(band, mid, colour = model)) +
    geom_rect(data = untested, inherit.aes = FALSE,
              aes(xmin = x - 0.5, xmax = x + 0.5, ymin = -Inf, ymax = Inf),
              fill = MUTED, alpha = 0.10) +
    geom_linerange(data = gi, aes(ymin = lo, ymax = hi), linewidth = 2.4,
                   alpha = 0.30, show.legend = FALSE) +
    geom_line(data = go, aes(group = 1, linetype = model), linewidth = 0.7) +
    geom_line(data = gi, aes(group = 1, linetype = model), linewidth = 0.7) +
    geom_point(data = gi, aes(shape = model, fill = model), size = 2, stroke = 0.4) +
    geom_point(data = go, aes(shape = model, fill = model), size = 2, stroke = 0.4) +
    facet_wrap(~ eir, nrow = 1, scales = "free_y") +
    scale_models() + guide_models() +
    scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.06))) +
    labs(x = "age band (years)", y = ylab) +
    theme_cmp() +
    theme(legend.position = "top", legend.justification = "left",
          axis.text.x = element_text(angle = 45, hjust = 1, size = rel(0.8)))
}
BAND_NOTE <- paste("Thick bars are the IBM's replicate band, median \u00b1 1.28 SD; fleet is one",
                   "deterministic run. Shaded bands carry under 5% of the outcome and are not",
                   "scored -- the claim rests on the unshaded ones. Bands are finer in",
                   "childhood, so equal spacing here is not equal width in years.")

## The test itself, beside a curve that cannot show it: fleet against the IBM
## median at each EIR, with the IBM's own replicate band as the tolerance. A
## hollow triangle inside the grey passes; a solid one outside misses.
panel_deviation <- function(gi, go, breaks) {
  d <- merge(gi[, c("init_EIR", "mid", "lo", "hi")],
             setNames(go[, c("init_EIR", "mid")], c("init_EIR", "fleet")), by = "init_EIR")
  d$rel <- 100 * (d$fleet / d$mid - 1)
  d$lo_r <- 100 * (d$lo / d$mid - 1); d$hi_r <- 100 * (d$hi / d$mid - 1)
  d$where <- factor(ifelse(d$fleet < d$lo | d$fleet > d$hi, "outside", "inside"),
                    levels = c("inside", "outside"))
  ggplot(d, aes(init_EIR)) +
    geom_linerange(aes(ymin = lo_r, ymax = hi_r), colour = MUTED, alpha = 0.35,
                   linewidth = 7) +
    geom_hline(yintercept = 0, colour = AXIS, linewidth = 0.5) +
    geom_point(aes(y = rel, shape = where), colour = COL[["fleet"]], fill = SURFACE,
               size = 2.6, stroke = 0.6, show.legend = TRUE) +
    scale_shape_manual(values = c(inside = 24, outside = 17), drop = FALSE,
                       labels = c(inside = "fleet inside the band", outside = "fleet outside it"),
                       name = NULL) +
    scale_x_log10(breaks = breaks, labels = scales::label_number(drop0trailing = TRUE),
                  minor_breaks = NULL) +
    labs(x = "EIR passed to set_equilibrium() (bites per adult per year, log scale)",
         y = "fleet vs the IBM median (%)") +
    theme_cmp()
}
## the impact figures' fleet rows that fall outside the IBM's band in their cell
outside_cells <- function(both) {
  ibm <- both[both$model == "IBM", c("scenario", "eir", "metric", "lo", "hi")]
  fl <- merge(both[both$model == "fleet", c("scenario", "eir", "metric", "mid")], ibm,
              by = c("scenario", "eir", "metric"))
  fl[fl$mid < fl$lo | fl$mid > fl$hi, ]
}
DEV_NOTE <- paste("Right: fleet as a percentage of the IBM median; grey = the IBM's replicate band",
                  "at each EIR, the tolerance the claim is decided on.")

## save to BOTH homes: man/figures (README, GitHub) and vignettes (pkgdown article)
save_fig <- function(g, name, width, height, dpi = 200) {
  for (dir in c("man/figures", "vignettes")) {
    d <- file.path(fc_root(), dir)
    dir.create(d, recursive = TRUE, showWarnings = FALSE)
    f <- file.path(d, paste0("cmp_", name, ".png"))
    ggsave(f, g, width = width, height = height, dpi = dpi, device = ragg::agg_png,
           bg = SURFACE)
  }
  invisible(g)
}
