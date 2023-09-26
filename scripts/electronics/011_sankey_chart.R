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
  "./cleaned_data/BoM_percentage_UNU.xlsx") %>%
  mutate_at(c('material'), trimws)

# *******************************************************************************
# Extraction > Refinement
# *******************************************************************************

# *******************************************************************************
# Refinement > Material formulation
# *******************************************************************************

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

# Right joins the two files to multiply the BoM by flows in unit to derive flows in mass of materials and components of products by year
material_formulation <- right_join(BoM_percentage_UNU, inflows,
                             by = c("product")) %>%
  # Multiply material composition (breakdown of total product) by inflows
  mutate(value = (freq * value)) %>%
  # Remove unwanted columns
  select(-c(freq,
            variable,
            unit)) %>%
  # Filter out 0 values
  filter(value >0) %>%
  mutate(across(c('value'), round, 2)) %>%
  mutate(source = "material_formulation",
         target = "component_manufacture")

# *******************************************************************************
# Component manufacture > product assembly
# *******************************************************************************

# Duplicates the first file and renames columns to create the next sankey link through making long-format the BoM
component_manufacture <- material_formulation %>% 
  mutate(source = target,
         target = "product_assembly")

# *******************************************************************************
# Product assembly > retail/distribute 
# *******************************************************************************

# Duplicates the first file and renames columns to create the next sankey link through making long-format the BoM
product_assembly <- material_formulation %>% 
  mutate(source = "product_assembly",
         target = "retail_distribute")

# *******************************************************************************
# Retail/distribute > consume
# *******************************************************************************

# Duplicates the first file and renames columns to create the next sankey link through making long-format the BoM
retail_distribute <- material_formulation %>% 
  mutate(source = "retail_distribute",
         target = "consume")

# *******************************************************************************
# Consume > repair/maintenance
# *******************************************************************************

# Read open repair data in 
repair <- 
  read_xlsx("./cleaned_data/Openrepair_UNU_mass.xlsx") %>%
  left_join(UNU_colloquial,
             by = c("unu_key")) %>%
  left_join(BoM_percentage_UNU,
            by = c("product")) %>%
  mutate(mass = freq*value) %>%
  select(-c(unu_key, value, freq)) %>%
  rename(value = mass) %>%
  mutate(source = "consume",
         target = "repair")

# Needs to then be duplicated and combined to create remainder of the reuse loop
repair_return <- repair %>%
  mutate(source = "repair",
         target = "consume")

repair <- rbindlist(
  list(
    repair,
    repair_return),
  use.names = TRUE)

# *******************************************************************************
# Consume > Collection 
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
  filter(product %in% unique(material_formulation$product)) %>%
  mutate_at(c('year'), as.numeric)

# Right join the BoM proportion and mass collected per year
collected <- right_join(BoM_percentage_UNU, collected_PCS,
                                   by = c("product")) %>%
  mutate(mass = freq*value) %>%
  select("material",
         "product",
         "year",
         "mass",
         "source",
         "target") %>%
  rename(value = mass) %>%
  mutate(source = "consume",
         target = "collection")

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
  filter(product %in% unique(material_formulation$product)) %>%
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
  mutate(source = "collection",
         target = "reuse")

# Needs to then be duplicated and combined to create remainder of the reuse loop
reuse_return <- reuse_received_AATF_material %>%
  mutate(source = "reuse",
         target = "retail_distribute")

reuse <- rbindlist(
  list(
    reuse_received_AATF_material,
    reuse_return),
  use.names = TRUE)

# *******************************************************************************
# Collection > recycling
# *******************************************************************************

# To improve the composition of outflow, we would ideally know the age of products at time they exit the stock to link to time-varying inflow composition data when we have this
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
  filter(product %in% unique(material_formulation$product)) %>%
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
  mutate(source = "collection",
         target = "recycle")

# Needs to then be duplicated and combined to create remainder of the reuse loop
recycling_return <- reuse_received_AATF_material %>%
  mutate(source = "recycle",
         target = "material_formulation")

recycle <- rbindlist(
  list(
    recycling_received_AATF_54_material,
    recycling_return),
  use.names = TRUE)

# *******************************************************************************
# Collection > refurbishment
# *******************************************************************************

# *******************************************************************************
# Collection > Remanufacture
# *******************************************************************************

# *******************************************************************************
# Collection > Exports
# *******************************************************************************

# *******************************************************************************
# Collection > Disposal
# *******************************************************************************

# Binds the sankey flows together
sankey_all <- rbindlist(
  list(
    material_formulation,
    component_manufacture,
    product_assembly,
    retail_distribute,
    collected,
    repair,
    reuse,
    recycle),
  use.names = TRUE) %>%
  filter(value != 0,
         material != "Total",
         year <= 2021,
         year >= 2008) %>%
  mutate(across(c('value'), round, 2)) %>%
  mutate_at(c('material'), trimws) %>%
  mutate(
    material = gsub("Other metals", 'Metals (other)', material),
    material = gsub("Other glass", 'Glass (other)', material),
    material = gsub("Flat panel glass", 'Flat-panel glass', material))

# Write file 
write_csv(sankey_all, 
          "./cleaned_data/electronics_sankey_links.csv")


