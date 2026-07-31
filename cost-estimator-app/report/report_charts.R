# Static ggplot2 versions of the app's key charts for the PDF report.
# Colors arrive in the payload (d$colors) straight from modules/theme.R,
# so the report always matches the app brand.

library(ggplot2)

report_theme <- function(colors) {
  theme_minimal(base_size = 11) +
    theme(
      text = element_text(color = colors$ink),
      axis.text = element_text(color = colors$ink_muted, size = 8.5),
      axis.title = element_text(color = colors$ink_muted, size = 9),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(color = colors$border, linewidth = 0.3),
      plot.title = element_text(size = 11, face = "bold", color = colors$ink),
      plot.title.position = "plot",
      legend.position = "bottom",
      legend.text = element_text(size = 8.5)
    )
}

fmt_usd <- function(x) paste0("$", format(round(x), big.mark = ",", scientific = FALSE))

# Waterfall of COCOMO multipliers ending at the final cost
gg_waterfall <- function(e, colors) {
  mb <- e$multiplier_breakdown
  rate <- e$params$avg_wage / 12

  steps <- list(list(name = "Base Effort", val = NA, abs = mb$base_effort * rate))
  ems <- list(
    "Experience" = mb$EM_experience, "Reuse" = mb$EM_reuse,
    "Tools" = mb$EM_tools, "Modern Framework" = mb$EM_modern,
    "Reliability" = mb$EM_rely, "Complexity" = mb$EM_cplx,
    "Reusability" = mb$EM_ruse, "Personnel" = mb$EM_pcon,
    "App Experience" = mb$EM_apex
  )
  always <- c("Experience", "Reuse", "Tools", "Modern Framework")

  running <- mb$base_effort * rate
  df <- data.frame(name = "Base Effort", start = 0, end = running,
                   type = "total", stringsAsFactors = FALSE)
  for (nm in names(ems)) {
    v <- ems[[nm]]
    if (!(nm %in% always) && v == 1.0) next
    delta <- running * (v - 1)
    df <- rbind(df, data.frame(name = nm, start = running, end = running + delta,
                               type = if (delta >= 0) "increase" else "decrease"))
    running <- running + delta
  }
  if (e$compression_penalty > 1.0) {
    delta <- running * (e$compression_penalty - 1)
    df <- rbind(df, data.frame(name = "Schedule Compression", start = running,
                               end = running + delta, type = "increase"))
    running <- running + delta
  }
  if (e$coordination_premium > 1.0) {
    delta <- running * (e$coordination_premium - 1)
    df <- rbind(df, data.frame(name = "Coordination", start = running,
                               end = running + delta, type = "increase"))
    running <- running + delta
  }
  df <- rbind(df, data.frame(name = "Final Cost", start = 0, end = e$cost_usd,
                             type = "total"))
  df$name <- factor(df$name, levels = df$name)

  ggplot(df, aes(x = name)) +
    geom_rect(aes(xmin = as.numeric(name) - 0.38, xmax = as.numeric(name) + 0.38,
                  ymin = pmin(start, end), ymax = pmax(start, end), fill = type)) +
    scale_fill_manual(values = c(total = colors$primary,
                                 increase = colors$negative,
                                 decrease = colors$positive), guide = "none") +
    scale_y_continuous(labels = scales::label_dollar(scale_cut = scales::cut_short_scale())) +
    labs(title = "Cost Breakdown: COCOMO II Multipliers", x = NULL, y = NULL) +
    report_theme(colors) +
    theme(axis.text.x = element_text(angle = 35, hjust = 1))
}

# Tornado of per-driver cost impact
gg_driver_tornado <- function(e, colors) {
  mb <- e$multiplier_breakdown
  base_total <- mb$base_effort * (e$params$avg_wage / 12)
  drivers <- c(
    "Experience" = mb$EM_experience, "Reuse Factor" = mb$EM_reuse,
    "Tool Support" = mb$EM_tools, "Modern Framework" = mb$EM_modern,
    "Reliability" = mb$EM_rely, "Product Complexity" = mb$EM_cplx,
    "Reusability" = mb$EM_ruse, "Personnel Continuity" = mb$EM_pcon,
    "App Experience" = mb$EM_apex
  )
  deltas <- vapply(drivers, function(v) base_total * (mb$EM_total - mb$EM_total / v),
                   numeric(1))
  df <- data.frame(name = names(deltas), delta = deltas)
  df <- df[order(abs(df$delta)), ]
  df$name <- factor(df$name, levels = df$name)

  ggplot(df, aes(x = delta, y = name, fill = delta > 0)) +
    geom_col(width = 0.7) +
    scale_fill_manual(values = c(`TRUE` = colors$negative, `FALSE` = colors$positive),
                      guide = "none") +
    scale_x_continuous(labels = scales::label_dollar(scale_cut = scales::cut_short_scale())) +
    labs(title = "What's Driving Your Cost?", x = "Cost delta (USD)", y = NULL) +
    report_theme(colors)
}

# Schedule vs cost tradeoff curve with the current estimate marked
gg_schedule_curve <- function(curve, e, colors) {
  ggplot(curve, aes(x = schedule, y = cost)) +
    geom_line(color = colors$primary, linewidth = 0.9) +
    geom_point(data = data.frame(schedule = e$final_schedule_months,
                                 cost = e$cost_usd),
               color = colors$negative, size = 3) +
    annotate("text", x = e$final_schedule_months, y = e$cost_usd,
             label = "  Current estimate", hjust = 0, vjust = -0.8,
             size = 3, color = colors$ink) +
    scale_y_continuous(labels = scales::label_dollar(scale_cut = scales::cut_short_scale())) +
    labs(title = "Schedule vs. Cost Tradeoff",
         x = "Maximum schedule (months)", y = NULL) +
    report_theme(colors)
}

# Cumulative TCO area chart (nominal)
gg_tco <- function(e, colors) {
  m <- e$maintenance
  if (is.null(m)) return(NULL)
  years <- 0:m$maintenance_years
  cumulative <- c(0, cumsum(m$yearly_costs)) + e$cost_usd
  df <- data.frame(year = years, tco = cumulative)

  ggplot(df, aes(x = year, y = tco)) +
    geom_area(fill = colors$primary, alpha = 0.12) +
    geom_line(color = colors$primary, linewidth = 0.9) +
    geom_point(color = colors$primary, size = 2) +
    scale_x_continuous(breaks = years) +
    scale_y_continuous(labels = scales::label_dollar(scale_cut = scales::cut_short_scale())) +
    labs(title = "Cumulative Cost of Ownership (nominal)",
         x = "Year", y = NULL) +
    report_theme(colors)
}
