##### **********************
# Waste Electronics On the Market Data Download (EA Dataset)

# *******************************************************************************
# Require packages
#********************************************************************************

require(magrittr)
require(writexl)
require(dplyr)
require(tidyverse)
require(readODS)
require(janitor)
require(data.table)
require(xlsx)

# *******************************************************************************
# Download and data preparation
#********************************************************************************

# Specify URL where file is stored
url <-
  "http://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/913181/Electrical_and_electronic_equipment_placed_on_market.ods"

# Specify destination where file should be saved
destfile <-
  "/Users/oliverlysaght/Desktop/R/MP/Publication/Input/WPP_Sectors/WEEE/EA/raw/EEE_on_the_market.ods"

# Apply download.file function in R
download.file(url, destfile)

# 2020
EEE20 <-
  read_ods("./raw/EEE_on_the_market.ods", sheet = "2020_Quarters_1_-_4") %>%
  as.data.frame()

EEE2020 <- EEE20[92:107, 2:4] %>%
  row_to_names(row_number = 1) %>%
  mutate(Year = 2020)

# 2019
EEE19 <-
  read_ods("./raw/EEE_on_the_market.ods", sheet = "2019_Quarters_1_-_4") %>% 
  as.data.frame()

EEE2019 <- EEE19[92:107, 2:4] %>%
  row_to_names(row_number = 1) %>% 
  mutate(Year = 2019)

# 2018
EEE18 <-
  read_ods("./raw/EEE_on_the_market.ods", sheet = "2018_Quarters_1_-_4") %>% 
  as.data.frame()

EEE2018 <- EEE18[92:107, 2:4] %>%
  row_to_names(row_number = 1) %>% 
  mutate(Year = 2018)

# 2017
EEE17 <-
  read_ods("./raw/EEE_on_the_market.ods", sheet = "2017_Quarters_1_-_4") %>% 
  as.data.frame()

EEE2017 <- EEE17[92:107, 2:4] %>%
  row_to_names(row_number = 1) %>% 
  mutate(Year = 2017)

# 2016
EEE16 <-
  read_ods("./raw/EEE_on_the_market.ods", sheet = "2016_Quarters_1_-_4") %>% 
  as.data.frame()

EEE2016 <- EEE16[92:107, 2:4] %>%
  row_to_names(row_number = 1) %>% 
  mutate(Year = 2016)

# 2015
EEE15 <-
  read_ods("./raw/EEE_on_the_market.ods", sheet = "2015_Quarters_1_-_4") %>% 
  as.data.frame()

EEE2015 <- EEE15[92:107, 2:4] %>%
  row_to_names(row_number = 1) %>% 
  mutate(Year = 2015)

# 2014
EEE14 <-
  read_ods("./raw/EEE_on_the_market.ods", sheet = "2014_Quarters_1-4") %>% 
  as.data.frame()

EEE2014 <- EEE14[92:107, 2:4] %>%
  row_to_names(row_number = 1) %>% 
  mutate(Year = 2014)

# 2013
EEE13 <-
  read_ods("./raw/EEE_on_the_market.ods", sheet = "2013_Quarters_1_-_4") %>% 
  as.data.frame()

EEE2013 <- EEE13[88:102, 2:4] %>%
  row_to_names(row_number = 1) %>% 
  mutate(Year = 2013)

# 2012
EEE12 <-
  read_ods("./raw/EEE_on_the_market.ods", sheet = "2012_Quarters_1_-_4") %>% 
  as.data.frame()

EEE2012 <- EEE12[88:102, 2:4] %>%
  row_to_names(row_number = 1) %>% 
  mutate(Year = 2012)

# 2011
EEE11 <-
  read_ods("./raw/EEE_on_the_market.ods", sheet = "2011_Quarters_1_-_4") %>% 
  as.data.frame()

EEE2011 <- EEE11[88:102, 2:4] %>%
  row_to_names(row_number = 1) %>% 
  mutate(Year = 2011)

# 2010
EEE10 <-
  read_ods("./raw/EEE_on_the_market.ods", sheet = "2010_Quarters_1_-_4") %>% 
  as.data.frame()

EEE2010 <- EEE10[89:103, 2:4] %>%
  row_to_names(row_number = 1) %>% 
  mutate(Year = 2010)

# 2009
EEE09 <-
  read_ods("./raw/EEE_on_the_market.ods", sheet = "2009_Quarters_1_-_4") %>% 
  as.data.frame()

EEE2009 <- EEE09[89:103, 2:4] %>%
  row_to_names(row_number = 1) %>% 
  mutate(Year = 2009)

# 2008
EEE08 <-
  read_ods("./raw/EEE_on_the_market.ods", sheet = "2008_Quarters_1_-_4") %>% 
  as.data.frame()

EEE2008 <- EEE08[84:98, 2:4] %>%
  row_to_names(row_number = 1) %>% 
  mutate(Year = 2008)

EEEmarkettotal <-
  rbindlist(
    list(
      EEE2020,
      EEE2019,
      EEE2018,
      EEE2017,
      EEE2016,
      EEE2015,
      EEE2014,
      EEE2013,
      EEE2012,
      EEE2011,
      EEE2010,
      EEE2009,
      EEE2008
    ),
    use.names = FALSE
  )

colnames(EEEmarkettotal)[2]  <- "Household"
colnames(EEEmarkettotal)[3]  <- "Non_Household"

EEEmarkettotal$Household <-
  as.numeric(EEEmarkettotal$Household)

EEEmarkettotal$Non_Household <-
  as.numeric(EEEmarkettotal$Non_Household)

EEEmarkettotal <-
  EEEmarkettotal %>% mutate(Total = Household + Non_Household)

EAWEEElong <- EEEmarkettotal %>%
  pivot_longer(-c(Category, Year),
               names_to = "Stream",
               values_to = "Value") %>%
               mutate_if(is.numeric, round, digits=1) 

EAWEEElong <- as.data.frame(EAWEEElong)

write.xlsx(EAWEEElong, file = "WEEE_all.xlsx", sheetName="EEE_market", append=TRUE, row.names = FALSE)
