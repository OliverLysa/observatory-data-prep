##### **********************
# Packaging Data Download (EA Dataset)

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
require(readxl)

options(scipen=999)

# *******************************************************************************
# Download and data preparation
#********************************************************************************
#

#2020 Q4
download.file("https://npwd.environment-agency.gov.uk/FileDownload.ashx?FileId=3188ad75-d7e2-4bbb-a63c-3bb373c84061",
              "./Publication/Input/WT/Packaging/Downloaded_files/2020_Q4.xls")

q4_20 <- read_excel("./Publication/Input/WT/Packaging/Downloaded_files/2020_Q4.xls", sheet = 1) %>% 
  as.data.frame()
q4_20 <- q4_20[c(6,8:16, 19), c(3,8,10,13)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = 2020, Quarter = 4)

#2020 Q3
download.file("https://npwd.environment-agency.gov.uk/FileDownload.ashx?FileId=959b6e97-3461-4155-8b84-5871dfd5d0bf",
              "./Publication/Input/WT/Packaging/Downloaded_files/2020_Q3.xls")

q3_20 <- read_excel("./Publication/Input/WT/Packaging/Downloaded_files/2020_Q3.xls", sheet = 1) %>% 
  as.data.frame()
q3_20 <- q3_20[c(6,8:16, 19), c(3,8,10,13)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = 2020, Quarter = 3)

#2020 Q2
download.file("https://npwd.environment-agency.gov.uk/FileDownload.ashx?FileId=093ee842-901a-4429-bc37-473023eceeb2", 
              "./Publication/Input/WT/Packaging/Downloaded_files/2020_Q2.xls")

q2_20 <- read_excel("./Publication/Input/WT/Packaging/Downloaded_files/2020_Q2.xls", sheet = 1) %>% 
  as.data.frame()
q2_20 <- q2_20[c(6,8:16, 19), c(3,8,10,13)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = 2020, Quarter = 2)

#2020 Q1
download.file("https://npwd.environment-agency.gov.uk/FileDownload.ashx?FileId=0c813490-bfd8-44d5-8881-d638987f0aa3",
              "./Publication/Input/WT/Packaging/Downloaded_files/2020_Q1.xls")

q1_20 <- read_excel("./Publication/Input/WT/Packaging/Downloaded_files/2020_Q1.xls", sheet = 1) %>% 
  as.data.frame()
q1_20 <- q1_20[c(6,8:16, 19), c(3,8,10,13)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = 2020, Quarter = 1)

#2019 Q4 
download.file("https://npwd.environment-agency.gov.uk/FileDownload.ashx?FileId=0196efc3-8991-4d93-9c3e-609ef6978229",
              "./Publication/Input/WT/Packaging/Downloaded_files/2019_Q4.xls")

q4_19 <- read_excel("./Publication/Input/WT/Packaging/Downloaded_files/2019_Q4.xls", sheet = 1) %>% 
  as.data.frame()
q4_19 <- q4_19[c(6,8:16, 19), c(4,10,12,16)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = 2019, Quarter = 4)

#2019 Q3
download.file("https://npwd.environment-agency.gov.uk/FileDownload.ashx?FileId=a1959e24-3c52-45cb-b8e8-3ff73e265063",
              "./Publication/Input/WT/Packaging/Downloaded_files/2019_Q3.xls")

q3_19 <- read_excel("./Publication/Input/WT/Packaging/Downloaded_files/2019_Q3.xls", sheet = 1) %>% 
  as.data.frame()
q3_19 <- q3_19[c(6,8:16, 19), c(4,10,12,16)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = 2019, Quarter = 3)

#2019 Q2
download.file("https://npwd.environment-agency.gov.uk/FileDownload.ashx?FileId=d7fb69de-3e3f-4c6d-a1ee-b524c42e85c3",
              "./Publication/Input/WT/Packaging/Downloaded_files/2019_Q2.xls")

q2_19 <- read_excel("./Publication/Input/WT/Packaging/Downloaded_files/2019_Q2.xls", sheet = 1) %>% 
  as.data.frame()
q2_19 <- q2_19[c(6,8:16, 19), c(4,10,12,16)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = 2019, Quarter = 2)

