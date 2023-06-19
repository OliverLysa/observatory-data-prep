##### **********************
# Author: Oliver Lysaght
# Purpose: Extract data and calculcate outflow destinations
# Inputs:
# Required annual updates:
# The URL to download from (check end June)
# https://www.gov.uk/government/statistical-data-sets/waste-electrical-and-electronic-equipment-weee-in-the-uk
# Defra's 'waste tracking' system should provide improved numbers for outflow destinations when in place

# Script calculates the outflow routing from the use and collection nodes across the following pathways to estimate a 'circularity rate'
# Direct resale
# Refurbishment
# Remanufacture
# Recycling
# Urban mining
# Disposal 

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
# WEEE generation (official statistics)
# *******************************************************************************

# Download file from net
download.file("http://data.defra.gov.uk/Waste/Table5_1_Total_generation_waste_NACE_EWC_STAT_2010_18_England.csv",
              "./raw_data/WP1.csv")

WP1 <- read.csv("./Publication/Input/WP/Downloaded_files/WP1.csv") %>%
  clean_names() 

WP1 <- WP1 %>%
  pivot_longer(- year, - ewc_stat_code, -ewc_stat_description, -hazardous_non_hazardous_split, source, value)

# *******************************************************************************
# Collection
# *******************************************************************************

# This report shows the amount of household and non-household Waste Electrical and Electronic Equipment (WEEE) collected by Producer Compliance Schemes and their members.

download.file("https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/1160179/WEEE_Collected_in_the_UK.ods",
              "./raw_data/WEEE_collected.ods")

# Extract and list all sheet names 
collected_sheet_names <- list_ods_sheets(
  "./raw_data/WEEE_collected.ods")

# Map sheet names to imported file by adding a column "sheetname" with its name
collected_data <- purrr::map_df(collected_sheet_names, 
                          ~dplyr::mutate(read_ods(
                            "./raw_data/WEEE_collected.ods", 
                            sheet = .x), 
                            sheetname = .x)) %>%
  mutate(quarters = case_when(str_detect(Var.1, "Period Covered") ~ Var.1), .before = Var.1) %>%
  tidyr::fill(1) %>%
  filter(grepl('January to December', quarters)) %>%
  mutate(source = case_when(str_detect(Var.1, "Collected in the UK") ~ Var.1), .before = Var.1) %>%
  tidyr::fill(2) %>%
  # make numeric and filter out anything but 1-14 in column 1
  mutate_at(c('Var.1'), as.numeric) %>%
  filter(between(Var.1, 1, 14)) %>%
  select(-c(
    `Var.1`,
    sheetname,
    Var.6,
    Var.7)) %>% 
  rename(year = 1,
         source = 2,
         product = 3,
         dcf = 4,
         reg_432 = 5,
         reg_503 = 6)

# Substring year column to last 4 characters
collected_data$year = str_sub(collected_data$year,-4)

# Replace na with household
collected_data["source"][is.na(collected_data["source"])] <- "Household"

# Make long-format and filter to household only
collected_household <- collected_data %>%
  # Remove everything in the code column following a hyphen
  mutate(source = gsub("\\ .*", "", source)) %>%
  filter(source == "Household") %>%
  # Pivot long to input to charts
  pivot_longer(-c(
    year,
    source,
    product),
    names_to = "route", 
    values_to = "value")

# Map sheet names to imported file by adding a column "sheetname" with its name to extract non-household data
collected_data_non_household <- purrr::map_df(collected_sheet_names, 
                                ~dplyr::mutate(read_ods(
                                  "./raw_data/WEEE_collected.ods", 
                                  sheet = .x), 
                                  sheetname = .x)) %>%
  mutate(quarters = case_when(str_detect(Var.1, "Period Covered") ~ Var.1), .before = Var.1) %>%
  tidyr::fill(1) %>%
  filter(grepl('January to December', quarters)) %>%
  mutate(source = case_when(str_detect(Var.1, "Collected in the UK") ~ Var.1), .before = Var.1) %>%
  tidyr::fill(2) %>%
  # make numeric and filter out anything but 1-14 in column 1
  mutate_at(c('Var.1'), as.numeric) %>%
  filter(between(Var.1, 1, 14)) %>%
  select(-c(
    `Var.1`,
    sheetname,
    Var.3,
    Var.4,
    Var.5,
    Var.6)) %>% 
  rename(year = 1,
         source = 2,
         product = 3,
         total = 4)

