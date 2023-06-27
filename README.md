# CE observatory

*Author*: Oliver Lysaght (oliverlysaght\@icloud.com)

Date of last update:

# Table of contents

# Purpose

A collection of scripts to:

1.  extract raw data from public official and emerging sources (incl. via API, web scraping and programmatic download requests) identified through a [dataset review](https://docs.google.com/spreadsheets/d/11jO8kaYktQ1ueMY1iJoaCl1dJU8r6RDfyxICPB1wFqg/edit#gid=795733331); and

2.  process/transform these, with steps including:

    1.  cleaning and reformatting;

    2.  mapping to a central classification;

    3.  grouping and summarising;

    4.  data validation (e.g. outlier replacement) and unknown value estimation;

    5.  calculating key variables/metrics; and

    6.  exporting and loading to the supabase backend being used to host observatory data.

in order to populate the ce-observatory - a UK national CE-observatory dashboard for description of current baseline and comparison of alternative target future circular economy configurations for specific resource-product-industry categories. The ce-observatory can be viewed at the following URL:

# How to use

## Software requirements and setup

Scripts are written in the programming languages R and Python. Please see [here](https://rstudio-education.github.io/hopr/starting.html) for more information on running R scripts and software requirements. R components are currently packaged within an R Project and relative file paths are used. These can be most easily interacted with using R Studio. See [here](https://www.python.org/downloads/) for the equivalent information for Python scripts used, which are contained in [Jupyter Notebooks](https://jupyter.org/install).

# Folder and file descriptions

## raw_data

Raw data inputs downloaded from sources

## cleaned_data

Cleaned data outputs derived from raw data files following processing in R or Python. Cleaned data files may undergo additional processing e.g. on the fly variable calculation within the dashboard environment subsequently.

## scripts

### functions.R

A collection of regularly used functions across all steps

### electronics

#### 000_classification_matching.R

Data is presented for electronics in the observatory dashboard categorised by the [UNU-54](https://github.com/OliverLysa/observatory/blob/main/classifications/classifications/UNU.xlsx) classification (Wang et al., 2012; [Forti, Baldé and Kuehr, 2018](https://collections.unu.edu/eserv/UNU:6477/RZ_EWaste_Guidelines_LoRes.pdf)). The objective of this classification system is to group products by 'similar function, comparable material composition (in terms of hazardous substances and valuable materials) and related end-of-life attributes...in addition to...a homogeneous average weight and life-time distribution' ([Baldé *et al.* 2015](https://i.unu.edu/media/ias.unu.edu-en/project/2238/E-waste-Guidelines_Partnership_2015.pdf)).

##### Inputs

-   UNU-HS6 correspondence table ([Baldé *et al.* 2015](https://i.unu.edu/media/ias.unu.edu-en/project/2238/E-waste-Guidelines_Partnership_2015.pdf))
-   CN8 codes
-   Prodcom codes
-   UKU14-CN correspondence table ([Stowell, Yumashev et al. 2019)](https://www.research.lancs.ac.uk/portal/en/datasets/wot-insights-into-the-flows-and-fates-of-ewaste-in-the-uk(3465c4c6-6e46-4ec5-aa3a-fe13da51661d).html)

##### Workflow

The [script](https://github.com/OliverLysa/observatory/blob/main/scripts/classification_matching/UNU_classification_matching.R) imports classifications and makes correlation tables for moving between classifications to then be able to link data. It takes the following steps:

1.  Imports UNU_HS6 correspondence table ([Baldé *et al.* 2015](https://i.unu.edu/media/ias.unu.edu-en/project/2238/E-waste-Guidelines_Partnership_2015.pdf))
2.  Joins UNU_HS6 to CN8 to create a [correspondence table](https://github.com/OliverLysa/observatory/blob/main/classifications/concordance_tables/UNU_2_CN8_2_PRODCOM_SIC.csv) for extracting UK trade data

<details>

<summary>More info: HS/CN classification</summary>

The 6 digit Harmonised Commodity Description and Coding System (HS) developed by the World Customs Organisation forms the basis of the 8 digit Combined Nomenclature (CN) and is relatively consistent with nomenclature systems for describing domestic production drawn on in the UK (Prodcom).

</details>

3.  Joins to the UK prodcom classification for extracting domestic production data

<details>

<summary>More info: Prodcom classification</summary>

Prodcom headings used in statistics on UK manufacturing production draw on up to eight-digit numerical codes, the first six of which align with the Classification of Products by Activity (CPA) and with two additional digits for further detail. The CPA coding frame for describing products (goods and services) extends the SIC classification by two further digits in alignment with the UN Central Product Classification (CPC).

</details>

4.  Joins to the SIC 2 and 4-digit level to create sector-level aggregates and link to GVA and emissions data to create productivity and intensity ratios

<details>

<summary>More info: SIC classification</summary>

The UK National Accounts (UKNA) describe national production, income, consumption, accumulation and wealth, and are the basis from which key national-level aggregates and indicators such as gross domestic product (GDP) are derived. The UK accounts are compiled by the UK ONS largely in accordance with the System of National Accounts (SNA), an internationally agreed standard set of recommendations introduced in the 1950s on how to compile national accounts covering agreed concepts, definitions, classifications and accounting rules. The SNA broadly separates economic actors into producing units (mainly corporations, nonprofit institutions and government units) and consuming units (mainly households). On the production side and as part of the UKNA, industries are classified into branches of homogeneous institutional units producing goods and services described under a given heading of a product classification (Lequiller and Blades, 2014). The Standard Industrial Classification (SIC) 2007, the first version of which was introduced in 1948 and which has since been revised several times, is a hierarchical 5 digit framework used in the UKNA to classify businesses by the type of economic activity they engage in.

Companies are self-assigned to at least one (and up to four) of a condensed list of SIC codes (\~730) when registering with the UK Companies House and again, but to a single code associated with their highest valueadded activity (principal activity), for most statistical returns (Jacobs and O'Neill, 2003). The UK SIC (2007) is based on the 4 digit International Standard Industrial Classification of All Economic Activities (ISIC) developed by the UN (ONS, 2009) while mirroring the NACE Rev. 2 classification developed by Eurostat and adding a further digit of detail where deemed useful. Overall, the UK SIC (2007) consists of 21 sections, 88 divisions, 272 groups, 615 classes and 191 subclasses, with a revision to the current structure planned in 2023.

</details>

5.  Links to the UK-14 classification used for EEE/WEEE Directive using concordance table from [Stowell, Yumashev et al. (2019)](https://www.research.lancs.ac.uk/portal/en/datasets/wot-insights-into-the-flows-and-fates-of-ewaste-in-the-uk(3465c4c6-6e46-4ec5-aa3a-fe13da51661d).html)

##### Outputs

-   UNU54 to HS6, CN8, Prodcom, SIC and UKU14 concordance table

#### 001_domestic_production.R

##### Input

##### Workflow

1.  Selects SIC codes from the classification table to define which sheets are imported
2.  Extracts relevant sheets in the ONS prodcom dataset, cleans data and puts into tidy format
3.  Validation and unknown values estimated
    1.  In some cases, values are suppressed

##### Output

#### 002_international_trade.R

Script extracts trade data from the UKTradeInfo website using the 'uktrade' R package.

##### Input

##### Workflow

1.  Isolates list of CN8 codes from classification database for codes of interest
2.  Uses a for loop to iterate through the trade terms, extract data using the 'uktrade' extractor function/wrapper to the UKTradeInfo API and print results to a single dataframe (this can take some time to run)
3.  Sums results grouped by year, flow type, country of source/destination, trade code

##### Output

#### 003_total_inflows.R

##### Apparent consumption

<details>

<summary>More info: Apparent consumption</summary>

There are a range of methodologies available for analysing material flows, the choice of which will affect final estimates (ONS, ). The most widely established methodological framework for measuring material resource flows at a national level is the Economy-Wide Material Flow Accounting (EW-MFA) system ([Eurostat, 2018](https://seea.un.org/sites/seea.un.org/files/ks-gq-18-006-en-n.pdf)) which underpins the SNA SEEA Material Flow Accounts (SNA-SEEA-MFA). In a closed economy or at the global level, the sum of domestic resource extraction (DE) is equivalent to consumption-based material flow indicators such as domestic material consumption (DMC) or raw material consumption (RMC) as well as their equivalent input-based indicators e.g., direct material input (DMI) and Raw Material Input (RMI) as all trade flows net out.

Domestic Material Consumption (DMC) is a headline indicator derived from the EW-MFA and SEEA-CF-MFA systems. It is currently the most widely used material flow-based indicator at the core of national statistical reporting on material flows. DMC is calculated by summing the used fraction of domestically extracted and harvested materials and the weight of imported raw materials, semi-finished and manufactured products, while excluding the weight of exported raw materials, semi-finished and manufactured products. 

DMC can therefore be written as:

Where *DE* is domestic extraction and *PtB* defines the physical trade balance of *Im* i.e. imports and *Ex* i.e. exports. DMC excludes hidden flows throughout. A closely linked indicator, Direct Material Input (DMI) is based on the same methodology but incorporates the materials mobilised or used in the production of exported goods and services ([OECD, 2008](https://www.oecd.org/environment/indicators-modelling-outlooks/MFA-Guide.pdf)).

This methodology can be applied at a sub-national level too, and is often referred to as an 'apparent consumption' method.

</details>

###### Workflow

1.  Left join summary trade and UNU classification to get flows by UNU
2.  Filter prodcom variable column and mutate values
3.  Pivot wide to create aggregate values then re-pivot long to estimate key aggregates
4.  Indicators based on <https://www.resourcepanel.org/global-material-flows-database>

###### Outputs

-   Material imports: Direct imports of materials as the weight of products crossing the border
-   Material exports:
-   domestic material input: Material requirement of production and consumption i.e. DE plus imports. Mass of raw materials extracted from the domestic territory, plus the physical weight of imports.
-   Physical trade balance (imports minus exports) (PTB) - Direct trade dependency in terms of material flows
-   Domestic Material Consumption - DE + PTB. Mass of raw materials extracted from the domestic territory, plus the physical weight of imports, minus the physical weight of exports. Differs from RMC by not taking the raw material equivalents of imports.
-   Raw Material Consumption (RMC) i.e. DE plus RTB - Mass of global raw material extraction associated with producing the goods and services consumed in England (not including hidden flows)
-   Material processed - Mass of domestic extraction, net imports and secondary materials.
-   Net addition to stocks - Mass of materials added to the economy's stock each year (gross additions) in buildings and other infrastructure, and materials incorporated into new durable goods such as cars, industrial machinery and household appliances, while old materials are removed from stock as buildings are demolished and durable goods disposed of.
-   Material import dependency - The proportion of materials used which derive from domestic extraction and material domestically reprocessed.

##### Placed on the market

###### Workflow

1.  [Extracts](https://github.com/OliverLysa/observatory/blob/main/scripts/data_extraction_transformation/Electronics/environment_agency/On_the_market.R) placed on market data from Environment Agency EPR datasets

#### 004_mass_conversion.R

The purpose of this script is to convert unit-level inflow data into mass equivalents e.g. tonnes of laptops and tablets each year using bill of materials (BoM data).

A BoM is a hierarchical data object providing a (potentially extensive) list of the raw materials, components and instructions required to construct, manufacture, or repair a product. BoMs are generally used by firms to communicate information about a product as it moves along a value chain in order to help navigate regulations, efficiently manage inventory and to support product life-cycle assessments. Utilising component and material shares captured within a BoM data object alongside corresponding information on the volume/mass of flows (and stocks) of products/components, makes it possible to move between material, component and product flows (and stocks) at the micro level.

##### Inputs

##### Workflow

1.  Extracts BoM data from Babbitt *et al* 2019 and mass trend data from Balde *et al.*
    1.  We assume homogeneity of the composition of products within each UNU after selecting a product archetype. We apply the trend in Balde *et al.* for years between X and X to simulate changes in trend into the future.
    2.  Can make the archetypal product profile more up to date
2.  Apply to unit-level flow data incl. using weightings
3.  Convert BoM to Sankey format

##### Output

##### Mass conversion

#### 005_stock_outflow_calculation.R

Generate stock and outflow estimates based on inflow and lifespan data. 'Lifespan' is a measure of how long materials and products are kept in circulation. Some historical lifespan data is available in, or can be derived from, existing literature and which varies in its presentation, definitions and methods employed (Oguchi et al. 2010). In some cases, lifespan point estimates such as a mean or median are provided, in other cases a range is given, and in others lifespan distribution parameters are made available. Care needs to be taken in transferring results, including accounting for difference in time and the place in which studies have been undertaken.

##### Inputs

<https://i.unu.edu/media/ias.unu.edu-en/project/2238/E-waste-Guidelines_Partnership_2015.pdf>

##### Workflow

1.  Extract lifespan/residence-time data
2.  Input prioritisation
3.  Calculate mean and median from Weibull parameters
4.  Compute distributions from lifespan parameters
5.  Imports benchmark stock data
6.  Iterate over products' parameters to calculate stock and outflows

##### Outputs

#### 006_outflow_routing.R

We know some outflow routes at a 14-category level from EA data.

##### Input

The NICER programme was ran in advance of the introduction of the Waste Tracking system across the UK.

##### Workflow

1.  Import outflow routing estimates and map to wire diagram categories
2.  Fly-tipping data (white goods) (Defra) and Illegal dumping (EA)
3.  EA WDI data
4.  Material recycled - Mass of waste produced that is recycled and re-enters the economic system.
5.  Material remanufactured - Mass of waste produced that is remanufactured and re-enters the economy system.
6.  Material reused -
7.  Material repaired - Fixing something that is broken or unusable so it can be used for its original purpose.
8.  Domestic Processed Output - The mass of materials used in the national economy before flowing into the environment, covering emissions to air, emissions to land (solid waste disposal), emissions to water, dissipative use of products (e.g. fertiliser) and dissipative losses (e.g. rubber losses from vehicles tyres).
9.  Data reformatted and restructured to calculate derived aggregates using end-of use mix % multiplied by an ordinal score, combined within a simple linear combination to produce CE-score metric
10. Compares recycling flows in relation to waste arisings of the same material/source.

#### 007_GVA.R

"Intensity indicators compare trends in economic activity such as value-added, income or consumption with trends in specific environmental flows such as emissions, energy and water use, and flows of waste. These indicators are expressed as either intensity or productivity ratios, where intensity indicators are calculated as the ratio of the environmental flow to the measure of economic activity, and productivity indicators are the inverse of this ratio." (SEEA-Environment Extensions, 2012, pg. 13).

##### Input

-   [Regional GVA figures](https://www.ons.gov.uk/economy/grossvalueaddedgva/datasets/nominalandrealregionalgrossvalueaddedbalancedbyindustry) - 2 digit

-   Up to 4-digit aGVA estimates provided in the ONS publication [Non-financial business economy, UK: Sections A to S](https://www.ons.gov.uk/businessindustryandtrade/business/businessservices/datasets/uknonfinancialbusinesseconomyannualbusinesssurveysectionsas). - 4 digit

-   Prodcom currently collates data for 232 industries at the 4 digit code level and covers SIC Divisions 8-33, whereas regional GVA figures cover 1-98 at a 2 digit level

##### Workflow

-   [Methodological options](https://docs.google.com/document/d/1jb01KOxCMkPIIc_za8DF5-2LLjh03HJv/edit?usp=sharing&ouid=100007595496292131489&rtpof=true&sd=true)

-   Extracts GVA data and maps to UNU codes

Scripts for sources capturing monetary data additional to prodcom/trade across production and consumption perspectives. We are looking at products which fall largely within the SIC codes 26-29. We start by looking at 2-digit GVA data for these codes GVA for the products in scope. This could include not only data from the manufacturing sector, but also from repair and maintenance activities associated with those products as captured below. This allows us to capture structural shifts at the meso-level.

At its most basic, a measure of efficiency or productivity tells us about a relationship in terms of scale between an output and an input. Singular measures of resource efficiency/productivity (as opposite to combined measures e.g. total factor productivity) generally seek to track the effectiveness with which an economy or sub-national process uses resource inputs to generate material or service outputs or anthropocentric value of some description.

Economic-physical productivity i.e. the money value of outputs per mass unit of material resource inputs. At national level, can be measured from production perspective (GDP/DMC or DMI), or can be measured from consumption perspective (GDP/RMC or RMI). Other indicators could be the amount of waste generated in relation to economic output, or alternatively in relation to resource inputs/stocks.

#### 008_emissions.R

-   Production emissions

-   Consumption emissions

-   Emissions intensity

#### 009_stacked_chart.R

#### 010_sankey_chart.R

#### 011_bubble_chart.R

#### 012_ifixit.R

-   Product characteristics - Product reparability (time required for disassembly, products meeting certain score of reparability), product failures.

#### 013_open_repair.R

#### 014_ebay.R

#### 015_policy_inputs.R
