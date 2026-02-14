# Shared Analysis Results Module
# Renders value boxes, charts, tables, sensitivity, and maintenance panels

# Dark-theme plotly layout defaults
dark_plotly_layout <- list(
  paper_bgcolor = "transparent",
  plot_bgcolor = "transparent",
  font = list(color = "#dee2e6"),
  xaxis = list(
    color = "#dee2e6",
    gridcolor = "rgba(255,255,255,0.1)",
    zerolinecolor = "rgba(255,255,255,0.2)"
  ),
  yaxis = list(
    color = "#dee2e6",
    gridcolor = "rgba(255,255,255,0.1)",
    zerolinecolor = "rgba(255,255,255,0.2)"
  )
)

analysisResultsUI <- function(id, ai_available = FALSE) {
  ns <- NS(id)
  navset_card_tab(
    nav_panel("Results",
      uiOutput(ns("results_summary")),
      layout_column_wrap(
        width = 1/2,
        card(
          card_header("Code Distribution by Language"),
          card_body(plotlyOutput(ns("lang_chart"), height = "380px"))
        ),
        card(
          card_header("Cost Breakdown: COCOMO II Multipliers"),
          card_body(plotlyOutput(ns("cost_breakdown"), height = "380px"))
        )
      )
    ),
    nav_panel("Details",
      DTOutput(ns("details_table")),
      tags$h5("Estimate Report",
        style = "border-bottom: 1px solid #444; padding-bottom: 8px; margin-top: 24px;"
      ),
      verbatimTextOutput(ns("estimate_text"))
    ),
    nav_panel("Sensitivity",
      uiOutput(ns("sensitivity_ui"))
    ),
    nav_panel("Maintenance & TCO",
      uiOutput(ns("maintenance_ui"))
    ),
    nav_panel("AI Assistant",
      if (!ai_available) {
        card(
          card_header("AI Assistant"),
          card_body(
            h4("Optional packages required"),
            p("The AI Assistant requires the",
              tags$code("ellmer"), "and",
              tags$code("shinychat"),
              "packages, which are not currently installed."),
            p("Install them from R:"),
            tags$pre("install.packages(c('ellmer', 'shinychat'))"),
            p("Then restart the app to enable the AI Assistant.")
          )
        )
      } else if (!nzchar(Sys.getenv("OPENAI_API_KEY", ""))) {
        card(
          card_header("AI Assistant"),
          card_body(
            h4("API key required"),
            p("The AI Assistant needs an OpenAI API key to generate responses."),
            p("Set it before launching the app:"),
            tags$pre('Sys.setenv(OPENAI_API_KEY = "sk-...")'),
            p("Or set the", tags$code("OPENAI_API_KEY"),
              "environment variable in your", tags$code(".Renviron"), "file."),
            p("Then restart the app.")
          )
        )
      } else {
        card(
          card_body(
            style = "padding: 0;",
            chat_ui(ns("ai_chat"), height = "600px")
          )
        )
      }
    )
  )
}

