# House style for the fleet-vs-malariasimulation comparison figures.
#
# Sourced by run.R (live) and render.R / render_pv.R (re-render from saved CSVs),
# so the three never drift. Everything visual lives here: palette, theme, series
# scales, the shared labels, and the panels and figures both parasites draw.
#
# Design rules (see the dataviz method the figures were built against):
#   * Two series, IBM vs fleet, encoded THREE ways -- colour, line type, point
#     shape -- so every panel reads in greyscale and under colour-vision
#     deficiency. Palette validated: indigo/coral pass CVD dE 27 (protan) and
#     normal-vision dE 38; both >= 3:1 on white.
#   * The IBM is stochastic. It is drawn as the median of N replicates with its
#     replicate band (median +/- 1.28 SD), never as one noisy realisation. The
#     band is the IBM's colour, translucent, everywhere: a bar at a discrete x
#     (an EIR, an age band, an impact cell, a deviation panel), a ribbon along a
#     continuous x (a season, a time series). The IBM legend key carries it.
#   * LAYER ORDER: where the two series overlap -- which, when the models agree,
#     is everywhere -- the mark that hides less goes on top. So the IBM's dashed
#     median draws OVER fleet's solid line (the solid shows through the gaps, so
#     both read), while fleet's hollow point draws OVER the IBM's filled one.
#     The band always sits at the bottom. Get this backwards and agreement looks
#     like a single series.
#   * Every test of fleet against the IBM's band -- EIR by EIR, band by band, cell
#     by cell -- marks fleet the same way: a hollow triangle inside the band, a
#     filled one outside it, named in the legend. Never colour alone.
#   * Hierarchy: the figure title, its subtitle (a sentence, ending in a full
#     stop), then panel titles and facet strips at one size, lower case. A panel
#     gets a title only where its axes do not already say what it shows. Every
#     title of a parasite's figure starts with its name and a colon.
#   * Text is set in proportion to the canvas (save_fig()), because every figure
#     is shown at the article's column width: a 14-inch figure and a 9-inch one
#     then read at the same size.
#   * Thin marks, hairline SOLID gridlines one step off the surface, no panel
#     border, legend at the top aligned with the title, titles left-aligned. Text
#     never wears a series colour. Typography: en dashes in ranges, true minus
#     signs, em dashes in prose.
#   * One y-axis per panel. Two measures = two panels (patchwork), never a dual axis.

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
## It marks the 1:1 line and nothing else, dotted, because the IBM owns dashed.
REF   <- "#D94801"; REF_LTY <- "11"
GRID  <- "#E5E7EB"; AXIS <- "#C9CCD1"; SURFACE <- "#FFFFFF"
## the site-file hexbins' ramp: near-white at the sparse end so the 1:1 ridge
## carries the ink
HEX_LOW <- "#F4F6FE"; HEX_HIGH <- "#171449"
ENV_ALPHA <- 0.16                                 # IBM ribbon, continuous x
IBM_BAR_A <- 0.30                                 # IBM band bar, discrete x
IBM_BAR_W <- 2.4                                  # ... drawn as a line
ANNOT_SIZE <- 2.9                                 # in-panel notes, mm

FONT <- if ("Segoe UI" %in% systemfonts::system_fonts()$family) "Segoe UI" else "sans"

## ---- shared labels ------------------------------------------------------------
## one wording per axis, in every figure that has it
EIR_AXIS <- "EIR passed to set_equilibrium() (bites per adult per year, log scale)"
DEV_LAB <- "fleet vs the IBM median (%)"
AGE_BAND_LAB <- "age band (years)"
POP_DENS_LAB <- "share of the population per year of age"
YEARS_LAB <- "years relative to deployment"
## years relative to a deployment at `zero`, the axis title saying they are years:
## −3, 0, +3
lab_years <- function(zero) function(b) {
  k <- as.integer(round(b - zero))
  ifelse(k == 0L, "0", ifelse(k < 0L, sprintf("−%d", -k), sprintf("+%d", k)))
}
## numbers with a true minus sign, at one precision along the axis
lab_signed <- scales::label_number(style_negative = "minus")

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
      legend.location = "plot",
      legend.title = element_blank(), legend.key.width = unit(1.6, "lines"),
      legend.margin = margin(0, 0, 0, 0), legend.box.spacing = unit(6, "pt"),
      strip.text = element_text(face = "bold", colour = INK, hjust = 0,
                                size = rel(0.95), margin = margin(b = 6)),
      strip.background = element_blank(), strip.placement = "outside",
      strip.switch.pad.grid = unit(8, "pt"), strip.switch.pad.wrap = unit(8, "pt"),
      plot.background = element_rect(fill = SURFACE, colour = NA),
      panel.spacing = unit(1.4, "lines"),
      plot.margin = margin(10, 14, 8, 10)
    )
}
## A panel's own title inside a figure sits one step below the figure's, at the
## size and weight of a facet strip, so figure title, panel title and facet label
## read as one hierarchy wherever they appear.
theme_panel_title <- function() theme(
  plot.title = element_text(face = "bold", colour = INK, size = rel(0.95), hjust = 0,
                            margin = margin(b = 3)),
  plot.subtitle = element_text(colour = INK2, size = rel(0.82), hjust = 0,
                               margin = margin(b = 6)))
