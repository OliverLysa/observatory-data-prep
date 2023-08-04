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
source("./scripts/Functions.R", 
       local = knitr::knit_global())

# Stop scientific notation of numeric values
options(scipen = 999)

# *******************************************************************************
# Data extraction
# *******************************************************************************
#

# Download dataset
download.file(
  "https://www.ons.gov.uk/file?uri=/businessindustryandtrade/manufacturingandproductionindustry/datasets/ukmanufacturerssalesbyproductprodcom/current/prodcomdata2020final10082021145108.xlsx",
  "raw_data/UK manufacturers' sales by product.xlsx")

# *******************************************************************************
# Data cleaning
# *******************************************************************************
#

# Read all prodcom sheets into a list of sheets (2008-2020)
prodcom_all <- read_excel_allsheets(
  "./raw_data/UK manufacturers' sales by product.xlsx")

# Remove sheets containing division totals (these create problems with bind)
prodcom_all = prodcom_all[-c(1:4)]

# Bind remaining sheets, create a code column and fill, filter to value-relevant rows
prodcom_filtered1 <- 
  dplyr::bind_rows(prodcom_all) %>%
  # Use the clean prodcom function
  clean_prodcom() %>%
  mutate(Code = case_when(str_detect(Variable, "CN") ~ Variable), .before = 1) %>%
  tidyr::fill(1) %>%
  filter(str_like(Variable, "Value%"))

# Bind remaining sheets, create a code column and fill, filter to volume relevant rows
prodcom_filtered2 <- 
  dplyr::bind_rows(prodcom_all) %>%
  # Use the clean prodcom function
  clean_prodcom() %>%
  mutate(Code = case_when(str_detect(Variable, "CN") ~ Variable), .before = 1) %>%
  tidyr::fill(1) %>%
  filter(str_like(Variable, "Volume%"))

# Bind the extracted data to create a complete dataset
prodcom_all <-
  rbindlist(
    list(
      prodcom_filtered1,
      prodcom_filtered2
    ),
    use.names = FALSE
  ) %>%
  na.omit()

# Use g sub to remove unwanted characters in the code column
prodcom_all <- prodcom_all %>%
  # Remove everything in the code column following a hyphen
  mutate(Code = gsub("\\-.*", "", Code),
         # Remove SIC07 in the code column to stop the SIC-level codes from being deleted with the subsequent line
         Code = gsub('SIC\\(07)', '', Code),
         # Remove everything after the brackets/parentheses in the code column
         Code = gsub("\\(.*", "", Code)
  )

# Rename columns so that they reflect the year for which data is available
prodcom_all <- prodcom_all %>%
  rename("2008" = 3,
         "2009" = 4,
         "2010" = 5,
         "2011" = 6,
         "2012" = 7,
         "2013" = 8,
         "2014" = 9,
         "2015" = 10,
         "2016" = 11,
         "2017" = 12,
         "2018" = 13,
         "2019" = 14,
         "2020" = 15) 

# Convert dataset to long-form, filter non-numeric values in the value column and mutate values
prodcom_all_numeric <- prodcom_all %>%
  pivot_longer(-c(
    `Code`,
    `Variable`
  ),
  names_to = "Year", 
  values_to = "Value") %>%
  filter(Value != "N/A",
         Value != "S",
         Value != "S*") %>%
  mutate(Value = gsub(" ","", Value),
         # Remove letter E in the value column
         Value = gsub("E","", Value),
         # Remove commas in the value column
         Value = gsub(",","", Value),
         # Remove NA in the value column
         Value = gsub("NA","", Value),
         # Remove anything after hyphen in the value column
         Value = gsub("\\-.*","", Value)) %>%
  mutate_at(c('Value'), as.numeric) %>%
  mutate_at(c('Code'), trimws)

# Write prodcom all (full dataset incl. for other areas of research outside of electronics)
write_xlsx(prodcom_all_numeric, 
           "./cleaned_data/prodcom_all.xlsx")

# Interpolation
# *******************************************************************************

# E = Estimate by ONS - accepted at face value
# S/S* = Suppressed (included in other SIC4 aggregate) - estimated
# N/A = Data not available - removed once pivotted

