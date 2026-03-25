# DSNY Site:
# https://data.cityofnewyork.us/browse?Dataset-Information_Agency=Department+of+Sanitation+%28DSNY%29&sortBy=relevance&pageSize=20&page=1

library(vroom)
library(dplyr)

# Load in Data -----------------------------------------------------------------

district_data <- vroom("DSNY_Districts.csv")
freq_data <- vroom("DSNY_Frequencies.csv")
litter_data <- vroom("DSNY_Litter_Basket_Inventory.csv")
recycle_data <- vroom("DSNY_Public_Recycling_Bins.csv")
food_data <- vroom("DSNY_Food_Scrap_Drop-Off_Locations.csv")


# Clean Data -------------------------------------------------------------------

# District Data
district_data <- district_data %>%
  rename(DISTRICT_AREA=SHAPE_Area,
         DISTRICT_LENGTH=SHAPE_Length,
         DISTRICT_MP=multipolygon) %>%
  select(DISTRICT,DISTRICT_AREA,DISTRICT_LENGTH,DISTRICT_MP)

# Frequency Data
# A = Mon, Wed, Fri; B = Tue, Thu, Sat; C = Mon, Thu; D = Tue, Fri; E = Wed, Sat. 
freq_data <- freq_data %>%
  rename(COLLECTION_DAYS=FREQUENCY) %>%
  select(DISTRICT,SECTION,COLLECTION_DAYS)

# Litter Data
litter_data <- litter_data %>%
  rename(LITTER_BASKET=BASKETTYPE) %>%
  select(SECTION,LITTER_BASKET)
litter_quant_data <- litter_data %>%
  group_by(SECTION) %>%
  summarise(NUM_LITTER_BASKETS=n())

# Recycling Data
recycle_data <- recycle_data %>%
  rename(DISTRICT="DSNY District",
         PAPER_BINS="Paper Bins",
         MGP_BINS="MGP Bins") %>%
  select(DISTRICT,PAPER_BINS,MGP_BINS)
recycle_quant_data <- recycle_data %>%
  group_by(DISTRICT) %>%
  summarise(NUM_PAPER_BINS=sum(PAPER_BINS),
            NUM_MGP_BINS=sum(MGP_BINS))

# Food Scrap Data
food_data <- food_data %>%
  rename(SECTION="DSNY Section",
         FOOD_LOCATION="Location Point") %>%
  select(SECTION,FOOD_LOCATION)
food_quant_data <- food_data %>%
  group_by(SECTION) %>%
  summarise(NUM_FOOD_SCRAP_LOCATIONS=n())
food_quant_data_no_nas <- food_quant_data %>%
  filter(!is.na(SECTION))


# Join Data --------------------------------------------------------------------

stuff1 <- merge(district_data,freq_data,by="DISTRICT",all=TRUE)
stuff2 <- merge(stuff1,litter_quant_data,by="SECTION",all=TRUE)
stuff3 <- merge(stuff2,recycle_quant_data,by="DISTRICT",all=TRUE)
all_data <- merge(stuff3,food_quant_data_no_nas,by="SECTION",all=TRUE)

all_data[is.na(all_data)] <- 0








- pest control
- sewers










