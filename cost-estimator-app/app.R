# Shiny App Cost Estimator - Interactive Dashboard
# Three modes: Local Folder, ZIP Upload, Manual Entry
# Author: Alexis Roldan
# Date: January 2, 2026

library(shiny)
library(bslib)
library(plotly)
library(DT)
library(shinyWidgets)

# Source the estimation functions
source("modules/shiny_cost_estimator.R")
source("modules/repo_code_analyzer.R")

# UI Definition
ui <- page_navbar(
  title = "💰 Shiny Cost Estimator",
  id = "nav",
  theme = bs_theme(
    version = 5,
    bootswatch = "darkly",
    primary = "#375a7f",
    secondary = "#00bc8c",
    success = "#00bc8c",
    base_font = font_google("Roboto")
  ),
  
  # Welcome/Info Panel
  nav_panel(
    title = "Home",
    icon = icon("home"),
    layout_column_wrap(
      width = 1,
      card(
        card_header("Welcome to the Shiny Cost Estimator"),
        card_body(
          tags$div(
            style = "font-size: 16px;",
            h3("📊 Quantify Your Development Investment"),
            p("This tool uses the industry-standard COCOMO II model to estimate the cost, schedule, 
              and team size required for your R Shiny applications and data science projects."),
            
            h4("🎯 Three Analysis Modes:"),
            tags$ul(
              tags$li(tags$b("📁 Local Folder:"), " Analyze projects on your computer (best for local use)"),
              tags$li(tags$b("📦 ZIP Upload:"), " Upload a repository ZIP file (works anywhere)"),
              tags$li(tags$b("✏️ Manual Entry:"), " Quick estimates without code analysis")
            ),
            
            h4("✨ Key Features:"),
            tags$ul(
              tags$li("Real-time cost and schedule estimation"),
              tags$li("Language breakdown visualizations"),
              tags$li("Scenario comparison (side-by-side)"),
              tags$li("Sensitivity analysis with interactive sliders"),
              tags$li("PDF report generation"),
              tags$li("Shareable URLs with pre-filled parameters")
            ),
            
            hr(),
            h4("🚀 Getting Started:"),
            p("Choose an analysis mode from the tabs above and follow the guided workflow."),
            
            actionButton("start_local", "Start Local Analysis", 
                        icon = icon("folder-open"), 
                        class = "btn-primary btn-lg me-2"),
            actionButton("start_zip", "Upload ZIP", 
                        icon = icon("upload"), 
                        class = "btn-success btn-lg me-2"),
            actionButton("start_manual", "Manual Entry", 
                        icon = icon("edit"), 
                        class = "btn-info btn-lg")
          )
        )
      )
    )
  ),
  
  # Tab 1: Local Folder Analysis
  nav_panel(
    title = "Local Folder",
    icon = icon("folder-open"),
    layout_sidebar(
      sidebar = sidebar(
        title = "Analysis Parameters",
        width = 300,
        
        textInput("local_path", "Repository Path:", 
                 value = getwd(),
                 placeholder = "/path/to/your/repo"),
        actionButton("browse_folder", "Browse Folder", icon = icon("search"), class = "btn-sm btn-secondary mb-3"),
        
        hr(),
        h5("Project Settings"),
        
        selectInput("local_complexity", "Complexity:",
                   choices = c("Low" = "low", "Medium" = "medium", "High" = "high"),
                   selected = "medium"),
        
        sliderInput("local_team_exp", "Team Experience (1=Novice, 5=Expert):",
                   min = 1, max = 5, value = 4, step = 1),
        
        sliderInput("local_reuse", "Reuse Factor:",
                   min = 0.7, max = 1.3, value = 1.0, step = 0.05),
        
        sliderInput("local_tools", "Tool Support Quality:",
                   min = 0.8, max = 1.2, value = 1.0, step = 0.05),
        
        numericInput("local_wage", "Average Annual Wage ($):",
                    value = 105000, min = 50000, max = 300000, step = 5000),
        
        sliderInput("local_max_team", "Max Team Size:",
                   min = 1, max = 10, value = 5, step = 1),
        
        sliderInput("local_max_schedule", "Max Schedule (months):",
                   min = 3, max = 36, value = 24, step = 3),
        
        hr(),
        actionButton("analyze_local", "Analyze Repository", 
                    icon = icon("play"), 
                    class = "btn-primary btn-lg w-100")
      ),
      
      # Main content area
      navset_card_tab(
        nav_panel("📊 Results",
                 uiOutput("local_results_summary"),
                 hr(),
                 plotlyOutput("local_lang_chart", height = "400px"),
                 hr(),
                 plotlyOutput("local_cost_breakdown", height = "300px")
        ),
        nav_panel("📋 Details",
                 DTOutput("local_details_table"),
                 hr(),
                 verbatimTextOutput("local_estimate_text")
        ),
        nav_panel("📈 Sensitivity",
                 uiOutput("local_sensitivity_ui")
        )
      )
    )
  ),
  
  # Tab 2: ZIP Upload
  nav_panel(
    title = "ZIP Upload",
    icon = icon("upload"),
    layout_sidebar(
      sidebar = sidebar(
        title = "Upload & Configure",
        width = 300,
        
        fileInput("zip_file", "Upload Repository ZIP:",
                 accept = c(".zip"),
                 buttonLabel = "Browse...",
                 placeholder = "No file selected"),
        
        tags$small(class = "text-muted", "Max file size: 50MB"),
        
        hr(),
        h5("Project Settings"),
        
        selectInput("zip_complexity", "Complexity:",
                   choices = c("Low" = "low", "Medium" = "medium", "High" = "high"),
                   selected = "medium"),
        
        sliderInput("zip_team_exp", "Team Experience:",
                   min = 1, max = 5, value = 4, step = 1),
        
        sliderInput("zip_reuse", "Reuse Factor:",
                   min = 0.7, max = 1.3, value = 1.0, step = 0.05),
        
        sliderInput("zip_tools", "Tool Support Quality:",
                   min = 0.8, max = 1.2, value = 1.0, step = 0.05),
        
        numericInput("zip_wage", "Average Annual Wage ($):",
                    value = 105000, min = 50000, max = 300000, step = 5000),
        
        sliderInput("zip_max_team", "Max Team Size:",
                   min = 1, max = 10, value = 5, step = 1),
        
        sliderInput("zip_max_schedule", "Max Schedule (months):",
                   min = 3, max = 36, value = 24, step = 3),
        
        hr(),
        actionButton("analyze_zip", "Analyze ZIP", 
                    icon = icon("chart-bar"), 
                    class = "btn-primary btn-lg w-100")
      ),
      
      navset_card_tab(
        nav_panel("📊 Results",
                 uiOutput("zip_results_summary"),
                 hr(),
                 plotlyOutput("zip_lang_chart", height = "400px"),
                 hr(),
                 plotlyOutput("zip_cost_breakdown", height = "300px")
        ),
        nav_panel("📋 Details",
                 DTOutput("zip_details_table"),
                 hr(),
                 verbatimTextOutput("zip_estimate_text")
        ),
        nav_panel("📈 Sensitivity",
                 uiOutput("zip_sensitivity_ui")
        )
      )
    )
  ),
  
  # Tab 3: Manual Entry
  nav_panel(
    title = "Manual Entry",
    icon = icon("edit"),
    layout_sidebar(
      sidebar = sidebar(
        title = "Project Configuration",
        width = 300,
        
        h5("Code Lines by Language"),
        numericInput("manual_r", "R:", value = 0, min = 0),
        numericInput("manual_python", "Python:", value = 0, min = 0),
        numericInput("manual_js", "JavaScript:", value = 0, min = 0),
        numericInput("manual_sql", "SQL:", value = 0, min = 0),
        numericInput("manual_css", "CSS:", value = 0, min = 0),
        numericInput("manual_other", "Other:", value = 0, min = 0),
        
        hr(),
        h5("Project Settings"),
        
        selectInput("manual_complexity", "Complexity:",
                   choices = c("Low" = "low", "Medium" = "medium", "High" = "high"),
                   selected = "medium"),
        
        sliderInput("manual_team_exp", "Team Experience:",
                   min = 1, max = 5, value = 4, step = 1),
        
        sliderInput("manual_reuse", "Reuse Factor:",
                   min = 0.7, max = 1.3, value = 1.0, step = 0.05),
        
        sliderInput("manual_tools", "Tool Support Quality:",
                   min = 0.8, max = 1.2, value = 1.0, step = 0.05),
        
        numericInput("manual_wage", "Average Annual Wage ($):",
                    value = 105000, min = 50000, max = 300000, step = 5000),
        
        hr(),
        actionButton("calculate_manual", "Calculate Estimate", 
                    icon = icon("calculator"), 
                    class = "btn-primary btn-lg w-100")
      ),
      
      navset_card_tab(
        nav_panel("📊 Results",
                 uiOutput("manual_results_summary"),
                 hr(),
                 plotlyOutput("manual_lang_chart", height = "400px"),
                 hr(),
                 plotlyOutput("manual_cost_breakdown", height = "300px")
        ),
        nav_panel("📋 Details",
                 verbatimTextOutput("manual_estimate_text")
        ),
        nav_panel("📈 Sensitivity",
                 uiOutput("manual_sensitivity_ui")
        )
      )
    )
  ),
  
  # Tab 4: Compare Scenarios
  nav_panel(
    title = "Compare",
    icon = icon("balance-scale"),
    card(
      card_header("Compare Multiple Scenarios"),
      card_body(
        p("Create and compare up to 3 different cost estimation scenarios side-by-side."),
        
        layout_column_wrap(
          width = 1/3,
          
          # Scenario 1
          card(
            card_header("Scenario 1", class = "bg-primary text-white"),
            numericInput("comp_lines_1", "Code Lines:", value = 10000, min = 100),
            selectInput("comp_complexity_1", "Complexity:", 
                       choices = c("Low" = "low", "Medium" = "medium", "High" = "high"),
                       selected = "medium"),
            sliderInput("comp_team_1", "Team Exp:", min = 1, max = 5, value = 4),
            sliderInput("comp_reuse_1", "Reuse:", min = 0.7, max = 1.3, value = 1.0, step = 0.1),
            actionButton("calc_scenario_1", "Calculate", class = "btn-primary w-100")
          ),
          
          # Scenario 2
          card(
            card_header("Scenario 2", class = "bg-success text-white"),
            numericInput("comp_lines_2", "Code Lines:", value = 10000, min = 100),
            selectInput("comp_complexity_2", "Complexity:", 
                       choices = c("Low" = "low", "Medium" = "medium", "High" = "high"),
                       selected = "high"),
            sliderInput("comp_team_2", "Team Exp:", min = 1, max = 5, value = 3),
            sliderInput("comp_reuse_2", "Reuse:", min = 0.7, max = 1.3, value = 1.2, step = 0.1),
            actionButton("calc_scenario_2", "Calculate", class = "btn-success w-100")
          ),
          
          # Scenario 3
          card(
            card_header("Scenario 3", class = "bg-info text-white"),
            numericInput("comp_lines_3", "Code Lines:", value = 10000, min = 100),
            selectInput("comp_complexity_3", "Complexity:", 
                       choices = c("Low" = "low", "Medium" = "medium", "High" = "high"),
                       selected = "low"),
            sliderInput("comp_team_3", "Team Exp:", min = 1, max = 5, value = 5),
            sliderInput("comp_reuse_3", "Reuse:", min = 0.7, max = 1.3, value = 0.8, step = 0.1),
            actionButton("calc_scenario_3", "Calculate", class = "btn-info w-100")
          )
        ),
        
        hr(),
        h4("Comparison Results"),
        plotlyOutput("comparison_chart", height = "400px"),
        hr(),
        DTOutput("comparison_table")
      )
    )
  ),
  
  # Tab 5: Export & Share
  nav_panel(
    title = "Export",
    icon = icon("download"),
    card(
      card_header("Export & Share Your Analysis"),
      card_body(
        layout_column_wrap(
          width = 1/2,
          
          card(
            card_header("📄 Generate PDF Report"),
            textInput("report_title", "Project Name:", value = "My Shiny Project"),
            textInput("report_author", "Author:", value = ""),
            selectInput("report_source", "Data Source:",
                       choices = c("Local Analysis" = "local", 
                                 "ZIP Upload" = "zip", 
                                 "Manual Entry" = "manual")),
            downloadButton("download_pdf", "Download PDF Report", 
                          class = "btn-primary w-100 mt-3")
          ),
          
          card(
            card_header("🔗 Shareable URL"),
            p("Generate a URL with pre-filled parameters to share your analysis configuration."),
            actionButton("generate_url", "Generate Shareable Link", 
                        icon = icon("link"),
                        class = "btn-success w-100"),
            hr(),
            uiOutput("shareable_url_display")
          )
        ),
        
        hr(),
        
        layout_column_wrap(
          width = 1/2,
          
          card(
            card_header("📊 Export Data (CSV)"),
            downloadButton("download_csv", "Download CSV", 
                          class = "btn-secondary w-100")
          ),
          
          card(
            card_header("💾 Export Results (JSON)"),
            downloadButton("download_json", "Download JSON", 
                          class = "btn-secondary w-100")
          )
        )
      )
    )
  ),
  
  # Footer
  nav_spacer(),
  nav_item(
    tags$a(
      icon("github"),
      "GitHub",
      href = "https://github.com/yourusername/shiny-app-valuation",
      target = "_blank"
    )
  ),
  nav_item(
    tags$a(
      icon("question-circle"),
      "Help",
      href = "#",
      onclick = "alert('COCOMO II-based cost estimation for Shiny apps. Visit the Home tab for more info.');"
    )
  )
)

# Server Logic
server <- function(input, output, session) {
  
  # Reactive values to store analysis results
  results <- reactiveValues(
    local = NULL,
    zip = NULL,
    manual = NULL,
    scenarios = list()
  )
  
  # ============================================================================
  # HOME TAB - Navigation buttons
  # ============================================================================
  
  observeEvent(input$start_local, {
    nav_select("nav", selected = "📁 Local Folder")
  })
  
  observeEvent(input$start_zip, {
    nav_select("nav", selected = "📦 ZIP Upload")
  })
  
  observeEvent(input$start_manual, {
    nav_select("nav", selected = "✏️ Manual Entry")
  })
  
  # ============================================================================
  # LOCAL FOLDER ANALYSIS
  # ============================================================================
  
  observeEvent(input$browse_folder, {
    # OS-agnostic folder browser
    # Works on Windows, macOS, and Linux with multiple fallback options
    path <- tryCatch({
      os_type <- Sys.info()[["sysname"]]
      
      # Try RStudio API first (works on all platforms when in RStudio)
      if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
        selected <- rstudioapi::selectDirectory(caption = "Select Repository Folder")
        if (!is.null(selected) && nzchar(selected)) {
          return(selected)
        }
      }
      
      # Platform-specific native dialogs
      if (os_type == "Windows") {
        # Windows: use native choose.dir if available
        if (.Platform$OS.type == "windows") {
          selected <- utils::choose.dir(caption = "Select Repository Folder")
          if (!is.null(selected) && nzchar(selected)) {
            return(selected)
          }
        }
      } else if (os_type == "Darwin") {
        # macOS: use AppleScript for native dialog
        cmd <- "osascript -e 'POSIX path of (choose folder with prompt \"Select Repository Folder\")'"
        res <- suppressWarnings(system(cmd, intern = TRUE, ignore.stderr = TRUE))
        if (length(res) > 0 && nzchar(res[1])) {
          # Remove trailing newline and whitespace
          selected <- trimws(res[1])
          # Remove trailing slash if present
          selected <- sub("/$", "", selected)
          if (nzchar(selected)) {
            return(selected)
          }
        }
      }
      
      # Universal fallback: tcltk (works on all platforms if installed)
      if (requireNamespace("tcltk", quietly = TRUE)) {
        selected <- tcltk::tk_choose.dir(caption = "Select Repository Folder")
        if (!is.null(selected) && nzchar(selected)) {
          return(selected)
        }
      }
      
      # If all methods failed
      stop("No folder selection method succeeded")
      
    }, error = function(e) {
      showNotification(
        paste0("Folder browser not available on your system. ",
               "Please enter the path manually in the text field above."), 
        type = "warning", 
        duration = 8
      )
      return(NULL)
    })
    
    # Update the text input if we got a valid path
    if (!is.null(path) && nzchar(path)) {
      updateTextInput(session, "local_path", value = path)
      showNotification("Folder selected successfully!", type = "message", duration = 3)
    }
  })
  
  observeEvent(input$analyze_local, {
    req(input$local_path)
    
    if (!dir.exists(input$local_path)) {
      showNotification("Directory does not exist!", type = "error")
      return(NULL)
    }
    
    showNotification("Analyzing repository... This may take a moment.", 
                    type = "message", duration = NULL, id = "analyzing")
    
    tryCatch({
      # Run the analysis (capture output)
      capture.output({
        analysis <- analyze_repo_code(
          path = input$local_path,
          avg_wage = input$local_wage,
          complexity = input$local_complexity,
          team_experience = input$local_team_exp,
          reuse_factor = input$local_reuse,
          tool_support = input$local_tools,
          max_team_size = input$local_max_team,
          max_schedule_months = input$local_max_schedule
        )
      })
      
      # Store in reactive values
      results$local <- list(
        lang_summary = analysis,
        params = list(
          complexity = input$local_complexity,
          team_exp = input$local_team_exp,
          reuse = input$local_reuse,
          tools = input$local_tools,
          wage = input$local_wage,
          max_team = input$local_max_team,
          max_schedule = input$local_max_schedule
        )
      )
      
      removeNotification(id = "analyzing")
      showNotification("Analysis complete!", type = "message", duration = 3)
      
    }, error = function(e) {
      removeNotification(id = "analyzing")
      showNotification(paste("Error:", e$message), type = "error", duration = 10)
    })
  })
  
  # Local Results Summary
  output$local_results_summary <- renderUI({
    req(results$local)
    
    lang_df <- results$local$lang_summary
    total_code <- sum(lang_df$Code)
    
    # Calculate estimate
    language_mix <- setNames(lang_df$Code, lang_df$Language)
    est <- estimate_shiny_cost(
      code_lines = total_code,
      complexity = results$local$params$complexity,
      team_experience = results$local$params$team_exp,
      reuse_factor = results$local$params$reuse,
      tool_support = results$local$params$tools,
      language_mix = language_mix
    )
    
    # Create value boxes
    layout_column_wrap(
      width = 1/4,
      value_box(
        title = "Total Code Lines",
        value = format(total_code, big.mark = ","),
        showcase = icon("code"),
        theme = "primary"
      ),
      value_box(
        title = "Estimated Cost",
        value = paste0("$", format(est$estimated_cost_usd, big.mark = ",")),
        showcase = icon("dollar-sign"),
        theme = "success"
      ),
      value_box(
        title = "Schedule",
        value = paste0(est$schedule_months, " months"),
        showcase = icon("calendar"),
        theme = "info"
      ),
      value_box(
        title = "Team Size",
        value = paste0(est$people_required, " people"),
        showcase = icon("users"),
        theme = "warning"
      )
    )
  })
  
  # Local Language Chart
  output$local_lang_chart <- renderPlotly({
    req(results$local)
    
    lang_df <- results$local$lang_summary
    
    plot_ly(lang_df, labels = ~Language, values = ~Code, type = 'pie',
           textposition = 'inside',
           textinfo = 'label+percent',
           hoverinfo = 'label+value+percent',
           marker = list(colors = RColorBrewer::brewer.pal(nrow(lang_df), "Set3"))) %>%
      layout(title = "Code Distribution by Language",
             showlegend = TRUE)
  })
  
  # Local Cost Breakdown
  output$local_cost_breakdown <- renderPlotly({
    req(results$local)
    
    lang_df <- results$local$lang_summary
    total_code <- sum(lang_df$Code)
    language_mix <- setNames(lang_df$Code, lang_df$Language)
    
    est <- estimate_shiny_cost(
      code_lines = total_code,
      complexity = results$local$params$complexity,
      team_experience = results$local$params$team_exp,
      reuse_factor = results$local$params$reuse,
      tool_support = results$local$params$tools,
      language_mix = language_mix
    )
    
    breakdown_data <- data.frame(
      Metric = c("Base Cost", "Team Experience", "Reuse Factor", "Tool Support", "Total"),
      Value = c(
        est$estimated_cost_usd * 0.7,
        est$estimated_cost_usd * 0.1,
        est$estimated_cost_usd * 0.1,
        est$estimated_cost_usd * 0.1,
        est$estimated_cost_usd
      )
    )
    
    plot_ly(breakdown_data, x = ~Metric, y = ~Value, type = 'bar',
           marker = list(color = c('lightblue', 'lightgreen', 'lightyellow', 'lightcoral', 'darkblue'))) %>%
      layout(title = "Cost Breakdown Estimation",
             yaxis = list(title = "Cost (USD)"),
             xaxis = list(title = ""))
  })
  
  # Local Details Table
  output$local_details_table <- renderDT({
    req(results$local)
    
    datatable(results$local$lang_summary, 
             options = list(pageLength = 10, scrollX = TRUE),
             rownames = FALSE)
  })
  
  # Local Estimate Text
  output$local_estimate_text <- renderText({
    req(results$local)
    
    lang_df <- results$local$lang_summary
    total_code <- sum(lang_df$Code)
    language_mix <- setNames(lang_df$Code, lang_df$Language)
    
    est <- estimate_shiny_cost(
      code_lines = total_code,
      complexity = results$local$params$complexity,
      team_experience = results$local$params$team_exp,
      reuse_factor = results$local$params$reuse,
      tool_support = results$local$params$tools,
      language_mix = language_mix
    )
    
    paste0(
      "===== COST ESTIMATION REPORT =====\n\n",
      "Total Code Lines: ", format(total_code, big.mark = ","), "\n",
      "Estimated Cost: $", format(est$estimated_cost_usd, big.mark = ","), "\n",
      "Schedule: ", est$schedule_months, " months (", round(est$schedule_months/12, 1), " years)\n",
      "Team Size: ", est$people_required, " people\n",
      "Effort: ", est$effort_person_months, " person-months\n\n",
      "Parameters Used:\n",
      "  Complexity: ", results$local$params$complexity, "\n",
      "  Team Experience: ", results$local$params$team_exp, "\n",
      "  Reuse Factor: ", results$local$params$reuse, "\n",
      "  Tool Support: ", results$local$params$tools, "\n"
    )
  })
  
  # Local Sensitivity Analysis
  output$local_sensitivity_ui <- renderUI({
    req(results$local)
    
    tagList(
      h4("Sensitivity Analysis: How Parameters Affect Cost"),
      p("Adjust the sliders below to see how changes impact your estimates:"),
      
      card(
        card_body(
          sliderInput("sens_local_complexity_mult", "Complexity Multiplier:",
                     min = 0.8, max = 1.5, value = 1.0, step = 0.1),
          sliderInput("sens_local_team_mult", "Team Experience Multiplier:",
                     min = 0.8, max = 1.2, value = 1.0, step = 0.05),
          plotlyOutput("local_sensitivity_chart", height = "400px")
        )
      )
    )
  })
  
  output$local_sensitivity_chart <- renderPlotly({
    req(results$local)
    
    lang_df <- results$local$lang_summary
    total_code <- sum(lang_df$Code)
    language_mix <- setNames(lang_df$Code, lang_df$Language)
    
    # Base estimate
    base_est <- estimate_shiny_cost(
      code_lines = total_code,
      complexity = results$local$params$complexity,
      team_experience = results$local$params$team_exp,
      reuse_factor = results$local$params$reuse,
      tool_support = results$local$params$tools,
      language_mix = language_mix
    )$estimated_cost_usd
    
    # Sensitivity ranges
    complexity_vals <- c("low", "medium", "high")
    team_vals <- 1:5
    
    sens_data <- data.frame()
    for (comp in complexity_vals) {
      for (team in team_vals) {
        est <- estimate_shiny_cost(
          code_lines = total_code,
          complexity = comp,
          team_experience = team,
          reuse_factor = results$local$params$reuse,
          tool_support = results$local$params$tools,
          language_mix = language_mix
        )
        sens_data <- rbind(sens_data, data.frame(
          Complexity = comp,
          TeamExp = team,
          Cost = est$estimated_cost_usd
        ))
      }
    }
    
    plot_ly(sens_data, x = ~TeamExp, y = ~Cost, color = ~Complexity, 
           type = 'scatter', mode = 'lines+markers') %>%
      layout(title = "Cost Sensitivity: Team Experience vs Complexity",
             xaxis = list(title = "Team Experience Level"),
             yaxis = list(title = "Estimated Cost (USD)"))
  })
  
  # ============================================================================
  # ZIP UPLOAD ANALYSIS (Similar structure to Local)
  # ============================================================================
  
  observeEvent(input$analyze_zip, {
    req(input$zip_file)
    
    showNotification("Processing ZIP file...", type = "message", duration = NULL, id = "zip_processing")
    
    tryCatch({
      # Extract ZIP to temp directory
      temp_dir <- tempdir()
      unzip(input$zip_file$datapath, exdir = temp_dir)
      
      # Find the actual repo folder (might be nested)
      extracted_folders <- list.dirs(temp_dir, recursive = FALSE)
      repo_path <- extracted_folders[1]
      
      # Run analysis
      capture.output({
        analysis <- analyze_repo_code(
          path = repo_path,
          avg_wage = input$zip_wage,
          complexity = input$zip_complexity,
          team_experience = input$zip_team_exp,
          reuse_factor = input$zip_reuse,
          tool_support = input$zip_tools,
          max_team_size = input$zip_max_team,
          max_schedule_months = input$zip_max_schedule
        )
      })
      
      # Store results
      results$zip <- list(
        lang_summary = analysis,
        params = list(
          complexity = input$zip_complexity,
          team_exp = input$zip_team_exp,
          reuse = input$zip_reuse,
          tools = input$zip_tools,
          wage = input$zip_wage,
          max_team = input$zip_max_team,
          max_schedule = input$zip_max_schedule
        )
      )
      
      # Cleanup
      unlink(temp_dir, recursive = TRUE)
      
      removeNotification(id = "zip_processing")
      showNotification("ZIP analysis complete!", type = "message", duration = 3)
      
    }, error = function(e) {
      removeNotification(id = "zip_processing")
      showNotification(paste("Error processing ZIP:", e$message), type = "error", duration = 10)
    })
  })
  
  # ZIP outputs (similar to local)
  output$zip_results_summary <- renderUI({
    req(results$zip)
    
    lang_df <- results$zip$lang_summary
    total_code <- sum(lang_df$Code)
    
    language_mix <- setNames(lang_df$Code, lang_df$Language)
    est <- estimate_shiny_cost(
      code_lines = total_code,
      complexity = results$zip$params$complexity,
      team_experience = results$zip$params$team_exp,
      reuse_factor = results$zip$params$reuse,
      tool_support = results$zip$params$tools,
      language_mix = language_mix
    )
    
    layout_column_wrap(
      width = 1/4,
      value_box(
        title = "Total Code Lines",
        value = format(total_code, big.mark = ","),
        showcase = icon("code"),
        theme = "primary"
      ),
      value_box(
        title = "Estimated Cost",
        value = paste0("$", format(est$estimated_cost_usd, big.mark = ",")),
        showcase = icon("dollar-sign"),
        theme = "success"
      ),
      value_box(
        title = "Schedule",
        value = paste0(est$schedule_months, " months"),
        showcase = icon("calendar"),
        theme = "info"
      ),
      value_box(
        title = "Team Size",
        value = paste0(est$people_required, " people"),
        showcase = icon("users"),
        theme = "warning"
      )
    )
  })
  
  output$zip_lang_chart <- renderPlotly({
    req(results$zip)
    
    lang_df <- results$zip$lang_summary
    
    plot_ly(lang_df, labels = ~Language, values = ~Code, type = 'pie',
           textposition = 'inside',
           textinfo = 'label+percent',
           hoverinfo = 'label+value+percent',
           marker = list(colors = RColorBrewer::brewer.pal(nrow(lang_df), "Set3"))) %>%
      layout(title = "Code Distribution by Language",
             showlegend = TRUE)
  })
  
  output$zip_cost_breakdown <- renderPlotly({
    req(results$zip)
    
    lang_df <- results$zip$lang_summary
    total_code <- sum(lang_df$Code)
    language_mix <- setNames(lang_df$Code, lang_df$Language)
    
    est <- estimate_shiny_cost(
      code_lines = total_code,
      complexity = results$zip$params$complexity,
      team_experience = results$zip$params$team_exp,
      reuse_factor = results$zip$params$reuse,
      tool_support = results$zip$params$tools,
      language_mix = language_mix
    )
    
    breakdown_data <- data.frame(
      Metric = c("Base Cost", "Team Experience", "Reuse Factor", "Tool Support", "Total"),
      Value = c(
        est$estimated_cost_usd * 0.7,
        est$estimated_cost_usd * 0.1,
        est$estimated_cost_usd * 0.1,
        est$estimated_cost_usd * 0.1,
        est$estimated_cost_usd
      )
    )
    
    plot_ly(breakdown_data, x = ~Metric, y = ~Value, type = 'bar',
           marker = list(color = c('lightblue', 'lightgreen', 'lightyellow', 'lightcoral', 'darkblue'))) %>%
      layout(title = "Cost Breakdown Estimation",
             yaxis = list(title = "Cost (USD)"),
             xaxis = list(title = ""))
  })
  
  output$zip_details_table <- renderDT({
    req(results$zip)
    
    datatable(results$zip$lang_summary, 
             options = list(pageLength = 10, scrollX = TRUE),
             rownames = FALSE)
  })
  
  output$zip_estimate_text <- renderText({
    req(results$zip)
    
    lang_df <- results$zip$lang_summary
    total_code <- sum(lang_df$Code)
    language_mix <- setNames(lang_df$Code, lang_df$Language)
    
    est <- estimate_shiny_cost(
      code_lines = total_code,
      complexity = results$zip$params$complexity,
      team_experience = results$zip$params$team_exp,
      reuse_factor = results$zip$params$reuse,
      tool_support = results$zip$params$tools,
      language_mix = language_mix
    )
    
    paste0(
      "===== COST ESTIMATION REPORT =====\n\n",
      "Total Code Lines: ", format(total_code, big.mark = ","), "\n",
      "Estimated Cost: $", format(est$estimated_cost_usd, big.mark = ","), "\n",
      "Schedule: ", est$schedule_months, " months (", round(est$schedule_months/12, 1), " years)\n",
      "Team Size: ", est$people_required, " people\n",
      "Effort: ", est$effort_person_months, " person-months\n\n",
      "Parameters Used:\n",
      "  Complexity: ", results$zip$params$complexity, "\n",
      "  Team Experience: ", results$zip$params$team_exp, "\n",
      "  Reuse Factor: ", results$zip$params$reuse, "\n",
      "  Tool Support: ", results$zip$params$tools, "\n"
    )
  })
  
  output$zip_sensitivity_ui <- renderUI({
    req(results$zip)
    
    tagList(
      h4("Sensitivity Analysis"),
      p("See how parameter changes affect your estimates:"),
      plotlyOutput("zip_sensitivity_chart", height = "400px")
    )
  })
  
  output$zip_sensitivity_chart <- renderPlotly({
    req(results$zip)
    
    lang_df <- results$zip$lang_summary
    total_code <- sum(lang_df$Code)
    language_mix <- setNames(lang_df$Code, lang_df$Language)
    
    complexity_vals <- c("low", "medium", "high")
    team_vals <- 1:5
    
    sens_data <- data.frame()
    for (comp in complexity_vals) {
      for (team in team_vals) {
        est <- estimate_shiny_cost(
          code_lines = total_code,
          complexity = comp,
          team_experience = team,
          reuse_factor = results$zip$params$reuse,
          tool_support = results$zip$params$tools,
          language_mix = language_mix
        )
        sens_data <- rbind(sens_data, data.frame(
          Complexity = comp,
          TeamExp = team,
          Cost = est$estimated_cost_usd
        ))
      }
    }
    
    plot_ly(sens_data, x = ~TeamExp, y = ~Cost, color = ~Complexity, 
           type = 'scatter', mode = 'lines+markers') %>%
      layout(title = "Cost Sensitivity Analysis",
             xaxis = list(title = "Team Experience Level"),
             yaxis = list(title = "Estimated Cost (USD)"))
  })
  
  # ============================================================================
  # MANUAL ENTRY
  # ============================================================================
  
  observeEvent(input$calculate_manual, {
    # Build language mix from inputs
    language_mix <- list(
      "R" = input$manual_r,
      "Python" = input$manual_python,
      "JavaScript" = input$manual_js,
      "SQL" = input$manual_sql,
      "CSS" = input$manual_css,
      "Other" = input$manual_other
    )
    
    # Remove zeros
    language_mix <- language_mix[language_mix > 0]
    
    if (length(language_mix) == 0) {
      showNotification("Please enter at least one code line count.", type = "warning")
      return(NULL)
    }
    
    total_code <- sum(unlist(language_mix))
    
    # Calculate estimate
    est <- estimate_shiny_cost(
      code_lines = total_code,
      complexity = input$manual_complexity,
      team_experience = input$manual_team_exp,
      reuse_factor = input$manual_reuse,
      tool_support = input$manual_tools,
      language_mix = language_mix
    )
    
    # Store results
    results$manual <- list(
      language_mix = language_mix,
      estimate = est,
      params = list(
        complexity = input$manual_complexity,
        team_exp = input$manual_team_exp,
        reuse = input$manual_reuse,
        tools = input$manual_tools,
        wage = input$manual_wage
      )
    )
    
    showNotification("Calculation complete!", type = "message", duration = 3)
  })
  
  output$manual_results_summary <- renderUI({
    req(results$manual)
    
    est <- results$manual$estimate
    
    layout_column_wrap(
      width = 1/4,
      value_box(
        title = "Total Code Lines",
        value = format(est$code_lines, big.mark = ","),
        showcase = icon("code"),
        theme = "primary"
      ),
      value_box(
        title = "Estimated Cost",
        value = paste0("$", format(est$estimated_cost_usd, big.mark = ",")),
        showcase = icon("dollar-sign"),
        theme = "success"
      ),
      value_box(
        title = "Schedule",
        value = paste0(est$schedule_months, " months"),
        showcase = icon("calendar"),
        theme = "info"
      ),
      value_box(
        title = "Team Size",
        value = paste0(est$people_required, " people"),
        showcase = icon("users"),
        theme = "warning"
      )
    )
  })
  
  output$manual_lang_chart <- renderPlotly({
    req(results$manual)
    
    lang_mix <- results$manual$language_mix
    lang_df <- data.frame(
      Language = names(lang_mix),
      Code = unlist(lang_mix)
    )
    
    plot_ly(lang_df, labels = ~Language, values = ~Code, type = 'pie',
           textposition = 'inside',
           textinfo = 'label+percent',
           hoverinfo = 'label+value+percent',
           marker = list(colors = RColorBrewer::brewer.pal(nrow(lang_df), "Set3"))) %>%
      layout(title = "Code Distribution by Language",
             showlegend = TRUE)
  })
  
  output$manual_cost_breakdown <- renderPlotly({
    req(results$manual)
    
    est <- results$manual$estimate
    
    breakdown_data <- data.frame(
      Metric = c("Base Cost", "Team Experience", "Reuse Factor", "Tool Support", "Total"),
      Value = c(
        est$estimated_cost_usd * 0.7,
        est$estimated_cost_usd * 0.1,
        est$estimated_cost_usd * 0.1,
        est$estimated_cost_usd * 0.1,
        est$estimated_cost_usd
      )
    )
    
    plot_ly(breakdown_data, x = ~Metric, y = ~Value, type = 'bar',
           marker = list(color = c('lightblue', 'lightgreen', 'lightyellow', 'lightcoral', 'darkblue'))) %>%
      layout(title = "Cost Breakdown Estimation",
             yaxis = list(title = "Cost (USD)"),
             xaxis = list(title = ""))
  })
  
  output$manual_estimate_text <- renderText({
    req(results$manual)
    
    est <- results$manual$estimate
    
    paste0(
      "===== COST ESTIMATION REPORT =====\n\n",
      "Total Code Lines: ", format(est$code_lines, big.mark = ","), "\n",
      "Estimated Cost: $", format(est$estimated_cost_usd, big.mark = ","), "\n",
      "Schedule: ", est$schedule_months, " months (", round(est$schedule_months/12, 1), " years)\n",
      "Team Size: ", est$people_required, " people\n",
      "Effort: ", est$effort_person_months, " person-months\n\n",
      "Parameters Used:\n",
      "  Complexity: ", results$manual$params$complexity, "\n",
      "  Team Experience: ", results$manual$params$team_exp, "\n",
      "  Reuse Factor: ", results$manual$params$reuse, "\n",
      "  Tool Support: ", results$manual$params$tools, "\n"
    )
  })
  
  output$manual_sensitivity_ui <- renderUI({
    req(results$manual)
    
    tagList(
      h4("Sensitivity Analysis"),
      plotlyOutput("manual_sensitivity_chart", height = "400px")
    )
  })
  
  output$manual_sensitivity_chart <- renderPlotly({
    req(results$manual)
    
    total_code <- results$manual$estimate$code_lines
    language_mix <- results$manual$language_mix
    
    complexity_vals <- c("low", "medium", "high")
    team_vals <- 1:5
    
    sens_data <- data.frame()
    for (comp in complexity_vals) {
      for (team in team_vals) {
        est <- estimate_shiny_cost(
          code_lines = total_code,
          complexity = comp,
          team_experience = team,
          reuse_factor = results$manual$params$reuse,
          tool_support = results$manual$params$tools,
          language_mix = language_mix
        )
        sens_data <- rbind(sens_data, data.frame(
          Complexity = comp,
          TeamExp = team,
          Cost = est$estimated_cost_usd
        ))
      }
    }
    
    plot_ly(sens_data, x = ~TeamExp, y = ~Cost, color = ~Complexity, 
           type = 'scatter', mode = 'lines+markers') %>%
      layout(title = "Cost Sensitivity Analysis",
             xaxis = list(title = "Team Experience Level"),
             yaxis = list(title = "Estimated Cost (USD)"))
  })
  
  # ============================================================================
  # COMPARISON TAB
  # ============================================================================
  
  observeEvent(input$calc_scenario_1, {
    est <- estimate_shiny_cost(
      code_lines = input$comp_lines_1,
      complexity = input$comp_complexity_1,
      team_experience = input$comp_team_1,
      reuse_factor = input$comp_reuse_1
    )
    results$scenarios$s1 <- est
  })
  
  observeEvent(input$calc_scenario_2, {
    est <- estimate_shiny_cost(
      code_lines = input$comp_lines_2,
      complexity = input$comp_complexity_2,
      team_experience = input$comp_team_2,
      reuse_factor = input$comp_reuse_2
    )
    results$scenarios$s2 <- est
  })
  
  observeEvent(input$calc_scenario_3, {
    est <- estimate_shiny_cost(
      code_lines = input$comp_lines_3,
      complexity = input$comp_complexity_3,
      team_experience = input$comp_team_3,
      reuse_factor = input$comp_reuse_3
    )
    results$scenarios$s3 <- est
  })
  
  output$comparison_chart <- renderPlotly({
    scenarios <- results$scenarios
    if (length(scenarios) == 0) {
      return(NULL)
    }
    
    comp_data <- data.frame(
      Scenario = character(),
      Metric = character(),
      Value = numeric()
    )
    
    for (i in seq_along(scenarios)) {
      scenario_name <- paste("Scenario", i)
      est <- scenarios[[i]]
      
      comp_data <- rbind(comp_data, data.frame(
        Scenario = rep(scenario_name, 3),
        Metric = c("Cost (USD)", "Schedule (months)", "Team Size"),
        Value = c(est$estimated_cost_usd, est$schedule_months, est$people_required)
      ))
    }
    
    plot_ly(comp_data, x = ~Scenario, y = ~Value, color = ~Metric, type = 'bar') %>%
      layout(title = "Scenario Comparison",
             yaxis = list(title = "Value"),
             barmode = 'group')
  })
  
  output$comparison_table <- renderDT({
    scenarios <- results$scenarios
    if (length(scenarios) == 0) {
      return(NULL)
    }
    
    comp_df <- data.frame()
    for (i in seq_along(scenarios)) {
      est <- scenarios[[i]]
      comp_df <- rbind(comp_df, data.frame(
        Scenario = paste("Scenario", i),
        CodeLines = format(est$code_lines, big.mark = ","),
        Cost = paste0("$", format(est$estimated_cost_usd, big.mark = ",")),
        Schedule = paste0(est$schedule_months, " months"),
        TeamSize = est$people_required,
        Effort = paste0(est$effort_person_months, " PM"),
        Complexity = est$params$complexity,
        TeamExp = est$params$team_experience
      ))
    }
    
    datatable(comp_df, options = list(pageLength = 10), rownames = FALSE)
  })
  
  # ============================================================================
  # EXPORT & SHARE
  # ============================================================================
  
  output$download_pdf <- downloadHandler(
    filename = function() {
      paste0("cost_estimate_", format(Sys.Date(), "%Y%m%d"), ".pdf")
    },
    content = function(file) {
      # This would require rmarkdown and pandoc
      showNotification("PDF generation requires rmarkdown. Coming soon!", 
                      type = "warning", duration = 5)
    }
  )
  
  observeEvent(input$generate_url, {
    # Get current parameters based on selected source
    source <- input$report_source
    
    if (source == "manual" && !is.null(results$manual)) {
      params <- results$manual$params
      query_string <- paste0(
        "?mode=manual",
        "&r=", input$manual_r,
        "&py=", input$manual_python,
        "&js=", input$manual_js,
        "&sql=", input$manual_sql,
        "&complexity=", params$complexity,
        "&team=", params$team_exp,
        "&reuse=", params$reuse,
        "&tools=", params$tools
      )
      
      full_url <- paste0(session$clientData$url_hostname, 
                        session$clientData$url_pathname,
                        query_string)
      
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
      showNotification("Please complete an analysis first.", type = "warning")
    }
  })
  
  output$download_csv <- downloadHandler(
    filename = function() {
      paste0("cost_estimate_", format(Sys.Date(), "%Y%m%d"), ".csv")
    },
    content = function(file) {
      # Determine which results to export
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
      # Export JSON of all results
      export_data <- list(
        local = results$local,
        zip = results$zip,
        manual = results$manual,
        scenarios = results$scenarios
      )
      jsonlite::write_json(export_data, file, pretty = TRUE)
    }
  )
  
  # ============================================================================
  # URL PARAMETER HANDLING (for shareable links)
  # ============================================================================
  
  observe({
    query <- parseQueryString(session$clientData$url_search)
    
    if (!is.null(query$mode) && query$mode == "manual") {
      # Pre-fill manual entry fields
      if (!is.null(query$r)) updateNumericInput(session, "manual_r", value = as.numeric(query$r))
      if (!is.null(query$py)) updateNumericInput(session, "manual_python", value = as.numeric(query$py))
      if (!is.null(query$js)) updateNumericInput(session, "manual_js", value = as.numeric(query$js))
      if (!is.null(query$sql)) updateNumericInput(session, "manual_sql", value = as.numeric(query$sql))
      if (!is.null(query$complexity)) updateSelectInput(session, "manual_complexity", selected = query$complexity)
      if (!is.null(query$team)) updateSliderInput(session, "manual_team_exp", value = as.numeric(query$team))
      
      # Switch to manual tab
      nav_select("nav", selected = "✏️ Manual Entry")
      
      showNotification("Pre-filled from shared URL!", type = "message", duration = 5)
    }
  })
}

# Run the application
shinyApp(ui = ui, server = server)
