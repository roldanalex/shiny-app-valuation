# Shiny Cost Estimator — Interactive App

A client-facing R Shiny application that estimates the development cost, schedule, and team size of software projects using a calibrated **COCOMO II.2000** model — and produces a **branded PDF report** your users can send out.

**Version 2.0.0** · Light professional theme · Quarto + Typst PDF reports · shinyapps.io-ready

---

## Quick Start

```r
# From the repository root
shiny::runApp("cost-estimator-app")

# Or with the launcher
Rscript cost-estimator-app/run_app.R
```

Check dependencies first:

```r
source("cost-estimator-app/check_dependencies.R")
```

Required: `shiny`, `bslib`, `plotly`, `DT`, `markdown`, `jsonlite`, `quarto`, `ggplot2`, `knitr`, `ragg` — plus the [Quarto CLI](https://quarto.org) ≥ 1.3 for PDF reports (Typst is bundled with Quarto; no LaTeX or Chrome needed).

---

## The App

Four tabs:

| Tab | What it does |
|---|---|
| **Home** | Live demo estimate and quick-start links |
| **Analyze** | The workhorse — pick an input method (Local Folder / ZIP Upload / Manual Entry), set parameters, run the analysis |
| **Compare** | Up to 3 scenarios side-by-side with shared wage/schedule so dollars stay comparable |
| **Export** | PDF report, shareable URL, CSV/JSON downloads |

The **Analyze** results area has four sub-tabs: Results (hero estimate + KPI cards + four charts), Details (language table + text report), Sensitivity, and Maintenance & TCO. A persistent summary strip keeps the key numbers and a **PDF Report** button visible while you scroll.

In-app help: a **How to Use** navbar button opens a task-oriented user manual (`markdown/app_manual.md`) written for non-technical users, alongside the **User Guide** (parameter reference) and **Release Notes**. Every sidebar parameter also has its own `?` explainer.

### Input methods

- **Local Folder** — scans a project directory (hidden on deployed servers)
- **ZIP Upload** — upload a repository ZIP (max 50 MB)
- **Manual Entry** — type line counts per language

Repository scans classify documentation and config files (Markdown, JSON, YAML, SVG, …) as **non-billable**: they are shown in the treemap and details table but never inflate the estimate.

---

## The Model

```
Effort = 2.94 × KLOC^B × EM_total × 0.85
```

- `KLOC` — thousands of productivity-weighted billable code lines
- `B` — 1.02 / 1.10 / 1.18 for low / medium / high complexity
- `EM_total` — product of effort multipliers (experience, reuse, tools, RELY, CPLX, RUSE, PCON, APEX)
- `0.85` — documented calibration for modern high-level frameworks
- Schedule: `TDEV = 3.67 × Effort^D`, `D = 0.28 + 0.2 × (B − 0.91)` (COCOMO II.2000)
- Schedule compression: smooth premium `ratio^1.25` capped at 2.0×; infeasible plans are flagged
- Cost = effort × (annual wage ÷ 12); teams ≥ 6 carry a 10% coordination overhead
- The ±30% band is an **estimate range** (typical COCOMO II accuracy), not a statistical confidence interval
- TCO: maintenance escalates 5%/yr and is discounted to present value (default 5%/yr)

The displayed numbers are internally consistent: **effort = team × schedule**, and the waterfall chart totals exactly the headline cost.

## PDF Report

The Export tab (and the summary strip) generates a 4–5 page branded PDF:

1. **Cover** — logo, project name, date, headline cost + estimate range
2. **Estimate summary** — KPI row, waterfall, driver tornado
3. **Schedule & ownership** — schedule/cost curve, TCO chart, assumptions table
4. **Methodology** — formulas, constants, and what the range means

Rendered server-side with **Quarto + Typst** (`report/estimate_report.qmd`), with ggplot2 chart re-renders and bundled Inter fonts. Colors come from the same design tokens as the app.

---

## Architecture

```
cost-estimator-app/
├── app.R                     # UI + server, sources everything below
├── modules/
│   ├── theme.R               # Design tokens (single source of truth for color/type)
│   ├── app_helpers.R         # Pure input-sanitizing helpers (unit-tested)
│   ├── pdf_report.R          # Quarto render pipeline + download handlers
│   ├── analysis_module.R     # Results UI: hero, KPIs, charts, strip
│   ├── comparison_module.R   # Scenario comparison
│   ├── export_module.R       # PDF / URL / CSV / JSON exports
│   ├── shiny_cost_estimator.R  # BUILD ARTIFACT - synced copy of ../R/
│   └── repo_code_analyzer.R    # BUILD ARTIFACT - synced copy of ../R/
├── report/                   # Quarto + Typst PDF report
│   ├── estimate_report.qmd
│   ├── report_charts.R       # ggplot2 chart re-renders
│   ├── logo.svg
│   └── fonts/                # Bundled Inter (static weights)
├── www/
│   ├── custom.css            # Light theme; colors via --app-* custom properties
│   └── favicon.svg
└── markdown/                 # In-app User Guide + Release Notes
```

**Design tokens:** every color lives in `modules/theme.R` (`app_colors`). bslib reads `app_theme()`, the CSS reads generated `--app-*` variables, plotly charts read `app_colors`, and the PDF receives the same list in its payload. Change a hex once; everything follows.

**Engine sync:** the canonical model lives in `../R/`. The copies in `modules/` are build artifacts refreshed by `Rscript tools/sync_modules.R` (a test fails if they drift). Deploy with `Rscript tools/deploy.R`, which syncs first.

---

## Testing

```bash
Rscript tests/testthat.R   # from the repository root
```

~180 assertions: golden values, model invariants (effort ≡ team × schedule, cost continuity, wage linearity), input validation, analyzer billable classification, helper sanitization, a `testServer` smoke test, and an end-to-end PDF render.

## Deployment

See [DEPLOYMENT.md](DEPLOYMENT.md). Short version:

```r
# One-time
rsconnect::setAccountInfo(...)

# Every deploy (syncs engine copies, then deploys)
Rscript tools/deploy.R
```

On shinyapps.io the Local Folder input is hidden automatically and PDF rendering uses the Quarto CLI provisioned by the platform — smoke-test the PDF button after your first deploy.

---

MIT License · Created by Alexis Roldan