# Pivot, filter out N/A and mutate to get prodcom including suppressed values
prodcom_all_suppressed <- prodcom_all %>%
  pivot_longer(-c(
    `Code`,
    `Variable`
  ),
  names_to = "Year", 
  values_to = "Value") %>%
  filter(Value != "N/A") %>%
  mutate(Value = gsub(" ","", Value),
         # Remove letter E in the value column
         Value = gsub("E","", Value),
         # Remove commas in the value column
         Value = gsub(",","", Value),
         # Remove anything after hyphen in the value column
         Value = gsub("\\-.*","", Value))

# Import trade data to calculate the trade ratio for suppressed data (in number of items)
trade_data <- 
  read_csv("./cleaned_data/electronics_trade_ungrouped.csv") %>%
  mutate(FlowTypeDescription = gsub("EU Exports", "Exports", FlowTypeDescription),
         FlowTypeDescription = gsub("Non-EU Exports", "Exports", FlowTypeDescription)) %>%
  filter(FlowTypeDescription == "Exports")

# Remove the month identifier in the month ID column to be able to group by year
# This feature can be removed for more time-granular data e.g. by month or quarter
trade_data$MonthId <- 
  substr(trade_data$MonthId, 1, 4)

trade_data <- trade_data %>%
  select("MonthId", 
         "FlowTypeDescription",
         "Cn8Code",
         "SuppUnit") %>%
  group_by(MonthId, Cn8Code) %>%
  summarise(Unit = sum(SuppUnit)) %>%
  rename(Year = 1)

# Import prodcom_cn condcordance table
PRODCOM_CN <-
  read_excel("./classifications/concordance_tables/PRODCOM_CN.xlsx")  %>%
  as.data.frame() %>%
  # Drop year, CN-split and prodtype columns
  select(-c(`YEAR`,
            `CN-Split`,
            `PRODTYPE`)) %>%
  na.omit()

# Remove spaces from the CN code
PRODCOM_CN$CNCODE <- 
  gsub('\\s+', '', PRODCOM_CN$CNCODE)

# Match prodcom data with trade data (code by year)

Trade_prodcom <- merge(trade_data,
                          PRODCOM_CN,
                          by.x=c("Cn8Code"),
                          by.y=c("CNCODE"))

Trade_prodcom <- merge(Trade_prodcom,
                       prodcom_all_suppressed,
                       by.x=c("PRCCODE"),
                       by.y=c("Code"))

# Aggregate CN to Prodcom level

# Calculate sum of values and units for all years in which data is available

# Calculate ratio between value and number of units

# Attach this ratio to dataframe with all exports

# Estimate missing number of units with the calculated ratio

# Merge prodcom data with UNU classification, summarise by UNU Key and filter volume rows not expressed in number of units
Prodcom_data_UNU <- merge(prodcom_all,
                                UNU_CN_PRODCOM,
                                by.x=c("Code"),
                                by.y=c("PRCCODE")) %>%
  group_by(`UNU KEY`, Year, Variable) %>%
  summarise(Value = sum(Value)) %>%
  filter(Variable != "Volume (Kilogram)")

# if a cell contains S or S*, we will replace it based on ratio of units exported and units produced for year for which data is available
# based on calculation of export units/ratio = prodcom units for that year

# Write summary file
write_xlsx(Prodcom_data_UNU, 
           "./cleaned_data/Prodcom_data_UNU.xlsx")

# Merge prodcom data with UNU classification, summarise by UNU Key and filter volume rows not expressed in number of units
Prodcom_data_UNU_WOT <- merge(prodcom_filtered_all,
                          WOT_UNU_CN8,
                          by.x=c("Code"),
                          by.y=c("PCC")) %>%
  group_by(`UNU`, Year.x, Variable) %>%
  summarise(Value = sum(Value)) %>%
  filter(Variable != "Volume (Kilogram)") %>%
  rename(Year = 2)

# Write summary file
write_xlsx(Prodcom_data_UNU_WOT, 
           "./cleaned_data/Prodcom_data_UNU_WOT.xlsx")
