# CE observatory

*Author*: Oliver Lysaght (oliverlysaght\@icloud.com)

# Table of contents

# Purpose

A collection of scripts to:

1.  extract raw data from public official and emerging sources (incl. via API, web scraping and programmatic download requests) identified through a [dataset review](https://docs.google.com/spreadsheets/d/11jO8kaYktQ1ueMY1iJoaCl1dJU8r6RDfyxICPB1wFqg/edit#gid=795733331);

2.  transform these through steps including:

    1.  cleaning and reformatting;
    2.  grouping and summarising;
    3.  mapping to a central classification;
    4.  data validation and unknown value estimation;
    5.  calculating key variables/metrics; and

3.  export cleaned data outputs to an open source PostGreSQL database (supabase) for storage.

Data outputs from these scripts are used to populate the ce-observatory - a dashboard providing for specific resource-product-industry categories, a detailed description of current baseline material and monetary flows alongside wider impacts alongside the means to make comparison with alternative circular economy configurations. The ce-observatory can be viewed at the following URL:

# How to use

## Software requirements and setup

Scripts in this repository are largely written in the programming language R. Please see [here](https://rstudio-education.github.io/hopr/starting.html) for more information on running R scripts and computer software requirements. The version of R and packages used are listed in the package_version file. Required packages are listed at the top of each script. Files are packaged within an R Project with relative file paths used to call data inputs and functions. These can be most easily navigated and ran within the R Studio IDE, though this can also be done in the terminal/command line.

The Python scripting language has also been used as part of the project in cases of superior performance or providing functions not otherwise available in R. Python scripts are largely presented within [Jupyter Notebooks](https://jupyter.org/install) - an open source IDE that requires installing the jupyter-notebook package in your Python environment, more information about which can be found [here](https://www.python.org/downloads/). In some cases, .py Python scripts are also used. These can be viewed and modified in a code editor such as Visual Studio Code and ran in the terminal/command line.

# Folder and file descriptions

## raw_data

Raw data inputs downloaded from a variety of sources

## intermediate_data

In a few cases, processing steps require exporting data outputs from the R/Python environments for processing in excel and reimporting. An example is the mapping tool used to convert 14-category electronics data captured in UK WEEE EPR datasets to the 54-category UNU-key classification used in presenting data on the electronics page. 'Intermediate' data files which undergo this type of processing are stored here.

## cleaned_data

Cleaned data outputs derived from raw and intermediate data files following processing in R, Python and/excel and which are added to the postgresql database backend for the observatory dashboard. Within the dashboard environment, cleaned data files may undergo additional processing such as on-the-fly aggregation or division of variables.

## scripts

### functions.R

A collection of regularly used functions across all other R scripts not otherwise provided in R packages.

### electronics

#### 000_classification_matching.R

The observatory dashboard presents data on electronics using two classifications:

1.  A 54 category '[UNU-KEY'](https://github.com/OliverLysa/observatory/blob/main/classifications/classifications/UNU.xlsx) classification (Wang et al., 2012; [Forti, Baldé and Kuehr, 2018](https://collections.unu.edu/eserv/UNU:6477/RZ_EWaste_Guidelines_LoRes.pdf)) - the objective of which is to group products by 'similar function, comparable material composition (in terms of hazardous substances and valuable materials) and related end-of-life attributes...in addition to...a homogeneous average weight and life-time distribution' ([Baldé *et al.* 2015](https://i.unu.edu/media/ias.unu.edu-en/project/2238/E-waste-Guidelines_Partnership_2015.pdf)); and
2.  A 14 category classification used by public authorities in the UK to report EEE/WEEE-related data against.

##### Inputs

-   UNU-HS6 correspondence table ([Baldé *et al.* 2015](https://i.unu.edu/media/ias.unu.edu-en/project/2238/E-waste-Guidelines_Partnership_2015.pdf))
-   CN8 codes
-   Prodcom codes
-   UKU14-UNU54 interactive mapping tool ([Stowell, Yumashev et al. 2019)](https://www.research.lancs.ac.uk/portal/en/datasets/wot-insights-into-the-flows-and-fates-of-ewaste-in-the-uk(3465c4c6-6e46-4ec5-aa3a-fe13da51661d).html)

##### Workflow

The [script](https://github.com/OliverLysa/observatory/blob/main/scripts/classification_matching/UNU_classification_matching.R) imports stand-alone classifications and a correspondence table published in the literature and makes an expanded correlation table to help move between the data sources drawn on. It takes the following steps:

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

5.  Links to the UK-14 classification using concordance table from [Stowell, Yumashev et al. (2019)](https://www.research.lancs.ac.uk/portal/en/datasets/wot-insights-into-the-flows-and-fates-of-ewaste-in-the-uk(3465c4c6-6e46-4ec5-aa3a-fe13da51661d).html)

##### Outputs

-   CSV of extended concordance table linking the UKU14, UNU54, HS6, CN8, Prodcom and SIC classifications

#### 001_domestic_production.R

Script extracts UK domestic production data from the annual ONS publication.

##### Inputs

-   [ONS Prodcom data](https://www.ons.gov.uk/businessindustryandtrade/manufacturingandproductionindustry/bulletins/ukmanufacturerssalesbyproductprodcom/2021results) (2008-20) and [2021 onwards](https://www.ons.gov.uk/businessindustryandtrade/manufacturingandproductionindustry/datasets/ukmanufacturerssalesbyproductprodcom)
-   Prodcom codes for the electronics sector derived from 000_classification_matching.R

##### Workflow

1.  Imports the UK ONS Prodcom datasets published by the ONS as multi-page spreadsheets, binds all sheets to create a single table, binds the 2008-2020 and 2021 data and exports full dataset for use across product categories
2.  Extracts data for prodcom codes specific to electronics, cleans data, summarises by UNU-KEY and puts into tidy format

##### Outputs

-   CSV of UK prodcom data across all available divisions (\< 33) in tidy format
-   CSV of domestic production data summarised by UNU in tidy format

#### 002_international_trade.R

Script extracts international trade data from the UKTradeInfo API using the 'uktrade' R package/wrapper.

##### Inputs

-   CN8 trade codes derived from 000_classification_matching.R script
-   Extractor function in functions script

##### Workflow

1.  Isolates list of CN8 codes from classification database for codes of interest
2.  Uses a for loop to iterate through the trade terms and extract trade data using the 'uktrade' extractor function/wrapper to the UKTradeInfo API and print results to a single dataframe (this can take some time to run)
3.  Sums results grouped by year, flow type, country of source/destination, trade code as well as by year, flow type and trade code (where country detail is not required)

##### Outputs

-   CSV of trade data (imports and exports) by CN8 code
-   CSV of trade data by UNU-Key, including broken-down by country
-   CSV of trade data by UNU-Key, without country breakdown

#### 003_total_inflows.R

##### Apparent consumption method

<details>

<summary>More info: Apparent consumption</summary>

The most widely established methodological framework for measuring material resource flows at a national level is the Economy-Wide Material Flow Accounting (EW-MFA) system ([Eurostat, 2018](https://seea.un.org/sites/seea.un.org/files/ks-gq-18-006-en-n.pdf)) which also underpins the SNA SEEA Material Flow Accounts (SNA-SEEA-MFA) (Lysaght *et al.* 2022).

In the language of these statistical systems, in a closed economy or at the global level, the sum of domestic resource extraction (DE) is equivalent to consumption-based material flow indicators such as domestic material consumption (DMC) or raw material consumption (RMC) as well as their equivalent input-based indicators such as direct material input (DMI) and Raw Material Input (RMI) as all trade flows net out.

Domestic Material Consumption (DMC) is a headline indicator derived from the EW-MFA and SEEA-CF-MFA systems. It is currently the most widely used material flow-based indicator at the core of national statistical reporting on material flows. DMC is calculated by summing the used fraction of domestically extracted and harvested materials and the weight of imported raw materials, semi-finished and manufactured products, while excluding the weight of exported raw materials, semi-finished and manufactured products. DMC can therefore be written as:

$$DE + PtB$$

Where *DE* is domestic extraction and *PtB* defines the physical trade balance of *Im* i.e. imports and *Ex* i.e. exports. DMC excludes hidden flows throughout. A closely linked indicator, Direct Material Input (DMI) is based on the same methodology but incorporates the materials mobilised or used in the production of exported goods and services ([OECD, 2008](https://www.oecd.org/environment/indicators-modelling-outlooks/MFA-Guide.pdf)).

This methodology can be applied at a sub-national level too (albeit entirely within the confines of the technosphere) by summing domestic production and PtB, which is often referred to as an 'apparent consumption' method (e.g. Gray, 2021).

</details>

###### Inputs

-   Prodcom data summarised by UNU (output of script 001)
-   Trade data summarised by UNU (output of script 002)

###### Workflow

1.  Import prodcom and trade data summarised by UNU to compiled domestic production, imports and exports
2.  As Prodcom includes suppressed values to protect confidentiality ([ONS, 2018](https://www.ons.gov.uk/businessindustryandtrade/manufacturingandproductionindustry/methodologies/ukmanufacturerssalesbyproductsurveyprodcomqmi)) - the omission of which will present a data gap - omitted values are estimated. Following V.M. van Straalen (2017), a ratio is calculated between units exported (generally not suppressed) and units produced for years for which data is available. Where values are available in adjacent years, a straight line projection is used. Otherwise, a median is taken across these ratios and applied to the years for which data is missing based on a calculation of export units/ratio = prodcom units.
3.  Key indicators and aggregates are calculated
4.  Data exported in CSV

###### Outputs

-   A CSV combining domestic production, import and export data, as well as the following indicators:
    -   Total imports - sum of EU and non-EU source imports
    -   Total exports - sum of EU and non-EU source exports
    -   Net trade balance - Imports - exports i.e. PtB
    -   Apparent consumption - domestic_production + total imports - total exports
    -   Apparent output - domestic production + total exports
    -   Apparent input - domestic production + total imports
    -   Material import dependency - The proportion of units imported of imports plus exports

##### Placed on the market

###### Inputs

-   Environment Agency placed on market (POM) data

###### Workflow

1.  [Extracts](https://github.com/OliverLysa/observatory/blob/main/scripts/data_extraction_transformation/Electronics/environment_agency/On_the_market.R) placed on market data from Environment Agency EPR spreadsheet, binds data from across sheets, pivot to long-format and exports as a consolidated file

###### Outputs

-   Compiled POM data 2007 onward

#### 004_mass_conversion.R

Script converts unit-level inflow data into mass equivalents e.g. tonnes of laptops and tablets each year using 'bill of materials' (BoM) data.

A BoM is a hierarchical data object providing a list of the raw materials, components and instructions required to construct, manufacture, or repair a product. BoMs are generally used by firms to communicate information about a product as it moves along a value chain in order to help navigate regulations, efficiently manage inventory and to support product life-cycle assessments. Utilising component and material shares captured within a BoM data object alongside corresponding information on the volume/mass of flows (and stocks) of products/components, makes it possible to move between material, component and product flows (and stocks) at the micro level.

##### Inputs

-   Outputs of 003_total_inflows.R
-   Babbitt *et al* 2019

##### Workflow

1.  Extracts BoM data from Babbitt *et al* 2019 and assigns these to UNU categories, assuming homogeneity of composition in each category
2.  Apply the mass trend data from van Straalen (2017) to simulate trends over time

##### Outputs

-   

#### 005_stock_outflow_calculation.R

Script calculates stock and outflow variables using inflow and lifespan data inputs.

##### Inputs

-   Lifespan data by UNU category transferred from life-time profiles in the Netherlands, France, Belgium and Italy ([CIRCABC, 2023](https://circabc.europa.eu/ui/group/636f928d-2669-41d3-83db-093e90ca93a2/library/8e36f907-0973-4bb3-8949-f2bf3efeb125/details)). Loss functions modelled after a Weibull distribution ('a continuous probability distribution that, when used for stock and flow models, can be described as modelling the population given a variable and time-dependent failure rate.') ([ProSUM, 2017](https://www.prosumproject.eu/sites/default/files/170601%20ProSUM%20Deliverable%203.3%20Final.pdf)).
-   Inflow data in unit and mass terms

<details>

<summary>Lifespans as an input into MFA</summary>

At its simplest, a lifespan refers to a specific interval of time an object exists in a particular form (see NICER overview). Here, 'Lifetime seeks to capture the period after a product has been sold and stays in households or businesses until it is disposed of. This includes 'the dormant time in sheds and the exchange of second-hand equipment between households and businesses within the country'. Lifespan information can input into material stock and flow accounting, life-cycle costing and linked assessments of impact in various ways. For instance, material stock accounting can take a bottom-up approach based on item inventories and material intensities (e.g. Wiedenhofer *et al.* 2015), or be estimated from the top-down based on inflow data and estimated lifespan distributions as in delay/survival models (e.g. [Fishman *et al.* (2014)](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4251510/).

As an example, the ONS and most National Statistical Institutions (NSIs) estimate the monetary value of non-financial assets as part of national balance sheets using a perpetual inventory method (PIM). This involves starting with a benchmark asset monetary value and accumulating asset purchases through gross fixed capital formation over their estimated lifetime (based on ad-hoc research e.g., [asset lives study](https://www.niesr.ac.uk/publications/academic-review-asset-lives-uk)) via an assumed capital retirement distribution to estimate *gross* capital stocks. From this, a depreciation function is used to estimate the *net* capital stock (Dey-Chowdhury, 2009), with this further step taken because of the monetary representation of values.

Loss functions modelled after a Weibull distribution ('a continuous probability distribution that, when used for stock and flow models, can be described as modelling the population given a variable and time-dependent failure rate.') ([ProSUM, 2017](https://www.prosumproject.eu/sites/default/files/170601%20ProSUM%20Deliverable%203.3%20Final.pdf)). A variable Y \> 0 represents time until an event from a particular origin. Y is variously referred to as survival time, event time, failure time and duration.

-   Values in a **hazard function** (h(y) reflect the probability that an event occurs in a period of time.

-   Values in a **cumulative distribution function (CDF)** F(y) reflect the probability that an event occurs at or before time y.

-   Values in a **cumulative survival function (CSF)** S(y) reflect the probability that an event occurs after time y (i.e. the inverse of the CDF).

<https://onlinelibrary.wiley.com/doi/abs/10.1111/jiec.12551> <https://www.sciencedirect.com/science/article/abs/pii/S0959652618339660>

</details>

##### Workflow

1.  Extract lifespan/residence-time data
2.  Input prioritisation
3.  Calculate mean and median from Weibull parameters
4.  Compute distributions from lifespan parameters in CDF form
5.  Imports benchmark stock data
6.  Iterate over products' inflow data by year and lifespan parameters to calculate stock and outflows

##### Outputs

-   A spreadsheet containing inflow, stock and outflow data by UNU-Key by year
-   Outflows calculated as the sum of discarded products entering the stock in each historic year multiplied by its lifetime distribution probability
-   Net change in stock between periods equals the difference between the total inflows and outflows.

$$
K(t) = I(t)-O(t)
$$

where K(t) is the change and I(t) and O(t) are the corresponding inflows and outflows in that year, respectively. This net change is added to the stock level in year t-1

#### 006_outflow_routing.R

##### Inputs

-   Disposal:

    -   Waste Data Interrogator

-   

##### Workflow

1.  Calculate collection
    1.  Sum of:
        1.  collection by PCS members across EEE/WEEE categories
        2.  market-driven resale:
        3.  direct reuse/resale through commercial and domestic routes
        4.  Warranty returns
        5.  Legal exports of WEEE
2.  Fly-tipping data (white goods) (Defra) and Illegal dumping (EA)
3.  
4.  Material recycled - Mass of waste produced that is recycled and re-enters the economic system.
5.  Material remanufactured - Mass of waste produced that is remanufactured and re-enters the economy system.
6.  Material reused -
7.  Material repaired - Fixing something that is broken or unusable so it can be used for its original purpose.
8.  Data reformatted and restructured to calculate derived aggregates using end-of use mix % multiplied by an ordinal score, combined within a simple linear combination to produce CE-score metric
9.  Compares recycling flows in relation to waste arisings of the same material/source.

##### Outputs

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

<details>

<summary>Intensity ratios</summary>

At its most basic, a measure of efficiency or productivity tells us about a relationship in terms of scale between an output and an input. Singular measures of resource efficiency/productivity (as opposite to combined measures e.g. total factor productivity) generally seek to track the effectiveness with which an economy or sub-national process uses resource inputs to generate material or service outputs or anthropocentric value of some description.

Economic-physical productivity i.e. the money value of outputs per mass unit of material resource inputs. At national level, can be measured from production perspective (GDP/DMC or DMI), or can be measured from consumption perspective (GDP/RMC or RMI). Other indicators could be the amount of waste generated in relation to economic output, or alternatively in relation to resource inputs/stocks.

</details>

#### 008_emissions.R

-   Production emissions

-   Consumption emissions

#### 009_stacked_chart.R

#### 010_bubble_chart.R

#### 011_sankey_chart.R

#### 012_ifixit.R

-   Product characteristics - Product reparability (time required for disassembly, products meeting certain score of reparability), product failures.

#### 013_open_repair.R
