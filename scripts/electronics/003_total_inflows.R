##### **********************
# Author: Oliver Lysaght
# Required annual updates:

# *******************************************************************************
# Packages
# *******************************************************************************

# Package names
packages <- c(
  "magrittr",
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
  "zoo",
  "naniar"
)

# Install packages not yet installed
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}

# Packages loading
invisible(lapply(packages, library, character.only = TRUE))

# *******************************************************************************
# Apparent consumption calculation
# *******************************************************************************
#

# Import prodcom UNU data if not in global environment
Prodcom_data_UNU <-
  read_excel("./cleaned_data/Prodcom_data_UNU.xlsx")  %>%
  as.data.frame()

# Filter prodcom variable column and mutate variable names to match the trade data
Prodcom_data_UNU <- Prodcom_data_UNU %>%
  mutate(FlowTypeDescription = "domestic production")

# Import trade UNU data if not in global environment
Summary_trade_UNU <-
  read_excel("./cleaned_data/Summary_trade_UNU.xlsx")  %>%
  as.data.frame() %>%
  filter(Variable == "Units") %>%
  select(-c(Variable))

# Bind/append prodcom and trade datasets to create a total inflow dataset
complete_inflows <- rbindlist(list(Summary_trade_UNU,
                                   Prodcom_data_UNU),
                              use.names = TRUE)

# Pivot wide to create aggregate indicators
# based on https://www.resourcepanel.org/global-material-flows-database
complete_inflows_wide <- pivot_wider(complete_inflows,
                                     names_from = FlowTypeDescription,
                                     values_from = Value) %>%
  clean_names()

# Turn domestic production NA values into a 0 (to remove)
complete_inflows_wide["domestic_production"][is.na(complete_inflows_wide["domestic_production"])] <-
  0

# Calculate key aggregates in wide format and then pivot longer
complete_inflows_long <- complete_inflows_wide %>%
  mutate(
    total_imports = eu_imports + non_eu_imports,
    total_exports = eu_exports + non_eu_exports,
    net_trade_balance = total_exports - total_imports,
    # equivalent of domestic material consumption at national level
    apparent_consumption = domestic_production + total_imports - total_exports,
    # production perspective - issue of duplication
    apparent_output = domestic_production + total_exports,
    apparent_input = domestic_production + total_imports,
    import_dependency = (total_imports / (total_imports + total_exports))
  ) %>%
  pivot_longer(-c(unu_key,
                  year),
               names_to = "indicator",
               values_to = 'value')

write_xlsx(complete_inflows_long,
           "./cleaned_data/inflows_indicators.xlsx")

# *******************************************************************************
# Automatic outlier detection and replacement
# *******************************************************************************
#

# Import data, converts to wide format (Redo this, but at the level of individual components of apparent consumption)
inflow_wide_outlier_replaced_NA <-
  read_xlsx("./cleaned_data/inflows_indicators.xlsx") %>%
  filter(indicator == "apparent_consumption") %>%
  select(-c(indicator)) %>%
  pivot_wider(names_from = unu_key,
              values_from = value) %>%
  clean_names() %>%
  select(-year) %>%
  mutate_at(
    .vars = vars(contains("x")),
    .funs = ~ ifelse(abs(.) > median(.) + 4 * mad(., constant = 1), NA, .),
    ~ ifelse(abs(.) > median(.) - 4 * mad(., constant = 1), NA, .)
  )

# Replace outliers (now NAs) by column/UNU across whole dataframe using straight-line interpolation
inflow_wide_outlier_replaced_interpolated <-
  na.approx(inflow_wide_outlier_replaced_NA,
            # as na.approx by itself only covers interpolation and not extrapolation (i.e. misses end values),
            # also performs extrapolation with rule parameter where end-values are missing through using constant (i.e. last known value)
            rule = 2,
            maxgap = 10) %>%
  as.data.frame() %>%
  mutate(year = c(2008:2021), .before = x0101) %>%
  pivot_longer(-year, 
               names_to = "unu_key",
               values_to = "value") %>%
  mutate(`unu_key` = gsub("x", "", `unu_key`))

write_xlsx(inflow_wide_outlier_replaced_interpolated,
           "./cleaned_data/inflow_indicators_interpolated.xlsx")

# Interpolate using cubic spline method instead
inflow_wide_outlier_replaced_spline <-
  na.spline(inflow_wide_outlier_replaced_NA) +
  0 * na.approx(inflow_wide_outlier_replaced_NA,
                na.rm = FALSE,
                rule = 2) %>%
  as.data.frame()

# *******************************************************************************
# Forecasts (including lightly interpolated data from prior step)
# *******************************************************************************
#

# Produce forecast of sales - arima with economic variable externally
# Hierarchical time-series with bottom up aggregation approach to forecast construction

# https://stackoverflow.com/questions/67564279/looping-with-arima-in-r

# Import outturn sales data (back to 2001 currently).
# 22 data point for annual time-step, 264 for monthly
inflow_wide_outlier_replaced_interpolated <-
  read_excel("inflow_wide_outlier_replaced_NA.xlsx", sheet = 1)

# Convert to time series format
apparent_consumption <- ts(inflow_wide_outlier_replaced_interpolated,
                           start = 2001,
                           frequency = 1)

# Import forecasted external data
external_forecasts_1 <-
  read_excel("gdp_forecast_1.xlsx", sheet = 2)

# Convert external forecasts to time series format
gdp_forecast_1 <- ts(external_forecasts_1$gdp_1,
                     start = 2022,
                     frequency = 1)

# Define arima model of consumption
arima_consumption <- auto.Arima(
  # define univariate timeseries
  apparent_consumption,
  allowdrift = F,
  xreg = gdp_forecast_1
)

# Generate forecast
forecast_com <-
  forecast(
    arima_consumption,
    h = 32,
    fan = F,
    level = 95,
    xreg = xreg_com_f
  )

# Create dataframe with forecasted data compiled
apparent_consumption_f <- data.frame(year_f,
                                     forecast_com$mean,
                                     forecast_com$lower[, 1],
                                     forecast_com$upper[, 1])

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
POM_sheet_names <- list_ods_sheets("./raw_data/EEE_on_the_market.ods")

# Map sheet names to imported file by adding a column "sheetname" with its name
POM_data <- purrr::map_df(POM_sheet_names,
                          ~ dplyr::mutate(
                            read_ods("./raw_data/EEE_on_the_market.ods",
                                     sheet = .x),
                            sheetname = .x
                          )) %>%
  # filter out NAs in column 1
  filter(Var.1 != "NA") %>%
  # Add column called quarters
  mutate(quarters = case_when(str_detect(Var.1, "Period covered") ~ Var.1), .before = Var.1) %>%
  # Fill column
  tidyr::fill(1) %>%
  filter(grepl('January - December', quarters)) %>%
  # make numeric and filter out anything but 1-14 in column 1
  mutate_at(c('Var.1'), as.numeric) %>%
  filter(between(Var.1, 1, 14)) %>%
  select(-c(`Var.1`,
            Var.5,
            quarters)) %>%
  rename(
    product = 1,
    household = 2,
    non_household = 3,
    year = 4
  ) %>%
  mutate(year = gsub("\\_.*", "", year))

# Pivot long to input to charts
POM_data <- POM_data %>%
  pivot_longer(-c(product,
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
