#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.

#### Libraries ####
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

iFixit <- read_excel("IFixit.xlsx", sheet = 1) 
iFixit <-iFixit[c(1:5)]

iFixit$Make <- trimws(iFixit$Make)

minvalueiFixit <- floor(min(iFixit$Year, na.rm = TRUE))
maxvalueiFixit <- ceiling(max(iFixit$Year, na.rm = TRUE)) 

grouped <- iFixit %>% group_by(Product, Make, Year) 

# Define UI for application that draws a histogram
ui <- fluidPage(
  
  # Sidebar with a slider input for number of bins 
  sidebarLayout(
    sidebarPanel(
      width = 3,
      selectInput(inputId = "iFixitprod",
              label = "Product Type",
              choices = c(unique(as.character(iFixit$Product))),
              selected = "Laptop")
    ),
    # Show a plot of the generated distribution
    mainPanel(
      plotlyOutput("ifixit")
    )
  )
)

# Define server logic required to draw a histogram
server <- function(input, output) {

output$ifixit <- renderPlotly({    

iFixittab <- reactive({
    filter <- filter(grouped, Product == input$iFixitprod) %>% 
      summarise(Value = round(mean(Repairability_Score),1)) 
  })
  
GGtab <- ggplot(iFixittab(),
      aes(x= Year, y = Value, group = Make, text=paste("Brand:",Make,"<br />Score:",Value, "<br />Year", Year))) +
      geom_point(aes(color=Make)) + 
      geom_line(aes(color=Make)) +
      theme_bw() +
      scale_x_continuous(breaks=seq(minvalueiFixit, maxvalueiFixit, 2)) +
      scale_y_continuous(breaks=seq(0, 10, 1)) +
      theme(axis.title.x = element_blank()) +
      theme(axis.title.y = element_blank())

ggplotly(GGtab, tooltip = c("text")) 

 }) 
}

# Run the application 
shinyApp(ui = ui, server = server)
