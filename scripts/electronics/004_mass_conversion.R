##### **********************
# Author: Oliver Lysaght
# Purpose:

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
              "janitor",
              "devtools",
              "roxygen2",
              "testthat",
              "knitr",
              "reshape2")

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
# Extract BoM data from Babbitt 2019 - to get material formulation and component stages
# *******************************************************************************

# Download data file from the url
download.file(
  "https://figshare.com/ndownloader/files/22858376",
  "./raw_data/Product_BOM_Babbit.xlsx"
)

# Read all sheets for bill of materials
BoM_sheet_names_Babbit <- readxl::excel_sheets(
  "./raw_data/Product_BOM_Babbit.xlsx")

# Import data mapped to sheet name 
BoM_data_Babbit <- purrr::map_df(BoM_sheet_names_Babbit, 
                          ~dplyr::mutate(readxl::read_excel(
                            "./raw_data/Product_BOM_Babbit.xlsx", 
                            sheet = .x), 
                            sheetname = .x))

# Convert the list of dataframes to a single dataframe, rename columns and filter
BoM_data_bound_Babbit <- BoM_data_Babbit %>%
  drop_na(2) %>%
  tidyr::fill(1) %>%
  select(-c(`Data From literature`,
            `Data from literature`,
            18)) %>%
  row_to_names(row_number = 1, 
               remove_rows_above = TRUE) %>%
  filter(`Product name` != "Product name") %>%
  dplyr::rename(model = `Product name`,
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
  mutate(year = gsub("\\)","", year)) %>%
  mutate_at(c('product'), trimws)

# Create filter of products for which we have data
BoM_filter_list_Babbit <- c("CRT Monitors",
                     "Video & DVD",
                     "CRT TVs",
                     "Desktop PCs",
                     "Small Household Items",
                     "Laptops",
                     "Flat Screen Monitors",
                     "Flat Screen TVs",
                     "Portable Audio",
                     "Printers",
                     "Mobile Phones",
                     "Household Monitoring",
                     "Toys",
                     "Digital camera",
                     "Gaming console",
                     "Cameras")

# TO REDO as external lookup table
# Rename products to match the UNU colloquial classification, group by product, component and material to average across models and years, then filter to products for which data is held
BoM_data_UNU_Babbit <- BoM_data_bound_Babbit %>%
  mutate(
    product = gsub("Blu-ray player", 'Video & DVD', product),
    product = gsub("CRT monitor", 'CRT Monitors', product),
    product = gsub("CRT TV", 'CRT TVs', product),
    product = gsub("Traditional desktop", 'Desktop PCs', product),
    product = gsub("Fitness tracker", 'Small Household Items', product),
    product = gsub("Laptop", 'Laptops', product),
    product = gsub("LCD monitor", 'Flat Screen Monitors', product),
    product = gsub("LCD TV", 'Flat Screen TVs', product),
    product = gsub("MP3 player", 'Portable Audio', product),
    product = gsub("Printer", 'Printers', product),
    product = gsub("Smartphone", 'Mobile Phones', product),
    product = gsub("Smart & non-smart thermostat", 'Household Monitoring', product),
    product = gsub("MP3 Player", 'Portable Audio', product),
    product = gsub("Drone", 'Toys', product),
    product = gsub("Digital camera", 'Cameras', product),
  ) %>%
  # filter to products of interest
  filter(product %in% BoM_filter_list_Babbit) %>%
  # simplify compositional breakdown
  mutate(across(everything(), ~ replace(., . == "Case", "Body"))) %>%
    mutate(across(everything(), ~ replace(., . == "Casing", "Body"))) %>%
    mutate(across(everything(), ~ replace(., . == "Main body", "Body"))) %>%
    mutate(across(everything(), ~ replace(., . == "Main assembly", "Body"))) %>%
    mutate(across(everything(), ~ replace(., . == "Access panel assembly", "Body"))) %>%
    mutate(across(everything(), ~ replace(., . == "Frame", "Body"))) %>%
    mutate(across(everything(), ~ replace(., . == "Case assembly", "Body"))) %>%
    mutate(across(everything(), ~ replace(., . == "Chasis bottom", "Body"))) %>%
    mutate(across(everything(), ~ replace(., . == "Chasis", "Body"))) %>%
    mutate(across(everything(), ~ replace(., . == "Cabinet", "Body"))) %>%
    mutate(across(everything(), ~ replace(., . == "Chasis top", "Body"))) %>%
    mutate(across(everything(), ~ replace(., . == "Inner frame", "Body"))) %>%
    mutate(across(everything(), ~ replace(., . == "Outer frame", "Body"))) %>%
    mutate(across(everything(), ~ replace(., . == "Drone (main body + camera)", "Body"))) %>%
    mutate(across(everything(), ~ replace(., . == "Other components*", "Other components"))) %>%
    mutate(across(everything(), ~ replace(., . == "ICs", "Induction coils"))) %>%
    mutate(across(everything(), ~ replace(., . == "Inductor coils", "Induction coils"))) %>%
    mutate(across(everything(), ~ replace(., . == "monitor cable", "Body"))) %>%
    mutate(across(everything(), ~ replace(., . == "3D Glasses", "Controls"))) %>%
    mutate(across(everything(), ~ replace(., . == "Remote control", "Controls"))) %>%
    mutate(across(everything(), ~ replace(., . == "Remote", "Controls"))) %>%
    mutate(across(everything(), ~ replace(., . == "Fitness tracker body", "Body"))) %>%
    mutate(across(everything(), ~ replace(., . == "Buckle", "Body"))) %>%
    mutate(across(everything(), ~ replace(., . == "Band", "Body"))) %>%
    mutate(across(everything(), ~ replace(., . == "Hard drive", "Drives"))) %>%
    mutate(across(everything(), ~ replace(., . == "Optical drive", "Drives"))) %>%
    mutate(across(everything(), ~ replace(., . == "Cradle", "Body"))) %>%
    mutate(across(everything(), ~ replace(., . == "Power Supply", "Cable"))) %>%
    mutate(across(everything(), ~ replace(., . == "Disk drive", "Drives"))) %>%
    mutate(across(everything(), ~ replace(., . == "Brackets", "Body"))) %>%
    mutate(across(everything(), ~ replace(., . == "Socket", "Cable"))) %>%
    mutate(across(everything(), ~ replace(., . == "Power supply unit", "Power"))) %>%
    mutate(across(everything(), ~ replace(., . == "Interior modules", "Drives"))) %>%
    mutate(across(everything(), ~ replace(., . == "Fan", "Fan and heat sink"))) %>%
    mutate(across(everything(), ~ replace(., . == "Heat sink", "Fan and heat sink"))) %>%
    mutate_at(c('value', 'year'), as.numeric)

# Done separate due to issue with special character
BoM_data_UNU_Babbit$product <- gsub("Laptops", "Laptops & Tablets",
                             BoM_data_UNU_Babbit$product)

# Write data file
write_xlsx(BoM_data_UNU_Babbit, 
           "./cleaned_data/BoM_data_UNU.xlsx")

# Return most recent model within each product group
BoM_data_UNU_Babbit_latest <- BoM_data_UNU_Babbit %>%
  # remove non-numeric entries in year column to then be able to select the latest
  mutate_at(c('year'), trimws) %>%
  mutate(year = gsub("[^0-9]", "", year)) %>%
  # convert year to numeric
  mutate_at(c('year'), as.numeric) %>%
  # replace any products missing year with 1990 so that they are not exluded by the top_n conversion
  replace_na(list(year = 1990)) %>%
  # get data for most recent product within each group
  group_by(product) %>%
  top_n(1, abs(year)) 

# convert product material composition into % terms (Converts Babbit into percentage format)
BoM_data_UNU_Babbit_latest_percentage <- BoM_data_UNU_Babbit_latest %>% 
  group_by(product, material) %>%
  summarise(sum(value)) %>%
  rename(value = 3) %>%
  mutate(freq = value / sum(value)) %>%
  select(-value) %>%
  mutate(
    material = gsub("Aluminum", 'Aluminium', material),
    material = gsub("PCB", 'Electronics incl. PCB', material),
    material = gsub("Steel", 'Ferrous', material),
    material = gsub("Other metals", 'Other metals', material),
    material = gsub("Flat panel glass", 'Flat panel glass', material),
    material = gsub("Other glass", 'Other glass', material)) %>%
  mutate_at(c('product'), trimws) 

# *******************************************************************************
# Extract BoM data from BEIS ICF Ecodesign report
# *******************************************************************************

BoM_BEIS_absolute <- 
  read_xlsx("./cleaned_data/BoM_manual.xlsx", sheet = 1)

# Add leading 0s to unu_key column up to 4 digits to help match to other data
BoM_BEIS_absolute$UNU <- str_pad(BoM_BEIS_absolute$UNU, 4, pad = "0")

# UNU codes to remove due to overlapping with Babbit (Babbit prioritised due to providing specific models)
remove <- c("0408", 
            "0309", 
            "0102",
            "0304")

# Pivot longer and filter
BoM_BEIS_absolute_long <- BoM_BEIS_absolute %>%
  select(-c(Make,
            Model,
            Year, 
            Source)) %>%
  filter(! UNU %in% remove) %>%
  pivot_longer(-c(
    UNU,
    Product,
    `Sub-type`,
    Component),
    names_to = "material", 
    values_to = "value") %>%
  drop_na(value)

# Exclude totals and convert to proportions
BoM_BEIS_percentage <- BoM_BEIS_absolute_long %>%
  filter(material != "Total") %>%
  group_by(UNU, material) %>%
  summarise(value = sum(value)) %>%
  mutate(freq = value / sum(value)) %>%
  select(-value) %>%
  dplyr::rename("unu_key" = 1)

# Replace UNU code with colloquial terms
BoM_BEIS_percentage <- left_join(BoM_BEIS_percentage, 
                              UNU_colloquial, 
                              by = c("unu_key")) %>%
  mutate(
    material = gsub("Electronics", 'Electronics incl. PCB', material),
    material = gsub("Aluminum", 'Aluminium', material)) %>%
  mutate_at(c('material'), trimws) 

# Drop unu_key column
BoM_BEIS_percentage <- BoM_BEIS_percentage[-1]

# Import BEIS and other preparatory study data already in percentage terms 
BoM_BEIS_proportions <- 
  read_xlsx("./cleaned_data/BoM_manual.xlsx", sheet = 2)

# Add leading 0s to unu_key column up to 4 digits to help match to other data
BoM_BEIS_proportions$UNU <- str_pad(BoM_BEIS_proportions$UNU, 4, pad = "0")

# Pivot longer and filter
BoM_BEIS_proportions_long <- BoM_BEIS_proportions %>%
  select(-c(Make,
            Model,
            Year,
            `Sub-type`,
            Component,
            Product,
            Source)) %>%
  filter(! UNU %in% remove) %>%
  pivot_longer(-c(
    UNU),
    names_to = "material", 
    values_to = "value") %>%
  drop_na(value) %>%
  rename('unu_key' = UNU,
         'freq' = value)

# Replace UNU code with colloquial terms
BoM_BEIS_proportions_long <- left_join(BoM_BEIS_proportions_long, 
                                 UNU_colloquial, 
                                 by = c("unu_key")) %>%
  select(-c(unu_key)) %>%
  mutate(
    material = gsub("Electronics", 'Electronics incl. PCB', material),
    material = gsub("Aluminum", 'Aluminium', material)) %>%
  mutate_at(c('material'), trimws) 

# Bind Babbit and BEIS sources
BoM_percentage_UNU <-
  rbindlist(
    list(
      BoM_BEIS_proportions_long,
      BoM_BEIS_percentage,
      BoM_data_UNU_Babbit_latest_percentage
    ),
    use.names = TRUE
  ) %>%
  mutate_at(c('material'), trimws)

BoM_percentage_UNU$material <-
  str_remove_all(BoM_percentage_UNU$material, "[^A-z|0-9|-|(|)|[:punct:]|\\s]")

BoM_percentage_UNU$material <- 
  gsub('[^[:alnum:] ]','',BoM_percentage_UNU$material)

BoM_percentage_UNU <- BoM_percentage_UNU %>%
  filter(freq != 0,
         material != "Total") %>%
  mutate(material = gsub("Other glass","Glass other", material),
         material = gsub("Flat panel glass","Flatpanelglass", material),
         material = gsub("Liion battery","Liionbattery", material))

BoM_percentage_UNU$material <-factor(BoM_percentage_UNU$material, levels=c('Others',
                                                                           'Glass other',
                                                                           'Flatpanelglass',
                                                                           'Plastic',
                                                                           'Liionbattery',
                                                                           'Electronics incl PCB',
                                                                           'Metals other',
                                                                           'Copper',
                                                                           'Aluminium',
                                                                           'Ferrous'))

# Stacked + percent
ggplot(na.omit(BoM_percentage_UNU), aes(fill=material, y=freq, x=product)) + 
  geom_bar(position="fill", stat="identity") +
  coord_flip() +
  scale_fill_viridis_d(direction = -1) +
  guides(fill = guide_legend(reverse = TRUE))

# *******************************************************************************
# Import mass data from https://github.com/Statistics-Netherlands/ewaste/blob/master/data/htbl_Key_Weight.csv
# to convert inflows in unit terms to mass terms 
# *******************************************************************************

# Import average mass data by UNU from WOT project
UNU_mass <- read_csv(
  "./cleaned_data/htbl_Key_Weight.csv") %>%
  clean_names() %>%
  group_by(unu_key, year) %>%
  summarise(value = mean(average_weight)) %>%
  rename(unu =1)

# Read in interpolated inflow data and filter to consumption of units to then multiply by mass
inflow_indicators <-
  read_xlsx("./cleaned_data/inflow_indicators.xlsx") %>%
  mutate_at(c('year'), as.numeric) %>%
  filter(indicator == "apparent_consumption") %>%
  na.omit() %>%
  mutate(variable = "inflow")

# Join by unu key and closest year
# For each value in inflow_indicators year column, find the closest value in UNU_mass that is less than or equal to that x value
by <- join_by(unu, closest(year >= year))
# Join
inflow_mass <- left_join(inflow_indicators, UNU_mass, by) %>%
  mutate_at(c("value.y"), as.numeric) %>%
  # calculate mass inflow in tonnes (as mass given in kg/unit in source)
  # https://i.unu.edu/media/ias.unu.edu-en/project/2238/E-waste-Guidelines_Partnership_2015.pdf
  mutate(mass_inflow = (value.x*value.y)/1000) %>%
  select(c(`unu`,
           `year.x`,
           mass_inflow)) %>%
  rename(year = 2,
         value = 3) %>%
  mutate(variable = "inflow") %>%
  mutate(unit = "mass")

# Write xlsx to the cleaned data folder
write_xlsx(inflow_mass, 
           "./cleaned_data/inflow_unu_mass.xlsx")