analysisResultsServer <- function(id, analysis_data, params, ai_available = FALSE) {
  moduleServer(id, function(input, output, session) {

    # Compute estimate reactively
    est <- reactive({
      req(analysis_data())
      data <- analysis_data()

      if (!is.null(data$lang_summary)) {
        lang_df <- data$lang_summary
        total_code <- sum(lang_df$Code)
        language_mix <- setNames(lang_df$Code, lang_df$Language)
      } else {
        total_code <- sum(unlist(data$language_mix))
        language_mix <- data$language_mix
      }

      p <- params()
      estimate_shiny_cost(
        code_lines = total_code,
        complexity = p$complexity,
        team_experience = p$team_exp,
        reuse_factor = p$reuse,
        tool_support = p$tools,
        language_mix = language_mix,
        avg_wage = if (!is.null(p$wage)) p$wage else 105000,
        max_team_size = if (!is.null(p$max_team)) p$max_team else 5,
        max_schedule_months = if (!is.null(p$max_schedule)) p$max_schedule else 24,
        rely = if (!is.null(p$rely)) p$rely else 1.0,
        cplx = if (!is.null(p$cplx)) p$cplx else 1.0,
        ruse = if (!is.null(p$ruse)) p$ruse else 1.0,
        pcon = if (!is.null(p$pcon)) p$pcon else 1.0,
        apex = if (!is.null(p$apex)) p$apex else 1.0,
        maintenance_rate = if (!is.null(p$maintenance_rate)) p$maintenance_rate else 0.20,
        maintenance_years = if (!is.null(p$maintenance_years)) p$maintenance_years else 0
      )
    })

    # Value boxes
    output$results_summary <- renderUI({
      e <- est()
      ci_text <- paste0(
        "$", format(e$confidence_interval$low, big.mark = ","),
        " - $", format(e$confidence_interval$high, big.mark = ",")
      )
      tagList(
        layout_columns(
          col_widths = c(5, 7),
          heights_equal = "row",

          # Hero cost card (left)
          value_box(
            title = "Estimated Cost",
            value = paste0("$", format(e$realistic_cost_usd, big.mark = ",")),
            p(ci_text),
            showcase = icon("dollar-sign"),
            showcase_layout = "top right",
            theme = "success",
            height = "100%"
          ),

          # 2x2 KPI grid (right)
          layout_column_wrap(
            width = 1/2,
            height = "100%",
            value_box(
              title = "Total Code Lines",
              value = format(e$code_lines, big.mark = ","),
              showcase = icon("code"),
              theme = "primary"
            ),
            value_box(
              title = "Schedule",
              value = paste0(e$final_schedule_months, " months"),
              showcase = icon("calendar"),
              theme = "info"
            ),
            value_box(
              title = "Team Size",
              value = paste0(e$final_people, " people"),
              showcase = icon("users"),
              theme = "warning"
            ),
            if (!is.null(e$maintenance)) {
              value_box(
                title = "Total Cost (TCO)",
                value = paste0(
                  "$", format(e$maintenance$tco, big.mark = ",")
                ),
                showcase = icon("coins"),
                theme = "primary"
              )
            } else {
              value_box(
                title = "Effort",
                value = paste0(e$effort_person_months, " PM"),
                showcase = icon("clock"),
                theme = "primary"
              )
            }
          )
        )
      )
    })

    # Language pie chart
    output$lang_chart <- renderPlotly({
      data <- analysis_data()
      if (!is.null(data$lang_summary)) {
        lang_df <- data$lang_summary
      } else {
        lang_df <- data.frame(
          Language = names(data$language_mix),
          Code = unlist(data$language_mix)
        )
      }
      n_colors <- max(3, nrow(lang_df))
      colors <- RColorBrewer::brewer.pal(min(n_colors, 12), "Set3")

      plot_ly(lang_df, labels = ~Language, values = ~Code, type = 'pie',
             textposition = 'inside',
             textinfo = 'label+percent',
             hoverinfo = 'label+value+percent',
             marker = list(colors = colors),
             textfont = list(color = "#fff")) %>%
        layout(
          showlegend = TRUE,
          paper_bgcolor = dark_plotly_layout$paper_bgcolor,
          plot_bgcolor = dark_plotly_layout$plot_bgcolor,
          font = dark_plotly_layout$font,
          legend = list(font = list(color = "#dee2e6"))
        )
    })

    # Waterfall cost breakdown chart
    output$cost_breakdown <- renderPlotly({
      e <- est()
      mb <- e$multiplier_breakdown
      base_cost <- mb$base_effort * 12000

      # Compute incremental effect of each multiplier
      multipliers <- list(
        list(name = "Experience", val = mb$EM_experience),
        list(name = "Reuse", val = mb$EM_reuse),
        list(name = "Tools", val = mb$EM_tools),
        list(name = "Modern Framework", val = mb$EM_modern)
      )

      # Only show non-default COCOMO drivers
      if (mb$EM_rely != 1.0) multipliers <- c(multipliers, list(list(name = "Reliability", val = mb$EM_rely)))
      if (mb$EM_cplx != 1.0) multipliers <- c(multipliers, list(list(name = "Complexity", val = mb$EM_cplx)))
      if (mb$EM_ruse != 1.0) multipliers <- c(multipliers, list(list(name = "Reusability", val = mb$EM_ruse)))
      if (mb$EM_pcon != 1.0) multipliers <- c(multipliers, list(list(name = "Personnel", val = mb$EM_pcon)))
      if (mb$EM_apex != 1.0) multipliers <- c(multipliers, list(list(name = "App Experience", val = mb$EM_apex)))

      names_vec <- c("Base Effort")
      values_vec <- c(base_cost)
      measures_vec <- c("absolute")

      running <- base_cost
      for (m in multipliers) {
        delta <- running * (m$val - 1)
        names_vec <- c(names_vec, m$name)
        values_vec <- c(values_vec, delta)
        measures_vec <- c(measures_vec, "relative")
        running <- running + delta
      }

      names_vec <- c(names_vec, "Final Cost")
      values_vec <- c(values_vec, e$estimated_cost_usd)
      measures_vec <- c(measures_vec, "total")

      plot_ly(
        type = "waterfall",
        x = ~names_vec,
        y = ~values_vec,
        measure = ~measures_vec,
        connector = list(line = list(color = "rgba(255,255,255,0.3)")),
        decreasing = list(marker = list(color = "#00bc8c")),
        increasing = list(marker = list(color = "#e74c3c")),
        totals = list(marker = list(color = "#375a7f"))
      ) %>%
        layout(
          xaxis = list(
            title = "",
            categoryorder = "array",
            categoryarray = names_vec,
            color = "#dee2e6",
            gridcolor = "rgba(255,255,255,0.1)"
          ),
          yaxis = list(
            title = "Cost (USD)",
            color = "#dee2e6",
            gridcolor = "rgba(255,255,255,0.1)"
          ),
          showlegend = FALSE,
          paper_bgcolor = dark_plotly_layout$paper_bgcolor,
          plot_bgcolor = dark_plotly_layout$plot_bgcolor,
          font = dark_plotly_layout$font
        )
    })

    # Details table
    output$details_table <- renderDT({
      data <- analysis_data()
      if (!is.null(data$lang_summary)) {
        datatable(data$lang_summary,
                 options = list(pageLength = 10, scrollX = TRUE),
                 rownames = FALSE)
      }
    })

    # Estimate text report
    output$estimate_text <- renderText({
      e <- est()
      report <- paste0(
        "===== COST ESTIMATION REPORT =====\n\n",
        "Total Code Lines: ", format(e$code_lines, big.mark = ","), "\n",
        "Estimated Cost: $", format(e$realistic_cost_usd, big.mark = ","), "\n",
        "Confidence Range: $", format(e$confidence_interval$low, big.mark = ","),
        " - $", format(e$confidence_interval$high, big.mark = ","), "\n",
        "Schedule: ", e$final_schedule_months, " months (", round(e$final_schedule_months/12, 1), " years)\n",
        "Team Size: ", e$final_people, " people\n",
        "Effort: ", e$effort_person_months, " person-months\n\n",
        "Parameters Used:\n",
        "  Complexity: ", e$params$complexity, "\n",
        "  Team Experience: ", e$params$team_experience, "\n",
        "  Reuse Factor: ", e$params$reuse_factor, "\n",
        "  Tool Support: ", e$params$tool_support, "\n"
      )
      if (e$premium_multiplier > 1.0) {
        report <- paste0(report, "  Schedule Premium: +", round((e$premium_multiplier - 1) * 100), "%\n")
      }
      if (!is.null(e$maintenance)) {
        report <- paste0(report,
          "\nMaintenance & TCO:\n",
          "  Annual Maintenance: $", format(e$maintenance$annual_maintenance, big.mark = ","), "\n",
          "  Total Maintenance (", e$maintenance$maintenance_years, "yr): $",
          format(e$maintenance$total_maintenance, big.mark = ","), "\n",
          "  Total Cost of Ownership: $", format(e$maintenance$tco, big.mark = ","), "\n"
        )
      }
      report
    })

    # Sensitivity analysis
    output$sensitivity_ui <- renderUI({
      ns <- session$ns
      tagList(
        h4("Sensitivity Analysis: How Parameters Affect Cost"),
        p("Shows how changes in complexity and team experience affect the estimated cost:"),
        plotlyOutput(ns("sensitivity_chart"), height = "400px")
      )
    })

    output$sensitivity_chart <- renderPlotly({
      data <- analysis_data()
      p <- params()

      if (!is.null(data$lang_summary)) {
        total_code <- sum(data$lang_summary$Code)
        language_mix <- setNames(data$lang_summary$Code, data$lang_summary$Language)
      } else {
        total_code <- sum(unlist(data$language_mix))
        language_mix <- data$language_mix
      }

      complexity_vals <- c("low", "medium", "high")
      team_vals <- 1:5

      sens_data <- data.frame()
      for (comp in complexity_vals) {
        for (team in team_vals) {
          e <- estimate_shiny_cost(
            code_lines = total_code,
            complexity = comp,
            team_experience = team,
            reuse_factor = p$reuse,
            tool_support = p$tools,
            language_mix = language_mix,
            avg_wage = if (!is.null(p$wage)) p$wage else 105000,
            max_team_size = if (!is.null(p$max_team)) p$max_team else 5,
            max_schedule_months = if (!is.null(p$max_schedule)) p$max_schedule else 24
          )
          sens_data <- rbind(sens_data, data.frame(
            Complexity = comp,
            TeamExp = team,
            Cost = e$realistic_cost_usd
          ))
        }
      }

      plot_ly(sens_data, x = ~TeamExp, y = ~Cost, color = ~Complexity,
             type = 'scatter', mode = 'lines+markers',
             colors = c("#00bc8c", "#375a7f", "#e74c3c")) %>%
        layout(
          title = list(
            text = "Cost Sensitivity: Team Experience vs Complexity",
            font = list(color = "#dee2e6")
          ),
          xaxis = list(
            title = "Team Experience Level",
            color = "#dee2e6",
            gridcolor = "rgba(255,255,255,0.1)"
          ),
          yaxis = list(
            title = "Estimated Cost (USD)",
            color = "#dee2e6",
            gridcolor = "rgba(255,255,255,0.1)"
          ),
          paper_bgcolor = dark_plotly_layout$paper_bgcolor,
          plot_bgcolor = dark_plotly_layout$plot_bgcolor,
          font = dark_plotly_layout$font,
          legend = list(font = list(color = "#dee2e6"))
        )
    })

    # Maintenance & TCO panel
    output$maintenance_ui <- renderUI({
      ns <- session$ns
      e <- est()
      if (is.null(e$maintenance)) {
        tagList(
          h4("Maintenance & Total Cost of Ownership"),
          p("Set maintenance years > 0 in the sidebar to see TCO projections."),
          tags$small("Typical annual maintenance is 15-25% of initial build cost.")
        )
      } else {
        m <- e$maintenance
        tagList(
          h4("Maintenance & Total Cost of Ownership"),
          layout_column_wrap(
            width = 1/3,
            value_box(
              title = "Build Cost",
              value = paste0("$", format(e$realistic_cost_usd, big.mark = ",")),
              theme = "primary"
            ),
            value_box(
              title = paste0("Maintenance (", m$maintenance_years, "yr)"),
              value = paste0("$", format(m$total_maintenance, big.mark = ",")),
              theme = "warning"
            ),
            value_box(
              title = "Total Cost (TCO)",
              value = paste0("$", format(m$tco, big.mark = ",")),
              theme = "success"
            )
          ),
          hr(),
          plotlyOutput(ns("maintenance_chart"), height = "350px")
        )
      }
    })

    output$maintenance_chart <- renderPlotly({
      e <- est()
      req(e$maintenance)
      m <- e$maintenance

      years <- seq_len(m$maintenance_years)
      plot_ly() %>%
        add_bars(x = "Build", y = e$realistic_cost_usd, name = "Build Cost",
                marker = list(color = "#375a7f")) %>%
        add_bars(x = paste("Year", years), y = m$yearly_costs, name = "Maintenance",
                marker = list(color = "#e74c3c")) %>%
        layout(
          title = list(
            text = "Build vs. Annual Maintenance Costs",
            font = list(color = "#dee2e6")
          ),
          xaxis = list(
            title = "",
            color = "#dee2e6",
            gridcolor = "rgba(255,255,255,0.1)"
          ),
          yaxis = list(
            title = "Cost (USD)",
            color = "#dee2e6",
            gridcolor = "rgba(255,255,255,0.1)"
          ),
          barmode = "group",
          showlegend = TRUE,
          paper_bgcolor = dark_plotly_layout$paper_bgcolor,
          plot_bgcolor = dark_plotly_layout$plot_bgcolor,
          font = dark_plotly_layout$font,
          legend = list(font = list(color = "#dee2e6"))
        )
    })

    # ==========================================================================
    # AI ASSISTANT (per-tab, uses this module's own est() reactive)
    # ==========================================================================

    if (ai_available && nzchar(Sys.getenv("OPENAI_API_KEY", ""))) {

      # Build context text from this module's estimate
      ai_context <- reactive({
        e <- est()
        req(e)

        # Language breakdown
        data <- analysis_data()
        lang_info <- ""
        if (!is.null(data$lang_summary)) {
          lang_df <- data$lang_summary
          lang_info <- paste(
            sprintf("%s: %s lines", lang_df$Language, format(lang_df$Code, big.mark = ",")),
            collapse = ", "
          )
        } else if (!is.null(data$language_mix)) {
          lang_info <- paste(
            sprintf("%s: %s lines", names(data$language_mix), format(unlist(data$language_mix), big.mark = ",")),
            collapse = ", "
          )
        }

        ctx <- sprintf(
          paste0(
            "Code: %s total lines (%s). ",
            "Complexity: %s, Team experience: %s/5. ",
            "Estimated cost: $%s, Schedule: %.1f months, Team: %.1f people. ",
            "Effort: %.1f person-months. ",
            "Confidence range: $%s - $%s."
          ),
          format(e$code_lines, big.mark = ","), lang_info,
          e$params$complexity, e$params$team_experience,
          format(round(e$realistic_cost_usd), big.mark = ","),
          e$final_schedule_months,
          e$final_people,
          e$effort_person_months,
          format(round(e$confidence_interval$low), big.mark = ","),
          format(round(e$confidence_interval$high), big.mark = ",")
        )

        if (!is.null(e$maintenance) && !is.null(e$maintenance$tco)) {
          ctx <- paste0(ctx, sprintf(
            " Maintenance: %d years at %.0f%%, TCO: $%s.",
            e$params$maintenance_years,
            e$params$maintenance_rate * 100,
            format(round(e$maintenance$tco), big.mark = ",")
          ))
        }

        ctx
      })

      # Chat object, re-created when context changes
      chat_obj <- reactive({
        ctx <- ai_context()
        system_prompt <- paste0(
          "You are an expert assistant for a COCOMO II-based ",
          "software cost estimation tool. ",
          "You help users understand their project estimates ",
          "and suggest ways to optimize costs.\n\n",
          "Key COCOMO II knowledge:\n",
          "- Formula: effort = A * KLOC^B * EM_total ",
          "(A=2.50, B=1.02-1.18)\n",
          "- EM_total is the product of all effort multipliers ",
          "(experience, reuse, tools, reliability, complexity, ",
          "reusability, personnel continuity, application experience)\n",
          "- Realistic constraints cap team size at 8, ",
          "schedule compression adds 20-100% premiums\n",
          "- Teams >= 6 get a 10% coordination premium\n",
          "- Maintenance compounds at 5%/year for turnover\n\n",
          "Current analysis results:\n", ctx, "\n\n",
          "Instructions: Explain estimates in plain English. ",
          "Be concise and practical. ",
          "When asked, suggest specific parameter changes to ",
          "reduce costs. Reference the actual numbers from ",
          "the analysis results above."
        )
        ellmer::chat_openai(
          system_prompt = system_prompt,
          model = "gpt-4.1-nano"
        )
      })

      # Welcome message (fires once when results appear)
      observe({
        req(est())
        greeting <- paste0(
          "Welcome! I'm your cost estimation assistant. ",
          "I can help you understand your COCOMO II estimates, ",
          "explain what the parameters mean, and suggest ways ",
          "to optimize your project costs.\n\n",
          "Try asking:\n",
          "- \"What does my estimate mean?\"\n",
          "- \"How can I reduce the cost?\"\n",
          "- \"Explain the confidence interval\"\n",
          "- \"What if we used a more experienced team?\""
        )
        chat_append("ai_chat", greeting)
      })

      # Handle user messages
      observeEvent(input$ai_chat_user_input, {
        stream <- chat_obj()$stream_async(input$ai_chat_user_input)
        chat_append("ai_chat", stream)
      })
    }

  })
}
