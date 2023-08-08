##### **********************
# Author: Oliver Lysaght
# Purpose: Converts cleaned data into sankey format for presenting in sankey chart
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
source("./scripts/functions.R", 
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

# convert into % terms 
BoM_sankey_percentage <- BoM_sankey_input %>% 
  group_by(product, material) %>% 
  summarise(sum(value)) %>%
  rename(value = 3) %>%
  mutate(freq = value / sum(value)) %>%
  select(-value)

# Import inflow data from the stacked area chart to multiply the BoM by to get tonnes per year across inflow stages
inflows <- read_excel(
  "./cleaned_data/inflows_indicators.xlsx") %>%
filter(indicator == "apparent_consumption",
       unit == "Units")

inflows <- merge(inflows, UNU_colloquial,
                   by = c("unu_key")) %>%
  select(-c(unu_key, unit))

# Right joins the two files to multiply the BoM by flows to get flows in mass by year
material_formulation <- right_join(BoM_sankey_input, inflows,
                             by = c("product")) %>%
  mutate(value = (value.x * value.y)/1000000) %>%
  select(-c(value.x,
            indicator,
            value.y)) %>%
  filter(value >0) %>%
  mutate(across(c('value'), round, 2)) %>%
  mutate(flow = "material formulation_component manufacture")

# Duplicates the first file and renames columns to create the next sankey link through making long-format the BoM
component_manufacture <- material_formulation %>% 
  mutate(source = target,
         target = product) %>%
  # Reorders columns
  select("product", 
         "source",
         "target",
         "material",
         "year",
         "value") %>%
  mutate(flow = "component manufacture_product usage")

# Collected

# Import collected data
collected_all_54 <- read_excel(
  "./cleaned_data/electronics_sankey/collected_all_54.xlsx")

# Produce product usage > collected stage data in sankey format in mass by 
# multiplying the proportions from the BoM to the mass flows
# the difference between this, other collection and anticipated outflows based on lifespans is leakage
collected <- merge(collected_all_54, UNU_colloquial,
                                     by = c("unu_key")) %>%
  mutate(source = product,
         target = product) %>%
  select("product", 
         "source",
         "target",
         "year",
         "value") %>%
  mutate(flow = "Product usage_collected") %>%
  filter(product %in% unique(component_manufacture$product)) %>%
  mutate_at(c('year'), as.numeric)

# Right join the BoM proportion and mass collected per year
collected_material <- right_join(BoM_sankey_percentage, collected,
                                   by = c("product")) %>%
  mutate(mass = freq*value) %>%
  select("product", 
         "source",
         "target",
         "material",
         "year",
         "mass",
         "flow") %>%
  rename(value = mass)
  
collected_material$target <- paste(collected_material$target, "collected", sep = "_")

# Reuse 

reuse_received_AATF_54 <- read_excel(
  "./cleaned_data/electronics_sankey/reuse_received_AATF_54.xlsx")

# Produce product usage > collected stage data in sankey format in mass by 
# multiplying the proportions from the BoM to the mass flows
# the difference between this, other collection and anticipated outflows based on lifespans is leakage
reuse_received_AATF <- merge(reuse_received_AATF_54, UNU_colloquial,
                   by = c("unu_key")) %>%
  mutate(source = product,
         target = product) %>%
  select("product", 
         "source",
         "target",
         "year",
         "value") %>%
  mutate(flow = "collected_reuse AATF") %>%
  filter(product %in% unique(component_manufacture$product)) %>%
  mutate_at(c('year'), as.numeric)

# Right join the BoM proportion and mass collected per year
reuse_received_AATF_material <- right_join(BoM_sankey_percentage, reuse_received_AATF,
                                 by = c("product")) %>%
  mutate(mass = freq*value) %>%
  select("product", 
         "source",
         "target",
         "material",
         "year",
         "mass",
         "flow") %>%
  rename(value = mass)

reuse_received_AATF_material$source <- paste(reuse_received_AATF_material$source, "collected", sep = "_")

# Binds the files
sankey_all <- rbindlist(
  list(
    material_formulation,
    component_manufacture,
    collected_material,
    reuse_received_AATF_material),
  use.names = TRUE) %>%
  filter(year != 2022,
         value != 0) %>%
  mutate(across(c('value'), round, 2))

# Write file 
write_csv(sankey_all, 
           "./cleaned_data/electronics_chart_sankey.csv")

# Multiply recycling by BoM Sankey percentage 