## age bands on a discrete axis, labelled at an angle so twelve of them fit
theme_bands <- function() theme(axis.text.x = element_text(angle = 45, hjust = 1, size = rel(0.8)))

## series scales -- every panel that draws both models uses exactly these.
## fleet's point is hollow -- filled with the surface -- so where it sits on the
## IBM's filled one both read, as the layer-order rule above intends. Both levels
## are in every scale even where a layer holds one of them -- the IBM's band --
## so the band joins the model keys instead of opening a second legend.
scale_models <- function(shapes = TRUE, lines = TRUE) {
  lv <- c("IBM", "fleet")
  s <- list(scale_colour_manual(values = COL, breaks = lv, limits = lv),
            scale_fill_manual(values = c(IBM = COL[["IBM"]], fleet = SURFACE),
                              breaks = lv, limits = lv),
            labs(colour = NULL, linetype = NULL, shape = NULL, fill = NULL))
  if (lines)  s <- c(s, list(scale_linetype_manual(values = LTY, breaks = lv, limits = lv)))
  if (shapes) s <- c(s, list(scale_shape_manual(values = SHP, breaks = lv, limits = lv)))
  s
}
## one key weight everywhere: line + point together, in the same order, and
## first among a panel's legends
guide_models <- function() guides(
  colour = guide_legend(order = 1, override.aes = list(linewidth = 0.9, size = 2.6)),
  fill = guide_legend(order = 1), linetype = guide_legend(order = 1),
  shape = guide_legend(order = 1))
## an axis title longer than a short panel is tall goes on two lines
wrap_lab <- function(x, width = 30) paste(strwrap(x, width), collapse = "\n")
## An outcome's name as a narrow column's strip: one line per phrase -- the
## measure, its unit, its ages -- rather than wherever the width happens to fall.
strip_lines <- function(x) {
  x <- sub(", ", "\n", x)
  x <- sub("episodes per ", "episodes\nper ", x)
  sub("per 1,000 ", "per 1,000\n", x)
}
## Captions do not wrap on their own, so they are folded here -- and how many
## characters fit is a property of the DEVICE, not a constant. Pass fig_width,
## the canvas width in inches, or width to set the character count directly.
## The fold is in proportion to the canvas because the text is (save_fig()).
cap <- function(..., fig_width = 10, width = 135)
  paste(strwrap(paste(...), width = width), collapse = "\n")
## a subtitle, set larger than a caption, so folded shorter
subt <- function(...) cap(..., width = 108)

## a deployment and the campaigns or rounds after it mark a time axis the same way
## in every figure: deployment a dashed ink rule, campaigns solid muted rules,
## darker than the grid so they cannot be taken for it
deploy_rule <- function(x) geom_vline(xintercept = x, colour = INK2, linewidth = 0.45,
                                      linetype = "22")
campaign_rules <- function(data) geom_vline(data = data, aes(xintercept = x), colour = MUTED,
                                            linewidth = 0.4)

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
## age bands as an ordered factor, "0–1", "1–2", ... in age order
band_factor <- function(d) {
  e <- unique(d[order(d$age_lo), c("age_lo", "age_hi")])
  factor(sprintf("%g–%g", d$age_lo, d$age_hi),
         levels = sprintf("%g–%g", e$age_lo, e$age_hi))
}
## IBM band and fleet value per age band, for one outcome column `m` of rep_age rows
band_summary <- function(d, m, by = character()) {
  d$band <- band_factor(d); d$y <- d[[m]]
  gi <- d[d$model == "IBM", ] |> dplyr::group_by(dplyr::across(dplyr::all_of(c(by, "band")))) |>
    dplyr::summarise(mid = replicate_band(y)$centre, lo = replicate_band(y)$lower,
                     hi = replicate_band(y)$upper, .groups = "drop") |>
    dplyr::mutate(model = "IBM")
  go <- d[d$model == "fleet", c(by, "band", "y")] |> dplyr::rename(mid = y) |>
    dplyr::mutate(model = "fleet")
  list(gi = gi, go = go)
}

