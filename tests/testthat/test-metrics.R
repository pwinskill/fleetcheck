test_that("agreement() is exact on cases with known answers", {
  x <- c(1, 2, 3, 4, 5)

  a <- agreement(x, x)
  expect_equal(a$n, 5L)
  expect_equal(a$cor, 1)
  expect_equal(a$rmse, 0)
  expect_equal(a$bias, 0)
  expect_equal(a$rel_bias, 0)
  expect_equal(a$slope, 1)

  # a constant offset moves bias, not slope
  b <- agreement(x, x + 0.5)
  expect_equal(b$bias, 0.5)
  expect_equal(b$slope, 1)
  expect_equal(b$rel_bias, 0.5 / mean(x))

  # a pure scaling moves slope, and bias with it
  s <- agreement(x, 1.1 * x)
  expect_equal(s$slope, 1.1)
  expect_equal(s$rel_bias, 0.1)

  # rmse is the root mean square of the differences, not of anything else
  d <- agreement(x, x + c(1, -1, 1, -1, 1))
  expect_equal(d$rmse, 1)
  expect_equal(d$bias, 1 / 5)
})

test_that("slope and rel_bias are different statements", {
  # a fan through the origin: slope 1.2, and a positive relative bias
  x <- 1:10
  f <- agreement(x, 1.2 * x)
  expect_equal(f$slope, 1.2)
  expect_equal(f$rel_bias, 0.2)

  # an offset with no scaling: slope exactly 1, bias positive. Reporting only
  # the slope here would say "no bias", which is why both are returned.
  o <- agreement(x, x + 3)
  expect_equal(o$slope, 1)
  expect_gt(o$rel_bias, 0)
})

test_that("agreement() handles missing and degenerate input", {
  expect_equal(agreement(c(1, 2, NA), c(1, 2, 5))$n, 2L)
  expect_true(is.na(agreement(1, 1)$cor))
  expect_true(is.na(agreement(c(0, 0), c(1, 1))$rel_bias))
  expect_error(agreement(1:3, 1:4))
})

test_that("band_position is 0 inside and a signed fraction outside", {
  expect_equal(band_position(5, 4, 6), 0)
  expect_equal(band_position(4, 4, 6), 0)   # edges count as inside
  expect_equal(band_position(6, 4, 6), 0)

  # 0.24% below a lower edge of 100 reads as -0.0024
  expect_equal(band_position(99.76, 100, 110), -0.0024)
  expect_equal(band_position(110.11, 100, 110), 0.001)

  expect_true(inside_band(5, 4, 6))
  expect_false(inside_band(3, 4, 6))
  expect_error(band_position(5, 6, 4))
})

test_that("band_summary reports the worst excursion, not the last", {
  v <- c(5, 99.76, 7, 121)
  lo <- c(4, 100, 6, 100)
  hi <- c(6, 110, 8, 110)
  s <- band_summary(v, lo, hi)
  expect_equal(s$n, 4L)
  expect_equal(s$n_inside, 2L)
  expect_equal(s$worst, 0.1)          # 121 against an upper edge of 110

  clean <- band_summary(c(5, 7), c(4, 6), c(6, 8))
  expect_equal(clean$n_inside, 2L)
  expect_equal(clean$worst, 0)
})

test_that("replicate_band is the 10-90% interval, read from every replicate", {
  set.seed(4)
  x <- rnorm(20, mean = 10, sd = 2)
  b <- replicate_band(x)
  expect_equal(b$centre, median(x))
  expect_equal(b$scale, sd(x))
  expect_equal(b$upper - b$lower, 2 * BAND_K * sd(x))
  # on a large normal sample the band and the percentiles agree; they are the
  # same interval, and the percentile estimate of it is what is noisy at n = 20
  y <- qnorm(seq(0.0005, 0.9995, length.out = 4000), 10, 2)
  q <- unname(quantile(y, c(0.1, 0.9)))
  expect_equal(replicate_band(y)$lower, q[1], tolerance = 0.02)
  expect_equal(replicate_band(y)$upper, q[2], tolerance = 0.02)
})

test_that("replicate_band refuses to invent a band it cannot estimate", {
  expect_true(is.na(replicate_band(numeric(0))$lower))
  expect_true(is.na(replicate_band(1)$lower))          # one replicate has no sd
  z <- replicate_band(rep(3, 20))                      # no spread at all
  expect_equal(z$scale, 0)
  expect_equal(z$lower, z$upper)
  expect_true(is.na(replicate_band(c(1, 2, NA))$centre) ||
              is.finite(replicate_band(c(1, 2, NA))$centre))
  expect_equal(replicate_band(c(1, 2, NA, 3))$centre, 2)   # na.rm by default
})

test_that("band_z reports headroom the band test cannot", {
  x <- c(rep(9, 10), rep(11, 10))                      # median 10, sd ~1.03
  expect_equal(band_z(10, x), 0)
  expect_gt(band_z(12, x), 0)
  expect_lt(band_z(8, x), 0)
  # a value exactly on the band edge is BAND_K standard deviations out
  b <- replicate_band(x)
  expect_equal(band_z(b$upper, x), BAND_K)
  expect_equal(band_z(b$lower, x), -BAND_K)
  expect_true(is.na(band_z(1, rep(3, 20))))            # no spread, no z
})

test_that("the band and the inside test agree on their own edges", {
  # the two are used together everywhere: a value inside the band must have
  # |z| <= BAND_K, and one outside must not
  set.seed(9)
  for (i in 1:20) {
    x <- rnorm(20, 5, 1.5); v <- rnorm(1, 5, 3)
    b <- replicate_band(x)
    expect_equal(inside_band(v, b$lower, b$upper), abs(band_z(v, x)) <= BAND_K)
  }
})

test_that("BURDEN_MIN is a share, not a percentage", {
  # a 5 here instead of 0.05 would silently test nothing at all
  expect_gt(BURDEN_MIN, 0)
  expect_lt(BURDEN_MIN, 1)
})
