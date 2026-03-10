# Loading Libraries -----------------------------------------------------
library(tidyverse)
library(vroom)
library(readxl)


# Reading In Data -------------------------------------------------------
report_data <- vroom("311_rodent_calls.csv")
district_data <- read_xlsx("nyc_council_context.xlsx")


# Merging Data Sets -----------------------------------------------------
rat_data <- report_data %>%
  mutate(`Council District` = as.numeric(`Council District`)) %>%
  left_join(district_data,
            join_by("Council District" == "council_district_id"))


# Writing Data ----------------------------------------------------------

vroom_write(rat_data,
            file = "rats.csv",
            delim = ",")