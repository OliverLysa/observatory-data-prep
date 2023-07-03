##### **********************
# Author: Oliver Lysaght
# Purpose: Script calculates the outflow routing from the use and collection nodes across the following pathways to estimate a 'circularity rate'
# Inputs:
# Required annual updates:
# The URL to download from (check end June)
# https://www.gov.uk/government/statistical-data-sets/waste-electrical-and-electronic-equipment-weee-in-the-uk
# Defra's 'waste tracking' system should provide improved numbers for outflow destinations within the regulated waste system when in place

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

# Turn off scientific notation of numeric values
options(scipen = 999)

# *******************************************************************************
# Maintenance/repair
# *******************************************************************************

# *******************************************************************************
# Collection/separation 
# *******************************************************************************

# WEEE collected - shows the amount of household and non-household Waste Electrical and Electronic Equipment (WEEE) collected by Producer Compliance Schemes and their members.

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
  filter(grepl('January to December', quarters) |
           grepl('January - December', quarters)) %>%
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
  filter(grepl('January to December', quarters) |
           grepl('January - December', quarters)) %>%
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

# Make long-format and filter to non-household only
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

# Prepare for converting from UKU 14 to UNU-54
collected_all_summarised <- collected_all %>%
  mutate_at(c('value'), as.numeric) %>%
  group_by(product, year) %>%
  summarise(value = sum(value))

# Convert to wide format
collected_all_wide <- collected_all_summarised %>%
  pivot_wider(names_from = "year", 
            values_from = "value")

# Reorder rows to match the UK14 to UNU mapping tool 
collected_all_wide$product <- factor(collected_all_wide$product, levels=c(
              "Large Household Appliances",
              "Small Household Appliances",
              "IT and Telcomms Equipment",
              "Consumer Equipment",
              "Lighting Equipment",
              "Electrical and Electronic Tools",
              "Toys Leisure and Sports",
              "Medical Devices",
              "Monitoring and Control Instruments",
              "Automatic Dispensers",
              "Display Equipment",
              "Cooling Appliances Containing Refrigerants",
              "Gas Discharge Lamps",
              "Gas Discharge Lamps and LED Light Sources",
              "Photovoltaic Panels"))

collected_all_wide <- collected_all_wide[order(collected_all_wide$product), ]

# Write output to xlsx form to convert via the UNU_UK mapping excel tool 
write_xlsx(collected_all_wide, 
           "./intermediate_data/collected_all_wide.xlsx")

# Reimport the data after converting UK 14 to UNU 54 in excel, clean
collected_all_wide_54 <- read_xlsx("./intermediate_data/collected_all_wide.xlsx",
           sheet = 2) %>%
  remove_empty() %>%
  rename(unu_key = 1,
         unu_description = 2) %>%
  mutate(# Remove everything after the brackets/parentheses in the code column
         unu_description = gsub("\\(.*", "", unu_description)) 

# Add leading 0s to unu_key column up to 4 digits to help match to other data
collected_all_wide_54$unu_key <- str_pad(collected_all_wide_54$unu_key, 4, pad = "0")

# Convert to long-form
collected_all_54 <- collected_all_wide_54 %>% 
  pivot_longer(-c(
  unu_key,
  unu_description),
  names_to = "year", 
  values_to = "value") %>%
  mutate(flow = "collected")

# Write output to xlsx form to convert via the UNU_UK mapping excel tool 
write_xlsx(collected_all_54, 
           "./cleaned_data/electronics_sankey/collected_all_54.xlsx")

# Difference between WEE collection and WEEE received may proxy collection-stage leakage 

# *******************************************************************************
# Reuse/resale and refurbishment
# *******************************************************************************

# Reported household & non-household reuse of WEEE received at an approved authorised treatment facility (AATF)
# Amount of WEEE that AATFs have reused themselves and sent onto others for reuse.

# Apply download.file function in R
download.file("https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/1160180/WEEE_received_at_an_approved_authorised_treatment_facility.ods",
              "./raw_data/WEEE_received_AATF.ods")

# Extract and list all sheet names 
received_AATF_sheet_names <- list_ods_sheets(
  "./raw_data/WEEE_received_AATF.ods")

# Map sheet names to imported file by adding a column "sheetname" with its name
# 2016 data is incorrectly listed in the source file as 2017. Have manually changed in the excel
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

# Make long-format
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

# filter to reuse
received_AATF_reuse <- received_AATF_data %>%
  filter(route == "received_reuse")
  
# Prepare for converting from UKU 14 to UNU-54
received_AATF_reuse_summarised <- received_AATF_reuse %>%
  mutate_at(c('value'), as.numeric) %>%
  group_by(product, year) %>%
  summarise(value = sum(value))

