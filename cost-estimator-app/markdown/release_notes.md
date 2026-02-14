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
