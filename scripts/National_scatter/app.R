#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.

#### Libraries ####
require(writexl)
require(readODS)
require(readxl)
require(janitor)
require(xlsx)
library(tidyverse)
require(data.table)
require(ggplot2)
require(plotly)
library(shiny)
require(shinyWidgets)

options(scipen=999)

# Import data
National <- read_excel("National_scatter.xlsx") %>%
  dplyr::select(- c(`ITL region name`, `SIC_group`)) %>%
  clean_names()

National$year <- as.numeric(National$year)

# Set upper and lower bound for the slider
minvalue <- floor(min(National$year, na.rm = TRUE))
maxvalue <- ceiling(max(National$year, na.rm = TRUE)) 

# Define UI for application that draws a histogram
ui <- fluidPage(
      sidebarLayout(
        sliderInput(
        "Range",
        label = "Year:",
        min = minvalue,
        max = maxvalue,
        value = c(minvalue, maxvalue),
        2,
        sep = "",
        width = '50%'
      ),
      mainPanel(
        plotlyOutput("National"))
))

server <- function(input, output) {

output$National <- renderPlotly({
    
Nat_tab <- reactive({
      filter <- filter(National,
                       between(year, input$Range[1], 
                               input$Range[2])
)}) 
    
National <- ggplot(Nat_tab(),
                         aes(x= emissions, y = gva, text=paste("Industry:",`sic07_description`, "<br />Emissions:",emissions,"<br />GVA:",gva))) +
    geom_point(aes(color=sic07_description)) +
      theme_bw()
    
    ggplotly(National, tooltip = c("text")) %>% 
      hide_legend()
    
  })
  
}

# Run the application 
shinyApp(ui = ui, server = server)

