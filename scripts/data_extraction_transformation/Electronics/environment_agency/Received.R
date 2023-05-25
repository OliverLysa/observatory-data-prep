##### **********************
# Waste Electronics Received Data Download (EA Dataset)

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

options(scipen=999)

# *******************************************************************************
# Download and data preparation
#********************************************************************************

# WEEE received AATF

# Apply download.file function in R
download.file("https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/913177/WEEE_received_at_an_approved_authorised_treatment_facility.ods",
              "./Publication/Input/WPP_Sectors/WEEE/EA/raw/WEEE_received_AATF.ods")

# 2020
EEE20 <-
  read_ods("./raw/WEEE_received_AATF.ods", sheet = "2020_Quarter_1-4") %>% 
  as.data.frame()

HEEE2020 <- EEE20[c(175:190), c(2:5)] %>%
  row_to_names(row_number = 1) %>% 
  mutate(Year = 2020, Source = "Household")

NHEEE2020 <- EEE20[c(194:209), c(2:5)] %>% 
  row_to_names(row_number = 1) %>% 
  clean_names() %>% 
  mutate(Year = 2020, Source = "Non_Household")

# 2019
EEE19 <-
  read_ods("./raw/WEEE_received_AATF.ods", sheet = "2019_Quarters_1-4") %>% 
  as.data.frame()

HEEE2019 <- EEE19[c(175:190), c(2:5)] %>%
  row_to_names(row_number = 1) %>% 
  mutate(Year = 2019, Source = "Household")

NHEEE2019 <- EEE19[c(194:209), c(2:5)] %>% 
  row_to_names(row_number = 1) %>% 
  clean_names() %>% 
  mutate(Year = 2019, Source = "Non_Household")

# 2018
EEE18 <-
  read_ods("./raw/WEEE_received_AATF.ods", sheet = "2018_Quarters_1-4") %>% 
  as.data.frame()

HEEE2018 <- EEE18[c(175:190), c(2:5)] %>%
  row_to_names(row_number = 1) %>% 
  mutate(Year = 2018, Source = "Household")

NHEEE2018 <- EEE18[c(194:209), c(2:5)] %>% 
  row_to_names(row_number = 1) %>% 
  clean_names() %>% mutate(Year = 2018, Source = "Non_Household")

# 2017
EEE17 <-
  read_ods("./raw/WEEE_received_AATF.ods", sheet = "2017_Quarters_1-4") %>% 
  as.data.frame()

HEEE2017 <- EEE17[c(175:190), c(2:5)] %>%
  row_to_names(row_number = 1) %>% 
  mutate(Year = 2017, Source = "Household")

NHEEE2017 <- EEE17[c(194:209), c(2:5)] %>% 
  row_to_names(row_number = 1) %>% 
  clean_names() %>% 
  mutate(Year = 2017, Source = "Non_Household")

# 2016
EEE16 <-
  read_ods("./raw/WEEE_received_AATF.ods", sheet = "2016_Quarters_1-4") %>% 
  as.data.frame()

HEEE2016 <- EEE16[c(175:190), c(2:5)] %>%
  row_to_names(row_number = 1) %>% 
  mutate(Year = 2016, Source = "Household")

NHEEE2016 <- EEE16[c(194:209), c(2:5)] %>% 
  row_to_names(row_number = 1) %>% 
  clean_names() %>% 
  mutate(Year = 2016, Source = "Non_Household")

# 2015
EEE15 <-
  read_ods("./raw/WEEE_received_AATF.ods", sheet = "2015_Quarters_1-4") %>% 
  as.data.frame()

HEEE2015 <- EEE15[c(175:190), c(2:5)] %>%
  row_to_names(row_number = 1) %>% 
  mutate(Year = 2015, Source = "Household")

NHEEE2015 <- EEE15[c(194:209), c(2:5)] %>% 
  row_to_names(row_number = 1) %>% 
  clean_names() %>% 
  mutate(Year = 2015, Source = "Non_Household")

# 2014
EEE14 <-
  read_ods("./raw/WEEE_received_AATF.ods", sheet = "2014_Quarters_1_-_4") %>% 
  as.data.frame()

HEEE2014 <- EEE14[c(175:190), c(2:5)] %>%
  row_to_names(row_number = 1) %>% 
  mutate(Year = 2014, Source = "Household")

NHEEE2014 <- EEE14[c(194:209), c(2:5)] %>% 
  row_to_names(row_number = 1) %>% 
  clean_names() %>% 
  mutate(Year = 2014, Source = "Non_Household")

