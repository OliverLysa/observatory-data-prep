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
              "rvest")

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

# Definitions: 
# Inflow: filter target column to consumption
# Outflow: filter target column to non-UK disposals and residual waste and sum

# To remove (manual extraction)
textiles_sankey_links_2018 <- read_csv(
  "./cleaned_data/textiles_sankey_links.csv") %>%
  filter()

# Read inflow, stock and outflow data for 2018
# Source: https://eprints.whiterose.ac.uk/198586/1/1-s2.0-S0959652623013161-main.pdf

# Specify the file from which to extract the table
pdf_file <- './raw_data/textiles/1-s2.0-S0959652623013161-main.pdf'

# Extract data frame from pdf using shiny/miniUI (brings up interactive window to drag to table of choice)
textiles_raw_2018 <- extract_areas(pdf_file, pages = 3) %>%
  as.data.frame() %>%
  select(-c(X4)) %>%
  row_to_names(1)

# *******************************************************************************
# Import scenario data and extract variables

# Variable filter list
filter_list <- c("Consumption",
                 "Non-UK disposals",
                 "Residual waste")

# Import projected data, filter to destination in filter list above and
textiles_sankey_projected <- read_excel(
  "./raw_data/textiles/Outputs_ForDistribution.xlsx") %>%
  filter(Destination %in% filter_list) %>%
  mutate(
    Destination = gsub("Non-UK disposals", 'outflow', Destination),
    Destination = gsub("Residual waste", 'outflow', Destination),
    Destination = gsub("Consumption", 'inflow', Destination)) %>%
  group_by(Destination, Year, Scenario) %>%
  summarise(value = sum(Value_kt)) %>%
  clean_names() %>%
  mutate(unit = "mass",
         product = "Textiles") %>%
  rename(variable = destination)
