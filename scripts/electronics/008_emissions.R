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

## Consumption emissions

# GG1 

# Download file from net
download.file("https://uk-air.defra.gov.uk/reports/cat09/2106240841_DA_GHGI_1990-2019_Final_Issue1.2.xlsx",
              "./Publication/Input/GG/Downloaded_files/England_NAEI_2019.xlsm")

#Import raw data
GG1 <- read_excel("./Publication/Input/GG/Downloaded_files/England_NAEI_2018.xlsm", sheet = 2) 

#Pivot long
GG1 <- GG1[c(16,139:147), c(1:26)] %>%
  row_to_names(row_number = 1) %>%
  pivot_longer(-c(IPCC), names_to = c("Year")) %>%
  filter(Year != "BaseYear", IPCC != "Total") 

GG1$Year <- as.numeric(as.character(GG1$Year))
GG1$value <- as.numeric(as.character(GG1$value))

GG1 <- GG1 %>% mutate_if(is.numeric, round, digits=0) 

write_xlsx(GG1, "./Publication/Input/GG/GG1.xlsx") 

# GG2
# Download file from net
download.file("http://sciencesearch.defra.gov.uk/Document.aspx?Document=15089_EnglandGHG,Carbon,EnergyFootprintResults(2001-2018).xlsx",
              destfile= "./Publication/Input/GG/Downloaded_files/Carbon_Footprint.xlsx")

#Import raw data
GG2 <- read_excel("./Publication/Input/GG/Downloaded_files/Carbon_Footprint.xlsx", sheet = 3) 

#Pivot long
GG2region <- GG2[c(1,3:19), c(1:17)] %>%
  row_to_names(row_number = 1) 

#Add column title 
colnames(GG2region)[1]  <- "Year"

#Pivot long
GG2region <- GG2region %>%
  pivot_longer(-c(Year), names_to = c("Region"))

#Make numeric columns
GG2region$Year<- as.numeric(as.character(GG2region$Year))
GG2region$value <- as.numeric(as.character(GG2region$value))

#Round numeric columns
GG2region <- GG2region %>% mutate_if(is.numeric, round, digits=0) 

write_xlsx(GG2region, "./Publication/Input/GG/GG2region.xlsx") 


