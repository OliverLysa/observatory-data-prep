# *******************************************************************************
# Packages
# *******************************************************************************

# Package names

# devtools::install_github("pvdmeulen/uktrade")

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
# Data extraction and tidying
# *******************************************************************************
#

# Isolate list of CN8 codes from classification table, column 'CN8'
trade_terms <- 
  UNU_CN_PRODCOM$CN8 %>%
unlist()

# Create a for loop that goes through the trade terms, extracts the data using the extractor function (in function script) based on the uktrade wrapper
# and prints the results to a list of dataframes
res <- list()
for (i in seq_along(trade_terms)) {
  res[[i]] <- extractor(trade_terms[i])
  
  print(i)
  
}

# Bind the list of dataframes to a single dataframe
bind <- 
  dplyr::bind_rows(res)

# Remove the month identifier in the month ID column to be able to group by year
# This feature can be removed for more time-granular data e.g. by month or quarter
bind$MonthId <- 
  substr(bind$MonthId, 1, 4)

# Summarise results in value, mass and unit terms grouped by year, flow type and trade code
Summary_trade <- bind %>%
  group_by(MonthId, 
           FlowTypeDescription, 
           Cn8Code) %>%
  summarise(sum(Value), 
            sum(NetMass), 
            sum(SuppUnit)) %>%
  rename(Year = MonthId) %>%
  # Pivot results longer
  pivot_longer(-c(Year, 
                  FlowTypeDescription, 
                  Cn8Code),
               names_to = "Variable",
               values_to = 'Value')

# Convert trade code to character 
Summary_trade$Cn8Code <- 
  as.character(Summary_trade$Cn8Code)

# Left join summary trade and UNU classification to summary by UNU
Summary_trade_UNU <- left_join(Summary_trade,
                               UNU_2_CN8_2_PRODCOM,
                               by = c('Cn8Code' = 'CN8')) %>%
  group_by(`UNU KEY`, Year, Variable, FlowTypeDescription) %>%
  summarise(Value = sum(Value)) %>%
  # Rename contents in variable column
  mutate(Variable = gsub("sum\\(NetMass)", 'Mass', Variable),
         Variable = gsub("sum\\(Value)", 'Value', Variable),
         Variable = gsub("sum\\(SuppUnit)", 'Units', Variable))

# Write xlsx file of output
write_xlsx(Summary_trade_UNU, 
          "./1. Extract/5. Cleaned_datafiles/trade_data_UNU.xlsx")