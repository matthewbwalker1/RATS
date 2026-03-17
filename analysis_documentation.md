# NYC Rodent Complaints Analysis — Documentation

BYU Statistics Case Competition 2026

---

## 1. Overview

### Dataset

The dataset contains **31,312 NYC 311 rodent-related service requests** filed in 2025, sourced from the NYC Open Data portal. Each row represents a single complaint. The dataset was merged with NYC Council District demographic data, adding three variables for each district: `population`, `median_household_income`, and `poverty_rate`.

Key columns used in this analysis:

| Column | Description |
|---|---|
| `Borough` | One of five NYC boroughs (Bronx, Brooklyn, Manhattan, Queens, Staten Island) |
| `Problem Detail` | Type of rodent problem (e.g., "Rat Sighting", "Mouse Sighting", "Condition Attracting Rodents") |
| `Location Type` | Raw location description (26 distinct values) |
| `Created Date` | Timestamp when the complaint was filed |
| `Closed Date` | Timestamp when the complaint was resolved |
| `Open Data Channel Type` | How the complaint was submitted (e.g., Phone, Online, Mobile) |
| `Council District` | NYC Council District number |
| `population` | Total population of the council district |
| `median_household_income` | Median household income for the council district |
| `poverty_rate` | Poverty rate for the council district |

### Research Questions

1. Do NYC boroughs differ in how quickly rodent complaints are resolved?
2. Does the type of rodent problem or location affect response time?
3. Are some boroughs disproportionately burdened with complaints relative to their population?
4. Is the mix of problem types or reporting channels consistent across boroughs, or does it vary?

### Competition Context

This analysis was prepared for the **BYU Statistics Case Competition 2026**. The goal is to apply appropriate statistical models (ANOVA, chi-square) to a real-world municipal dataset and draw defensible conclusions about equity, responsiveness, and spatial patterns in NYC's rodent complaint system.

---

## 2. Data Preparation

### Response Time Calculation

`response_time_hours` is derived as:

```
response_time_hours = Closed Date − Created Date  (in hours)
```

Both timestamps are parsed with `mdy_hms()` (month-day-year, hour-minute-second format). The difference is computed using `difftime(..., units = "hours")` and coerced to a numeric value.

**Why negative/zero values are filtered:** A negative response time means the recorded `Closed Date` precedes `Created Date`, which is physically impossible and indicates a data entry error or timestamp corruption. Zero-hour closures may represent auto-closed duplicates. These rows are removed with `filter(response_time_hours >= 0)` before any modeling begins.

### Location Group Bucketing

The raw `Location Type` column contains 26 distinct string values that are too granular for stable ANOVA estimates. They are collapsed into **6 groups** using regex pattern matching:

| Group | Raw values matched |
|---|---|
| **Residential** | "1-2", "3+", "apartment", "residential" |
| **Commercial** | "store", "commercial", "restaurant", "food", "market" |
| **Outdoor/Park** | "park", "playground", "garden", "lot" |
| **Public/Institutional** | "school", "hospital", "public", "government" |
| **Street/Infrastructure** | "street", "sidewalk", "alley", "catch basin" |
| **Other** | Anything not matched above |

Matching is case-insensitive. A value matches the first rule it satisfies (top-to-bottom priority).

---

## 3. Charts

### QQ Plot — Raw Response Time

**What it is:** A quantile-quantile (QQ) plot comparing the empirical quantiles of `response_time_hours` against the theoretical quantiles of a normal distribution. The red line shows where the points would fall if the data were perfectly normal.

**How to read it:** If the data are normally distributed, points should fall tightly along the red line. Deviations in the tails indicate skew or heavy tails. An upward-curving right tail means right-skew (a long upper tail).

**What it teaches us:** Response times are heavily right-skewed. Most complaints are resolved within a few days, but a small fraction take weeks or months, pulling the upper tail far above the normal reference line. This violation of normality is the primary motivation for the log transformation applied later.

---

### QQ Plot — log(Response Time + 1)

