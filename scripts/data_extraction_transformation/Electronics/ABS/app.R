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

RSectors <- read_excel("ABS_input.xlsx") %>%
  pivot_longer(-c(Year, Description, 1), names_to = c("Indicator")) %>%
  filter(value != "[c]") %>%
  filter(value != "[low]") %>%
  na.omit()

RSectors$Indicator <- trimws(RSectors$Indicator)

extract <- c("Retail sale of second-hand goods in stores",
             "Repair of computers and communication equipment",
             "Repair of consumer electronics",
             "Renting and leasing of personal and household goods",
             "Renting and leasing of office machinery and equipment (including computers)",
             "Repair of electronic and optical equipment",
             "Repair of electrical equipment",
             "Wholesale of waste and scrap")

RSectors <- RSectors %>%
  filter(Description %in% extract)

RSectors$value <-
  as.numeric(RSectors$value)

RSectors$value <- 
  round(RSectors$value, digits=0)

ggplot(RSectors,
              aes(x= Year, y = value, group = Indicator)) +
  geom_line(aes(color=Description)) +
  theme(axis.title.x = element_blank()) +
  scale_x_continuous(breaks=seq(2008, 2020, 1)) +
  theme(axis.title.y = element_blank())

# Define UI for application that draws a histogram
ui <- fluidPage(
      sidebarLayout(sidebarPanel(
        selectInput(
          inputId = "Indicator",
          label = "Indicator",
          choices = c(unique(as.character(RSectors$Indicator))),
          selected = "Total turnover"
        ),
        pickerInput(
          inputId = "SIC",
          label = "Activity",
          choices = c(unique(as.character(RSectors$Description))),
          selected = "Repair of consumer electronics",
          multiple = TRUE
          ),
      ),
      # Show a plot of the generated distribution
      mainPanel(
        plotlyOutput("ABS"))
))

# Define server logic required to draw a histogram
server <- function(input, output) {

output$ABS <- renderPlotly({
  
shiny::validate(
    need(input$SIC, "")) 
  
RSectorstab <- reactive({
    filteredRSectorGVAtab <- filter(RSectors, Indicator == input$Indicator,
                                              Description %in% input$SIC)
})
  
GVA <- ggplot(RSectorstab(),
                  aes(x= Year, y = value, group = Indicator, text=paste("SIC:",Description,"<br />Value:",value, "<br />Year:",Year))) +
      geom_line(aes(color=Description)) +
      geom_point(aes(color=Description)) +
      theme_bw() +
      theme(axis.title.x = element_blank()) +
      scale_x_continuous(breaks=seq(2008, 2020, 2)) +
      theme(axis.title.y = element_blank())
    
ggplotly(GVA, tooltip = c("text")) %>% 
      hide_legend()
  }) 
}

# Run the application 
shinyApp(ui = ui, server = server)
