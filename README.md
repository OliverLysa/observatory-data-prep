# CE-observatory

*Author*: Oliver Lysaght

*Date of last update*: 2023-05-15

# Table of contents

# Purpose

A collection of R and Python scripts for extracting raw data files and processing these data to populate the ce-observatory - a UK national CE-Observatory dashboard for detailed description of current baseline and comparison of alternative target future circular economy configurations for specific resource-product-industry categories.

The ce-observatory can be viewed at the following URL:

## Mapping sources to end-points

### End-points

### Where the data is sourced from

#### **'Contribute' pipeline**

CSV uploads of data following specified format and schema.

Metadata covering provenance, methods used.

#### **Extract pipeline**

Using public data from official and emerging sources. Raw data **extracted** via API, web-scraping, download requests and manual retrieval.

# Software requirements

Scripts are written in the programming languages R and Python.

# Description of folders and scripts

## Classifications

Spreadsheet files of core classifications used for structuring and retrieving data.

Concordance or correlation tables for moving between these classifications.

Scripts for matching classifications.

## Scripts

### Classification matching

### Data extraction

Scripts for extracting data from sources via API where available, web scraping and manual downloading, cleaning and validation, outlier replacement and unknown values estimated.

Protocols for:

Trade

Prodcom

Bill of materials

Lifespan

Outflow

GVA

Emissions

### Variable calculation

-   Scripts for calculating/deriving data presented on the dashboard where not taken directly from sources
-   KPI definitions and methodologies

### Visualise

-   Data reformatted and restructured to populate required end-points (e.g. derived aggregations)

## Raw data

Raw data files downloaded from sources

## Cleaned data

Cleaned data files, derived from raw data files following cleaning and tidying. Enclosed intermediate files may undergo additional processing through variable calculation scripts to input to the observatory dashboard.

# Planned updates

Ongoing
