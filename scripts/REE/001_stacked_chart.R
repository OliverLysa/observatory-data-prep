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
              "janitor")

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
# REE - taken from pages with the following naming scheme '1. Wi_20y_zero CE_1' 

# Import the vensim output in spreadsheet format
REE_vensim_all <- read_excel_allsheets(
  "./raw_data/230807_Wind_REE Scenarios_Sankey string generator_SEin.xlsx")

## Extract wind data

# Extract low lifespan, low circularity scenario for wind
wind_low_lifespan_low_circularity <- 
  REE_vensim_all[["1. Wi_20y_zero CE_1"]] %>%
  mutate(product = "Wind turbine",
         aggregation = "material",
         scenario = "Baseline_life_zero_eol", .before = Time) %>%
  rename(variable = 4,
         metric = 5)

# Extract low lifespan, high circularity scenario for wind
wind_low_lifespan_high_circularity <- 
  REE_vensim_all[["2. Wi_20y_High CE_2"]] %>%
  mutate(product = "Wind turbine",
         aggregation = "material",
         scenario = "Baseline_life_high_eol", .before = Time) %>%
  rename(variable = 4,
         metric = 5)

# Extract high lifespan, low circularity scenario for wind
wind_high_lifespan_low_circularity <- 
  REE_vensim_all[["3. Wi_30y_zero CE_3"]] %>%
  mutate(product = "Wind turbine",
         aggregation = "material",
         scenario = "Extended_life_zero_eol", .before = Time) %>%
  rename(variable = 4,
         metric = 5)

# Extract high lifespan, high circularity scenario for wind
wind_high_lifespan_high_circularity <- 
  REE_vensim_all[["4. Wi_30y lifespan_High CE_4"]] %>%
  mutate(product = "Wind turbine",
         aggregation = "material",
         scenario = "Extended_life_high_eol", .before = Time) %>%
  rename(variable = 4,
         metric = 5)

## BEV

# Extract low lifespan, low circularity scenario for EV
EV_low_lifespan_low_circularity <- 
  REE_vensim_all[["1. EV_14y_zero CE_1"]] %>%
  mutate(product = "BEV",
         aggregation = "material",
         scenario = "Baseline_life_zero_eol", .before = Time) %>%
  rename(variable = 4,
         metric = 5)

# Extract low lifespan, low circularity scenario for EV
EV_low_lifespan_high_circularity <- 
  REE_vensim_all[["2. EV_14y_high CE_2"]] %>%
  mutate(product = "BEV",
         aggregation = "material",
         scenario = "Baseline_life_high_eol", .before = Time) %>%
  rename(variable = 4,
         metric = 5)

# Extract low lifespan, low circularity scenario for EV
EV_high_lifespan_low_circularity <- 
  REE_vensim_all[["3. EV_18y_zero CE_3"]] %>%
  mutate(product = "BEV",
         aggregation = "material",
         scenario = "Extended_life_zero_eol", .before = Time) %>%
  rename(variable = 4,
         metric = 5)

# Extract high lifespan, high circularity scenario for EV 
EV_high_lifespan_high_circularity <- 
  REE_vensim_all[["4. EV_18y_High CE_4"]] %>%
  mutate(product = "BEV",
         aggregation = "material",
         scenario = "Extended_life_high_eol", .before = Time) %>%
  rename(variable = 4,
         metric = 5)

# Bind the extracted data to create a complete dataset, filter to variables of interest and rename these variables
REE_stacked_area <-
  rbindlist(
    list(
      wind_low_lifespan_low_circularity,
      wind_low_lifespan_high_circularity,
      wind_high_lifespan_low_circularity,
      wind_high_lifespan_high_circularity,
      EV_low_lifespan_low_circularity,
      EV_low_lifespan_high_circularity,
      EV_high_lifespan_low_circularity,
      EV_high_lifespan_high_circularity
    ),
    use.names = TRUE
  ) %>%
  filter(grepl('Release rate 6|Release rate 7|Release rate 6 R|Release rate 7 R|Consume \\(use\\) S', variable)) %>%
  select(-metric) %>%
  pivot_longer(-c(product, aggregation, scenario, variable),
               names_to = "year",
               values_to = "value") %>%
  mutate(variable = gsub("Release rate 6 R", "Inflow", variable),
         variable = gsub("Release rate 6", "Inflow", variable),
         variable = gsub("Release rate 7 R", "Outflow", variable),
         variable = gsub("Release rate 7", "Outflow", variable),
         variable = gsub("\"", "", variable),
         variable = gsub("Consume \\(use\\) S", "Stock", variable)) %>%
  mutate(across(c('value'), round, 2)) %>%
  mutate(unit = "mass")

# Write csv file
write_csv(REE_stacked_area,
          "./cleaned_data/REE_chart_stacked_area.csv")
