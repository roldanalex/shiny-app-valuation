# Shiny App Cost Estimator - Interactive Dashboard
# Modular architecture with COCOMO II estimation engine
# Author: Alexis Roldan

library(shiny)
library(bslib)
library(plotly)
library(DT)
library(shinyWidgets)

# Optional AI assistant packages
ai_available <- tryCatch({
  requireNamespace("ellmer", quietly = TRUE) &&
    requireNamespace("shinychat", quietly = TRUE)
}, error = function(e) FALSE)

if (ai_available) library(shinychat)

# Source estimation functions (prefer R/ originals, fall back to modules/)
if (file.exists("../R/shiny_cost_estimator.R")) {
  source("../R/shiny_cost_estimator.R")
} else {
  source("modules/shiny_cost_estimator.R")
}
if (file.exists("../R/repo_code_analyzer.R")) {
  source("../R/repo_code_analyzer.R")
} else {
  source("modules/repo_code_analyzer.R")
}

# Source UI/server modules
source("modules/analysis_module.R")
source("modules/comparison_module.R")
source("modules/export_module.R")

# Helper: setting label with inline "?" help button
setting_help_btn <- function(label, id) {
  tags$div(
    style = "display: flex; align-items: center; gap: 6px;",
    tags$span(label, style = "font-weight: 600;"),
    actionButton(
      id,
      label = "?",
      class = "btn btn-outline-secondary btn-sm",
      style = paste0(
        "border-radius: 50%; width: 22px; height: 22px;",
        " padding: 0; font-size: 12px; line-height: 20px;"
      )
    )
  )
}

# Reusable sidebar settings block with help buttons
project_settings_sidebar <- function(prefix) {
  tagList(
    hr(),
    h5("Project Settings"),

    setting_help_btn("Complexity:", paste0(prefix, "_help_complexity")),
    selectInput(paste0(prefix, "_complexity"), label = NULL,
               choices = c("Low" = "low", "Medium" = "medium",
                           "High" = "high"),
               selected = "medium"),

    setting_help_btn("Team Experience:", paste0(prefix, "_help_team")),
    sliderInput(paste0(prefix, "_team_exp"), label = NULL,
               min = 1, max = 5, value = 4, step = 1),

    setting_help_btn("Reuse Factor:", paste0(prefix, "_help_reuse")),
    sliderInput(paste0(prefix, "_reuse"), label = NULL,
               min = 0.7, max = 1.3, value = 1.0, step = 0.05),

    setting_help_btn("Tool Support Quality:", paste0(prefix, "_help_tools")),
    sliderInput(paste0(prefix, "_tools"), label = NULL,
               min = 0.8, max = 1.2, value = 1.0, step = 0.05),

    setting_help_btn("Average Annual Wage ($):", paste0(prefix, "_help_wage")),
    numericInput(paste0(prefix, "_wage"), label = NULL,
                value = 105000, min = 50000, max = 300000, step = 5000),

    setting_help_btn("Max Team Size:", paste0(prefix, "_help_maxteam")),
    sliderInput(paste0(prefix, "_max_team"), label = NULL,
               min = 1, max = 10, value = 5, step = 1),

    setting_help_btn("Max Schedule (months):", paste0(prefix, "_help_maxsched")),
    sliderInput(paste0(prefix, "_max_schedule"), label = NULL,
               min = 3, max = 36, value = 24, step = 3)
  )
}