## ---- shared panels ------------------------------------------------------------
## Both models at a discrete x -- an EIR on the grid, an age band. The IBM's band
## is a translucent bar `band_w` wide in x's own units (log10 units on the EIR
## axis), drawn as a fill so the IBM key carries it as the ribbon key does; then
## the medians in the layer order above.
model_layers <- function(gi, go, xvar, band_w) list(
  geom_tile(data = gi, aes(x = .data[[xvar]], y = (lo + hi) / 2, height = hi - lo,
                           fill = model),
            width = band_w, alpha = IBM_BAR_A, colour = NA),
  geom_line(data = go, aes(.data[[xvar]], mid, colour = model, linetype = model, group = model),
            linewidth = 0.75),
  geom_line(data = gi, aes(.data[[xvar]], mid, colour = model, linetype = model, group = model),
            linewidth = 0.75),
  geom_point(data = gi, aes(.data[[xvar]], mid, colour = model, shape = model, fill = model),
             size = 2.4, stroke = 0.5),
  geom_point(data = go, aes(.data[[xvar]], mid, colour = model, shape = model, fill = model),
             size = 2.4, stroke = 0.5))
## the y scale of a rate or a share: from zero, a little headroom. A band's lower
## edge below zero -- median - 1.28 SD of a rare, skewed count -- is clipped to the
## floor rather than dropped, which would lose the whole bar or open a gap in
## the ribbon.
y_from_zero <- function(pct = FALSE, headroom = 0.06)
  scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, headroom)),
                     oob = scales::oob_squish,
                     labels = if (pct) scales::percent else waiver())

## An outcome against transmission intensity, on the EIR grid.
panel_eir_curve <- function(gi, go, breaks, ylab, pct = FALSE) {
  ggplot() + model_layers(gi, go, "init_EIR", band_w = 0.035) +
    scale_x_log10(breaks = breaks, labels = scales::label_number(drop0trailing = TRUE),
                  minor_breaks = NULL) +
    y_from_zero(pct) + scale_models() + guide_models() +
    labs(x = EIR_AXIS, y = wrap_lab(ylab)) + theme_cmp()
}

