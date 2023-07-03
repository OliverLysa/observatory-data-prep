
# *******************************************************************************
# Stacked area chart

# *******************************************************************************
# Electronics

# Read inflow, stock and outflow data
unu_inflow_stock_outflow <- read_excel(
  "./cleaned_data/unu_inflow_stock_outflow.xlsx")

# Read UNU colloquial
UNU_colloquial <- read_xlsx("./classifications/classifications/UNU_colloquial.xlsx")

# Merge with UNU colloquial to get user-friendly naming
electronics_stacked_area_chart <- merge(unu_inflow_stock_outflow,
                                        UNU_colloquial,
                                        by=c("unu_key" = "unu_key")) %>%
  na.omit() %>%
  select(-unu_key) %>%
  mutate(across(c('value'), round, 0)) %>%
  filter(unit == "mass") %>%
  select(-c(unit))

# Write stacked area chart data to excel file
write_xlsx(electronics_stacked_area_chart, 
          "./cleaned_data/electronics_stacked_area_chart.xlsx")

# Write stacked area chart data
write_csv(electronics_stacked_area_chart, 
           "./cleaned_data/electronics_stacked_area_chart.csv")

# *******************************************************************************
# REE

# Import the vensim output
REE_vensim_all <- read_excel_allsheets(
  "./raw_data/230616_Wind_REE Scenarios_Sankey string generator.xlsx")

# Extract low lifespan, low circularity scenario for wind
wind_low_lifespan_low_circularity <- 
  REE_vensim_all[["1. Wi_20y_zero CE_1"]] %>%
  mutate(product = "Wind turbine",
         aggregation = "material",
         scenario = "baseline_life_zero_eol", .before = Time) %>%
  rename(variable = 4,
         metric = 5)

# Extract high lifespan, high circularity scenario for wind
wind_high_lifespan_high_circularity <- 
  REE_vensim_all[["2. Wi_30y lifespan_High CE_4"]] %>%
  mutate(product = "Wind turbine",
         aggregation = "material",
         scenario = "Extended_life_high_eol", .before = Time) %>%
  rename(variable = 4,
         metric = 5)

# Extract low lifespan, low circularity scenario for EV
EV_low_lifespan_low_circularity <- 
  REE_vensim_all[["3. EV_14y_zero CE_1"]] %>%
  mutate(product = "BEV",
         aggregation = "material",
         scenario = "baseline_life_zero_eol", .before = Time) %>%
  rename(variable = 4,
         metric = 5)

# Extract high lifespan, high circularity scenario for EV 
EV_high_lifespan_high_circularity <- 
  REE_vensim_all[["4. EV_18y_High CE_4"]] %>%
  mutate(product = "BEV",
         aggregation = "material",
         scenario = "Extended_life_high_eol", .before = Time) %>%
  rename(variable = 4,
         metric = 5)

# Bind the extracted data to create a complete dataset, filter to variables of interest and rename these variables
REE_stacked_area <-
  rbindlist(
    list(
      wind_low_lifespan_low_circularity,
      wind_high_lifespan_high_circularity,
      EV_low_lifespan_low_circularity,
      EV_high_lifespan_high_circularity
    ),
    use.names = TRUE
  ) %>%
  filter(grepl('Release rate 6|Release rate 7|Release rate 6 R|Release rate 7 R|Consume \\(use\\) S', variable)) %>%
  select(-metric) %>%
  pivot_longer(-c(product, aggregation, scenario, variable),
               names_to = "year",
               values_to = "value") %>%
  mutate(variable = gsub("Release rate 6 R", "Inflow", variable),
         variable = gsub("Release rate 6", "Inflow", variable),
         variable = gsub("Release rate 7 R", "Outflow", variable),
         variable = gsub("Release rate 7", "Outflow", variable),
         variable = gsub("\"", "", variable),
         variable = gsub("Consume \\(use\\) S", "Stock", variable)) %>%
  mutate(across(c('value'), round, 2)) %>%
  mutate(unit = "mass")

write_csv(REE_stacked_area,
          "./cleaned_data/REE_chart_stacked_area.csv")
