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
# Chart construction
# *******************************************************************************
#

# Get lifespan data (constant within each scenario and product group)
REE_lifespan_assumptions <- 
  read_xlsx("./intermediate_data/REE_lifespan_assumptions.xlsx") 

# Import sankey data to get outflow route by year to calculate ce-score
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
  mutate(percentage = round(value / Total, 2)) %>%
  mutate(percentage = gsub("NaN", "0", percentage)) %>%
  mutate_at(c('percentage'), as.numeric)

# Multiply percentages by ordinal score
outflow_routing_weights <- read_excel(
  "./intermediate_data/weights.xlsx")

# Merge outflow routing with outflow routing weights
outflow_routing_weighted <- merge(outflow_routing,
                                  outflow_routing_weights,
                                  by.x=c("route"),
                                  by.y=c("route")) %>%
  mutate(route_score = score*percentage) %>%
  group_by(scenario,product, year) %>%
  summarise(ce_score = sum(route_score))

# Import inflow data
consumption <- read_csv("./cleaned_data/REE_chart_stacked_area.csv") %>%
  filter(variable == "Inflow")

# Merge consumption and lifespan assumptions
REE_chart_bubble <- merge(consumption, REE_lifespan_assumptions,
                          by = c("product", "scenario"))

# Merge consumption and ce-score
REE_chart_bubble <- merge(REE_chart_bubble, 
                          outflow_routing_weighted,
                          by = c("product", 
                                 "scenario", 
                                 "year")) %>%
  select(-c(aggregation, variable, unit)) %>%
  rename(mass = value)

# Write file
write_csv(REE_chart_bubble,
          "./cleaned_data/REE_chart_bubble.csv")