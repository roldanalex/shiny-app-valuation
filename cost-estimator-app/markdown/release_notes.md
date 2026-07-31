## v2.0.0 - July 2026

### Branded PDF Reports

- **One-click PDF report** (Export tab and summary strip) — a client-ready document with cover page, headline estimate and range, cost breakdown and driver charts, schedule/TCO analysis, assumptions table, and methodology notes
- Rendered with Quarto + Typst (no LaTeX or Chrome needed), fully compatible with shinyapps.io

### Model Corrections (COCOMO II.2000 alignment)

- Constants aligned with published COCOMO II.2000: A = 2.94, C = 3.67, and the schedule exponent now anchored at B = 0.91 (the previous 1.01 anchor systematically shortened schedules). The 15% modern-framework calibration is now applied exactly once and documented
- **Consistent numbers**: displayed effort now always equals team size × schedule, including under schedule compression
- **Smooth compression premium**: the discrete 20/40/70/100% premium ladder (which created cost cliffs of up to 42% from a one-month schedule change) is replaced by a continuous premium anchored to COCOMO II's SCED driver, capped at +100%
- **One wage rate**: the hardcoded $12k/month internal rate is gone; every figure (including the waterfall chart) now derives from your wage input
- **Honest uncertainty language**: the ±30% band is now labeled "Estimate range", not a confidence interval
- **Discounted TCO**: multi-year maintenance is reported both nominally and in present value (default 5%/yr discount rate); TCO uses present value
- **Docs excluded from billing**: Markdown, JSON, YAML, SVG, and other non-code files are shown in the analysis but no longer inflate the estimate
- Feasibility flag: when a compressed schedule would need more people than your team cap, the app says so explicitly

### Chart Fixes

- Waterfall chart now totals exactly the headline cost and includes explicit schedule-compression and coordination steps
- Driver-impact chart units corrected (bars were inflated by the schedule length)
- Sensitivity curves now include all advanced drivers and pass through your actual estimate, with a marker at your current position
- Comparison chart split into three panels (cost, schedule, team) with proper axes; shared wage/schedule inputs keep scenarios comparable

### Light Professional Redesign

- New light theme with a single design-token source of truth (`modules/theme.R` + `www/custom.css`) driving the app, all charts, and the PDF report
- Unified KPI cards replace the multicolor value boxes; the estimate range indicator now shows real low/mid/high ticks
- Language treemap uses the brand palette, with non-billable languages greyed out
- Inter typography throughout

### Robustness

- Blank or invalid Manual Entry fields no longer crash the analysis
- Shared-URL parameters are validated and bounds-checked
- 50MB upload limit actually enforced (previously capped at Shiny's 5MB default)
- Input validation added for wage, team size, schedule, and discount rate
- Test suite expanded from 59 to ~180 assertions, including golden-value and model-invariant tests

### Removed

- AI Assistant tab (client-facing deployments should not carry API-key cost/risk)

---

## v1.0.1 - February 2026

### Interactive Web App

- **Hero dashboard layout** with KPI value boxes (cost, schedule, team size, confidence range) displayed prominently at the top of each analysis view
- **Waterfall cost breakdown chart** showing how base effort flows through each multiplier (experience, reuse, tools, modern framework, COCOMO drivers) to reach the final estimate. Bars are ordered from base effort on the left to total cost on the right
- **Modular architecture** with dedicated modules for analysis results, scenario comparison, and export functionality

### COCOMO II Cost Drivers

- **Five advanced drivers** added to the sidebar: Required Reliability (RELY), Product Complexity (CPLX), Required Reusability (RUSE), Personnel Continuity (PCON), and Application Experience (APEX)
- Each driver has its own slider with the standard COCOMO II range, defaulting to 1.0 (nominal)
- Drivers are multiplied into the effort calculation and reflected in the waterfall chart

### Maintenance & TCO Projections

- **Annual maintenance rate** slider (0-40% of build cost)
- **Maintenance years** slider (0-10 years)
- Annual costs compound at 5% per year to account for knowledge turnover
- Dedicated **Maintenance sub-tab** with year-by-year breakdown and Total Cost of Ownership

### Scenario Comparison

- Compare up to **3 scenarios** side-by-side in the Compare tab
- Each scenario has independent parameter controls including tool support
- Results displayed in a comparative table for quick decision-making

### Export & Sharing

- **Shareable URLs** with proper protocol detection (http/https) and pre-filled Manual Entry parameters
- **CSV export** of analysis results
- **JSON export** for programmatic consumption

### User Interface

- **User Guide** and **Release Notes** accessible from navbar buttons (replacing the GitHub link)
- **App footer** with version number and author credit
- Dark theme (Bootswatch Darkly) with Roboto font throughout
- Sensitivity analysis charts for exploring parameter impact interactively

### Bug Fixes

- Fixed waterfall chart bar ordering so bars flow logically from base effort through multipliers to total
- Fixed invisible effort value box that was unreadable on the dark theme
- Fixed comment double-counting in repository analysis by using single-pass OR across patterns