# 2013
EEE13 <-
  read_ods("./raw/WEEE_received_AATF.ods", sheet = "2013_Quarters_1_-_4") %>% 
  as.data.frame()

HEEE2013 <- EEE13[c(167:181), c(2:5)] %>%
  row_to_names(row_number = 1) %>% 
  mutate(Year = 2013, Source = "Household")

NHEEE2013 <- EEE13[c(185:199), c(2:5)] %>% 
  row_to_names(row_number = 1) %>% 
  clean_names() %>% 
  mutate(Year = 2013, Source = "Non_Household")

# 2012
EEE12 <-
  read_ods("./raw/WEEE_received_AATF.ods", sheet = "2012_Quarters_1_-_4") %>% 
  as.data.frame()

HEEE2012 <- EEE12[c(167:181), c(2:5)] %>%
  row_to_names(row_number = 1) %>% 
  mutate(Year = 2012, Source = "Household")

NHEEE2012 <- EEE12[c(185:199), c(2:5)] %>% 
  row_to_names(row_number = 1) %>% 
  clean_names() %>% 
  mutate(Year = 2012, Source = "Non_Household")

# 2011
EEE11 <-
  read_ods("./raw/WEEE_received_AATF.ods", sheet = "2011_Quarters_1_-_4") %>% 
  as.data.frame()

HEEE2011 <- EEE11[c(167:181), c(2:5)] %>%
  row_to_names(row_number = 1) %>% 
  mutate(Year = 2011, Source = "Household")

NHEEE2011 <- EEE11[c(185:199), c(2:5)] %>% 
  row_to_names(row_number = 1) %>% clean_names() %>% 
  mutate(Year = 2011, Source = "Non_Household")

# 2010
EEE10 <-
  read_ods("./raw/WEEE_received_AATF.ods", sheet = "2010_Quarters_1_-_4") %>% 
  as.data.frame()

HEEE2010 <- EEE10[c(167:181), c(2:5)] %>%
  row_to_names(row_number = 1) %>% 
  mutate(Year = 2010, Source = "Household")

NHEEE2010 <- EEE10[c(185:199), c(2:5)] %>% 
  row_to_names(row_number = 1) %>% 
  clean_names() %>% 
  mutate(Year = 2010, Source = "Non_Household")

# 2009
EEE09 <-
  read_ods("./raw/WEEE_received_AATF.ods", sheet = "2009_Quarters_1_-_4") %>% 
  as.data.frame()

HEEE2009 <- EEE09[c(167:181), c(2:10)] %>%
  row_to_names(row_number = 1) %>% 
  mutate(Year = 2009, Source = "Household")

NHEEE2009 <- EEE09[c(185:199), c(2:10)] %>% 
  row_to_names(row_number = 1) %>% 
  clean_names() %>% 
  mutate(Year = 2009, Source = "Non_Household")

# 2008
EEE08 <-
  read_ods("./raw/WEEE_received_AATF.ods", sheet = "2008_Quarters_1_-_4") %>% 
  as.data.frame()

HEEE2008 <- EEE08[c(167:181), c(2:10)] %>%
  row_to_names(row_number = 1) %>% 
  mutate(Year = 2008, Source = "Household")

NHEEE2008 <- EEE08[c(186:200), c(2:10)] %>% 
  row_to_names(row_number = 1) %>% 
  clean_names() %>% 
  mutate(Year = 2008, Source = "Non_Household")

receivedAATF <-
  rbindlist(
    list(
      HEEE2020,
      HEEE2019,
      HEEE2018,
      HEEE2017,
      HEEE2016,
      HEEE2015,
      HEEE2014,
      HEEE2013,
      HEEE2012,
      HEEE2011,
      HEEE2010,
      NHEEE2020,
      NHEEE2019,
      NHEEE2018,
      NHEEE2017,
      NHEEE2016,
      NHEEE2015,
      NHEEE2014,
      NHEEE2013,
      NHEEE2012,
      NHEEE2011,
      NHEEE2010
    ),
    use.names = FALSE)

receivedAATFearly <-
  rbindlist(
    list(
      HEEE2009,
      HEEE2008,
      NHEEE2009,
      NHEEE2008
    ),
    use.names = FALSE)

receivedlong <- receivedAATF %>%
  pivot_longer(-c(Category, Year, Source),
               names_to = "Stream",
               values_to = "Value")

receivedlongearly <- receivedAATFearly %>%
  pivot_longer(-c(Category, Year, Source),
               names_to = "Stream",
               values_to = "Value")

