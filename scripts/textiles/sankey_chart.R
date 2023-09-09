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
# Import data

# Import data
textiles_sankey_links <- read_excel(
  "./raw_data/textiles/Outputs_ForDistribution_v2.xlsx",
  sheet = "Flows") %>%
  rename(source = Origin,
         target = Destination,
         value = Value_kt) %>%
  clean_names() %>%
  mutate(value = value*1000) %>%
  mutate(across(c('value'), round, 1)) %>%
  mutate(material = "Textiles",
         product = "Textiles") %>%
  mutate(across(everything(), ~ replace(., . == "Non-UK reuse", "Reused non-UK"))) %>%
  mutate(across(everything(), ~ replace(., . == "Non-UK disposals", "Disposed non-UK"))) %>%
  mutate(across(everything(), ~ replace(., . == "Reused UK", "UK reuse"))) %>%
  filter(value != 0) %>%
  write_csv(
    "./cleaned_data/textiles_sankey_links.csv")

