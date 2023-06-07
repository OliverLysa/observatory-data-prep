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

# Plotly credentials
Sys.setenv("plotly_username"="OliverLy")
Sys.setenv("plotly_api_key"="eaSRJK9wPThl8ZhwORnY")

# Import data
Openrepair <- read_csv("OpenRepairData_v0.3_aggregate_202110.csv") 

# Filter data
filter <- (c("Tablet", "Mobile", "Laptop"))

Openrepairlifespan <-
  Openrepair %>% 
  filter(product_age != "NA", 
         product_age < 30, 
         product_age > 0,
         product_category %in% filter) 

Openrepairtab <- 
  Openrepair[c(5,10)] %>% 
  filter(repair_status != "Unknown",
         product_category %in% filter)

Openrepairtab$repair_status <-
  factor(Openrepairtab$repair_status, 
         levels=c("End of life","Repairable", "Fixed"))

# Repair success
Openrepairgg <- ggplot(na.omit(Openrepairtab), aes(product_category, fill = repair_status, text=paste("Repair status:",repair_status))) +
  geom_bar(position = "fill", width = 0.8) +
  scale_fill_manual(values = c("#666666", "#FF9E16", "#00AF41")) +
  coord_flip() +
  theme_bw() +
  theme(axis.title.x = element_blank()) +
  theme(axis.title.y = element_blank()) +
  theme(legend.title = element_blank()) +
  scale_y_continuous(breaks=seq(0,1,0.2), labels = scales::percent) +
  scale_color_discrete(name="")

Openrepairggplotly <- ggplotly(Openrepairgg, tooltip = c("text")) %>%
  hide_legend()

api_create(Openrepairggplotly, filename = "Open_repair_successrate")

# Lifespan to repair
Lifespanchart <- ggplot(Openrepairlifespan, aes(x = reorder(product_category, product_age, FUN = median), y = product_age)) + 
  geom_boxplot(outlier.size = -1) +
  coord_flip() +
  theme_bw() +
  theme(axis.title.x = element_blank()) +
  theme(axis.title.y = element_blank()) +
  theme(legend.title = element_blank())

Lifespanchartggploly <- ggplotly(Lifespanchart, tooltip = c("count"))

api_create(Lifespanchartggploly, filename = "Open_repair_lifespan_consumer") 
