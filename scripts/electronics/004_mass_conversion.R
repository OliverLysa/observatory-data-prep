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
              "devtools",
              "roxygen2",
              "testthat",
              "knitr",
              "reshape2")

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
source("./scripts/functions.R", 
       local = knitr::knit_global())

# Stop scientific notation of numeric values
options(scipen = 999)

# *******************************************************************************
# Mass data from https://github.com/Statistics-Netherlands/ewaste/blob/master/data/htbl_Key_Weight.csv
# *******************************************************************************

# Import mass data
UNU_mass <- read_csv(
  "./cleaned_data/htbl_Key_Weight.csv") %>%
  clean_names() %>%
  group_by(unu_key, year) %>%
  summarise(value = mean(average_weight))

# Read inflow data and filter to consumption of units to multiply by mass
inflows_indicators <-
  read_xlsx("./cleaned_data/inflows_indicators.xlsx") %>%
  filter(indicator == "apparent_consumption",
         unit == "Units") %>%
  mutate_at(c('year'), as.numeric) %>%
  na.omit() %>%
  rename(variable = indicator) %>%
  mutate(variable = gsub("apparent_consumption", "inflow", variable),
         unit = gsub("Units", "unit", unit))

# Join by unu key and closest year
# For each value in inflow_indicators year column, find the closest value in UNU_mass that is less than or equal to that x value.
by <- join_by(unu_key, closest(year >= year))
inflow_mass <- left_join(inflows_indicators, UNU_mass, by) %>%
  mutate_at(c("value.y"), as.numeric) %>%
  # calculate mass inflow in tonnes (as mass given in kg/unit in source)
  # https://i.unu.edu/media/ias.unu.edu-en/project/2238/E-waste-Guidelines_Partnership_2015.pdf
  mutate(mass_inflow = (value.x*value.y)/1000) %>%
  select(c(`unu_key`,
            `year.x`,
            mass_inflow)) %>%
  rename(year = 2,
       value = 3) %>%
  mutate(variable = "inflow") %>%
  mutate(unit = "mass")

# Bind the extracted data to create a complete dataset
inflow_unu_mass_units <-
  rbindlist(
    list(
      inflows_indicators,
      inflow_mass
    ),
    use.names = TRUE
  ) %>%
  na.omit()
  
# Write xlsx to the cleaned data folder
write_xlsx(inflow_unu_mass_units, 
           "./cleaned_data/inflow_unu_mass_units.xlsx")

# *******************************************************************************
# Extract BoM data from Babbitt 2019
# *******************************************************************************

# Download data file from the url
download.file(
  "https://figshare.com/ndownloader/files/22858376",
  "./raw_data/Product_BOM.xlsx"
)

# Read all sheets for bill of materials
BoM_sheet_names <- readxl::excel_sheets(
  "./raw_data/Product_BOM.xlsx")

# Import data mapped to sheet name 
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
  mutate(year = gsub("\\)","", year)) %>%
  mutate_at(c('product'), trimws)

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
                     "Household Monitoring",
                     "Toys",
                     "Digital camera",
                     "Games console")

# Rename products to match the UNU colloquial classification, group by product, component and material to average across models and years, then filter to products for which data is held
BoM_data_UNU <- BoM_data_bound %>%
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
         product = gsub("Smart & non-smart thermostat", 'Household Monitoring', product),
         product = gsub("MP3 Player", 'Portable Audio', product),
         product = gsub("Drone", 'Toys', product)) %>%
  filter(product %in% BoM_filter_list) %>%
  mutate(across(everything(), ~replace(., . == "Case", "Body"))) %>%
  mutate(across(everything(), ~replace(., . == "Casing", "Body"))) %>%
  mutate(across(everything(), ~replace(., . == "Main body", "Body"))) %>%              
  mutate(across(everything(), ~replace(., . == "Main assembly", "Body"))) %>%              
  mutate(across(everything(), ~replace(., . == "Access panel assembly", "Body"))) %>%            
  mutate(across(everything(), ~replace(., . == "Frame", "Body"))) %>%
  mutate(across(everything(), ~replace(., . == "Case assembly", "Body"))) %>%
  mutate(across(everything(), ~replace(., . == "Chasis bottom", "Body"))) %>%
  mutate(across(everything(), ~replace(., . == "Chasis top", "Body"))) %>%
  mutate(across(everything(), ~replace(., . == "Inner frame", "Body"))) %>%
  mutate(across(everything(), ~replace(., . == "Outer frame", "Body"))) %>%
  mutate(across(everything(), ~replace(., . == "Drone (main body + camera)", "Body"))) %>%
  mutate(across(everything(), ~replace(., . == "Other components*", "Other components"))) %>%
  mutate(across(everything(), ~replace(., . == "ICs", "Induction coils"))) %>%
  mutate(across(everything(), ~replace(., . == "Inductor coils", "Induction coils"))) %>%
  mutate(across(everything(), ~replace(., . == "monitor cable", "Body"))) %>%
  mutate(across(everything(), ~replace(., . == "3D Glasses", "Controls"))) %>%
  mutate(across(everything(), ~replace(., . == "Remote control", "Controls"))) %>%     
  mutate(across(everything(), ~replace(., . == "Fitness tracker body", "Body"))) 

BoM_data_UNU$product <- gsub("Laptops", "Laptops & Tablets", 
                             BoM_data_UNU$product)
    
# *******************************************************************************
# Extract BoM data from BEIS 
# *******************************************************************************

# https://etl.beis.gov.uk/shared-files/3316/3713/8281/UK_ErP_Policy_Study_final_v4-stc_2_11_21.pdf


# Write data file
write_xlsx(BoM_data_UNU, 
           "./cleaned_data/BoM_data_UNU.xlsx")
