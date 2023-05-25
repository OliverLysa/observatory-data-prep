##### **********************
# Waste Electronics Collected Data Download (EA Dataset)

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

download.file("https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/913175/WEEE_collected_in_the_UK.ods",
              "./Publication/Input/WPP_Sectors/WEEE/EA/raw/WEEE_collected.ods")

# 2020
EEE20 <-
  read_ods("./raw/WEEE_collected.ods", sheet = "2020_Quarter_1_-_4") %>% 
  as.data.frame()

HEEE2020 <-
  EEE20[c(87:102), c(2, 6)] %>%
  row_to_names(row_number = 1) %>% 
  mutate(Year = 2020, Source = "Household")

NHEEE2020 <-
  EEE20[c(114:129), c(2, 7)] %>%
  row_to_names(row_number = 1) %>% 
  clean_names() %>% 
  mutate(Year = 2020, Source = "Non_Household")

# 2019
EEE19 <-
  read_ods("./raw/WEEE_collected.ods", sheet = "2019_Quarter_1_-_4") %>% 
  as.data.frame()

HEEE2019 <-
  EEE19[c(87:102), c(2, 6)] %>%
  row_to_names(row_number = 1) %>% 
  mutate(Year = 2019, Source = "Household")

NHEEE2019 <-
  EEE19[c(114:129), c(2, 7)] %>%
  row_to_names(row_number = 1) %>% 
  clean_names() %>% 
  mutate(Year = 2019, Source = "Non_Household")

# 2018
EEE18 <-
  read_ods("./raw/WEEE_collected.ods", sheet = "2018_Quarter_1_-_4") %>% 
  as.data.frame()

HEEE2018 <- 
  EEE18[c(87:102), c(2, 6)] %>%
  row_to_names(row_number = 1) %>% 
  mutate(Year = 2018, Source = "Household")

NHEEE2018 <- 
  EEE18[c(114:129), c(2, 7)] %>%
  row_to_names(row_number = 1) %>% 
  clean_names() %>% 
  mutate(Year = 2018, Source = "Non_Household")

# 2017
EEE17 <-
  read_ods("./raw/WEEE_collected.ods", sheet = "2017_Quarter_1_-_4") %>% 
  as.data.frame()

HEEE2017 <- 
  EEE17[c(87:102), c(2, 6)] %>%
  row_to_names(row_number = 1) %>% 
  mutate(Year = 2017, Source = "Household")

NHEEE2017 <- 
  EEE17[c(114:129), c(2, 7)] %>%
  row_to_names(row_number = 1) %>% 
  clean_names() %>% 
  mutate(Year = 2017, Source = "Non_Household")

# 2016
EEE16 <-
  read_ods("./raw/WEEE_collected.ods", sheet = "2016_Quarter_1_-_4") %>% 
  as.data.frame()

HEEE2016 <- EEE16[c(87:102), c(2, 6)] %>%
  row_to_names(row_number = 1) %>% 
  mutate(Year = 2016, Source = "Household")

NHEEE2016 <- EEE16[c(114:129), c(2, 7)] %>%
  row_to_names(row_number = 1) %>% 
  clean_names() %>% 
  mutate(Year = 2016, Source = "Non_Household")

# 2015
EEE15 <-
  read_ods("./raw/WEEE_collected.ods", sheet = "2015_Quarter_1-4") %>% 
  as.data.frame()

HEEE2015 <- EEE15[c(88:103), c(2, 6)] %>%
  row_to_names(row_number = 1) %>% 
  mutate(Year = 2015, Source = "Household")

NHEEE2015 <- EEE15[c(115:130), c(2, 7)] %>%
  row_to_names(row_number = 1) %>% 
  clean_names() %>% 
  mutate(Year = 2015, Source = "Non_Household")

# 2014
EEE14 <-
  read_ods("./raw/WEEE_collected.ods", sheet = "2014_Quarter_1_-_4") %>% 
  as.data.frame()

HEEE2014 <- EEE14[c(88:103), c(2, 6)] %>%
  row_to_names(row_number = 1) %>% 
  mutate(Year = 2014, Source = "Household")

NHEEE2014 <- EEE14[c(115:130), c(2, 7)] %>%
  row_to_names(row_number = 1) %>% 
  clean_names() %>% 
  mutate(Year = 2014, Source = "Non_Household")

# 2013
EEE13 <-
  read_ods("./raw/WEEE_collected.ods", sheet = "2013_Quarter_1_-_4") %>%
  as.data.frame()

