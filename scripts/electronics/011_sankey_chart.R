##### **********************
# Author: Oliver Lysaght
# Purpose: Converts cleaned data into sankey format
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
# SANKEY

# Import BoM data for most recent product within each group
BoM_recent <- read_excel(
  "./cleaned_data/BoM_data_average_int2.xlsx")

# Renames columns
Babbit_sankey_input <- BoM_recent %>%
  mutate(source = material) %>%
  rename(target = component)

# Reorders columns
Babbit_sankey_input <- Babbit_sankey_input[, c("product", 
                                               "source",
                                               "target",
                                               "material",
                                               "value")]

# Duplicates the first file and renames columns
Babbit_sankey_input2 <- Babbit_sankey_input %>% 
  mutate(source = target,
         target = product)

# Reorders columns 
Babbit_sankey_input2 <- Babbit_sankey_input2[, c("product", 
                                                 "source",
                                                 "target",
                                                 "material",
                                                 "value")]

# Binds the two files
Electronics_BoM_sankey_Babbitt2 <- rbindlist(
  list(
    Babbit_sankey_input,
    Babbit_sankey_input2),
  use.names = TRUE)

# Gets unit flows by year
stacked_units <- electronics_stacked_area_chart %>%
  filter(variable == "inflow") %>%
  rename(product = unu_description)

# Right joins the two files to multiply the BoM by flows to get flows in mass by year
Babbitt_joined <- right_join(Electronics_BoM_sankey_Babbitt2, stacked_units,
                             by = c("product")) %>%
  mutate(value = (value.x * value.y)/1000000) %>%
  select(-c(value.x,
            variable,
            value.y)) %>%
  filter(value >0) %>%
  mutate(across(c('value'), round, 2))

# Reorders columns 
Babbitt_joined <- Babbitt_joined[, c("year",
                                     "product",
                                     "source",
                                     "target",
                                     "material",
                                     "value")]

# Write file 
write_xlsx(Babbitt_joined, 
           "./cleaned_data/electronics_sankey_links.xlsx")

# REE ()

# Import units data
REE_units <- 
  read_excel("./cleaned_data/REE_units.xlsx", col_names = T) %>%
  select(1,3,5) %>%
  rename(year = 1,
         'Offshore wind turbine' = 2,
         'Onshore wind turbine' = 3) %>%
  pivot_longer(-year,
               names_to = "product",
               values_to = "value")

# Import sankey data for single product by year
REE_sankey_links <-
  read_excel("./cleaned_data/REE_sankey_links.xlsx", col_names = T)

# Left join and convert units to mass
REE_sankey_links <- 
  left_join(REE_sankey_links, REE_units, by = c('year','product')) %>%
  mutate(value = Value*value) %>%
  select(-Value)

write_xlsx(REE_sankey_links, 
           "./cleaned_data/REE_sankey_links_units.xlsx")  
