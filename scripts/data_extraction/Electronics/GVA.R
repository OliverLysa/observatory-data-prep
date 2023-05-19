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

##### **********************
# GVA Data Download

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
