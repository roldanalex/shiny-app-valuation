# Shiny App Cost Estimator (COCOMO II-inspired)
# Usage: source this file and call estimate_shiny_cost(<code_lines>, <complexity>, <team_experience>, <reuse_factor>, <tool_support>)

#' Estimate cost, schedule, and team size for a Shiny app
#' @param code_lines Number of code lines (R + JS + CSS + Python + SQL)
#' @param complexity "low", "medium", or "high" (affects exponent)
#' @param team_experience 1 (novice) to 5 (expert)
#' @param reuse_factor 0.7 (lots of reuse) to 1.3 (little reuse)
#' @param tool_support 0.8 (excellent) to 1.2 (poor)
#' @param language_mix List with code lines by language (optional, for weighting)
#' @param avg_wage Average annual wage for cost estimation (default: 105000)
#' @param max_team_size Maximum team size constraint (default: 5)
#' @param max_schedule_months Maximum schedule constraint in months (default: 24)
#' @param rely Required reliability multiplier (0.82-1.26, default: 1.0)
#' @param cplx Product complexity multiplier (0.73-1.74, default: 1.0)
#' @param ruse Required reusability multiplier (0.95-1.24, default: 1.0)
#' @param pcon Personnel continuity multiplier (0.81-1.29, default: 1.0)
#' @param apex Application experience multiplier (0.81-1.22, default: 1.0)
#' @param maintenance_rate Annual maintenance as fraction of build cost (default: 0.20)
#' @param maintenance_years Number of years to project maintenance (default: 0)
#' @return List with cost, schedule, people, effort, constraints, confidence, and maintenance
estimate_shiny_cost <- function(
  code_lines,
  complexity = "medium",
  team_experience = 4,
  reuse_factor = 1.0,
  tool_support = 1.0,
  language_mix = NULL,
  avg_wage = 105000,
  max_team_size = 5,
  max_schedule_months = 24,
  rely = 1.0,
  cplx = 1.0,
  ruse = 1.0,
  pcon = 1.0,
  apex = 1.0,
  maintenance_rate = 0.20,
  maintenance_years = 0
) {
  # Input validation
  stopifnot(is.numeric(code_lines), code_lines >= 0)
  complexity <- match.arg(complexity, c("low", "medium", "high"))
  stopifnot(is.numeric(team_experience), team_experience >= 1, team_experience <= 5)
  stopifnot(is.numeric(reuse_factor), reuse_factor >= 0.7, reuse_factor <= 1.3)
  stopifnot(is.numeric(tool_support), tool_support >= 0.8, tool_support <= 1.2)
  stopifnot(is.numeric(rely), rely >= 0.82, rely <= 1.26)
  stopifnot(is.numeric(cplx), cplx >= 0.73, cplx <= 1.74)
  stopifnot(is.numeric(ruse), ruse >= 0.95, ruse <= 1.24)
  stopifnot(is.numeric(pcon), pcon >= 0.81, pcon <= 1.29)
  stopifnot(is.numeric(apex), apex >= 0.81, apex <= 1.22)
  stopifnot(is.numeric(maintenance_rate), maintenance_rate >= 0, maintenance_rate <= 1)
  stopifnot(is.numeric(maintenance_years), maintenance_years >= 0)

  # COCOMO II base values (adjusted for modern web/data apps)
  A <- 2.50
  B <- switch(complexity, low = 1.02, medium = 1.10, high = 1.18, 1.10)

  # Language productivity factors
  lang_productivity <- list(
    "R" = 1.0,
    "Python" = 1.1,
    "SQL" = 1.3,
    "JavaScript" = 0.9,
    "CSS" = 1.2,
    "HTML" = 1.3,
    "Markdown" = 1.5,
    "YAML" = 1.5,
    "JSON" = 1.5
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
  EM_modern <- 0.85  # Modern frameworks reduce effort by ~15%

  # COCOMO II cost drivers
  EM_rely <- rely
  EM_cplx <- cplx
  EM_ruse <- ruse
  EM_pcon <- pcon
  EM_apex <- apex

  EM_total <- EM_experience * EM_reuse * EM_tools * EM_modern *
              EM_rely * EM_cplx * EM_ruse * EM_pcon * EM_apex

  # Base effort before multipliers (for waterfall chart)
  base_effort <- A * (KLOC ^ B)

  # Effort (person-months)
  effort <- base_effort * EM_total

  # Schedule (months) - adjusted for agile/iterative development
  C <- 3.50
  D <- 0.28 + 0.2 * (B - 1.01)
  schedule <- if (effort > 0) C * (effort ^ D) else 0

  # Team size
  people <- if (schedule > 0) effort / schedule else 0

  # Base cost (unconstrained, $12k/month/person)
  cost <- effort * 12000

  # --- Realistic constraints (ported from Python version) ---
  monthly_wage <- avg_wage / 12
  original_people <- people
  original_schedule <- schedule
  original_effort <- effort

  max_realistic_people <- 8

  unconstrained_people <- min(original_people, max_team_size)
  unconstrained_schedule <- if (unconstrained_people > 0) original_effort / unconstrained_people else original_effort

  final_people <- min(unconstrained_people, max_realistic_people)
  natural_schedule <- if (final_people > 0) original_effort / final_people else original_effort
  final_schedule <- min(natural_schedule, max_schedule_months)

  premium_multiplier <- 1.0
  coordination_premium <- 1.0

  if (natural_schedule > max_schedule_months) {
    compression_ratio <- if (final_schedule > 0) natural_schedule / final_schedule else natural_schedule
    if (compression_ratio >= 4) {
      premium_multiplier <- 2.0
    } else if (compression_ratio >= 3) {
      premium_multiplier <- 1.7
    } else if (compression_ratio >= 2) {
      premium_multiplier <- 1.4
    } else {
      premium_multiplier <- 1.2
    }
    realistic_cost <- original_effort * monthly_wage * premium_multiplier
  } else {
    if (final_people >= 6) {
      coordination_premium <- 1.1
    }
    realistic_cost <- original_effort * monthly_wage * coordination_premium
  }

  average_monthly_cost <- if (final_schedule > 0) realistic_cost / final_schedule else 0

  # --- Confidence intervals (~+/-30% COCOMO II accuracy) ---
  confidence_interval <- list(
    low = round(realistic_cost * 0.70),
    high = round(realistic_cost * 1.30)
  )

  # --- Maintenance cost estimation ---
  maintenance <- NULL
  if (maintenance_years > 0) {
    annual_maintenance <- realistic_cost * maintenance_rate
    # Compound 5% annual turnover factor
    yearly_costs <- numeric(maintenance_years)
    for (yr in seq_len(maintenance_years)) {
      yearly_costs[yr] <- annual_maintenance * (1.05 ^ (yr - 1))
    }
    total_maintenance <- sum(yearly_costs)
    tco <- realistic_cost + total_maintenance
    maintenance <- list(
      annual_maintenance = round(annual_maintenance),
      maintenance_years = maintenance_years,
      maintenance_rate = maintenance_rate,
      yearly_costs = round(yearly_costs),
      total_maintenance = round(total_maintenance),
      tco = round(tco)
    )
  }

  # --- Multiplier breakdown for waterfall chart ---
  multiplier_breakdown <- list(
    base_effort = round(base_effort, 2),
    EM_experience = EM_experience,
    EM_reuse = EM_reuse,
    EM_tools = EM_tools,
    EM_modern = EM_modern,
    EM_rely = EM_rely,
    EM_cplx = EM_cplx,
    EM_ruse = EM_ruse,
    EM_pcon = EM_pcon,
    EM_apex = EM_apex,
    EM_total = EM_total
  )

  list(
    code_lines = code_lines,
    effort_person_months = round(effort, 2),
    schedule_months = round(schedule, 2),
    people_required = round(people, 2),
    estimated_cost_usd = round(cost),
    realistic_cost_usd = round(realistic_cost),
    final_people = round(final_people, 2),
    final_schedule_months = round(final_schedule, 2),
    premium_multiplier = premium_multiplier,
    coordination_premium = coordination_premium,
    average_monthly_cost = round(average_monthly_cost),
    confidence_interval = confidence_interval,
    maintenance = maintenance,
    multiplier_breakdown = multiplier_breakdown,
    params = list(
      complexity = complexity,
      team_experience = team_experience,
      reuse_factor = reuse_factor,
      tool_support = tool_support,
      avg_wage = avg_wage,
      max_team_size = max_team_size,
      max_schedule_months = max_schedule_months,
      rely = rely,
      cplx = cplx,
      ruse = ruse,
      pcon = pcon,
      apex = apex,
      maintenance_rate = maintenance_rate,
      maintenance_years = maintenance_years
    )
  )
}


#' Print a Shiny cost estimation report in scc-style format
#' @param result Output from estimate_shiny_cost()
print_shiny_cost_report <- function(result) {
  cat("\n-----------------------------------------------------------------------\n")
  cat(sprintf("%-25s %12s\n", "Metric", "Value"))
  cat("-----------------------------------------------------------------------\n")
  cat(sprintf("%-25s %12d\n", "Total Code Lines", result$code_lines))
  cat(sprintf("%-25s %12.2f\n", "Effort (person-months)", result$effort_person_months))
  cat(sprintf("%-25s %12.2f\n", "Schedule (months)", result$final_schedule_months))
  cat(sprintf("%-25s %12.2f\n", "People Required", result$final_people))
  cat(sprintf("%-25s $%11s\n", "Estimated Cost (USD)", format(result$realistic_cost_usd, big.mark=",")))
  if (!is.null(result$confidence_interval)) {
    cat(sprintf("%-25s $%s - $%s\n", "Confidence Range",
                format(result$confidence_interval$low, big.mark=","),
                format(result$confidence_interval$high, big.mark=",")))
  }
  cat("-----------------------------------------------------------------------\n")
  cat("Parameters Used:\n")
  cat(sprintf("  Complexity:        %s\n", result$params$complexity))
  cat(sprintf("  Team Experience:   %s\n", result$params$team_experience))
  cat(sprintf("  Reuse Factor:      %.2f\n", result$params$reuse_factor))
  cat(sprintf("  Tool Support:      %.2f\n", result$params$tool_support))
  if (result$premium_multiplier > 1.0) {
    cat(sprintf("  Schedule Premium:  +%.0f%%\n", (result$premium_multiplier - 1.0) * 100))
  }
  if (result$coordination_premium > 1.0) {
    cat(sprintf("  Coordination:      +%.0f%%\n", (result$coordination_premium - 1.0) * 100))
  }
  if (!is.null(result$maintenance)) {
    cat("-----------------------------------------------------------------------\n")
    cat("Maintenance & TCO:\n")
    cat(sprintf("  Annual Maintenance:  $%s\n", format(result$maintenance$annual_maintenance, big.mark=",")))
    cat(sprintf("  Maintenance Years:   %d\n", result$maintenance$maintenance_years))
    cat(sprintf("  Total Maintenance:   $%s\n", format(result$maintenance$total_maintenance, big.mark=",")))
    cat(sprintf("  Total Cost (TCO):    $%s\n", format(result$maintenance$tco, big.mark=",")))
  }
  cat("-----------------------------------------------------------------------\n\n")
}

# Example usage:
# result <- estimate_shiny_cost(35000, complexity = "medium", team_experience = 4, reuse_factor = 0.9, tool_support = 0.9)
# print_shiny_cost_report(result)
