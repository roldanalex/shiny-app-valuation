# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

COCOMO II-based cost estimation toolkit for R Shiny and data science projects. Estimates development effort, schedule, team size, budget, and maintenance/TCO from code line counts and project parameters. Available as R scripts, a Python CLI, and an interactive Shiny web app.

## Running the Shiny App

```bash
# Launch from project root
Rscript cost-estimator-app/run_app.R

# Or from R console
shiny::runApp("cost-estimator-app")
```

Required R packages: `shiny`, `bslib`, `plotly`, `DT`, `shinyWidgets`, `jsonlite`, `RColorBrewer`

Optional (for AI Assistant sub-tab): `ellmer`, `shinychat` + `OPENAI_API_KEY` environment variable

Check dependencies: `source("cost-estimator-app/check_dependencies.R")`

## Running Tests

```bash
Rscript tests/testthat.R
```

Requires: `testthat` package.

## Command-Line Usage

```bash
# R: Analyze a repository
Rscript -e 'source("R/repo_code_analyzer.R"); analyze_repo_code(".")'

# Python: Analyze a repository
python3 Python/repo_code_analyzer.py analyze .

# Python: Direct estimation from line count
python3 Python/repo_code_analyzer.py estimate --lines 10000 --complexity medium --team-exp 4

# Python: With maintenance projection
python3 Python/repo_code_analyzer.py estimate --lines 10000 --maintenance-years 3
```

## Architecture

### Core Estimation Engine

`R/shiny_cost_estimator.R` — Standalone COCOMO II model with realistic constraints.

Key function: `estimate_shiny_cost()` returns a list with:
- `realistic_cost_usd`, `final_people`, `final_schedule_months` — constrained estimates
- `estimated_cost_usd`, `effort_person_months`, `schedule_months`, `people_required` — raw COCOMO values
- `confidence_interval` — list with `low` and `high` (70%/130% of realistic cost)
- `maintenance` — list with `annual_maintenance`, `total_maintenance`, `tco` (NULL if maintenance_years=0)
- `multiplier_breakdown` — list with `base_effort` and all EM_* values for waterfall chart
- `premium_multiplier`, `coordination_premium`, `average_monthly_cost`
- `params` — all input parameters preserved

Parameters include: `code_lines`, `complexity`, `team_experience`, `reuse_factor`, `tool_support`, `language_mix`, `avg_wage`, `max_team_size`, `max_schedule_months`, plus COCOMO II drivers (`rely`, `cplx`, `ruse`, `pcon`, `apex`) and maintenance (`maintenance_rate`, `maintenance_years`).

`R/repo_code_analyzer.R` — Scans repositories, counts lines/comments/complexity by language (using single-pass OR to avoid double-counting), then calls the estimator. Finds `shiny_cost_estimator.R` via relative path resolution.

`Python/repo_code_analyzer.py` — Python equivalent with full feature parity: CLI (`analyze` and `estimate` subcommands), COCOMO II drivers, maintenance/TCO, confidence intervals, and export support (CSV, HTML, TXT).

### Shiny Web App (Modular Architecture)

`cost-estimator-app/app.R` — Main app file (~600 lines). Defines layout and wires up modules. Sources estimation functions from `../R/` with fallback to `modules/` for deployment.

**Modules:**
- `modules/analysis_module.R` — Shared `analysisResultsUI`/`analysisResultsServer` for value boxes, waterfall chart, language pie chart, details table, sensitivity analysis, and maintenance/TCO panel. Used by all three analysis tabs.
- `modules/comparison_module.R` — Side-by-side scenario comparison (up to 3 scenarios with tool_support param).
- `modules/export_module.R` — Shareable URL generation (with proper protocol) and CSV/JSON export.
- `modules/shiny_cost_estimator.R` — Copy of `R/shiny_cost_estimator.R` (deployment fallback).
- `modules/repo_code_analyzer.R` — Copy of `R/repo_code_analyzer.R` (deployment fallback).

**AI Assistant** (in `modules/analysis_module.R`): Optional chatbot embedded as a 5th sub-tab within each analysis module (Local Folder, ZIP, Manual), alongside Results, Details, Sensitivity, and Maintenance & TCO. Powered by `ellmer` + `shinychat`. Requires `OPENAI_API_KEY` env var. Gracefully degrades: shows install instructions if packages missing, setup instructions if no API key. Uses `gpt-4.1-nano` by default. Each tab's chat has its own context built directly from the module's `est()` reactive, so it references that specific analysis's numbers. Module namespacing ensures independent chat instances with no ID collisions.

**Important:** `modules/shiny_cost_estimator.R` and `modules/repo_code_analyzer.R` are deployment fallback copies. The app prefers `../R/` originals. When updating the R/ files, copy them to modules/ as well.

### Key Design Details

- The COCOMO II formula: effort = A * KLOC^B * EM_total, where A=2.50, B=1.02-1.18, and EM_total is the product of experience, reuse, tools, modern framework (0.85), and optional drivers (rely, cplx, ruse, pcon, apex).
- Realistic constraints cap team size at min(max_team_size, 8), schedule at max_schedule_months. Schedule compression triggers premium multipliers (1.2x-2.0x). Teams >= 6 get 1.1x coordination premium.
- Confidence intervals: +/- 30% of realistic cost.
- Maintenance: annual_maintenance = realistic_cost * maintenance_rate, compounded 5% annually for turnover. TCO = build + total_maintenance.
- Language productivity weights adjust effective KLOC (e.g., SQL at 1.3x, JavaScript at 0.9x).
- Comment counting uses single-pass OR across patterns to avoid double-counting.
- The app has six top-level tabs: Home, Local Folder, ZIP Upload, Manual Entry, Compare, and Export. The AI Assistant is embedded as a sub-tab within each analysis module.
- Test suite in `tests/testthat/` covers return structure, known-input ranges, complexity ordering, input validation, constraints, maintenance math, confidence intervals, and multiplier consistency.
