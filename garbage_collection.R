rat_data <- vroom("rats.csv")

rats_data <- rat_data %>%
  filter(as.character(Location) != "") %>%
  st_as_sf(., wkt = "Location", crs = 4326)

freq_data <- vroom("DSNY_Frequencies.csv")

freq_data <- freq_data %>%
  mutate(
    multipolygon = gsub("\n", " ", multipolygon),
    multipolygon = gsub("\r", " ", multipolygon)
  ) %>%
  st_as_sf(., wkt = "multipolygon", crs = 4326) %>%
  st_make_valid(.)

rat_freq_data <- st_join(rats_data, freq_data)

rat_freq_data %>%
  st_drop_geometry(.) %>%
  mutate(`Council District` = as.numeric(`Council District`),
       `Created Date` = mdy_hms(`Created Date`),
       month = month(`Created Date`),
       week = week(`Created Date`),
       dow = wday(`Created Date`)
) %>%
  summarize(reports = n(),
            .by = c(dow, FREQUENCY)) %>%
  # filter(`Council District` %in% sample(`Council District`, size = 5)) %>%
  ggplot(mapping = aes(x = dow,
                       y = reports)
  ) +
  geom_line(aes(color = factor(FREQUENCY)))