#2019 Q1
download.file("https://npwd.environment-agency.gov.uk/FileDownload.ashx?FileId=601d5e83-9a06-47e2-bd70-b3d48b2709d0",
              "./Publication/Input/WT/Packaging/Downloaded_files/2019_Q1.xls")

q1_19 <- read_excel("./Publication/Input/WT/Packaging/Downloaded_files/2019_Q1.xls", sheet = 1) %>% 
  as.data.frame()
q1_19 <- q1_19[c(6,8:16, 19), c(4,10,12,16)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = 2019, Quarter = 1)

#2018 Q4
download.file("https://npwd.environment-agency.gov.uk/FileDownload.ashx?FileId=8547f686-64b9-4516-ac63-a29d4b91716f",
              "./Publication/Input/WT/Packaging/Downloaded_files/2018_Q4.xls")

q4_18 <- read_excel("./Publication/Input/WT/Packaging/Downloaded_files/2018_Q4.xls", sheet = 1) %>% 
  as.data.frame()
q4_18 <- q4_18[c(6,8:16, 19), c(4,10,14,17)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = 2018, Quarter = 4)

#2018 Q3
download.file("https://npwd.environment-agency.gov.uk/FileDownload.ashx?FileId=8106a0b0-a2b8-4eea-b2aa-bbcac9babdeb",
              "./Publication/Input/WT/Packaging/Downloaded_files/2018_Q3.xls")

q3_18 <- read_excel("./Publication/Input/WT/Packaging/Downloaded_files/2018_Q3.xls", sheet = 1) %>% 
  as.data.frame()
q3_18 <- q3_18[c(6,8:16, 19), c(4,10,14,17)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = 2018, Quarter = 3)

#2018 Q2
download.file("https://npwd.environment-agency.gov.uk/FileDownload.ashx?FileId=1408a62e-7f35-44b5-a6e4-43318ce6a5fd",
              "./Publication/Input/WT/Packaging/Downloaded_files/2018_Q2.xls")

q2_18 <- read_excel("./Publication/Input/WT/Packaging/Downloaded_files/2018_Q2.xls", sheet = 1) %>% 
  as.data.frame()
q2_18 <- q2_18[c(6,8:16, 19), c(4,10,14,17)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = 2018, Quarter = 2)

#2018 Q1
download.file("https://npwd.environment-agency.gov.uk/FileDownload.ashx?FileId=91cb0968-62cd-4bb3-aa4c-34b58d549203",
              "./Publication/Input/WT/Packaging/Downloaded_files/2018_Q1.xls")

q1_18 <- read_excel("./Publication/Input/WT/Packaging/Downloaded_files/2018_Q1.xls", sheet = 1) %>% 
  as.data.frame()
q1_18 <- q1_18[c(6,8:16, 19), c(4,10,14,17)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = 2018, Quarter = 1)

#2017 Q4
download.file("https://npwd.environment-agency.gov.uk/FileDownload.ashx?FileId=80d2990a-f390-4efc-9ae2-80bc2d764f42",
              "./Publication/Input/WT/Packaging/Downloaded_files/2017_Q4.xls")

q4_17 <- read_excel("./Publication/Input/WT/Packaging/Downloaded_files/2017_Q4.xls", sheet = 1) %>% 
  as.data.frame()
q4_17 <- q4_17[c(6,8:16, 19), c(4,10,14,17)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = 2017, Quarter = 4)

#2017 Q3
download.file("https://npwd.environment-agency.gov.uk/FileDownload.ashx?FileId=66ddd059-6d09-45dd-9450-276cea13b922",
              "./Publication/Input/WT/Packaging/Downloaded_files/2017_Q3.xls")

q3_17 <- read_excel("./Publication/Input/WT/Packaging/Downloaded_files/2017_Q3.xls", sheet = 1) %>% 
  as.data.frame()
q3_17 <- q3_17[c(6,8:16, 19), c(4,10,14,17)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = 2017, Quarter = 3)

#2017 Q2
download.file("https://npwd.environment-agency.gov.uk/FileDownload.ashx?FileId=c892a807-28fe-4531-8992-3733df0b6dca",
              "./Publication/Input/WT/Packaging/Downloaded_files/2017_Q2.xls")

