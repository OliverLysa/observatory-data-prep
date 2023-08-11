##### **********************
# Author: Oliver Lysaght
# Purpose:
# Inputs:
# Required annual updates:

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
              "forecast",
              "lmtest",
              "zoo")

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

# Filter prodcom variable column and mutate variable names to match the trade data
Prodcom_data_UNU <- Prodcom_data_UNU %>%
  filter(Variable != "£ per Number of items",
         Variable != "£ per Kilogram") %>%
  mutate(FlowTypeDescription = "domestic production") %>%
  mutate(Variable = gsub("Value £000\\'s", "Value", Variable),
         Variable = gsub("Volume \\(Number of items)", "Units", Variable),
         Variable = gsub("Volume \\(Kilogram)", "Mass", Variable))

# Import trade UNU data if not in global environment
Summary_trade_UNU <-
  read_excel("./cleaned_data/Summary_trade_UNU.xlsx")  %>%
  as.data.frame()

# Bind/append prodcom and trade datasets to create a total inflow dataset
complete_inflows <- rbindlist(
  list(
    Summary_trade_UNU,
    Prodcom_data_UNU),
  use.names = TRUE)

# Pivot wide to create aggregate values then re-pivot long to estimate key aggregates
# Indicators based on https://www.resourcepanel.org/global-material-flows-database
complete_inflows_wide <- pivot_wider(complete_inflows, 
                         names_from = FlowTypeDescription, 
                         values_from = Value) %>%
  clean_names()

# Turn domestic production NA values into a 0
complete_inflows_wide["domestic_production"][is.na(complete_inflows_wide["domestic_production"])] <- 0

# Calculate key aggregates in wide format and then pivot longer
complete_inflows_long <- complete_inflows_wide %>% 
  mutate(total_imports = eu_imports + non_eu_imports,
         total_exports = eu_exports + non_eu_exports,
         net_trade_balance = total_exports - total_imports,
         # equivalent of domestic material consumption at national level
         apparent_consumption = domestic_production + total_imports - total_exports,
         # production perspective - issue of duplication 
         apparent_output = domestic_production + total_exports,
         apparent_input = domestic_production + total_imports,
         import_dependency = (total_imports/(total_imports+total_exports))) %>%
  pivot_longer(-c(unu_key, 
                  year, 
                  variable),
               names_to = "indicator",
               values_to = 'value') %>%
  rename(unit = variable)

write_xlsx(complete_inflows_long, 
          "./cleaned_data/inflows_indicators.xlsx")

# Missing 0001, 0002, 0406, 0502, 0505, 0507, 0702

# *******************************************************************************
# Outlier replacement
# *******************************************************************************
# 

# We use linear interpolation
# Truncation/imputation
# https://stackoverflow.com/questions/72867763/linear-interpolation-in-r-for-columns

df$new_rates <- na.approx(df$rates)
df

# *******************************************************************************
# Forecasts and backcasts
# *******************************************************************************
# 

# Import economic data 
economic_electronics <- ts(data$column, start = 1998, frequency = 1)

# Generate ACF to define ARIMA parameters
Acf(economic_electronics)

# Generate PACF to define ARIMA parameters
Pacf(economic_electronics)

# ARIMA forecast

# Import data for outturn and forecast
data_eng <- read_excel("ci_data_eng.xlsx", sheet = "Sheet1")
data_gdp_forecast <- read_excel("ci_data_eng.xlsx", sheet = "Sheet2")

# Convert to time series format
gdp <- ts(data_eng$gdp_uk, start = 1998, frequency = 1)
gdp_f <- ts(data_gdp_forecast$gdp_uk, start = 2019, frequency = 1)

# Create trend variable
trend <- data_eng$year - 1997

# Take the log of the trend
log_trend <- log(trend)
trend_f <- seq(2019, 2050, 1) - 1997
log_trend_f <- log(trend_f)
dum <- data_eng$dum
dum_f <- rep(0, 32)
dum_f[2:5] <- c(1,0.5,0.25,0.125)
year_f <- seq(2019, 2050, 1)

################################################################################

# Import GVA data 
gva_com <- ts(data_eng$commercial, start = 1998, frequency = 1)

# Generate 
Acf(gva_com)
Pacf(gva_com)

xreg_com <- cbind(gdp, dum)
xreg_com_f <- cbind(gdp_f, dum_f)
xreg_com_f <- as.ts(xreg_com_f, start = 2019, frequency = 1)
colnames(xreg_com_f) <- colnames(xreg_com)

arima_com <- Arima(gva_com, order = c(1,0,0), include.drift = F, include.mean = T, xreg = xreg_com)
coeftest(arima_com, df = 17)
tsdiag(arima_com)

forecast_com <- forecast(arima_com, h=32, fan = F, level = 95, xreg = xreg_com_f)
autoplot(forecast_com)

################################################################################


gva_ind <- ts(data_eng$industrial, start = 1998, end = 2018, frequency = 1)
Acf(gva_ind)
Pacf(gva_ind)

xreg_ind <- cbind(gdp, dum)
xreg_ind_f <- cbind(gdp_f, dum_f)
xreg_ind_f <- as.ts(xreg_ind_f, start = 2019, frequency = 1)
colnames(xreg_ind_f) <- colnames(xreg_ind)

arima_ind <- Arima(gva_ind, order = c(0,0,1), include.drift = F, include.mean = T, xreg = xreg_ind)
coeftest(arima_ind, df = 17)
tsdiag(arima_ind)

forecast_ind <- forecast(arima_ind, h=32, fan = F, level = 95, xreg = xreg_ind_f)
autoplot(forecast_ind)

################################################################################


gva_c_i_f <- data.frame(year_f, 
                        forecast_com$mean, forecast_com$lower[,1], forecast_com$upper[,1],
                        forecast_ind$mean, forecast_ind$lower[,1], forecast_ind$upper[,1])
colnames(gva_c_i_f) <- c("Year", "Com Central", "Com Lower", "Com Upper", 
                         "Ind Central", "Ind Lower", "Ind Upper")

write.csv(gva_c_i_f, "gva_c_i_forecast.csv", row.names = F)

# ARIMA backcast

euretail %>%
  reverse_ts() %>%
  auto.arima() %>%
  forecast() %>%
  reverse_forecast() -> bc

# Comparison with outturn data

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
  mutate(quarters = case_when(str_detect(Var.1, "Period covered") ~ Var.1), .before = Var.1) %>%
  tidyr::fill(1) %>%
  filter(grepl('January - December', quarters)) %>%
  # make numeric and filter out anything but 1-14 in column 1
  mutate_at(c('Var.1'), as.numeric) %>%
  filter(between(Var.1, 1, 14)) %>%
  select(-c(
            `Var.1`,
            Var.5,
            quarters)) %>% 
  rename(product = 1,
         household = 2,
         non_household = 3,
         year = 4) %>%
  mutate(year = gsub("\\_.*", "", year))

# Pivot long to input to charts
POM_data <- POM_data %>%
  pivot_longer(-c(
  product,
  year),
  names_to = "end_use", 
  values_to = "value")

# Write output to xlsx form
write_xlsx(POM_data, 
          "./cleaned_data/electronics_placed_on_market.xlsx")

# Sayer et al 2019
# Freeriders: 46Kt
# Misreporting: 1Kt
# WEEE reported in UK and sold in Ireland: 5Kt 
