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
# Functions and options
# *******************************************************************************

# Import functions
source("./scripts/functions.R", 
       local = knitr::knit_global())

# Stop scientific notation of numeric values
options(scipen = 999)

# *******************************************************************************
# REE

# Get lifespan data (constant within each scenario)
REE_lifespan_assumptions <- read_xlsx("./intermediate_data/REE_lifespan_assumptions.xlsx") 

# Calculate 'ce_score'

# Import sankey data to get outflow route by year 
outflow_routing <- read_csv("./cleaned_data/REE_sankey_links.csv") %>%
  filter(source == "Collect") %>%
  select(-c(material, source)) %>%
  pivot_wider(names_from = target, 
              values_from = value) %>%
  mutate(Total = select(., Resale:Disposal) %>% 
           rowSums(na.rm = TRUE)) %>%
  pivot_longer(-c(scenario,
                  year,
                  product,
                  Total),
               names_to = "route",
               values_to = "value") %>% 
  mutate(value = round(value / Total *100, 2)) %>%
  mutate(value = gsub("NaN", "0", value))

# Multiply percentages by ordinal score
outflow_routing_weights <- read_excel(
  "./intermediate_data/weights.xlsx")

# Merge outflow routing with outflow routing weights
outflow_routing_weighted <- merge(outflow_routing,
                                  outflow_routing_weights,
                                  by.x=c("route"),
                                  by.y=c("route")) %>%
  mutate(route_score = value*score) %>%
  group_by(`unu_key`, year) %>%
  summarise(ce_score = sum(route_score))

# Import consumption/inflow data
consumption <- read_csv("./cleaned_data/REE_chart_stacked_area.csv") %>%
  filter(variable == "Inflow") %>%
  mutate(across(c('mass'), round, 1))

# Merge datasets across the variables listed, clean table for supabase
REE_chart_bubble <- merge(consumption, REE_chart_bubble,
                   by = c("product", "scenario", "year")) %>%
  select(-c(aggregation, variable, mass, unit)) %>%
  rename("mass" = value)

# Write file
write_csv(REE_chart_bubble,
          "./cleaned_data/REE_chart_bubble.csv")