# Shared sidebar for advanced COCOMO drivers + maintenance
advanced_cocomo_sidebar <- function(prefix) {
  tagList(
    hr(),
    tags$details(
      tags$summary(tags$b("Advanced COCOMO Drivers")),
      setting_help_btn("Required Reliability:", paste0(prefix, "_help_rely")),
      sliderInput(paste0(prefix, "_rely"), label = NULL,
                 min = 0.82, max = 1.26, value = 1.0, step = 0.01),
      setting_help_btn("Product Complexity:", paste0(prefix, "_help_cplx")),
      sliderInput(paste0(prefix, "_cplx"), label = NULL,
                 min = 0.73, max = 1.74, value = 1.0, step = 0.01),
      setting_help_btn("Required Reusability:", paste0(prefix, "_help_ruse")),
      sliderInput(paste0(prefix, "_ruse"), label = NULL,
                 min = 0.95, max = 1.24, value = 1.0, step = 0.01),
      setting_help_btn("Personnel Continuity:", paste0(prefix, "_help_pcon")),
      sliderInput(paste0(prefix, "_pcon"), label = NULL,
                 min = 0.81, max = 1.29, value = 1.0, step = 0.01),
      setting_help_btn("Application Experience:", paste0(prefix, "_help_apex")),
      sliderInput(paste0(prefix, "_apex"), label = NULL,
                 min = 0.81, max = 1.22, value = 1.0, step = 0.01)
    ),
    hr(),
    tags$details(
      tags$summary(tags$b("Maintenance & TCO")),
      setting_help_btn("Annual Maintenance Rate:", paste0(prefix, "_help_maint_rate")),
      sliderInput(paste0(prefix, "_maint_rate"), label = NULL,
                 min = 0, max = 0.40, value = 0.20, step = 0.05),
      setting_help_btn("Maintenance Years:", paste0(prefix, "_help_maint_years")),
      sliderInput(paste0(prefix, "_maint_years"), label = NULL,
                 min = 0, max = 10, value = 0, step = 1)
    )
  )
}

# UI Definition
ui <- page_navbar(
  title = "Shiny Cost Estimator",
  id = "nav",
  theme = bs_theme(
    version = 5,
    bootswatch = "darkly",
    primary = "#375a7f",
    secondary = "#00bc8c",
    success = "#00bc8c",
    base_font = font_google("Roboto")
  ),
  footer = tags$footer(
    class = "bg-dark text-light py-2 px-3 mt-auto",
    style = "display: flex; justify-content: space-between; align-items: center; font-size: 0.85rem;",
    tags$span("Shiny Cost Estimator v1.0.1"),
    tags$span("Created by Alexis Roldan - 2026")
  ),

  # Home tab
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
            h3("Quantify Your Development Investment"),
            p("This tool uses the industry-standard COCOMO II model to estimate the cost, schedule,
              and team size required for your R Shiny applications and data science projects."),

            h4("Three Analysis Modes:"),
            tags$ul(
              tags$li(tags$b("Local Folder:"), " Analyze projects on your computer (best for local use)"),
              tags$li(tags$b("ZIP Upload:"), " Upload a repository ZIP file (works anywhere)"),
              tags$li(tags$b("Manual Entry:"), " Quick estimates without code analysis")
            ),

            h4("Key Features:"),
            tags$ul(
              tags$li("Real-time cost and schedule estimation with confidence intervals"),
              tags$li("COCOMO II waterfall cost breakdown"),
              tags$li("Maintenance cost and Total Cost of Ownership (TCO) projections"),
              tags$li("Advanced COCOMO II cost drivers (reliability, complexity, reusability, etc.)"),
              tags$li("Scenario comparison (side-by-side)"),
              tags$li("Sensitivity analysis with interactive charts"),
              tags$li("Shareable URLs with pre-filled parameters")
            ),

            hr(),
            h4("Getting Started:"),
            p("Choose an analysis mode below or from the tabs above."),

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

  # Local Folder tab
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
        actionButton("browse_folder", "Browse Folder", icon = icon("search"),
                    class = "btn-sm btn-secondary mb-3"),

        project_settings_sidebar("local"),
        advanced_cocomo_sidebar("local"),

        hr(),
        actionButton("analyze_local", "Analyze Repository",
                    icon = icon("play"),
                    class = "btn-primary btn-lg w-100")
      ),
      analysisResultsUI("local_results", ai_available = ai_available)
    )
  ),

  # ZIP Upload tab
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

        project_settings_sidebar("zip"),
        advanced_cocomo_sidebar("zip"),

        hr(),
        actionButton("analyze_zip", "Analyze ZIP",
                    icon = icon("chart-bar"),
                    class = "btn-primary btn-lg w-100")
      ),
      analysisResultsUI("zip_results", ai_available = ai_available)
    )
  ),

  # Manual Entry tab
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

        project_settings_sidebar("manual"),
        advanced_cocomo_sidebar("manual"),

        hr(),
        actionButton("calculate_manual", "Calculate Estimate",
                    icon = icon("calculator"),
                    class = "btn-primary btn-lg w-100")
      ),
      analysisResultsUI("manual_results", ai_available = ai_available)
    )
  ),

  # Compare tab
  nav_panel(
    title = "Compare",
    icon = icon("balance-scale"),
    comparisonUI("compare")
  ),

  # Export tab
  nav_panel(
    title = "Export",
    icon = icon("download"),
    exportUI("export")
  ),

  # Navbar buttons
  nav_spacer(),
  nav_item(
    actionButton("btn_user_guide", label = tagList(icon("book"), "User Guide"),
                 class = "btn-light btn-sm")
  ),
  nav_item(
    actionButton("btn_release_notes", label = tagList(icon("clipboard-list"), "Release Notes"),
                 class = "btn-light btn-sm")
  )
)

