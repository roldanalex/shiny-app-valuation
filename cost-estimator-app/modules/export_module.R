# Export & Share Module
# PDF report, shareable URL, and raw data downloads.

exportUI <- function(id) {
  ns <- NS(id)
  card(
    card_header("Export & Share Your Analysis"),
    card_body(
      layout_column_wrap(
        width = 1/2,

        card(
          card_header("PDF Report"),
          card_body(
            p("Download a branded, client-ready PDF report with the headline",
              " estimate, key charts, assumptions, and methodology."),
            uiOutput(ns("pdf_section"))
          )
        ),

        card(
          card_header("Shareable URL"),
          card_body(
            p("Generate a URL with pre-filled parameters to share your",
              " analysis configuration (Manual Entry only)."),
            actionButton(ns("generate_url"), "Generate Shareable Link",
                        icon = icon("link"),
                        class = "btn-primary w-100"),
            hr(),
            uiOutput(ns("shareable_url_display"))
          )
        )
      ),

      card(
        class = "mt-3",
        card_header("Export Data"),
        card_body(
          layout_column_wrap(
            width = 1/2,
            downloadButton(ns("download_csv"), "Download CSV",
                          class = "btn-outline-secondary w-100"),
            downloadButton(ns("download_json"), "Download JSON",
                          class = "btn-outline-secondary w-100")
          )
        )
      )
    )
  )
}

exportServer <- function(id, results, analysis_handles, session_data) {
  moduleServer(id, function(input, output, session) {

    has_estimate <- reactive({
      !is.null(results$analyze)
    })

    # ── PDF report ──────────────────────────────────────────────────────────
    output$pdf_section <- renderUI({
      ns <- session$ns
      if (!pdf_report_available()) {
        tags$div(
          class = "alert alert-warning mb-0",
          "PDF rendering is unavailable: the ", tags$code("quarto"),
          " package (and Quarto >= 1.3) is required."
        )
      } else if (!has_estimate()) {
        tags$div(
          class = "alert alert-info mb-0",
          "Run an analysis first, then download your report here."
        )
      } else {
        downloadButton(ns("download_pdf"), "Download PDF Report",
                      class = "btn-primary w-100", icon = icon("file-pdf"))
      }
    })

    output$download_pdf <- pdf_download_handler(function() {
      data <- results$analyze
      build_report_payload(
        est          = analysis_handles$est(),
        billable     = analysis_handles$billable_data(),
        curve        = analysis_handles$tradeoff_curve(),
        project_name = if (!is.null(data$source_label)) data$source_label else "Your Project"
      )
    })

    # ── Shareable URL ───────────────────────────────────────────────────────
    observeEvent(input$generate_url, {
      r <- results$analyze
      if (!is.null(r) && !is.null(r$language_mix) && !is.null(r$params)) {
        p <- r$params
        query_string <- paste0(
          "?mode=manual",
          "&r=",   if (!is.null(r$language_mix[["R"]]))          r$language_mix[["R"]]          else 0,
          "&py=",  if (!is.null(r$language_mix[["Python"]]))      r$language_mix[["Python"]]      else 0,
          "&js=",  if (!is.null(r$language_mix[["JavaScript"]])) r$language_mix[["JavaScript"]] else 0,
          "&sql=", if (!is.null(r$language_mix[["SQL"]]))         r$language_mix[["SQL"]]         else 0,
          "&complexity=", p$complexity,
          "&team=", p$team_exp,
          "&reuse=", p$reuse,
          "&tools=", p$tools
        )

        parent_session <- session_data$parent_session
        full_url <- paste0(
          parent_session$clientData$url_protocol, "//",
          parent_session$clientData$url_hostname, ":",
          parent_session$clientData$url_port,
          parent_session$clientData$url_pathname,
          query_string
        )

        output$shareable_url_display <- renderUI({
          tagList(
            h5("Copy this URL:"),
            tags$div(
              class = "alert alert-info",
              tags$code(full_url),
              tags$button(
                class = "btn btn-sm btn-outline-secondary mt-2 d-block",
                # URL is app-generated (numeric params + whitelisted values),
                # JSON-encoded to keep the attribute injection-safe
                onclick = paste0("navigator.clipboard.writeText(",
                                 jsonlite::toJSON(full_url, auto_unbox = TRUE), ")"),
                "Copy to Clipboard"
              )
            )
          )
        })

        showNotification("Shareable URL generated!", type = "message", duration = 3)
      } else {
        showNotification(
          "Please run a Manual Entry analysis first to generate a shareable URL.",
          type = "warning"
        )
      }
    })

    # ── Raw data downloads ──────────────────────────────────────────────────
    output$download_csv <- downloadHandler(
      filename = function() {
        paste0("cost_estimate_", format(Sys.Date(), "%Y%m%d"), ".csv")
      },
      content = function(file) {
        r <- results$analyze
        if (!is.null(r) && !is.null(r$lang_summary)) {
          write.csv(r$lang_summary, file, row.names = FALSE)
        } else {
          showNotification("No language data to export. Run a Local Folder or ZIP analysis first.", type = "warning")
          write.csv(data.frame(), file, row.names = FALSE)
        }
      }
    )

    output$download_json <- downloadHandler(
      filename = function() {
        paste0("cost_estimate_", format(Sys.Date(), "%Y%m%d"), ".json")
      },
      content = function(file) {
        jsonlite::write_json(results$analyze, file, pretty = TRUE)
      }
    )
  })
}
