# Loading Libraries -----------------------------------------------------
library(tidyverse)
library(vroom)
library(readxl)
library(lubridate)


# Reading In Data -------------------------------------------------------
report_data <- vroom("311_rodent_calls.csv")
district_data <- read_xlsx("nyc_council_context.xlsx")


# Merging Data Sets -----------------------------------------------------
rat_data <- report_data %>%
  mutate(`Council District` = as.numeric(`Council District`)) %>%
  left_join(district_data,
            join_by("Council District" == "council_district_id"))

council_data <- report_data %>%
  mutate(`Council District` = as.numeric(`Council District`)) %>%
  summarize(reports = n(),
            .by = `Council District`) %>%
  inner_join(district_data,
            join_by("Council District" == "council_district_id")) %>%
  select(-council_district_name)

time_area_data <- report_data %>%
  mutate(`Council District` = as.numeric(`Council District`),
         `Created Date` = mdy_hms(`Created Date`),
         month = month(`Created Date`),
         week = week(`Created Date`)) %>%
  summarize(reports = n(),
            .by = c(`Council District`), month)

# Writing Data ----------------------------------------------------------

vroom_write(rat_data,
            file = "rats.csv",
            delim = ",")

vroom_write(council_data,
            file = "councils.csv",
            delim = ",")

vroom_write(time_area_data,
            file = "time_area.csv",
            delim = ",")
