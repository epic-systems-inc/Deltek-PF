## What
This repo contains scripts that connect EPIC's ERP software to an internal application.

## Why
The current way things are done: A canned csv report is exported from the software 
by an accounting admin and uploaded to some file on a server, after which
a task runs a program that uses that data to update internal reports.

The goal of these scripts is to automatically pull this data from the database
so as to eliminate the middle man and a tedious manual process which often involves
corrupt csv files and bugs.

However, the database for the version of the application being used isn't documented very well 
and it is difficult to find table definitions and where our most important data is 
located, so there are a few python scripts in here with the purpose of figuring 
this out. 
Also there is a QA script which tests the data from the reports (not provided) 
against the data from the query result set (also not provided).

## Execution details
1. The first script run is DB_tables_to_csv.py, which runs DB_tables.sql to query 
our DB for tables and row counts and write this info to a csv file.
2. After, deltek_data_directory_crawler.py crawls and scrapes our Data Directory and
writes table and column defintions to a csv file.
3. Lastly, data_qa_test.py runs the pf_project_details SQL query 
against report data to show differences between the result query set and the report, if any.