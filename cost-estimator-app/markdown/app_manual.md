This app answers one question: **what would it cost to build (or rebuild) a software application?** You describe the project — or upload its code — and the app estimates the development cost, timeline, and team size, with a PDF report you can share.

No technical background is needed. Every parameter has a **?** button next to it with a plain-language explanation.

---

## The Four Tabs

| Tab | Use it to... |
|---|---|
| **Home** | See a live example estimate and jump into the tool |
| **Analyze** | Produce an estimate for your project (start here) |
| **Compare** | Put up to 3 what-if scenarios side by side |
| **Export** | Download the PDF report, share a link, or export data |

---

## Get Your First Estimate (2 minutes)

1. Open the **Analyze** tab.
2. In the sidebar, keep **Manual Entry** selected.
3. Enter roughly how many lines of code the project has, split by language
   (for example — R: 15,000 · JavaScript: 3,000). A rough guess is fine;
   you can refine later.
4. Set the three parameters that matter most:
   - **Complexity** — how architecturally involved the app is (when in doubt, Medium)
   - **Team Experience** — average skill of the team, 1 (novice) to 5 (expert)
   - **Average Annual Wage** — the fully-loaded yearly cost per developer
5. Click **Run Analysis**.

The sidebar collapses and your results appear: the headline cost with its
**estimate range (±30%)**, plus cards for schedule, team size, and effort.

> **Tip:** A summary strip stays pinned to the bottom of the screen with your
> key numbers and a **PDF Report** button — it follows you as you explore.

### Don't know your line counts?

Let the app count them for you:

- **ZIP Upload** — zip the project folder and upload it (up to 50 MB).
- **Local Folder** — if you're running the app on your own computer, point it
  at the project directory.

The app detects each programming language automatically. Documentation and
configuration files (README files, JSON, YAML, …) are shown in the results but
**never counted toward the cost** — only real code is billed.

---

## Reading Your Results

The Analyze tab has four sub-tabs:

### Results

- **Code Distribution by Language** — what the project is made of. Greyed
  boxes marked "not billed" are docs/config, excluded from cost.
- **Cost Breakdown** — a waterfall showing how the estimate is built: base
  effort, then each factor (experience, reuse, tools, …) adding or removing
  cost, ending at exactly the headline number.
- **What's Driving Your Cost?** — the same factors ranked by dollar impact.
  Bars to the left save money; bars to the right add cost.
- **Schedule vs. Cost Tradeoff** — what happens to cost if you demand a
  faster (or allow a slower) delivery. Your current estimate is marked with a dot.

### Details

The full language table plus a plain-text summary of the estimate you can copy anywhere.

### Sensitivity

How the estimate would move if team experience or complexity were different.
The diamond marker is your current estimate.

### Maintenance & TCO

Hidden until you set **Maintenance Years** above 0 in the sidebar. Shows the
yearly cost of keeping the app alive and the **Total Cost of Ownership**
(build + maintenance, discounted to today's dollars).

---

## What the Numbers Mean (Honest Fine Print)

- **Estimate range (±30%)** — software estimation is inherently uncertain.
  The range reflects the typical accuracy of this class of model
  (COCOMO II); treat the low and high ends as equally plausible.
- **Schedule warnings** — if you cap the schedule tighter than the work
  naturally allows, the app adds a compression premium (rush work costs
  more) and warns you. If the deadline would need more people than your team
  cap allows, it flags the plan as **not feasible** rather than pretending.
- **Consistency** — the numbers always agree with each other:
  effort = team size × schedule, and the waterfall chart totals the headline
  cost to the dollar.

---

## Comparing Scenarios

On the **Compare** tab:

1. Set the **shared cost parameters** (wage and max schedule) once — they
   apply to every scenario so the dollar figures stay comparable.
2. Fill in up to three scenario cards (e.g., "experienced team" vs "junior
   team" vs "high complexity").
3. Click **Calculate** on each card.

Results appear as three charts (cost with its range, schedule, team size) and
a detail table.

---

## Sharing Your Estimate

From the **Export** tab — or the **PDF Report** button in the summary strip:

- **PDF Report** — a polished multi-page document with the headline estimate,
  charts, every assumption you used, and a methodology page. Ready to email.
  (Takes a few seconds to generate.)
- **Shareable URL** — sends a colleague a link that pre-fills your Manual
  Entry numbers so they see the same estimate.
- **CSV / JSON** — raw data for spreadsheets or other tools.

---

## Frequently Asked Questions

**Why did the cost jump when I shortened the schedule?**
Compressed timelines require more parallel work, senior talent, and overtime.
The model adds a premium that grows with the amount of compression (up to
double the cost).

**Why is the team size shown with decimals (e.g., 2.4 people)?**
It's an average staffing level over the project — 2.4 people means roughly
two full-time developers plus one part-time.

**Why doesn't adding documentation increase the estimate?**
Only code that must be designed, written, and tested drives cost. Docs and
config files are listed for transparency but excluded from billing.

**Which wage should I enter?**
The *fully-loaded* annual cost per developer — salary plus benefits and
overhead. If you only know base salary, add roughly 25–40%.

**Can I trust a single number?**
Use the range, not the point estimate, for budgeting — and read the
methodology page of the PDF report for exactly how the numbers are produced.
