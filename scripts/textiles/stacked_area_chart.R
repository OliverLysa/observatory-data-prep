##### **********************
# Author: Oliver Lysaght
# Purpose: Import textiles baseline and scenario data published by Millward-Hopkins and create stacked area chart input

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
              "tabulizer",
              "pdftools",
              "data.table",
              "shiny",
              "miniUI",
              "rvest",
              "DataEditR")

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

# Turn off scientific notation of numeric values
options(scipen = 999)

# *******************************************************************************
# Data extraction
# *******************************************************************************
  
# *******************************************************************************
# Extract variables

# Non-UK disposals vs. UK disposals
# Recycled, UK reuse and non-UK reuse (aggregate)

# Create filter list for variables
filter_list <- c("Consumption",
                 "Non-UK disposals",
                 "Residual waste",
                 "UK reuse",
                 "Reused non-UK")

# Import sankey data 
textiles_area <- read_csv(
          "./cleaned_data/textiles_sankey_links.csv") %>%
  filter(target %in% filter_list) %>%
  mutate(
    target = gsub("Consumption", 'consumption',target),
    target = gsub("UK reuse", 'reuse',target),
    target = gsub("Reused UK", 'reuse',target),
    target = gsub("Reused non-UK", 'reuse',target),
    target = gsub("Non-UK disposals", 'waste', target),
    target = gsub("Residual waste", 'waste', target)) %>%
  group_by(target, year, scenario) %>%
  summarise(value = sum(value)) %>%
  clean_names() %>%
  rename(variable = target) %>%
  mutate(product = "Clothing") %>%
  write_csv("./cleaned_data/textiles_chart_area.csv")
