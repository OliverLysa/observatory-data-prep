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
Dataset_mass <- read_excel("REE_input.xlsx", sheet = "Nd_demand") %>%
  na.omit()

# Round values
Dataset_mass$value <- 
  round(Dataset_mass$value, digits=2)

# Import data
Dataset_mass_outflow <- read_excel("REE_input.xlsx", sheet = "Nd_outflow") %>%
  na.omit()

# Round values
Dataset_mass_outflow$value <- 
  round(Dataset_mass_outflow$value, digits=2)

# Import data
Dataset_monetary_outflow <- read_excel("REE_input.xlsx", sheet = "Nd_outflow_value") %>%
  na.omit()

Dataset_monetary_outflow <- Dataset_monetary_outflow %>%
  mutate(value = value/1000000)

# Round values
Dataset_monetary_outflow$value <- 
  round(Dataset_monetary_outflow$value, digits=2)

# Set upper and lower bound for the slider
minvalue <- floor(min(Dataset_mass$year, na.rm = TRUE))
maxvalue <- ceiling(max(Dataset_mass$year, na.rm = TRUE)) 

# Define UI for application
ui <- fluidPage(
        titlePanel("Nd in Permanent magnets"),
        sidebarLayout(sidebarPanel(
        selectInput(
          inputId = "product",
          label = "Signature product",
          choices = c(unique(as.character(Dataset_mass$product))),
          selected = "Wind"
        ),
        pickerInput(
          inputId = "scenario",
          label = "Scenario",
          choices = c(unique(as.character(Dataset_mass$scenario))),
          multiple = TRUE,
          selected = "1_Baseline lifespan + Zero EoL recovery"
        ),
        sliderInput(
          "Range",
          label = "Period",
          min = minvalue,
          max = maxvalue,
          value = c(minvalue, maxvalue),
          5,
          sep = ""
        ),
      ),
      # Show a plot of the generated distribution
      mainPanel(
        tabsetPanel(
          tabPanel("Cumulative Nd demand (tonnes)", plotlyOutput("Mass")), 
          tabPanel("Cumulative Nd disposed of (tonnes)", plotlyOutput("Mass_outflows")),
          tabPanel("Cumulative value of Nd disposed of (million £)", plotlyOutput("Monetary_outflows")),
))))

# Define server logic required to draw a histogram
server <- function(input, output) {

output$Mass <- renderPlotly({
  
shiny::validate(
    need(input$product, "")) 
  
shiny::validate(
    need(input$scenario, "")) 
  
Filtered_table <- reactive({
    filtered <- filter(Dataset_mass, between(year, input$Range[1], 
                                        input$Range[2]),
                                product %in% input$product,
                                scenario %in% input$scenario)
})
  
GVA <- ggplot(Filtered_table(),
      aes(x= year, y = value, group = scenario, text=paste("Product:",product, "<br />Value:",value, "<br />Year:",year))) +
      geom_line(aes(color=scenario, linetype=scenario), linewidth = 1.3) +
      scale_color_manual(values = c("#D9262E", "#FF9E16", "#FFCC00", "#00AF41")) +
      theme_minimal() +
      theme(axis.title.x = element_blank()) +
      scale_x_continuous(breaks=seq(1985, 2050, 5)) +
      scale_y_continuous(breaks=seq(0, 80000, 5000)) +
      theme(axis.title.y = element_blank()) +
      theme(legend.position = "bottom") +
      labs(color=NULL)
    
ggplotly(GVA, tooltip = c("text"))

})

output$Mass_outflows <- renderPlotly({
  
  shiny::validate(
    need(input$product, "")) 
  
  shiny::validate(
    need(input$scenario, "")) 
  
  Filtered_table <- reactive({
    filtered <- filter(Dataset_mass_outflow, between(year, input$Range[1], 
                                        input$Range[2]),
                       product %in% input$product,
                       scenario %in% input$scenario)
})
  
GVA <- ggplot(Filtered_table(),
                aes(x= year, y = value, group = scenario, text=paste("Product:",product, "<br />Value:",value, "<br />Year:",year))) +
    geom_line(aes(color=scenario, linetype=scenario), linewidth = 1.3) +
    scale_color_manual(values = c("#D9262E", "#FF9E16", "#FFCC00", "#00AF41")) +
    theme_minimal() +
    theme(axis.title.x = element_blank()) +
    scale_x_continuous(breaks=seq(1985, 2050, 5)) +
    scale_y_continuous(breaks=seq(0, 25000, 5000)) +
    theme(axis.title.y = element_blank()) +
    theme(legend.position = "bottom") +
    labs(color=NULL)
  
  ggplotly(GVA, tooltip = c("text"))
  
}) 

output$Monetary_outflows <- renderPlotly({
  
  shiny::validate(
    need(input$product, "")) 
  
  shiny::validate(
    need(input$scenario, "")) 
  
  Filtered_table <- reactive({
    filtered <- filter(Dataset_monetary_outflow, between(year, input$Range[1], 
                                        input$Range[2]),
                       product %in% input$product,
                       scenario %in% input$scenario)
  })
  
  GVA <- ggplot(Filtered_table(),
                aes(x= year, y = value, group = scenario, text=paste("Product:",product, "<br />Value:",value, "<br />Year:",year))) +
    geom_line(aes(color=scenario, linetype=scenario), linewidth = 1.3) +
    scale_color_manual(values = c("#D9262E", "#FF9E16", "#FFCC00", "#00AF41")) +
    theme_minimal() +
    theme(axis.title.x = element_blank()) +
    scale_x_continuous(breaks=seq(1985, 2050, 5)) +
    theme(axis.title.y = element_blank()) +
    theme(legend.position = "bottom") +
    labs(color=NULL)
  
  ggplotly(GVA, tooltip = c("text"))
  
}) 

}

# %>% layout(legend = list(orientation = "h", x = 0.4, y = -0.2))

# Run the application 
shinyApp(ui = ui, server = server)
