# Gives the ability to retrieve bill of material or compositional data from multiple sources
# and reformat and restructure to the required format for inputting to the NICER dashbord 
# Most BoM data is structured in the following format: 
# Sankey data is structured as 

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
# Functions and options
# *******************************************************************************
# Import functions
source("./data_extraction_scripts/functions.R", 
       local = knitr::knit_global())

# Stop scientific notation of numeric values
options(scipen = 999)

#### Babbitt et al ####
# Use weighted averages to go from BoM to UNU based on inflow share data

# Download data file from the url
download.file(
  "https://figshare.com/ndownloader/files/22858376",
  "./raw_data/BoM/disassembly_detail.xlsx"
)

# Read all sheets for bill of materials
BoM_sheet_names <- readxl::excel_sheets(
  "./raw_data/BoM/disassembly_detail.xlsx")

BoM_data <- purrr::map_df(BoM_sheet_names, 
                          ~dplyr::mutate(readxl::read_excel(
                            "./raw_data/BoM/disassembly_detail.xlsx", 
                            sheet = .x), 
                            sheetname = .x))

# Convert the list of dataframes to a single dataframe, rename columns and filter (tidy format)
BoM_data_bound <- BoM_data %>%
  drop_na(2) %>%
  tidyr::fill(1) %>%
  select(-c(`Data From literature`,
            `Data from literature`,
            18)) %>%
  row_to_names(row_number = 1, 
               remove_rows_above = TRUE) %>%
  filter(`Product name` != "Product name") %>%
  rename(model = `Product name`,
         component = Component,
         product = 15) %>%
  pivot_longer(-c(
    model,
    component,
    product),
    names_to = "material", 
    values_to = "value") %>%
  drop_na(value) %>%
  filter(component != "Total mass (g)",
         material != "Total mass (g)",
         component != "-",
         component != "Mass %",
         model != "Product") %>%
  mutate_at(c('value'), as.numeric) %>%
  mutate(across(c('value'), round, 2)) %>%
  drop_na(value) %>%
  separate(model, c("model", "year"), "\\(") %>%
  mutate(year = gsub("\\)","", year))

# Write summary file
#write.csv(BoM_data_bound, 
# "./cleaned_data/bill_of_materials.csv")

Sankey_input <- BoM_data_bound %>% 
  mutate(source = material) %>%
  rename(target = component)

Sankey_input <- Sankey_input[, c("year", 
                                 "product", 
                                 "model",
                                 "source",
                                 "target",
                                 "material",
                                 "value")]

Sankey_input2 <- Sankey_input %>% 
  mutate(source = target,
         target = product)

Sankey_input2 <- Sankey_input2[, c("year", 
                                   "product", 
                                   "model",
                                   "source",
                                   "target",
                                   "material",
                                   "value")]

Electronics_BoM_sankey_Babbitt <- rbindlist(
  list(
    Sankey_input,
    Sankey_input2),
  use.names = TRUE)

# Write summary file
write_xlsx(Electronics_BoM_sankey_Babbitt, 
           "./cleaned_data/Electronics_BoM_sankey_Babbitt.xlsx")

#### Extract REE-relevant BoM data ####

# We need tidy data to input into required sankey format 
# mutate year and 