## An outcome by age band, one panel per EIR when `gi` carries an `eir` column.
## x is the age BAND, not a continuous age, for three reasons, and the last is the
## important one. The bands are unequal -- one year wide in infancy, twenty-five
## at the top -- so a continuous axis gives a quarter of its width to the last
## band. On a linear age axis most outcomes are flat and near zero above age 20,
## so most of the panel carried no information. And every age criterion is band
## by band: drawing bands as bands means the reader sees exactly what is being
## tested. `shade` names bands drawn but not compared, on a grey background. Where
## `go` carries `outside`, those fleet points are filled -- a scored band where
## fleet falls outside the IBM's band -- and the legend names them.
OUT_KEY <- "fleet outside the IBM band"
panel_bands <- function(gi, go, ylab, pct = FALSE, shade = NULL) {
  p <- ggplot(mapping = aes(x = band))
  if (!is.null(shade) && nrow(shade))
    p <- p + geom_rect(data = shade, inherit.aes = FALSE,
                       aes(xmin = x - 0.5, xmax = x + 0.5, ymin = -Inf, ymax = Inf),
                       fill = MUTED, alpha = 0.10)
  p <- p + model_layers(gi, go, "band", band_w = 0.22)
  if ("outside" %in% names(go))
    p <- p +
      geom_point(data = go[go$outside, ], aes(band, mid, alpha = OUT_KEY), shape = 24,
                 colour = COL[["fleet"]], fill = COL[["fleet"]], size = 2.4, stroke = 0.5) +
      scale_alpha_manual(values = setNames(1, OUT_KEY), limits = OUT_KEY, name = NULL) +
      guides(alpha = guide_legend(order = 2, override.aes = list(
        shape = 24, colour = COL[["fleet"]], fill = COL[["fleet"]], size = 2.6)))
  p <- p + y_from_zero(pct) + scale_models() + guide_models() +
    labs(x = AGE_BAND_LAB, y = wrap_lab(ylab)) + theme_cmp() + theme_bands()
  if ("eir" %in% names(gi)) p + facet_wrap(~ eir, nrow = 1, scales = "free_y") else p
}
## The age-profile panel both parasites' age-profile claims rest on. `ap` has one
## row per model, replicate, transmission level (`eir`, a factor) and age band
## (`age_lo`, `age_hi`, `pop_frac`), and the outcome column `m`. Bands carrying
## less than BURDEN_MIN of the outcome are drawn but not scored, on a grey
## background, so the figure and the criterion say the same thing; in the scored
## ones a fleet point outside the IBM's band is filled. `scored = FALSE` for a
## panel no claim rests on.
panel_outcome <- function(ap, m, ylab, pct = FALSE, scored = TRUE) {
  s <- band_summary(ap, m, by = "eir")
  shade <- NULL
  if (scored) {
    d <- ap; d$band <- band_factor(d); d$y <- d[[m]]
    shares <- d[d$model == "IBM", ] |> dplyr::group_by(eir, band) |>
      dplyr::summarise(ep = stats::median(y * pop_frac), .groups = "drop") |>
      dplyr::group_by(eir) |> dplyr::mutate(share = ep / sum(ep)) |> dplyr::ungroup()
    shade <- shares |> dplyr::filter(share < BURDEN_MIN) |> dplyr::mutate(x = as.numeric(band))
    g <- merge(s$go, merge(s$gi[, c("eir", "band", "lo", "hi")],
                           shares[, c("eir", "band", "share")], by = c("eir", "band")),
               by = c("eir", "band"))
    s$go <- dplyr::mutate(g, outside = share >= BURDEN_MIN & (mid < lo | mid > hi))
  }
  panel_bands(s$gi, s$go, ylab, pct, shade)
}
BAND_NOTE <- paste("A filled triangle marks a scored band where fleet falls outside the IBM's band.",
                   "Age bands on a grey background carry under 5% of the outcome and are not",
                   "scored — the claim rests on the others. Bands are finer in childhood, so",
                   "equal spacing here is not equal width in years.")

## The test itself, beside a curve that cannot show it: fleet against the IBM
## median, with the IBM's own replicate band as the tolerance -- EIR by EIR or
## band by band. A hollow triangle inside the band passes; a filled one outside
## misses. No vertical grid and no baseline rule: the bars mark the positions,
## and the zero line is the reference.
DEV_KEYS <- c(inside = "fleet inside it", outside = "fleet outside it")
DEV_BAND <- "IBM band"
deviation_frame <- function(x, fleet, mid, lo, hi)
  data.frame(x = x, rel = 100 * (fleet / mid - 1),
             lo_r = 100 * (lo / mid - 1), hi_r = 100 * (hi / mid - 1),
             where = factor(ifelse(fleet < lo | fleet > hi, "outside", "inside"),
                            levels = names(DEV_KEYS)))
panel_deviation_core <- function(d) {
  ggplot(d, aes(x)) +
    geom_linerange(aes(ymin = lo_r, ymax = hi_r, colour = DEV_BAND),
                   linewidth = IBM_BAR_W * 1.6, alpha = IBM_BAR_A) +
    geom_hline(yintercept = 0, colour = AXIS, linewidth = 0.5) +
    geom_point(aes(y = rel, shape = where, fill = where), colour = COL[["fleet"]],
               size = 2.6, stroke = 0.6,
               show.legend = c(colour = FALSE, shape = TRUE, fill = TRUE)) +
    scale_colour_manual(values = setNames(COL[["IBM"]], DEV_BAND), name = NULL) +
    scale_shape_manual(values = c(inside = 24, outside = 24), labels = DEV_KEYS,
                       drop = FALSE, name = NULL) +
    scale_fill_manual(values = c(inside = SURFACE, outside = COL[["fleet"]]),
                      labels = DEV_KEYS, drop = FALSE, name = NULL) +
    guides(colour = guide_legend(order = 1), shape = guide_legend(order = 2),
           fill = guide_legend(order = 2)) +
    scale_y_continuous(labels = lab_signed) +
    labs(y = DEV_LAB) + theme_cmp() +
    theme(panel.grid.major.x = element_blank(), axis.line.x = element_blank())
}
## EIR by EIR, from the curve panel's IBM summary `gi` and fleet rows `go`
panel_deviation <- function(gi, go, breaks) {
  d <- merge(gi[, c("init_EIR", "mid", "lo", "hi")],
             setNames(go[, c("init_EIR", "mid")], c("init_EIR", "fleet")), by = "init_EIR")
  panel_deviation_core(deviation_frame(d$init_EIR, d$fleet, d$mid, d$lo, d$hi)) +
    scale_x_log10(breaks = breaks, labels = scales::label_number(drop0trailing = TRUE),
                  minor_breaks = NULL) +
    labs(x = EIR_AXIS)
}
## band by band
panel_deviation_bands <- function(band, fleet, mid, lo, hi)
  panel_deviation_core(deviation_frame(band, fleet, mid, lo, hi)) +
    labs(x = AGE_BAND_LAB) + theme_bands()
