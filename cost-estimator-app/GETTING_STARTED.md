# 🎉 Shiny Cost Estimator App - Setup Complete!

## ✅ What's Been Created

Your interactive Shiny Cost Estimator app is ready! Here's what's available:

### 📁 App Files

```
cost-estimator-app/
├── app.R                    # Main Shiny application (single file)
├── README.md                # Complete app documentation
├── DEPLOYMENT.md            # Deployment guide for various platforms
├── check_dependencies.R     # Dependency checker script
├── run_app.R               # Quick launcher script
└── test_data.R             # Example test data
```

### 🎯 Three Analysis Modes

1. **📁 Local Folder Analysis**
   - Browse folders on your computer
   - No file size limits
   - Best for local development

2. **📦 ZIP Upload**
   - Drag-and-drop repository archives
   - Works on deployed servers
   - 50MB limit (configurable)

3. **✏️ Manual Entry**
   - Enter code lines by language
   - Instant calculations
   - Perfect for quick estimates

### ✨ Key Features

- 📊 **Interactive visualizations** (pie charts, bar charts, sensitivity analysis)
- 💰 **Real-time cost calculations** with parameter sliders
- ⚖️ **Scenario comparison** (side-by-side analysis)
- 📈 **Sensitivity analysis** (what-if scenarios)
- 📄 **Export options** (PDF, CSV, JSON)
- 🔗 **Shareable URLs** (pre-filled parameters)
- 🎨 **Modern UI** (Bootstrap 5 with bslib theme)

---

## 🚀 Quick Start

### 1. Install Dependencies

```r
# Run the dependency checker
source("cost-estimator-app/check_dependencies.R")

# If packages are missing, install them:
install.packages(c(
  "shiny", "bslib", "plotly", "DT", 
  "shinyWidgets", "jsonlite", "RColorBrewer"
))
```

### 2. Test Locally

```r
# Option A: Direct launch
shiny::runApp("cost-estimator-app")

# Option B: Use the launcher script
Rscript cost-estimator-app/run_app.R

# Option C: From RStudio
# Open cost-estimator-app/app.R and click "Run App"
```

The app will open in your browser at `http://localhost:3838`

### 3. Try the Examples

```r
# Load test data
source("cost-estimator-app/test_data.R")

# See 5 pre-configured examples:
# - Small Dashboard (4,300 lines, ~$55K)
# - Medium Platform (15,000 lines, ~$145K)
# - Large Enterprise (39,000 lines, ~$420K)
# - Quick Prototype (1,500 lines, ~$15K)
# - Comparison scenarios
```

---

## 🌐 Deploy to Free Hosting

### Deploy to shinyapps.io (Free Tier)

```r
# 1. Install rsconnect
install.packages("rsconnect")

# 2. Configure your account (get token from shinyapps.io)
rsconnect::setAccountInfo(
  name = 'your-account-name',
  token = 'your-token',
  secret = 'your-secret'
)

# 3. Deploy!
rsconnect::deployApp(
  appDir = 'cost-estimator-app',
  appName = 'shiny-cost-estimator',
  forceUpdate = TRUE
)
```

**Free Tier Includes:**
- ✅ 5 applications
- ✅ 25 active hours/month
- ✅ 1GB RAM per instance
- ✅ Custom URLs

**See detailed deployment instructions**: [cost-estimator-app/DEPLOYMENT.md](cost-estimator-app/DEPLOYMENT.md)

---

## 📖 User Guide

### Analyzing a Local Repository

1. Launch the app
2. Click **"📁 Local Folder"** tab
3. Enter or browse to your repository path
4. Adjust parameters:
   - **Complexity**: Low/Medium/High
   - **Team Experience**: 1-5 (novice to expert)
   - **Reuse Factor**: 0.7-1.3
   - **Tool Support**: 0.8-1.2
   - **Max Team Size**: 1-10
   - **Max Schedule**: 3-36 months
5. Click **"Analyze Repository"**
6. View results in three sub-tabs:
   - **Results**: Summary cards and charts
   - **Details**: Full language breakdown table
   - **Sensitivity**: Interactive analysis

### Uploading a ZIP File

1. Click **"📦 ZIP Upload"** tab
2. Drag-and-drop or browse for ZIP
3. Configure parameters (same as above)
4. Click **"Analyze ZIP"**
5. Review results

**Tip**: Exclude large files before zipping (node_modules, .git, etc.)

### Manual Entry

1. Click **"✏️ Manual Entry"** tab
2. Enter code lines by language:
   - R, Python, JavaScript, SQL, CSS, Other
3. Configure project settings
4. Click **"Calculate Estimate"**
5. Instantly view results

### Comparing Scenarios

1. Click **"⚖️ Compare"** tab
2. Configure up to 3 scenarios
3. Click "Calculate" for each
4. View side-by-side comparison

**Example**: Compare experienced team vs. junior team, or high vs. low complexity

### Exporting Results

1. Click **"📄 Export"** tab
2. Choose format:
   - PDF Report (comprehensive document)
   - CSV Data (spreadsheet)
   - JSON (programmatic use)
3. Generate **Shareable URL** to send configuration to colleagues

---

## 🎨 Customization

### Change Theme/Colors

Edit `app.R` (lines 20-30):

