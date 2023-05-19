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
              "janitor")

# Install packages not yet installed
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}

# Packages loading
invisible(lapply(packages, library, character.only = TRUE))

# *******************************************************************************
# Bubble chart data

# Map flows data to electronics bubble chart
electronics_bubble_flows <- flows_all %>%
  # filter to 2017, variable = Units, indicator = apparent_consumption
  filter(year == 2017,
         variable == 'Units',
         indicator == "apparent_consumption") %>%
  select(-c(year, 
            variable, 
            indicator)) %>%
  rename(apparent_consumption = value)

# Map lifespan data to electronics bubble chart
mean_lifespan <- lifespan_data %>%
  select(c(unu, mean)) %>%
  rename(mean_lifespan = mean)

electronics_bubble_chart <- merge(electronics_bubble_flows,
                                  mean_lifespan,
                                  by.x=c("unu_key"),
                                  by.y=c("unu")) %>%
  mutate(across(c('mean_lifespan'), round, 1))

electronics_bubble_chart2 <- merge(electronics_bubble_chart,
                                   electronics_bubble_outflow,
                                   by.x=c("unu_key"),
                                   by.y=c("UNU KEY")) %>%
  rename(ce_score = scaled) 

write_xlsx(electronics_bubble_chart2, 
           "./cleaned_data/electronics_bubble_chart.xlsx")

electronics_stacked_area_chart <- flows_all %>%
  # filter to 2017, variable = Units, indicator = apparent_consumption
  filter(variable == 'Units',
         indicator == "apparent_consumption") %>%
  select(-c(variable, 
            indicator)) %>%
  rename(apparent_consumption = value)

UNU <- electronics_bubble_chart2 %>%
  select(c(unu_key, `UNU DESCRIPTION`))

electronics_stacked_area_chart <- merge(electronics_stacked_area_chart,
                                        UNU,
                                        by=c("unu_key" = "unu_key")) %>%
  na.omit() 

write_xlsx(electronics_stacked_area_chart, 
           "./cleaned_data/electronics_stacked_area_chart.xlsx")