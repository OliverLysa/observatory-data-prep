##### **********************
# Author: Oliver Lysaght
# Purpose: Converts cleaned data into sankey format for presenting in sankey chart
# Inputs:
# Required updates:

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
# REE

# REE Data input
REE_sankey_links <- read_xlsx("./intermediate_data/REE_sankey_links.xlsx") %>%
  mutate(across(c('value'), round, 2)) %>%
  filter(!year < 2007 | product != "BEV") %>%
  filter(target != "Lost") %>%
  mutate(value = gsub("-", "", value))

# Write CSV
write_csv(REE_sankey_links,
          "./cleaned_data/REE_sankey_links.csv")
