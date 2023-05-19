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