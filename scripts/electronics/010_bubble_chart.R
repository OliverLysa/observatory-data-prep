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
              "janitor"
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
source("./data_extraction_scripts/functions.R", 
       local = knitr::knit_global())

# Stop scientific notation of numeric values
options(scipen = 999)

# *******************************************************************************
# Bubble chart data

# Read input data for lifespan and mass 
# This input is used in the earlier stock calculation
inflow_weibull_chart <- read_xlsx( 
           "./cleaned_data/inflow_weibull.xlsx") %>%
  # Calculate mean and median from Weibull parameters
  mutate(average = scale*exp(gammaln(1+1/shape)),
         median = scale*(log(2))^(1/shape)) %>%
  filter(unit == "mass") %>%
  select(-c(shape,
            scale,
            variable,
            unit,
            median))

electronics_bubble_chart2 <- read_excel(
  "./cleaned_data/electronics_bubble_chart.xlsx")
