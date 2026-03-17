library(tidyverse)
library(lubridate)

# ── Load data ──────────────────────────────────────────────────────────────────
rats <- read_csv("~/Desktop/rats.csv")

# Quick sanity checks
cat("Rows:", nrow(rats), "\n")
cat("Columns:", ncol(rats), "\n")
summary(rats)
table(rats$Borough)

# ── Derive temporal variables ──────────────────────────────────────────────────
rats <- rats %>%
  mutate(
    created             = mdy_hms(`Created Date`),
    closed              = mdy_hms(`Closed Date`),
    response_time_hours = as.numeric(difftime(closed, created, units = "hours")),
    month               = month(created),
    day_of_week         = wday(created, label = TRUE)
  ) %>%
  filter(response_time_hours >= 0)   # drop negative / malformed timestamps

cat("Rows after filter:", nrow(rats), "\n")

# ── Simplify Location Type ─────────────────────────────────────────────────────
rats <- rats %>%
  mutate(
    location_group = case_when(
      str_detect(`Location Type`, regex("1-2|3\\+|apartment|residential", ignore_case = TRUE)) ~ "Residential",
      str_detect(`Location Type`, regex("store|commercial|restaurant|food|market",  ignore_case = TRUE)) ~ "Commercial",
      str_detect(`Location Type`, regex("park|playground|garden|lot",               ignore_case = TRUE)) ~ "Outdoor/Park",
      str_detect(`Location Type`, regex("school|hospital|public|government",        ignore_case = TRUE)) ~ "Public/Institutional",
      str_detect(`Location Type`, regex("street|sidewalk|alley|catch basin",        ignore_case = TRUE)) ~ "Street/Infrastructure",
      TRUE ~ "Other"
    )
  )

table(rats$location_group)

# ── Diagnostic plots ───────────────────────────────────────────────────────────

# Raw response time
qqnorm(rats$response_time_hours, main = "QQ Plot – Raw Response Time")
qqline(rats$response_time_hours, col = "red")

# Log-transformed (skew correction)
qqnorm(log(rats$response_time_hours + 1), main = "QQ Plot – log(Response Time + 1)")
qqline(log(rats$response_time_hours + 1), col = "red")

# Boxplots
boxplot(response_time_hours ~ Borough, data = rats,
        main = "Response Time by Borough", ylab = "Hours",
        las = 2, col = "lightblue")

boxplot(response_time_hours ~ `Problem Detail`, data = rats,
        main = "Response Time by Problem Type", ylab = "Hours",
        las = 2, col = "lightgreen")

boxplot(response_time_hours ~ location_group, data = rats,
        main = "Response Time by Location Group", ylab = "Hours",
        las = 2, col = "lightyellow")

# ── One-Factor ANOVAs ──────────────────────────────────────────────────────────

# 1a. Response time ~ Borough
model1a <- aov(response_time_hours ~ Borough, data = rats)
cat("\n── ANOVA: response_time_hours ~ Borough ──\n")
print(summary(model1a))
print(TukeyHSD(model1a))
plot(model1a, main = "Model 1a Diagnostics")

# 1b. Response time ~ Problem Detail
model1b <- aov(response_time_hours ~ `Problem Detail`, data = rats)
cat("\n── ANOVA: response_time_hours ~ Problem Detail ──\n")
print(summary(model1b))
print(TukeyHSD(model1b))

# 1c. Response time ~ Location Group
model1c <- aov(response_time_hours ~ location_group, data = rats)
cat("\n── ANOVA: response_time_hours ~ Location Group ──\n")
print(summary(model1c))
print(TukeyHSD(model1c))

# ── Two-Factor ANOVAs ──────────────────────────────────────────────────────────

# 2a. Borough × Problem Detail (with interaction)
model2a <- aov(response_time_hours ~ Borough * `Problem Detail`, data = rats)
cat("\n── ANOVA: response_time_hours ~ Borough * Problem Detail ──\n")
print(summary(model2a))

# 2b. Borough × Location Group (with interaction)
model2b <- aov(response_time_hours ~ Borough * location_group, data = rats)
cat("\n── ANOVA: response_time_hours ~ Borough * Location Group ──\n")
print(summary(model2b))

# ── District-level aggregation (per-capita analysis) ──────────────────────────
district_summary <- rats %>%
  group_by(`Council District`, Borough, population,
           median_household_income, poverty_rate) %>%
  summarise(n_complaints = n(), .groups = "drop") %>%
  mutate(complaints_per_1000 = n_complaints / population * 1000)

cat("\nDistrict-level summary (", nrow(district_summary), "rows ):\n")
print(district_summary)

# 3. Complaints per 1,000 residents ~ Borough
model3 <- aov(complaints_per_1000 ~ Borough, data = district_summary)
cat("\n── ANOVA: complaints_per_1000 ~ Borough ──\n")
print(summary(model3))
print(TukeyHSD(model3))

boxplot(complaints_per_1000 ~ Borough, data = district_summary,
        main = "Rodent Complaints per 1,000 Residents by Borough",
        ylab = "Complaints per 1,000", las = 2, col = "salmon")

# ── Chi-Square Tests ───────────────────────────────────────────────────────────

# 4a. Problem Detail independent of Borough?
tbl_pd_boro <- table(rats$`Problem Detail`, rats$Borough)
cat("\n── Chi-Square: Problem Detail × Borough ──\n")
print(chisq.test(tbl_pd_boro))

# 4b. Channel type independent of Borough?
tbl_ch_boro <- table(rats$`Open Data Channel Type`, rats$Borough)
cat("\n── Chi-Square: Channel Type × Borough ──\n")
print(chisq.test(tbl_ch_boro))

# ── Optional: log-transform ANOVA for more valid inference ────────────────────
rats <- rats %>% mutate(log_response = log(response_time_hours + 1))

model_log <- aov(log_response ~ Borough * `Problem Detail`, data = rats)
cat("\n── ANOVA (log-transformed): log(response+1) ~ Borough * Problem Detail ──\n")
print(summary(model_log))
plot(model_log, main = "Log-Transform Model Diagnostics")

