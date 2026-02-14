# Run tests for the Shiny Cost Estimator
# Usage: Rscript tests/testthat.R (from project root)

library(testthat)

# Source the estimation functions
source("R/shiny_cost_estimator.R")

test_dir("tests/testthat")
