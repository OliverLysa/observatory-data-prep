# *******************************************************************************
# Extraction functions
#********************************************************************************

# Read all sheets of an excel file
read_excel_allsheets <- function(filename, tibble = FALSE) {
  # but if you would prefer a tibble output, pass tibble = TRUE
  sheets <- readxl::excel_sheets(filename)
  x <- lapply(sheets, function(X) readxl::read_excel(filename, sheet = X))
  if(!tibble) x <- lapply(x, as.data.frame)
  names(x) <- sheets
  x 
}

# Read all sheets of ABS excel file
read_excel_allsheets_ABS <- function(filename, tibble = FALSE) {
  # but if you would prefer a tibble output, pass tibble = TRUE
  sheets <- readxl::excel_sheets(filename)
  x <- lapply(sheets, function(X) readxl::read_excel(filename, sheet = X, skip = 6))
  if(!tibble) x <- lapply(x, as.data.frame)
  names(x) <- sheets
  x
}

# Read all sheets of ABS excel file
read_excel_allsheets_BEIS_emissions_SIC <- function(filename, tibble = FALSE) {
  # but if you would prefer a tibble output, pass tibble = TRUE
  sheets <- readxl::excel_sheets(filename)
  x <- lapply(sheets, function(X) readxl::read_excel(filename, sheet = X, skip = 4))
  if(!tibble) x <- lapply(x, as.data.frame)
  names(x) <- sheets
  x
}

# Use the OTS package to extract trade data from the UKTradeInfo API
extractor <- function(x) {
  trade_results <-
    load_ots(
      # The month argument specifies a range in the form of c(min, max)
      month = c(200101, 202212),
      flow = NULL,
      commodity = c(x),
      country = NULL,
      print_url = TRUE,
      join_lookup = FALSE,
      output = "df"
    )
  trade_results <- trade_results %>%
    mutate(search_code = x)
  
  return(trade_results)
}

# Use the comtrade API to extract historic trade data
# Define get comtrade function
get.Comtrade <- function(url="http://comtrade.un.org/api/get?"
                         ,maxrec=50000
                         ,type="C"
                         ,freq="A"
                         ,px="HS"
                         ,ps="now"
                         ,r
                         ,p
                         ,rg="all"
                         ,cc="TOTAL"
                         ,fmt="json"
)
{
  string<- paste(url
                 ,"max=",maxrec,"&" #maximum no. of records returned
                 ,"type=",type,"&" #type of trade (c=commodities)
                 ,"freq=",freq,"&" #frequency
                 ,"px=",px,"&" #classification
                 ,"ps=",ps,"&" #time period
                 ,"r=",r,"&" #reporting area
                 ,"p=",p,"&" #partner country
                 ,"rg=",rg,"&" #trade flow
                 ,"cc=",cc,"&" #classification code
                 ,"fmt=",fmt        #Format
                 ,sep = ""
  )
  
  if(fmt == "csv") {
    raw.data<- read.csv(string,header=TRUE)
    return(list(validation=NULL, data=raw.data))
  } else {
    if(fmt == "json" ) {
      raw.data<- fromJSON(file=string)
      data<- raw.data$dataset
      validation<- unlist(raw.data$validation, recursive=TRUE)
      ndata<- NULL
      if(length(data)> 0) {
        var.names<- names(data[[1]])
        data<- as.data.frame(t( sapply(data,rbind)))
        ndata<- NULL
        for(i in 1:ncol(data)){
          data[sapply(data[,i],is.null),i]<- NA
          ndata<- cbind(ndata, unlist(data[,i]))
        }
        ndata<- as.data.frame(ndata)
        colnames(ndata)<- var.names
      }
      return(list(validation=validation,data =ndata))
    }
  }
}

# *******************************************************************************
# Wrangling functions
# *******************************************************************************

# Clean prodcom sheets
clean_prodcom <- function(df) {
    df %>% drop_na(1) %>%
    clean_names() %>%
    rename("Variable" = 1) %>%
    # filter(!grepl('Note', Variable)) %>%
    filter(!grepl("type change",Variable)) %>%
    filter(Variable != c("SIC Totals and Non Production Headings"))
    
}

# Add leading 0s to unu_key column up to 4 digits to help match to other data
# BoM_BEIS$UNU <- str_pad(BoM_BEIS$UNU, 4, pad = "0")


#Get first date in the time series
first_date <- function(x){
  a <- floor(min(x, na.rm = TRUE))
}

#Get latest date in the time series by specifying data frame and column e.g. RMC$Date
latest_date <- function(x){
  a <- ceiling(max(x, na.rm = TRUE))
}

#Get penultimate date in the time series by specifying data frame and column e.g. RMC$Date
penultimate_date <- function(x){
  a <- ceiling(max(x, na.rm = TRUE)-1)
}

#Get value in column of choice associated with latest date in time series (a = dataset e.g. RMC, x = column name for value of interest e.g. Quantity, b = date column)
latest_value <- function(a, x, b){
  e <- with(a, x[which.max(b)])
}

#Get penultimate value in column of choice associated with latest date in time series (a = dataset e.g. RMC, x = column name for value of interest e.g. Quantity, b = date column)
penultimate_value <- function(a, x, b){
  a <- with(a, x[which.max(b)-1])
}

# Shorten chart units
addUnits <- function(n) 
{
  labels <- ifelse(n < 1000, n,  # less than thousands
                   ifelse(n < 1e6, paste0(round(n/1e3), 'k'),  # in thousands
                          ifelse(n < 1e9, paste0(round(n/1e6), 'M'),  # in millions
                                 ifelse(n < 1e12, paste0(round(n/1e6), 'M'), # in billions
                                 ))))
  return(labels)
}


# *******************************************************************************
# Renaming functions
# *******************************************************************************

# Import user-friendly names for codes
UNU_colloquial <- read_xlsx( 
  "./classifications/classifications/UNU_colloquial.xlsx") %>%
  dplyr::rename(product = unu_description)

# *******************************************************************************
# statistical functions
# *******************************************************************************

# *******************************************************************************
# Lifespans

# Calculate CDF from Weibull parameters
cdweibull <- function(x, shape, scale, log = FALSE){
  dd <- dweibull(x, shape= shape, scale = scale, log = log)
  dd <- 1-(cumsum(dd) * c(0, diff(x)))
  return(dd)
}

# From Weibull par inverse mixdist
weibullparinv <- function(shape, scale, loc = 0) 
{
  nu <- 1/shape
  if (nu < 1e-6) {
    mu <- scale * (1 + nu * digamma(1) + nu^2 * (digamma(1)^2 + 
                                                   trigamma(1))/2)
    sigma <- scale^2 * nu^2 * trigamma(1)
  }
  else {
    mu <- loc + gamma(1 + (nu)) * scale
    sigma <- sqrt(gamma(1 + 2 * nu) - (gamma(1 + nu))^2) * 
      scale
  }
  data.frame(mu, sigma, loc)
}

# *******************************************************************************
# Backcasting

# Function to reverse time
reverse_ts <- function(y)
{
  ts(rev(y), start=tsp(y)[1L], frequency=frequency(y))
}

# Function to reverse a forecast
reverse_forecast <- function(object)
{
  h <- length(object[["mean"]])
  f <- frequency(object[["mean"]])
  object[["x"]] <- reverse_ts(object[["x"]])
  object[["mean"]] <- ts(rev(object[["mean"]]),
                         end=tsp(object[["x"]])[1L]-1/f, frequency=f)
  object[["lower"]] <- object[["lower"]][h:1L,]
  object[["upper"]] <- object[["upper"]][h:1L,]
  return(object)
}
