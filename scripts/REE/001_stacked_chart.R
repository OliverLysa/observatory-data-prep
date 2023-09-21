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
         scenario = "Baseline_life_zero_eol", .before = Time) 

# Extract low lifespan, high circularity scenario for wind
wind_low_lifespan_high_circularity <- 
  REE_vensim_all[["2. Wi_20y_High CE_2"]] %>%
  mutate(product = "Wind turbine",
         scenario = "Baseline_life_high_eol", .before = Time)

# Extract high lifespan, low circularity scenario for wind
wind_high_lifespan_low_circularity <- 
  REE_vensim_all[["3. Wi_30y_zero CE_3"]] %>%
  mutate(product = "Wind turbine",
         scenario = "Extended_life_zero_eol", .before = Time)

# Extract high lifespan, high circularity scenario for wind
wind_high_lifespan_high_circularity <- 
  REE_vensim_all[["4. Wi_30y lifespan_High CE_4"]] %>%
  mutate(product = "Wind turbine",
         scenario = "Extended_life_high_eol", .before = Time)

## BEV

# Extract low lifespan, low circularity scenario for EV
EV_low_lifespan_low_circularity <- 
  REE_vensim_all[["1. EV_14y_zero CE_1"]] %>%
  mutate(product = "BEV",
         scenario = "Baseline_life_zero_eol", .before = Time)

# Extract low lifespan, low circularity scenario for EV
EV_low_lifespan_high_circularity <- 
  REE_vensim_all[["2. EV_14y_high CE_2"]] %>%
  mutate(product = "BEV",
         scenario = "Baseline_life_high_eol", .before = Time)

# Extract low lifespan, low circularity scenario for EV
EV_high_lifespan_low_circularity <- 
  REE_vensim_all[["3. EV_18y_zero CE_3"]] %>%
  mutate(product = "BEV",
         scenario = "Extended_life_zero_eol", .before = Time)

# Extract high lifespan, high circularity scenario for EV 
EV_high_lifespan_high_circularity <- 
  REE_vensim_all[["4. EV_18y_High CE_4"]] %>%
  mutate(product = "BEV",
         scenario = "Extended_life_high_eol", .before = Time)

# Create lookup for flows
variable <- c('Inflow','Stock','Outflow','Inflow (virgin)')
filter <- c('Total','Total','Total','Virgin')
filter_lookup <- data.frame(variable, filter)

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
  rename(variable = 3,
         metric = 4) %>%
  filter(grepl('Release rate 6|Release rate 7|Release rate 6 R|Release rate 7 R|Consume \\(use\\) S|Virgin material 6', variable)) %>%
  select(-metric) %>%
  pivot_longer(-c(product, scenario, variable),
               names_to = "year",
               values_to = "value") %>%
  mutate(variable = gsub("Release rate 6 R", "Inflow", variable),
         variable = gsub("Release rate 6", "Inflow", variable),
         variable = gsub("Release rate 7 R", "Outflow", variable),
         variable = gsub("Release rate 7", "Outflow", variable),
         variable = gsub("Virgin material 6", "Inflow (virgin)", variable),
         variable = gsub("\"", "", variable),
         variable = gsub("Consume \\(use\\) S", "Stock", variable)) %>%
  # Convert any negatives to 0
  mutate(value = if_else(value < 0, 0, value)) %>%
  mutate(across(c('value'), round, 2)) %>%
  right_join(filter_lookup, by = c("variable")) 

REE_stacked_area <- REE_stacked_area %>%
  mutate(across(everything(), ~ replace(., . == "Inflow (virgin)", "Inflow")))
  
# Write csv file
write_csv(REE_stacked_area,
          "./cleaned_data/REE_chart_stacked_area.csv")
