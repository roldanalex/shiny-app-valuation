# Unit tests for the pure app helpers (no Shiny session needed)

local({
  root <- if (dir.exists("R")) "." else file.path("..", "..")
  source(file.path(root, "cost-estimator-app", "modules", "app_helpers.R"),
         local = FALSE)
})

test_that("clean_count sanitizes hostile inputs", {
  expect_equal(clean_count(100), 100)
  expect_equal(clean_count(0), 0)
  expect_equal(clean_count(NULL), 0)
  expect_equal(clean_count(NA), 0)
  expect_equal(clean_count(NA_real_), 0)
  expect_equal(clean_count(-50), 0)
  expect_equal(clean_count(Inf), 0)
  expect_equal(clean_count(NaN), 0)
  expect_equal(clean_count("abc"), 0)
  expect_equal(clean_count("123"), 123)
  expect_equal(clean_count(numeric(0)), 0)
  expect_equal(clean_count(c(1, 2)), 0)
})

test_that("build_language_mix drops blanks, NAs, and zeros", {
  mix <- build_language_mix(list(R = 5000, Python = NA, JavaScript = NULL,
                                 SQL = 0, CSS = -10, Other = "abc"))
  expect_equal(mix, list(R = 5000))
  expect_equal(build_language_mix(list(R = NA, Python = NULL)), setNames(list(), character(0)))
})

test_that("blank manual entry no longer crashes the engine", {
  # Regression: list(R = 100, Python = NA) used to produce an NA-named
  # element that crashed estimate_shiny_cost
  mix <- build_language_mix(list(R = 100, Python = NA))
  e <- estimate_shiny_cost(sum(unlist(mix)), language_mix = mix)
  expect_gt(e$cost_usd, 0)
})

test_that("parse_num_param bounds-checks URL values", {
  expect_equal(parse_num_param("1000"), 1000)
  expect_null(parse_num_param("abc"))
  expect_null(parse_num_param("-5"))
  expect_null(parse_num_param("99999999999"))
  expect_null(parse_num_param(NULL))
  expect_null(parse_num_param("Inf"))
  expect_equal(parse_num_param("3", lo = 1, hi = 5), 3)
  expect_null(parse_num_param("7", lo = 1, hi = 5))
})
