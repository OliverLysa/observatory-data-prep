##### **********************
# Author: Oliver Lysaght
# Purpose:
# Inputs:
# Required annual updates:
# The URL to download from

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
source("./scripts/functions.R", 
       local = knitr::knit_global())

# Stop scientific notation of numeric values
options(scipen = 999)

# *******************************************************************************
# Calculate outflows - EEE moving on from use, storage and hoarding
# *******************************************************************************

# https://onlinelibrary.wiley.com/doi/abs/10.1111/jiec.12551
# https://www.sciencedirect.com/science/article/abs/pii/S0959652618339660

# Import lifespan data - these need to be reviewed further to work out exactly to which period they refer. e.g. inflow through exiting stock
# or inflow through hibernation etc. 
lifespan_data <- read_excel("./cleaned_data/electronics_lifespan.xlsx",
                            sheet = 1,
                            range = "A2:AY75")

# Keep only collated lifespan data columns and rename
lifespan_data_filtered <- lifespan_data[c(1:54), c(1, 7, 8)] %>%
  rename(unu_key = 1,
         shape = 2,
         scale = 3) %>%
  na.omit()

# Import inflow data to match to lifespan
inflow_unu_mass_units <-
  read_xlsx("./cleaned_data/inflow_unu_mass_units.xlsx")

# Merge inflow and lifespan data by unu_key
inflow_weibull <-
  merge(
    inflow_unu_mass_units,
    lifespan_data_filtered,
    by = c("unu_key"),
    all.x = TRUE
  )

# Write summary file
write_xlsx(inflow_weibull, 
           "./cleaned_data/inflow_weibull.xlsx")

# Set up dataframe for outflow calculation based on Balde et al 2016. Create empty columns for all years in range of interest
year_first <- min(as.integer(inflow_weibull$year))
year_last <- max(as.integer(inflow_weibull$year)) + 30
years <- c(year_first:year_last)
empty <-
  as.data.frame(matrix(NA, ncol = length(years), nrow = nrow(inflow_weibull)))
colnames(empty) <- years

# Add the empty columns to inflow weibull dataframe
inflow_weibull_outflow <- cbind(inflow_weibull, empty)
rm(empty)

# Calculate WEEE from inflow year based on shape and scale parameters
for (i in year_first:year_last) {
  inflow_weibull_outflow$WEEE_POM_dif <-
    i - (as.integer(inflow_weibull[, "year"]))
  wb <-
    dweibull(
      inflow_weibull_outflow[(inflow_weibull_outflow$WEEE_POM_dif >= 0), "WEEE_POM_dif"] + 0.5,
      shape = inflow_weibull_outflow[(inflow_weibull_outflow$WEEE_POM_dif >= 0), "shape"],
      scale = inflow_weibull_outflow[(inflow_weibull_outflow$WEEE_POM_dif >= 0), "scale"],
      log = FALSE
    )
  weee <-
    wb * inflow_weibull_outflow[(inflow_weibull_outflow$WEEE_POM_dif >= 0), "value"]
  inflow_weibull_outflow[(inflow_weibull_outflow$WEEE_POM_dif >= 0), as.character(i)] <-
    weee
}

# Make long format while including the year placed on market
inflow_weibull_long <- inflow_weibull_outflow %>% select(-c(shape,
                                                    scale,
                                                    value,
                                                    WEEE_POM_dif)) %>%
  rename(year_pom = year) %>%
  mutate(variable = gsub("inflow",
                         "outflow",
                         variable)) %>%
  pivot_longer(-c(unu_key,
                  year_pom,
                  unit,
                  variable),
               names_to = "year",
               values_to = "value") %>%
  na.omit()

# Make long format aggregating by year outflow (i.e. suppressing year POM)
inflow_weibull_long_outflow_summary <- inflow_weibull_outflow %>%
  select(-c(shape,
            scale,
            value,
            WEEE_POM_dif)) %>%
  rename(year_pom = year) %>%
  mutate(variable = gsub("inflow",
                         "outflow",
                         variable)) %>%
  pivot_longer(-c(unu_key,
                  year_pom,
                  unit,
                  variable),
               names_to = "year",
               values_to = "value") %>%
  na.omit() %>%
  group_by(unu_key, 
           unit, 
           variable, 
           year) %>%
  summarise(value = 
              sum(value))

# Bind the inflow and outflow data (with stock to be added next)
unu_inflow_outflow <-
  rbindlist(
    list(
      inflow_unu_mass_units,
      inflow_weibull_long_outflow_summary
    ),
    use.names = TRUE
  ) %>%
  na.omit()

## STOCK CALCULATION - based on https://github.com/Statistics-Netherlands/ewaste/blob/master/scripts/05_Make_tblAnalysis.R

# Merge the two datasets covering inflows and outflow horizontally for the subsequent stock calculation 
inflow_outflow_merge <-
  merge(
    inflow_unu_mass_units,
    inflow_weibull_long_outflow_summary,
    by = c("unu_key", "year", "unit"),
    all.x = TRUE
  ) %>%
  select(-c("variable.x",
            "variable.y")) %>%
  rename(inflow = 4,
         outflow = 5)

# Calculate the stock (historic POM - historic WEEE) in weight and units by calculating the cumulative sums and then subtracting from each other 

# Calculate cumulative sums per group
tbl_stock <- data.table(inflow_outflow_merge)
tbl_stock[, inflow_cumsum := cumsum(inflow), by=list(unu_key, unit)]
tbl_stock[, outflow_cumsum := cumsum(outflow), by=list(unu_key, unit)]

# Calculate stock by year subtracting cumulative outflows from cumulative inflows
tbl_stock$stock <- tbl_stock$inflow_cumsum - tbl_stock$outflow_cumsum
# Convert into dataframe
tbl_stock <- as.data.frame(tbl_stock)

# Select columns of interest for merge
unu_stock <- tbl_stock %>%
  select(c("unu_key",
            "year",
           "unit",
           "stock"))

# Merge inflow, stock and outflow, pivot longer
unu_inflow_stock_outflow <-
  merge(
    inflow_outflow_merge,
    unu_stock,
    by = c("unu_key", "year", "unit"),
    all.x = TRUE
  ) %>%
  pivot_longer(-c(unu_key,
                  year,
                  unit),
               names_to = "variable",
               values_to = "value")
  
# Write summary file
write_xlsx(unu_inflow_stock_outflow, 
           "./cleaned_data/unu_inflow_stock_outflow.xlsx")

