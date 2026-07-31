# Comparison Module
# Side-by-side scenario comparison. Shared cost parameters (wage, schedule cap)
# apply to all scenarios so the dollar figures are actually comparable.

comparisonUI <- function(id) {
  ns <- NS(id)

  scenario_card <- function(n, complexity, team, reuse, tools) {
    card(
      card_header(paste("Scenario", n)),
      numericInput(ns(paste0("lines_", n)), "Code Lines:", value = 10000, min = 100),
      selectInput(ns(paste0("complexity_", n)), "Complexity:",
                 choices = c("Low" = "low", "Medium" = "medium", "High" = "high"),
                 selected = complexity),
      sliderInput(ns(paste0("team_", n)), "Team Exp:", min = 1, max = 5, value = team),
      sliderInput(ns(paste0("reuse_", n)), "Reuse:", min = 0.7, max = 1.3, value = reuse, step = 0.1),
      sliderInput(ns(paste0("tools_", n)), "Tool Support:", min = 0.8, max = 1.2, value = tools, step = 0.1),
      actionButton(ns(paste0("calc_", n)), "Calculate", class = "btn-primary w-100")
    )
  }

  card(
    card_header("Compare Multiple Scenarios"),
    card_body(
      p("Create and compare up to 3 different cost estimation scenarios side-by-side."),

      # Shared cost parameters - applied to every scenario
      card(
        class = "result-card mb-3",
        card_header("Shared Cost Parameters"),
        card_body(
          layout_column_wrap(
            width = 1/2,
            numericInput(ns("wage"), "Average Annual Wage ($):",
                        value = 105000, min = 50000, max = 300000, step = 5000),
            sliderInput(ns("max_schedule"), "Max Schedule (months):",
                       min = 3, max = 36, value = 24, step = 3)
          ),
          tags$small(class = "text-muted",
            "These apply to all scenarios so costs stay comparable.")
        )
      ),

      layout_column_wrap(
        width = 1/3,
        scenario_card(1, "medium", 4, 1.0, 1.0),
        scenario_card(2, "high",   3, 1.2, 1.0),
        scenario_card(3, "low",    5, 0.8, 0.9)
      ),

      hr(),
      h4("Comparison Results"),
      plotlyOutput(ns("comparison_chart"), height = "400px"),
      hr(),
      DTOutput(ns("comparison_table"))
    )
  )
}

comparisonServer <- function(id) {
  moduleServer(id, function(input, output, session) {
    scenarios <- reactiveValues(s1 = NULL, s2 = NULL, s3 = NULL)

    calc_scenario <- function(n) {
      tryCatch(
        estimate_shiny_cost(
          code_lines          = max(0, input[[paste0("lines_", n)]]),
          complexity          = input[[paste0("complexity_", n)]],
          team_experience     = input[[paste0("team_", n)]],
          reuse_factor        = input[[paste0("reuse_", n)]],
          tool_support        = input[[paste0("tools_", n)]],
          avg_wage            = if (isTruthy(input$wage)) input$wage else 105000,
          max_schedule_months = if (isTruthy(input$max_schedule)) input$max_schedule else 24
        ),
        error = function(e) {
          showNotification(paste("Scenario", n, "error:", e$message), type = "error")
          NULL
        }
      )
    }

    observeEvent(input$calc_1, scenarios$s1 <- calc_scenario(1))
    observeEvent(input$calc_2, scenarios$s2 <- calc_scenario(2))
    observeEvent(input$calc_3, scenarios$s3 <- calc_scenario(3))

    # Recompute already-calculated scenarios when shared params change
    observeEvent(list(input$wage, input$max_schedule), {
      if (!is.null(scenarios$s1)) scenarios$s1 <- calc_scenario(1)
      if (!is.null(scenarios$s2)) scenarios$s2 <- calc_scenario(2)
      if (!is.null(scenarios$s3)) scenarios$s3 <- calc_scenario(3)
    }, ignoreInit = TRUE)

    get_scenarios <- reactive({
      s <- list()
      if (!is.null(scenarios$s1)) s[["Scenario 1"]] <- scenarios$s1
      if (!is.null(scenarios$s2)) s[["Scenario 2"]] <- scenarios$s2
      if (!is.null(scenarios$s3)) s[["Scenario 3"]] <- scenarios$s3
      s
    })

    output$comparison_chart <- renderPlotly({
      s <- get_scenarios()
      if (length(s) == 0) return(NULL)

      scenario_names <- names(s)
      costs      <- sapply(s, function(e) e$cost_usd)
      range_low  <- sapply(s, function(e) e$estimate_range$low)
      range_high <- sapply(s, function(e) e$estimate_range$high)
      schedules  <- sapply(s, function(e) e$final_schedule_months)
      teams      <- sapply(s, function(e) e$final_people)

      bar_colors <- app_colors$seq[c(5, 3, 2)][seq_along(s)]

      panel <- function(y, title, error_y = NULL, fmt = ",.0f", prefix = "") {
        plot_ly(
          x      = scenario_names,
          y      = y,
          type   = "bar",
          marker = list(color = bar_colors),
          error_y = error_y,
          showlegend = FALSE,
          hovertemplate = paste0("%{x}<br>", title, ": ", prefix,
                                 "%{y:", fmt, "}<extra></extra>")
        ) %>%
          layout(
            xaxis = c(app_plotly_layout$xaxis, list(title = "")),
            yaxis = c(app_plotly_layout$yaxis, list(title = title))
          )
      }

      subplot(
        panel(costs, "Cost (USD)", prefix = "$",
              error_y = list(
                type = "data", symmetric = FALSE,
                array = range_high - costs, arrayminus = costs - range_low,
                color = app_colors$ink_muted, thickness = 2, width = 6
              )),
        panel(schedules, "Schedule (months)", fmt = ",.1f"),
        panel(teams, "Team Size", fmt = ",.1f"),
        nrows = 1, shareX = FALSE, shareY = FALSE,
        titleY = TRUE, margin = 0.06
      ) %>%
        layout(
          paper_bgcolor = app_plotly_layout$paper_bgcolor,
          plot_bgcolor  = app_plotly_layout$plot_bgcolor,
          font          = app_plotly_layout$font,
          showlegend    = FALSE
        )
    })

    output$comparison_table <- renderDT({
      s <- get_scenarios()
      if (length(s) == 0) return(NULL)

      comp_df <- data.frame()
      for (nm in names(s)) {
        est <- s[[nm]]
        comp_df <- rbind(comp_df, data.frame(
          Scenario  = nm,
          CodeLines = format(est$code_lines, big.mark = ","),
          Cost      = paste0("$", format(est$cost_usd, big.mark = ",")),
          `Range (±30%)` = paste0("$", format(est$estimate_range$low, big.mark = ","),
                                  " - $", format(est$estimate_range$high, big.mark = ",")),
          Schedule  = paste0(est$final_schedule_months, " months"),
          TeamSize  = est$final_people,
          Effort    = paste0(est$effort_person_months, " PM"),
          Complexity = est$params$complexity,
          TeamExp   = est$params$team_experience,
          check.names = FALSE
        ))
      }

      datatable(comp_df, options = list(pageLength = 10), rownames = FALSE)
    })
  })
}