# Substring year column to last 4 characters
collected_data_non_household$year = str_sub(collected_data_non_household$year,-4)

# Replace na with household
collected_data_non_household["source"][is.na(collected_data["source"])] <- "Household"

# Make long-format and filter to household only
collected_data_non_household <- collected_data_non_household %>%
  # Remove everything in the code column following a hyphen
  mutate(source = gsub("\\ .*", "", source)) %>%
  filter(source == "Non-Household") %>%
  # Pivot long to input to charts
  pivot_longer(-c(
    year,
    source,
    product),
    names_to = "route", 
    values_to = "value")

# Bind household and non-household data
collected_all <-
  rbindlist(
    list(
      collected_household,
      collected_data_non_household
    ),
    use.names = FALSE)

# Write output to xlsx form
write_xlsx(collected_all, 
           "./cleaned_data/electronics_collected_all.xlsx")

# *******************************************************************************
# WEEE received at an approved authorised treatment facility (AATF)
# *******************************************************************************

# Apply download.file function in R
download.file("https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/1160180/WEEE_received_at_an_approved_authorised_treatment_facility.ods",
              "./raw_data/WEEE_received_AATF.ods")

# Extract and list all sheet names 
received_AATF_sheet_names <- list_ods_sheets(
  "./raw_data/WEEE_received_AATF.ods")

a <- read_ods("./raw_data/WEEE_received_AATF.ods")

# Map sheet names to imported file by adding a column "sheetname" with its name
received_AATF_data <- purrr::map_df(received_AATF_sheet_names, 
                                ~dplyr::mutate(read_ods(
                                  "./raw_data/WEEE_received_AATF.ods", 
                                  sheet = .x), 
                                  sheetname = .x)) %>%
  mutate(quarters = case_when(str_detect(Var.1, "Period covered") ~ Var.1), .before = Var.1) %>%
  tidyr::fill(1) %>%
  filter(grepl('January to December', quarters)) %>%
  mutate(source = case_when(str_detect(Var.1, "ousehold WEEE") ~ Var.1), .before = Var.1) %>%
  tidyr::fill(2) %>%
  # make numeric and filter out anything but 1-14 in column 1
  mutate_at(c('Var.1'), as.numeric) %>%
  filter(between(Var.1, 1, 14)) %>%
  select(-c(
    `Var.1`,
    sheetname,
    Var.6,
    Var.7,
    Var.8,
    Var.9,
    Var.10)) %>% 
  rename(year = 1,
         source = 2,
         product = 3,
         received_treatment = 4,
         received_reuse = 5,
         sent_AATF_ATF = 6)

# Substring year column to last 4 characters
received_AATF_data$year = str_sub(received_AATF_data$year,-4)

# Make long-format and filter to household only
received_AATF_data <- received_AATF_data %>%
  # Remove everything in the code column following a hyphen
  # Pivot long to input to charts
  pivot_longer(-c(
    year,
    source,
    product),
    names_to = "route", 
    values_to = "value")

# Write output to xlsx form
write_xlsx(received_AATF_data, 
           "./cleaned_data/received_AATF_data.xlsx")

# *******************************************************************************
# WEEE received by approved exporters
# *******************************************************************************

# Apply download.file function in R
download.file("https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/1160181/WEEE_received_by_approved_exporters.ods",
              "./raw_data/WEEE_received_export.ods")

