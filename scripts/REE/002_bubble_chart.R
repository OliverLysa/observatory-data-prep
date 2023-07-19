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
# REE

# Import consumption/inflow data
consumption <- read_csv("./cleaned_data/REE_chart_stacked_area.csv") %>%
  filter(variable == "Inflow")

# REE Data input
REE_chart_bubble <- read_xlsx("./cleaned_data/REE_chart_bubble.xlsx") %>%
  mutate(across(c('mass'), round, 1))

# Merge datasets across the variables listed, clean table for supabase
REE_chart_bubble <- merge(consumption, REE_chart_bubble,
                   by = c("product", "scenario", "year")) %>%
  select(-c(aggregation, variable, mass, unit)) %>%
  rename("mass" = value)

# Write file
write_csv(REE_chart_bubble,
          "./cleaned_data/REE_chart_bubble.csv")
