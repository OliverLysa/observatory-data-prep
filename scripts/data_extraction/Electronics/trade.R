
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


# devtools::install_github("pvdmeulen/uktrade")

# *******************************************************************************
# Data extraction and tidying
# *******************************************************************************
#

#### Extract trade data ####

# Isolate list of CN8 codes from classification table
trade_terms <- 
  UNU_2_CN8_2_PRODCOM$CN8 # delete the following for whole dataframe [283:344] %>%
unlist()

# Create a for loop that goes through the trade terms, extracts the data using the extractor function based on the uktrade wrapper
# and prints the results to a list of dataframes
res <- list()
for (i in seq_along(trade_terms)) {
  res[[i]] <- extractor(trade_terms[i])
  
  print(i)
  
}

# Convert the list of dataframes to a single dataframe
bind <- 
  dplyr::bind_rows(res)

# Remove the month identifier in the month ID column to be able to group by year
bind$MonthId <- 
  substr(bind$MonthId, 1, 4)

# Outlier detection and replacement

# Summarise results grouped by year, flow type and code
Summary_trade <- bind %>%
  # Group by month
  group_by(MonthId, 
           FlowTypeDescription, 
           Cn8Code) %>%
  summarise(sum(Value), 
            sum(NetMass), 
            sum(SuppUnit)) %>%
  rename(Year = MonthId) %>%
  # Pivot results longer
  pivot_longer(-c(Year, 
                  FlowTypeDescription, 
                  Cn8Code),
               names_to = "Variable",
               values_to = 'Value')

# Write csv file
# write.csv(Summary_trade_UNU, 
#          "./1. Extract/5. Cleaned_datafiles/Summary_trade_UNU.csv")