##### **********************
# Author: Oliver Lysaght
# Purpose: Converts cleaned data into sankey format
# Inputs:
# Required updates:

# https://cran.r-project.org/web/packages/PantaRhei/vignettes/panta-rhei.html
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
# Electronics

# Import BoM data
BoM_sankey_input <- read_excel(
  "./cleaned_data/BoM_data_UNU.xlsx") %>%
  # remove non-numeric entries in year column to then be able to select the latest
  mutate_at(c('year'), trimws) %>%
  mutate(year = gsub("[^0-9]", "", year)) %>%
  # convert to numeric
  mutate_at(c('year'), as.numeric) %>%
  na.omit() %>%
  # get data for most recent product within each group
  group_by(product) %>%
  top_n(1, abs(year)) %>%
  # Renames columns
  mutate(source = material) %>%
  rename(target = component) %>%
  select("product", 
         "source",
         "target",
         "material",
         "value")

# Import unit inflow data from the stacked area chart
stacked_units <- read_excel(
  "./cleaned_data/electronics_stacked_area_chart.xlsx") %>%
  filter(variable == "inflow") %>%
  rename(product = unu_description)

# Right joins the two files to multiply the BoM by flows to get flows in mass by year
material_formulation <- right_join(Babbit_sankey_input, stacked_units,
                             by = c("product")) %>%
  mutate(value = (value.x * value.y)/1000000) %>%
  select(-c(value.x,
            variable,
            value.y)) %>%
  filter(value >0) %>%
  mutate(across(c('value'), round, 2)) %>%
  mutate(flow = "material formulation")

# Duplicates the first file and renames columns to create the next sankey link
Babbit_sankey_input2 <- Babbit_sankey_input %>% 
  mutate(source = target,
         target = product)

# Reorders columns 
Babbit_sankey_input2 <- Babbit_sankey_input2[, c("product", 
                                                 "source",
                                                 "target",
                                                 "material",
                                                 "value")]

# Right joins the two files to multiply the BoM by flows to get flows in mass by year
component_manufacture <- right_join(Babbit_sankey_input2, stacked_units,
                                   by = c("product")) %>%
  mutate(value = (value.x * value.y)/1000000) %>%
  select(-c(value.x,
            variable,
            value.y)) %>%
  filter(value >0) %>%
  mutate(across(c('value'), round, 2)) %>%
  mutate(flow = "component manufacture")

# Imports collection data



# Binds the files
Electronics_BoM_sankey_Babbitt <- rbindlist(
  list(
    Babbit_sankey_input,
    Babbit_sankey_input2),
  use.names = TRUE)



# Write file 
write_xlsx(Babbitt_joined, 
           "./cleaned_data/electronics_sankey_links.xlsx")

# *******************************************************************************
# REE

# REE Data input
REE_sankey_links <- read_xlsx("./intermediate_data/sankey_scenarios.xlsx") %>%
  filter(value != 0,
         target != "Lost") %>%
  mutate(across(c('value'), round, 2))

write_csv(REE_sankey_links,
          "./cleaned_data/REE_sankey_links2.csv")
