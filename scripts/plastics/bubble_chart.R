# *******************************************************************************
# Packages
# *******************************************************************************
# Package names
packages <- c("magrittr", 
              "writexl", 
              "readxl", 
              "dplyr", 
              "tidyverse", 
              "readODS", 
              "data.table", 
              "mixdist",
              "janitor",
              "logOfGamma")

# Install packages not yet installed
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}

# Packages loading
invisible(lapply(packages, library, character.only = TRUE))

# *******************************************************************************
# Functions and options
# *******************************************************************************

# Import functions
source("./scripts/functions.R", 
       local = knitr::knit_global())

# Stop scientific notation of numeric values
options(scipen = 999)

# *******************************************************************************
# Extract and match
# *******************************************************************************

# Import consumption
SW_all <- read_excel(
  "./plastics/received/210521_EXEmPlar_Sankey string_SW.xlsx",
  sheet = "Sorting_SW") %>%
  # remove the top row
  slice(-1) %>%
  # remove columns where all rows are na
  select_if(function(x) !(all(is.na(x)) | all(x=="")))

# Create inflow variable
consumption <- SW_all %>%
  select(7:8) %>%
  rename(product = 1,
         consumption = 2) %>%
  na.omit()

# Get EoL data 
EoL_Cornwall <- read_xlsx( 
  "./plastics/EXEmPlar_Plastic Flow Analysis_DRAFT_2.xlsx",
  sheet = "EoL_Cornwall",
  range = "C6:G71") %>%
  drop_na(Reused_C)

EoL_Devon <- read_xlsx( 
  "./plastics/EXEmPlar_Plastic Flow Analysis_DRAFT_2.xlsx",
  sheet = "EoL_Devon",
  range = "C6:G71") %>%
  drop_na(Reused_D)

EoL_Somerset <- read_xlsx( 
  "./plastics/EXEmPlar_Plastic Flow Analysis_DRAFT_2.xlsx",
  sheet = "EoL_Somerset",
  range = "C6:G71") %>%
  drop_na(Reused_S)

# Get average of EoL data across the regions
EoL_all <- rbindlist(
  list(
    EoL_Cornwall,
    EoL_Devon,
    EoL_Somerset),
  use.names = FALSE) %>%
  rename(product = 1,
         reuse = 2,
         burned_buried = 3,
         lost = 4,
         disposal = 5) %>%
  pivot_longer(-c(product),
             names_to = 'route',
             values_to = 'value') %>%
  na.omit() %>%
  group_by(product, route) %>%
  summarise(average = mean(value))

# Import score weighting based on EMF CE Model
outflow_routing_weights <- read_excel(
  "./intermediate_data/weights.xlsx",
  sheet = "Exemplar")

# Scoring logic based on the EMF CE-model 

# Reused: 10 
# Recycling: 6
# Downcycling: -6 
# Export: -6 
# Landfill: -8 
# Lost: -8 
# Leakage: -10 
# Incineration: -10 
# Buried: -10

# Merge outflow routing with outflow routing weights
outflow_routing_weighted <- merge(EoL_all,
                                  outflow_routing_weights,
                                  by.x=c("route"),
                                  by.y=c("route")) %>%
  mutate(route_score = average*weight) %>%
  group_by(product) %>%
  summarise(ce_score = sum(route_score))

# Merge variables together
plastics_bubble_chart <- 
  left_join(
    consumption,
    outflow_routing_weighted,
    by = c("product")) %>%
  filter(product != "Total")

# Turn NA values into a 0
plastics_bubble_chart["ce_score"][is.na(plastics_bubble_chart["ce_score"])] <- 0

# Write file   
write_csv(plastics_bubble_chart,
          "./cleaned_data/plastics_bubble_chart.csv")
