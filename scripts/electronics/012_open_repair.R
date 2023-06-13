# Import libraries
library(httr)
library(jsonlite)
require(writexl)
require(readODS)
require(readxl)
require(janitor)
require(xlsx)
library(tidyverse)
require(data.table)
require(kableExtra)
require(ggplot2)
require(plotly)
library(rvest)
library(netstat)
library(ggridges)

# Import data, filter to britain and remove certain outliers (less than 0 years) and likely outliers (over 100)
Openrepair <- read_csv("./raw_data/OpenRepairData_v0.3_aggregate_202210.csv") %>%
  filter(country == "GBR",
         product_age != "NA",
         product_age < 40, 
         product_age > 0)

Lifespanchart <- ggplot(Openrepair, aes(x = reorder(product_category, product_age, FUN = median), y = product_age)) + 
  geom_boxplot(outlier.size = -1) +
  coord_flip() +
  theme(axis.title.x = element_blank()) +
  theme(axis.title.y = element_blank()) +
  theme(legend.title = element_blank())

ggplotly(Lifespanchart, tooltip = c("count"))  

ggplot(Openrepair, aes(x = product_age, y = product_category, fill = after_stat(y))) + 
  geom_density_ridges(scale = 3) +
  scale_fill_viridis_c(name = "age", option = "C") 

ggplot(Openrepair, aes(x = product_age, y = reorder(product_category,product_age, FUN = median), fill = after_stat(y))) + 
  geom_density_ridges(scale = 3) +
  scale_fill_viridis_c(name = "age", option = "C") +
  theme_minimal()

ggplot(Openrepair, aes(x = product_age, y = fct_reorder(product_category,product_age))) +
  stat_density_ridges(quantile_lines = FALSE, quantiles = 4, alpha = 0.7) +
  theme_minimal()

ggplot(Openrepair, aes(x = product_age, y = fct_reorder(product_category,product_age), fill = factor(stat(quantile)))) +
  stat_density_ridges(
    geom = "density_ridges_gradient",
    calc_ecdf = TRUE,
    quantiles = c(0.025, 0.975)
  ) +
  scale_fill_manual(
    name = "Probability", values = c("#FF0000A0", "#A0A0A0A0", "#0000FFA0"),
    labels = c("(0, 0.025]", "(0.025, 0.975]", "(0.975, 1]")
  ) +
  theme_minimal()

ggplot(Openrepair, aes(x = product_age, y = fct_reorder(product_category,product_age), fill = 0.5 - abs(0.5 - stat(ecdf)))) +
  stat_density_ridges(geom = "density_ridges_gradient", calc_ecdf = TRUE) +
  scale_fill_viridis_c(name = "Tail probability", direction = -1) +
  theme_minimal()

ggplot(Openrepair, aes(x = product_age, y = fct_reorder(product_category,product_age), height = stat(density))) + 
  geom_density_ridges(stat = "density")
  
Openrepairtab <- 
  Openrepair[c(5,10)] %>% 
  filter(repair_status != "Unknown",
         product_category %in% filter)

Openrepairtab$repair_status <-
  factor(Openrepairtab$repair_status, 
         levels=c("End of life","Repairable", "Fixed"))

