# Export & Share Module

exportUI <- function(id) {
  ns <- NS(id)
  card(
    card_header("Export & Share Your Analysis"),
    card_body(
      layout_column_wrap(
        width = 1/2,

        card(
          card_header("Shareable URL"),
          p("Generate a URL with pre-filled parameters to share your analysis configuration."),
          selectInput(ns("url_source"), "Data Source:",
                     choices = c("Manual Entry" = "manual")),
          actionButton(ns("generate_url"), "Generate Shareable Link",
                      icon = icon("link"),
                      class = "btn-success w-100"),
          hr(),
          uiOutput(ns("shareable_url_display"))
        ),

        card(
          card_header("Export Data"),
          layout_column_wrap(
            width = 1,
            downloadButton(ns("download_csv"), "Download CSV",
                          class = "btn-secondary w-100"),
            downloadButton(ns("download_json"), "Download JSON",
                          class = "btn-secondary w-100")
          )
        )
      )
    )
  )
}

exportServer <- function(id, results, session_data) {
  moduleServer(id, function(input, output, session) {

    observeEvent(input$generate_url, {
      if (!is.null(results$manual) && !is.null(results$manual$params)) {
        p <- results$manual$params
        query_string <- paste0(
          "?mode=manual",
          "&r=", if (!is.null(results$manual$language_mix[["R"]])) results$manual$language_mix[["R"]] else 0,
          "&py=", if (!is.null(results$manual$language_mix[["Python"]])) results$manual$language_mix[["Python"]] else 0,
          "&js=", if (!is.null(results$manual$language_mix[["JavaScript"]])) results$manual$language_mix[["JavaScript"]] else 0,
          "&sql=", if (!is.null(results$manual$language_mix[["SQL"]])) results$manual$language_mix[["SQL"]] else 0,
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
                class = "btn btn-sm btn-secondary mt-2",
                onclick = paste0("navigator.clipboard.writeText('", full_url, "')"),
                "Copy to Clipboard"
              )
            )
          )
        })

        showNotification("Shareable URL generated!", type = "message", duration = 3)
      } else {
        showNotification("Please complete a manual analysis first.", type = "warning")
      }
    })

    output$download_csv <- downloadHandler(
      filename = function() {
        paste0("cost_estimate_", format(Sys.Date(), "%Y%m%d"), ".csv")
      },
      content = function(file) {
        if (!is.null(results$local)) {
          write.csv(results$local$lang_summary, file, row.names = FALSE)
        } else if (!is.null(results$zip)) {
          write.csv(results$zip$lang_summary, file, row.names = FALSE)
        } else {
          showNotification("No data to export", type = "warning")
        }
      }
    )

    output$download_json <- downloadHandler(
      filename = function() {
        paste0("cost_estimate_", format(Sys.Date(), "%Y%m%d"), ".json")
      },
      content = function(file) {
        export_data <- list(
          local = results$local,
          zip = results$zip,
          manual = results$manual
        )
        jsonlite::write_json(export_data, file, pretty = TRUE)
      }
    )
  })
}
