# The modules/ engine copies are build artifacts of R/ (see tools/sync_modules.R).
# Drift between them means someone hand-edited a copy - fail loudly.

test_that("modules/ engine copies are identical to canonical R/ sources", {
  # Works whether tests run from the repo root or from tests/testthat
  root <- if (dir.exists("R")) "." else file.path("..", "..")
  root <- normalizePath(root)
  for (f in c("shiny_cost_estimator.R", "repo_code_analyzer.R")) {
    src <- file.path(root, "R", f)
    dst <- file.path(root, "cost-estimator-app", "modules", f)
    expect_true(file.exists(src), info = src)
    expect_true(file.exists(dst), info = dst)
    expect_identical(readLines(src), readLines(dst),
                     info = paste0(f, " has drifted; run Rscript tools/sync_modules.R"))
  }
})
