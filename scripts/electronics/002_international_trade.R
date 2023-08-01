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
              "janitor",
              "future",
              "furrr")

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

# Create filter list for any codes to exclude - these cause a 403 API error on my computer
filter_list <- c("84721000",
                 "95030061",
                 "85286920",
                 "85192010",
                 "90258080")

# Read file of CN codes
UNU_CN_PRODCOM <- read_xlsx("./classifications/concordance_tables/UNU_CN_PRODCOM_SIC.xlsx") %>%
  filter(! CN8 %in% filter_list)

# Isolate list of CN8 codes from classification table, column 'CN8', extract unique codes and unlist
trade_terms <- 
  UNU_CN_PRODCOM$CN8 %>%
  unique() %>%
  unlist()

# If a subset of those codes are sought, these can be selected by index position 
# trade_terms <- trade_terms[271:303]

# Create a for loop that goes through the trade terms, extracts the data using the extractor function (in function script) based on the uktrade wrapper
# and prints the results to a list of dataframes
res <- list()
for (i in seq_along(trade_terms)) {
  res[[i]] <- extractor(trade_terms[i])
  
  print(i)
  
}

# Bind the list of returned dataframes to a single dataframe
bind <- 
  dplyr::bind_rows(res)

# If you have not used the in-built lookup codes in the uktrade R package, the flow-types need to be described
bind <- bind %>%
  mutate(FlowTypeId = gsub(1, 'EU Imports', FlowTypeId),
         FlowTypeId = gsub(2, 'EU Exports', FlowTypeId),
         FlowTypeId = gsub(3, 'Non-EU Imports', FlowTypeId),
         FlowTypeId = gsub(4, 'Non-EU Exports', FlowTypeId)) %>%
  rename(FlowTypeDescription = FlowTypeId)

# Remove the month identifier in the month ID column to be able to group by year
# This feature can be removed for more time-granular data e.g. by month or quarter
bind$MonthId <- 
  substr(bind$MonthId, 1, 4)

# Summarise results in value, mass and unit terms grouped by year, flow type, trade code and country. Requires having used the lookup tables in the trade package
Summary_trade_country_split <- bind %>%
  group_by(MonthId, 
           FlowTypeDescription, 
           Cn8Code,
           CountryName) %>%
  summarise(sum(Value), 
            sum(NetMass), 
            sum(SuppUnit)) %>%
  rename(Year = MonthId) %>%
  # Pivot results longer
  pivot_longer(-c(Year, 
                  FlowTypeDescription, 
                  Cn8Code,
                  CountryName),
               names_to = "Variable",
               values_to = 'Value')

# Left join summary trade country split and UNU classification to summarise by UNU
Summary_trade_country_UNU <- left_join(Summary_trade_country_split,
                               UNU_CN_PRODCOM,
                               by = c('Cn8Code' = 'CN8')) %>%
  group_by(`UNU KEY`, 
           Year, 
           Variable, 
           FlowTypeDescription, 
           CountryName) %>%
  summarise(Value = sum(Value)) %>%
  # Rename contents in variable column
  mutate(Variable = gsub("sum\\(NetMass)", 'Mass', Variable),
         Variable = gsub("sum\\(Value)", 'Value', Variable),
         Variable = gsub("sum\\(SuppUnit)", 'Units', Variable))

# Write CSV of raw trade data for codes
write_xlsx(Summary_trade_country_UNU, 
           "./cleaned_data/Summary_trade_country_split.xlsx")

# Summarise results in value, mass and unit terms grouped by year, flow type and trade code (this then obscures trade country source/destination)
Summary_trade <- bind %>%
  group_by(MonthId, 
           FlowTypeDescription, 
           CommodityId) %>%
  summarise(sum(Value), 
            sum(NetMass), 
            sum(SuppUnit)) %>%
  rename(Year = MonthId) %>%
  # Pivot results longer
  pivot_longer(-c(Year, 
                  FlowTypeDescription, 
                  CommodityId),
               names_to = "Variable",
               values_to = 'Value') %>%
  # Convert trade code to character
  mutate_at(c(3), as.character)

# Left join summary trade and UNU classification to summarise by UNU
Summary_trade_UNU <- left_join(Summary_trade,
                               UNU_CN_PRODCOM,
                               by = c('CommodityId' = 'CN8')) %>%
  group_by(`UNU KEY`, Year, Variable, FlowTypeDescription) %>%
  summarise(Value = sum(Value)) %>%
  # Rename contents in variable column
  mutate(Variable = gsub("sum\\(NetMass)", 'Mass', Variable),
         Variable = gsub("sum\\(Value)", 'Value', Variable),
         Variable = gsub("sum\\(SuppUnit)", 'Units', Variable))

# Write xlsx file of output
write_xlsx(Summary_trade_UNU, 
          "./cleaned_data/summary_trade_UNU_pre_2007.xlsx")

# Work in progress

# Isolate list of CN8 codes from classification table, column 'CN'
trade_terms_wot <- WOT_UNU_CN8 %>%
  filter(Year > 2008) %>%
  mutate(CN = gsub("85279290","85279200", CN)) %>%
  filter(CN != c("85287235",
                 "85287251"))

# Extract unique terms from the list
trade_terms_wot <-
  unique(trade_terms_wot$CN) %>%
  unlist() %>%
  as.character(CN)