DEV_NOTE <- paste("Right: fleet's departure from the IBM median, in per cent, against the IBM's",
                  "replicate band at each EIR — the tolerance the claim is decided on.")
POP_NOTE <- paste("Shares are divided by band width, so bands of unequal width are comparable.",
                  "Right: fleet's departure from the IBM median, in per cent, after renormalising",
                  "to the 0–60 population as the claim's criterion does, against the IBM's",
                  "replicate band — the tolerance the claim is decided on.")

## ---- shared figures -----------------------------------------------------------
## One outcome's EIR claim: the curve, and beside it the test.
fig_eir_claim <- function(gi, go, breaks, ylab, pct, title, caption) {
  (panel_eir_curve(gi, go, breaks, ylab, pct) | panel_deviation(gi, go, breaks)) +
    plot_layout(axis_titles = "collect") +
    plot_annotation(title = title, caption = caption, theme = theme_cmp()) &
    theme(legend.position = "top", legend.justification = "left")
}

## The population age structure at one EIR: the shares per year of age, band by
## band, and the test the population-age-structure claim makes. Shares are
## divided by band width, because the bands are unequal and a raw share makes a
## wide band look populous for no reason but its width. The top band is drawn
## but marked: fleet's oldest age group is ABSORBING, open-ended above 80, and
## the renderer assigns an open-ended group wholly to the band holding its lower
## edge, so fleet's 60–85 holds everyone over 80 however old while the IBM's
## holds 60–85 year olds only. The test renormalises to the 0–60 population
## first, exactly as the criterion states, so that convention moves no other band.
not_comparable <- function(n) list(
  annotate("text", x = n + 0.45, y = Inf, vjust = 1.3, hjust = 1, size = ANNOT_SIZE,
           lineheight = 0.95, colour = INK2, label = "not\ncomparable"))
fig_pop_age <- function(pa, title, subtitle, caption) {
  pa$dens <- pa$pop_frac / (pa$age_hi - pa$age_lo)
  s <- band_summary(pa, "dens")
  n <- nlevels(s$gi$band)
  p_struct <- panel_bands(s$gi, s$go, POP_DENS_LAB, pct = TRUE, shade = data.frame(x = n)) +
    not_comparable(n)
  rn <- function(d) { d <- d[d$age_hi <= 60, ]; d$share <- d$pop_frac / sum(d$pop_frac); d }
  keep <- c("model", "rep", "age_lo", "age_hi", "share")
  ri <- pa[pa$model == "IBM", ] |> dplyr::group_by(rep) |> dplyr::group_modify(~ rn(.x)) |>
    dplyr::ungroup()
  sr <- band_summary(dplyr::bind_rows(ri[, keep], rn(pa[pa$model == "fleet", ])[, keep]), "share")
  dv <- merge(sr$go[, c("band", "mid")], sr$gi[, c("band", "mid", "lo", "hi")], by = "band",
              suffixes = c("_fleet", ""))
  p_dev <- panel_deviation_bands(dv$band, dv$mid_fleet, dv$mid, dv$lo, dv$hi)
  (p_struct | p_dev) + plot_layout(axis_titles = "collect") +
    plot_annotation(title = title, subtitle = subtitle, caption = caption, theme = theme_cmp())
}