```r
theme = bs_theme(
  version = 5,
  bootswatch = "flatly",  # Try: cosmo, journal, minty, etc.
  primary = "#2C3E50",    # Your brand color
  secondary = "#18BC9C",
  base_font = font_google("Roboto")  # Your preferred font
)
```

**Available themes**: flatly, cosmo, cerulean, journal, litera, lumen, minty, pulse, sandstone, simplex, spacelab, united, yeti

### Add Custom Languages

Edit `R/shiny_cost_estimator.R`:

```r
lang_productivity <- list(
  "R" = 1.0,
  "Python" = 1.1,
  "YourLanguage" = 1.2,  # Add here
  # ...
)
```

### Adjust Limits

Modify UI sliders in `app.R`:

```r
# Max team size (currently 1-10)
sliderInput("local_max_team", "Max Team Size:",
           min = 1, max = 15, value = 8)  # Change max

# Max schedule (currently 3-36 months)
sliderInput("local_max_schedule", "Max Schedule:",
           min = 3, max = 60, value = 36)  # Extend
```

---

## 🐛 Troubleshooting

### "Package not found"
```r
# Install missing packages
install.packages(c("shiny", "bslib", "plotly", "DT", "shinyWidgets", "jsonlite", "RColorBrewer"))
```

### "Cannot find R files"
- Ensure you're running from project root
- Check that `R/shiny_cost_estimator.R` and `R/repo_code_analyzer.R` exist
- Verify relative paths in `app.R`

### "Folder browser not working"
- Expected on Mac/Linux (Windows only)
- Solution: Manually enter path or use ZIP upload

### "App crashes on deployment"
```r
# Check logs on shinyapps.io
rsconnect::showLogs(appName = "shiny-cost-estimator", entries = 100)
```

---

## 📊 Example Workflows

### Workflow 1: Project Planning
1. Use **Manual Entry** mode
2. Estimate code lines for planned features
3. Try different complexity levels
4. Compare scenarios in **Compare** tab
5. Export PDF report for stakeholders

### Workflow 2: Portfolio Valuation
1. Use **Local Folder** mode
2. Analyze each existing app
3. Export CSV for each
4. Sum total portfolio value in spreadsheet

### Workflow 3: Build vs. Buy
1. Analyze similar projects for benchmarks
2. Use **Sensitivity Analysis** for risk assessment
3. Compare with vendor quotes
4. Generate shareable URL for decision makers

### Workflow 4: Team Planning
1. Analyze repository with **Local Folder**
2. Adjust **Max Team Size** slider
3. See schedule impact in real-time
4. Export results for resource planning

---

## 📚 Additional Resources

- **App Documentation**: [cost-estimator-app/README.md](cost-estimator-app/README.md)
- **Deployment Guide**: [cost-estimator-app/DEPLOYMENT.md](cost-estimator-app/DEPLOYMENT.md)
- **Test Data**: [cost-estimator-app/test_data.R](cost-estimator-app/test_data.R)
- **Main Toolkit README**: [README.md](README.md)

### COCOMO II Resources
- Official site: http://csse.usc.edu/csse/research/COCOMOII/
- Book: "Software Cost Estimation with COCOMO II" by Barry Boehm

### Shiny Resources
- Shiny Gallery: https://shiny.rstudio.com/gallery/
- Mastering Shiny: https://mastering-shiny.org/
- Community: https://community.rstudio.com/

---

## 🎯 Next Steps

### For Local Use:
1. ✅ Run dependency checker
2. ✅ Test all three modes
3. ✅ Try example data
4. ✅ Customize theme (optional)
5. ✅ Bookmark `http://localhost:3838`

### For Deployment:
1. ✅ Test locally first
2. ✅ Sign up for shinyapps.io
3. ✅ Install rsconnect
4. ✅ Deploy app
5. ✅ Share URL with team

### For Development:
1. ✅ Fork repository
2. ✅ Add custom features
3. ✅ Test locally
4. ✅ Submit pull request

---

## 💡 Tips for Best Results

### Code Analysis:
- Clean your repo before analysis (remove node_modules, .git)
- For ZIP uploads, keep under 50MB
- Include all source files, not just main scripts

### Parameter Selection:
- Be realistic with team experience (most teams are 3-4)
- Consider actual tool support (good IDE + Git = 0.9)
- Factor in reuse (internal packages, templates)
- Adjust complexity based on architecture, not just lines

### Presentations:
- Use **Compare** tab to show different scenarios
- Export PDF reports for formal proposals
- Generate shareable URLs for stakeholder review
- Show sensitivity analysis for risk assessment

---

## 🤝 Support & Contributing

**Questions?**
- Check documentation files
- Review test examples
- Open GitHub issue
- Email: alexis.roldan@takeda.com

**Want to contribute?**
- Add new visualizations
- Improve mobile responsiveness
- Add internationalization
- Create video tutorials

---

## 🎉 You're Ready!

Your Shiny Cost Estimator app is fully configured and ready to use!

**Start analyzing now:**
```r
shiny::runApp("cost-estimator-app")
```

**Happy estimating! 💰📊🚀**

---

*Built with ❤️ using R Shiny, bslib, and COCOMO II*

*Last updated: January 2, 2026*
