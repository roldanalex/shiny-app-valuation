# Golden-value regression tests, frozen from the v2.0 engine
# (COCOMO II.2000: A = 2.94, C = 3.67, D anchored at 0.91, EM_modern = 0.85,
# smooth compression penalty ratio^1.25 capped at 2.0, single avg_wage rate).
# If a deliberate model change moves these, re-freeze with a comment in the PR.

test_that("golden: 10k lines, defaults", {
  e <- estimate_shiny_cost(10000)
  expect_equal(e$cost_usd, 275280, tolerance = 0.5)
  expect_equal(e$effort_person_months, 31.46, tolerance = 0.01)
  expect_equal(e$final_people, 2.86, tolerance = 0.01)
  expect_equal(e$final_schedule_months, 10.99, tolerance = 0.01)
  expect_equal(e$compression_penalty, 1.0)
  expect_true(e$schedule_feasible)
  expect_equal(e$estimate_range$low, 192696, tolerance = 0.5)
  expect_equal(e$estimate_range$high, 357864, tolerance = 0.5)
})

test_that("golden: 50k lines, high complexity, junior team, 12-month cap", {
  e <- estimate_shiny_cost(50000, complexity = "high", team_experience = 2,
                           max_schedule_months = 12)
  expect_equal(e$cost_usd, 5350253, tolerance = 0.5)
  expect_equal(e$effort_person_months, 555.87, tolerance = 0.01)
  expect_equal(e$final_people, 46.32, tolerance = 0.01)
  expect_equal(e$final_schedule_months, 12.0)
  expect_equal(e$compression_penalty, 2.0)
  expect_equal(e$coordination_premium, 1.1)
  expect_false(e$schedule_feasible)
})

test_that("golden: 2k lines, low complexity", {
  e <- estimate_shiny_cost(2000, complexity = "low")
  expect_equal(e$cost_usd, 44343, tolerance = 0.5)
  expect_equal(e$effort_person_months, 5.07, tolerance = 0.01)
  expect_equal(e$final_people, 0.85, tolerance = 0.01)
  expect_equal(e$final_schedule_months, 5.99, tolerance = 0.01)
  expect_true(e$schedule_feasible)
})
