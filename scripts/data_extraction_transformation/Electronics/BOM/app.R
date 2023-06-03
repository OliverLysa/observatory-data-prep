#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.

#### Libraries ####
library(readxl)
library(tidyverse)
library(dplyr)
library(treemap)
library(shiny)
require(shinyWidgets)
library(d3treeR)

options(scipen=999)

# Import data
BOM <- read_excel("./Extension_workbook.xlsx", 
                  sheet = "BOM_longform") 

BOM$Model <- gsub("[()]", "", BOM$Model)

BOM <- as.data.frame(sapply(BOM, function(x) gsub("\"", "", x)))

BOM$Value <- as.numeric(as.character(BOM$Value))

BOM <- BOM %>%
  filter(Component != "Total mass (g)", 
         Material != "Total mass (g)",
         Product == "Laptop",
         Model == "Apple Macbook pro 15.4 A1286 2011")

# Define UI for application that draws a histogram
ui <- fluidPage(
  # Application title
  titlePanel("Bill of materials"),
  # Sidebar 
  sidebarLayout(sidebarPanel(
    selectInput(
      inputId = "Product",
      label = "Product",
      choices = c(unique(as.character(BOM$Product))),
      selected = "Laptop"
    ),
    selectInput(
      inputId = "Model",
      label = "Model",
      choices = c(unique(as.character(BOM$Model))),
      selected = "Apple Macbook pro 15.4 A1286 2011"
    ),),
    # Show a plot of the generated distribution
    mainPanel(
      d3tree3Output("tree")
    )
  )
)

server <- function(input, output) {
  
output$tree <- renderD3tree3({
    
    data <- reactive({
      filtered <- filter(BOM, Model == input$Model, 
                         Product == input$Product)
      
    })
    
    d3treeR::d3tree3(treemap::treemap(data(),
                             index = c("Component", "Material"),
                             vSize = "Value",
                             vColor = "Value",
                             type = "value",
                             aspRatio=5/3,
                             draw = FALSE),
            rootname = "Composition")
    
  })
  
}

shinyApp(ui, server)