**What it is:** The same QQ plot as above, but applied to `log(response_time_hours + 1)`. The `+ 1` prevents `log(0)` errors for any zero-hour cases that survived filtering.

**How to read it:** Same interpretation as the raw QQ plot. Better normality appears as points hugging the red line more closely, especially in the tails.

**What it teaches us:** The log transformation substantially improves normality. The upper tail tucks in and the point cloud aligns more closely with the reference line. This confirms that log-scale models (`model_log`) will produce more valid ANOVA inference than raw-scale models (`model1a`, `model2a`).

---

### Boxplot — Response Time by Borough

**What it is:** Five side-by-side boxplots (one per borough) where the y-axis is `response_time_hours`. Each box spans the interquartile range (IQR, 25th–75th percentile), the horizontal line inside the box is the median, whiskers extend to ~1.5× IQR, and dots beyond the whiskers are outliers. Boxes are colored light blue.

**How to read it:** Taller boxes indicate more variability within that borough. A higher median line means typical complaints take longer to close. Many dots above the upper whisker confirm the right-skewed distribution noted in the QQ plot.

**What it teaches us:** Median response times differ visibly across boroughs. Some boroughs show tighter distributions (more consistent service) while others show wider spreads. This visual difference motivates the formal ANOVA test in `model1a`.

---

### Boxplot — Response Time by Problem Type

**What it is:** Side-by-side boxplots (one per level of `Problem Detail`) where the y-axis is `response_time_hours`. Labels are rotated 90° (`las = 2`) for readability. Boxes are colored light green.

**How to read it:** Compare median lines across problem categories. A category with a dramatically higher or lower median than others suggests that problem type influences how quickly inspectors respond.

**What it teaches us:** Different problem types may trigger different response protocols. For example, active rat sightings may be prioritized differently than complaints about conditions attracting rodents. This plot motivates `model1b` and the two-factor models (`model2a`, `model_log`).

---

### Boxplot — Response Time by Location Group

**What it is:** Side-by-side boxplots (one per `location_group`) where the y-axis is `response_time_hours`. Labels are rotated 90°. Boxes are colored light yellow.

**How to read it:** Differences in box height or median position across location groups indicate that where a complaint originates affects how quickly it is resolved.

**What it teaches us:** Location context plausibly affects response: a complaint at a school or hospital (Public/Institutional) might be escalated differently than one from a residential building. Visual differences here motivate `model1c` and `model2b`.

---

### Model 1a ANOVA Diagnostics (4-panel)

**What it is:** The standard 4-panel diagnostic plot produced by `plot(model1a)`, which is an `aov` object for `response_time_hours ~ Borough`. The four panels are:
1. **Residuals vs Fitted** — plots residuals against fitted (group mean) values
2. **Normal Q-Q** — QQ plot of standardized residuals
3. **Scale-Location** — square root of |standardized residuals| vs fitted values
4. **Residuals vs Leverage** — identifies influential observations

**How to read it:**
- *Residuals vs Fitted*: a horizontal band with no pattern is ideal; a funnel shape indicates heteroscedasticity (unequal variances).
- *Normal Q-Q*: points should follow the diagonal; heavy tails signal non-normality.
- *Scale-Location*: a flat loess line indicates constant variance; an upward slope means variance increases with fitted values.
- *Residuals vs Leverage*: points outside Cook's distance contours are highly influential.

**What it teaches us:** These diagnostics expose the core weakness of running ANOVA directly on raw response times. The residual plots show a pronounced funnel shape (variance grows with the mean), and the QQ plot of residuals has heavy tails — confirming that the raw-scale ANOVA assumptions are violated. Results from `model1a`–`model2b` should therefore be interpreted cautiously; `model_log` addresses these issues.

---

### Boxplot — Complaints per 1,000 Residents by Borough

**What it is:** Side-by-side boxplots where the unit of observation is a **council district** (n ≈ 51 rows in `district_summary`) rather than an individual complaint. The y-axis is `complaints_per_1000 = n_complaints / population × 1000`. Boxes are colored salmon.

