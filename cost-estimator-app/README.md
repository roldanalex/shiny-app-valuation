# 💰 Shiny Cost Estimator App

Interactive web application for estimating development costs of R Shiny applications and data science projects using the COCOMO II model.

## 🚀 Quick Start

### Local Deployment

```r
# Install required packages
install.packages(c("shiny", "bslib", "plotly", "DT", "shinyWidgets", "jsonlite", "RColorBrewer"))

# Run the app
shiny::runApp("cost-estimator-app")
```

### Deploy to shinyapps.io (Free Hosting)

```r
# Install rsconnect
install.packages("rsconnect")

# Configure your account (first time only)
rsconnect::setAccountInfo(
  name = "your-account-name",
  token = "your-token",
  secret = "your-secret"
)

# Deploy
rsconnect::deployApp(
  appDir = "cost-estimator-app",
  appName = "shiny-cost-estimator",
  forceUpdate = TRUE
)
```

## 📋 Features

### Three Analysis Modes

1. **📁 Local Folder Analysis**
   - Best for local use
   - Direct file system access
   - No file size limits
   - Full repository scanning

2. **📦 ZIP Upload**
   - Works on deployed servers
   - Drag-and-drop interface
   - Max 50MB file size
   - Automatic extraction and analysis

3. **✏️ Manual Entry**
   - Quick estimates
   - No code required
   - Enter lines by language
   - Instant calculations

### Interactive Features

- **📊 Language Breakdown**: Pie charts showing code distribution
- **💰 Cost Analysis**: Detailed breakdown of estimation components
- **📈 Sensitivity Analysis**: Interactive "what-if" scenarios
- **⚖️ Scenario Comparison**: Compare up to 3 different configurations
- **📄 Export Options**: PDF reports, CSV data, JSON exports
- **🔗 Shareable URLs**: Generate links with pre-filled parameters

## 🎯 User Guide

### Analyzing a Local Repository

1. Click **"📁 Local Folder"** tab
2. Enter repository path or click "Browse Folder"
3. Adjust project parameters:
   - **Complexity**: Low/Medium/High
   - **Team Experience**: 1 (novice) to 5 (expert)
   - **Reuse Factor**: 0.7 (high reuse) to 1.3 (greenfield)
   - **Tool Support**: 0.8 (excellent) to 1.2 (poor)
4. Click **"Analyze Repository"**
5. View results in three sub-tabs:
   - **Results**: Summary metrics and visualizations
   - **Details**: Full language breakdown table
   - **Sensitivity**: Interactive analysis charts

### Uploading a ZIP File

1. Click **"📦 ZIP Upload"** tab
2. Drag-and-drop or browse for your repository ZIP
3. Configure project parameters
4. Click **"Analyze ZIP"**
5. Review results (same layout as Local analysis)

**Tips for ZIP Upload:**
- Archive your entire repository (including subdirectories)
- Exclude large binary files and dependencies
- Keep under 50MB for best performance
- Use `.gitignore` patterns before zipping

### Manual Entry

1. Click **"✏️ Manual Entry"** tab
2. Enter code lines by language:
   - R, Python, JavaScript, SQL, CSS, Other
3. Configure project settings
4. Click **"Calculate Estimate"**
5. Instantly see cost projections

**Use Cases:**
- Quick ballpark estimates
- Planning new projects
- Comparing technology stacks
- Budget justification meetings

### Comparing Scenarios

1. Click **"⚖️ Compare"** tab
2. Configure up to 3 scenarios with different parameters
3. Click "Calculate" for each scenario
4. View side-by-side comparison chart and table

**Example Comparisons:**
- Experienced team vs. junior team
- High complexity vs. low complexity
- Greenfield vs. high-reuse projects
- Different team size constraints

### Exporting Results

1. Click **"📄 Export"** tab
2. Choose export format:
   - **PDF Report**: Comprehensive document (requires rmarkdown)
   - **CSV Data**: Language breakdown spreadsheet
   - **JSON**: Complete results for programmatic use
3. Generate **Shareable URL** to send configuration to colleagues

## ⚙️ Configuration

### Parameter Guide

#### Complexity Levels
- **Low (B=1.02)**: Simple apps, single module, < 5K lines
- **Medium (B=1.10)**: Multi-module, moderate integration, 5-20K lines
- **High (B=1.18)**: Complex architecture, AI/ML integration, > 20K lines

#### Team Experience
- **1**: Novice (new to Shiny, +15% effort)
- **2**: Beginner (some experience, +10% effort)
- **3**: Competent (regular use, +5% effort)
- **4**: Proficient (baseline, no adjustment)
- **5**: Expert (Shiny specialists, -5% effort)

#### Reuse Factor
- **0.7**: High reuse (internal packages, templates, 50%+ reusable)
- **0.9**: Moderate reuse (some shared components, 20-30%)
- **1.0**: Baseline (typical project, ~10% reuse)
- **1.2**: Low reuse (mostly custom, < 5%)
- **1.3**: Greenfield (entirely new domain)

