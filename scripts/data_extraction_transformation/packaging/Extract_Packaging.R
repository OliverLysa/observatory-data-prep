require(janitor)
require(data.table)
require(readxl)
require(writexl)
require(tidyverse)

q4_21 <- read_excel("./2021/22_03_31_Rpt_(2021_Q4_Recycling_Summary).xls", sheet = 1) %>% 
  as.data.frame()
q4_21 <- q4_21[c(6,8:16), c(3,8,10,13)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = "Q4 2021")

q3_21 <- read_excel("./2021/22_03_31_Rpt_(2021_Q3_Recycling_Summary).xls", sheet = 1) %>% 
  as.data.frame()
q3_21 <- q3_21[c(6,8:16), c(3,8,10,13)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = "Q3 2021")

q2_21 <- read_excel("./2021/22_03_31_Rpt_(2021_Q2_Recycling_Summary).xls", sheet = 1) %>% 
  as.data.frame()
q2_21 <- q2_21[c(6,8:16), c(3,8,10,13)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = "Q2 2021")

q1_21 <- read_excel("./2021/22_03_31_Rpt_(2021_Q1_Recycling_Summary).xls", sheet = 1) %>% 
  as.data.frame()
q1_21 <- q1_21[c(6,8:16), c(3,8,10,13)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = "Q1 2021")

q4_20 <- read_excel("./2020/21_03_25_Rpt_(2020_Q4_Recovery_Recycling_Summary.xls", sheet = 1) %>% 
  as.data.frame()
q4_20 <- q4_20[c(6,8:16), c(3,8,10,13)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = "Q4 2020")

q3_20 <- read_excel("./2020/20_11_27_Rpt_(2020_Q3_Recovery_Recycling_Summary).xls", sheet = 1) %>% 
  as.data.frame()
q3_20 <- q3_20[c(6,8:16, 19), c(4,10,12,16)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = "Q3 2020")

q2_20 <- read_excel("./2020/20_11_27_Rpt_(2020_Q2_Recovery_Recycling_Summary).xls", sheet = 1) %>% 
  as.data.frame()
q2_20 <- q2_20[c(6,8:16, 19), c(4,10,12,16)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = "Q2 2020")

q1_20 <- read_excel("./2020/20_11_27_Rpt_(2020_Q1_Recovery_Recycling_Summary).xls", sheet = 1) %>% 
  as.data.frame()
q1_20 <- q1_20[c(6,8:16, 19), c(4,10,12,16)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = "Q1 2020")

q4_19 <- read_excel("./2019/20_11_20_Rpt_(2019__Q4_Recycling_and_recovery_summary).xls", sheet = 1) %>% 
  as.data.frame()
q4_19 <- q4_19[c(6,8:16, 19), c(4,10,12,16)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = "Q4 2019")

q3_19 <- read_excel("./2019/20_03_31_Rpt_(2019__Q3_Recycling_and_recovery_summary).xls", sheet = 1) %>% 
  as.data.frame()
q3_19 <- q3_19[c(6,8:16, 19), c(4,10,12,16)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = "Q3 2019")

q2_19 <- read_excel("./2019/20_03_31_Rpt_(2019__Q2_Recycling_and_recovery_summary).xls", sheet = 1) %>% 
  as.data.frame()
q2_19 <- q2_19[c(6,8:16, 19), c(4,10,12,16)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = "Q2 2019")

q1_19 <- read_excel("./2019/20_03_31_Rpt_(2019__Q1_Recycling_and_recovery_summary).xls", sheet = 1) %>% 
  as.data.frame()
q1_19 <- q1_19[c(6,8:16, 19), c(4,10,12,16)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = "Q1 2019")

q4_18 <- read_excel("./2018/19_03_29_Rpt_(2018_Q4_RRS).xls", sheet = 1) %>% 
  as.data.frame()
q4_18 <- q4_18[c(6,8:16, 19), c(4,10,14,17)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = "Q4 2018")

q3_18 <- read_excel("./2018/19_03_29_Rpt_(2018_Q3_RRS).xls", sheet = 1) %>% 
  as.data.frame()
q3_18 <- q3_18[c(6,8:16, 19), c(4,10,14,17)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = "Q3 2018")

q2_18 <- read_excel("./2018/19_03_29_Rpt_(2018_Q2_RRS).xls", sheet = 1) %>% 
  as.data.frame()
q2_18 <- q2_18[c(6,8:16, 19), c(4,10,14,17)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = "Q2 2018")

q1_18 <- read_excel("./2018/19_03_29_Rpt_(2018_Q1_RRS).xls", sheet = 1) %>% 
  as.data.frame()
q1_18 <- q1_18[c(6,8:16, 19), c(4,10,14,17)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = "Q1 2018")

q4_17 <- read_excel("./2017/18_03_29_Rpt_(2017_Q4_Recovery_Recycling_Summary).xls", sheet = 1) %>% 
  as.data.frame()
q4_17 <- q4_17[c(6,8:16, 19), c(4,10,14,17)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = "Q4 2017")

q3_17 <- read_excel("./2017/18_03_29_Rpt_(2017_Q3_Recovery_Recycling_Summary).xls", sheet = 1) %>% 
  as.data.frame()
q3_17 <- q3_17[c(6,8:16, 19), c(4,10,14,17)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = "Q3 2017")