**How to read it:** Each data point is a council district; the box summarizes the distribution of complaint rates across all districts within a borough. A high median means that borough's districts tend to have more complaints relative to their population size.

**What it teaches us:** Raw complaint counts are biased by population — a dense borough will naturally file more complaints. Normalizing by population per 1,000 residents reveals whether the *burden* of rodent complaints is equitably distributed. A borough with a high per-capita rate despite average density signals a genuine rodent problem or higher reporting propensity, not just a larger population.

---

### Log-Transform Model Diagnostics (4-panel)

**What it is:** The same 4-panel `plot()` output as the Model 1a diagnostics, but now for `model_log`, which models `log(response_time_hours + 1) ~ Borough * Problem Detail`.

**How to read it:** Same interpretation as the Model 1a diagnostics above.

**What it teaches us:** Compared to the raw-scale diagnostics, these panels should show improved behavior: a flatter spread in the Scale-Location plot, tighter alignment in the QQ plot, and less pronounced funnel structure in Residuals vs Fitted. Improved diagnostics validate the decision to use the log-scale model as the primary inferential tool.

---

## 4. Statistical Tests

### model1a — One-Factor ANOVA: `response_time_hours ~ Borough`

- **Null hypothesis:** All five boroughs have the same mean response time.
- **What the p-value tells us:** A small p-value (< 0.05) rejects the null, indicating at least one borough has a statistically different mean response time from the others.
- **What Tukey HSD adds:** The omnibus ANOVA F-test only tells us *that* a difference exists. Tukey's Honest Significant Difference test performs all 10 pairwise borough comparisons while controlling the family-wise error rate, revealing *which specific pairs* differ. This identifies whether, for example, Manhattan and the Bronx are distinguishable from each other, not just from the overall mean.

---

### model1b — One-Factor ANOVA: `response_time_hours ~ Problem Detail`

- **Null hypothesis:** All problem types (Rat Sighting, Mouse Sighting, Condition Attracting Rodents, etc.) have the same mean response time.
- **What the p-value tells us:** Rejection indicates that the nature of the complaint is a statistically significant predictor of how long resolution takes.
- **What Tukey HSD adds:** Identifies which specific problem type pairs drive the overall difference (e.g., whether "Rat Sighting" is handled faster than "Condition Attracting Rodents").

---

### model1c — One-Factor ANOVA: `response_time_hours ~ location_group`

- **Null hypothesis:** All location groups (Residential, Commercial, Outdoor/Park, Public/Institutional, Street/Infrastructure, Other) have the same mean response time.
- **What the p-value tells us:** Rejection indicates that where a complaint originates predicts response speed.
- **What Tukey HSD adds:** Identifies which location group pairs are statistically distinguishable — e.g., whether Public/Institutional complaints are resolved faster than Residential ones.

---

### model2a — Two-Factor ANOVA: `response_time_hours ~ Borough * Problem Detail`

- **Null hypothesis (main effects):** Borough has no effect on mean response time; Problem Detail has no effect on mean response time.
- **Null hypothesis (interaction):** The effect of Problem Detail on response time does not differ by Borough (no Borough × Problem Detail interaction).
- **What the p-value tells us:** Significant main effects indicate independent influence of each factor. A significant interaction term means that the borough effect depends on problem type — e.g., rat sightings might be resolved faster in Manhattan but not in the Bronx, while mouse sightings show the reverse pattern.
- **Note:** No Tukey HSD is run for two-factor models, as the interaction term makes pairwise comparisons complex and the raw-scale assumptions are already suspect (see diagnostics).

---

### model2b — Two-Factor ANOVA: `response_time_hours ~ Borough * location_group`

- **Null hypothesis:** Same structure as model2a but replacing Problem Detail with location_group.
- **Interpretation:** Significant interaction would indicate that the relationship between location type and response speed varies by borough — for example, street-level complaints in Staten Island may be handled differently than those in Brooklyn.

---

### model3 — One-Factor ANOVA: `complaints_per_1000 ~ Borough`

