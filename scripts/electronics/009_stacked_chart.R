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
# Stacked area chart
# *******************************************************************************

# *******************************************************************************
# Import data

# Read inflow, stock and outflow data
unu_inflow_stock_outflow <- read_excel(
  "./cleaned_data/unu_inflow_stock_outflow.xlsx")

# Read UNU colloquial
UNU_colloquial <- read_xlsx("./classifications/classifications/UNU_colloquial.xlsx")

# Merge with UNU colloquial to get user-friendly naming
electronics_stacked_area_chart <- merge(unu_inflow_stock_outflow,
                                        UNU_colloquial,
                                        by=c("unu_key" = "unu_key")) %>%
  na.omit() %>%
  select(-unu_key) %>%
  mutate(across(c('value'), round, 0)) %>%
  filter(unit == "mass") %>%
  select(-c(unit))

# Write stacked area chart data to excel file
write_xlsx(electronics_stacked_area_chart, 
          "./cleaned_data/electronics_stacked_area_chart.xlsx")

# Write stacked area chart data
write_csv(electronics_stacked_area_chart, 
           "./cleaned_data/electronics_stacked_area_chart.csv")
