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
# Use ---------------------------

#### Extract lifespan/residence-time data ####

# Time in use and time in storage 

# Import lifespan data
lifespan_data <- read_excel(
  "./cleaned_data/electronics_lifespan.xlsx",
  sheet = 1,
  range = "A2:AY75")

# Rename columns and clean names
lifespan_data <- lifespan_data[c(1:73), c(1,4,7:50)] %>%
  rename(UNU = 1,
         UNU_5 = 2,
         Shape = 3,
         Scale = 4) %>%
  clean_names()

# Specify x-axis (time periods for which distribution is printed
x_axis <- seq(0, 50, 
              by = 1)

# for (i in seq_along(lifespan_data)) {
#  cdweibull(x_axis, lifespan_data$shape, lifespan_data$scale)
#  }

# Calculate mean and median from Weibull parameters
# weibullparinv(1.6, 8.1599999951404, loc = 0)

# Derive Weibull parameters from Open Repair Data

### Stock data: Electrical products data tables (represent an underestimate)

# https://onlinelibrary.wiley.com/doi/abs/10.1111/jiec.12551
# https://www.sciencedirect.com/science/article/abs/pii/S0959652618339660