HEEE2013 <- EEE13[c(84:98), c(2, 6)] %>%
  row_to_names(row_number = 1) %>%
  mutate(Year = 2013, Source = "Household")

NHEEE2013 <- EEE13[c(110:124), c(2, 7)] %>%
  row_to_names(row_number = 1) %>%
  clean_names() %>%
  mutate(Year = 2013, Source = "Non_Household")

# 2012
EEE12 <-
  read_ods("./raw/WEEE_collected.ods", sheet = "2012_Quarter_1_-_4") %>% 
  as.data.frame()

HEEE2012 <- EEE12[c(83:97), c(2, 6)] %>%
  row_to_names(row_number = 1) %>% 
  mutate(Year = 2012, Source = "Household")

NHEEE2012 <- EEE12[c(109:123), c(2, 7)] %>%
  row_to_names(row_number = 1) %>% 
  clean_names() %>% 
  mutate(Year = 2012, Source = "Non_Household")

# 2011
EEE11 <-
  read_ods("./raw/WEEE_collected.ods", sheet = "2011_Quarter_1_-_4") %>% 
  as.data.frame()

HEEE2011 <- EEE11[c(84:98), c(2, 6)] %>%
  row_to_names(row_number = 1) %>% 
  mutate(Year = 2011, Source = "Household")

NHEEE2011 <- EEE11[c(110:124), c(2, 7)] %>%
  row_to_names(row_number = 1) %>% 
  clean_names() %>% 
  mutate(Year = 2011, Source = "Non_Household")

# 2010
EEE10 <-
  read_ods("./raw/WEEE_collected.ods", sheet = "2010_Quarter_1_-_4") %>% 
  as.data.frame()

HEEE2010 <- EEE10[c(84:98), c(2, 5)] %>%
  row_to_names(row_number = 1) %>% 
  mutate(Year = 2010, Source = "Household")

NHEEE2010 <- EEE10[c(108:122), c(2, 7)] %>%
  row_to_names(row_number = 1) %>% 
  clean_names() %>% 
  mutate(Year = 2010, Source = "Non_Household")

# 2009
EEE09 <-
  read_ods("./raw/WEEE_collected.ods", sheet = "2009_Quarters_1_-_4") %>% 
  as.data.frame()

HEEE2009 <- EEE09[c(87:101), c(2, 5)] %>%
  row_to_names(row_number = 1) %>% 
  mutate(Year = 2009, Source = "Household")

NHEEE2009 <- EEE09[c(111:125), c(2, 7)] %>%
  row_to_names(row_number = 1) %>% 
  clean_names() %>% 
  mutate(Year = 2009, Source = "Non_Household")

# 2008
EEE08 <-
  read_ods("./raw/WEEE_collected.ods", sheet = "2008_Quarters_1_-_4") %>% 
  as.data.frame()

HEEE2008 <- EEE08[c(83:97), c(2, 5)] %>%
  row_to_names(row_number = 1) %>% 
  mutate(Year = 2008, Source = "Household")

NHEEE2008 <- EEE08[c(107:121), c(2, 7)] %>%
  row_to_names(row_number = 1) %>% 
  clean_names() %>% 
  mutate(Year = 2008, Source = "Non_Household")

# Bind
EEEcollecttotal <-
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
      HEEE2009,
      HEEE2008,
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
      NHEEE2010,
      NHEEE2009,
      NHEEE2008
    ),
    use.names = FALSE
  )

colnames(EEEcollecttotal)[1]  <- "Category"
colnames(EEEcollecttotal)[2]  <- "Value"
colnames(EEEcollecttotal)[4]  <- "Stream"

EEEcollectwide <-
  pivot_wider(EEEcollecttotal,
              names_from = Stream,
              values_from = Value)

EEEcollectwide$Household <-
  as.numeric(EEEcollectwide$Household)

EEEcollectwide$Non_Household <-
  as.numeric(EEEcollectwide$Non_Household)

EEEcollecttot <-
  EEEcollectwide %>% mutate(Total = Household + Non_Household)

EEEEcollecttotlong <- EEEcollecttot %>%
  pivot_longer(-c(Category, Year),
               names_to = "Stream",
               values_to = "Value") %>%
               mutate_if(is.numeric, round, digits=1) 

EEEEcollecttotlong$Category <-
  gsub("Total", "Totals", EEEEcollecttotlong$Category)

EEEEcollecttotlong <- as.data.frame(EEEEcollecttotlong)

write.xlsx(EEEEcollecttotlong, file = "WEEE_all.xlsx", sheetName="WEEE_collected", row.names = FALSE)