q2_17 <- read_excel("./2017/18_03_29_Rpt_(2017_Q2_Recovery_Recycling_Summary).xls", sheet = 1) %>% 
  as.data.frame()
q2_17 <- q2_17[c(6,8:16, 19), c(4,10,14,17)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = "Q2 2017")

q1_17 <- read_excel("./2017/18_03_29_Rpt_(2017_Q1_Recovery_Recycling_Summary).xls", sheet = 1) %>% 
  as.data.frame()
q1_17 <- q1_17[c(6,8:16, 19), c(4,10,14,17)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = "Q1 2017")

q4_16 <- read_excel("./2016/20_12_07_Rpt_(2016_Q4_Recovery_&_Recycling_Summary).xls", sheet = 1) %>% 
  as.data.frame()
q4_16 <- q4_16[c(6,8:16, 19), c(4,10,12,16)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = "Q4 2016")

q3_16 <- read_excel("./2016/17_03_31_Rpt_(2016_Q3_Recovery_&_Recycling_Summary).xls", sheet = 1) %>% 
  as.data.frame()
q3_16 <- q3_16[c(6,8:16, 19), c(4,10,14,17)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = "Q3 2016")

q2_16 <- read_excel("./2016/17_03_31_Rpt_(2016_Q2_Recovery_&_Recycling_Summary).xls", sheet = 1) %>% 
  as.data.frame()
q2_16 <- q2_16[c(6,8:16, 19), c(4,10,14,17)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = "Q2 2016")

q1_16 <- read_excel("./2016/17_03_31_Rpt_(2016_Q1_Recovery_&_Recycling_Summary).xls", sheet = 1) %>% 
  as.data.frame()
q1_16 <- q1_16[c(6,8:16, 19), c(3,7,12,14)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = "Q1 2016")

q4_15 <- read_excel("./2015/16_03_31_Rpt_(Recovery_&_Recycling_Summary_2015_Q4).xls", sheet = 1) %>% 
  as.data.frame()
q4_15 <- q4_15[c(6,8:16, 19), c(4,10,14,17)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = "Q4 2015")

q3_15 <- read_excel("./2015/16_03_31_Rpt_(Recovery_&_Recycling_Summary_2015_Q3).xls", sheet = 1) %>% 
  as.data.frame()
q3_15 <- q3_15[c(6,8:16, 19), c(4,10,14,17)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = "Q3 2015")

q2_15 <- read_excel("./2015/16_03_31_Rpt_(Recovery_&_Recycling_Summary_2015_Q2).xlsx", sheet = 1) %>% 
  as.data.frame()
q2_15 <- q2_15[c(6,8:16, 19), c(4,10,14,17)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = "Q2 2015")

q1_15 <- read_excel("./2015/16_03_31_Rpt_(Recovery_&_Recycling_Summary_2015_Q1).xls", sheet = 1) %>% 
  as.data.frame()
q1_15 <- q1_15[c(6,8:16, 19), c(4,10,14,17)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = "Q1 2015")

q4_14 <- read_excel("./2014/15_03_31_Rpt_(Recovery_&_Recycling_Summary_2014_Q4).xls", sheet = 1) %>% 
  as.data.frame()
q4_14 <- q4_14[c(6,8:16, 19), c(4,10,14,17)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = "Q4 2014")

q3_14 <- read_excel("./2014/15_03_31_Rpt_(Recovery_&_Recycling_Summary_2014_Q3).xls", sheet = 1) %>% 
  as.data.frame()
q3_14 <- q3_14[c(6,8:16, 19), c(4,10,14,17)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = "Q3 2014")

q2_14 <- read_excel("./2014/15_03_31_Rpt_(Recovery_&_Recycling_Summary_2014_Q2).xls", sheet = 1) %>% 
  as.data.frame()
q2_14 <- q2_14[c(6,8:16, 19), c(3,7,12,14)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = "Q2 2014")

q1_14 <- read_excel("./2014/15_03_31_Rpt_(Recovery_&_Recycling_Summary_2014_Q1).xls", sheet = 1) %>% 
  as.data.frame()
q1_14 <- q1_14[c(6,8:16, 19), c(3,7,12,14)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = "Q1 2014")

# Bind
packagingtotal <-
  rbindlist(
    list(
      q1_14,
      q2_14,
      q3_14,
      q4_14,
      q1_15,
      q2_15,
      q3_15,
      q4_15,
      q1_16,
      q2_16,
      q3_16,
      q4_16,
      q1_17,
      q2_17,
      q3_17,
      q4_17,
      q1_18,
      q2_18,
      q3_18,
      q4_18,
      q1_19,
      q2_19,
      q3_19,
      q4_19,
      q1_20,
      q2_20,
      q3_20,
      q4_20,
      q1_21,
      q2_21,
      q3_21,
      q4_21
    ),
    use.names = FALSE
  )

packagingtotal <- packagingtotal %>% 
  rename(Material = na) %>% 
  rename(Domestic = waste_accepted_for_uk_reprocessing) %>% 
  rename(Overseas = waste_exported_for_overseas_reprocessing) %>%
  rename(Total = total_waste_accepted_or_exported) %>% 
  mutate_if(is.numeric, round, digits=0) 

write_xlsx(packagingtotal, "Accepted_all.xlsx") 

