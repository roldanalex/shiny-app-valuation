# Branded PDF report rendering (Quarto + Typst - no LaTeX or Chrome needed,
# works on shinyapps.io). Shared by the export module and the summary strip.

pdf_report_available <- function() {
  requireNamespace("quarto", quietly = TRUE) &&
    !is.null(quarto::quarto_path()) &&
    requireNamespace("ggplot2", quietly = TRUE) &&
    dir.exists("report")
}

#' Assemble everything the .qmd needs into one payload
build_report_payload <- function(est, billable, curve, project_name) {
  list(
    est          = est,
    billable     = billable[c("total_code", "billable_code", "has_docs")],
    curve        = curve,
    colors       = app_colors,
    app_version  = if (exists("APP_VERSION")) APP_VERSION else "2.0.0",
    project_name = project_name,
    generated_on = Sys.Date()
  )
}

#' Render the report to output_file. Renders in a tempdir copy because the
#' deployed app directory is not reliably writable on shinyapps.io.
render_estimate_pdf <- function(payload, output_file) {
  work_root <- file.path(tempdir(), paste0("report_", as.integer(Sys.time()),
                                           "_", sample.int(1e6, 1)))
  dir.create(work_root, recursive = TRUE)
  on.exit(unlink(work_root, recursive = TRUE), add = TRUE)

  file.copy("report", work_root, recursive = TRUE)
  work_dir <- file.path(work_root, "report")
  saveRDS(payload, file.path(work_dir, "data.rds"))

  quarto::quarto_render(
    input          = file.path(work_dir, "estimate_report.qmd"),
    execute_params = list(data_path = "data.rds"),
    quiet          = FALSE
  )

  pdf_path <- file.path(work_dir, "estimate_report.pdf")
  if (!file.exists(pdf_path)) stop("PDF rendering failed - no output produced.")
  file.copy(pdf_path, output_file, overwrite = TRUE)
  invisible(output_file)
}

#' downloadHandler wrapper used by both call sites
pdf_download_handler <- function(get_payload) {
  downloadHandler(
    filename = function() {
      sprintf("cost-estimate-%s.pdf", format(Sys.Date(), "%Y%m%d"))
    },
    content = function(file) {
      withProgress(message = "Rendering PDF report...", value = 0.3, {
        payload <- get_payload()
        setProgress(0.5, detail = "Building charts and pages")
        render_estimate_pdf(payload, file)
        setProgress(1)
      })
    }
  )
}