#### Tool Support Quality
- **0.8**: Excellent (RStudio, Git, CI/CD, testing, linters)
- **0.9**: Good (IDE, version control, some automation)
- **1.0**: Baseline (standard setup)
- **1.1**: Fair (limited tooling)
- **1.2**: Poor (no IDE, no version control)

## 🔧 Technical Details

### Architecture

```
app.R
├── UI Layer (bslib + Bootstrap 5)
│   ├── Home (welcome + navigation)
│   ├── Local Folder (shinyFiles browser)
│   ├── ZIP Upload (file input handler)
│   ├── Manual Entry (form inputs)
│   ├── Compare (scenario builder)
│   └── Export (reports + URLs)
│
└── Server Layer
    ├── Reactive values (results storage)
    ├── Analysis engine (COCOMO II)
    ├── Visualization (plotly charts)
    ├── Data tables (DT)
    └── Export handlers (PDF, CSV, JSON)
```

### Dependencies

```r
# Required packages
library(shiny)        # Web framework
library(bslib)        # Modern UI components
library(plotly)       # Interactive charts
library(DT)           # Data tables
library(shinyWidgets) # Enhanced inputs
library(jsonlite)     # JSON export
library(RColorBrewer) # Chart colors
```

### File Structure

```
cost-estimator-app/
├── app.R              # Single-file Shiny app
├── README.md          # This file
└── www/               # Static assets (optional)
    └── custom.css     # Additional styling
```

## 🚨 Troubleshooting

### "Folder browser not available"
- **Issue**: `choose.dir()` doesn't work on Mac/Linux
- **Solution**: Manually enter the full path in the text box
- **Alternative**: Use ZIP upload mode

### "Error processing ZIP"
- **Issue**: ZIP file format not recognized
- **Solution**: Ensure proper ZIP compression (not RAR, 7z, etc.)
- **Check**: Verify folder structure inside ZIP

### "No files found to analyze"
- **Issue**: All files excluded by patterns
- **Solution**: Check `.gitignore` and exclusion patterns
- **Verify**: Repository contains analyzable code files

### Package installation errors
- **Issue**: Missing system dependencies
- **Solution**: Install system libraries:
  ```bash
  # Ubuntu/Debian
  sudo apt-get install libssl-dev libcurl4-openssl-dev
  
  # macOS
  brew install openssl curl
  ```

## 🎨 Customization

### Branding

Edit the theme in `app.R`:

```r
theme = bs_theme(
  version = 5,
  bootswatch = "flatly",  # Change theme: cosmo, journal, etc.
  primary = "#2C3E50",    # Your brand color
  secondary = "#18BC9C",
  base_font = font_google("Roboto")  # Your font
)
```

### Adding Custom Languages

Edit `shiny_cost_estimator.R`:

```r
lang_productivity <- list(
  "R" = 1.0,
  "Python" = 1.1,
  "YourLanguage" = 1.2,  # Add your language
  # ...
)
```

### Adjusting Limits

Modify constraints in the UI:

```r
# Max team size
sliderInput("local_max_team", "Max Team Size:",
           min = 1, max = 15, value = 8)  # Change max value

# Max schedule
sliderInput("local_max_schedule", "Max Schedule (months):",
           min = 3, max = 60, value = 36)  # Extend timeline
```

## 📊 Example Use Cases

### Case 1: Pre-Project Planning
**Scenario**: Estimating a new Shiny dashboard

1. Use **Manual Entry** mode
2. Estimate ~8,000 lines R, ~2,000 lines JS
3. Set complexity = Medium, team = 4
4. Get instant budget for proposal

### Case 2: Portfolio Valuation
**Scenario**: Assessing 10 existing applications

1. Use **Local Folder** mode
2. Analyze each app directory
3. Export CSV results
4. Sum total replacement value

### Case 3: Build vs. Buy Decision
**Scenario**: Should we build or purchase?

1. Use **Manual Entry** for quick estimate
2. Compare with vendor quotes
3. Use **Sensitivity Analysis** for risk assessment
4. Generate **PDF report** for stakeholders

### Case 4: Team Planning
**Scenario**: How many developers needed?

1. Analyze repository with **Local Folder**
2. Adjust **Max Team Size** slider
3. See schedule impact
4. Use **Compare** tab for different team sizes

## 🤝 Contributing

To enhance the app:

1. Fork the repository
2. Add features to `app.R`
3. Test locally with `shiny::runApp()`
4. Submit pull request

**Ideas for Enhancement:**
- GitHub/GitLab integration
- Historical project database
- Machine learning calibration
- Multi-language support
- Dark mode toggle
- Advanced reporting templates

## 📄 License

MIT License - See main repository LICENSE file

## 💬 Support

- **Issues**: Open GitHub issue
- **Email**: alexis.m.roldan.ds@gmail.com
- **Documentation**: See main README.md

---

**Built with ❤️ using R Shiny and COCOMO II**

*Last updated: January 2, 2026*
