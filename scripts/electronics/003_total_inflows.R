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

# Pivot wide to create aggregate values
# Indicators based on https://www.resourcepanel.org/global-material-flows-database
complete_inflows_wide <- pivot_wider(complete_inflows, 
                         names_from = FlowTypeDescription, 
                         values_from = Value) %>%
  clean_names()

# Turn domestic production NA values into a 0 (to remove)
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
# Outlier detection and replacement
# *******************************************************************************
# 

# Import UNU timeseries data in column form (can be calculated as a vector or matrix)
# Perform rolling MAD
runmad(
  x,
  k,
  center = runmed(x, k),
  constant = 3,
  endrule = c("mad"),
  align = c("center")
)

# na.approx performs linear interpolation to replace outliers across whole dataframe, by column/UNU

by_col <- na.approx(m,
                    # as na.approx by itself only covers interpolation and not extrapolation (i.e. misses end values),
                    # also performs extrapolation with rule parameter where end-values are missing through using constant (i.e. last known value)
                    rule = 2,
                    maxgap = 10)

# Interpolate using cubic spline method instead
by_col_spline <- na.spline(m) +
  0 * na.approx(m, na.rm = FALSE)

# By row instead
by_row <- t(na.approx(t(m)))

# *******************************************************************************
# Forecasts (including lightly interpolated data from prior step)
# *******************************************************************************
#

# Produce forecast of sales - arima with economic variable externally 
# Hierarchical time-series with bottom up aggregation approach to forecast construction

# Import outturn sales data (back to 2001 currently).
# 22 data point for annual time-step, 264 for monthly
apparent_consumption <- 
  read_excel("forecast_inputs.xlsx", sheet = 1)

# Convert to time series format
apparent_consumption <- ts(apparent_consumption$value, 
                           start = 2001, 
                           frequency = 1)

# Generate ACF to define ARIMA parameters
Acf(apparent_consumption)

# Generate PACF to define ARIMA parameters
Pacf(apparent_consumption)

# Import forecasted external data (GDP,GVA, GDHI, HE)
external_forecasts_1 <-
  read_excel("gdp_forecast_1.xlsx", sheet = 2)

# Convert external forecasts to time series format
gdp_forecast_1 <- ts(external_forecasts_1$gdp_1,
            start = 2022, 
            frequency = 1)

# Trend

# Create dummy variable (if needed) 
dummy <- apparent_consumption$dummy
dummy_f <- rep(0, 28)
dummy_f[2:5] <- c(1,0.5,0.25,0.125)
year_f <- seq(2022, 2050, 1)

# Combine external predictive variables
xreg_com <- cbind(gdp_forecast_1, dummy)
xreg_com_f <- cbind(gdp_forecast_1, dummy_f)
# Convert to timeseries
xreg_com_f <- as.ts(xreg_com_f, start = 2022, frequency = 1)
# Change column names
colnames(xreg_com_f) <- colnames(xreg_com)

# Define arima model of consumption
arima_consumption <- Arima(apparent_consumption, 
                   order = c(1,0,0), 
                   include.drift = F, 
                   include.mean = T, 
                   xreg = xreg_com)

# Coefficient test (generic function for performing z and (quasi-)t Wald tests of estimated coefficients)
coeftest(arima_consumption, 
         # Define degrees of freedom
         df = )

# Generate forecast
forecast_com <- forecast(arima_com, h=32, fan = F, level = 95, xreg = xreg_com_f)

# Create dataframe with forecasted data compiled
apparent_consumption_f <- data.frame(year_f, 
                        forecast_com$mean, forecast_com$lower[,1], forecast_com$upper[,1])

# *******************************************************************************
# POM method (EA WEEE EPR data)
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
