# Shiny App Cost Estimator (COCOMO II-inspired)
# Usage: source this file and call estimate_shiny_cost(<code_lines>, <complexity>, <team_experience>, <reuse_factor>, <tool_support>)

#' Estimate cost, schedule, and team size for a Shiny app
#' @param code_lines Number of code lines (R + JS + CSS + Python + SQL)
#' @param complexity "low", "medium", or "high" (affects exponent)
#' @param team_experience 1 (novice) to 5 (expert)
#' @param reuse_factor 0.7 (lots of reuse) to 1.3 (little reuse)
#' @param tool_support 0.8 (excellent) to 1.2 (poor)
#' @param language_mix List with code lines by language (optional, for weighting)
#' @return List with cost, schedule, people, and effort
estimate_shiny_cost <- function(
  code_lines,
  complexity = "medium",
  team_experience = 4,
  reuse_factor = 1.0,
  tool_support = 1.0,
  language_mix = NULL
) {
  # COCOMO II base values (adjusted for modern web/data apps)
  # Modern frameworks are more productive than classic COCOMO assumes
  A <- 2.50  # Reduced from 2.94 for modern tools/frameworks
  B <- switch(complexity, low = 1.02, medium = 1.10, high = 1.18, 1.10)
  
  # Language productivity factors (lines per person-month)
  # Higher = more productive = lower cost
  lang_productivity <- list(
    "R" = 1.0,           # Baseline (R/Shiny is fairly productive)
    "Python" = 1.1,      # Python is slightly more productive
    "SQL" = 1.3,         # SQL is declarative, very productive
    "JavaScript" = 0.9,  # JS can be complex with frameworks
    "CSS" = 1.2,         # CSS is relatively simple
    "HTML" = 1.3,        # HTML is markup, very productive
    "Markdown" = 1.5,    # Markdown is trivial
    "YAML" = 1.5,        # Config files are trivial
    "JSON" = 1.5         # Config files are trivial
  )
  
  # Calculate effective KLOC with language weighting
  if (!is.null(language_mix)) {
    weighted_code <- 0
    for (lang in names(language_mix)) {
      productivity <- lang_productivity[[lang]]
      if (is.null(productivity)) productivity <- 1.0
      weighted_code <- weighted_code + (language_mix[[lang]] / productivity)
    }
    KLOC <- weighted_code / 1000
  } else {
    KLOC <- code_lines / 1000
  }
  
  # Effort multipliers
  EM_experience <- 1.2 - 0.05 * team_experience  # 1.15 (novice) to 0.95 (expert)
  EM_reuse <- reuse_factor
  EM_tools <- tool_support
  
  # Additional multiplier for modern frameworks
  EM_modern <- 0.85  # Modern frameworks (Shiny, Databricks) reduce effort by ~15%
  
  EM_total <- EM_experience * EM_reuse * EM_tools * EM_modern
  
  # Effort (person-months)
  effort <- A * (KLOC ^ B) * EM_total
  
  # Schedule (months) - adjusted for agile/iterative development
  C <- 3.50  # Reduced from 3.67 for faster modern development cycles
  D <- 0.28 + 0.2 * (B - 1.01)  # COCOMO II schedule exponent
  schedule <- C * (effort ^ D)
  
  # Team size
  people <- effort / schedule
  
  # Cost (USD, rough, $12k/month/person for blended team)
  cost <- effort * 12000
  list(
    code_lines = code_lines,
    effort_person_months = round(effort, 2),
    schedule_months = round(schedule, 2),
    people_required = round(people, 2),
    estimated_cost_usd = round(cost),
    params = list(complexity = complexity, team_experience = team_experience, reuse_factor = reuse_factor, tool_support = tool_support)
  )
}


#' Print a Shiny cost estimation report in scc-style format
#' @param result Output from estimate_shiny_cost()
print_shiny_cost_report <- function(result) {
  cat("\n───────────────────────────────────────────────────────────────────────────────\n")
  cat(sprintf("%-25s %12s\n", "Metric", "Value"))
  cat("───────────────────────────────────────────────────────────────────────────────\n")
  cat(sprintf("%-25s %12d\n", "Total Code Lines", result$code_lines))
  cat(sprintf("%-25s %12.2f\n", "Effort (person-months)", result$effort_person_months))
  cat(sprintf("%-25s %12.2f\n", "Schedule (months)", result$schedule_months))
  cat(sprintf("%-25s %12.2f\n", "People Required", result$people_required))
  cat(sprintf("%-25s $%11s\n", "Estimated Cost (USD)", format(result$estimated_cost_usd, big.mark=",")))
  cat("───────────────────────────────────────────────────────────────────────────────\n")
  cat("Parameters Used:\n")
  cat(sprintf("  Complexity:        %s\n", result$params$complexity))
  cat(sprintf("  Team Experience:   %s\n", result$params$team_experience))
  cat(sprintf("  Reuse Factor:      %.2f\n", result$params$reuse_factor))
  cat(sprintf("  Tool Support:      %.2f\n", result$params$tool_support))
  cat("───────────────────────────────────────────────────────────────────────────────\n\n")
}

# Example usage:
# result <- estimate_shiny_cost(35000, complexity = "medium", team_experience = 4, reuse_factor = 0.9, tool_support = 0.9)
# print_shiny_cost_report(result)
