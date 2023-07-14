##### **********************
# Author: Oliver Lysaght
# Purpose:
# Inputs:
# Required updates and frequency: 
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
              "RCurl",
              "curl",
              "future",
              "furr",
              "targets",
              "renv")

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
source("./1. Extract/3. Extraction scripts/Functions.R", 
       local = knitr::knit_global())

# Stop scientific notation of numeric values
options(scipen = 999)

# *******************************************************************************
# Linking datasets through classification matching
# *******************************************************************************
#

## Link UNU to CN8 and PRDCODE - old method

# Import UNU HS6 correspondence table
UNU_HS6 <-
  read_excel("./classifications/concordance_tables/UNU_HS6.xlsx")  %>%
  as.data.frame()

# Import CN8 classification
CN <-
  read_excel("./classifications/classifications/CN8.xlsx")  %>%
  as.data.frame() %>%
  mutate_at(c(1), as.character) %>%
  rename(CN_Description = Description)

# Substring CN8 column to create HS6 code 
CN$CN6 <- 
  substr(CN$CN8, 1, 6)

# Left join CN on UNU_HS6 to create correspondence table
UNU_CN8 <- 
  left_join(UNU_HS6,
            CN,
            by = c('HS6' = 'CN6')) %>%
  # Drop description and unit columns
  select(-c(`Supplementary unit`)) %>%
  # Omit HS6 codes where CN8 codes corresponding to UNU categories were not available
  na.omit()

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

# Left join UNU_CN8 to PRODCOM_CN, create SIC Division and Class columns (2 and 4 digit)
UNU_CN_PRODCOM <- 
  left_join(UNU_CN8,
            PRODCOM_CN,
            by = c('CN8' = 'CNCODE')) %>%
  na.omit() %>%
  mutate(SIC2 = substr(PRCCODE, 1, 2),
         SIC4 = substr(PRCCODE, 1, 4))

# Trim white space in PRCCODE column
UNU_CN_PRODCOM$PRCCODE <- 
  trimws(UNU_CN_PRODCOM$PRCCODE, 
         which = c("both"))

# Write file
write_xlsx(UNU_CN_PRODCOM, 
          "./classifications/concordance_tables/UNU_CN_PRODCOM_SIC.xlsx")

## Link UNU to CN8 and PRDCODE - 2nd method

# Import correspondence table from WOT 

# Import UNU CN8 correspondence correspondence table
WOT_UNU_CN8 <-
  read_csv("./classifications/concordance_tables/wot2.0/cn-to-pcc-to-unu-mappings-in-WOT.csv") %>%
  mutate(SIC2 = substr(PCC, 1, 2),
         SIC4 = substr(PCC, 1, 4))

# Write file
write_xlsx(WOT_UNU_CN8, 
           "./classifications/concordance_tables/WOT_UNU_CN8_PCC_SIC.xlsx")
