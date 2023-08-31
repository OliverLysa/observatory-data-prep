##### **********************
# Author: Oliver Lysaght
# Purpose: Converts cleaned data into sankey format for presenting in sankey chart

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
# Proportional data
# *******************************************************************************

# Read proportion data
# This approach assumes that proportions are the same across all years/value chain stages
BoM_percentage_UNU <- read_xlsx(
  "./cleaned_data/BoM_percentage_UNU.xlsx")

# *******************************************************************************
# Material formulation > Component manufacture
# *******************************************************************************

# Import interpolated inflow mass data
inflow_unu_mass <- read_xlsx( 
           "./cleaned_data/inflow_unu_mass.xlsx")

# Merge inflows and colloquial
inflows <- merge(inflow_unu_mass, UNU_colloquial,
                   by = c("unu_key")) %>%
  select(-c(unu_key))

# Right joins the two files to multiply the BoM by flows in unit to derive flows in mass between materials and components of products, components and materials by year by year
material_formulation <- right_join(BoM_percentage_UNU, inflows,
                             by = c("product")) %>%
  mutate(value = (value.x * value.y)/1000000) %>%
  select(-c(value.x,
            value.y)) %>%
  filter(value >0) %>%
  mutate(across(c('value'), round, 2)) %>%
  mutate(flow = "material formulation_component manufacture")

# Aggregated (lesser-level detail - for more aggregate sankey)
material_formulation <- right_join(BoM_sankey_input, inflows,
                                   by = c("product")) %>%
  mutate(value = (value.x * value.y)/1000000) %>%
  select(-c(value.x,
            value.y)) %>%
  filter(value >0) %>%
  mutate(across(c('value'), round, 2)) %>%
  mutate(flow = "material formulation_component manufacture")

# Aggregated (lesser-level detail table)
material_formulation_aggregated <- material_formulation %>%
  mutate(source = "Material_formulation",
         target = "Component_manufacture") %>%
  group_by(product, source, target, material) %>%
  summarise(value = sum(value))

# *******************************************************************************
# Component manufacture > product usage
# *******************************************************************************

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

# *******************************************************************************
# Repair/maintenance
# *******************************************************************************



# *******************************************************************************
# Usage > Collection/separation 
# *******************************************************************************

# Import collected data
collected_all_54 <- read_excel(
  "./cleaned_data/electronics_sankey/collected_all_54.xlsx")

# Produce product usage > collected stage data in mass sankey format by 
# multiplying the proportions from the BoM to the mass flows

collected_PCS <- merge(collected_all_54, UNU_colloquial,
                                     by = c("unu_key")) %>%
  mutate(source = product,
         target = product) %>%
  select("product", 
         "source",
         "target",
         "year",
         "value") %>%
  # filter(product %in% unique(component_manufacture$product)) %>%
  mutate_at(c('year'), as.numeric)

# Right join the BoM proportion and mass collected per year
collected_material <- right_join(BoM_percentage_UNU, collected,
                                   by = c("product")) %>%
  mutate(mass = freq*value) %>%
  select("product", 
         "source",
         "target",
         "material",
         "year",
         "mass") %>%
  rename(value = mass) %>%
  mutate(source = "usage",
         target = "collected")

# *******************************************************************************
# Collection > reuse/resale
# *******************************************************************************

# Import reuse AATF data
reuse_received_AATF_54 <- read_excel(
  "./cleaned_data/electronics_sankey/reuse_received_AATF_54.xlsx")

# Produce product usage > collected stage data in sankey format in mass by 
# multiplying the proportions from the BoM to the mass flows
# the difference between this, other collection and anticipated outflows based on lifespans is leakage
reuse_received_AATF <- merge(reuse_received_AATF_54, UNU_colloquial,
                   by = c("unu_key")) %>%
  select("product", 
         "year",
         "value") %>%
  # filter(product %in% unique(component_manufacture$product)) %>%
  mutate_at(c('year'), as.numeric)

# Right join the BoM proportion and mass collected per year
reuse_received_AATF_material <- right_join(BoM_percentage_UNU, reuse_received_AATF,
                                 by = c("product")) %>%
  mutate(mass = freq*value) %>%
  select("product", 
         "material",
         "year",
         "mass") %>%
  rename(value = mass) %>%
  mutate(source = "collected",
         target = "reuse")

# Needs to then be duplicated and combined to create remainder of the reuse loop

# *******************************************************************************
# Collection > recycling
# *******************************************************************************

# To improve the composition of outflow, we would ideally know the age of products at time they exit the stock to link to time-varying inflow composition data
# Multiply recycling by BoM Sankey percentage
recycling_received_AATF_54 <- read_excel(
  "./cleaned_data/electronics_sankey/recycling_received_AATF_54.xlsx")

# Produce product usage > collected stage data in sankey format in mass by 
# multiplying the proportions from the BoM to the mass flows
# the difference between this, other collection and anticipated outflows based on lifespans is leakage
recycling_received_AATF_54 <- merge(recycling_received_AATF_54, UNU_colloquial,
                             by = c("unu_key")) %>%
  select("product", 
         "year",
         "value") %>%
  # filter(product %in% unique(component_manufacture$product)) %>%
  mutate_at(c('year'), as.numeric)

# Right join the BoM proportion and mass collected per year
recycling_received_AATF_54_material <- right_join(BoM_percentage_UNU, recycling_received_AATF_54,
                                           by = c("product")) %>%
  mutate(mass = freq*value) %>%
  select("product", 
         "material",
         "year",
         "mass") %>%
  rename(value = mass) %>%
  mutate(source = "collected",
         target = "recycle")

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

# *******************************************************************************
# Refurbishment
# *******************************************************************************

# *******************************************************************************
# Remanufacture
# *******************************************************************************

# Write file 
write_csv(sankey_all, 
          "./cleaned_data/electronics_chart_sankey.csv")


