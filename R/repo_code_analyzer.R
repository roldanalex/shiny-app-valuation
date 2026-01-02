# Repository Code Analyzer (scc-style report in R)
# Usage: source this file and call analyze_repo_code(path = ".", avg_wage = 105000)

#' Analyze code in a repository and generate an scc-style report
#' @param path Path to repository root (default: current directory)
#' @param avg_wage Average annual wage for cost estimation (default: 105000)
#' @param complexity Project complexity: "low", "medium", or "high" (default: "medium")
#' @param team_experience Team experience level 1-5 (default: 4)
#' @param reuse_factor Code reuse factor 0.7-1.3 (default: 1.0)
#' @param tool_support Tool support quality 0.8-1.2 (default: 1.0)
#' @param max_team_size Maximum team size constraint (default: 5)
#' @param max_schedule_months Maximum schedule constraint in months (default: 24)
#' @return Data frame with file statistics by language
analyze_repo_code <- function(
  path = ".",
  avg_wage = 105000,
  complexity = "medium",
  team_experience = 4,
  reuse_factor = 1.0,
  tool_support = 1.0,
  max_team_size = 5,
  max_schedule_months = 24
) {
  # Language mappings by file extension
  lang_map <- list(
    ".R" = "R",
    ".r" = "R",
    ".js" = "JavaScript",
    ".jsx" = "JavaScript",
    ".ts" = "TypeScript",
    ".tsx" = "TypeScript",
    ".css" = "CSS",
    ".scss" = "Sass",
    ".sass" = "Sass",
    ".html" = "HTML",
    ".htm" = "HTML",
    ".md" = "Markdown",
    ".Rmd" = "Markdown",
    ".qmd" = "Markdown",
    ".yml" = "YAML",
    ".yaml" = "YAML",
    ".json" = "JSON",
    ".xml" = "XML",
    ".svg" = "SVG",
    ".py" = "Python",
    ".tex" = "TeX",
    ".sh" = "Shell",
    ".txt" = "Plain Text",
    ".LICENSE" = "License",
    ".c" = "C",
    ".cpp" = "C++",
    ".h" = "C Header",
    ".java" = "Java",
    ".sql" = "SQL"
  )
  
  # Comment patterns by language
  comment_patterns <- list(
    "R" = c("^\\s*#"),
    "JavaScript" = c("^\\s*//", "^\\s*/\\*", "^\\s*\\*"),
    "TypeScript" = c("^\\s*//", "^\\s*/\\*", "^\\s*\\*"),
    "CSS" = c("^\\s*/\\*", "^\\s*\\*"),
    "Sass" = c("^\\s*//", "^\\s*/\\*", "^\\s*\\*"),
    "HTML" = c("^\\s*<!--"),
    "Python" = c("^\\s*#"),
    "Shell" = c("^\\s*#"),
    "SQL" = c("^\\s*--", "^\\s*/\\*", "^\\s*\\*"),
    "C" = c("^\\s*//", "^\\s*/\\*", "^\\s*\\*"),
    "C++" = c("^\\s*//", "^\\s*/\\*", "^\\s*\\*"),
    "Java" = c("^\\s*//", "^\\s*/\\*", "^\\s*\\*")
  )

  # Get all files recursively, excluding common non-code directories
  all_files <- list.files(
    path,
    recursive = TRUE,
    full.names = TRUE,
    include.dirs = FALSE
  )

  # Exclude directories we don't want to count
  exclude_patterns <- c(
    "/\\.git/", "/\\.Rproj\\.user/", "/node_modules/", 
    "/\\.venv/", "/venv/", "/__pycache__/", "/\\.DS_Store$",
    "/\\.Rhistory$", "/\\.RData$", "/packrat/", "/renv/"
  )

  for (pattern in exclude_patterns) {
    all_files <- all_files[!grepl(pattern, all_files)]
  }

  # Analyze each file
  results <- lapply(all_files, function(file) {
    # Get file extension
    ext <- tolower(tools::file_ext(file))
    if (ext == "") {
      # Check if it's a LICENSE file
      if (grepl("LICENSE|LICENCE", basename(file), ignore.case = TRUE)) {
        ext <- ".LICENSE"
      } else {
        ext <- paste0(".", basename(file))
      }
    } else {
      ext <- paste0(".", ext)
    }

    # Map to language
    language <- lang_map[[ext]]
    if (is.null(language)) {
      language <- "Other"
    }

    # Try to read file
    lines <- tryCatch(
      readLines(file, warn = FALSE, encoding = "UTF-8"),
      error = function(e) character(0)
    )

    if (length(lines) == 0) {
      return(NULL)
    }
  
    # Count lines
    total_lines <- length(lines)
    blank_lines <- sum(grepl("^\\s*$", lines))
    
    # Count comments
    comment_lines <- 0
    patterns <- comment_patterns[[language]]
    if (!is.null(patterns)) {
      for (pattern in patterns) {
        comment_lines <- comment_lines + sum(grepl(pattern, lines))
      }
    }
    
    # Code lines
    code_lines <- total_lines - blank_lines - comment_lines
    
    # Rough complexity estimate (count of function/class definitions, loops, conditionals)
    complexity_count <- 0
    if (language == "R") {
      complexity_count <- sum(grepl("function\\s*\\(|for\\s*\\(|while\\s*\\(|if\\s*\\(", lines))
    } else if (language %in% c("JavaScript", "TypeScript")) {
      complexity_count <- sum(grepl("function\\s+|=>|for\\s*\\(|while\\s*\\(|if\\s*\\(|class\\s+", lines))
    } else if (language == "Python") {
      complexity_count <- sum(grepl("def\\s+|class\\s+|for\\s+|while\\s+|if\\s+", lines))
    }
    
    # Get file size
    file_size <- file.info(file)$size
    
    data.frame(
      Language = language,
      File = file,
      Lines = total_lines,
      Blanks = blank_lines,
      Comments = comment_lines,
      Code = code_lines,
      Complexity = complexity_count,
      Bytes = file_size,
      stringsAsFactors = FALSE
    )
  })
  
  # Combine results
  results <- do.call(rbind, results[!sapply(results, is.null)])
  
  if (is.null(results) || nrow(results) == 0) {
    cat("No files found to analyze.\n")
    return(invisible(NULL))
  }
  
  # Aggregate by language
  lang_summary <- aggregate(
    cbind(Lines, Blanks, Comments, Code, Complexity, Bytes) ~ Language,
    data = results,
    FUN = sum
  )
  
  # Count files per language
  file_counts <- aggregate(
    File ~ Language,
    data = results,
    FUN = length
  )
  names(file_counts)[2] <- "Files"
  
  # Merge
  lang_summary <- merge(file_counts, lang_summary, by = "Language")
  
  # Sort by code lines descending
  lang_summary <- lang_summary[order(-lang_summary$Code), ]
  
  # Calculate totals
  totals <- data.frame(
    Language = "Total",
    Files = sum(lang_summary$Files),
    Lines = sum(lang_summary$Lines),
    Blanks = sum(lang_summary$Blanks),
    Comments = sum(lang_summary$Comments),
    Code = sum(lang_summary$Code),
    Complexity = sum(lang_summary$Complexity),
    Bytes = sum(lang_summary$Bytes)
  )
  
  # Print report
  cat("\n───────────────────────────────────────────────────────────────────────────────\n")
  cat(sprintf("%-20s %9s %9s %9s %9s %9s %10s\n", 
              "Language", "Files", "Lines", "Blanks", "Comments", "Code", "Complexity"))
  cat("───────────────────────────────────────────────────────────────────────────────\n")
  
  for (i in 1:nrow(lang_summary)) {
    cat(sprintf("%-20s %9d %9d %9d %9d %9d %10d\n",
                lang_summary$Language[i],
                lang_summary$Files[i],
                lang_summary$Lines[i],
                lang_summary$Blanks[i],
                lang_summary$Comments[i],
                lang_summary$Code[i],
                lang_summary$Complexity[i]))
  }
  
  cat("───────────────────────────────────────────────────────────────────────────────\n")
  cat(sprintf("%-20s %9d %9d %9d %9d %9d %10d\n",
              totals$Language,
              totals$Files,
              totals$Lines,
              totals$Blanks,
              totals$Comments,
              totals$Code,
              totals$Complexity))
  cat("───────────────────────────────────────────────────────────────────────────────\n")
  
  # Calculate cost using COCOMO II
  # Try to find the estimator in common locations
  estimator_paths <- c(
    "sandbox/shiny_cost_estimator.R",
    file.path(path, "sandbox/shiny_cost_estimator.R"),
    file.path(dirname(path), "sandbox/shiny_cost_estimator.R")
  )
  
  estimator_path <- NULL
  for (p in estimator_paths) {
    if (file.exists(p)) {
      estimator_path <- p
      break
    }
  }
  
  if (!is.null(estimator_path)) {
    source(estimator_path, local = TRUE)
    
    # Build language mix for productivity weighting
    language_mix <- setNames(lang_summary$Code, lang_summary$Language)
    
    # Use total code lines for estimation
    cost_result <- estimate_shiny_cost(
      code_lines = totals$Code,
      complexity = complexity,
      team_experience = team_experience,
      reuse_factor = reuse_factor,
      tool_support = tool_support,
      language_mix = language_mix
    )
    
    # Adjust cost based on wage
    monthly_wage <- avg_wage / 12
    
    # Apply realistic constraints for small team development
    original_people <- cost_result$people_required
    original_schedule <- cost_result$schedule_months
    original_effort <- cost_result$effort_person_months
    
    # Hard constraints: max 8 people, max 24 months
    max_realistic_people <- 8
    max_realistic_schedule <- max_schedule_months  # Default 24 months
    
    # Calculate what's needed without constraints
    unconstrained_people <- min(original_people, max_team_size)
    unconstrained_schedule <- original_effort / unconstrained_people
    
    # Apply hard constraints
    final_people <- min(unconstrained_people, max_realistic_people)
    natural_schedule <- original_effort / final_people
    final_schedule <- min(natural_schedule, max_realistic_schedule)
    
    # Determine if we need cost adjustments
    monthly_wage <- avg_wage / 12
    
    if (natural_schedule > max_realistic_schedule) {
      # Schedule is constrained - need aggressive approach
      # Calculate premium based on how much we're compressing
      compression_ratio <- natural_schedule / final_schedule
      
      # Aggressive premium for compressed timelines
      if (compression_ratio >= 4) {
        premium_multiplier <- 2.0  # 100% premium for 4x+ compression
      } else if (compression_ratio >= 3) {
        premium_multiplier <- 1.7  # 70% premium for 3x compression
      } else if (compression_ratio >= 2) {
        premium_multiplier <- 1.4  # 40% premium for 2x compression
      } else {
        premium_multiplier <- 1.2  # 20% premium for mild compression
      }
      
      premium_monthly_wage <- monthly_wage * premium_multiplier
      final_cost <- original_effort * premium_monthly_wage
      
      cat(sprintf("Estimated Cost to Develop (realistic) $%s\n", 
                  format(round(final_cost), big.mark = ",")))
      cat(sprintf("Estimated Schedule Effort (realistic) %.1f months (%.1f years)\n", 
                  final_schedule, final_schedule / 12))
      cat(sprintf("Estimated People Required (realistic) %.0f people", round(final_people)))
      
      if (final_people > 5) {
        cat(sprintf(" (%.0f core + %.0f contractors)\n", 5, round(final_people - 5)))
      } else {
        cat("\n")
      }
      
      cat("\nRealistic Project Breakdown:\n")
      cat(sprintf("  • Total effort required: %.0f person-months\n", original_effort))
      cat(sprintf("  • Team size: %.0f people (max allowed: %d)\n", round(final_people), max_realistic_people))
      cat(sprintf("  • Timeline: %.1f months (max allowed: %d months)\n", 
                  final_schedule, max_realistic_schedule))
      cat(sprintf("  • Cost premium: +%.0f%% for aggressive timeline\n",
                  (premium_multiplier - 1.0) * 100))
      cat(sprintf("  • Premium covers: Senior/expert engineers, overtime, consultants, accelerated tooling\n"))
      cat(sprintf("  • Average monthly cost: $%s/month\n", 
                  format(round(final_cost / final_schedule), big.mark = ",")))
      
      # Show what unconstrained would look like
      if (natural_schedule > max_realistic_schedule * 1.5) {
        base_cost <- original_effort * monthly_wage
        cat(sprintf("\n  Note: Without timeline constraints:\n"))
        cat(sprintf("    • Natural timeline would be: %.1f months (%.1f years)\n", 
                    natural_schedule, natural_schedule / 12))
        cat(sprintf("    • Base cost (no premium): $%s\n",
                    format(round(base_cost), big.mark = ",")))
        cat(sprintf("    • Compression ratio: %.1fx faster delivery\n", compression_ratio))
      }

    } else {
      # Schedule fits within constraints
      adjusted_cost <- original_effort * monthly_wage

      # Apply mild premium if using large team (6-8 people need coordination)
      if (final_people >= 6) {
        coordination_premium <- 1.1  # 10% premium for coordination overhead
        adjusted_cost <- adjusted_cost * coordination_premium
      } else {
        coordination_premium <- 1.0
      }

      cat(sprintf("Estimated Cost to Develop (realistic) $%s\n", 
                  format(round(adjusted_cost), big.mark = ",")))
      cat(sprintf("Estimated Schedule Effort (realistic) %.1f months (%.1f years)\n", 
                  final_schedule, final_schedule / 12))
      cat(sprintf("Estimated People Required (realistic) %.0f people\n", round(final_people)))

      cat("\nRealistic Project Breakdown:\n")
      cat(sprintf("  • Total effort required: %.0f person-months\n", original_effort))
      cat(sprintf("  • Team size: %.0f people\n", round(final_people)))
      cat(sprintf("  • Timeline: %.1f months (%.1f years)\n", 
                  final_schedule, final_schedule / 12))

      if (coordination_premium > 1.0) {
        cat(sprintf("  • Coordination overhead: +%.0f%% for team size\n",
                    (coordination_premium - 1.0) * 100))
      }

      cat(sprintf("  • Average monthly cost: $%s/month\n", 
                  format(round(adjusted_cost / final_schedule), big.mark = ",")))
    }
  } else {
    # Fallback: use basic COCOMO formula
    KLOC <- totals$Code / 1000
    effort <- 2.94 * (KLOC ^ 1.12)
    schedule <- 3.67 * (effort ^ 0.30)
    people <- effort / schedule
    cost <- effort * (avg_wage / 12)

    cat(sprintf("Estimated Cost to Develop (organic) $%s\n", 
                format(round(cost), big.mark = ",")))
    cat(sprintf("Estimated Schedule Effort (organic) %.2f months\n", schedule))
    cat(sprintf("Estimated People Required (organic) %.2f\n", people))
  }

  cat("───────────────────────────────────────────────────────────────────────────────\n")
  cat(sprintf("Processed %s bytes, %.3f megabytes (SI)\n", 
              format(totals$Bytes, big.mark = ","),
              totals$Bytes / 1000000))
  cat("───────────────────────────────────────────────────────────────────────────────\n\n")

  invisible(lang_summary)
}

# Example usage:
# analyze_repo_code(".", avg_wage = 105000, complexity = "medium", team_experience = 4)
# analyze_repo_code("/path/to/other/repo", avg_wage = 120000)
