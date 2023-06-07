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
              "mixdist")

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

## Link UNU to CN8

# Import UNU HS6 correspondence table
UNU_2_HS6 <-
  read_excel("./1. Extract/2. Classification database/Core_classifications.xlsx",
             sheet = "UNU_2_HS6")  %>%
  as.data.frame()

# Import CN8 classification
CN <-
  read_excel("./1. Extract/2. Classification database/Core_classifications.xlsx",
             sheet = "CN")  %>%
  as.data.frame() %>%
  mutate_at(c(1), as.character) %>%
  rename(CN_Description = Description)

# Substring CN8 column to create HS6 code 
CN$CN6 <- 
  substr(CN$CN8, 1, 6)

# Left join CN on UNU_2_HS6 to create correspondence table
UNU_2_CN8 <- 
  left_join(UNU_2_HS6,
            CN,
            by = c('HS6' = 'CN6')) %>%
  # Drop description and unit columns
  select(-c(`HS Description`,
            `Supplementary unit`)) %>%
  # Omit HS6 codes where CN8 codes corresponding to UNU categories were not available
  na.omit()

# Link UNU_2_CN8 to Prodcom classification
PRODCOM_2_CN <-
  read_excel("./1. Extract/2. Classification database/Core_classifications.xlsx",
             sheet = "PRODCOM_2_CN")  %>%
  as.data.frame() %>%
  # Drop year, CN-split and prodtype columns
  select(-c(`YEAR`,
            `CN-Split`,
            `PRODTYPE`)) %>%
  na.omit()

# Remove spaces from the CN code
PRODCOM_2_CN$CNCODE <- 
  gsub('\\s+', '', PRODCOM_2_CN$CNCODE)

# Left join UNU_2_CN8 to PRODCOM_2_CN
UNU_2_CN8_2_PRODCOM <- 
  left_join(UNU_2_CN8,
            PRODCOM_2_CN,
            by = c('CN8' = 'CNCODE'))

# Substring PRCCODE column to create SIC Division (2 digit) and then 4 digit
UNU_2_CN8_2_PRODCOM$SIC2 <-
  substr(UNU_2_CN8_2_PRODCOM$PRCCODE, 1, 2)

# Substring PRCCODE column to create SIC Class(4 digit)
UNU_2_CN8_2_PRODCOM$SIC4 <-
  substr(UNU_2_CN8_2_PRODCOM$PRCCODE, 1, 4)

# Trim white space in PRCCODE column
UNU_2_CN8_2_PRODCOM$PRCCODE <- 
  trimws(UNU_2_CN8_2_PRODCOM$PRCCODE, 
         which = c("both"))

# write_xlsx(UNU_2_CN8_2_PRODCOM, 
#          "./1. Extract/2. Classification database/Concordance tables/UNU_2_CN8_2_PRODCOM_SIC.xlsx")
