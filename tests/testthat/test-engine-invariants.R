# Structural invariants of the cost engine. These lock in the v2.0 fixes:
# - effort == people x schedule (identity, even under compression)
# - cost is continuous in max_schedule_months (no premium-ladder cliffs)
# - cost is exactly linear in avg_wage (no hardcoded $/month rate)

test_that("effort equals people x schedule across an input grid", {
  for (lines in c(2000, 10000, 50000, 200000)) {
    for (max_sched in c(6, 12, 24)) {
      for (max_team in c(2, 5, 10)) {
        e <- estimate_shiny_cost(lines, max_schedule_months = max_sched,
                                 max_team_size = max_team)
        if (e$effort_person_months > 0) {
          expect_equal(e$effort_person_months,
                       e$final_people * e$final_schedule_months,
                       tolerance = 0.05,
                       info = sprintf("lines=%d max_sched=%d max_team=%d",
                                      lines, max_sched, max_team))
        }
      }
    }
  }
})

test_that("cost is continuous in max_schedule_months (no cliffs)", {
  # Sweep the schedule cap through the compression region; adjacent
  # half-month steps must never move cost by more than 5%.
  costs <- sapply(seq(4, 40, by = 0.5), function(s) {
    estimate_shiny_cost(100000, max_schedule_months = s, max_team_size = 5)$cost_usd
  })
  rel_change <- abs(diff(costs)) / head(costs, -1)
  expect_lt(max(rel_change), 0.05)
})

test_that("cost scales exactly linearly with avg_wage", {
  base <- estimate_shiny_cost(10000, avg_wage = 105000)
  double <- estimate_shiny_cost(10000, avg_wage = 210000)
  expect_equal(double$cost_usd, 2 * base$cost_usd, tolerance = 2)
  # Wage moves the estimate range too
  expect_equal(double$estimate_range$low, 2 * base$estimate_range$low, tolerance = 4)
})

test_that("compression penalty is smooth and capped", {
  # Just inside the boundary: no penalty
  e_free <- estimate_shiny_cost(50000, max_schedule_months = 60)
  expect_equal(e_free$compression_penalty, 1.0)
  # Deep compression: capped at 2.0
  e_deep <- estimate_shiny_cost(500000, max_schedule_months = 4, max_team_size = 2)
  expect_lte(e_deep$compression_penalty, 2.0)
  expect_false(e_deep$schedule_feasible)
})

test_that("schedule exponent follows COCOMO II.2000 (D anchored at 0.91)", {
  # medium complexity: B = 1.10 -> D = 0.28 + 0.2 * (1.10 - 0.91) = 0.318
  e <- estimate_shiny_cost(10000)
  effort0 <- e$unconstrained_effort_pm
  expect_equal(e$schedule_months, 3.67 * effort0 ^ 0.318, tolerance = 0.05)
})