receivedtotal <-
  rbindlist(
    list(
      receivedlong,
      receivedlongearly
    ),
    use.names = FALSE)

colnames(receivedtotal)[3]  <- "Stream"
colnames(receivedtotal)[4]  <- "Treatment"

receivedtotal <- receivedtotal %>% 
  mutate(Received_Type = "AATF")

# *******************************************************************************
# WEEE received non-obligated
#********************************************************************************

# Apply download.file function in R
download.file("https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/913182/Non-obligated_WEEE_received_at_approved_authorised_treatment_facilities_and_approved_exporters.ods",
              "./Publication/Input/WPP_Sectors/WEEE/EA/raw/non_obligated_received.ods")

# 2020
EEE20 <-
  read_ods("non_obligated_received.ods", sheet = 1) %>% as.data.frame()

EEE2020 <- EEE20[c(87:102), c(2:3)] %>%
  row_to_names(row_number = 1) %>% mutate(Year = 2020)

# 2019
EEE19 <-
  read_ods("non_obligated_received.ods", sheet = 2) %>% as.data.frame()

EEE2019 <- EEE19[c(87:102), c(2:3)] %>%
  row_to_names(row_number = 1) %>% mutate(Year = 2019)

# 2018
EEE18 <-
  read_ods("non_obligated_received.ods", sheet = 3) %>% as.data.frame()

EEE2018 <- EEE18[c(87:102), c(2,5)] %>%
  row_to_names(row_number = 1) %>% mutate(Year = 2018)

# 2017
EEE17 <-
  read_ods("non_obligated_received.ods", sheet = 4) %>% as.data.frame()

EEE2017 <- EEE17[c(88:103), c(2,5)] %>%
  row_to_names(row_number = 1) %>% mutate(Year = 2017)

# 2016
EEE16 <-
  read_ods("non_obligated_received.ods", sheet = 5) %>% as.data.frame()

EEE2016 <- EEE16[c(87:102), c(2,5)] %>%
  row_to_names(row_number = 1) %>% mutate(Year = 2016)

# 2015
EEE15 <-
  read_ods("non_obligated_received.ods", sheet = 6) %>% as.data.frame()

EEE2015 <- EEE15[c(87:102), c(2,5)] %>%
  row_to_names(row_number = 1) %>% mutate(Year = 2015)

# 2014
EEE14 <-
  read_ods("non_obligated_received.ods", sheet = 7) %>% as.data.frame()

EEE2014 <- EEE14[c(87:102), c(2,5)] %>%
  row_to_names(row_number = 1) %>% mutate(Year = 2014)

# 2013
EEE13 <-
  read_ods("non_obligated_received.ods", sheet = 8) %>% as.data.frame()

EEE2013 <- EEE13[c(83:97), c(2:3)] %>%
  row_to_names(row_number = 1) %>% mutate(Year = 2013)

# 2012
EEE12 <-
  read_ods("non_obligated_received.ods", sheet = 9) %>% as.data.frame()

EEE2012 <- EEE12[c(83:97), c(2:3)] %>%
  row_to_names(row_number = 1) %>% mutate(Year = 2012)

# 2011
EEE11 <-
  read_ods("non_obligated_received.ods", sheet = 10) %>% as.data.frame()

EEE2011 <- EEE11[c(83:97), c(2:3)] %>%
  row_to_names(row_number = 1) %>% mutate(Year = 2011)

# 2010
EEE10 <-
  read_ods("non_obligated_received.ods", sheet = 11) %>% as.data.frame()

EEE2010 <- EEE10[c(7:21), c(2:3)] %>%
  row_to_names(row_number = 1) %>% mutate(Year = 2010)

receivednonob <-
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
      EEE2010
    ),
    use.names = FALSE)

colnames(receivednonob)[2]  <- "Value"

receivednonob <- receivednonob %>% 
  mutate(Received_Type = "Non_Obligated") %>% 
  mutate(Stream = "Unspecified") %>% 
  mutate(Treatment = "Unspecified")

# *******************************************************************************
# WEEE received export
#********************************************************************************

# Specify URL where file is stored
url <- "https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/913180/WEEE_received_by_approved_exporters.ods"

# Specify destination where file should be saved
destfile <- "/Users/oliverlysaght/Desktop/R/WPP/WEEE/EA/WEEE_received_export.ods"

# Apply download.file function in R
download.file(url, destfile)

#Bind received datasets
receivedall <- rbind(receivedtotal, 
                     receivednonob)

receivedall$Value <-
  as.numeric(receivedall$Value)

write_xlsx(receivedall, "Received_all.xlsx")  

