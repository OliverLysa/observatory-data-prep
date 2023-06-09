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
# Apparent consumption method
# *******************************************************************************
#

# Import prodcom UNU data if not in global environment
Prodcom_data_UNU <-
  read_excel("./cleaned_data/Prodcom_data_UNU.xlsx")  %>%
  as.data.frame()

# Filter prodcom variable column and mutate variable names to reflect the trade data
Prodcom_data_26_32_UNU <- Prodcom_data_26_32_UNU %>%
  filter(Variable != "£ per Number of items",
         Variable != "£ per Kilogram") %>%
  mutate(FlowTypeDescription = "domestic production") %>%
  mutate(Variable = gsub("Value £000\\'s", "Value", Variable),
         Variable = gsub("Volume \\(Number of items)", "Units", Variable),
         Variable = gsub("Volume \\(Kilogram)", "Mass", Variable))

# Bind/append prodcom and trade datasets to create a total inflow dataset
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

# Turn domestic production NA values into a 0
flows_all["domestic_production"][is.na(flows_all["domestic_production"])] <- 0

# Calculate key aggregates in wide format and then pivot longer
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

write_xlsx(flows_all, 
          "./cleaned_data/electronics_flows.xlsx")

# *******************************************************************************
# POM method
# *******************************************************************************
#

# Download EEE data file from URL at government website
download.file(
  "https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/1160182/Electrical_and_electronic_equipment_placed_on_the_UK_market.ods",
  "./raw_data/EEE_on_the_market.ods"
)

# Extract and list all sheet names 
POM_sheet_names <- list_ods_sheets(
  "./raw_data/EEE_on_the_market.ods")

# Map sheet names to imported file by adding a column "sheetname" with its name
POM_data <- purrr::map_df(POM_sheet_names, 
                          ~dplyr::mutate(read_ods(
                            "./raw_data/EEE_on_the_market.ods", 
                            sheet = .x), 
                            sheetname = .x)) %>%
  # filter out NAs in column 1
  filter(Var.1 != "NA") %>%
  # make numeric and filter out anything but 1-14 in column 1
  mutate_at(c('Var.1'), as.numeric) %>%
  filter(between(Var.1, 1, 14)) %>%
  select(-c(`Var.1`,
            Var.5)) %>% 
  rename(product = 1,
         household = 2,
         non_household = 3,
         year = 4)

# substring the year column to remove the quarterly reference while keeping partial years in
POM_data$year <- 
  substr(POM_data$year, 1, 4)

# Pivot long to input to charts
POM_data <- POM_data %>%
  pivot_longer(-c(
  product,
  year),
  names_to = "end_use", 
  values_to = "value")

# Write output to xlsx form
write_xlsx(POM_data, 
          "./cleaned_data/electronics_POM.xlsx")