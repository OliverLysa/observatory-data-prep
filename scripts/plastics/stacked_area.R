##### **********************
# Author: Oliver Lysaght
# Purpose: Import textiles baseline and scenario data published by Millward-Hopkins and create stacked area chart input

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
              "mixdist",
              "janitor",
              "tabulizer",
              "pdftools",
              "data.table",
              "shiny",
              "miniUI",
              "rvest",
              "DataEditR")

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

# Turn off scientific notation of numeric values
options(scipen = 999)

# *******************************************************************************
# Data extraction
# *******************************************************************************

# *******************************************************************************
# Import sankey data 
SW_all <- read_excel(
  "./plastics/received/210521_EXEmPlar_Sankey string_SW.xlsx",
  sheet = "Sorting_SW") %>%
  # remove the top row
  slice(-1) %>%
  # remove columns where all rows are na
  select_if(function(x) !(all(is.na(x)) | all(x=="")))

# Create inflow variable
inflow <- SW_all %>%
  select(7:8) %>%
  rename(product = 1,
         value = 2) %>%
  mutate(variable = "inflow") %>%
  na.omit() %>%
  filter(product != "Total")

# Create collection variable
collection <- SW_all %>%
  select(15:16) %>%
  rename(route = 1,
         value = 2) %>%
  mutate(variable = "collection") %>%
  filter(route == "Total") %>%
  na.omit() %>%
  rename(product = 1)

# Create end of use variable
treatment <- SW_all %>%
  select(15:16) %>%
  rename(route = 1,
         value = 2) %>%
  mutate(variable = "treatment") %>%
  filter(route == "Total") %>%
  na.omit() %>%
  rename(product = 1)

# Create stacked all
stacked_all <- rbindlist(
  list(
    inflow,
    collection,
    treatment),
  use.names = FALSE) %>%
  mutate(scenario = "BAU",
         year = "2018") %>%
  mutate(product = gsub("Total", "Plastics", product)) %>%
  mutate(across(c('value'), round, 2)) %>%
  write_csv("./cleaned_data/plastics_chart_area.csv")


