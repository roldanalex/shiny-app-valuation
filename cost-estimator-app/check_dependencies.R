# Check Dependencies for Shiny Cost Estimator App
# Run this before deploying to ensure all packages are installed

cat("\n")
cat("═══════════════════════════════════════════════════════════════\n")
cat("  Shiny Cost Estimator - Dependency Checker\n")
cat("═══════════════════════════════════════════════════════════════\n\n")

# Required packages
required_packages <- c(
  "shiny",
  "bslib", 
  "plotly",
  "DT",
  "shinyWidgets",
  "jsonlite",
  "RColorBrewer"
)

# Optional but recommended
recommended_packages <- c(
  "rsconnect",  # For deployment
  "rmarkdown",  # For PDF reports
  "knitr"       # For PDF reports
)

# Check function
check_package <- function(pkg) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    version <- as.character(packageVersion(pkg))
    cat("✓", pkg, paste0("(v", version, ")"), "\n")
    return(TRUE)
  } else {
    cat("✗", pkg, "(not installed)\n")
    return(FALSE)
  }
}

# Check required packages
cat("Required Packages:\n")
cat("─────────────────────────────────────────────────────────────\n")
required_status <- sapply(required_packages, check_package)

cat("\n")

# Check recommended packages
cat("Recommended Packages:\n")
cat("─────────────────────────────────────────────────────────────\n")
recommended_status <- sapply(recommended_packages, check_package)

cat("\n")

# Check R version
r_version <- paste(R.version$major, R.version$minor, sep = ".")
cat("R Version:", r_version)
if (as.numeric(R.version$major) >= 4) {
  cat(" ✓\n")
} else {
  cat(" ⚠ (R >= 4.0 recommended)\n")
}

cat("\n")

# Check source files
cat("Source Files:\n")
cat("─────────────────────────────────────────────────────────────\n")

source_files <- c(
  "../R/shiny_cost_estimator.R",
  "../R/repo_code_analyzer.R"
)

for (file in source_files) {
  if (file.exists(file)) {
    cat("✓", file, "\n")
  } else {
    cat("✗", file, "(not found)\n")
  }
}

cat("\n")

# Summary
cat("═══════════════════════════════════════════════════════════════\n")
cat("Summary:\n")
cat("─────────────────────────────────────────────────────────────\n")

missing_required <- required_packages[!required_status]
missing_recommended <- recommended_packages[!recommended_status]

if (length(missing_required) == 0) {
  cat("✓ All required packages installed!\n")
} else {
  cat("⚠", length(missing_required), "required package(s) missing:\n")
  cat("  ", paste(missing_required, collapse = ", "), "\n\n")
  cat("  Install with:\n")
  cat("  install.packages(c('", paste(missing_required, collapse = "', '"), "'))\n\n", sep = "")
}

if (length(missing_recommended) > 0) {
  cat("ℹ", length(missing_recommended), "recommended package(s) missing:\n")
  cat("  ", paste(missing_recommended, collapse = ", "), "\n\n")
  cat("  Install with:\n")
  cat("  install.packages(c('", paste(missing_recommended, collapse = "', '"), "'))\n\n", sep = "")
}

# Ready status
if (length(missing_required) == 0 && all(file.exists(source_files))) {
  cat("\n")
  cat("🎉 Ready to deploy!\n")
  cat("\n")
  cat("Next steps:\n")
  cat("  1. Test locally:  shiny::runApp('cost-estimator-app')\n")
  cat("  2. Deploy:        See DEPLOYMENT.md for instructions\n")
} else {
  cat("\n")
  cat("⚠ Not ready to deploy. Please install missing packages/files.\n")
}

cat("═══════════════════════════════════════════════════════════════\n\n")

# Return invisible status
invisible(list(
  required_ok = length(missing_required) == 0,
  recommended_ok = length(missing_recommended) == 0,
  files_ok = all(file.exists(source_files)),
  missing_required = missing_required,
  missing_recommended = missing_recommended
))