# Convert to wide format
received_AATF_reuse_summarised_wide <- received_AATF_reuse_summarised %>%
  pivot_wider(names_from = "year", 
              values_from = "value")

# Reorder rows to match the UK14 to UNU mapping tool 
received_AATF_reuse_summarised_wide$product <- factor(received_AATF_reuse_summarised_wide$product, levels=c(
  "Large Household Appliances",
  "Small Household Appliances",
  "IT and Telcomms Equipment",
  "Consumer Equipment",
  "Lighting Equipment",
  "Electrical and Electronic Tools",
  "Toys Leisure and Sports",
  "Medical Devices",
  "Monitoring and Control Instruments",
  "Automatic Dispensers",
  "Display Equipment",
  "Cooling Appliances Containing Refrigerants",
  "Gas Discharge Lamps",
  "Gas Discharge Lamps and LED Light Sources",
  "Photovoltaic Panels"))

received_AATF_reuse_summarised_wide <- received_AATF_reuse_summarised_wide[order(received_AATF_reuse_summarised_wide$product), ]

# Write output to xlsx form to convert via the UNU_UK mapping excel tool 
write_xlsx(received_AATF_reuse_summarised_wide, 
           "./intermediate_data/received_reuse_summarised_wide.xlsx")

# Reimport the data after converting UK 14 to UNU 54 in excel, clean
received_AATF_reuse_wide_54 <- read_xlsx("./intermediate_data/received_reuse_summarised_wide.xlsx",
                                   sheet = 2) %>%
  remove_empty() %>%
  rename(unu_key = 1,
         unu_description = 2) %>%
  mutate(# Remove everything after the brackets/parentheses in the code column
    unu_description = gsub("\\(.*", "", unu_description)) 

# Add leading 0s to unu_key column up to 4 digits to help match to other data
received_AATF_reuse_wide_54$unu_key <- str_pad(received_AATF_reuse_wide_54$unu_key, 4, pad = "0")

received_AATF_reuse_54 <- received_AATF_reuse_wide_54 %>% 
  pivot_longer(-c(
    unu_key,
    unu_description),
    names_to = "year", 
    values_to = "value") %>%
  mutate(flow = "received_AATF_reuse")

# Write output to xlsx
write_xlsx(received_AATF_reuse_54, 
           "./cleaned_data/electronics_sankey/reuse_received_AATF_54.xlsx")

# IT asset management sector (ITAM), mobile phone buyback schemes, online auction sites and classified listings.
# Commercial reuse (B2B): 90Kt
# Domestic reuse (B2C/C2C): 82Kt - https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/1077642/second-hand-sales-of-electrical-products.pdf
# ITAM/D e.g large global operators like RDC-Computacenter, TES and SIMS: 90Kt - covers remanufacturing too
# Returns under warranty: 102Kt
# We estimate the weight of products collected for potential reuse, to be 237 Kt for 2017

# *******************************************************************************
# Remanufacture
# *******************************************************************************

# Oakdene Hollins
# Industry report (2005) - remanufacturing industry association

# *******************************************************************************
# Recycling
# *******************************************************************************

# filter received data to received at aatf for recycling
received_recycling <- received_AATF_data %>%
  filter(route == "received_treatment")

# Prepare for converting from UKU 14 to UNU-54
received_recycling_summarised <- received_recycling %>%
  mutate_at(c('value'), as.numeric) %>%
  group_by(product, year) %>%
  summarise(value = sum(value))

# Convert to wide format
received_recycling_summarised_wide <- received_recycling_summarised %>%
  pivot_wider(names_from = "year", 
              values_from = "value")

# Reorder rows to match the UK14 to UNU mapping tool 
received_recycling_summarised_wide$product <- factor(received_recycling_summarised_wide$product, levels=c(
  "Large Household Appliances",
  "Small Household Appliances",
  "IT and Telcomms Equipment",
  "Consumer Equipment",
  "Lighting Equipment",
  "Electrical and Electronic Tools",
  "Toys Leisure and Sports",
  "Medical Devices",
  "Monitoring and Control Instruments",
  "Automatic Dispensers",
  "Display Equipment",
  "Cooling Appliances Containing Refrigerants",
  "Gas Discharge Lamps",
  "Gas Discharge Lamps and LED Light Sources",
  "Photovoltaic Panels"))

received_recycling_summarised_wide <- received_recycling_summarised_wide[order(received_recycling_summarised_wide$product), ]

# Write output to xlsx form to convert via the UNU_UK mapping excel tool 
write_xlsx(received_recycling_summarised_wide, 
           "./intermediate_data/received_recycling_summarised_wide.xlsx")

