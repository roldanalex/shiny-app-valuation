# Sync canonical engine sources from R/ into the app's modules/ directory.
# The modules/ copies are BUILD ARTIFACTS - never edit them by hand.
# Run from the repo root: Rscript tools/sync_modules.R

synced_files <- c("shiny_cost_estimator.R", "repo_code_analyzer.R")

root <- normalizePath(".")
if (!dir.exists(file.path(root, "R"))) {
  stop("Run this script from the repository root (R/ directory not found).")
}

for (f in synced_files) {
  src <- file.path(root, "R", f)
  dst <- file.path(root, "cost-estimator-app", "modules", f)
  ok <- file.copy(src, dst, overwrite = TRUE)
  if (!ok) stop("Failed to copy ", src, " -> ", dst)
  hash <- tools::md5sum(c(src, dst))
  cat(sprintf("%-25s %s -> %s [%s]\n", f, "R/", "cost-estimator-app/modules/",
              if (hash[[1]] == hash[[2]]) "OK" else "HASH MISMATCH"))
  if (hash[[1]] != hash[[2]]) stop("Hash mismatch after copy for ", f)
}

cat("Sync complete.\n")
