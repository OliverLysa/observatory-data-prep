##### **********************
# Date of last update: July 2022
# Purpose: Extract open repair data product lifespans

# *******************************************************************************
# Require packages
#********************************************************************************

#### Libraries ####
library(httr)
library(jsonlite)
require(writexl)
require(readODS)
require(readxl)
require(janitor)
require(xlsx)
library(tidyverse)
require(data.table)
library(rvest)
library(netstat)

rm(list = ls())
options(warn = -1)

#### Extract ####

# Read data
Openrepair <-
  read_csv("OpenRepairData_v0.3_aggregate_202110.csv", col_names = T)

# Filter to outcome of repair attempt is end of life and summarise average and median by product category
Openrepair_EOL <-
  Openrepair %>%
  filter(repair_status == "End of life",
         product_age != "NA") %>%
  group_by(product_category) %>% summarise(Average_EoL = mean(product_age),
                                           Median_EoL = median(product_age)) %>%
  mutate_if(is.numeric, round, digits = 1)

# Filter to outcome of repair attempt is repair and summarise average and median by product category
Openrepair_repaired <-
  Openrepair %>%
  filter(repair_status != "Unknown",
         repair_status != "End of life",
         product_age != "NA") %>%
  group_by(product_category) %>% summarise(Average_fix = mean(product_age),
                                           Median_fix = median(product_age)) %>%
  mutate_if(is.numeric, round, digits = 1)

# Merge the two prior datasets 
Product_age <-
  merge(Openrepair_EOL, Openrepair_repaired) %>%
  mutate(source = "Open_repair")


## UK only
Openrepair_EOL_UK <-
  Openrepair %>%
  filter(country == "GBR",
         repair_status != "End of life",
         product_age != "NA") %>%
  group_by(product_category) %>% summarise(Average_EoL = mean(product_age),
                                           Median_EoL = median(product_age)) %>%
  mutate_if(is.numeric, round, digits = 1)

Openrepair_repaired_UK <-
  Openrepair %>%
  filter(country == "GBR",
         repair_status != "Unknown",
         repair_status != "End of life",
         product_age != "NA") %>%
  group_by(product_category) %>% summarise(Average_fix = mean(product_age),
                                           Median_fix = median(product_age)) %>%
  mutate_if(is.numeric, round, digits = 1)

# Merge the two prior datasets 
Product_age_UK <-
  merge(Openrepair_EOL_UK, Openrepair_repaired_UK) %>%
  mutate(source = "Open_repair")

write.csv(Product_age,
          "Openrepair_lifespan.csv",
          row.names = FALSE)

write.csv(Product_age_UK,
          "Openrepair_lifespan_UK.csv",
          row.names = FALSE)

# Fitting distribution 

Openrepair_repaired <-
  Openrepair %>%
  filter(repair_status != "Unknown",
         repair_status != "End of life",
         product_age != "NA")


f<-fitdistr(x, 'weibull')