q2_17 <- read_excel("./Publication/Input/WT/Packaging/Downloaded_files/2017_Q2.xls", sheet = 1) %>% 
  as.data.frame()
q2_17 <- q2_17[c(6,8:16, 19), c(4,10,14,17)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = 2017, Quarter = 2)

#2017 Q1
download.file("https://npwd.environment-agency.gov.uk/FileDownload.ashx?FileId=3459e7ef-3633-45b9-a091-3a92d4ddb7c3",
              "./Publication/Input/WT/Packaging/Downloaded_files/2017_Q1.xls")

q1_17 <- read_excel("./Publication/Input/WT/Packaging/Downloaded_files/2017_Q1.xls", sheet = 1) %>% 
  as.data.frame()
q1_17 <- q1_17[c(6,8:16, 19), c(4,10,14,17)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = 2017, Quarter = 1)

#2016 Q4
download.file("https://npwd.environment-agency.gov.uk/FileDownload.ashx?FileId=43e5e5b1-6a2b-4588-baae-e754d7afef7e",
              "./Publication/Input/WT/Packaging/Downloaded_files/2016_Q4.xls")

q4_16 <- read_excel("./Publication/Input/WT/Packaging/Downloaded_files/2016_Q4.xls", sheet = 1) %>% 
  as.data.frame()
q4_16 <- q4_16[c(6,8:16, 19), c(4,10,12,16)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = 2016, Quarter = 4)

#2016 Q3
download.file("https://npwd.environment-agency.gov.uk/FileDownload.ashx?FileId=cf379ea9-b4b8-4f59-87db-c969655fbf86",
              "./Publication/Input/WT/Packaging/Downloaded_files/2016_Q3.xls")

q3_16 <- read_excel("./Publication/Input/WT/Packaging/Downloaded_files/2016_Q3.xls", sheet = 1) %>% 
  as.data.frame()
q3_16 <- q3_16[c(6,8:16, 19), c(4,10,14,17)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = 2016, Quarter = 3)

#2016 Q2
download.file("https://npwd.environment-agency.gov.uk/FileDownload.ashx?FileId=f74c32ec-6ebb-4a79-a581-f6cc795d1de6",
              "./Publication/Input/WT/Packaging/Downloaded_files/2016_Q2.xls")

q2_16 <- read_excel("./Publication/Input/WT/Packaging/Downloaded_files/2016_Q2.xls", sheet = 1) %>% 
  as.data.frame()
q2_16 <- q2_16[c(6,8:16, 19), c(4,10,14,17)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = 2016, Quarter = 2)

#2016 Q1
download.file("https://npwd.environment-agency.gov.uk/FileDownload.ashx?FileId=e03f4ab5-c81a-4cbb-8480-bf6d789e7deb",
              "./Publication/Input/WT/Packaging/Downloaded_files/2016_Q1.xls")

q1_16 <- read_excel("./Publication/Input/WT/Packaging/Downloaded_files/2016_Q1.xls", sheet = 1) %>% 
  as.data.frame()
q1_16 <- q1_16[c(6,8:16, 19), c(3,7,12,14)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = 2016, Quarter = 1)

#2015 Q4
download.file("https://npwd.environment-agency.gov.uk/FileDownload.ashx?FileId=20a75eef-72ff-42af-b94e-f951e0113c0d",
              "./Publication/Input/WT/Packaging/Downloaded_files/2015_Q4.xls")

q4_15 <- read_excel("./Publication/Input/WT/Packaging/Downloaded_files/2015_Q4.xls", sheet = 1) %>% 
  as.data.frame()
q4_15 <- q4_15[c(6,8:16, 19), c(4,10,14,17)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = 2015, Quarter = 4)

#2015 Q3
download.file("https://npwd.environment-agency.gov.uk/FileDownload.ashx?FileId=fa2e16a1-5fe0-4b73-96c1-c1902d596a42",
              "./Publication/Input/WT/Packaging/Downloaded_files/2015_Q3.xls")

q3_15 <- read_excel("./Publication/Input/WT/Packaging/Downloaded_files/2015_Q3.xls", sheet = 1) %>% 
  as.data.frame()
q3_15 <- q3_15[c(6,8:16, 19), c(4,10,14,17)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = 2015, Quarter = 3)

