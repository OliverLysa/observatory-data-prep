# 🚀 CE observatory data processing

*Author*: Oliver Lysaght (oliverlysaght\@icloud.com)

## WORK IN PROGRESS

# Purpose

*'Dashboards can be a powerful way of allowing access to large amounts of data, which can help people make decisions'* ([ONS, 2022](https://analysisfunction.civilservice.gov.uk/policy-store/top-tips-for-designing-dashboards/))

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

Scripts in this repository are largely written in the programming language R. Please see [here](https://rstudio-education.github.io/hopr/starting.html) for more information on running R scripts and computer software requirements. We use targets and renv packages for a reproducible environment, saved here. Files are packaged within an R Project with relative file paths used to call data inputs and functions. These can be most easily navigated and ran within the R Studio IDE, though this can also be done in the terminal/command line.

The Python scripting language has also been used as part of the project in cases where it offers better performance or provides functions not otherwise available in R. Python scripts are largely presented within [Jupyter Notebooks](https://jupyter.org/install) - an open source IDE that requires installing the jupyter-notebook package in your Python environment, more information about which can be found [here](https://www.python.org/downloads/). In some cases, .py Python scripts are also used. These can be viewed and modified in a code editor such as Visual Studio Code and ran in the terminal/command line.

## Updates

The observatory has been designed to incorporate new data as it becomes available to help with trend assessment, monitoring and evaluation. On the dashboard front-end, this is achieved with scheduled content updates via Contentful. On the back-end, this is achieved through automated R and Python scripts for data extraction and processing, followed by automated PostgreSQL scripts for data storage. In R, we use the package 'cronR' to execute cronjobs in the MacOS environment, with a daily re-run schedule. Imported data undergoes a structure validation and content validation check to reduce risk of build failure.

# Folder and file descriptions

## [raw_data](https://github.com/OliverLysa/observatory/tree/main/raw_data)

Raw data inputs downloaded from a variety of sources

## [intermediate_data](https://github.com/OliverLysa/observatory/tree/main/intermediate_data)

In a few cases, processing steps require exporting data outputs from the R/Python environments for processing in excel and reimporting. An example is the mapping tool used to convert 14-category electronics data captured in UK WEEE EPR datasets to the 54-category UNU-key classification used in presenting data on the electronics page. 'Intermediate' data files which undergo this type of processing are stored here.

## [cleaned_data](https://github.com/OliverLysa/observatory/tree/main/cleaned_data)

Cleaned data outputs derived from raw and intermediate data files following processing in R, Python and/excel and which are added to the postgresql database backend for the observatory dashboard. Within the dashboard environment, cleaned data files may undergo additional processing such as on-the-fly aggregation or division of variables.

## scripts

### [functions.R](https://github.com/OliverLysa/observatory/blob/main/scripts/functions.R)

A collection of custom user-defined functions regularly used throughout the data processing pipeline and not otherwise provided in R packages.

### electronics

Individual scripts encompass extraction and transformation steps.

#### [000_classification_matching.R](https://github.com/OliverLysa/observatory/blob/main/scripts/electronics/000_classification_matching.R)

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
6.  Exports data to CSV format

##### Outputs

-   CSV of extended concordance table linking the UKU14, UNU54, HS6, CN8, Prodcom and SIC classifications

------------------------------------------------------------------------

#### [001_domestic_production.R](https://github.com/OliverLysa/observatory/blob/main/scripts/electronics/001_domestic_production.R)

Script extracts UK domestic production data from the annual ONS publication. Estimation of missing values through interpolation and outlier replacement is undertaken in script 003.

##### Inputs

-   [ONS Prodcom data](https://www.ons.gov.uk/businessindustryandtrade/manufacturingandproductionindustry/bulletins/ukmanufacturerssalesbyproductprodcom/2021results) (2008-20) and [2021 onwards](https://www.ons.gov.uk/businessindustryandtrade/manufacturingandproductionindustry/datasets/ukmanufacturerssalesbyproductprodcom). Prodcom currently collates data for 232 industries at the 4 digit code level and covers SIC Divisions 8-33. 'Items within PRODCOM can be divided into three main categories (raw materials, industries' intermediate consumption and final consumer products)' ([Barrett *et al.* 2004](https://www.researchgate.net/publication/245912879_Development_of_Physical_Accounts_for_the_UK_and_Evaluating_Policy_Scenarios)).
-   Prodcom codes for the electronics sector derived from 000_classification_matching.R

##### Workflow

1.  Imports the UK ONS Prodcom datasets published by the ONS as multi-page spreadsheets, binds all sheets to create a single table, binds the 2008-2020 and 2021 data and exports full dataset for use across product categories
2.  Extracts data for prodcom codes specific to electronics, cleans data, summarises by UNU-KEY and puts into tidy format
3.  Backcasting - needed for accurate stock and outflow estimates
4.  Projections
5.  Exports data to CSV format

##### Outputs

-   CSV of UK prodcom data across all available divisions (\< 33) in tidy format
-   CSV of domestic production data summarised by UNU in tidy format

------------------------------------------------------------------------

#### [002_international_trade.R](https://github.com/OliverLysa/observatory/blob/main/scripts/electronics/002_international_trade.R)

Script extracts international trade data from the UKTradeInfo API using the 'uktrade' R package/wrapper.

##### Inputs

-   CN8 trade codes derived from 000_classification_matching.R script
-   Extractor function in functions script

##### Workflow

1.  Isolates list of CN8 codes from classification database for codes of interest
2.  Uses a for loop to iterate through the trade terms and extract trade data using the 'uktrade' extractor function/wrapper to the UKTradeInfo API and print results to a single dataframe (this can take some time to run)
3.  Sums results grouped by year, flow type, country of source/destination, trade code as well as by year, flow type and trade code (where country detail is not required)
4.  Backcasting - needed for accurate stock and outflow estimates
5.  Projections
6.  Exports data to CSV format

##### Outputs

-   CSV of trade data (imports and exports) by CN8 code
-   CSV of trade data by UNU-Key, including broken-down by country
-   CSV of trade data by UNU-Key, without country breakdown

------------------------------------------------------------------------

#### [003_total_inflows.R](https://github.com/OliverLysa/observatory/blob/main/scripts/electronics/003_total_inflows.R)

Script calculates total inflows based on the apparent consumption method (drawing on domestic production and trade data) and extracting placed on market data (PoM) from UK-level administrative data from the EEE/WEEE Extended Producer Responsibility Scheme. For the apparent consumption method, automated corrections are applied.

##### Apparent consumption method

<details>

<summary>More info: Apparent consumption</summary>

The most widely established methodological framework for measuring material resource flows at a national level is the Economy-Wide Material Flow Accounting (EW-MFA) system ([Eurostat, 2018](https://seea.un.org/sites/seea.un.org/files/ks-gq-18-006-en-n.pdf)) which also underpins the SNA SEEA Material Flow Accounts (SNA-SEEA-MFA) (Lysaght *et al.* 2022).

In the language of these statistical systems, in a closed economy or at the global level, the sum of domestic resource extraction (DE) is equivalent to consumption-based material flow indicators such as domestic material consumption (DMC) or raw material consumption (RMC) as well as their equivalent input-based indicators such as direct material input (DMI) and Raw Material Input (RMI) as all trade flows net out.

Domestic Material Consumption (DMC) is a headline indicator derived from the EW-MFA and SEEA-CF-MFA systems. It is currently the most widely used material flow-based indicator at the core of national statistical reporting on material flows. DMC is calculated by summing the used fraction of domestically extracted and harvested materials and the weight of imported raw materials, semi-finished and manufactured products, while excluding the weight of exported raw materials, semi-finished and manufactured products. DMC can therefore be written as:

$$DE + PtB$$

Where *DE* is domestic extraction and *PtB* defines the physical trade balance of *Im* i.e. imports and *Ex* i.e. exports. DMC excludes hidden flows throughout. A closely linked indicator, Direct Material Input (DMI) is based on the same methodology but incorporates the materials mobilised or used in the production of exported goods and services ([OECD, 2008](https://www.oecd.org/environment/indicators-modelling-outlooks/MFA-Guide.pdf)).

This methodology can be applied at a sub-national level too (albeit entirely within the confines of the technosphere) by summing domestic production and PtB, which is often referred to as an 'apparent consumption' method (e.g. Gray, 2021). A reliance on apparent consumption methodologies alone carry risk of obfuscating true global environmental impact of production and trade activities in the UK better captured through indicators such as 'raw material consumption' (RMC) and its equivalents. These seek to capture the full upstream used material extraction associated with consumption activities. At the same time, there remains a gap in the understanding of actual material flows through the UK economy and this work seeks to fill this gap.

</details>

###### Inputs

-   Prodcom data summarised by UNU (output of script 001)
-   Trade data summarised by UNU (output of script 002)
-   GDP forecasts

###### Workflow

1.  Import domestic production and trade data summarised by UNU
2.  As Prodcom includes **suppressed values** to protect confidentiality ([ONS, 2018](https://www.ons.gov.uk/businessindustryandtrade/manufacturingandproductionindustry/methodologies/ukmanufacturerssalesbyproductsurveyprodcomqmi)) and the omission of which will present a data gap, these values are estimated. To do so and following van Straalen *et al.* (2016), a ratio is calculated between units exported (generally not suppressed) and units produced for years for which data is available. Where values are available in any adjacent years within the available timeseries, linear interpolation is used. Otherwise, a median is taken across an available ratio and applied to the years for which data is missing based on a calculation of export units/ratio = prodcom units.
3.  **Detect outliers** at the level of domestic production, exports and imports by UNU through using a moving/rolling median absolute deviation (MAD) approach (runmad package). Outliers are replaced based on a straight line interpolation between values for years either side of the outlier.
4.  Key indicators and aggregates are calculated for all years 1990-2030.
5.  Future baseline values for UNUs are **forecasted** based on the observed relationship/ratio between per capita GDP in chained volume measures (CVM) and apparent consumption for the years for which data is available. While other variables such as household expenditure are likely to display a stronger relationship to apparent consumption of electronics, due to the availability of projections data for GDP as published by the UK OBR, GDP is used. For calculating the ratio from observed data, a chained volume measure of GVA and GDP is used to remove inflationary price effects, allowing for inter-temporal comparison in 'real' terms. A time-series forecasting approach is used to forecast future ratios between GDP and UNU-key. These ratios are then mutiplied by per-capita GDP forecasts derived from data published by the OBR and ONS to estimate future apparent consumption by UNU (at a unit-level).
6.  The same approach is used to estimate historic consumption back to 1990, as a time-series backcast based on the observed relationship between GDP and apparent consumption by UNU-key for years for which data is available. Observed historical population and GDP data is then used to calculate the unobserved apparent consumption by UNU-key based on a consumption ratio to per-capita GDP. This is done both to provide historical comparison, but also to improve the
7.  Exports data to CSV format

###### Outputs

-   A CSV combining domestic production, import and export data, as well as the following derived indicators in unit terms:
    -   Total imports = sum of EU and non-EU source imports
    -   Total exports = sum of EU and non-EU source exports
    -   Net trade balance = Imports - exports i.e. PtB
    -   Apparent consumption = domestic_production + total imports - total exports
    -   Apparent output = domestic production + total exports
    -   Apparent input = domestic production + total imports
    -   Import dependency = units imported / imports + exports

##### Placed on the market

###### Inputs

-   Environment Agency placed on market (POM) [data](https://www.gov.uk/government/statistical-data-sets/waste-electrical-and-electronic-equipment-weee-in-the-uk) - Specific to producers who are obligated to report under the WEEE Directive. Separate studies e.g. those under the WEEE Flows series - Valpak ([UK EEEFlows 2018](https://sp.demeter.zeus.gsi.gov.uk/Sites/aa12/RDIA/ResourceEffic/Waste%2520Prevention%2520Programme/Chapter%25208%2520-%2520Electronics/Readings/1.%2520Overview/ukeeeflow2018updatereport-final_1.pdf?Web=1)), WRAP ([WRAP (2016)](http://www.wrap.org.uk/sustainable-electricals/esap/re-use-and-recycling/report/weee-market-flow-model-and-report) -- and separately, an [independent review](#0) (2020) by Anthesis, provide estimates of EEE onto the market trying to account for unregistered companies and those exempt from current regulations. Differences don't seem significant (all for the year 2017): EA official collection figures: 1,615k tonnes, Valpak: 1,821k tonnes, Anthesis: 1,657k tonnes.

###### Workflow

1.  [Extracts](https://github.com/OliverLysa/observatory/blob/main/scripts/data_extraction_transformation/Electronics/environment_agency/On_the_market.R) placed on market data from Environment Agency EPR administrative data publication presented across multiple sheets, binds annual data, converts to long-format
2.  Exports consolidated data to CSV format

###### Outputs

-   A CSV of compiled POM data for years 2007 onward

------------------------------------------------------------------------

#### [004_mass_conversion.R](https://github.com/OliverLysa/observatory/blob/main/scripts/electronics/004_mass_conversion.R)

Script converts unit-level inflow data into mass equivalents e.g. tonnes of laptops and tablets.

##### Inputs

-   Outputs of 003_total_inflows.R script 'apparent consumption' method
-   Van Straalen, V.M, Roskam, A.J., & Baldé, C.P. (2016). Waste over Time [computer software]. The Hague, The Netherlands: Statistics Netherlands (CBS). Retrieved from:  [http://github.com/Statistics-Netherlands/ewaste](https://github.com/Statistics-Netherlands/ewaste)
-   [Babbitt *et al.* 2019 'bill of materials' (BoM) data](https://www.nature.com/articles/s41597-020-0573-9)
-   [ICF (2021) UK Energy-related Products Policy Study](https://etl.beis.gov.uk/shared-files/3316/3713/8281/UK_ErP_Policy_Study_final_v4-stc_2_11_21.pdf)
-   Plank, B., Streeck, J., Virág, D., Kraussman, F., Haberl, H., Widenhofer, D. (2022) Compilation of an economy-wide material flow database for 14 stock-building materials in 177 countries from 1900 to 2016. MethodsX, Volume 9. doi: 10.1016/j.mex.2022.101654.
    -   filtered to final goods, classified in SITC

<details>

<summary>More info: Bill of materials</summary>

A BoM is a hierarchical data object providing a list of the raw materials, components and instructions required to construct, manufacture, or repair a product. BoMs are generally used by firms to communicate information about a product as it moves along a value chain in order to help navigate regulations, efficiently manage inventory and to support product life-cycle assessments. Utilising component and material shares captured within a BoM data object alongside corresponding information on the volume/mass of flows (and stocks) of products/components, makes it possible to move between material, component and product flows (and stocks) at the micro level.

</details>

##### Workflow

1.  Extracts BoM data from Babbitt *et al.* 2019 and assigns these to UNU-KEYs
2.  Matches BoM data to inflow data by UNU-KEY and multiplies annual unit-level data by BoM data to calculate apparent consumption in mass terms
3.  Exports data to CSV format

##### Outputs

-   A CSV of annual inflows by UNU-KEY in both unit and mass terms

------------------------------------------------------------------------

#### [005_stock_outflow_calculation.R](https://github.com/OliverLysa/observatory/blob/main/scripts/electronics/005_stock_outflow.R)

Script calculates values for the stock of electronics and outflows from the stock based on inflow data and lifespan assumptions

##### Inputs

-   Inflow data in unit and mass terms
-   Lifespan assumptions by UNU category transferred from life-time profiles in the Netherlands, France, Belgium and Italy ([CIRCABC, 2023](https://circabc.europa.eu/ui/group/636f928d-2669-41d3-83db-093e90ca93a2/library/8e36f907-0973-4bb3-8949-f2bf3efeb125/details)) and specified as scale and shape variables of a Weibull distribution

<details>

<summary>More info: Lifespans as an input into MFA</summary>

At its simplest, a lifespan refers to a specific interval of time an object exists in a particular form (see NICER overview). Here, 'lifetime seeks to capture the period after a product has been sold and stays in households or businesses until it is disposed of'. This includes 'the dormant time in sheds and the exchange of second-hand equipment between households and businesses within the country' ([CIRCABC, 2023](https://circabc.europa.eu/ui/group/636f928d-2669-41d3-83db-093e90ca93a2/library/8e36f907-0973-4bb3-8949-f2bf3efeb125/details)).

Lifespan information can input into material stock and flow accounting, life-cycle costing and linked assessments of impact in various ways. For instance, material stock accounting can take a bottom-up approach based on item inventories and material intensities (e.g. Wiedenhofer *et al.* 2015), or be estimated from the top-down based on inflow data and estimated lifespan distributions as in delay/survival models (e.g. [Fishman *et al.* (2014)](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4251510/).

As an example, the ONS and most National Statistical Institutions (NSIs) estimate the monetary value of non-financial assets as part of national balance sheets using a perpetual inventory method (PIM). This involves starting with a benchmark asset monetary value and accumulating asset purchases through gross fixed capital formation over their estimated lifetime (based on ad-hoc research e.g., [asset lives study](https://www.niesr.ac.uk/publications/academic-review-asset-lives-uk)) via an assumed capital retirement distribution to estimate *gross* capital stocks. From this, a depreciation function is used to estimate the *net* capital stock (Dey-Chowdhury, 2009), with this further step taken because of the monetary representation of values.

</details>

##### Workflow

1.  Imports lifespan data specified as shape and scale parameters of the Weibull distribution - 'a continuous probability distribution that, when used for stock and flow models, can be described as modelling the population given a variable and time-dependent failure rate' ([ProSUM, 2017](https://www.prosumproject.eu/sites/default/files/170601%20ProSUM%20Deliverable%203.3%20Final.pdf)).
2.  Imports unit- and mass-level inflow data
3.  Estimates outflows by inflow year calculated based on a **hazard function** (h(y) (reflecting the probability that an event occurs in a period of time) and as the sum of discarded products entering the stock in each historic year multiplied by its lifetime distribution probability
4.  Calculate the stock in weight and units by calculating the cumulative sums of inflows and outflows by year and then subtracting from each other. Net change in stock between periods equals the difference between the total inflows and outflows i.e.

$$
K(t) = I(t)-O(t)
$$

where K(t) is the change and I(t) and O(t) are the corresponding inflows and outflows in that year, respectively. This net change is added to the stock level in year t-1

Stock estimates are compared against stock estimates data published by DESNZ (largely based on survey data), sources such as Ofcom and projections undertaken as part of the Market Transformation Programme.

5.  Combines inflow, stock and outflow by UNU-KEY by year into a single dataset
6.  Exports data to CSV format

##### Outputs

-   A CSV file containing inflow, stock and outflow data by UNU-Key by year in both unit and mass-terms

------------------------------------------------------------------------

#### [006_outflow_routing.R](https://github.com/OliverLysa/observatory/blob/main/scripts/electronics/006_outflow_routing.R)

Calculates the route of products and materials leaving the stock (as our lifespan data reflects years both in the in-use and non-in-use stock) across several categories aligned to the wire diagram.

##### Inputs

-   Environment Agency administrative [EPR data](https://www.gov.uk/government/statistical-data-sets/waste-electrical-and-electronic-equipment-weee-in-the-uk) on:
    -   WEEE collected - household and non-household Waste Electrical and Electronic Equipment (WEEE) collected by Producer Compliance Schemes and their members.
        -   Household WEEE from Designated Collection Facilities (DCFs) that has been collected by Producer Compliance Schemes, and household WEEE that DCFs have cleared themselves.
        -   Household WEEE returned by distributors to Producer Compliance Schemes.
        -   Household WEEE collected through a collection system a Producer Compliance Scheme operates itself.
        -   Non-household WEEE collected
    -   Reported household & non-household reuse of WEEE received at an approved authorised treatment facility (AATF)
        -   WEEE that AATFs have received, including that they have reused themselves/sent for reuse elsewhere and that sent to other AATFs/ATFs (as a whole appliance) w. household/non-household split
    -   WEEE received by approved exporters
        -   WEEE received by approved exporters w. household and non-household split
    -   Non-obligated WEEE received at approved authorised treatment facilities and approved exporters
        -   Tonnages of non-obligated WEEE received by AATFs and AEs
        -   Total amount of non-obligated WEEE received by AATFs from designated collection facilities
-   Wider Environment Agency data on:
    -   Illegal waste sites
    -   Waste Data Interrogator
-   Defra data on flytipping
-   UKU14-UNU54 interactive mapping tool ([Stowell, Yumashev et al. 2019)](https://www.research.lancs.ac.uk/portal/en/datasets/wot-insights-into-the-flows-and-fates-of-ewaste-in-the-uk(3465c4c6-6e46-4ec5-aa3a-fe13da51661d).html)

##### Workflow

1.  Calculate collection including by PCS, B2B
2.  Calculate repair ('*repair of defective product so it can be used with its original function*')
3.  Calculate reuse/resale ('*reuse by another consumer of discarded product which is still in good condition and fulfils its original function*')
4.  Calculate refurbishment ('*restore an old product and bring it up to date*')
5.  Calculate remanufactured ('*use parts of discarded product in a new product with the same function*')
6.  Calculate recycled ('*process materials to obtain the same (high grade) or lower (low grade) quality*')
7.  Calculate domestic disposal (including incineration of material with energy recovery, without energy recovery and landfill)
8.  Calculate exports

Definitions in quotation marks from [Kirchher, Reike and Hekkert (2017)](https://pdf.sciencedirectassets.com/271808/1-s2.0-S0921344917X00104/1-s2.0-S0921344917302835/main.pdf?X-Amz-Security-Token=IQoJb3JpZ2luX2VjEAoaCXVzLWVhc3QtMSJHMEUCIFp9P2BGjCHqPBgb2xV19C6sgiM6xIwynQIwqHTZeRIbAiEA9vPeduKQMJGka6wLwCNDSd0fAhM4XlTcKct9YyVEqtUqvAUIk%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FARAFGgwwNTkwMDM1NDY4NjUiDLxImPnrwM%2B3l58gqyqQBS3kw5hBhmdwqbWqrnz9A%2FzouvmmJnHuUKqSSZqw40vay8fLzJdQDOiMjVciiv38xgtwMlGXKy56gOlLzo7Ck2iVFbldjFnvFeeWUcPk%2BvUv%2BvJx44IrdJEo4iDFB9A1zCOgQiHAWHjc2dsh91hUsgBvtFmgNGbWEEvjtVbwZ0N5913R50lUAjWyqSGk%2BZPhlJXTeNO7pGhgqz6qGn3YToqPz6pRYlbPki4v%2BqqNRL9Bi%2B%2FpNl7CNsFiETjwl0EPLMcx1JNsNmlkcrhHvNY%2B5vwkGKl7dx3nDeQPBcRUN%2FiEkOrPAHCzFltEwG4TUqpbQquCc%2B3MIYR0S2FVMDhF1gfj3fGQAerI3VVwLsPfxedKlM6g1VdHI6QiiSkBwj4%2FKhs9FjSoBlUxAlOBRnMWeI5U5EwsYJt5%2FgAhs%2F23RkhvAYFeJtIXSG%2F4aITfX5NAAz4aOVU%2BsZq0B6Iikmoe%2F0Vw82doqaHeLwES9f25pqZinPIo0dj6L%2BTsSjHm8x8yvL7UgLdqVKzBhYf0TmYulseS0fo8mfSdMfHJv%2BOaUYVpwjRISmjcAN%2FQ3tMnhAeLVvIR0ni8twSZTPkKsmr1G5Oja568uKYdYWcyQ9D%2BOIuP92FQfNrO3eBFczW0HcksaqmVUIZ93dDUutVLU%2BboS2pm39XqsbCAODS2bM0Niy%2FZIOQidmjTyWJWYFKZzsxvSSCXIsDddUVxYXWPFHGI6iM2oLoNNkDYV3qCAI92%2FWFpIKam7wDMfohqC9Jt3%2FIGx%2ByDOkQbnUWCStXYikeBRjWWAr9SgASGnXX%2BH7Lqbc7uAJv1woy3dUTCpvP2VGLzweghnVUZWIzqj4pKVWNklG4AXDOqkkzeDDEABRknaEAKMP244KUGOrEB79srAJRuPIFLwimi%2BNoOYR74QY6giHH9UJbs%2B3Mtw3kkwWesoeoigHc0gM74R%2BNVuAVe2XRoidC8k35WhCApRjN3ri0xBqm4fRL0ueC%2FcpuNxmaoRizvUzSN3USacfT79koKUYIehazW2LOZJ0nBQ0yUbfjuMRE%2BFz2iNVBd6Vhf7CU6wNFszwRhKciz7zWZmmbNz7zWNamCmfaexW4eBbSD8t%2FiDFdyJfSg6OIvmYBF&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Date=20230719T183149Z&X-Amz-SignedHeaders=host&X-Amz-Expires=300&X-Amz-Credential=ASIAQ3PHCVTY2TUPFYPI%2F20230719%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Signature=9f73cbf3a05b1ed248358cdf71a38335dc91bfb00b3297a54647aab730e28be4&hash=dcaa3fd5d00981711e978218987ce1db48ef6bec8085a8b31781eac58bd54d80&host=68042c943591013ac2b2430a89b270f6af2c76d8dfd086a07176afe7c76c2c61&pii=S0921344917302835&tid=spdf-82cdff6d-2c9b-487c-b36a-faa12036d8eb&sid=2216cd4c54eef848569a67e187efaadbe15bgxrqa&type=client&tsoh=d3d3LnNjaWVuY2VkaXJlY3QuY29t&ua=0f1c560a565b5604535e&rr=7e950b28ba233ac7&cc=us).

##### Outputs

-   **Historic Indicators from Eurostat**
    1.  **Collection rate** = Equals the volumes collected of WEEE in the reference year divided by the average quantity of electrical and electronic equipment (EEE) put on the market in the previous three years (both expressed in mass unit).

    2.  **Reuse and recycling rate** = calculated by dividing the weight of the WEEE that enters the recycling/preparing for re-use facility by the weight of all separately collected WEEE (both in mass unit) in accordance with Article 11(2) of the WEEE Directive 2012/19/EU, considering that the total amount of collected WEEE is sent to treatment/recycling facilities. Reuse and recycling rate', as addressed in the Directive 2012/19/EU, measures the efficiency of the treatment process only 

    3.  **Recycling rate of e-waste =** Eurostat multiplies the WEEE 'collection rate' and use the reuse and recycling rate (3 and 4) to produce a combined recycling rate.
-   CSV of mass and unit flows by value-chain stage

------------------------------------------------------------------------

#### [007_GVA.R](https://github.com/OliverLysa/observatory/blob/main/scripts/electronics/007_GVA.R)

Script imports 2-digit and 4-digit gross value added (GVA) data and filters to SIC codes of relevance to electronics based on review of [methodological options](https://docs.google.com/document/d/1jb01KOxCMkPIIc_za8DF5-2LLjh03HJv/edit?usp=sharing&ouid=100007595496292131489&rtpof=true&sd=true)

##### Input

-   2-digit [regional GVA figures](https://www.ons.gov.uk/economy/grossvalueaddedgva/datasets/nominalandrealregionalgrossvalueaddedbalancedbyindustry) published by the UK ONS
-   4-digit aGVA data published by the ONS in its publication [Non-financial business economy, UK: Sections A to S](https://www.ons.gov.uk/businessindustryandtrade/business/businessservices/datasets/uknonfinancialbusinesseconomyannualbusinesssurveysectionsas). - 4 digit
-   SIC codes derived from script 000

<details>

<summary>More info: Gross value added</summary>

Gross value added (GVA) measures the increase in the value of the economy due to the production of goods and services calculated as the difference between the value of goods and services sold and intermediate expenses incurred to produce these.

</details>

##### Workflow

1.  Imports 2-digit and 4-digit GVA data from ONS publications, binds all sheets to create a single table
2.  Maps GVA data for SIC codes 26-29 (capturing manufacturing-related GVA values) and codes representing repair andv maintenance activities (to capture structural shifts at the mes-level) to UNU-Keys
3.  Exports data to CSV format

<details>

<summary>More information: Intensity ratios</summary>

At its most basic, a measure of efficiency or productivity tells us about a relationship in terms of scale between an output and an input. Singular measures of resource efficiency/productivity (as opposite to combined measures e.g. total factor productivity) generally seek to track the effectiveness with which an economy or sub-national process uses resource inputs to generate material or service outputs or anthropocentric value of some description.

"Intensity indicators compare trends in economic activity such as value-added, income or consumption with trends in specific environmental flows such as emissions, energy and water use, and flows of waste. These indicators are expressed as either intensity or productivity ratios, where intensity indicators are calculated as the ratio of the environmental flow to the measure of economic activity, and productivity indicators are the inverse of this ratio." (SEEA-Environment Extensions, 2012, pg. 13).

Economic-physical productivity i.e. the money value of outputs per mass unit of material resource inputs. At national level, can be measured from production perspective (GDP/DMC or DMI), or can be measured from consumption perspective (GDP/RMC or RMI). Other indicators could be the amount of waste generated in relation to economic output, or alternatively in relation to resource inputs/stocks.

</details>

##### Outputs

-   A CSV of 2-digit GVA and 4-digit aGVA data specific to electronics

------------------------------------------------------------------------

#### [008_emissions.R](https://github.com/OliverLysa/observatory/blob/main/scripts/electronics/008_emissions.R)

A script to import production and consumption emissions data and link to electronics classification.

##### Inputs

-   UK production emissions by SIC published by BEIS
-   UK consumption emissions by SIC published by Defra
-   SIC codes derived from script 000

##### Workflow

1.  Imports production emissions data and filter to SIC codes of relevance
2.  Imports consumption emissions data and filters to SIC codes of relevance
3.  Exports combined production and consumption emissions data by year by SIC code

##### Outputs

-   A CSV of production and consumption emissions data by SIC

------------------------------------------------------------------------

#### [009_stacked_chart.R](https://github.com/OliverLysa/observatory/blob/main/scripts/electronics/009_stacked_chart.R)

A script to prepare data for the stacked area/bar chart in the dashboard

##### Inputs

-   Outputs of script 005
-   UNU-KEY colloquial lookup

##### Workflow

1.  Imports tidy inflow, stock and outflow data in mass terms from script 005
2.  Merges with the UNU-KEY colloquial lookup to link to a user-friendly naming scheme
3.  Exports CSV of stacked area chart

##### Outputs

-   A CSV of stacked area data

------------------------------------------------------------------------

#### [010_bubble_chart.R](https://github.com/OliverLysa/observatory/blob/main/scripts/electronics/010_bubble_chart.R)

A script to prepare data for the bubble/scatter chart in the dashboard

##### Inputs

-   004 mass conversion
-   005 - lifespan assumptions
-   006 outflow routing

##### Workflow

1.  Calculate mean and median lifespan point estimates from Weibull parameters based on the following equations:
    -   mean = scale\*exp(gammaln(1+1/shape))
    -   median = scale\*(log(2))\^(1/shape))
2.  Calculate 'CE-score' as a weighted linear combination including the share of flows across each post-use reverse loop, disposal or losses multiplied by an ordinal factor, combined within a simple linear combination
3.  Extracts inflow data from the outputs of script 005

##### Outputs

-   A CSV file containing data on mean lifespan, CE-score and inflow by UNU-KEY by year

------------------------------------------------------------------------

#### [011_sankey_chart.R](https://github.com/OliverLysa/observatory/blob/main/scripts/electronics/011_sankey_chart.R)

A script to converts cleaned data into sankey format for presenting in dashboard

##### Inputs

-   BoM data from script 004
-   Inflow data from script 003
-   Outflow data from script 006

##### Workflow

1.  Imports BoM data stored as flat file with a from-to pair structure to construct the inflow stages, multiplying BoM data in physical terms by inflow in units

2.  Imports outflow data (in mass) and applies the BoM (in proportion) to calculate material composition of relevant flows

3.  Binds data tables together to get flows, by year

##### Outputs

-   CSV of sankey data

------------------------------------------------------------------------

#### [012_ifixit.R](https://github.com/OliverLysa/observatory/blob/main/scripts/electronics/012_ifixit.R)

A script to import and clean data on repairability scores to go into the dashbord shelf on 'enablers' and prepares for presentation in chart

##### Inputs

-   Expert-given repair scores across laptops, tablets and smartphones provided on the iFixit website

##### Workflow

1.  Scrap data from the iFixit website
2.  Summarise by product type, by make, by year using an average where there are multiple models by brand in a given year

##### Outputs

-   A CSV of repairability scores by product

------------------------------------------------------------------------

#### [013_open_repair.R](https://github.com/OliverLysa/observatory/blob/main/scripts/electronics/013_open_repair.R)

A script to import and clean data collated from Repair Cafes by the Open Repair Alliance

##### Inputs

-   Citizen science data collected from repair cafes and collated by the Open Repair Alliance

##### Workflow

1.  Import data, filter to data from GBR repair cafes
2.  Calculate lifespan until repair attempt for products where manufacturing year and year of repair attempt are noted
3.  Calculate repair success rate as the share of successful repairs of the total number of attempted repairs by product

##### Outputs

-   CSV containing data on repair success rate by product
-   CSV containing data on lifespan until repair attempt by product
