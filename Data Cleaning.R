# Loading Libraries -----------------------------------------------------
library(tidyverse)
library(vroom)
library(readxl)
library(lubridate)


# Reading In Data -------------------------------------------------------
report_data <- vroom("311_rodent_calls.csv")
district_data <- read_xlsx("nyc_council_context.xlsx")

# Resolution Description Mapping ----------------------------------------

resolution_descriptions <- c(
  "The Department of Health and Mental Hygiene found violations on the property you reported. Follow-up inspections will be scheduled.",
  "The Department of Health and Mental Hygiene tried to inspect the property you reported but could not access the site. If you have information that will help the inspector access the site, please go online to nyc.gov/311 or call 311 and refile your complaint with contact information.",
  "This service request was closed because the Department of Health and Mental Hygiene received an earlier complaint about the same location.  You can find inspection results for this address by going to the online Rat Portal at www.nyc.gov/rats.",
  "The Department of Health and Mental Hygiene inspected the property you reported and did not find any violations at the time of the inspection. The property passed inspection.",
  "An inspection of the property was conducted and it passed with minor violations found.",
  NA,
  "An inspection of this property was conducted and violations were identified. The owner is correcting the condition. If the condition persists, please submit another complaint to 311.",
  "The Department of Health and Mental Hygiene could not locate the address provided. Please go online to nyc.gov/311 or call 311 and file another request and provide the complete street address of the builiding. If your complaint was about a vacant lot, abandoned building ,street, or in a sewer, provide the nearest street address or intersection.",
  "The Department of Health and Mental Hygiene closed this complaint and referred it to another agency because it was not within its jurisdiction.",
  "The Department of Health and Mental Hygiene (DOHMH) actioned and closed your service request. No further updates will be available.",
  "An investigation was performed on this property and the property owner was provided with information and guidance on eliminating rodents or rodent conditions on their property. If the condition persists, please submit another complaint to 311.",
  "The Department of Health and Mental Hygiene could not conduct an inspection at the property you reported because dangerous conditions at that site make it unsafe for inspectors to attempt access."
)

resolution_statuses <- c(
  "Confirmed", "No determination/administrative", "No determination/administrative", 
  "Not Confirmed", "Not Confirmed", "No determination/administrative", 
  "Confirmed", "No determination/administrative", "No determination/administrative",
  "No determination/administrative", "Confirmed", "Not Confirmed"
)

res_map <- data.frame(resolution_description = resolution_descriptions,
                      resolution_status = resolution_statuses)

report_data <- report_data %>% 
  left_join(res_map, 
            join_by("Resolution Description" == "resolution_description"))


# Merging Data Sets, counting reports by type, computing reporting rates--
rat_data <- report_data %>%
  mutate(`Council District` = as.numeric(`Council District`)) %>%
  left_join(district_data,
            join_by("Council District" == "council_district_id"))

council_data <- report_data %>%
  mutate(`Council District` = as.numeric(`Council District`)) %>%
  summarize(reports = n(),
            confirmed_reports = sum(resolution_status == "Confirmed"),
            .by = `Council District`) %>%
  inner_join(district_data,
             join_by("Council District" == "council_district_id")) %>%
  dplyr::select(-council_district_name) %>%
  mutate(rate_all = (reports/population) * 1000,
         rate_confirmed = (confirmed_reports/population) * 1000)

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

