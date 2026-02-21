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
                class = "btn btn-sm btn-secondary mt-2",
                onclick = paste0("navigator.clipboard.writeText('", full_url, "')"),
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
