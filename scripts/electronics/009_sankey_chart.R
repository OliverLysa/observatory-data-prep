
# *******************************************************************************
# SANKEY

# Import units data
REE_units <- 
  read_excel("./cleaned_data/REE_units.xlsx", col_names = T) %>%
  select(1,3,5) %>%
  rename(year = 1,
         'Offshore wind turbine' = 2,
         'Onshore wind turbine' = 3) %>%
  pivot_longer(-year,
               names_to = "product",
               values_to = "value")

# Import sankey data for single product by year
REE_sankey_links <-
  read_excel("./cleaned_data/REE_sankey_links.xlsx", col_names = T)

# Left join and convert units to mass
REE_sankey_links <- 
  left_join(REE_sankey_links, REE_units, by = c('year','product')) %>%
  mutate(value = Value*value) %>%
  select(-Value)

write_xlsx(REE_sankey_links, 
           "./cleaned_data/REE_sankey_links_units.xlsx")  

BoM_recent <- read_excel(
  "./cleaned_data/BoM_data_average_int2.xlsx")

# Convert data to sankey format
Babbit_sankey_input <- BoM_recent %>%
  mutate(source = material) %>%
  rename(target = component)

Babbit_sankey_input <- Babbit_sankey_input[, c("product", 
                                               "source",
                                               "target",
                                               "material",
                                               "value")]

write_xlsx(Babbit_sankey_input, 
           "./raw_data/Babbit_sankey_input.xlsx")

Babbit_sankey_input2 <- Babbit_sankey_input %>% 
  mutate(source = target,
         target = product)

Babbit_sankey_input2 <- Babbit_sankey_input2[, c("product", 
                                                 "source",
                                                 "target",
                                                 "material",
                                                 "value")]

write_xlsx(Babbit_sankey_input2, 
           "./raw_data/Babbit_sankey_input2.xlsx")

Electronics_BoM_sankey_Babbitt2 <- rbindlist(
  list(
    Babbit_sankey_input,
    Babbit_sankey_input2),
  use.names = TRUE)

stacked_units <- electronics_stacked_area_chart %>%
  filter(variable == "inflow") %>%
  rename(product = unu_description)

Babbitt_joined <- right_join(Electronics_BoM_sankey_Babbitt2, stacked_units,
                             by = c("product")) %>%
  mutate(value = (value.x * value.y)/1000000) %>%
  select(-c(value.x,
            variable,
            value.y)) %>%
  filter(value >0) %>%
  mutate(across(c('value'), round, 2))

Babbitt_joined <- Babbitt_joined[, c("year",
                                     "product",
                                     "source",
                                     "target",
                                     "material",
                                     "value")]

write_xlsx(Babbitt_joined, 
           "./cleaned_data/electronics_sankey_links.xlsx")