#2015 Q2
download.file("https://npwd.environment-agency.gov.uk/FileDownload.ashx?FileId=51d4e838-bb27-4581-82fe-a59176eddd57",
              "./Publication/Input/WT/Packaging/Downloaded_files/2015_Q2.xlsx")

q2_15 <- read_excel("./Publication/Input/WT/Packaging/Downloaded_files/2015_Q2.xlsx", sheet = 1) %>% 
  as.data.frame()
q2_15 <- q2_15[c(6,8:16, 19), c(4,10,14,17)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = 2015, Quarter = 2)

#2015 Q1
download.file("https://npwd.environment-agency.gov.uk/FileDownload.ashx?FileId=5804b199-f5a0-42b3-8f0b-262ab0bf0fa5",
              "./Publication/Input/WT/Packaging/Downloaded_files/2015_Q1.xls")

q1_15 <- read_excel("./Publication/Input/WT/Packaging/Downloaded_files/2015_Q1.xls", sheet = 1) %>% 
  as.data.frame()
q1_15 <- q1_15[c(6,8:16, 19), c(4,10,14,17)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = 2015, Quarter = 1)

#2014 Q4
download.file("https://npwd.environment-agency.gov.uk/FileDownload.ashx?FileId=34d7ba13-13bb-40c8-b3c5-1ccddd4f319f",
              "./Publication/Input/WT/Packaging/Downloaded_files/2014_Q4.xls")

q4_14 <- read_excel("./Publication/Input/WT/Packaging/Downloaded_files/2014_Q4.xls", sheet = 1) %>% 
  as.data.frame()
q4_14 <- q4_14[c(6,8:16, 19), c(4,10,14,17)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = 2014, Quarter = 4)

#2014 Q3
download.file("https://npwd.environment-agency.gov.uk/FileDownload.ashx?FileId=ea85224a-50d4-4b4d-b5ed-bdaf84a969d6",
              "./Publication/Input/WT/Packaging/Downloaded_files/2014_Q3.xls")

q3_14 <- read_excel("./Publication/Input/WT/Packaging/Downloaded_files/2014_Q3.xls", sheet = 1) %>% 
  as.data.frame()
q3_14 <- q3_14[c(6,8:16, 19), c(4,10,14,17)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = 2014, Quarter = 3)

#2014 Q2
download.file("https://npwd.environment-agency.gov.uk/FileDownload.ashx?FileId=4ad97c58-27a4-4c57-bfc2-38e42b8d1124",
              "./Publication/Input/WT/Packaging/Downloaded_files/2014_Q2.xls")

q2_14 <- read_excel("./Publication/Input/WT/Packaging/Downloaded_files/2014_Q3.xls", sheet = 1) %>% 
  as.data.frame()
q2_14 <- q2_14[c(6,8:16, 19), c(4,10,14,17)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = 2014, Quarter = 2)

#2014 Q1
download.file("https://npwd.environment-agency.gov.uk/FileDownload.ashx?FileId=c9efa5ac-8190-424e-a179-cfaeb7dd889a",
              "./Publication/Input/WT/Packaging/Downloaded_files/2014_Q1.xls")

q1_14 <- read_excel("./Publication/Input/WT/Packaging/Downloaded_files/2014_Q1.xls", sheet = 1) %>% 
  as.data.frame()

q1_14 <- q1_14[c(6,8:16, 19), c(3,7,12,14)] %>%
  row_to_names(row_number = 1) %>% clean_names() %>% mutate(Year = 2014, Quarter = 1)

# Bind
Packaging_2014_on <-
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
      q4_20
    ),
    use.names = FALSE
  )

Packaging_2014_on <- Packaging_2014_on %>% 
  rename(Material = na) %>% 
  rename(`Treatment Domestic` = waste_accepted_for_uk_reprocessing) %>% 
  rename(`Treatment Overseas` = waste_exported_for_overseas_reprocessing) %>%
  rename(Total = total_waste_accepted_or_exported)

Packaging_2014_on <- Packaging_2014_on %>% 
  filter(Material != "Paper Composting", Material != "Wood Composting", Material != "EfW")

Packaging_2014_on$`Treatment Domestic` <-
  as.numeric(Packaging_2014_on$`Treatment Domestic`)

