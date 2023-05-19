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

#### Extract prodcom data ####

# Download dataset
download.file(
  "https://www.ons.gov.uk/file?uri=/businessindustryandtrade/manufacturingandproductionindustry/datasets/ukmanufacturerssalesbyproductprodcom/current/prodcomdata2020final10082021145108.xlsx",
  "UK manufacturers' sales by product.xlsx")

# Retrieve SIC codes from the classification table to define which sheets are imported
SIC_sheets <- unique(UNU_2_CN8_2_PRODCOM$SIC2) %>%
  as.data.frame() %>%
  na.omit() %>%
  # 39 filtered due to Prodcom only covering up to Division 33
  filter(. != "39") %>%
  rename("Code" = 1)

# These are being set manually at the moment 

# Read excel sheet, clean, filter out blank rows and those not directly linked to output data (Division 26)
Prodcom_data_26 <- read_excel(
  "./raw_data/UK manufacturers' sales by product.xlsx",
  sheet = "Division 26") %>%
  clean_prodcom() %>%
  mutate(Code = case_when(str_detect(Variable, "26") ~ Variable), .before = 1) %>%
  tidyr::fill(Code)

# Read excel sheet, clean, filter out blank rows and those not directly linked to output data (Division 27)
Prodcom_data_27 <- read_excel(
  "./raw_data/UK manufacturers' sales by product.xlsx",
  sheet = "Division 27") %>%
  clean_prodcom() %>%
  mutate(Code = case_when(str_detect(Variable, "27") ~ Variable), .before = 1) %>%
  tidyr::fill(Code)

# Read excel sheet, clean, filter out blank rows and those not directly linked to output data (Divsion 28)
Prodcom_data_28 <- read_excel(
  "./raw_data/UK manufacturers' sales by product.xlsx",
  sheet = "Division 28") %>%
  clean_prodcom() %>%
  mutate(Code = case_when(str_detect(Variable, "28") ~ Variable), .before = 1) %>%
  tidyr::fill(Code)

# Read excel sheet, clean, filter out blank rows and those not directly linked to output data (Divsion 29)
Prodcom_data_29 <- read_excel(
  "./raw_data/UK manufacturers' sales by product.xlsx",
  sheet = "Division 29") %>%
  clean_prodcom() %>%
  mutate(Code = case_when(str_detect(Variable, "29") ~ Variable), .before = 1) %>%
  tidyr::fill(Code)

# Read excel sheet, clean, filter out blank rows and those not directly linked to output data (Division 32)
Prodcom_data_32 <- read_excel(
  "./raw_data/UK manufacturers' sales by product.xlsx",
  sheet = "Division 32") %>%
  clean_prodcom() %>%
  mutate(Code = case_when(str_detect(Variable, "32") ~ Variable), .before = 1) %>%
  tidyr::fill(Code)

# Bind the extracted division-level data
Prodcom_data_26_32 <-
  rbindlist(
    list(
      Prodcom_data_26,
      Prodcom_data_27,
      Prodcom_data_28,
      Prodcom_data_29,
      Prodcom_data_32
    ),
    use.names = FALSE
  ) %>%
  na.omit()

# Rename columns so that they reflect the year for which data is available
Prodcom_data_26_32 <- Prodcom_data_26_32 %>%
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

# Delete rows where the two columns match to remove prodcom code from variable list
Prodcom_data_26_32 <-
  Prodcom_data_26_32[Prodcom_data_26_32$Code != Prodcom_data_26_32$Variable, ]

# Use g sub to remove unwanted characters
Prodcom_data_26_32 <- Prodcom_data_26_32 %>%
  # Remove everything in the code column following a hyphen
  mutate(Code = gsub("\\-.*", "", Code),
         # Remove SIC07 in the code column to stop the SIC-level codes from being deleted with the subsequent line
         Code = gsub('SIC\\(07)', '', Code),
         # Remove everything after the brackets/parentheses in the code column
         Code = gsub("\\(.*", "", Code)
  )

# Convert dataset to long-form and filter non-numeric values in the value column
Prodcom_data_26_32 <- Prodcom_data_26_32 %>%
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

# Merge prodcom data with UNU classification, summarise by UNU Key
Prodcom_data_26_32_UNU <- merge(Prodcom_data_26_32,
                                UNU_2_CN8_2_PRODCOM,
                                by.x=c("Code"),
                                by.y=c("PRCCODE")) %>%
  group_by(`UNU KEY`, Year, Variable) %>%
  summarise(Value = sum(Value))

# Write summary file
# write.csv(Prodcom_data_26_32_UNU, 
# "./1. Extract/5. Cleaned_datafiles/Prodcom_data_26_32_UNU.csv")