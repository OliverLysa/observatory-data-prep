
# *******************************************************************************
# Stacked area chart

electronics_stacked_area_wide <- read_excel(
  "./raw_data/electronics_stacked_area_wide.xlsx")

electronics_stacked_area_long <- electronics_stacked_area_wide %>%
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

write_xlsx(electronics_stacked_area_chart, 
           "./cleaned_data/electronics_stacked_area_chart.xlsx")