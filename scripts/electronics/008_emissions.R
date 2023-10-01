##### **********************
# Author: Oliver Lysaght
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
# EMISSIONS

# Production emissions from BEIS (covering 7 Kyoto gases)
download.file(
  "https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/1086808/SIC-final-greenhouse-gas-emissions-tables-2020.xlsx",
  "./raw_data/UK greenhouse gas emissions by Standard Industrial Classification.xlsx"
)

# Create lookup for gases
gas_number <- c(1,2,3,4,5,6,7,8)
gas_name <- c('Total GHGs','CO2','CH4','N2O','HFCs','PFCs','SF6','NF3')
gas_lookup <- data.frame(gas_number, gas_name)

# Read in sheet names and convert columns to character to enable bind
BEIS_emissions_sheets <- read_excel_allsheets_BEIS_emissions_SIC(
  "./raw_data/UK greenhouse gas emissions by Standard Industrial Classification.xlsx") %>%
  lapply(\(x) mutate(x, across(.fns = as.character)))

# Remove covering sheets containing cover and contents
BEIS_emissions_sheets = BEIS_emissions_sheets[-c(1:2,11)]

# Bind rows to create one single dataframe, filter, rename, pivot and filter again
BEIS_emissions_data <-
  dplyr::bind_rows(BEIS_emissions_sheets) %>%
  rename(group = 2) %>%
  filter(!grepl('Total', group)) %>%
  filter(!grepl('name', group)) %>%
  filter(!grepl('[A-Z]', Section)) %>%
  filter(!grepl('-', Section)) %>%
  drop_na(2) %>%
  rename(group = 1,
         section = 2,
         group_name = 3) %>%
  mutate(gas_number = ((row_number()-1) %/% 120)+1) %>%
  right_join(gas_lookup, by = c("gas_number")) %>%
  select(-c(gas_number)) %>%
  pivot_longer(-c(group, section, group_name, gas_name),
               names_to = 'year',
               values_to = 'value') 

# Filter to SIC codes of interest
filter <- c("26", "27")
BEIS_emissions_electronics <- 
  BEIS_emissions_data %>%
  filter(group %in% filter) %>%
  select(-c(group,section)) %>%
  mutate_at(c('year','value'), as.numeric)

ggplot(BEIS_emissions_electronics, aes(x = year, y = value, group = group_name)) +
  facet_wrap(vars(gas_name), nrow = 4) +
  theme_light() +
  geom_line(aes(color=group_name)) +
  theme(legend.position="bottom")

# Write output to xlsx form
write_xlsx(BEIS_emissions_electronics, 
           "./cleaned_data/electronics_emissions_production.xlsx")

## Material footprint

# Material footprint
download.file(
  "https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/1176404/2020_Defra_results_England.ods",
  "./raw_data/England_material_footprint.ods"
)

# Create lookup
material_number <- c(1,2,3,4,5)
material_name <- c('Total','Biomass','Metallic ores','Fossil fuels','Non-metallic minerals')
material_lookup <- data.frame(material_number, material_name)

# Create filter list for products
filter_list <- c("Household appliances",
                 "Tools and equipment for house and garden",
                 "Medical products appliances and equipment",
                 "Telephone and telefax equipment",
                 "Audio-visual photo and info processing equipment",
                 "Other recreational equipment etc")

# Import data and filter
mf_product <- read_ods("./raw_data/England_material_footprint.ods",
                       sheet = 5) %>%
  row_to_names(row_number = 2, 
               remove_rows_above = TRUE) %>%
  clean_names() %>%
  drop_na(5) %>%
  select(-1) %>%
  rename(year = 1) %>%
  na.omit() %>% 
  mutate(material_number = ((row_number()-1) %/% 20)+1) %>%
  right_join(material_lookup, by = c("material_number")) %>%
  select(-c(material_number)) %>%
  pivot_longer(-c(year, material_name),
               names_to = "product") %>%
  mutate(product = gsub("_", " ", product)) %>%
  mutate(product = sub("(.)", "\\U\\1", product, perl=TRUE)) %>%
  filter(product %in% filter_list) %>%
  mutate_at(c('value'), as.numeric)

# Create chart
ggplot(mf_product, aes(x = year, y = value, group = product)) +
  facet_wrap(vars(material_name), nrow = 4, scales = "free") +
  geom_line(aes(color=product)) +
  theme_light() +
  theme(legend.position="bottom")

## Consumption emissions

download.file(
  "https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/1175932/2023_03_21_Defra_results_England_rev.ods",
  "./raw_data/England_carbon_footprint.ods"
)

# Create lookup
emissions_number <- c(1,2)
emissions_name <- c('Greenhouse Gas emissions','Carbon Dioxide emissions')
emissions_lookup <- data.frame(emissions_number, emissions_name)

# Create filter list for products
filter_list <- c("Household appliances",
                 "Tools and equipment for house and garden",
                 "Medical products appliances and equipment",
                 "Telephone and telefax equipment",
                 "Audio-visual photo and info processing equipment",
                 "Other recreational equipment etc")

# Import data and filter
cf_product <- read_ods("./raw_data/England_carbon_footprint.ods",
                       sheet = 5) %>%
  row_to_names(row_number = 1, 
               remove_rows_above = TRUE) %>%
  clean_names() %>%
  drop_na(5) %>%
  select(-1) %>%
  rename(year = 1) %>%
  na.omit() %>% 
  mutate(emissions_number = ((row_number()-1) %/% 20)+1) %>%
  right_join(emissions_lookup, by = c("emissions_number")) %>%
  select(-c(emissions_number)) %>%
  pivot_longer(-c(year, emissions_name),
               names_to = "product") %>%
  mutate(product = gsub("_", " ", product)) %>%
  mutate(product = sub("(.)", "\\U\\1", product, perl=TRUE)) %>%
  filter(product %in% filter_list) %>%
  mutate_at(c('value'), as.numeric)

# Create chart
ggplot(cf_product, aes(x = year, y = value, group = product)) +
  facet_wrap(vars(emissions_name), nrow = 2) +
  geom_line(aes(color=product)) +
  theme_light() +
  theme(legend.position="bottom")
