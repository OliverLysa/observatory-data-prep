
# *******************************************************************************
# Stacked area chart

# Read wide format data (stock and outflow currently calculated in excel)
electronics_stacked_area_wide_units <- read_excel(
  "./cleaned_data/electronics_stacked_area_wide.xlsx")

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

electronics_stacked_area_chart <- merge(electronics_stacked_area_long,
                                        UNU_colloquial,
                                        by=c("unu_key" = "unu_key")) %>%
  na.omit() %>%
  select(-unu_key)

write_xlsx(UNU_colloquial, 
           "./classifications/classifications/UNU_colloquial.xlsx")

write_xlsx(electronics_stacked_area_chart, 
           "./cleaned_data/electronics_stacked_area_chart.xlsx")