- **Null hypothesis:** All boroughs have the same mean per-capita complaint rate across their council districts.
- **What the p-value tells us:** Rejection indicates that rodent complaint burden, adjusted for population, differs across boroughs.
- **What Tukey HSD adds:** Identifies which borough pairs have significantly different per-capita rates. A borough with a significantly higher rate despite population adjustment signals a genuine geographic disparity in rodent burden or reporting behavior.
- **Caveat:** This analysis runs on n ≈ 51 rows (one per council district), so statistical power is substantially lower than the complaint-level models.

---

### chisq.test — Problem Detail × Borough

- **Null hypothesis:** The distribution of `Problem Detail` categories is independent of `Borough` (the mix of problem types is the same in every borough).
- **What the p-value tells us:** Rejection means the type of rodent problem reported differs by borough. For example, mouse sightings may be proportionally more common in Manhattan (dense residential housing) than in Staten Island.
- **Note:** With n = 31,312, expected cell counts are large, so the chi-square approximation is reliable. However, a statistically significant result at this sample size may represent a very small practical effect; Cramér's V (not computed here) would quantify effect size.

---

### chisq.test — Channel Type × Borough

- **Null hypothesis:** The distribution of `Open Data Channel Type` (Phone, Online, Mobile, etc.) is independent of `Borough`.
- **What the p-value tells us:** Rejection means residents in different boroughs use different channels to report complaints. This could reflect digital access disparities, demographic differences, or borough-specific outreach programs.
- **Same caveat** regarding large sample size and effect size applies.

---

### model_log — Two-Factor ANOVA: `log(response_time_hours + 1) ~ Borough * Problem Detail`

- **Null hypothesis:** Same as model2a — Borough and Problem Detail have no effect on (log) response time, and their interaction is zero.
- **What the p-value tells us:** Same interpretation as model2a, but on the log scale. Because the log transformation substantially reduces skew and stabilizes variance (as confirmed by the diagnostic plots), this model produces more valid p-values than model2a.
- **How to interpret log-scale results:** A significant Borough effect on `log(response + 1)` means boroughs differ multiplicatively in response time, not just additively. Back-transforming coefficients via `exp()` gives response time ratios rather than differences in hours.
- **What Tukey HSD adds:** Not computed here; the two-factor interaction structure makes pairwise contrasts complex. The primary value of `model_log` is model validation (cleaner diagnostics) rather than post-hoc comparison.

---

## 5. Limitations & Caveats

### ANOVA Assumptions

Standard ANOVA assumes (1) normally distributed residuals and (2) equal variance across groups (homoscedasticity). The raw-scale models (`model1a` through `model2b`) violate both assumptions:

- Response times are heavily right-skewed, producing non-normal residuals (visible in the Model 1a QQ diagnostic).
- Variance grows with the group mean — groups with longer average response times also show more spread (visible in the Scale-Location panel).

The log-transformed model (`model_log`) substantially alleviates both issues. **For formal inference, conclusions from `model_log` are more statistically defensible than those from the raw-scale models.** Results from `model1a`–`model2b` are useful for descriptive comparison and visualization but should not be relied upon for strict hypothesis testing.

### Chi-Square Tests

With 31,312 observations, all expected cell counts are well above 5, so the chi-square approximation is valid. However, **large sample sizes guarantee small p-values** even for trivial differences. A significant chi-square test at n = 31,312 does not imply a practically meaningful association. Cramér's V (effect size for chi-square) was not computed in this analysis and would be needed to assess practical significance.

### Per-Capita Analysis (model3)

The per-capita ANOVA operates on `district_summary`, which has approximately **n = 51 rows** (one per council district). This is a very small sample for ANOVA:

- **Low statistical power:** Genuine differences between boroughs may fail to reach significance simply because there are few data points.
- **Unequal group sizes:** Boroughs contain different numbers of council districts, which can affect the stability of variance estimates.
- **Ecological fallacy risk:** District-level averages smooth over within-district variation; conclusions about individual complaint patterns should not be drawn from this model.

Despite these limitations, the per-capita model is the most appropriate tool for the equity question ("are some boroughs disproportionately burdened?"), since complaint counts alone conflate population size with rodent burden.
