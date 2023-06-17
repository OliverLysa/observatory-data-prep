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
# Bubble chart data

# Read input data for lifespan and mass
inflow_weibull <- read_xlsx( 
           "./cleaned_data/inflow_weibull.xlsx") %>%
  # Calculate mean from Weibull parameters
  mutate(average = scale*exp(gammaln(1+1/shape)))


J4×(LN(2))^(1÷I4)

# Map flows data to electronics bubble chart
electronics_bubble_flows <- flows_all %>%
  # filter to 2017, variable = Units, indicator = apparent_consumption
  filter(year == 2017,
         variable == 'Units',
         indicator == "apparent_consumption") %>%
  select(-c(year, 
            variable, 
            indicator)) %>%
  rename(apparent_consumption = value)

# Convert unit flow data to mass using the Bill of Materials
Babbit_product_total_mass <- BoM_data_average %>%
  group_by(product) %>%
  summarise(value = sum(value))

# Map lifespan data to electronics bubble chart
mean_lifespan <- lifespan_data %>%
  select(c(unu, mean)) %>%
  rename(mean_lifespan = mean)

electronics_bubble_chart <- merge(electronics_bubble_flows,
                                  mean_lifespan,
                                  by.x=c("unu_key"),
                                  by.y=c("unu")) %>%
  mutate(across(c('mean_lifespan'), round, 1))

electronics_bubble_chart2 <- merge(electronics_bubble_chart,
                                   electronics_bubble_outflow,
                                   by.x=c("unu_key"),
                                   by.y=c("UNU KEY")) %>%
  rename(ce_score = scaled)

write_xlsx(electronics_bubble_chart2, 
           "./cleaned_data/electronics_bubble_chart.xlsx")

# UNU <- electronics_bubble_chart2 %>%
#  select(c(unu_key, `UNU DESCRIPTION`))

UNU_colloquial <- electronics_bubble_chart2 %>%
  select(-c(apparent_consumption, 
            mean_lifespan, 
            Year,
            ce_score)) %>%
  clean_names()

write_xlsx(UNU_colloquial, 
           "./classifications/classifications/UNU_colloquial.xlsx")

electronics_bubble_chart2 <- read_excel(
  "./cleaned_data/electronics_bubble_chart.xlsx")
