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
  "UK manufacturers' sales by product.xlsx")

# *******************************************************************************
# Data cleaning
# *******************************************************************************
#

# Read all prodcom sheets into a list of sheets
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
prodcom_filtered_all <-
  rbindlist(
    list(
      prodcom_filtered1,
      prodcom_filtered2
    ),
    use.names = FALSE
  ) %>%
  na.omit()

# Use g sub to remove unwanted characters in the code column
prodcom_filtered_all <- prodcom_filtered_all %>%
  # Remove everything in the code column following a hyphen
  mutate(Code = gsub("\\-.*", "", Code),
         # Remove SIC07 in the code column to stop the SIC-level codes from being deleted with the subsequent line
         Code = gsub('SIC\\(07)', '', Code),
         # Remove everything after the brackets/parentheses in the code column
         Code = gsub("\\(.*", "", Code)
  )

# Rename columns so that they reflect the year for which data is available
prodcom_filtered_all <- prodcom_filtered_all %>%
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
prodcom_filtered_all <- prodcom_filtered_all %>%
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

# Write prodcom all (for other areas of research outside of electronics)
write_xlsx(prodcom_filtered_all, 
           "./cleaned_data/prodcom_all.xlsx")

# Merge prodcom data with UNU classification, summarise by UNU Key and filter volume rows not expressed in number of units
Prodcom_data_UNU <- merge(prodcom_filtered_all,
                                UNU_CN_PRODCOM,
                                by.x=c("Code"),
                                by.y=c("PRCCODE")) %>%
  group_by(`UNU KEY`, Year, Variable) %>%
  summarise(Value = sum(Value)) %>%
  filter(Variable != "Volume (Kilogram)")

# Write summary file
write_xlsx(Prodcom_data_UNU, 
 "./cleaned_data/Prodcom_data_UNU.xlsx")
