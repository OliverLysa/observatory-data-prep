
# *******************************************************************************
# Stacked area chart

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

# REE Data input
REE_stacked_area <- read_xlsx("./cleaned_data/REE_chart_stacked_area.xlsx") %>%
  mutate(across(c('value'), round, 2))

write_csv(REE_stacked_area,
          "./cleaned_data/REE_stacked_area.csv")
