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
              "janitor",
              "onsr")

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
source("./scripts/Functions.R", 
       local = knitr::knit_global())

# Stop scientific notation of numeric values
options(scipen = 999)

# *******************************************************************************
# Data extraction
# *******************************************************************************
#

##### **********************
# 2-digit GVA Data Download

# We are looking at products which fall largely within the SIC codes 26-29
# We start by looking at 2-digit GVA data for these codes
# GVA for the products in scope could include not only data from the manufacturing sector, but also from repair
# and maintenance activities associated with those products as captured below. This allows us to capture structural shifts
# at the meso-level

# Import 2 digit GVA data published by ONS
GVA_2dig_current <-
  read_excel(
    "./raw_data/GVA/regionalgrossvalueaddedbalancedbyindustryandallitlregions.xlsx",
    sheet = "Table1c",
    range = "A2:AA1714"
  )  %>%
  as.data.frame() %>%
  filter(`ITL region name` == "United Kingdom") %>%
  dplyr::filter(!grepl('-', `SIC07 code`)) %>%
  mutate(`SIC07 code` = gsub("\\).*", "", `SIC07 code`),
         `SIC07 code` = gsub(".*\\(", "", `SIC07 code`)) 

# add relevant repair codes
codes <- c("26", "27")

# Filter to electronics sectors
electronics_GVA <- GVA_2dig_current %>%
  filter(`SIC07 code` %in% c(codes))

# Convert to long-form
electronics_GVA <- electronics_GVA %>%
  pivot_longer(-c(
    `ITL region code`,
    `ITL region name`,
    `SIC07 code`,
    `SIC07 description`
  ),
  names_to = "Year", 
  values_to = "GVA") %>%
  as.data.frame() %>%
  select(-`ITL region code`) %>%
  rename(SIC_group = `SIC07 code`)

ggplot(electronics_GVA, aes(group=SIC_group, y=GVA, x=Year)) + 
  geom_line(aes(color=SIC_group)) +
  theme(panel.background = element_rect(fill = "#FFFFFF")) +
  ylab("Millions")

write_xlsx(electronics_GVA, 
           "./cleaned_data/electronics_GVA.xlsx") 

##### **********************
# 4-digit aGVA Data Download

# Download the raw 4-digit aGVA data
download.file("https://www.ons.gov.uk/file?uri=/businessindustryandtrade/business/businessservices/datasets/uknonfinancialbusinesseconomyannualbusinesssurveysectionsas/current/abssectionsas.xlsx",
              "./raw_data/Non-financial business economy, UK: Sections A to S.xlsx")

# Extract all sheets into a list of dataframes. We use an ABS specific function to exclude 
aGVA_sheets <- read_excel_allsheets_ABS(
  "./raw_data/Non-financial business economy, UK: Sections A to S.xlsx")

# Remove covering sheets containing division totals
aGVA_sheets = aGVA_sheets[-c(1:4)]

# Bind rows to create one single dataframe, filter, rename, pivot and filter again
aGVA_data <-
  dplyr::bind_rows(aGVA_sheets) %>%
  filter(Description != "Description") %>%
  rename(code = 1) %>%
  mutate(code = gsub("\\.", "", code)) %>%
  dplyr::filter(!grepl('(Part)', `code`)) %>%
  clean_names() %>%
  pivot_longer(-c(`code`,
                  `description`,
                  `year`),
               names_to = "indicator",
               values_to = "value") %>%
  filter(value != "[c]") %>%
  filter(value != "[low]") %>%
  mutate_at(c('value'), as.numeric) %>%
  mutate(indicator = gsub("number_of_enterprises", 'Number of enterprises', indicator),
         indicator = gsub("total_turnover", 'Total turnover', indicator),
         indicator = gsub("approximate_gross_value_added_at_basic_prices_a_gva", 'aGVA at basic prices', indicator),
         indicator = gsub("total_purchases_of_goods_materials_and_services", 'Total purchases of goods and services', indicator),
         indicator = gsub("total_employment_costs", 'Employment costs', indicator),
         indicator = gsub("total_stocks_and_work_in_progress_value_at_end_of_year", 'Stock end of year', indicator),
         indicator = gsub("total_stocks_and_work_in_progress_value_at_beginning_of_year", 'Stock beginning of year', indicator),
         indicator = gsub("total_stocks_and_work_in_progress_increase_during_year", 'Stock increase during year', indicator),
         indicator = gsub("total_net_capital_expenditure_note_2", 'Net capital expenditure', indicator),
         indicator = gsub("total_capital_expenditure_acquisitions_note_2", 'Capital expenditure acquisitions', indicator),
         indicator = gsub("total_capital_expenditure_disposals_note_2", 'Capital expenditure disposals', indicator))

# Write summary file
write_xlsx(aGVA_data, 
           "./cleaned_data/ABS_all.xlsx")

# Select codes of interest
              # 33.12	Repair of machinery 
extract <- c("3312",
             # 33.13	Repair of electronic and optical equipment
             "3313",
             # 33.14	Repair of electrical equipment
             "3314",
             # 95.1 Repair of computers and communication equipment
             "951",
             # 95.21	Repair of consumer electronics
             "9521",
             # 95.22	Repair of household appliances and home and garden equipment
             "9522")

# Extract those codes from the code column 
aGVA_data_electronics <- aGVA_data %>%
  filter(code %in% extract)

# Write summary file
write_xlsx(aGVA_data_electronics, 
           "./cleaned_data/ABS_electronics.xlsx")
