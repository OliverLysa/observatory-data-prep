# CE-observatory

*Author*: Oliver Lysaght

*Date of last update*: 2023-05-15

# Table of contents

# Purpose

Downloads raw and pre-processed data to populate the ce-observatory - a UK national CE-Observatory dashboard for detailed description of current baseline states and comparison of alternative target future circular economy configurations for specific resource-product-industry categories.

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

Scripts for extracting data from sources via API where available, web scraping and manual downloading. Steps:

-   Data retrieved
-   Data **validated** and **cleaned**
-   Outlier replacement and unknown values estimated

### Variable calculation

-   Scripts for calculating/deriving data presented in components where not taken directly from sources

### Visualise

-   Data reformatted and restructured to populate required end-points (e.g. derived aggregations)

## Raw data

Raw data files downloaded from sources

## Cleaned data

Cleaned data files, derived from raw data files following cleaning and tidying. Enclosed intermediate files may undergo additional processing through variable calculation scripts to input to the observatory dashboard.

# Planned updates

Ongoing