# Reimport the data after converting UK 14 to UNU 54 in excel, clean
received_AATF_recycling_wide_54 <- read_xlsx("./intermediate_data/received_recycling_summarised_wide.xlsx",
                                         sheet = 2) %>%
  remove_empty() %>%
  rename(unu_key = 1,
         unu_description = 2) %>%
  mutate(# Remove everything after the brackets/parentheses in the code column
    unu_description = gsub("\\(.*", "", unu_description)) 

# Add leading 0s to unu_key column up to 4 digits to help match to other data
received_AATF_recycling_wide_54$unu_key <- str_pad(received_AATF_recycling_wide_54$unu_key, 4, pad = "0")

# Pivot longer and add flow identifier
received_AATF_recycling_54 <- received_AATF_reuse_wide_54 %>% 
  pivot_longer(-c(
    unu_key,
    unu_description),
    names_to = "year", 
    values_to = "value") %>%
  mutate(flow = "received_AATF_recycling")

# Write output to xlsx
write_xlsx(received_AATF_recycling_54, 
           "./cleaned_data/electronics_sankey/recycling_received_AATF_54.xlsx")

# Non-obligated WEEE received at approved authorised treatment facilities and approved exporters

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
  mutate(source = "unspecified") %>%
  na.omit()

# Write output to xlsx form
write_xlsx(WEEE_received_non_obligated, 
           "./cleaned_data/WEEE_received_non_obligated.xlsx")

# Prepare for converting from UKU 14 to UNU-54
received_non_obligated_summarised <-WEEE_received_non_obligated %>%
  mutate_at(c('value'), as.numeric) %>%
  group_by(product, year) %>%
  summarise(value = sum(value))

# Convert to wide format
received_non_obligated_summarised_wide <- received_non_obligated_summarised %>%
  pivot_wider(names_from = "year", 
              values_from = "value")

# Reorder rows to match the UK14 to UNU mapping tool 
received_non_obligated_summarised_wide$product <- factor(received_non_obligated_summarised_wide$product, levels=c(
  "Large Household Appliances",
  "Small Household Appliances",
  "IT and Telcomms Equipment",
  "Consumer Equipment",
  "Lighting Equipment",
  "Electrical and Electronic Tools",
  "Toys Leisure and Sports",
  "Medical Devices",
  "Monitoring and Control Instruments",
  "Automatic Dispensers",
  "Display Equipment",
  "Cooling Appliances Containing Refrigerants",
  "Gas Discharge Lamps",
  "Gas Discharge Lamps and LED Light Sources",
  "Photovoltaic Panels"))

received_non_obligated_summarised_wide <- received_non_obligated_summarised_wide[order(received_non_obligated_summarised_wide$product), ]

# Write output to xlsx form to convert via the UNU_UK mapping excel tool 
write_xlsx(received_non_obligated_summarised_wide, 
           "./intermediate_data/received_non_obligated_summarised_wide.xlsx")

# Reimport the data after converting UK 14 to UNU 54 in excel, clean
received_non_obligated_summarised_wide_54 <- read_xlsx("./intermediate_data/received_non_obligated_summarised_wide.xlsx",
                                         sheet = 2) %>%
  remove_empty() %>%
  rename(unu_key = 1,
         unu_description = 2) %>%
  mutate(# Remove everything after the brackets/parentheses in the code column
    unu_description = gsub("\\(.*", "", unu_description)) 

# Add leading 0s to unu_key column up to 4 digits to help match to other data
received_non_obligated_summarised_wide_54$unu_key <- str_pad(received_non_obligated_summarised_wide_54$unu_key, 4, pad = "0")

# Make long
received_non_obligated_54 <- received_non_obligated_summarised_wide_54 %>% 
  pivot_longer(-c(
    unu_key,
    unu_description),
    names_to = "year", 
    values_to = "value") %>%
  mutate(flow = "received_AATF_reuse")

# Write output to xlsx
write_xlsx(received_non_obligated_54, 
           "./cleaned_data/electronics_sankey/received_non_obligated_54.xlsx")

# https://www.data.gov.uk/dataset/0e0c12d8-24f6-461f-b4bc-f6d6a5bf2de5/wastedataflow-local-authority-waste-management

# sites operating under exemptions T11 (Para 47 Scotland) and ATF permits

# *******************************************************************************
# Exports
# *******************************************************************************

# WEEE received by approved exporters

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

# Prepare for converting from UKU 14 to UNU-54
received_export_data_summarised <-WEEE_received_export_data %>%
  mutate_at(c('value'), as.numeric) %>%
  group_by(product, year) %>%
  summarise(value = sum(value))

