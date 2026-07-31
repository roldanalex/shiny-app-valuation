# Getting Started — Shiny Cost Estimator (v2.0.0)

A five-minute path from clone to first estimate. For full documentation see
[README.md](README.md); for hosting see [DEPLOYMENT.md](DEPLOYMENT.md).

## 1. Install dependencies

```r
install.packages(c("shiny", "bslib", "plotly", "DT", "markdown", "jsonlite",
                   "quarto", "ggplot2", "knitr", "ragg"))
```

For PDF reports, also install the [Quarto CLI](https://quarto.org/docs/get-started/)
(version ≥ 1.3 — Typst is bundled, no LaTeX or Chrome needed).

Verify everything:

```r
source("cost-estimator-app/check_dependencies.R")
```

## 2. Run the app

```r
# From the repository root
shiny::runApp("cost-estimator-app")
```

## 3. Your first estimate

1. Open the **Analyze** tab.
2. Keep **Manual Entry** selected and type some line counts (e.g. R: 15000,
   JavaScript: 3000, CSS: 2000).
3. Adjust **Complexity**, **Team Experience**, and **Average Annual Wage** —
   every parameter has a `?` button explaining what it means.
4. Click **Run Analysis**.

You'll get the hero estimate with its ±30% range, KPI cards, and four charts
(language treemap, cost waterfall, driver impact, schedule/cost tradeoff).
Set **Maintenance Years** > 0 in the sidebar to unlock the TCO analysis.

## 4. Analyze a real repository

- **Local Folder** (local runs only): point at any project directory.
- **ZIP Upload**: works everywhere, max 50 MB.

Documentation and config files (Markdown, JSON, YAML, …) are counted and shown
but **excluded from the billable estimate**.

## 5. Share the result

- **PDF Report** — one click in the summary strip or the Export tab produces a
  branded, client-ready PDF (cover, charts, assumptions, methodology).
- **Shareable URL** — pre-fills Manual Entry parameters for a colleague.
- **CSV / JSON** — raw data downloads.

## 6. Deploy

```bash
Rscript tools/deploy.R   # syncs engine copies, deploys to shinyapps.io
```

See [DEPLOYMENT.md](DEPLOYMENT.md) for shinyapps.io setup, the Quarto/Typst
PDF notes, and other hosting options.
