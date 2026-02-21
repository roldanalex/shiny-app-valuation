# Comparison Module
# Side-by-side scenario comparison

comparisonUI <- function(id) {
  ns <- NS(id)
  card(
    card_header("Compare Multiple Scenarios"),
    card_body(
      p("Create and compare up to 3 different cost estimation scenarios side-by-side."),

      layout_column_wrap(
        width = 1/3,

        # Scenario 1
        card(
          card_header("Scenario 1", class = "bg-primary text-white"),
          numericInput(ns("lines_1"), "Code Lines:", value = 10000, min = 100),
          selectInput(ns("complexity_1"), "Complexity:",
                     choices = c("Low" = "low", "Medium" = "medium", "High" = "high"),
                     selected = "medium"),
          sliderInput(ns("team_1"), "Team Exp:", min = 1, max = 5, value = 4),
          sliderInput(ns("reuse_1"), "Reuse:", min = 0.7, max = 1.3, value = 1.0, step = 0.1),
          sliderInput(ns("tools_1"), "Tool Support:", min = 0.8, max = 1.2, value = 1.0, step = 0.1),
          actionButton(ns("calc_1"), "Calculate", class = "btn-primary w-100")
        ),

        # Scenario 2
        card(
          card_header("Scenario 2", class = "bg-success text-white"),
          numericInput(ns("lines_2"), "Code Lines:", value = 10000, min = 100),
          selectInput(ns("complexity_2"), "Complexity:",
                     choices = c("Low" = "low", "Medium" = "medium", "High" = "high"),
                     selected = "high"),
          sliderInput(ns("team_2"), "Team Exp:", min = 1, max = 5, value = 3),
          sliderInput(ns("reuse_2"), "Reuse:", min = 0.7, max = 1.3, value = 1.2, step = 0.1),
          sliderInput(ns("tools_2"), "Tool Support:", min = 0.8, max = 1.2, value = 1.0, step = 0.1),
          actionButton(ns("calc_2"), "Calculate", class = "btn-success w-100")
        ),

        # Scenario 3
        card(
          card_header("Scenario 3", class = "bg-info text-white"),
          numericInput(ns("lines_3"), "Code Lines:", value = 10000, min = 100),
          selectInput(ns("complexity_3"), "Complexity:",
                     choices = c("Low" = "low", "Medium" = "medium", "High" = "high"),
                     selected = "low"),
          sliderInput(ns("team_3"), "Team Exp:", min = 1, max = 5, value = 5),
          sliderInput(ns("reuse_3"), "Reuse:", min = 0.7, max = 1.3, value = 0.8, step = 0.1),
          sliderInput(ns("tools_3"), "Tool Support:", min = 0.8, max = 1.2, value = 0.9, step = 0.1),
          actionButton(ns("calc_3"), "Calculate", class = "btn-info w-100")
        )
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

    observeEvent(input$calc_1, {
      scenarios$s1 <- estimate_shiny_cost(
        code_lines = input$lines_1,
        complexity = input$complexity_1,
        team_experience = input$team_1,
        reuse_factor = input$reuse_1,
        tool_support = input$tools_1
      )
    })

    observeEvent(input$calc_2, {
      scenarios$s2 <- estimate_shiny_cost(
        code_lines = input$lines_2,
        complexity = input$complexity_2,
        team_experience = input$team_2,
        reuse_factor = input$reuse_2,
        tool_support = input$tools_2
      )
    })

    observeEvent(input$calc_3, {
      scenarios$s3 <- estimate_shiny_cost(
        code_lines = input$lines_3,
        complexity = input$complexity_3,
        team_experience = input$team_3,
        reuse_factor = input$reuse_3,
        tool_support = input$tools_3
      )
    })

    get_scenarios <- reactive({
      s <- list()
      if (!is.null(scenarios$s1)) s$s1 <- scenarios$s1
      if (!is.null(scenarios$s2)) s$s2 <- scenarios$s2
      if (!is.null(scenarios$s3)) s$s3 <- scenarios$s3
      s
    })

    output$comparison_chart <- renderPlotly({
      s <- get_scenarios()
      if (length(s) == 0) return(NULL)

      scenario_names <- paste("Scenario", seq_along(s))
      costs     <- sapply(s, function(e) e$realistic_cost_usd)
      ci_low    <- sapply(s, function(e) e$confidence_interval$low)
      ci_high   <- sapply(s, function(e) e$confidence_interval$high)
      schedules <- sapply(s, function(e) e$final_schedule_months)
      teams     <- sapply(s, function(e) e$final_people)

      bar_colors <- c("#375a7f", "#00bc8c", "#e74c3c")

      p <- plot_ly()

      for (i in seq_along(s)) {
        col <- bar_colors[((i - 1) %% length(bar_colors)) + 1]
        p <- p %>%
          add_trace(
            type        = "bar",
            name        = scenario_names[i],
            x           = c("Cost (USD)", "Schedule (months)", "Team Size"),
            y           = c(costs[i], schedules[i], teams[i]),
            marker      = list(color = col),
            error_y     = list(
              type      = "data",
              symmetric = FALSE,
              array     = c(ci_high[i] - costs[i], 0, 0),
              arrayminus = c(costs[i] - ci_low[i], 0, 0),
              color     = col,
              thickness = 2,
              width     = 6
            )
          )
      }

      p %>%
        layout(
          title    = list(text = "Scenario Comparison", font = list(color = "#dee2e6")),
          yaxis    = list(
            title     = "Value",
            color     = "#dee2e6",
            gridcolor = "rgba(255,255,255,0.1)"
          ),
          xaxis    = list(color = "#dee2e6"),
          barmode  = "group",
          paper_bgcolor = "transparent",
          plot_bgcolor  = "transparent",
          font     = list(color = "#dee2e6"),
          legend   = list(font = list(color = "#dee2e6"))
        )
    })

    output$comparison_table <- renderDT({
      s <- get_scenarios()
      if (length(s) == 0) return(NULL)

      comp_df <- data.frame()
      for (i in seq_along(s)) {
        est <- s[[i]]
        comp_df <- rbind(comp_df, data.frame(
          Scenario = paste("Scenario", i),
          CodeLines = format(est$code_lines, big.mark = ","),
          Cost = paste0("$", format(est$realistic_cost_usd, big.mark = ",")),
          `Confidence` = paste0("$", format(est$confidence_interval$low, big.mark = ","),
                               " - $", format(est$confidence_interval$high, big.mark = ",")),
          Schedule = paste0(est$final_schedule_months, " months"),
          TeamSize = est$final_people,
          Effort = paste0(est$effort_person_months, " PM"),
          Complexity = est$params$complexity,
          TeamExp = est$params$team_experience,
          check.names = FALSE
        ))
      }

      datatable(comp_df, options = list(pageLength = 10), rownames = FALSE)
    })
  })
}
