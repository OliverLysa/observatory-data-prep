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

# *******************************************************************************
# WEEE collected in the UK
# *******************************************************************************

# This report shows both the amount of household and non-household Waste Electrical and Electronic Equipment (WEEE) collected by Producer Compliance Schemes and their members.

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
# WEEE received at an approved authorised treatment facility
# *******************************************************************************

# Apply download.file function in R
download.file("https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/1160180/WEEE_received_at_an_approved_authorised_treatment_facility.ods",
              "./raw_data/WEEE_received_AATF.ods")

# *******************************************************************************
# WEEE received by approved exporters
# *******************************************************************************

# *******************************************************************************
# Non-obligated WEEE received at approved authorised treatment facilities and approved exporters
# *******************************************************************************

# Apply download.file function in R
download.file("https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/913182/Non-obligated_WEEE_received_at_approved_authorised_treatment_facilities_and_approved_exporters.ods",
              "./Publication/Input/WPP_Sectors/WEEE/EA/raw/non_obligated_received.ods")


