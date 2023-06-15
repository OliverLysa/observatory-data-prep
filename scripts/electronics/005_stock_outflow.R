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

# *******************************************************************************
# Data extraction
# *******************************************************************************

# Import lifespan data
lifespan_data <- read_excel(
  "./cleaned_data/electronics_lifespan.xlsx",
  sheet = 1,
  range = "A2:AY75")

# Rename columns and clean names
lifespan_data_filtered <- lifespan_data[c(1:54), c(1,7,8)] %>%
  rename(unu_key = 1,
         shape = 2,
         scale = 3) %>%
  na.omit() 

# Calculate mean and median from Weibull parameters
weibullparinv(1.6, 8.1599999951404, loc = 0)

# Import inflow data
inflow_unu_mass_units <- 
  read_xlsx("./cleaned_data/inflow_unu_mass_units.xlsx")

# Merge inflow and lifespan data by unu_key
inflow_weibull <- merge(inflow_unu_mass_units, lifespan_data_filtered,  by=c("unu_key"),  
                        all.x = TRUE)

# Create empty columns for all years in range of interest
year_first <- min(as.integer(inflow_weibull$year))
year_last <- max(as.integer(inflow_weibull$year)) + 30

years <- c(year_first:year_last)
empty <- as.data.frame(matrix(NA, ncol = length(years), nrow = nrow(inflow_weibull)))
colnames(empty) <- years

# Add them to inflow weibull dataframe
inflow_weibull <- cbind(inflow_weibull, empty)
rm(empty)

# Calculate WEEE from inflow year 
for (i in year_first:year_last){
  inflow_weibull$WEEE_POM_dif <- i - ( as.integer(inflow_weibull[, "year"]) )
  wb <- dweibull(inflow_weibull[(inflow_weibull$WEEE_POM_dif >= 0),"WEEE_POM_dif"] + 0.5,
                 shape = inflow_weibull[(inflow_weibull$WEEE_POM_dif >= 0), "shape"],
                 scale = inflow_weibull[(inflow_weibull$WEEE_POM_dif >= 0), "scale"],
                 log = FALSE)
  weee <-  wb * inflow_weibull[(inflow_weibull$WEEE_POM_dif >= 0), "value"]
  inflow_weibull[(inflow_weibull$WEEE_POM_dif >= 0), as.character(i)] <- weee
}  

### Stock data: Electrical products data tables (represent an underestimate)

# https://onlinelibrary.wiley.com/doi/abs/10.1111/jiec.12551
# https://www.sciencedirect.com/science/article/abs/pii/S0959652618339660