Packaging_2014_on$`Treatment Overseas` <-
  as.numeric(Packaging_2014_on$`Treatment Overseas`)

Packaging_2014_on$Total <-
  as.numeric(Packaging_2014_on$Total)

write_xlsx(Packaging_2014_on, "./Publication/Input/WT/Packaging/Packaging_accepted.xlsx") 

# Chart preparation 

Packagingaccepted <- read_xlsx("./Publication/Input/WT/Packaging/Packaging_accepted.xlsx") 

Packagingaccepted_pre2014 <- read_xlsx("./Publication/Input/WT/Packaging/Packaging_accepted_pre2014.xlsx") 

Packagingaccepted <- rbind(Packagingaccepted_pre2014, Packagingaccepted)

Packagingaccepted <- Packagingaccepted[order(Packagingaccepted$Year, Packagingaccepted$Quarter),]

Packagingaccepted <- Packagingaccepted %>% 
  pivot_longer(-c(Material, Year, Quarter), names_to = "Indicator") %>%
  na.omit(value)

Packagingaccepted$Material <- gsub("Wood Composting", "Wood", Packagingaccepted$Material)

Packagingaccepted$Material <- gsub("Paper Composting", "Paper/board", Packagingaccepted$Material)

Packagingaccepted$Material <- gsub("Glass Other", "Glass", Packagingaccepted$Material)

Packagingaccepted$Material <- gsub("Glass Re-melt", "Glass", Packagingaccepted$Material)

Packagingaccepted <- Packagingaccepted %>% 
  group_by(Year, Material, Indicator) %>% 
  summarise(Value = sum(value))

Packagingaccepted <- Packagingaccepted %>%
  filter(Indicator != "Total", Year != 2010, Year != 2011) %>% 
  mutate(Value = Value/1000) %>%
  mutate_if(is.numeric, round, digits=0) %>%
  mutate(Measure = "Treatment") %>%
  clean_names()

# 

download.file("http://data.defra.gov.uk/Waste/Table7_1_Packaging_waste_recycling_recovery_material_UK_2012_20.csv",
              "./Publication/Input/WT/Packaging/Downloaded_files/UKStatsonWaste_Packaging.csv")

UKStats <- read.csv("./Publication/Input/WT/Packaging/Downloaded_files/UKStatsonWaste_Packaging.csv") %>%
  as.data.frame() %>% clean_names()

UKStats <- UKStats %>%
  rename(Material = material_thousand_tonnes) %>%
  rename(Arisings = packaging_waste_arising) %>%
  rename(`Recycling Rate` = achieved_recovery_recycling_rate)

UKStats$total_recovered_recycled <- NULL
UKStats$`Recycling Rate` <- NULL

UKStats <- UKStats %>% 
  filter(str_detect(Material, 'Aluminium|Steel|Paper|Glass|Plastic|Wood'))

UKStats$Material <- gsub('\\s+', '', UKStats$Material)
UKStats$year <- gsub('*', '', UKStats$year, fixed = TRUE)

UKStats$Material <- gsub("Glass(recycling)", "Glass", UKStats$Material, fixed = TRUE)
UKStats$Material <- gsub("Plastic(recycling)", "Plastic", UKStats$Material, fixed = TRUE)
UKStats$Material <- gsub("Wood(recycling)", "Wood", UKStats$Material, fixed = TRUE)
UKStats$Material <- gsub("PaperandCard(recycling)board", "Paper/board", UKStats$Material, fixed = TRUE)
UKStats$Material <- gsub("ofwhich:Steel(recycling)", "Steel", UKStats$Material, fixed = TRUE)
UKStats$Material <- gsub("ofwhich:Aluminium(recycling)", "Aluminium", UKStats$Material, fixed = TRUE)

UKStats <- UKStats %>% 
  pivot_longer(-c(Material, year), names_to = "Measure") %>%
  mutate(Indicator = "Placed on Market") %>%
  clean_names()

UKStats$year <- as.numeric(as.character(UKStats$year))

Packaging_tonnages <- rbind(Packagingaccepted, UKStats)

write_xlsx(Packaging_tonnages, "./Publication/Input/WT/Packaging/Packaging_all.xlsx") 


