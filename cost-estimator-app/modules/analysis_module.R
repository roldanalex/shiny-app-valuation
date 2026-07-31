# Shared Analysis Results Module
# Renders the hero estimate, KPI cards, charts, tables, sensitivity, and
# maintenance panels. All colors come from modules/theme.R (app_colors).

analysisResultsUI <- function(id) {
  ns <- NS(id)
  tagList(
    navset_card_tab(
      # ── Results sub-tab ──────────────────────────────────────────────────
      nav_panel("Results",
        uiOutput(ns("results_summary")),
        layout_column_wrap(
          width = 1/2,
          card(
            class = "result-card",
            full_screen = TRUE,
            card_header("Code Distribution by Language"),
            card_body(plotlyOutput(ns("lang_chart"), height = "420px"))
          ),
          card(
            class = "result-card",
            full_screen = TRUE,
            card_header("Cost Breakdown: COCOMO II Multipliers"),
            card_body(plotlyOutput(ns("cost_breakdown"), height = "420px"))
          )
        ),
        layout_column_wrap(
          width = 1/2,
          card(
            class = "result-card",
            full_screen = TRUE,
            card_header("What's Driving Your Cost?"),
            card_body(plotlyOutput(ns("driver_impact"), height = "420px"))
          ),
          card(
            class = "result-card",
            full_screen = TRUE,
            card_header("Schedule vs. Cost Tradeoff"),
            card_body(plotlyOutput(ns("schedule_tradeoff"), height = "420px"))
          )
        )
      ),

      # ── Details sub-tab ──────────────────────────────────────────────────
      nav_panel("Details",
        DTOutput(ns("details_table")),
        tags$h5("Estimate Report", class = "mt-4 pb-2 border-bottom"),
        verbatimTextOutput(ns("estimate_text"))
      ),

      # ── Sensitivity sub-tab ──────────────────────────────────────────────
      nav_panel("Sensitivity",
        uiOutput(ns("sensitivity_ui"))
      ),

      # ── Maintenance & TCO sub-tab ────────────────────────────────────────
      nav_panel("Maintenance & TCO",
        uiOutput(ns("maintenance_ui"))
      )
    ),

    # ── Persistent summary strip (appears once estimate exists) ──────────────
    uiOutput(ns("summary_strip"))
  )
}

# Split analysis data into billable / non-billable views.
# Manual-entry mixes are fully billable; repo scans carry a Billable column.
split_billable <- function(data) {
  if (!is.null(data$lang_summary)) {
    df <- data$lang_summary
    if (is.null(df$Billable)) df$Billable <- TRUE
    billable <- df[df$Billable, , drop = FALSE]
    list(
      lang_df      = df,
      total_code   = sum(df$Code),
      billable_code = sum(billable$Code),
      language_mix = as.list(setNames(billable$Code, billable$Language)),
      has_docs     = any(!df$Billable & df$Code > 0)
    )
  } else {
    mix <- data$language_mix
    list(
      lang_df      = data.frame(Language = names(mix),
                                Code = unlist(mix),
                                Billable = TRUE),
      total_code   = sum(unlist(mix)),
      billable_code = sum(unlist(mix)),
      language_mix = mix,
      has_docs     = FALSE
    )
  }
}

# Call the engine with the current sidebar params over a given language mix
run_estimate <- function(bd, p, overrides = list()) {
  args <- list(
    code_lines          = bd$billable_code,
    complexity          = p$complexity,
    team_experience     = p$team_exp,
    reuse_factor        = p$reuse,
    tool_support        = p$tools,
    language_mix        = bd$language_mix,
    avg_wage            = if (!is.null(p$wage))          p$wage          else 105000,
    max_team_size       = if (!is.null(p$max_team))      p$max_team      else 5,
    max_schedule_months = if (!is.null(p$max_schedule))  p$max_schedule  else 24,
    rely                = if (!is.null(p$rely))          p$rely          else 1.0,
    cplx                = if (!is.null(p$cplx))          p$cplx          else 1.0,
    ruse                = if (!is.null(p$ruse))          p$ruse          else 1.0,
    pcon                = if (!is.null(p$pcon))          p$pcon          else 1.0,
    apex                = if (!is.null(p$apex))          p$apex          else 1.0,
    maintenance_rate    = if (!is.null(p$maintenance_rate))  p$maintenance_rate  else 0.20,
    maintenance_years   = if (!is.null(p$maintenance_years)) p$maintenance_years else 0
  )
  args[names(overrides)] <- overrides
  do.call(estimate_shiny_cost, args)
}

