
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
  select(-c(unit)) %>%
  filter(value != 0)

# Write stacked area chart data
write_xlsx(electronics_stacked_area_chart, 
           "./cleaned_data/electronics_stacked_area_chart.xlsx")
