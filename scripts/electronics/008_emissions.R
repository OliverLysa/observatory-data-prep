##### **********************
# Author: Oliver Lysaght
# Purpose:
# Inputs: Leeds carbon footprint data published by Defra (key Leeds contacts: Anne Owen, John Barrett)
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

# Write output to xlsx form
write_xlsx(Emissions_2_digit, 
           "./cleaned_data/electronics_emissions_production.xlsx")

# Generate ggplot  
ggplot(na.omit(Emissions_2_digit), aes(x= Year, y = Emissions, group = SIC_group)) +
  theme_bw() +
  geom_line(aes(color=SIC_group)) +
  scale_y_continuous(
    breaks = seq(0, 2000, 250),
    minor_breaks = seq(0 , 1250, 125),
    limits = c(0, 2000),
    expand = c(0, 0)
  ) +
  scale_x_continuous(
    breaks = seq(1990, 2020, 5), 
    expand = c(0, 0.3)
  ) +
  ylab("(ktCO2e)") +
  xlab("Year")

ggplot(BEIS_emissions_electronics, aes(x = year, y = value, group = group_name)) +
  facet_wrap(vars(gas_name), nrow = 4) +
  theme_light() +
  geom_line(aes(color=group_name)) +
  theme(legend.position="bottom")

## Consumption emissions

