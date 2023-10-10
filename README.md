# 🚀 CE observatory data processing

## WORK IN PROGRESS

*If you identify any issues, please contact*: Oliver Lysaght (oliverlysaght\@icloud.com)

# Purpose

A collection of scripts to:

1.  extract raw data from public official and emerging sources (incl. via API, web scraping and programmatic download requests) starting from those identified through a [dataset review](https://docs.google.com/spreadsheets/d/11jO8kaYktQ1ueMY1iJoaCl1dJU8r6RDfyxICPB1wFqg/edit#gid=795733331);

2.  transform these through steps including:

    1.  cleaning and reformatting;
    2.  grouping by classifications and summarising;
    3.  data validation, interpolation and extrapolation;
    4.  calculating key variables/metrics; and

3.  export cleaned data outputs to an open source PostGreSQL database (supabase) for storage.

Data outputs from these scripts are used to populate the ce-observatory - a dashboard providing for specific resource-product-industry categories, a detailed description using high-quality data of current baseline material and monetary flows as well as wider impacts, alongside the means to make comparison with alternative circular economy configurations.

# How to use

## Software requirements and setup

Scripts in this repository are largely written in the programming language R. Please see [here](https://rstudio-education.github.io/hopr/starting.html) for more information on running R scripts and computer software requirements. Files are packaged within an R Project with relative file paths used to call data inputs and functions. These can be most easily navigated and ran within the R Studio IDE, though this can also be done in the terminal/command line. We use targets and renv packages for a reproducible environment.

The Python scripting language has also been used as part of the project in cases where it offers better performance or provides functions not otherwise available in R. Python scripts are largely presented within [Jupyter Notebooks](https://jupyter.org/install) - an open source IDE that requires installing the jupyter-notebook package in your Python environment, more information about which can be found [here](https://www.python.org/downloads/). In some cases, .py Python scripts are also used. These can be viewed and modified in a code editor such as Visual Studio Code and ran in the terminal/command line.

## Updates

The observatory has been designed to incorporate new data as it becomes available to help with timely insight, trend assessment, monitoring and evaluation. Web hooks are used to trigger site rebuild following data updates. Data updates are ran through scheduled extraction scripts, with imported data undergoing structure, data type and content validation to reduce risk of build failure on the front-end.

# Folder and file descriptions

## [raw_data](https://github.com/OliverLysa/observatory/tree/main/raw_data)

Raw data inputs downloaded from a variety of sources

## [intermediate_data](https://github.com/OliverLysa/observatory/tree/main/intermediate_data)

In a few cases, processing steps require exporting data outputs from the R/Python environments for processing in excel and reimporting. An example is the mapping tool used to convert 14-category electronics data captured in UK WEEE EPR datasets to the 54-category UNU-key classification used in presenting data on the electronics page. 'Intermediate' data files which undergo this type of processing are stored in this folder.

## [cleaned_data](https://github.com/OliverLysa/observatory/tree/main/cleaned_data)

Cleaned data outputs derived from raw and intermediate data files following processing in R, Python and/excel and which are added to the postgresql database backend for the observatory dashboard. Within the dashboard environment, cleaned data files may undergo additional processing such as on-the-fly aggregation.

## scripts

### [functions.R](https://github.com/OliverLysa/observatory/blob/main/scripts/functions.R)

A collection of custom user-defined functions regularly used throughout the data processing pipeline and not otherwise provided in R packages.

## Product-group specific

[Electronics scripts readme](https://github.com/OliverLysa/observatory-data-prep/blob/main/electronics_readme.md)