analysisResultsServer <- function(id, analysis_data, params) {
  moduleServer(id, function(input, output, session) {

    billable_data <- reactive({
      req(analysis_data())
      split_billable(analysis_data())
    })

    # Compute estimate reactively
    est <- reactive({
      run_estimate(billable_data(), params())
    })

    # ==========================================================================
    # RESULTS SUMMARY — hero cost card + 2×2 KPI grid
    # ==========================================================================
    output$results_summary <- renderUI({
      e  <- est()
      bd <- billable_data()
      range_low  <- paste0("$", format(e$estimate_range$low,  big.mark = ","))
      range_high <- paste0("$", format(e$estimate_range$high, big.mark = ","))

      compressed <- e$compression_penalty > 1.0
      infeasible <- !e$schedule_feasible

      sched_note <- if (infeasible) {
        sprintf("Needs %s people — above your %d-person cap",
                format(e$final_people, big.mark = ","),
                as.integer(min(e$params$max_team_size, 8)))
      } else if (compressed) {
        sprintf("Compressed from %.1f months (+%d%% cost)",
                e$natural_schedule_months,
                round((e$compression_penalty - 1) * 100))
      } else NULL

      tagList(
        layout_columns(
          col_widths = c(5, 7),
          heights_equal = "row",

          # ── Hero cost card ──
          div(
            class = "hero-card",
            div(class = "hero-label", "Estimated Development Cost"),
            div(class = "hero-value", paste0("$", format(e$cost_usd, big.mark = ","))),
            div(
              class = "range-track-container",
              div(
                class = "range-track",
                div(class = "range-fill"),
                div(class = "range-tick tick-low"),
                div(class = "range-tick tick-mid"),
                div(class = "range-tick tick-high")
              ),
              div(
                class = "range-labels",
                tags$span(range_low),
                tags$span(class = "range-mid-label", "Estimate range (±30%)"),
                tags$span(range_high)
              )
            )
          ),

          # ── 2×2 KPI grid ──
          layout_column_wrap(
            width = 1/2,
            height = "100%",
            div(class = "kpi-card",
              div(class = "kpi-label",
                  if (bd$has_docs) "Billable Code Lines" else "Total Code Lines"),
              div(class = "kpi-value", format(bd$billable_code, big.mark = ",")),
              if (bd$has_docs)
                div(class = "kpi-note",
                    paste0(format(bd$total_code - bd$billable_code, big.mark = ","),
                           " doc/config lines excluded"))
            ),
            div(class = paste("kpi-card", if (compressed || infeasible) "kpi-warning"),
              div(class = "kpi-label", "Schedule"),
              div(class = "kpi-value", paste0(e$final_schedule_months, " months")),
              if (!is.null(sched_note)) div(class = "kpi-note", sched_note)
            ),
            div(class = "kpi-card",
              div(class = "kpi-label", "Team Size"),
              div(class = "kpi-value", paste0(e$final_people, " people"))
            ),
            if (!is.null(e$maintenance)) {
              div(class = "kpi-card",
                div(class = "kpi-label", "Total Cost (TCO)"),
                div(class = "kpi-value",
                    paste0("$", format(e$maintenance$tco, big.mark = ","))),
                div(class = "kpi-note",
                    sprintf("Maintenance discounted at %.0f%%/yr",
                            e$maintenance$discount_rate * 100))
              )
            } else {
              div(class = "kpi-card",
                div(class = "kpi-label", "Effort"),
                div(class = "kpi-value", paste0(e$effort_person_months, " PM")),
                div(class = "kpi-note", "person-months")
              )
            }
          )
        )
      )
    })

    # ==========================================================================
    # LANGUAGE TREEMAP
    # ==========================================================================
    output$lang_chart <- renderPlotly({
      bd      <- billable_data()
      lang_df <- bd$lang_df[bd$lang_df$Code > 0, , drop = FALSE]
      lang_df <- lang_df[order(-lang_df$Billable, -lang_df$Code), , drop = FALSE]

      n_billable <- sum(lang_df$Billable)
      colors <- character(nrow(lang_df))
      colors[lang_df$Billable]  <- rev(app_seq_palette(n_billable))
      colors[!lang_df$Billable] <- app_colors$border

      labels <- ifelse(lang_df$Billable, lang_df$Language,
                       paste0(lang_df$Language, " (not billed)"))

      plot_ly(
        type      = "treemap",
        labels    = labels,
        parents   = rep("", nrow(lang_df)),
        values    = lang_df$Code,
        textinfo  = "label+percent root",
        marker    = list(colors = colors, line = list(color = "#FFFFFF", width = 2)),
        hovertemplate = paste0(
          "<b>%{label}</b><br>",
          "Lines: %{value:,}<br>",
          "Share: %{percentRoot:.1%}<extra></extra>"
        )
      ) %>%
        layout(
          paper_bgcolor = app_plotly_layout$paper_bgcolor,
          plot_bgcolor  = app_plotly_layout$plot_bgcolor,
          font          = app_plotly_layout$font,
          margin        = list(t = 10, b = 10, l = 10, r = 10)
        )
    })

    # ==========================================================================
    # WATERFALL COST BREAKDOWN — ties to the hero number to the dollar
    # ==========================================================================
    output$cost_breakdown <- renderPlotly({
      e  <- est()
      mb <- e$multiplier_breakdown
      monthly_rate <- e$params$avg_wage / 12
      base_cost <- mb$base_effort * monthly_rate

      multipliers <- list(
        list(name = "Experience",       val = mb$EM_experience),
        list(name = "Reuse",            val = mb$EM_reuse),
        list(name = "Tools",            val = mb$EM_tools),
        list(name = "Modern Framework", val = mb$EM_modern)
      )
      if (mb$EM_rely != 1.0) multipliers <- c(multipliers, list(list(name = "Reliability",   val = mb$EM_rely)))
      if (mb$EM_cplx != 1.0) multipliers <- c(multipliers, list(list(name = "Complexity",    val = mb$EM_cplx)))
      if (mb$EM_ruse != 1.0) multipliers <- c(multipliers, list(list(name = "Reusability",   val = mb$EM_ruse)))
      if (mb$EM_pcon != 1.0) multipliers <- c(multipliers, list(list(name = "Personnel",     val = mb$EM_pcon)))
      if (mb$EM_apex != 1.0) multipliers <- c(multipliers, list(list(name = "App Experience",val = mb$EM_apex)))

      names_vec    <- c("Base Effort")
      values_vec   <- c(base_cost)
      measures_vec <- c("absolute")

      running <- base_cost
      for (m in multipliers) {
        delta <- running * (m$val - 1)
        names_vec    <- c(names_vec,    m$name)
        values_vec   <- c(values_vec,   delta)
        measures_vec <- c(measures_vec, "relative")
        running <- running + delta
      }

      # running is now effort0 * rate; add the constraint premiums explicitly
      if (e$compression_penalty > 1.0) {
        delta <- running * (e$compression_penalty - 1)
        names_vec    <- c(names_vec,    "Schedule Compression")
        values_vec   <- c(values_vec,   delta)
        measures_vec <- c(measures_vec, "relative")
        running <- running + delta
      }
      if (e$coordination_premium > 1.0) {
        delta <- running * (e$coordination_premium - 1)
        names_vec    <- c(names_vec,    "Coordination Overhead")
        values_vec   <- c(values_vec,   delta)
        measures_vec <- c(measures_vec, "relative")
        running <- running + delta
      }

      names_vec    <- c(names_vec,    "Final Cost")
      values_vec   <- c(values_vec,   e$cost_usd)
      measures_vec <- c(measures_vec, "total")

      plot_ly(
        type      = "waterfall",
        x         = names_vec,
        y         = values_vec,
        measure   = measures_vec,
        connector = list(line = list(color = app_colors$grid)),
        decreasing = list(marker = list(color = app_colors$positive)),
        increasing = list(marker = list(color = app_colors$negative)),
        totals     = list(marker = list(color = app_colors$primary))
      ) %>%
        layout(
          xaxis = c(app_plotly_layout$xaxis,
                    list(title = "", categoryorder = "array",
                         categoryarray = names_vec)),
          yaxis = c(app_plotly_layout$yaxis, list(title = "Cost (USD)")),
          showlegend    = FALSE,
          paper_bgcolor = app_plotly_layout$paper_bgcolor,
          plot_bgcolor  = app_plotly_layout$plot_bgcolor,
          font          = app_plotly_layout$font
        )
    })

    # ==========================================================================
    # DRIVER IMPACT HORIZONTAL BAR
    # ==========================================================================
    output$driver_impact <- renderPlotly({
      e  <- est()
      mb <- e$multiplier_breakdown
      monthly_rate <- e$params$avg_wage / 12
      base_total <- mb$base_effort * monthly_rate  # dollars, before multipliers

      driver_list <- list(
        list(name = "Experience",           val = mb$EM_experience),
        list(name = "Reuse Factor",         val = mb$EM_reuse),
        list(name = "Tool Support",         val = mb$EM_tools),
        list(name = "Modern Framework",     val = mb$EM_modern),
        list(name = "Reliability",          val = mb$EM_rely),
        list(name = "Product Complexity",   val = mb$EM_cplx),
        list(name = "Reusability",          val = mb$EM_ruse),
        list(name = "Personnel Continuity", val = mb$EM_pcon),
        list(name = "App Experience",       val = mb$EM_apex)
      )

      # Cost each driver adds relative to it being nominal (1.0), holding the
      # others at their current values: delta_i = base * (EM_total - EM_total/EM_i)
      names_d <- sapply(driver_list, `[[`, "name")
      deltas  <- sapply(driver_list, function(d) {
        base_total * (mb$EM_total - mb$EM_total / d$val)
      })

      ord     <- order(abs(deltas), decreasing = TRUE)
      names_d <- names_d[ord]
      deltas  <- deltas[ord]

      bar_colors <- ifelse(deltas > 0, app_colors$negative, app_colors$positive)

      plot_ly(
        x           = deltas,
        y           = names_d,
        type        = "bar",
        orientation = "h",
        marker      = list(color = bar_colors),
        hovertemplate = paste0(
          "<b>%{y}</b><br>",
          "Cost delta: $%{x:,.0f}<extra></extra>"
        )
      ) %>%
        layout(
          xaxis = c(app_plotly_layout$xaxis, list(title = "Cost Delta (USD)")),
          yaxis = c(app_plotly_layout$yaxis[setdiff(names(app_plotly_layout$yaxis), "gridcolor")],
                    list(title = "", autorange = "reversed")),
          showlegend    = FALSE,
          paper_bgcolor = app_plotly_layout$paper_bgcolor,
          plot_bgcolor  = app_plotly_layout$plot_bgcolor,
          font          = app_plotly_layout$font,
          margin        = list(l = 150, r = 20, t = 20, b = 50)
        )
    })

    # ==========================================================================
    # SCHEDULE / COST TRADEOFF CURVE
    # ==========================================================================
    tradeoff_curve <- reactive({
      bd <- billable_data()
      p  <- params()
      schedules <- seq(6, 36, by = 2)
      costs <- sapply(schedules, function(s) {
        tryCatch(
          run_estimate(bd, p, overrides = list(
            max_schedule_months = s,
            maintenance_rate = 0, maintenance_years = 0
          ))$cost_usd,
          error = function(err) NA_real_
        )
      })
      data.frame(schedule = schedules, cost = costs)
    })

    output$schedule_tradeoff <- renderPlotly({
      e     <- est()
      curve <- tradeoff_curve()

      plot_ly() %>%
        add_trace(
          x    = curve$schedule,
          y    = curve$cost,
          type = "scatter",
          mode = "lines",
          line = list(color = app_colors$primary, width = 2),
          name = "Cost curve",
          hovertemplate = paste0(
            "Schedule: %{x} months<br>",
            "Cost: $%{y:,.0f}<extra></extra>"
          )
        ) %>%
        add_trace(
          x      = e$final_schedule_months,
          y      = e$cost_usd,
          type   = "scatter",
          mode   = "markers",
          marker = list(color = app_colors$negative, size = 12, symbol = "circle"),
          name   = "Current estimate",
          hovertemplate = paste0(
            "<b>Current estimate</b><br>",
            "Schedule: %{x} months<br>",
            "Cost: $%{y:,.0f}<extra></extra>"
          )
        ) %>%
        layout(
          xaxis = c(app_plotly_layout$xaxis, list(title = "Max Schedule (months)")),
          yaxis = c(app_plotly_layout$yaxis, list(title = "Estimated Cost (USD)")),
          legend        = list(font = list(color = app_colors$ink)),
          paper_bgcolor = app_plotly_layout$paper_bgcolor,
          plot_bgcolor  = app_plotly_layout$plot_bgcolor,
          font          = app_plotly_layout$font,
          margin        = list(t = 20, b = 50, l = 80, r = 20)
        )
    })

    # ==========================================================================
    # DETAILS TABLE
    # ==========================================================================
    output$details_table <- renderDT({
      data <- analysis_data()
      if (!is.null(data$lang_summary)) {
        df <- data$lang_summary
        if (!is.null(df$Billable)) {
          df$Billable <- ifelse(df$Billable, "Yes", "No (docs/config)")
        }
        datatable(df,
                 options = list(pageLength = 10, scrollX = TRUE),
                 rownames = FALSE)
      }
    })

    # Estimate text report
    output$estimate_text <- renderText({
      e  <- est()
      bd <- billable_data()
      report <- paste0(
        "===== COST ESTIMATION REPORT =====\n\n",
        "Billable Code Lines: ", format(bd$billable_code, big.mark = ","), "\n",
        if (bd$has_docs)
          paste0("Excluded Docs/Config Lines: ",
                 format(bd$total_code - bd$billable_code, big.mark = ","), "\n")
        else "",
        "Estimated Cost: $", format(e$cost_usd, big.mark = ","), "\n",
        "Estimate Range (+/-30%): $", format(e$estimate_range$low,  big.mark = ","),
        " - $", format(e$estimate_range$high, big.mark = ","), "\n",
        "Schedule: ", e$final_schedule_months, " months (",
        round(e$final_schedule_months / 12, 1), " years)\n",
        "Team Size: ", e$final_people, " people\n",
        "Effort: ", e$effort_person_months, " person-months\n\n",
        "Parameters Used:\n",
        "  Complexity: ",      e$params$complexity,       "\n",
        "  Team Experience: ", e$params$team_experience,  "\n",
        "  Reuse Factor: ",    e$params$reuse_factor,     "\n",
        "  Tool Support: ",    e$params$tool_support,     "\n",
        "  Average Wage: $",   format(e$params$avg_wage, big.mark = ","), "\n"
      )
      if (e$compression_penalty > 1.0) {
        report <- paste0(report,
          "  Schedule Compression Premium: +",
          round((e$compression_penalty - 1) * 100), "%\n"
        )
      }
      if (!e$schedule_feasible) {
        report <- paste0(report,
          "  WARNING: this schedule needs ", e$final_people,
          " people, above the ", as.integer(min(e$params$max_team_size, 8)),
          "-person cap. Consider a longer schedule.\n"
        )
      }
      if (e$coordination_premium > 1.0) {
        report <- paste0(report,
          "  Coordination Overhead: +",
          round((e$coordination_premium - 1) * 100), "%\n"
        )
      }
      if (!is.null(e$maintenance)) {
        report <- paste0(report,
          "\nMaintenance & TCO:\n",
          "  Annual Maintenance: $", format(e$maintenance$annual_maintenance, big.mark = ","), "\n",
          "  Total Maintenance (", e$maintenance$maintenance_years, "yr, nominal): $",
          format(e$maintenance$total_maintenance_nominal, big.mark = ","), "\n",
          "  Total Maintenance (present value @ ",
          round(e$maintenance$discount_rate * 100), "%/yr): $",
          format(e$maintenance$total_maintenance_pv, big.mark = ","), "\n",
          "  Total Cost of Ownership: $", format(e$maintenance$tco, big.mark = ","), "\n"
        )
      }
      report
    })

    # ==========================================================================
    # SENSITIVITY ANALYSIS
    # ==========================================================================
    output$sensitivity_ui <- renderUI({
      ns <- session$ns
      tagList(
        h4("Sensitivity Analysis: How Parameters Affect Cost"),
        p("Shows how changes in complexity and team experience affect the",
          " estimated cost, holding every other parameter at its current value.",
          " The marker is your current estimate."),
        plotlyOutput(ns("sensitivity_chart"), height = "400px")
      )
    })

    output$sensitivity_chart <- renderPlotly({
      bd <- billable_data()
      p  <- params()
      e  <- est()

      complexity_vals <- c("low", "medium", "high")
      team_vals       <- 1:5
      sens_data       <- data.frame()

      for (comp in complexity_vals) {
        for (team in team_vals) {
          e_s <- run_estimate(bd, p, overrides = list(
            complexity = comp, team_experience = team,
            maintenance_rate = 0, maintenance_years = 0
          ))
          sens_data <- rbind(sens_data, data.frame(
            Complexity = comp,
            TeamExp    = team,
            Cost       = e_s$cost_usd
          ))
        }
      }
      sens_data$Complexity <- factor(sens_data$Complexity,
                                     levels = c("low", "medium", "high"))

      plot_ly(
        sens_data,
        x      = sens_data$TeamExp,
        y      = sens_data$Cost,
        color  = sens_data$Complexity,
        type   = "scatter",
        mode   = "lines+markers",
        colors = c(app_colors$positive, app_colors$primary, app_colors$negative)
      ) %>%
        add_trace(
          x      = p$team_exp,
          y      = e$cost_usd,
          type   = "scatter",
          mode   = "markers",
          marker = list(color = app_colors$ink, size = 13, symbol = "diamond"),
          name   = "Your estimate",
          inherit = FALSE,
          hovertemplate = "<b>Your estimate</b><br>Cost: $%{y:,.0f}<extra></extra>"
        ) %>%
        layout(
          title = list(
            text = "Cost Sensitivity: Team Experience vs Complexity",
            font = list(color = app_colors$ink)
          ),
          xaxis = c(app_plotly_layout$xaxis, list(title = "Team Experience Level")),
          yaxis = c(app_plotly_layout$yaxis, list(title = "Estimated Cost (USD)")),
          paper_bgcolor = app_plotly_layout$paper_bgcolor,
          plot_bgcolor  = app_plotly_layout$plot_bgcolor,
          font          = app_plotly_layout$font,
          legend        = list(font = list(color = app_colors$ink))
        )
    })

    # ==========================================================================
    # MAINTENANCE & TCO PANEL
    # ==========================================================================
    output$maintenance_ui <- renderUI({
      ns <- session$ns
      e  <- est()
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
            div(class = "kpi-card",
              div(class = "kpi-label", "Build Cost"),
              div(class = "kpi-value", paste0("$", format(e$cost_usd, big.mark = ",")))
            ),
            div(class = "kpi-card",
              div(class = "kpi-label", paste0("Maintenance (", m$maintenance_years, "yr)")),
              div(class = "kpi-value",
                  paste0("$", format(m$total_maintenance_pv, big.mark = ","))),
              div(class = "kpi-note",
                  sprintf("Present value @ %.0f%%/yr (nominal: $%s)",
                          m$discount_rate * 100,
                          format(m$total_maintenance_nominal, big.mark = ",")))
            ),
            div(class = "kpi-card",
              div(class = "kpi-label", "Total Cost (TCO)"),
              div(class = "kpi-value", paste0("$", format(m$tco, big.mark = ","))),
              div(class = "kpi-note", "Build + maintenance present value")
            )
          ),
          hr(),
          layout_column_wrap(
            width = 1/2,
            card(
              card_header("Cumulative TCO Over Time (nominal)"),
              card_body(plotlyOutput(ns("maintenance_chart"), height = "320px"))
            ),
            card(
              card_header("TCO at Different Maintenance Rates"),
              card_body(plotlyOutput(ns("maint_rate_chart"), height = "320px"))
            )
          )
        )
      }
    })

    # Cumulative TCO line chart (nominal dollars, intuitive year-by-year view)
    output$maintenance_chart <- renderPlotly({
      e <- est()
      req(e$maintenance)
      m <- e$maintenance

      build_cost   <- e$cost_usd
      yearly_costs <- m$yearly_costs
      n_years      <- m$maintenance_years

      years      <- 0:n_years
      cumulative <- c(0, cumsum(yearly_costs)) + build_cost

      breakeven_idx <- which(cumsum(yearly_costs) >= build_cost)
      breakeven_yr  <- if (length(breakeven_idx) > 0) breakeven_idx[1] else NA

      shapes <- list()
      annotations_list <- list()

      two_x <- 2 * build_cost
      if (max(cumulative) >= two_x) {
        shapes <- c(shapes, list(list(
          type = "line",
          x0 = 0, x1 = n_years,
          y0 = two_x, y1 = two_x,
          line = list(color = app_colors$warning, dash = "dash", width = 1.5)
        )))
        annotations_list <- c(annotations_list, list(list(
          x = n_years * 0.02, y = two_x,
          text = "2× build cost", showarrow = FALSE,
          xanchor = "left", yanchor = "bottom",
          font = list(color = app_colors$warning, size = 11)
        )))
      }

      if (!is.na(breakeven_yr)) {
        shapes <- c(shapes, list(list(
          type = "line",
          x0 = breakeven_yr, x1 = breakeven_yr,
          y0 = build_cost,   y1 = cumulative[breakeven_yr + 1],
          line = list(color = app_colors$negative, dash = "dot", width = 1.5)
        )))
        annotations_list <- c(annotations_list, list(list(
          x = breakeven_yr, y = cumulative[breakeven_yr + 1],
          text = paste0("Maint = Build<br>(Year ", breakeven_yr, ")"),
          showarrow = TRUE, arrowhead = 2, arrowcolor = app_colors$negative,
          font = list(color = app_colors$negative, size = 11),
          xanchor = "left"
        )))
      }

      plot_ly() %>%
        add_trace(
          x    = years,
          y    = cumulative,
          type = "scatter",
          mode = "lines+markers",
          fill = "tozeroy",
          fillcolor = "rgba(28, 93, 153, 0.12)",
          line   = list(color = app_colors$primary, width = 2.5),
          marker = list(color = app_colors$primary, size = 7),
          name   = "Cumulative TCO",
          hovertemplate = "Year %{x}<br>Total: $%{y:,.0f}<extra></extra>"
        ) %>%
        layout(
          xaxis = c(app_plotly_layout$xaxis, list(title = "Year", dtick = 1)),
          yaxis = c(app_plotly_layout$yaxis, list(title = "Cumulative Cost (USD)")),
          shapes      = shapes,
          annotations = annotations_list,
          showlegend    = FALSE,
          paper_bgcolor = app_plotly_layout$paper_bgcolor,
          plot_bgcolor  = app_plotly_layout$plot_bgcolor,
          font          = app_plotly_layout$font,
          margin        = list(t = 20, b = 50, l = 80, r = 20)
        )
    })

    # Maintenance rate sensitivity chart
    output$maint_rate_chart <- renderPlotly({
      e <- est()
      req(e$maintenance)
      bd <- billable_data()
      p  <- params()

      rates <- seq(0.10, 0.30, by = 0.05)
      tcos  <- sapply(rates, function(r) {
        tryCatch({
          est_r <- run_estimate(bd, p, overrides = list(
            maintenance_rate = r,
            maintenance_years = e$maintenance$maintenance_years
          ))
          if (!is.null(est_r$maintenance)) est_r$maintenance$tco else NA_real_
        }, error = function(err) NA_real_)
      })

      cur_rate <- e$params$maintenance_rate

      plot_ly(
        x    = rates * 100,
        y    = tcos,
        type = "bar",
        marker = list(
          color = ifelse(
            abs(rates - cur_rate) < 0.001,
            app_colors$primary, app_colors$seq[3]
          )
        ),
        hovertemplate = paste0(
          "Rate: %{x:.0f}%<br>",
          "TCO: $%{y:,.0f}<extra></extra>"
        )
      ) %>%
        layout(
          xaxis = c(app_plotly_layout$xaxis, list(title = "Annual Maintenance Rate (%)")),
          yaxis = c(app_plotly_layout$yaxis, list(title = "Total Cost of Ownership (USD)")),
          showlegend    = FALSE,
          paper_bgcolor = app_plotly_layout$paper_bgcolor,
          plot_bgcolor  = app_plotly_layout$plot_bgcolor,
          font          = app_plotly_layout$font,
          margin        = list(t = 20, b = 50, l = 80, r = 20)
        )
    })

    # ==========================================================================
    # PERSISTENT SUMMARY STRIP
    # ==========================================================================
    output$summary_strip <- renderUI({
      req(analysis_data())
      e <- est()
      div(
        class = "summary-strip",
        div(class = "strip-item",
          tags$span("Cost: ",     class = "strip-label"),
          tags$span(paste0("$", format(e$cost_usd, big.mark = ",")),
                    class = "strip-value")
        ),
        div(class = "strip-item",
          tags$span("Schedule: ", class = "strip-label"),
          tags$span(paste0(e$final_schedule_months, " months"),
                    class = "strip-value")
        ),
        div(class = "strip-item",
          tags$span("Team: ",     class = "strip-label"),
          tags$span(paste0(e$final_people, " people"),
                    class = "strip-value")
        ),
        div(class = "strip-item",
          tags$span("Range: ",    class = "strip-label"),
          tags$span(paste0(
            "$", format(e$estimate_range$low,  big.mark = ","), " – ",
            "$", format(e$estimate_range$high, big.mark = ",")
          ), class = "strip-value")
        ),
        if (e$compression_penalty > 1.0)
          div(class = "strip-item",
            tags$span(
              class = "strip-warning",
              paste0("⚠ Schedule premium: +",
                     round((e$compression_penalty - 1) * 100), "%")
            )
          ),
        if (!e$schedule_feasible)
          div(class = "strip-item",
            tags$span(
              class = "strip-warning",
              "⚠ Schedule not feasible with team cap"
            )
          ),
        if (pdf_report_available())
          div(class = "strip-item", style = "margin-left: auto;",
            downloadButton(session$ns("download_pdf"), "PDF Report",
                          class = "btn-sm btn-primary", icon = icon("file-pdf"))
          )
      )
    })

    output$download_pdf <- pdf_download_handler(function() {
      data <- analysis_data()
      build_report_payload(
        est          = est(),
        billable     = billable_data(),
        curve        = tradeoff_curve(),
        project_name = if (!is.null(data$source_label)) data$source_label else "Your Project"
      )
    })

    # Return the estimate and supporting data so the export module can
    # build the PDF report from the exact same numbers.
    list(
      est = est,
      billable_data = billable_data,
      tradeoff_curve = tradeoff_curve
    )
  })
}