# Server Logic
server <- function(input, output, session) {

  # Reactive values to store analysis results
  results <- reactiveValues(
    local = NULL,
    zip = NULL,
    manual = NULL
  )

  # ============================================================================
  # HOME TAB - Navigation buttons (fixed: plain text tab names)
  # ============================================================================

  observeEvent(input$start_local, {
    nav_select("nav", selected = "Local Folder")
  })

  observeEvent(input$start_zip, {
    nav_select("nav", selected = "ZIP Upload")
  })

  observeEvent(input$start_manual, {
    nav_select("nav", selected = "Manual Entry")
  })

  # ============================================================================
  # NAVBAR BUTTONS - User Guide and Release Notes modals
  # ============================================================================

  observeEvent(input$btn_user_guide, {
    showModal(modalDialog(
      tags$div(
        style = "background: #fff; color: #212529; padding: 20px; border-radius: 6px;",
        includeMarkdown("markdown/user_guide.md")
      ),
      title = "User Guide",
      size = "l",
      easyClose = TRUE,
      footer = modalButton("Close")
    ))
  })

  observeEvent(input$btn_release_notes, {
    showModal(modalDialog(
      tags$div(
        style = "background: #fff; color: #212529; padding: 20px; border-radius: 6px;",
        includeMarkdown("markdown/release_notes.md")
      ),
      title = "Release Notes - v1.0.1",
      size = "l",
      easyClose = TRUE,
      footer = modalButton("Close")
    ))
  })

  # ============================================================================
  # HELP BUTTONS - modals for project settings
  # ============================================================================

  help_content <- list(
    complexity = list(
      title = "Complexity",
      body = tagList(
        p("This describes how architecturally complex your project is."),
        tags$ul(
          tags$li(tags$b("Low:"), " Simple apps with one or two screens,",
            " basic forms, straightforward logic. Think a single-page",
            " dashboard or a small CRUD tool."),
          tags$li(tags$b("Medium:"), " Multi-page apps with several",
            " interconnected features, moderate data processing,",
            " and some integration with external services."),
          tags$li(tags$b("High:"), " Large systems with complex",
            " architecture, AI/ML components, real-time data,",
            " heavy integrations, or many interacting modules.")
        ),
        p("When in doubt, choose", tags$b("Medium"), ".",
          " Higher complexity means the model predicts",
          " exponentially more effort.")
      )
    ),
    team = list(
      title = "Team Experience",
      body = tagList(
        p("Rate your team's average skill level on a 1-5 scale:"),
        tags$ul(
          tags$li(tags$b("1 - Novice:"), " New to the language,",
            " framework, and problem domain. Expect longer ramp-up."),
          tags$li(tags$b("2 - Beginner:"), " Some exposure but still",
            " learning. Needs guidance on architecture decisions."),
          tags$li(tags$b("3 - Competent:"), " Can work independently",
            " on most tasks. Solid understanding of the stack."),
          tags$li(tags$b("4 - Proficient:"), " Experienced developers",
            " who know the tools well. This is the baseline."),
          tags$li(tags$b("5 - Expert:"), " Deep expertise in the",
            " domain and tech stack. Writes efficient, clean code fast.")
        ),
        p("Higher experience means the team works faster,",
          " reducing the overall cost estimate.")
      )
    ),
    reuse = list(
      title = "Reuse Factor",
      body = tagList(
        p("How much existing code, libraries, or templates can",
          " your team reuse in this project?"),
        tags$ul(
          tags$li(tags$b("0.70 (High Reuse):"), " Over half the code",
            " comes from existing packages, templates, or past projects."),
          tags$li(tags$b("1.00 (Baseline):"), " Typical project with",
            " about 10% reuse from standard libraries."),
          tags$li(tags$b("1.30 (Greenfield):"), " Everything is built",
            " from scratch in an unfamiliar domain.")
        ),
        p("Lower values reduce the cost estimate because less",
          " new code needs to be written.")
      )
    ),
    tools = list(
      title = "Tool Support Quality",
      body = tagList(
        p("How good is your development environment and toolchain?"),
        tags$ul(
          tags$li(tags$b("0.80 (Excellent):"), " Full IDE (RStudio/VS Code),",
            " version control, CI/CD, automated testing, linters,",
            " and code review processes."),
          tags$li(tags$b("1.00 (Standard):"), " Basic IDE and version",
            " control. Some manual processes."),
          tags$li(tags$b("1.20 (Poor):"), " No IDE, no version control,",
            " manual deployments, limited tooling.")
        ),
        p("Better tools mean faster development.",
          " Lower values reduce the cost estimate.")
      )
    ),
    wage = list(
      title = "Average Annual Wage",
      body = tagList(
        p("The average annual salary (in USD) for developers on",
          " the project. This is used to convert person-months of",
          " effort into a dollar cost."),
        p("Include the full loaded cost if possible (salary +",
          " benefits + overhead). If you only know the base salary,",
          " the default of $105,000 is a reasonable US average for",
          " data science and software roles."),
        p("This setting scales the final cost linearly",
          " - doubling the wage doubles the estimate.")
      )
    ),
    maxteam = list(
      title = "Max Team Size",
      body = tagList(
        p("The maximum number of people you can put on the project",
          " at the same time."),
        p("The model uses this to cap how many people work in",
          " parallel. A smaller team means a longer schedule;",
          " a larger team (6+) adds coordination overhead (a 10%",
          " cost premium)."),
        p("The effective maximum is 8 regardless of this setting,",
          " because beyond that point coordination costs outweigh",
          " the benefit of additional people.")
      )
    ),
    maxsched = list(
      title = "Max Schedule",
      body = tagList(
        p("The longest the project is allowed to take, in months."),
        p("If the natural schedule from the model exceeds this",
          " limit, the estimator compresses the timeline. Compressed",
          " timelines cost more because they require senior talent,",
          " overtime, or additional parallel work streams."),
        tags$ul(
          tags$li("Mild compression: +20% cost premium"),
          tags$li("Moderate compression: +40% cost premium"),
          tags$li("Heavy compression: +70% cost premium"),
          tags$li("Extreme compression: +100% cost premium")
        ),
        p("Set this to a realistic deadline for your project.")
      )
    ),
    rely = list(
      title = "Required Reliability",
      body = tagList(
        p("How critical is it that the software operates without failure?"),
        tags$ul(
          tags$li(tags$b("0.82 (Very Low):"), " Prototype or proof-of-concept.",
            " Failures have minimal consequence."),
          tags$li(tags$b("1.00 (Nominal):"), " Standard business application.",
            " Failures are inconvenient but recoverable."),
          tags$li(tags$b("1.26 (Very High):"), " Mission-critical system.",
            " Failures cause significant financial or safety impact.")
        ),
        p("Higher reliability requires more testing, reviews,",
          " and defensive coding, which increases effort.")
      )
    ),
    cplx = list(
      title = "Product Complexity",
      body = tagList(
        p("The algorithmic and computational complexity of the software."),
        tags$ul(
          tags$li(tags$b("0.73 (Very Low):"), " Simple CRUD operations,",
            " basic forms, straightforward data display."),
          tags$li(tags$b("1.00 (Nominal):"), " Moderate logic, standard",
            " data processing, typical web application."),
          tags$li(tags$b("1.74 (Extra High):"), " Heavy ML/AI, real-time",
            " processing, complex algorithms, or distributed systems.")
        ),
        p("This is independent of project size - a small app",
          " can still have complex algorithms.")
      )
    ),
    ruse = list(
      title = "Required Reusability",
      body = tagList(
        p("How much effort is spent making components reusable",
          " across projects?"),
        tags$ul(
          tags$li(tags$b("0.95 (Low):"), " Code is written for this",
            " project only. Minimal documentation or generalization."),
          tags$li(tags$b("1.00 (Nominal):"), " Some consideration for",
            " reuse within the same project."),
          tags$li(tags$b("1.24 (Extra High):"), " Building generalized",
            " libraries meant to be shared across multiple projects.",
            " Requires extensive documentation and testing.")
        ),
        p("Note: this is different from the Reuse Factor setting,",
          " which measures how much existing code you can leverage.",
          " This measures the effort to", tags$em("create"), " reusable code.")
      )
    ),
    pcon = list(
      title = "Personnel Continuity",
      body = tagList(
        p("How stable is your development team over the project lifetime?"),
        tags$ul(
          tags$li(tags$b("0.81 (Very High continuity):"), " Stable team",
            " with very low turnover. Everyone stays through completion."),
          tags$li(tags$b("1.00 (Nominal):"), " Typical turnover.",
            " Some team members rotate during the project."),
          tags$li(tags$b("1.29 (Very Low continuity):"), " High churn.",
            " Frequent departures requiring constant onboarding.")
        ),
        p("Team turnover increases effort because new members",
          " need ramp-up time and knowledge is lost.")
      )
    ),
    apex = list(
      title = "Application Experience",
      body = tagList(
        p("How familiar is your team with the application domain",
          " (not just the programming language)?"),
        tags$ul(
          tags$li(tags$b("0.81 (Very High):"), " Team has deep domain",
            " expertise. They have built similar applications before."),
          tags$li(tags$b("1.00 (Nominal):"), " Moderate familiarity.",
            " Team understands the domain but hasn't built this exact type."),
          tags$li(tags$b("1.22 (Very Low):"), " Brand new domain.",
            " Team needs significant learning before being productive.")
        ),
        p("This is distinct from Team Experience (general skill level).",
          " A senior developer can still be new to a specific domain",
          " like finance or bioinformatics.")
      )
    ),
    maint_rate = list(
      title = "Annual Maintenance Rate",
      body = tagList(
        p("The percentage of the original build cost spent annually",
          " on maintenance (bug fixes, updates, minor enhancements)."),
        tags$ul(
          tags$li(tags$b("15-20%:"), " Typical for most applications.",
            " Covers routine bug fixes, dependency updates, and",
            " minor feature tweaks."),
          tags$li(tags$b("25-30%:"), " Active applications with frequent",
            " change requests or regulatory updates."),
          tags$li(tags$b("35-40%:"), " Legacy systems or rapidly evolving",
            " domains requiring constant adaptation.")
        ),
        p("The model compounds maintenance costs at 5% per year to",
          " account for growing complexity and knowledge turnover.",
          " Set to 0 to exclude maintenance from the estimate.")
      )
    ),
    maint_years = list(
      title = "Maintenance Years",
      body = tagList(
        p("How many years of post-deployment maintenance to include",
          " in the Total Cost of Ownership (TCO) calculation."),
        tags$ul(
          tags$li(tags$b("0:"), " No maintenance projection.",
            " Only the build cost is shown."),
          tags$li(tags$b("3-5 years:"), " Typical planning horizon",
            " for most business applications."),
          tags$li(tags$b("7-10 years:"), " Long-lived enterprise or",
            " infrastructure systems.")
        ),
        p("Setting this to 1 or more enables the Maintenance & TCO",
          " panel in the results, showing year-by-year costs and",
          " cumulative total cost of ownership.")
      )
    )
  )

  # Register help button handlers for all three tab prefixes
  lapply(c("local", "zip", "manual"), function(prefix) {
    lapply(names(help_content), function(key) {
      btn_id <- paste0(prefix, "_help_", key)
      hc <- help_content[[key]]
      observeEvent(input[[btn_id]], {
        showModal(modalDialog(
          tags$div(
            style = paste0(
              "background: #fff; color: #212529;",
              " padding: 15px; border-radius: 6px;"
            ),
            hc$body
          ),
          title = hc$title,
          size = "m",
          easyClose = TRUE,
          footer = modalButton("Close")
        ))
      })
    })
  })

  # ============================================================================
  # HELPER: build params list from inputs
  # ============================================================================

  local_params <- reactive({
    list(
      complexity = input$local_complexity,
      team_exp = input$local_team_exp,
      reuse = input$local_reuse,
      tools = input$local_tools,
      wage = input$local_wage,
      max_team = input$local_max_team,
      max_schedule = input$local_max_schedule,
      rely = input$local_rely,
      cplx = input$local_cplx,
      ruse = input$local_ruse,
      pcon = input$local_pcon,
      apex = input$local_apex,
      maintenance_rate = input$local_maint_rate,
      maintenance_years = input$local_maint_years
    )
  })

  zip_params <- reactive({
    list(
      complexity = input$zip_complexity,
      team_exp = input$zip_team_exp,
      reuse = input$zip_reuse,
      tools = input$zip_tools,
      wage = input$zip_wage,
      max_team = input$zip_max_team,
      max_schedule = input$zip_max_schedule,
      rely = input$zip_rely,
      cplx = input$zip_cplx,
      ruse = input$zip_ruse,
      pcon = input$zip_pcon,
      apex = input$zip_apex,
      maintenance_rate = input$zip_maint_rate,
      maintenance_years = input$zip_maint_years
    )
  })

  manual_params <- reactive({
    list(
      complexity = input$manual_complexity,
      team_exp = input$manual_team_exp,
      reuse = input$manual_reuse,
      tools = input$manual_tools,
      wage = input$manual_wage,
      max_team = input$manual_max_team,
      max_schedule = input$manual_max_schedule,
      rely = input$manual_rely,
      cplx = input$manual_cplx,
      ruse = input$manual_ruse,
      pcon = input$manual_pcon,
      apex = input$manual_apex,
      maintenance_rate = input$manual_maint_rate,
      maintenance_years = input$manual_maint_years
    )
  })

  # ============================================================================
  # LOCAL FOLDER ANALYSIS
  # ============================================================================

  observeEvent(input$browse_folder, {
    path <- tryCatch({
      os_type <- Sys.info()[["sysname"]]

      if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
        selected <- rstudioapi::selectDirectory(caption = "Select Repository Folder")
        if (!is.null(selected) && nzchar(selected)) return(selected)
      }

      if (os_type == "Darwin") {
        cmd <- "osascript -e 'POSIX path of (choose folder with prompt \"Select Repository Folder\")'"
        res <- suppressWarnings(system(cmd, intern = TRUE, ignore.stderr = TRUE))
        if (length(res) > 0 && nzchar(res[1])) {
          selected <- sub("/$", "", trimws(res[1]))
          if (nzchar(selected)) return(selected)
        }
      }

      if (requireNamespace("tcltk", quietly = TRUE)) {
        selected <- tcltk::tk_choose.dir(caption = "Select Repository Folder")
        if (!is.null(selected) && nzchar(selected)) return(selected)
      }

      stop("No folder selection method succeeded")
    }, error = function(e) {
      showNotification("Folder browser not available. Please enter the path manually.",
                      type = "warning", duration = 8)
      return(NULL)
    })

    if (!is.null(path) && nzchar(path)) {
      updateTextInput(session, "local_path", value = path)
      showNotification("Folder selected!", type = "message", duration = 3)
    }
  })

  observeEvent(input$analyze_local, {
    req(input$local_path)

    if (!dir.exists(input$local_path)) {
      showNotification("Directory does not exist!", type = "error")
      return(NULL)
    }

    tryCatch({
      withProgress(message = "Analyzing repository...", value = 0, {
        capture.output({
          analysis <- analyze_repo_code(
            path = input$local_path,
            avg_wage = input$local_wage,
            complexity = input$local_complexity,
            team_experience = input$local_team_exp,
            reuse_factor = input$local_reuse,
            tool_support = input$local_tools,
            max_team_size = input$local_max_team,
            max_schedule_months = input$local_max_schedule,
            progress_callback = function(current, total) {
              setProgress(
                value = current / total,
                detail = paste0("File ", current, " of ", total)
              )
            }
          )
        })
        results$local <- list(lang_summary = analysis)
      })
      showNotification("Analysis complete!", type = "message", duration = 3)
    }, error = function(e) {
      showNotification(paste("Error:", e$message), type = "error", duration = 10)
    })
  })

  local_data <- reactive({
    req(results$local)
    results$local
  })

  analysisResultsServer("local_results", local_data, local_params, ai_available = ai_available)

  # ============================================================================
  # ZIP UPLOAD ANALYSIS
  # ============================================================================

  observeEvent(input$analyze_zip, {
    req(input$zip_file)

    # Security: check file size (50MB limit)
    if (file.info(input$zip_file$datapath)$size > 50 * 1024 * 1024) {
      showNotification("File exceeds 50MB limit.", type = "error")
      return(NULL)
    }

    tryCatch({
      withProgress(message = "Analyzing ZIP contents...", value = 0, {
        # Use isolated temp directory instead of shared tempdir()
        temp_dir <- tempfile(pattern = "zip_analysis_")
        dir.create(temp_dir)
        on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

        setProgress(value = 0.1, detail = "Extracting ZIP file...")
        unzip(input$zip_file$datapath, exdir = temp_dir)

        # Validate: no path traversal
        extracted_files <- list.files(temp_dir, recursive = TRUE, full.names = TRUE)
        relative_paths <- gsub(paste0("^", normalizePath(temp_dir)), "", normalizePath(extracted_files))
        if (any(grepl("\\.\\.", relative_paths))) {
          showNotification("ZIP contains invalid paths (path traversal detected).", type = "error")
          return(NULL)
        }

        # Find the actual repo folder
        extracted_folders <- list.dirs(temp_dir, recursive = FALSE)
        repo_path <- if (length(extracted_folders) > 0) extracted_folders[1] else temp_dir

        setProgress(value = 0.2, detail = "Analyzing files...")
        capture.output({
          analysis <- analyze_repo_code(
            path = repo_path,
            avg_wage = input$zip_wage,
            complexity = input$zip_complexity,
            team_experience = input$zip_team_exp,
            reuse_factor = input$zip_reuse,
            tool_support = input$zip_tools,
            max_team_size = input$zip_max_team,
            max_schedule_months = input$zip_max_schedule,
            progress_callback = function(current, total) {
              setProgress(
                value = 0.2 + 0.8 * (current / total),
                detail = paste0("File ", current, " of ", total)
              )
            }
          )
        })
        results$zip <- list(lang_summary = analysis)
      })
      showNotification("ZIP analysis complete!", type = "message", duration = 3)
    }, error = function(e) {
      showNotification(paste("Error:", e$message), type = "error", duration = 10)
    })
  })

  zip_data <- reactive({
    req(results$zip)
    results$zip
  })

  analysisResultsServer("zip_results", zip_data, zip_params, ai_available = ai_available)

  # ============================================================================
  # MANUAL ENTRY
  # ============================================================================

  observeEvent(input$calculate_manual, {
    language_mix <- list(
      "R" = input$manual_r,
      "Python" = input$manual_python,
      "JavaScript" = input$manual_js,
      "SQL" = input$manual_sql,
      "CSS" = input$manual_css,
      "Other" = input$manual_other
    )

    language_mix <- language_mix[language_mix > 0]

    if (length(language_mix) == 0) {
      showNotification("Please enter at least one code line count.", type = "warning")
      return(NULL)
    }

    results$manual <- list(
      language_mix = language_mix,
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

  manual_data <- reactive({
    req(results$manual)
    results$manual
  })

  analysisResultsServer("manual_results", manual_data, manual_params, ai_available = ai_available)

  # ============================================================================
  # COMPARISON & EXPORT MODULES
  # ============================================================================

  comparisonServer("compare")
  exportServer("export", results, list(parent_session = session))

  # ============================================================================
  # URL PARAMETER HANDLING (for shareable links)
  # ============================================================================

  observe({
    query <- parseQueryString(session$clientData$url_search)

    if (!is.null(query$mode) && query$mode == "manual") {
      if (!is.null(query$r)) updateNumericInput(session, "manual_r", value = as.numeric(query$r))
      if (!is.null(query$py)) updateNumericInput(session, "manual_python", value = as.numeric(query$py))
      if (!is.null(query$js)) updateNumericInput(session, "manual_js", value = as.numeric(query$js))
      if (!is.null(query$sql)) updateNumericInput(session, "manual_sql", value = as.numeric(query$sql))
      if (!is.null(query$complexity)) updateSelectInput(session, "manual_complexity", selected = query$complexity)
      if (!is.null(query$team)) updateSliderInput(session, "manual_team_exp", value = as.numeric(query$team))

      nav_select("nav", selected = "Manual Entry")
      showNotification("Pre-filled from shared URL!", type = "message", duration = 5)
    }
  })
}

# Run the application
shinyApp(ui = ui, server = server)