# Extract and list all sheet names 
WEEE_received_export <- list_ods_sheets(
  "./raw_data/WEEE_received_export.ods")

# Map sheet names to imported file by adding a column "sheetname" with its name
WEEE_received_export_data <- purrr::map_df(WEEE_received_export, 
                                    ~dplyr::mutate(read_ods(
                                      "./raw_data/WEEE_received_export.ods", 
                                      sheet = .x), 
                                      sheetname = .x)) %>%
  mutate(quarters = case_when(str_detect(Var.1, "Period Covered") ~ Var.1), .before = Var.1) %>%
  tidyr::fill(1) %>%
  filter(grepl('January to December', quarters)) %>%
  mutate(source = case_when(str_detect(Var.1, "Household WEEE") ~ Var.1), .before = Var.1) %>%
  tidyr::fill(2) %>%
  # make numeric and filter out anything but 1-14 in column 1
  mutate_at(c('Var.1'), as.numeric) %>%
  filter(between(Var.1, 1, 14)) %>%
  select(-c(
    `Var.1`,
    sheetname,
    Var.5)) %>% 
  rename(year = 1,
         source = 2,
         product = 3,
         received_export = 4,
         received_export_reuse = 5)

# Substring year column to last 4 characters
WEEE_received_export_data$year = str_sub(WEEE_received_export_data$year,-4)

# Make long-format
WEEE_received_export_data <- WEEE_received_export_data %>%
  # Remove everything in the code column following a hyphen
  # Pivot long to input to charts
  pivot_longer(-c(
    year,
    source,
    product),
    names_to = "route", 
    values_to = "value")

# Write output to xlsx form
write_xlsx(WEEE_received_export_data, 
           "./cleaned_data/WEEE_received_export_data.xlsx")

# *******************************************************************************
# Non-obligated WEEE received at approved authorised treatment facilities and approved exporters
# *******************************************************************************

# Apply download.file function in R
download.file("https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/1160183/Non-obligated_WEEE_received_at_approved_authorised_treatment_facilities_and_approved_exporters.ods",
              "./raw_data/WEEE_received_non_obligated.ods")

# Extract and list all sheet names 
WEEE_received_non_obligated <- list_ods_sheets(
  "./raw_data/WEEE_received_non_obligated.ods")

# Map sheet names to imported file by adding a column "sheetname" with its name
WEEE_received_non_obligated <- purrr::map_df(WEEE_received_non_obligated, 
                                           ~dplyr::mutate(read_ods(
                                             "./raw_data/WEEE_received_non_obligated.ods", 
                                             sheet = .x), 
                                             sheetname = .x)) %>%
  mutate(quarters = case_when(str_detect(Var.1, "Period covered") ~ Var.1), .before = Var.1) %>%
  tidyr::fill(1) %>%
  filter(grepl('January to December', quarters)) %>%
  # make numeric and filter out anything but 1-14 in column 1
  mutate_at(c('Var.1'), as.numeric) %>%
  filter(between(Var.1, 1, 14)) %>%
  select(-c(
    `Var.1`,
    sheetname,
    Var.5)) %>% 
  rename(year = 1,
         product = 2,
         received_AATF_AE = 3,
         received_AATF_DCF = 4)

# Substring year column to last 4 characters
WEEE_received_non_obligated$year = str_sub(WEEE_received_non_obligated$year,-4)

# Make long-format
WEEE_received_non_obligated <- WEEE_received_non_obligated %>%
  # Remove everything in the code column following a hyphen
  # Pivot long to input to charts
  pivot_longer(-c(
    year,
    product),
    names_to = "route", 
    values_to = "value") %>%
  mutate(source = "unspecified")

# Write output to xlsx form
write_xlsx(WEEE_received_non_obligated, 
           "./cleaned_data/WEEE_received_non_obligated.xlsx")

# *******************************************************************************
# Outflow fate
# *******************************************************************************

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
