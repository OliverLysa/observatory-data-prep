##### **********************
# Author: Oliver Lysaght
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
# Import baseline sankey data 
# *******************************************************************************

# *******************************************************************************
# Import 2018 data and calculate variables 

# Definitions: 
# Inflow: filter target column to consumption
# Outflow: filter target column to non-UK disposals and residual waste and sum

# Manual extraction
textiles_sankey_links_2018 <- read_csv(
  "./raw_data/textiles/textiles_sankey_links.csv") %>%
  filter() %>%
  mutate(scenario = "BAU_v6")

# Read inflow, stock and outflow data for 2018
# Source: https://eprints.whiterose.ac.uk/198586/1/1-s2.0-S0959652623013161-main.pdf

# Specify the file from which to extract the table
pdf_file <- './raw_data/textiles/1-s2.0-S0959652623013161-main.pdf'

# Extract data frame from pdf using shiny/miniUI (brings up interactive window to drag to table of choice)
textiles_raw_2018 <- extract_areas(pdf_file, pages = 3) %>%
  as.data.frame() %>%
  select(-c(X4)) %>%
  row_to_names(1)

# If any cell in row blank, combine contents of non-empty cells with those above as a suffix

# *******************************************************************************
# Import scenario data

# Import projected data, filter to destination in filter list above and
textiles_sankey_projected <- read_excel(
  "./raw_data/textiles/Outputs_ForDistribution.xlsx") %>%
  rename(source = Origin,
         target = Destination,
         value = Value_kt) %>%
  clean_names() %>%
  mutate(product = "Textiles",
         material = "Textiles")

# Bind 2018 data and scenario data and name changes for consistency
textiles_sankey <- rbindlist(
  list(
    textiles_sankey_links_2018,
    textiles_sankey_projected),
  use.names = TRUE) %>%
  mutate(value = value*1000) %>%
  mutate(across(c('value'), round, 1)) %>%
  mutate(across(everything(), ~ replace(., . == "Non-UK reuse", "Reused non-UK"))) %>%
  mutate(across(everything(), ~ replace(., . == "Non-UK disposals", "Disposed non-UK")))

# Write csv
write_csv(textiles_sankey,
  "./cleaned_data/textiles_sankey_links.csv")

