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

# Outflow
# *******************************************************************************
# 

#### Outflow fate (CE-score) ####

# Import data, pivot longer, filter, drop NA and rename column 'route' 
Outflow_routing <- read_excel(
  "./cleaned_data/electronics_outflow.xlsx") %>%
  pivot_longer(-c(
    `UNU KEY`,
    `UNU DESCRIPTION`,
    `Variable`
  ),
  names_to = "route", 
  values_to = "value") %>%
  filter(Variable == "Percentage",
         route != "Total") %>%
  drop_na(value) %>%
  mutate(Year = 2017) %>%
  select(-Variable) %>%
  mutate(route = gsub("General bin", "disposal", route),
         route = gsub("Recycling", "recycling", route),
         route = gsub("Sold", "resale", route),
         route = gsub("Donation or re-use", "resale", route),
         route = gsub("Other", "refurbish", route),
         route = gsub("Take back scheme", "remanufacture", route),
         route = gsub("Unknown", "maintenance", route))  

# Multiply percentages by ordinal score

Outflow_routing_weights <- read_excel(
  "./data_extraction_scripts/Electronics/weights.xlsx")

electronics_bubble_outflow <- merge(Outflow_routing,
                                    Outflow_routing_weights,
                                    by.x=c("route"),
                                    by.y=c("route")) %>%
  mutate(route_score = value*score) %>%
  group_by(`UNU KEY`, `UNU DESCRIPTION`, Year) %>%
  summarise(score = sum(route_score)) %>%
  # =(suboptimal-actual)/(suboptimal-optimal)
  mutate(scaled = (0-score)/(0-5)*100) %>%
  mutate(across(c('scaled'), round, 1)) %>%
  select(-c(score))

# Fly-tipping https://www.gov.uk/government/statistical-data-sets/env24-fly-tipping-incidents-and-actions-taken-in-england
# Waste Data Flow https://www.data.gov.uk/dataset/0e0c12d8-24f6-461f-b4bc-f6d6a5bf2de5/wastedataflow-local-authority-waste-management
# Waste data interrogator
# WEEE Statistics https://www.gov.uk/government/statistical-data-sets/waste-electrical-and-electronic-equipment-weee-in-the-uk