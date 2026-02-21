# Shiny App Cost Estimator - Interactive Dashboard
# Modular architecture with COCOMO II estimation engine
# Author: Alexis Roldan

library(shiny)
library(bslib)
library(plotly)
library(DT)
library(shinyWidgets)
library(markdown)

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

# Detect deployed environment (shinyapps.io sets R_CONFIG_ACTIVE="rsconnect")
is_deployed <- nzchar(Sys.getenv("R_CONFIG_ACTIVE"))

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

# Reusable sidebar settings block with help buttons — "analyze" prefix
project_settings_sidebar <- function(prefix) {
  tagList(
    tags$div(
      class = "sidebar-section",
      tags$h6("Project Parameters", class = "sidebar-section-label"),

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
                 min = 0.8, max = 1.2, value = 1.0, step = 0.05)
    ),
    hr(),
    tags$div(
      class = "sidebar-section",
      tags$h6("Cost Parameters", class = "sidebar-section-label"),

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
  )
}

# Shared sidebar for advanced COCOMO drivers + maintenance
advanced_cocomo_sidebar <- function(prefix) {
  tagList(
    hr(),
    tags$details(
      tags$summary(
        tags$b("Advanced COCOMO Drivers"),
        tags$span(style = "margin-left: 8px;"),
        uiOutput(paste0(prefix, "_em_total_badge"), inline = TRUE)
      ),
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
  header = tags$head(
    tags$link(rel = "icon", type = "image/svg+xml", href = "favicon.svg"),
    tags$style(HTML("
      /* ---- Summary strip ---- */
      .summary-strip {
        position: sticky; bottom: 0; z-index: 100;
        background: rgba(22, 26, 33, 0.97);
        border-top: 1px solid #375a7f;
        padding: 6px 20px;
        display: flex; gap: 24px; align-items: center;
        font-size: 0.85rem;
      }
      .summary-strip .strip-item { color: #dee2e6; }
      .summary-strip .strip-label { color: #888; margin-right: 4px; }
      .summary-strip .strip-value { color: #00bc8c; font-weight: 600; }

      /* ---- Hero cost box ---- */
      .confidence-bar-container { margin-top: 6px; }
      .confidence-bar {
        height: 4px; border-radius: 2px;
        background: linear-gradient(to right, rgba(255,255,255,0.2), rgba(255,255,255,0.85), rgba(255,255,255,0.2));
      }
      .confidence-labels {
        display: flex; justify-content: space-between;
        font-size: 0.7rem; color: rgba(255,255,255,0.8); margin-top: 2px;
      }

      /* ---- Sidebar section labels ---- */
      .sidebar-section-label {
        font-size: 0.68rem; text-transform: uppercase;
        letter-spacing: 0.08em; color: #888; margin: 12px 0 4px;
      }

      /* ---- Result card accent ---- */
      .result-card { border-left: 3px solid #00bc8c !important; }
      .warning-card { border-left: 3px solid #f39c12 !important; }

      /* ---- Count-up animation ---- */
      @keyframes countup { from { opacity: 0.3; } to { opacity: 1; } }
      .value-box .value { animation: countup 0.4s ease-out; }

      /* ---- EM total badge ---- */
      .em-badge {
        display: inline-block; padding: 1px 6px;
        border-radius: 10px; font-size: 0.72rem;
        font-weight: 600; vertical-align: middle;
      }
      .em-neutral { background: #444; color: #ccc; }
      .em-green   { background: #00bc8c22; color: #00bc8c; border: 1px solid #00bc8c55; }
      .em-red     { background: #e74c3c22; color: #e74c3c; border: 1px solid #e74c3c55; }

      /* ---- Input method radio buttons ---- */
      .input-method-bar {
        padding: 10px 16px 6px;
        border-bottom: 1px solid rgba(255,255,255,0.08);
        margin-bottom: 4px;
      }
      .input-method-bar .radio-inline { font-size: 0.9rem; }

      /* ---- Demo card on Home ---- */
      .demo-card-stat {
        text-align: center;
        padding: 12px 8px;
      }
      .demo-card-stat .stat-val {
        font-size: 1.6rem; font-weight: 700; color: #00bc8c;
      }
      .demo-card-stat .stat-lbl {
        font-size: 0.8rem; color: #aaa; margin-top: 2px;
      }

      /* ---- Sidebar wider ---- */
      .bslib-sidebar-layout > .sidebar { min-width: 280px; }
    "))
  ),
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
    tags$span("Shiny Cost Estimator v1.1.0"),
    tags$span("Created by Alexis Roldan - 2026")
  ),

  # ── Home tab (Live Demo) ──────────────────────────────────────────────────
  nav_panel(
    title = "Home",
    icon = icon("home"),
    layout_column_wrap(
      width = 1,
      card(
        card_header(
          tags$div(
            style = "display: flex; justify-content: space-between; align-items: center;",
            tags$span("COCOMO II Cost Estimator — Live Demo"),
            tags$small("10,000 lines · Medium complexity · Team exp 3", class = "text-muted")
          )
        ),
        card_body(
          uiOutput("demo_stats"),
          hr(),
          h4("Quantify Your Development Investment"),
          p(
            "This tool uses the industry-standard COCOMO II model to estimate cost, schedule,",
            " and team size for R Shiny and data science projects."
          ),
          tags$ul(
            if (!is_deployed) tags$li(tags$b("Local Folder:"), " Scan a project directory directly"),
            tags$li(tags$b("ZIP Upload:"), " Upload a repository ZIP (works anywhere)"),
            tags$li(tags$b("Manual Entry:"), " Quick estimates from known line counts")
          ),
          br(),
          div(
            style = "display: flex; gap: 12px; flex-wrap: wrap;",
            actionButton("go_analyze", "Analyze Your Project →",
                         class = "btn-success btn-lg",
                         style = "width: auto;",
                         icon = icon("arrow-right")),
            actionButton("go_compare", "Compare Scenarios",
                         class = "btn-outline-secondary btn-lg",
                         style = "width: auto;",
                         icon = icon("balance-scale"))
          )
        )
      )
    )
  ),

  # ── Analyze tab (merged Local / ZIP / Manual) ─────────────────────────────
  nav_panel(
    title = "Analyze",
    icon = icon("chart-bar"),
    layout_sidebar(
      sidebar = sidebar(
        open = "open",
        id = "analyze_sidebar",
        title = "Analysis Parameters",
        width = 300,

        # Input method selector
        div(
          class = "input-method-bar",
          radioButtons(
            "input_method", NULL,
            choices = {
              if (!is_deployed)
                c("Local Folder" = "local", "ZIP Upload" = "zip", "Manual Entry" = "manual")
              else
                c("ZIP Upload" = "zip", "Manual Entry" = "manual")
            },
            selected = "manual",
            inline = TRUE
          )
        ),

        # ── Local-only inputs ──
        if (!is_deployed)
          conditionalPanel(
            condition = "input.input_method == 'local'",
            textInput("local_path", "Repository Path:",
                     value = getwd(),
                     placeholder = "/path/to/your/repo"),
            actionButton("browse_folder", "Browse Folder", icon = icon("search"),
                        class = "btn-sm btn-secondary mb-3")
          ),

        # ── ZIP inputs ──
        conditionalPanel(
          condition = "input.input_method == 'zip'",
          fileInput("zip_file", "Upload Repository ZIP:",
                   accept = c(".zip"),
                   buttonLabel = "Browse...",
                   placeholder = "No file selected"),
          tags$small(class = "text-muted", "Max file size: 50MB")
        ),

        # ── Manual inputs ──
        conditionalPanel(
          condition = "input.input_method == 'manual'",
          tags$div(
            class = "sidebar-section",
            tags$h6("Code Lines by Language", class = "sidebar-section-label"),
            numericInput("manual_r",      "R:",          value = 0, min = 0),
            numericInput("manual_python", "Python:",     value = 0, min = 0),
            numericInput("manual_js",     "JavaScript:", value = 0, min = 0),
            numericInput("manual_sql",    "SQL:",        value = 0, min = 0),
            numericInput("manual_css",    "CSS:",        value = 0, min = 0),
            numericInput("manual_other",  "Other:",      value = 0, min = 0)
          )
        ),

        # ── Shared project settings ──
        project_settings_sidebar("analyze"),
        advanced_cocomo_sidebar("analyze"),

        hr(),
        actionButton("run_analysis", "Run Analysis",
                    icon = icon("play"),
                    class = "btn-primary btn-lg w-100")
      ),

      # Results area
      analysisResultsUI("analyze_results", ai_available = ai_available)
    )
  ),

  # ── Compare tab ───────────────────────────────────────────────────────────
  nav_panel(
    title = "Compare",
    icon = icon("balance-scale"),
    comparisonUI("compare")
  ),

  # ── Export tab ────────────────────────────────────────────────────────────
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
  results <- reactiveValues(analyze = NULL)

  # ============================================================================
  # HOME TAB — Live Demo
  # ============================================================================

  demo_est <- local({
    tryCatch(
      estimate_shiny_cost(
        code_lines   = 10000,
        complexity   = "medium",
        team_experience = 3,
        reuse_factor = 1.0,
        tool_support = 1.0,
        avg_wage     = 105000,
        max_team_size = 5,
        max_schedule_months = 24
      ),
      error = function(e) NULL
    )
  })

  output$demo_stats <- renderUI({
    req(!is.null(demo_est))
    e <- demo_est
    layout_column_wrap(
      width = 1/4,
      div(class = "demo-card-stat",
        div(class = "stat-val", paste0("$", format(e$realistic_cost_usd, big.mark = ","))),
        div(class = "stat-lbl", "Estimated Cost")
      ),
      div(class = "demo-card-stat",
        div(class = "stat-val", paste0(e$final_schedule_months, " mo")),
        div(class = "stat-lbl", "Schedule")
      ),
      div(class = "demo-card-stat",
        div(class = "stat-val", paste0(e$final_people, " people")),
        div(class = "stat-lbl", "Team Size")
      ),
      div(class = "demo-card-stat",
        div(class = "stat-val",
            paste0("$", format(e$confidence_interval$low, big.mark = ","),
                   " – $", format(e$confidence_interval$high, big.mark = ","))),
        div(class = "stat-lbl", "70% Confidence Range")
      )
    )
  })

  observeEvent(input$go_analyze, nav_select("nav", selected = "Analyze"))
  observeEvent(input$go_compare, nav_select("nav", selected = "Compare"))

  # ============================================================================
  # NAVBAR BUTTONS — User Guide and Release Notes modals
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
      title = "Release Notes - v1.1.0",
      size = "l",
      easyClose = TRUE,
      footer = modalButton("Close")
    ))
  })

  # ============================================================================
  # HELP BUTTONS — modals for project settings
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

  # Register help button handlers for "analyze" prefix
  lapply(names(help_content), function(key) {
    btn_id <- paste0("analyze_help_", key)
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

  # ============================================================================
  # EM_TOTAL BADGE (for Advanced COCOMO Drivers summary line)
  # ============================================================================

  output$analyze_em_total_badge <- renderUI({
    rely <- if (!is.null(input$analyze_rely)) input$analyze_rely else 1.0
    cplx <- if (!is.null(input$analyze_cplx)) input$analyze_cplx else 1.0
    ruse <- if (!is.null(input$analyze_ruse)) input$analyze_ruse else 1.0
    pcon <- if (!is.null(input$analyze_pcon)) input$analyze_pcon else 1.0
    apex <- if (!is.null(input$analyze_apex)) input$analyze_apex else 1.0
    em  <- rely * cplx * ruse * pcon * apex
    cls <- if (abs(em - 1.0) < 0.01) "em-badge em-neutral"
           else if (em < 1.0)        "em-badge em-green"
           else                      "em-badge em-red"
    tags$span(class = cls, sprintf("EM: %.2fx", em))
  })

  # ============================================================================
  # HELPER: build params list from inputs
  # ============================================================================

  analyze_params <- reactive({
    list(
      complexity        = input$analyze_complexity,
      team_exp          = input$analyze_team_exp,
      reuse             = input$analyze_reuse,
      tools             = input$analyze_tools,
      wage              = input$analyze_wage,
      max_team          = input$analyze_max_team,
      max_schedule      = input$analyze_max_schedule,
      rely              = input$analyze_rely,
      cplx              = input$analyze_cplx,
      ruse              = input$analyze_ruse,
      pcon              = input$analyze_pcon,
      apex              = input$analyze_apex,
      maintenance_rate  = input$analyze_maint_rate,
      maintenance_years = input$analyze_maint_years
    )
  })

  # ============================================================================
  # BROWSE FOLDER (Local only)
  # ============================================================================

  if (!is_deployed) {
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
  }

  # ============================================================================
  # SINGLE ANALYSIS RUNNER (branches on input_method)
  # ============================================================================

  observeEvent(input$run_analysis, {
    method <- input$input_method

    if (method == "local") {
      # ── Local folder ──
      req(input$local_path)
      if (!dir.exists(input$local_path)) {
        showNotification("Directory does not exist!", type = "error")
        return(NULL)
      }
      tryCatch({
        withProgress(message = "Analyzing repository...", value = 0, {
          capture.output({
            analysis <- analyze_repo_code(
              path              = input$local_path,
              avg_wage          = input$analyze_wage,
              complexity        = input$analyze_complexity,
              team_experience   = input$analyze_team_exp,
              reuse_factor      = input$analyze_reuse,
              tool_support      = input$analyze_tools,
              max_team_size     = input$analyze_max_team,
              max_schedule_months = input$analyze_max_schedule,
              progress_callback = function(current, total) {
                setProgress(
                  value  = current / total,
                  detail = paste0("File ", current, " of ", total)
                )
              }
            )
          })
          results$analyze <- list(lang_summary = analysis)
        })
        showNotification("Analysis complete!", type = "message", duration = 3)
      }, error = function(e) {
        showNotification(paste("Error:", e$message), type = "error", duration = 10)
      })

    } else if (method == "zip") {
      # ── ZIP upload ──
      req(input$zip_file)
      if (file.info(input$zip_file$datapath)$size > 50 * 1024 * 1024) {
        showNotification("File exceeds 50MB limit.", type = "error")
        return(NULL)
      }
      tryCatch({
        withProgress(message = "Analyzing ZIP contents...", value = 0, {
          temp_dir <- tempfile(pattern = "zip_analysis_")
          dir.create(temp_dir)
          on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

          setProgress(value = 0.1, detail = "Extracting ZIP file...")
          unzip(input$zip_file$datapath, exdir = temp_dir)

          extracted_files <- list.files(temp_dir, recursive = TRUE, full.names = TRUE)
          if (length(extracted_files) == 0) {
            showNotification(
              "Could not extract any files from the ZIP archive.",
              type = "error"
            )
            return(NULL)
          }

          relative_paths <- gsub(
            paste0("^", normalizePath(temp_dir)), "",
            normalizePath(extracted_files)
          )
          if (any(grepl("\\.\\.", relative_paths))) {
            showNotification(
              "ZIP contains invalid paths (path traversal detected).",
              type = "error"
            )
            return(NULL)
          }

          extracted_folders <- list.dirs(temp_dir, recursive = FALSE)
          extracted_folders <- extracted_folders[
            !grepl("^__MACOSX$", basename(extracted_folders))
          ]
          extracted_folders <- extracted_folders[
            !grepl("^\\.", basename(extracted_folders))
          ]
          repo_path <- if (length(extracted_folders) > 0) extracted_folders[1] else temp_dir

          setProgress(value = 0.2, detail = "Analyzing files...")
          capture.output({
            analysis <- analyze_repo_code(
              path              = repo_path,
              avg_wage          = input$analyze_wage,
              complexity        = input$analyze_complexity,
              team_experience   = input$analyze_team_exp,
              reuse_factor      = input$analyze_reuse,
              tool_support      = input$analyze_tools,
              max_team_size     = input$analyze_max_team,
              max_schedule_months = input$analyze_max_schedule,
              progress_callback = function(current, total) {
                setProgress(
                  value  = 0.2 + 0.8 * (current / total),
                  detail = paste0("File ", current, " of ", total)
                )
              }
            )
          })

          if (is.null(analysis) || nrow(analysis) == 0 || sum(analysis$Code) == 0) {
            showNotification(
              "No code files found in the ZIP archive. Please ensure it contains source code files.",
              type = "warning", duration = 8
            )
            return(NULL)
          }

          results$analyze <- list(lang_summary = analysis)
        })
        showNotification("ZIP analysis complete!", type = "message", duration = 3)
      }, error = function(e) {
        showNotification(paste("Error:", e$message), type = "error", duration = 10)
      })

    } else {
      # ── Manual entry ──
      language_mix <- list(
        "R"          = input$manual_r,
        "Python"     = input$manual_python,
        "JavaScript" = input$manual_js,
        "SQL"        = input$manual_sql,
        "CSS"        = input$manual_css,
        "Other"      = input$manual_other
      )
      language_mix <- language_mix[language_mix > 0]

      if (length(language_mix) == 0) {
        showNotification("Please enter at least one code line count.", type = "warning")
        return(NULL)
      }

      results$analyze <- list(
        language_mix = language_mix,
        params = list(
          complexity  = input$analyze_complexity,
          team_exp    = input$analyze_team_exp,
          reuse       = input$analyze_reuse,
          tools       = input$analyze_tools,
          wage        = input$analyze_wage
        )
      )
      showNotification("Calculation complete!", type = "message", duration = 3)
    }

    # Collapse sidebar after analysis so results take full width
    tryCatch(
      sidebar_toggle("analyze_sidebar", open = FALSE, session = session),
      error = function(e) NULL
    )
  })

  # Analysis data reactive
  analyze_data <- reactive({
    req(results$analyze)
    results$analyze
  })

  analysisResultsServer("analyze_results", analyze_data, analyze_params, ai_available = ai_available)

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
      if (!is.null(query$r))   updateNumericInput(session, "manual_r",      value = as.numeric(query$r))
      if (!is.null(query$py))  updateNumericInput(session, "manual_python", value = as.numeric(query$py))
      if (!is.null(query$js))  updateNumericInput(session, "manual_js",     value = as.numeric(query$js))
      if (!is.null(query$sql)) updateNumericInput(session, "manual_sql",    value = as.numeric(query$sql))
      if (!is.null(query$complexity))
        updateSelectInput(session, "analyze_complexity", selected = query$complexity)
      if (!is.null(query$team))
        updateSliderInput(session, "analyze_team_exp",   value = as.numeric(query$team))

      updateRadioButtons(session, "input_method", selected = "manual")
      nav_select("nav", selected = "Analyze")
      showNotification("Pre-filled from shared URL!", type = "message", duration = 5)
    }
  })
}

# Run the application
shinyApp(ui = ui, server = server)
