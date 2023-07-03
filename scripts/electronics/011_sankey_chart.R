##### **********************
# Author: Oliver Lysaght
# Purpose: Converts cleaned data into sankey format
# Inputs:
# Required updates:

# https://cran.r-project.org/web/packages/PantaRhei/vignettes/panta-rhei.html
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
source("./data_extraction_scripts/functions.R", 
       local = knitr::knit_global())

# Stop scientific notation of numeric values
options(scipen = 999)

# *******************************************************************************
# Electronics

# Import BoM data
BoM_data_UNU <- read_excel(
  "./cleaned_data/BoM_data_UNU.xlsx") %>%
  mutate_at(c('year'), trimws)

# Remove non-numeric characters from the year column 
BoM_data_UNU$year <-gsub("[^0-9]", "", BoM_data_UNU$year)

# Remove rows where the year value is empty 
BoM_data_UNU <- BoM_data_UNU[-which(BoM_data_UNU$year == ""), ]

# Convert year column to numeric
BoM_data_UNU$year <- as.numeric(as.character(BoM_data_UNU$year))

# Get data for most recent product within each group
BoM_data_UNU_latest <- BoM_data_UNU %>% 
  group_by(product) %>%
  top_n(1, abs(year))

# Renames columns
Babbit_sankey_input <- BoM_data_UNU_latest %>%
  mutate(source = material) %>%
  rename(target = component)

# Reorders columns
Babbit_sankey_input <- Babbit_sankey_input[, c("product", 
                                               "source",
                                               "target",
                                               "material",
                                               "value")]

# Duplicates the first file and renames columns
Babbit_sankey_input2 <- Babbit_sankey_input %>% 
  mutate(source = target,
         target = product)

# Reorders columns 
Babbit_sankey_input2 <- Babbit_sankey_input2[, c("product", 
                                                 "source",
                                                 "target",
                                                 "material",
                                                 "value")]

# Binds the two files
Electronics_BoM_sankey_Babbitt <- rbindlist(
  list(
    Babbit_sankey_input,
    Babbit_sankey_input2),
  use.names = TRUE)

electronics_stacked_area_chart <- read_excel(
"./cleaned_data/electronics_stacked_area_chart.xlsx")

# Gets unit flows by year
stacked_units <- electronics_stacked_area_chart %>%
  filter(variable == "inflow") %>%
  rename(product = unu_description)

# Right joins the two files to multiply the BoM by flows to get flows in mass by year
Babbitt_joined <- right_join(Electronics_BoM_sankey_Babbitt, stacked_units,
                             by = c("product")) %>%
  mutate(value = (value.x * value.y)/1000000) %>%
  select(-c(value.x,
            variable,
            value.y)) %>%
  filter(value >0) %>%
  mutate(across(c('value'), round, 2))

# Reorders columns 
Babbitt_joined <- Babbitt_joined[, c("year",
                                     "product",
                                     "source",
                                     "target",
                                     "material",
                                     "value")]

# Write file 
write_xlsx(Babbitt_joined, 
           "./cleaned_data/electronics_sankey_links.xlsx")

# *******************************************************************************
# REE

# REE Data input
REE_sankey_links <- read_xlsx("./intermediate_data/sankey_scenarios.xlsx") %>%
  filter(value != 0,
         target != "Lost") %>%
  mutate(across(c('value'), round, 2))

write_csv(REE_sankey_links,
          "./cleaned_data/REE_sankey_links2.csv")