# Convert to wide format
received_export_data_summarised_wide <- received_export_data_summarised %>%
  pivot_wider(names_from = "year", 
              values_from = "value")

# Reorder rows to match the UK14 to UNU mapping tool 
received_export_data_summarised_wide$product <- factor(received_export_data_summarised_wide$product, levels=c(
  "Large Household Appliances",
  "Small Household Appliances",
  "IT and Telcomms Equipment",
  "Consumer Equipment",
  "Lighting Equipment",
  "Electrical and Electronic Tools",
  "Toys Leisure and Sports",
  "Medical Devices",
  "Monitoring and Control Instruments",
  "Automatic Dispensers",
  "Display Equipment",
  "Cooling Appliances Containing Refrigerants",
  "Gas Discharge Lamps",
  "Gas Discharge Lamps and LED Light Sources",
  "Photovoltaic Panels"))

received_export_data_summarised_wide <- received_export_data_summarised_wide[order(received_export_data_summarised_wide$product), ]

# Write output to xlsx form to convert via the UNU_UK mapping excel tool 
write_xlsx(received_export_data_summarised_wide, 
           "./intermediate_data/received_export_data_summarised_wide.xlsx")

# Reimport the data after converting UK 14 to UNU 54 in excel, clean
received_export_data_summarised_wide_54 <- read_xlsx("./intermediate_data/received_export_data_summarised_wide.xlsx",
                                                       sheet = 2) %>%
  remove_empty() %>%
  rename(unu_key = 1,
         unu_description = 2) %>%
  mutate(# Remove everything after the brackets/parentheses in the code column
    unu_description = gsub("\\(.*", "", unu_description)) 

# Add leading 0s to unu_key column up to 4 digits to help match to other data
received_export_data_summarised_wide_54$unu_key <- str_pad(received_export_data_summarised_wide_54$unu_key, 4, pad = "0")

# Make long
received_export_data_54 <- received_export_data_summarised_wide_54 %>% 
  pivot_longer(-c(
    unu_key,
    unu_description),
    names_to = "year", 
    values_to = "value") %>%
  mutate(flow = "export (AE)")

# Write output to xlsx
write_xlsx(received_export_data_54, 
           "./cleaned_data/electronics_sankey/export_received_54.xlsx")

# https://onlinelibrary.wiley.com/doi/full/10.1111/jiec.13406
# https://step-initiative.org/files/_documents/other_publications/UNU-Transboundary-Movement-of-Used-EEE.pdf

# *******************************************************************************
# Disposal
# *******************************************************************************
# Covering material releases into environmental mediums incl. land and water

# Landfill - Waste Data Interrogator (waste received)

received_AATF_reuse_wide_54 <- read_xlsx("./intermediate_data/received_reuse_summarised_wide.xlsx",
                                         sheet = 2) %>%

# EWC codes specific to electronics - Discarded electrical and electronic equipment
# 09 01 10
# 09 01 11*
# 09 01 12
# 16 02 11*
# 16 02 13*
# 16 02 14
# 20 01 23*
# 20 01 35*
# 20 01 36 

# Helps separate mixed municipal waste code

# Collected from households for disposal Household waste composition study 
# UK HOUSEHOLD RESIDUAL plus RECYCLING TOTAL - 516,000 tonnes 320,560 going into the recycling stream. 195544 going into residual stream

# LACW Statistics

# Illegal dumping
# https://www.gov.uk/government/statistical-data-sets/env24-fly-tipping-incidents-and-actions-taken-in-england
# https://www.gov.uk/government/publications/environment-agency-2021-data-on-regulated-businesses-in-england

# *******************************************************************************
# Sayers et al 
# *******************************************************************************

# Import data outflow fate (CE-score), pivot longer, filter, drop NA and rename column 'route' 
outflow_routing <- read_excel(
  "./cleaned_data/electronics_outflow.xlsx") %>%
  clean_names() %>%
  pivot_longer(-c(
    `unu_key`,
    `unu_description`,
    `variable`
  ),
  names_to = "route", 
  values_to = "value") %>%
  filter(variable == "Percentage",
         route != "Total",
         value != 	
           0.000000000) %>%
  drop_na(value) %>%
  mutate(year = 2017) %>%
  select(-c(variable, unu_description)) %>%
  mutate(route = gsub("General bin", "disposal", route),
         route = gsub("Recycling", "recycling", route),
         route = gsub("Sold", "resale", route),
         route = gsub("Donation or re-use", "resale", route),
         route = gsub("Other", "refurbish", route),
         route = gsub("Take back scheme", "remanufacture", route),
         route = gsub("Unknown", "maintenance", route))

