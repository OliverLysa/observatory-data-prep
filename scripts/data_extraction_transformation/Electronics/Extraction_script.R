
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
              "devtools",
              "roxygen2")

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
# Linking datasets through classification matching
# *******************************************************************************
#

## Link UNU to CN8

# Import UNU HS6 correspondence table
UNU_2_HS6 <-
  read_excel("./classifications/classifications/Core_classifications.xlsx",
             sheet = "UNU_2_HS6")  %>%
  as.data.frame()

# Import CN8 classification
CN <-
  read_excel("./classifications/classifications/Core_classifications.xlsx",
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
  read_excel("./classifications/classifications/Core_classifications.xlsx",
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
#          "./classifications/Concordance tables/UNU_2_CN8_2_PRODCOM_SIC.xlsx")

# *******************************************************************************
# Data extraction and tidying
# *******************************************************************************
#

# *******************************************************************************
# MASS FLOWS
# 

# Inflow ---------------------------

# Apparent consumption method
# **************************

# devtools::install_github("pvdmeulen/uktrade")

#### Extract trade data ####

# Isolate list of CN8 codes from classification table
trade_terms <- 
  UNU_2_CN8_2_PRODCOM$CN8 # delete the following for whole dataframe [283:344] %>%
  unlist()
  
# Create a for loop that goes through the trade terms, extracts the data using the extractor function based on the uktrade wrapper
# and prints the results to a list of dataframes
res <- list()
for (i in seq_along(trade_terms)) {
  res[[i]] <- extractor(trade_terms[i])
  
  print(i)
  
}

# Convert the list of dataframes to a single dataframe
bind <- 
  dplyr::bind_rows(res)

# Remove the month identifier in the month ID column to be able to group by year
bind$MonthId <- 
  substr(bind$MonthId, 1, 4)

# Outlier detection and replacement

# Summarise results grouped by year, flow type and code
Summary_trade <- bind %>%
  # Group by month
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

# Write csv file
# write.csv(Summary_trade_UNU, 
#          "./1. Extract/5. Cleaned_datafiles/Summary_trade_UNU.csv")

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

# Match trade and production data

# Import trade summary
Summary_trade <- read.csv(
  "./cleaned_data/electronics_Summary_trade.csv")

# Convert trade code to character
Summary_trade$Cn8Code <- as.character(Summary_trade$Cn8Code)

# Left join summary trade and UNU classification to get flows by UNU
Summary_trade_UNU <- left_join(Summary_trade,
                               UNU_2_CN8_2_PRODCOM,
                               by = c('Cn8Code' = 'CN8')) %>%
  group_by(`UNU KEY`, Year, Variable, FlowTypeDescription) %>%
  summarise(Value = sum(Value)) %>%
  # Rename contents in variable column
  mutate(Variable = gsub("sum\\(NetMass)", 'Mass', Variable),
       Variable = gsub("sum\\(Value)", 'Value', Variable),
       Variable = gsub("sum\\(SuppUnit)", 'Units', Variable))

# Filter prodcom variable column and mutate values 
Prodcom_data_26_32_UNU <- Prodcom_data_26_32_UNU %>%
  filter(Variable != "£ per Number of items",
         Variable != "£ per Kilogram") %>%
  mutate(FlowTypeDescription = "domestic production") %>%
  mutate(Variable = gsub("Value £000\\'s", "Value", Variable),
         Variable = gsub("Volume \\(Number of items)", "Units", Variable),
         Variable = gsub("Volume \\(Kilogram)", "Mass", Variable))

# Bind/append datasets 
flows <- rbindlist(
  list(
    Summary_trade_UNU,
    Prodcom_data_26_32_UNU),
  use.names = TRUE)

# Pivot wide to create aggregate values then re-pivot long to estimate key aggregates
# Indicators based on https://www.resourcepanel.org/global-material-flows-database
flows_all <- pivot_wider(flows, 
                         names_from = FlowTypeDescription, 
                         values_from = Value) %>%
  clean_names()

flows_all["domestic_production"][is.na(flows_all["domestic_production"])] <- 0

flows_all <- flows_all %>% 
  mutate(total_imports = eu_imports + non_eu_imports,
         total_exports = eu_exports + non_eu_exports,
         net_trade_balance = total_exports - total_imports,
         # equivalent of domestic material consumption at national level
         apparent_consumption = domestic_production + total_imports - total_exports,
         # production perspective - issue of duplication 
         apparent_output = domestic_production + total_exports) %>%
  pivot_longer(-c(unu_key, 
                  year, 
                  variable),
               names_to = "indicator",
               values_to = 'value')

# write_xlsx(flows_all, 
#          "./1. Extract/5. Cleaned_datafiles/electronics_flows.xlsx")

# POM data - see separate script

#### Extract BoM data ####
# Use weighted averages to go from BoM to UNU based on inflow share data

# Download data file from the url
download.file(
  "https://figshare.com/ndownloader/files/22858376",
  "./1. Extract/4. Raw_data_files/Product_BOM.xlsx"
)

# Read all sheets for bill of materials
BoM_sheet_names <- readxl::excel_sheets(
  "./raw_data/Product_BOM.xlsx")

BoM_data <- purrr::map_df(BoM_sheet_names, 
                          ~dplyr::mutate(readxl::read_excel(
                            "./raw_data/Product_BOM.xlsx", 
                            sheet = .x), 
                            sheetname = .x))

# Convert the list of dataframes to a single dataframe, rename columns and filter
BoM_data_bound <- BoM_data %>%
  drop_na(2) %>%
  tidyr::fill(1) %>%
  select(-c(`Data From literature`,
            `Data from literature`,
            18)) %>%
  row_to_names(row_number = 1, 
               remove_rows_above = TRUE) %>%
  filter(`Product name` != "Product name") %>%
  rename(model = `Product name`,
         component = Component,
         product = 15) %>%
  pivot_longer(-c(
  model,
  component,
  product),
  names_to = "material", 
  values_to = "value") %>%
  drop_na(value) %>%
  filter(component != "Total mass (g)",
         material != "Total mass (g)",
         component != "-",
         component != "Mass %",
         model != "Product") %>%
  mutate_at(c('value'), as.numeric) %>%
  mutate(across(c('value'), round, 2)) %>%
  drop_na(value) %>%
  separate(model, c("model", "year"), "\\(") %>%
  mutate(year = gsub("\\)","", year))

# Create filter of products for which we have data
BoM_filter_list <- c("CRT Monitors",
                     "CRT TVs",
                     "Video & DVD",
                     "Desktop PCs",
                     "Small Household Items",
                     "Laptops",
                     "Flat Screen Monitors",
                     "Flat Screen TVs",
                     "Portable Audio",
                     "Printers",
                     "Mobile Phones",
                     "Household Monitoring")

# Rename products to match the UNU colloquial classification, group by product, component and material to average across models and years, then filter to products for which data is held
BoM_data_average <- BoM_data_bound %>%
  mutate(product = gsub("Blu-ray player", 'Video & DVD', product),
         product = gsub("CRT monitor", 'CRT Monitors', product),
         product = gsub("CRT TV", 'CRT TVs', product),
         product = gsub("Traditional desktop", 'Desktop PCs', product),
         product = gsub("Fitness tracker", 'Small Household Items', product),
         product = gsub("Laptop", 'Laptops', product),
         product = gsub("LCD monitor", 'Flat Screen Monitors', product),
         product = gsub("LCD TV", 'Flat Screen TVs', product),
         product = gsub("MP3 player", 'Portable Audio', product),
         product = gsub("Printer", 'Printers', product),
         product = gsub("Smartphone", 'Mobile Phones', product),
         product = gsub("Smart & non-smart thermostat", 'Household Monitoring', product)) %>%
  filter(product %in% BoM_filter_list)

BoM_data_average$product <- gsub("Laptops", "Laptops & Tablets", BoM_data_average$product)

write_xlsx(BoM_data_average, 
           "./raw_data/BoM_data_average_int.xlsx")

lifespan_data <- read_excel(
  "./cleaned_data/electronics_lifespan.xlsx",
  sheet = 1,
  range = "A2:AY75")

BoM_recent <- read_excel(
           "./cleaned_data/BoM_data_average_int2.xlsx")

# Convert data to sankey format
Babbit_sankey_input <- BoM_recent %>%
  mutate(source = material) %>%
  rename(target = component)

Babbit_sankey_input <- Babbit_sankey_input[, c("product", 
                                 "source",
                                 "target",
                                 "material",
                                 "value")]

write_xlsx(Babbit_sankey_input, 
           "./raw_data/Babbit_sankey_input.xlsx")

Babbit_sankey_input2 <- Babbit_sankey_input %>% 
  mutate(source = target,
         target = product)

Babbit_sankey_input2 <- Babbit_sankey_input2[, c("product", 
                                   "source",
                                   "target",
                                   "material",
                                   "value")]

write_xlsx(Babbit_sankey_input2, 
           "./raw_data/Babbit_sankey_input2.xlsx")

Electronics_BoM_sankey_Babbitt2 <- rbindlist(
  list(
    Babbit_sankey_input,
    Babbit_sankey_input2),
  use.names = TRUE)

stacked_units <- electronics_stacked_area_chart %>%
  filter(variable == "inflow") %>%
  rename(product = unu_description)

Babbitt_joined <- right_join(Electronics_BoM_sankey_Babbitt2, stacked_units,
                                 by = c("product")) %>%
  mutate(value = (value.x * value.y)/1000000) %>%
  select(-c(value.x,
            variable,
            value.y)) %>%
  filter(value >0) %>%
  mutate(across(c('value'), round, 2))

Babbitt_joined <- Babbitt_joined[, c("year",
                                     "product",
                                     "source",
                                     "target",
                                     "material",
                                     "value")]

write_xlsx(Babbitt_joined, 
           "./cleaned_data/electronics_sankey_links.xlsx")

# https://www.sciencedirect.com/science/article/pii/S0959652623004109?via%3Dihub#fig5

# Use ---------------------------

#### Extract lifespan/residence-time data ####

# Time in use and time in storage 

# Import lifespan data
lifespan_data <- read_excel(
  "./cleaned_data/electronics_lifespan.xlsx",
  sheet = 1,
  range = "A2:AY75")

# Rename columns and clean names
lifespan_data <- lifespan_data[c(1:73), c(1,4,7:50)] %>%
  rename(UNU = 1,
         UNU_5 = 2,
         Shape = 3,
         Scale = 4) %>%
  clean_names()

# Specify x-axis (time periods for which distribution is printed
# x_axis <- seq(0, 50, 
#              by = 1)

# for (i in seq_along(lifespan_data)) {
#  cdweibull(x_axis, lifespan_data$shape, lifespan_data$scale)
#  }

# Calculate mean and median from Weibull parameters
# weibullparinv(1.6, 8.1599999951404, loc = 0)

# Derive Weibull parameters from Open Repair Data

### Stock data: Electrical products data tables (represent an underestimate)

# https://onlinelibrary.wiley.com/doi/abs/10.1111/jiec.12551
# https://www.sciencedirect.com/science/article/abs/pii/S0959652618339660

# Outflow
# *******************************************************************************
# 

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
  "./scripts/data_extraction_transformation/Electronics/weights.xlsx")

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

# Fly-tipping https://www.gov.uk/government/statistical-data-sets/env24-fly-tipping-incidents-and-actions-taken-in-england
# Waste Data Flow https://www.data.gov.uk/dataset/0e0c12d8-24f6-461f-b4bc-f6d6a5bf2de5/wastedataflow-local-authority-waste-management
# Waste data interrogator
# WEEE Statistics https://www.gov.uk/government/statistical-data-sets/waste-electrical-and-electronic-equipment-weee-in-the-uk

# *******************************************************************************
# MONETARY FLOWS

# Capturing any sources additional to prodcom/trade across production and consumption perspectives

# We are looking at products which fall largely within the SIC codes 26-29
# We start by looking at 2-digit GVA data for these codes
# GVA for the products in scope could include not only data from the manufacturing sector, but also from repair
# and maintenance activities associated with those products as captured below. This allows us to capture structural shifts
# at the meso-level

#### Gross value added Division-level ####
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

# Retrieve SIC codes from lookup tablets
codes <- SIC_sheets$Code
# add relevant repair codes
repair_codes <- c("33", "95")

# Filter to electronics sectors
electronics_GVA <- GVA_2dig_current %>%
  filter(`SIC07 code` %in% c(codes, repair_codes))

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

write_xlsx(electronics_GVA, 
           "./cleaned_data/electronics_GVA.xlsx") 

# Further sectoral detail and additional variables can be derived from the UK Annual Business Survey 

download.file("https://www.ons.gov.uk/file?uri=/businessindustryandtrade/business/businessservices/datasets/uknonfinancialbusinesseconomyannualbusinesssurveysectionsas/current/abssectionsas.xlsx",
              "./raw_data/Non-financial business economy, UK: Sections A to S.xlsx")

# 33.12	Repair of machinery 
# 33.13	Repair of electronic and optical equipment
# 33.14	Repair of electrical equipment 
# 95.1 Repair of computers and communication equipment
# 95.11	Repair of computers and peripheral equipment
# 95.12	Repair of communication equipment 
# 95.21	Repair of consumer electronics
# 95.22	Repair of household appliances and home and garden equipment
# 77.3	Renting and leasing of other machinery, equipment and tangible goods

# Oakdene Hollins study

# *******************************************************************************
# EMISSIONS

# Poduction emissions 

download.file(
  "https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/1086808/SIC-final-greenhouse-gas-emissions-tables-2020.xlsx",
  "UK greenhouse gas emissions by Standard Industrial Classification.xlsx"
)

Emissions_2_digit <-
  read_excel(
    "UK greenhouse gas emissions by Standard Industrial Classification.xlsx",
    sheet = "8.1",
    range = "A31:AH164"
  )  %>%
  as.data.frame() %>%
  filter(
    `Group name` != "Total greenhouse gas emissions",
    `Group name` != "Land use, land use change and forestry (LULUCF)",
    `SIC(07) group` != 97,
    `SIC(07) group` != 100,
    `SIC(07) group` != 101
  ) %>%
  select(-Section) %>%
  rename(group_name = `Group name`) %>%
  rename(SIC_group = `SIC(07) group`)

Emissions_2_digit$SIC_group <- Emissions_2_digit$SIC_group %>%
  str_remove("\\..*") %>%
  str_remove("\\(.*")

Emissions_2_digit <- Emissions_2_digit %>%
  pivot_longer(-c(SIC_group, group_name),
               names_to = 'Year',
               values_to = 'Emissions') %>%
  group_by(SIC_group, Year) %>%
  summarise(Emissions = sum(Emissions))

Joined <- inner_join(
  GVA_2dig_current_long,
  Emissions_2_digit,
  by = c("Year", "SIC_group"),
  type = "full"
)

# Consumption emissions 

# *******************************************************************************
# Bubble chart data

# Read all flows data
flows_all <- read_excel(
  "./cleaned_data/electronics_flows.xlsx")

# Map flows data to electronics bubble chart
electronics_bubble_flows <- flows_all %>%
  # filter to 2017, variable = Units, indicator = apparent_consumption
  filter(year == 2017,
         variable == 'Units',
         indicator == "apparent_consumption") %>%
  select(-c(year, 
            variable, 
            indicator)) %>%
  rename(apparent_consumption = value)

# Convert unit flow data to mass using the Bill of Materials
Babbit_product_total_mass <- BoM_data_average %>%
  group_by(product) %>%
  summarise(value = sum(value))

# Map lifespan data to electronics bubble chart
mean_lifespan <- lifespan_data %>%
  select(c(unu, mean)) %>%
  rename(mean_lifespan = mean)

electronics_bubble_chart <- merge(electronics_bubble_flows,
                                  mean_lifespan,
                                  by.x=c("unu_key"),
                                  by.y=c("unu")) %>%
  mutate(across(c('mean_lifespan'), round, 1))

electronics_bubble_chart2 <- merge(electronics_bubble_chart,
                                   electronics_bubble_outflow,
                                   by.x=c("unu_key"),
                                   by.y=c("UNU KEY")) %>%
  rename(ce_score = scaled)

write_xlsx(electronics_bubble_chart2, 
           "./cleaned_data/electronics_bubble_chart.xlsx")

# UNU <- electronics_bubble_chart2 %>%
#  select(c(unu_key, `UNU DESCRIPTION`))

UNU_colloquial <- electronics_bubble_chart2 %>%
  select(-c(apparent_consumption, 
            mean_lifespan, 
            Year,
            ce_score)) %>%
  clean_names()

write_xlsx(UNU_colloquial, 
           "./classifications/classifications/UNU_colloquial.xlsx")

electronics_bubble_chart2 <- read_excel(
  "./cleaned_data/electronics_bubble_chart.xlsx")

# *******************************************************************************
# Stacked area chart

electronics_stacked_area_wide <- read_excel(
  "./raw_data/electronics_stacked_area_wide.xlsx")

electronics_stacked_area_long <- electronics_stacked_area_wide %>%
  pivot_longer(-c(
    `UNU`,
    `Shape`,
    `Scale`,
    `variable`
  ),
  names_to = "year", 
  values_to = "value") %>%
  as.data.frame() %>%
  select(-c(`Shape`,
            `Scale`)) %>%
  clean_names() %>%
  rename('unu_key' = 'unu')

electronics_stacked_area_chart <- merge(electronics_stacked_area_long,
                                        UNU_colloquial,
                                        by=c("unu_key" = "unu_key")) %>%
  na.omit() %>%
  select(-unu_key)

write_xlsx(electronics_stacked_area_chart, 
           "./cleaned_data/electronics_stacked_area_chart.xlsx")

# *******************************************************************************
# SANKEY

# Import units data
REE_units <- 
  read_excel("./cleaned_data/REE_units.xlsx", col_names = T) %>%
  select(1,3,5) %>%
  rename(year = 1,
         'Offshore wind turbine' = 2,
         'Onshore wind turbine' = 3) %>%
  pivot_longer(-year,
               names_to = "product",
               values_to = "value")

# Import sankey data for single product by year
REE_sankey_links <-
  read_excel("./cleaned_data/REE_sankey_links.xlsx", col_names = T)

# Left join and convert units to mass
REE_sankey_links <- 
  left_join(REE_sankey_links, REE_units, by = c('year','product')) %>%
  mutate(value = Value*value) %>%
  select(-Value)

write_xlsx(REE_sankey_links, 
           "./cleaned_data/REE_sankey_links_units.xlsx")  
