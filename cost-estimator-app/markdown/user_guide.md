## Overview

The Shiny Cost Estimator uses the **COCOMO II** (Constructive Cost Model) methodology to estimate the cost, schedule, team size, and budget required for software projects. It analyzes your codebase or accepts manual line counts, then applies industry-standard parametric models to produce realistic estimates.

**What it estimates:**

- Development cost (USD)
- Schedule duration (months)
- Team size (people)
- Confidence intervals (+/- 30%)
- Maintenance costs and Total Cost of Ownership (TCO)

---

## Analysis Modes

All three input methods are available from the single **Analyze** tab. Use the selector at the top of the sidebar to switch between them.

### Local Folder

Best for analyzing projects on your local machine.

> **Note:** Local Folder is only available when running the app locally (e.g., from RStudio or `shiny::runApp()`). On the hosted version (shinyapps.io), use **ZIP Upload** or **Manual Entry** instead.

1. Navigate to the **Analyze** tab
2. Select **Local Folder** in the sidebar selector
3. Enter or browse to the repository path
4. Adjust project settings in the sidebar
5. Click **Run Analysis**
6. Review results in the sub-tabs on the right

### ZIP Upload

Best for analyzing projects on a deployed server or when sharing with others.

1. Navigate to the **Analyze** tab
2. Select **ZIP Upload** in the sidebar selector
3. Click **Browse** and select a `.zip` file of your repository (max 50 MB)
4. Adjust project settings in the sidebar
5. Click **Run Analysis**
6. Review results in the sub-tabs on the right

### Manual Entry

Best for quick estimates when you already know your line counts.

1. Navigate to the **Analyze** tab
2. Select **Manual Entry** in the sidebar selector
3. Enter code lines per language (R, Python, JavaScript, SQL, CSS, Other)
4. Adjust project settings in the sidebar
5. Click **Run Analysis**
6. Review results in the sub-tabs on the right

---

## Sidebar Parameters

| Parameter | Range | Default | Description |
|---|---|---|---|
| Complexity | Low / Medium / High | Medium | Architectural complexity of the project |
| Team Experience | 1 (Novice) - 5 (Expert) | 4 | Average team skill level |
| Reuse Factor | 0.70 - 1.30 | 1.00 | Code reuse (lower = more reuse) |
| Tool Support | 0.80 - 1.20 | 1.00 | Quality of dev tooling (lower = better) |
| Average Annual Wage | $50K - $300K | $105K | Average developer salary |
| Max Team Size | 1 - 10 | 5 | Maximum team members allowed |
| Max Schedule | 3 - 36 months | 24 | Maximum project duration |

---

## Advanced COCOMO Drivers

Expand the **Advanced COCOMO Drivers** section in the sidebar to fine-tune the model:

| Driver | Range | Default | What it controls |
|---|---|---|---|
| Required Reliability (RELY) | 0.82 - 1.26 | 1.00 | Cost of software failure |
| Product Complexity (CPLX) | 0.73 - 1.74 | 1.00 | Algorithmic and control complexity |
| Required Reusability (RUSE) | 0.95 - 1.24 | 1.00 | Effort to build reusable components |
| Personnel Continuity (PCON) | 0.81 - 1.29 | 1.00 | Impact of team turnover |
| Application Experience (APEX) | 0.81 - 1.22 | 1.00 | Team familiarity with the domain |

Values above 1.0 increase effort; values below 1.0 decrease effort.

---

## Maintenance & TCO

Expand the **Maintenance & TCO** section in the sidebar:

- **Annual Maintenance Rate**: Percentage of build cost spent on maintenance per year (default: 20%)
- **Maintenance Years**: Number of years to project (default: 0 = disabled)

When enabled, the Maintenance sub-tab shows annual costs (with 5% compounding for knowledge turnover) and the Total Cost of Ownership (build + total maintenance).

---

## Understanding Results

Results appear in five sub-tabs:

### Results

KPI value boxes showing estimated cost, schedule, team size, and cost range (confidence interval). Below these are four charts:

- **Code Distribution by Language** — a treemap showing the share of code lines per language
- **Cost Breakdown: COCOMO II Multipliers** — a waterfall chart showing how each effort multiplier adds or removes cost from the base estimate
- **What's Driving Your Cost?** — a horizontal bar chart ranking each driver by its dollar impact (red = adds cost, green = saves cost)
- **Schedule vs. Cost Tradeoff** — a curve showing how changing the max schedule deadline affects the total cost

Each chart card has a full-screen expand icon in the top-right corner. A persistent summary strip at the bottom of the page always shows the key metrics (cost, schedule, team, confidence range).

### Details

- **Language breakdown** treemap (for repo analyses)
- **Detailed parameters table** showing all inputs and calculated values

### Sensitivity

Interactive chart showing how the estimate changes as you vary complexity and team experience while holding other parameters constant.

### Maintenance & TCO

Visible when maintenance years > 0. Shows:

- Build cost, total maintenance, and TCO value boxes
- **Cumulative TCO Over Time** — a line chart showing year-by-year growth in total spend, with a break-even annotation when cumulative maintenance equals the build cost
- **TCO at Different Maintenance Rates** — a bar chart comparing total cost of ownership across maintenance rate scenarios

---

## Compare

The **Compare** tab lets you evaluate up to 3 scenarios side-by-side. Each scenario has its own set of parameters including a tool support slider. Enter code lines and settings for each scenario, then click **Run Comparison** to see results in a comparative table.

---

## Export & Sharing

The **Export** tab provides:

- **Shareable URL**: Generates a link with pre-filled Manual Entry parameters that you can send to colleagues
- **CSV Export**: Download results as a spreadsheet-ready file
- **JSON Export**: Download results in JSON format for programmatic use

Note: Shareable URLs only work with Manual Entry parameters.
