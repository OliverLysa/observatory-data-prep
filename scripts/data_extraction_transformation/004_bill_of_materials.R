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
              "knitr")

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