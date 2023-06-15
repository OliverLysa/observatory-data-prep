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
# Calculate outflows
# *******************************************************************************

# https://onlinelibrary.wiley.com/doi/abs/10.1111/jiec.12551
# https://www.sciencedirect.com/science/article/abs/pii/S0959652618339660

# Import lifespan data
lifespan_data <- read_excel("./cleaned_data/electronics_lifespan.xlsx",
                            sheet = 1,
                            range = "A2:AY75")

# Keep only collated lifespan data columns and rename
lifespan_data_filtered <- lifespan_data[c(1:54), c(1, 7, 8)] %>%
  rename(unu_key = 1,
         shape = 2,
         scale = 3) %>%
  na.omit()

# Calculate mean from Weibull parameters to go into the bubble chart
weibullparinv(1.6, 8.1599999951404, loc = 0)

# Import inflow data to match to UNU
inflow_unu_mass_units <-
  read_xlsx("./cleaned_data/inflow_unu_mass_units.xlsx")

# Merge inflow and lifespan data by unu_key
inflow_weibull <-
  merge(
    inflow_unu_mass_units,
    lifespan_data_filtered,
    by = c("unu_key"),
    all.x = TRUE
  )

# Set up dataframe for outflow calculation based on Balde et al 2016. Create empty columns for all years in range of interest
year_first <- min(as.integer(inflow_weibull$year))
year_last <- max(as.integer(inflow_weibull$year)) + 30
years <- c(year_first:year_last)
empty <-
  as.data.frame(matrix(NA, ncol = length(years), nrow = nrow(inflow_weibull)))
colnames(empty) <- years

# Add the empty columns to inflow weibull dataframe
inflow_weibull <- cbind(inflow_weibull, empty)
rm(empty)

# Calculate WEEE from inflow year based on shape and scale parameters
for (i in year_first:year_last) {
  inflow_weibull$WEEE_POM_dif <-
    i - (as.integer(inflow_weibull[, "year"]))
  wb <-
    dweibull(
      inflow_weibull[(inflow_weibull$WEEE_POM_dif >= 0), "WEEE_POM_dif"] + 0.5,
      shape = inflow_weibull[(inflow_weibull$WEEE_POM_dif >= 0), "shape"],
      scale = inflow_weibull[(inflow_weibull$WEEE_POM_dif >= 0), "scale"],
      log = FALSE
    )
  weee <-
    wb * inflow_weibull[(inflow_weibull$WEEE_POM_dif >= 0), "value"]
  inflow_weibull[(inflow_weibull$WEEE_POM_dif >= 0), as.character(i)] <-
    weee
}

# Make long format while including the year placed on market
inflow_weibull_long <- inflow_weibull %>% select(-c(shape,
                                                    scale,
                                                    value,
                                                    WEEE_POM_dif)) %>%
  rename(year_pom = year) %>%
  mutate(variable = gsub("inflow",
                         "outflow",
                         variable)) %>%
  pivot_longer(-c(unu_key,
                  year_pom,
                  unit,
                  variable),
               names_to = "year",
               values_to = "value") %>%
  na.omit()

# Make long format aggregating by year outflow (i.e. suppressing year POM)
inflow_weibull_long_outflow_summary <- inflow_weibull %>%
  select(-c(shape,
            scale,
            value,
            WEEE_POM_dif)) %>%
  rename(year_pom = year) %>%
  mutate(variable = gsub("inflow",
                         "outflow",
                         variable)) %>%
  pivot_longer(-c(unu_key,
                  year_pom,
                  unit,
                  variable),
               names_to = "year",
               values_to = "value") %>%
  na.omit() %>%
  group_by(unu_key, 
           unit, 
           variable, 
           year) %>%
  summarise(value = 
              sum(value))

### Stock data: Electrical products data tables (represent an underestimate)

# ----------------------------------------------------------------------------------
#                                        WEEE and Stock
# ----------------------------------------------------------------------------------

# ----------------------------------------------------------
# tbl_WEEE: Add calculated WEEE data
# ----------------------------------------------------------
tbl_WEEE <- read.csv("tbl_WEEE.csv", quote = "\"",
                     colClasses = c("numeric", "character", "character", "character", "numeric",
                                    "numeric", "numeric", "numeric"))

# select only data for the same years as are available in tbl_POM.
selection <- which( as.numeric(tbl_WEEE$Year) <= as.numeric(max(tbl_POM$Year)) )
tbl_WEEE <- tbl_WEEE[selection, ]


# ----------------------------------------------------------
# tbl_WEEE: Aggregate the data and append it to dataset
# ----------------------------------------------------------

# Set inputfile for calculations
mydf <- tbl_WEEE
mydf <- plyr::rename(mydf,c("WEEE_t"="var_t"))
mydf <- plyr::rename(mydf,c("WEEE_pieces"="var_p"))

