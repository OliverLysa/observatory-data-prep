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

# Production emissions 

download.file(
  "https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/1086808/SIC-final-greenhouse-gas-emissions-tables-2020.xlsx",
  "./raw_data/UK greenhouse gas emissions by Standard Industrial Classification.xlsx"
)

Emissions_2_digit <-
  read_excel(
    "./raw_data/UK greenhouse gas emissions by Standard Industrial Classification.xlsx",
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

filter <- c("26", "27", "28", "29", "32")

Emissions_2_digit <- Emissions_2_digit %>%
  pivot_longer(-c(SIC_group, group_name),
               names_to = 'Year',
               values_to = 'Emissions') %>%
  group_by(SIC_group, Year) %>%
  summarise(Emissions = sum(Emissions)) %>%
  filter(SIC_group %in% filter)

# Write output to xlsx form
write_xlsx(Emissions_2_digit, 
           "./cleaned_data/electronics_emissions_production.xlsx")

# Consumption emissions

# Carbon footprint 