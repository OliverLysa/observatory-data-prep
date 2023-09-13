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
# Import and export bubble data
# *******************************************************************************

bubble_data <- read_excel(
  "./raw_data/textiles/Outputs_ForDistribution_v2.xlsx",
  sheet = "Impacts") %>%
  pivot_wider(names_from = Impact, 
              values_from = Value) %>%
  clean_names() %>%
  rename(energy = energy_pj,
         ghgs = gh_gs_mt,
         land = land_km2,
         water = water_million_m3) %>%
  mutate_if(is.numeric, round, digits = 1) %>%
  mutate(product = "Clothing") %>%
  write_csv("./cleaned_data/textiles_chart_bubble.csv")