source(file.path(SCRIPT_PATH, "05a_calculate_aggregates.R"))

mydf_all <- plyr::rename(mydf_all,c("var_t"="WEEE_t"))
mydf_all <- plyr::rename(mydf_all,c("var_p"="WEEE_pieces"))

tbl_WEEE_all <- mydf_all

# Calculate the stock (historic POM - historic WEEE) in weight and units.
tbl_stock <- merge(tbl_POM_all[, c(1:6, 9, 10)], tbl_WEEE_all[, 1:6],
                   by=c("UNU_Key", "Stratum" , "Country", "Year"), all.x = TRUE)

# Calculate cumulative sums per group
require(data.table)
tbl_stock <- data.table(tbl_stock)
tbl_stock[, POM_t_cumsum := cumsum(POM_t), by=list(UNU_Key, Stratum, Country)]
tbl_stock[, POM_pieces_cumsum := cumsum(POM_pieces), by=list(UNU_Key, Stratum, Country)]
tbl_stock[, WEEE_t_cumsum := cumsum(WEEE_t), by=list(UNU_Key, Stratum, Country)]
tbl_stock[, WEEE_pieces_cumsum := cumsum(WEEE_pieces), by=list(UNU_Key, Stratum, Country)]

tbl_stock$stock_t <- tbl_stock$POM_t_cumsum - tbl_stock$WEEE_t_cumsum
tbl_stock$stock_pieces <- tbl_stock$POM_pieces_cumsum - tbl_stock$WEEE_pieces_cumsum
tbl_stock <- as.data.frame(tbl_stock)

# Stock lower than zero cannot exist.
# The value of the ones lower than zero are added to the WEEE.
# This will only happen in far future for products that are not produced anymore for a long time.
selection <- which (tbl_stock$stock_t < 0 )
if (length(selection) > 0){
  tbl_stock[selection, "WEEE_t"] <- tbl_stock[selection, "WEEE_t"] - tbl_stock[selection, "stock_t"]
  tbl_stock[selection, "WEEE_pieces"] <- tbl_stock[selection, "WEEE_pieces"] - tbl_stock[selection, "stock_pieces"]
  tbl_stock[selection, "stock_t"] <- 0
  tbl_stock[selection, "stock_pieces"] <- 0
}

# Not needed anymore
tbl_stock$POM_t <- NULL
tbl_stock$POM_pieces <- NULL
tbl_stock$POM_t_cumsum <- NULL
tbl_stock$POM_pieces_cumsum <- NULL
tbl_stock$WEEE_t_cumsum <- NULL
tbl_stock$WEEE_pieces_cumsum <- NULL


### Create WEEE table
# Copy stock to WEEE table in cases WEEE had been changed for products that are long
# time not used anymore.
tbl_WEEE_all <- tbl_stock[1:8]
# Calculate kpi and ppi
tbl_WEEE_all$kpi <- tbl_WEEE_all$WEEE_t / tbl_WEEE_all$Inhabitants * 1000
tbl_WEEE_all$ppi <- tbl_WEEE_all$WEEE_pieces / tbl_WEEE_all$Inhabitants

tbl_WEEE_all$flag <- NA

# Order of rows:
sortorder <- order( tbl_WEEE_all$UNU_Key, tbl_WEEE_all$Country, -rank(tbl_WEEE_all$Year) )

# Order of columns: 
sortorder_c <- c("UNU_Key", "UNU_Key_Description", "Stratum", "Country", "Year", "Inhabitants", "kpi", "ppi",
                 "WEEE_t", "WEEE_pieces", "flag")

tbl_WEEE_all <- tbl_WEEE_all[sortorder, sortorder_c]


### Create Stock table
tbl_Stock_all <- tbl_stock[c(1:6, 9, 10)]
# Calculate kpi and ppi
tbl_Stock_all$kpi <- tbl_Stock_all$stock_t / tbl_Stock_all$Inhabitants * 1000
tbl_Stock_all$ppi <- tbl_Stock_all$stock_pieces / tbl_Stock_all$Inhabitants

tbl_Stock_all$flag <- NA

# Order of rows:
sortorder <- order( tbl_Stock_all$UNU_Key, tbl_Stock_all$Country, -rank(tbl_Stock_all$Year) )

# Order of columns: 
sortorder_c <- c("UNU_Key", "UNU_Key_Description", "Stratum", "Country", "Year", "Inhabitants", "kpi", "ppi",
                 "stock_t", "stock_pieces", "flag")

tbl_Stock_all <- tbl_Stock_all[sortorder, sortorder_c]

# Clean-up
rm(Population)
rm(htbl_Key_Aggregates)
