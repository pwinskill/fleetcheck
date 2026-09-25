# The evidence article's section for each claim

A heading, the verdict and the claim, the criterion that decides it and
what was measured against it, what the result cost to produce and where
its code is, the one figure that is evidence for the claim, and the
note. Both evidence articles render their sections with this, so the two
cannot drift apart in how a claim is presented. The criterion and the
measurement are repeated from the table because a README link lands on
the section, and a note written against them reads as nonsense without
them.

## Usage

``` r
claim_sections_md(claims, fig_dir = ".")
```

## Arguments

- claims:

  as returned by
  [`read_claims()`](https://pwinskill.github.io/fleetcheck/reference/read_claims.md),
  filtered to the page's claims.

- fig_dir:

  where the figures are, relative to the article.

## Value

a character vector of markdown lines.

## Details

A figure the register declares but the build does not have is shown as
missing, loudly, rather than passed off as a claim with no figure.

The figure is written as an `<img>` rather than `![alt](src)`: pandoc
turns a markdown image into a `<figure>` and prints the alt text as a
caption, which put the claim on screen a second time directly under the
heading that had just said it. The alt text is the claim and its
verdict, because an empty alt tells a screen reader the image is
decorative, on a page whose entire content is evidence, and the claim
alone would state as true what may have failed. Width and height are
given so the browser reserves the space before the image arrives;
without them a deep link to a claim, which is how the README and the
front page arrive, jumps to a position that then moves as the images
load.
