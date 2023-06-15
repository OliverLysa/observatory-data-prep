
# *******************************************************************************
# Stacked area chart

# Read inflow, stock and outflow data
electronics_stacked_area_wide_units <- read_excel(
  "./cleaned_data/electronics_stacked_area_wide.xlsx")

# Replace with output from script 5

# Convert the wide format data to long format
electronics_stacked_area_long_units <- electronics_stacked_area_wide %>%
  pivot_longer(-c(
    `UNU`,
    `Shape`,
    `Scale`,
    `variable`
  ),
  names_to = "year", 
  values_to = "value") %>%
  as.data.frame() %>%
  select(-c(`Shape`,
            `Scale`)) %>%
  clean_names() %>%
  rename('unu_key' = 'unu')

# Merge with UNU colloquial to get naming 

UNU_colloquial <- read_xlsx("./classifications/classifications/UNU_colloquial.xlsx")

electronics_stacked_area_chart <- merge(electronics_stacked_area_long,
                                        UNU_colloquial,
                                        by=c("unu_key" = "unu_key")) %>%
  na.omit() %>%
  select(-unu_key)

# Write stacked area chart data
write_xlsx(electronics_stacked_area_chart, 
           "./cleaned_data/electronics_stacked_area_chart.xlsx")