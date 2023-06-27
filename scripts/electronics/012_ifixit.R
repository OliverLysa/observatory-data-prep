##### **********************
# Author: Oliver Lysaght
# Purpose: Download iFixit repairability score data
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
source("./data_extraction_scripts/functions.R", 
       local = knitr::knit_global())

# Stop scientific notation of numeric values
options(scipen = 999)

# *******************************************************************************
# iFixit

# Read in the data
iFixit <- read_excel(
  "./raw_data/IFixit.xlsx", sheet = 1, range = "A1:E238")

# Group by and summarise
grouped <- iFixit %>% 
  group_by(Product, Make, Year) %>%
  summarise(Value = round(mean(Repairability_Score),1)) 

# Write file 
write_xlsx(grouped, 
           "./cleaned_data/iFixit.xlsx")
