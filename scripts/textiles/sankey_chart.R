##### **********************
# Purpose: Converts cleaned data into sankey format for presenting in sankey chart

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
# Proportional data
# *******************************************************************************

# Read proportion data
# This approach assumes that proportions are the same across all years/value chain stages
textiles_percentage <- read_xlsx(
  "./intermediate_data/textiles_composition.xlsx") %>%
  mutate_at(c('proportion'), as.numeric)

# *******************************************************************************
# Import total mass flows

# Import data
textiles_sankey_links <- read_excel(
  "./raw_data/textiles/Outputs_ForDistribution_v2.xlsx",
  sheet = "Flows") %>%
  # rename columns
  rename(source = Origin,
         target = Destination,
         value = Value_kt) %>%
  # clean all names
  clean_names() %>%
  # multiply value by 1000 to convert to tonnes (shorthand built into javascript)
  mutate(Value = value * 1000) %>%
  # mutate to add product column
  mutate(product = "Clothing") %>%
  # Rename
  mutate(across(everything(), ~ replace(., . == "Non-UK reuse", "Reused non-UK"))) %>%
  mutate(across(everything(), ~ replace(., . == "Non-UK disposals", "Disposed non-UK"))) %>%
  mutate(across(everything(), ~ replace(., . == "Reused UK", "UK reuse"))) %>%
  # Right join to compositional data
  right_join(textiles_percentage, by = c("product")) %>%
  # Convert value to numeric
  mutate_at(c('Value'), as.numeric) %>%
  # Multiply material composition (breakdown of total product) by inflows
  mutate(value = Value*proportion) %>%
  # Remove unwanted columns
  select(-c(Value, proportion)) %>%
  # Remove any 0 flows
  filter(value != 0,
         year != 2018) %>%
  # Round
  mutate(across(c('value'), round, 2)) %>%
  write_csv(
    "./cleaned_data/textiles_sankey_links.csv")



