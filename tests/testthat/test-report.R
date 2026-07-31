# PDF report pipeline smoke test. Skipped when Quarto or ggplot2 is missing
# (e.g. minimal CI runners) - the app degrades gracefully in that case too.

test_that("PDF report renders end to end", {
  skip_if_not_installed("quarto")
  skip_if_not_installed("ggplot2")
  skip_if(is.null(quarto::quarto_path()), "Quarto CLI not available")

  root <- if (dir.exists("R")) "." else file.path("..", "..")
  app_dir <- file.path(root, "cost-estimator-app")
  source(file.path(app_dir, "modules", "theme.R"), local = FALSE)
  source(file.path(app_dir, "modules", "pdf_report.R"), local = FALSE)

  e <- estimate_shiny_cost(20000, maintenance_rate = 0.20, maintenance_years = 3)
  curve <- data.frame(schedule = seq(6, 36, 2))
  curve$cost <- sapply(curve$schedule, function(s)
    estimate_shiny_cost(20000, max_schedule_months = s)$cost_usd)

  payload <- build_report_payload(
    est = e,
    billable = list(total_code = 20000, billable_code = 20000, has_docs = FALSE),
    curve = curve,
    project_name = "Test Project"
  )

  out <- tempfile(fileext = ".pdf")
  old_wd <- setwd(app_dir); on.exit(setwd(old_wd))
  render_estimate_pdf(payload, out)
  setwd(old_wd)

  expect_true(file.exists(out))
  expect_gt(file.info(out)$size, 10000)
})

test_that("module server computes a consistent estimate (testServer smoke)", {
  skip_if_not_installed("shiny")
  skip_if_not_installed("bslib")
  skip_if_not_installed("plotly")
  skip_if_not_installed("DT")

  suppressPackageStartupMessages({
    library(shiny); library(bslib); library(plotly); library(DT)
  })

  root <- if (dir.exists("R")) "." else file.path("..", "..")
  app_dir <- file.path(root, "cost-estimator-app")
  source(file.path(app_dir, "modules", "theme.R"), local = FALSE)
  source(file.path(app_dir, "modules", "pdf_report.R"), local = FALSE)
  source(file.path(app_dir, "modules", "analysis_module.R"), local = FALSE)

  shiny::testServer(
    analysisResultsServer,
    args = list(
      analysis_data = reactive(list(language_mix = list(R = 10000),
                                    source_label = "Manual Entry")),
      params = reactive(list(complexity = "medium", team_exp = 4,
                             reuse = 1.0, tools = 1.0, wage = 105000,
                             max_team = 5, max_schedule = 24))
    ),
    {
      e <- est()
      expect_gt(e$cost_usd, 0)
      # The displayed identity must hold
      expect_equal(e$effort_person_months,
                   e$final_people * e$final_schedule_months,
                   tolerance = 0.05)
      curve <- tradeoff_curve()
      expect_true(all(diff(curve$cost) <= 1))  # cost non-increasing in schedule
    }
  )
})
