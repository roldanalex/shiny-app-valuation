# Deploy the cost estimator app to shinyapps.io.
# This is the ONLY supported deploy path: it re-syncs the engine copies first
# so modules/ can never drift from the canonical R/ sources.
# Run from the repo root: Rscript tools/deploy.R

source("tools/sync_modules.R")

if (!requireNamespace("rsconnect", quietly = TRUE)) {
  stop("The 'rsconnect' package is required: install.packages('rsconnect')")
}

rsconnect::deployApp(
  appDir = "cost-estimator-app",
  appName = "shiny-cost-estimator",
  forceUpdate = TRUE
)