## the impact figures' fleet rows that fall outside the IBM's band in their cell
outside_cells <- function(both) {
  ibm <- both[both$model == "IBM", c("scenario", "eir", "metric", "lo", "hi")]
  fl <- merge(both[both$model == "fleet", c("scenario", "eir", "metric", "mid")], ibm,
              by = c("scenario", "eir", "metric"))
  fl[fl$mid < fl$lo | fl$mid > fl$hi, ]
}
## Intervention impact, cell by cell: each intervention's reduction at each EIR,
## the IBM's median and band against fleet, with fleet marked inside or outside
## the band as in every other test; a grey bar joins the two medians. `both` has
## scenario, eir, metric, model, mid and (IBM rows) lo, hi; `scenarios` lists the
## row labels top to bottom.
IMPACT_KEYS <- c("IBM", "fleet inside the IBM band", "fleet outside it")
IMPACT_NOTE <- "A grey bar joins the IBM's median to fleet's."
fig_impact <- function(both, scenarios, title, subtitle, caption) {
  out <- outside_cells(both)
  both$key <- ifelse(both$model == "IBM", IMPACT_KEYS[1], IMPACT_KEYS[2])
  hit <- paste(both$scenario, both$eir, both$metric) %in% paste(out$scenario, out$eir, out$metric)
  both$key[both$model == "fleet" & hit] <- IMPACT_KEYS[3]
  both$key <- factor(both$key, levels = IMPACT_KEYS)
  seg <- both |> dplyr::select(scenario, eir, metric, model, mid) |>
    tidyr::pivot_wider(names_from = model, values_from = mid)
  xmin <- min(-0.04, floor(min(c(both$lo, both$mid), na.rm = TRUE) * 20) / 20 - 0.03)
  kv <- function(...) setNames(c(...), IMPACT_KEYS)
  ggplot(both, aes(y = scenario)) +
    geom_vline(xintercept = 0, colour = AXIS, linewidth = 0.5) +
    geom_segment(data = seg, aes(x = IBM, xend = fleet, yend = scenario), colour = GRID,
                 linewidth = 2.2, lineend = "round") +
    geom_linerange(data = both[both$model == "IBM", ], aes(xmin = lo, xmax = hi),
                   colour = COL[["IBM"]], linewidth = IBM_BAR_W, alpha = IBM_BAR_A) +
    geom_point(aes(x = mid, colour = key, shape = key, fill = key), size = 2.8, stroke = 0.6) +
    facet_grid(eir ~ metric, labeller = labeller(metric = strip_lines)) +
    scale_colour_manual(values = kv(COL[["IBM"]], COL[["fleet"]], COL[["fleet"]]),
                        limits = IMPACT_KEYS, name = NULL) +
    scale_fill_manual(values = kv(COL[["IBM"]], SURFACE, COL[["fleet"]]),
                      limits = IMPACT_KEYS, name = NULL) +
    scale_shape_manual(values = kv(21, 24, 24), limits = IMPACT_KEYS, name = NULL) +
    guides(colour = guide_legend(override.aes = list(size = 2.6))) +
    scale_x_continuous(labels = scales::label_percent(style_negative = "minus"),
                       breaks = seq(0, 1, 0.5), minor_breaks = seq(-0.25, 1, 0.25),
                       limits = c(xmin, 1.02), expand = expansion(mult = 0.02)) +
    scale_y_discrete(limits = rev(unname(scenarios)), expand = expansion(add = 0.7)) +
    coord_cartesian(clip = "off") +
    labs(title = title, subtitle = subtitle, x = "reduction relative to baseline", y = NULL,
         caption = caption) +
    theme_cmp() + theme(panel.grid.major.y = element_blank(), axis.line.x = element_blank(),
                        axis.text.y = element_text(size = rel(0.9), lineheight = 0.95, hjust = 1),
                        strip.text.y = element_text(angle = 0, hjust = 0),
                        panel.spacing.x = unit(2, "lines"), panel.spacing.y = unit(1.3, "lines"))
}

## Save to BOTH homes: man/figures (README, GitHub) and vignettes (pkgdown
## article). Every figure is shown at the article's column width, so the text is
## set in proportion to the canvas -- 13 pt per 10 inches -- and a 14-inch figure
## reads at the size of a 10-inch one.
save_fig <- function(g, name, width, height, dpi = 200) {
  sz <- theme(text = element_text(size = 13 * width / 10))
  g <- if (inherits(g, "patchwork")) g & sz else g + sz
  for (dir in c("man/figures", "vignettes")) {
    d <- file.path(fc_root(), dir)
    dir.create(d, recursive = TRUE, showWarnings = FALSE)
    f <- file.path(d, paste0("cmp_", name, ".png"))
    ggsave(f, g, width = width, height = height, dpi = dpi, device = ragg::agg_png,
           bg = SURFACE)
  }
  invisible(g)
}
