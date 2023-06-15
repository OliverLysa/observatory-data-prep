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
              "RSelenium", 
              "netstat", 
              "uktrade", 
              "httr",
              "jsonlite",
              "mixdist",
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
# Data extraction
# *******************************************************************************

# Import lifespan data
lifespan_data <- read_excel(
  "./cleaned_data/electronics_lifespan.xlsx",
  sheet = 1,
  range = "A2:AY75")

# Rename columns and clean names
lifespan_data_filtered <- lifespan_data[c(1:54), c(1,7,8)] %>%
  rename(unu_key = 1,
         shape = 2,
         scale = 3) %>%
  na.omit() 

for (i in seq_along(unu_keys)) {
  weibullparinv(lifespan_data_filtered$shape, lifespan_data_filtered$scale, loc = 0)
}

# Calculate mean and median from Weibull parameters
# weibullparinv(1.6, 8.1599999951404, loc = 0)

### Stock data: Electrical products data tables (represent an underestimate)

# https://onlinelibrary.wiley.com/doi/abs/10.1111/jiec.12551
# https://www.sciencedirect.com/science/article/abs/pii/S0959652618339660