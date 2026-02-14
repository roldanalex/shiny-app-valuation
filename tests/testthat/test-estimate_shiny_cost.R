# Tests for estimate_shiny_cost()
# Functions should already be sourced before running tests

test_that("return structure has expected fields", {
  result <- estimate_shiny_cost(10000)
  expect_type(result, "list")
  expect_true("code_lines" %in% names(result))
  expect_true("effort_person_months" %in% names(result))
  expect_true("schedule_months" %in% names(result))
  expect_true("people_required" %in% names(result))
  expect_true("estimated_cost_usd" %in% names(result))
  expect_true("realistic_cost_usd" %in% names(result))
  expect_true("final_people" %in% names(result))
  expect_true("final_schedule_months" %in% names(result))
  expect_true("premium_multiplier" %in% names(result))
  expect_true("coordination_premium" %in% names(result))
  expect_true("average_monthly_cost" %in% names(result))
  expect_true("confidence_interval" %in% names(result))
  expect_true("multiplier_breakdown" %in% names(result))
  expect_true("params" %in% names(result))
})

test_that("known input produces reasonable ranges", {
  result <- estimate_shiny_cost(10000, complexity = "medium", team_experience = 4)
  expect_gt(result$realistic_cost_usd, 0)
  expect_gt(result$effort_person_months, 0)
  expect_gt(result$final_schedule_months, 0)
  expect_gt(result$final_people, 0)
  expect_equal(result$code_lines, 10000)
})

test_that("complexity ordering: low < medium < high", {
  low <- estimate_shiny_cost(10000, complexity = "low")
  med <- estimate_shiny_cost(10000, complexity = "medium")
  high <- estimate_shiny_cost(10000, complexity = "high")
  expect_lt(low$effort_person_months, med$effort_person_months)
  expect_lt(med$effort_person_months, high$effort_person_months)
})

test_that("team experience reduces cost", {
  novice <- estimate_shiny_cost(10000, team_experience = 1)
  expert <- estimate_shiny_cost(10000, team_experience = 5)
  expect_gt(novice$realistic_cost_usd, expert$realistic_cost_usd)
})

test_that("input validation rejects bad inputs", {
  expect_error(estimate_shiny_cost(-100))
  expect_error(estimate_shiny_cost(10000, complexity = "invalid"))
  expect_error(estimate_shiny_cost(10000, team_experience = 0))
  expect_error(estimate_shiny_cost(10000, team_experience = 6))
  expect_error(estimate_shiny_cost(10000, reuse_factor = 0.5))
  expect_error(estimate_shiny_cost(10000, reuse_factor = 1.5))
  expect_error(estimate_shiny_cost(10000, tool_support = 0.5))
  expect_error(estimate_shiny_cost(10000, tool_support = 1.5))
  expect_error(estimate_shiny_cost(10000, rely = 0.5))
  expect_error(estimate_shiny_cost(10000, cplx = 2.0))
  expect_error(estimate_shiny_cost(10000, ruse = 0.5))
  expect_error(estimate_shiny_cost(10000, pcon = 0.5))
  expect_error(estimate_shiny_cost(10000, apex = 0.5))
})

test_that("zero code lines returns zero cost", {
  result <- estimate_shiny_cost(0)
  expect_equal(result$estimated_cost_usd, 0)
  expect_equal(result$effort_person_months, 0)
})

test_that("confidence intervals bracket realistic cost", {
  result <- estimate_shiny_cost(10000)
  expect_lt(result$confidence_interval$low, result$realistic_cost_usd)
  expect_gt(result$confidence_interval$high, result$realistic_cost_usd)
  # 70% and 130% of realistic cost (tolerance of 1 for rounding)
  expect_equal(result$confidence_interval$low, round(result$realistic_cost_usd * 0.70), tolerance = 1)
  expect_equal(result$confidence_interval$high, round(result$realistic_cost_usd * 1.30), tolerance = 1)
})

test_that("maintenance calculation works correctly", {
  result <- estimate_shiny_cost(10000, maintenance_years = 3, maintenance_rate = 0.20)
  expect_false(is.null(result$maintenance))
  expect_equal(result$maintenance$maintenance_years, 3)
  expect_equal(result$maintenance$maintenance_rate, 0.20)
  expect_equal(length(result$maintenance$yearly_costs), 3)
  # TCO = build + total maintenance (tolerance of 1 for rounding)
  expect_equal(result$maintenance$tco, result$realistic_cost_usd + result$maintenance$total_maintenance, tolerance = 1)
  # Year 2 should be more than year 1 (5% annual increase)
  expect_gt(result$maintenance$yearly_costs[2], result$maintenance$yearly_costs[1])
})

test_that("maintenance is NULL when years = 0", {
  result <- estimate_shiny_cost(10000, maintenance_years = 0)
  expect_null(result$maintenance)
})

test_that("constraint premiums apply for large projects", {
  # Large project that should trigger schedule compression
  result <- estimate_shiny_cost(100000, max_schedule_months = 6, max_team_size = 3)
  # Should have a premium multiplier > 1
  expect_gt(result$premium_multiplier, 1.0)
  expect_gt(result$realistic_cost_usd, result$estimated_cost_usd)
})

test_that("COCOMO II drivers affect cost", {
  base <- estimate_shiny_cost(10000)
  high_rely <- estimate_shiny_cost(10000, rely = 1.26)
  expect_gt(high_rely$effort_person_months, base$effort_person_months)

  high_cplx <- estimate_shiny_cost(10000, cplx = 1.74)
  expect_gt(high_cplx$effort_person_months, base$effort_person_months)
})

test_that("multiplier breakdown is consistent", {
  result <- estimate_shiny_cost(10000)
  mb <- result$multiplier_breakdown
  expected_total <- mb$EM_experience * mb$EM_reuse * mb$EM_tools * mb$EM_modern *
                    mb$EM_rely * mb$EM_cplx * mb$EM_ruse * mb$EM_pcon * mb$EM_apex
  expect_equal(mb$EM_total, expected_total, tolerance = 1e-10)
})

test_that("language mix affects KLOC weighting", {
  # Python is more productive (1.1), so fewer effective KLOC
  py_result <- estimate_shiny_cost(10000, language_mix = list("Python" = 10000))
  js_result <- estimate_shiny_cost(10000, language_mix = list("JavaScript" = 10000))
  # JavaScript (0.9 productivity) should cost more than Python (1.1 productivity)
  expect_gt(js_result$effort_person_months, py_result$effort_person_months)
})

test_that("params are preserved in output", {
  result <- estimate_shiny_cost(5000, complexity = "high", team_experience = 2,
                                reuse_factor = 1.1, tool_support = 0.9)
  expect_equal(result$params$complexity, "high")
  expect_equal(result$params$team_experience, 2)
  expect_equal(result$params$reuse_factor, 1.1)
  expect_equal(result$params$tool_support, 0.9)
})
