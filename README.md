# CE observatory

*Author*: Oliver Lysaght

*Date of last update*: 2023-05-31

# Table of contents

# Purpose

A collection of scripts for:

1.  extracting raw data from public official and emerging sources (incl. via API, web scraping and programmatic download requests); and

2.  processing these incl. cleaning, validation, outlier replacement and unknown value estimation to populate the ce-observatory - a UK national CE-observatory dashboard for description of current baseline and comparison of alternative target future circular economy configurations for specific resource-product-industry categories.

The ce-observatory can be viewed at the following URL:

# How to use

## Software requirements

Scripts are written in the programming languages R and Python.

# Folders

## Raw data

Raw data files downloaded from sources

## Cleaned data

Cleaned data files, derived from raw data files following cleaning and tidying. Enclosed intermediate files may undergo additional processing through variable calculation scripts to input to the observatory dashboard.

## Scripts

### Classification matching

Script imports classifications and makes correlation tables for moving between these.

1.  Imports the UNU-HS6 correspondence table from Balde *et al.*
2.  Imports the CN8 classification for 8-digit trade data
3.  Joins CN8 to UNU_2\_HS6 to create a [correspondence table](https://github.com/OliverLysa/observatory/blob/main/classifications/concordance_tables/UNU_2_CN8_2_PRODCOM_SIC.csv)
4.  Links to prodcom and the SIC 2 and 4-digit level

### Trade data

Script extracts trade data from the UKTradeInfo website using the 'uktrade' R package.

1.  Isolates list of CN8 codes from classification database for objects of interest
2.  Uses a for loop to iterate through the trade terms, extract data using the 'uktrade' extractor function/wrapper to the UKTradeInfo API and print results to a single dataframe
3.  Sums results grouped by year, flow type and trade code

### Prodcom

1.  Selects SIC codes from the classification table to define which sheets are imported
2.  Extracts relevant sheets in the ONS prodcom dataset, cleans data and put into tidy format

### Apparent consumption

1.  Left join summary trade and UNU classification to get flows by UNU
2.  Filter prodcom variable column and mutate values
3.  Pivot wide to create aggregate values then re-pivot long to estimate key aggregates
4.  Indicators based on <https://www.resourcepanel.org/global-material-flows-database>

### Placed on the market

1.  [Extracts](https://github.com/OliverLysa/observatory/blob/main/scripts/data_extraction_transformation/Electronics/environment_agency/On_the_market.R) placed on market data from Environment Agency EPR datasets

### Mass conversion & bill of materials 

1.  Extracts BoM data from Babbitt *et al* 2019 and mass trend data from Balde *et al.*
2.  Convert BoM to Sankey format

### Lifespan

1.  Extract lifespan/residence-time data
2.  Calculate mean and median from Weibull parameters
3.  Compute distributions from lifespan parameters
4.  Imports stock data
5.  Iterate over products' parameters to calculate stock and outflows

### Outflow routing

1.  Import outflow routing estimates and map to wire diagram categories

2.  Data reformatted and restructured to calculate derived aggregates using simple linear combination to produce CE-score metric

### GVA

Scripts for sources capturing monetary data additional to prodcom/trade across production and consumption perspectives. We are looking at products which fall largely within the SIC codes 26-29. We start by looking at 2-digit GVA data for these codes GVA for the products in scope. This could include not only data from the manufacturing sector, but also from repair and maintenance activities associated with those products as captured below. This allows us to capture structural shifts at the meso-level.

Extracts GVA data and maps to UNU codes

\# 33.12	Repair of machinery 
# 33.13	Repair of electronic and optical equipment
# 33.14	Repair of electrical equipment 
# 95.1 Repair of computers and communication equipment
# 95.11	Repair of computers and peripheral equipment
# 95.12	Repair of communication equipment 
# 95.21	Repair of consumer electronics
# 95.22	Repair of household appliances and home and garden equipment
# 77.3	Renting and leasing of other machinery, equipment and tangible goods

### Emissions

-   Production emissions

-   Consumption emissions

# Contact
