"""
The purpose of this script is to crawl+scrape the Deltek Data Directory for 
table structures and definitions. The data directory is not laid out in the 
most user-friendly way and it is difficult to see each table and the columns
and column descriptions contained therein because each table is accessed
via a link.

The script will output an csv file with the following format:
-----------------------------------------------------------------------------
Table | Definition | RowCount | ColumnName | DataType | NULL | ColDescription
-----------------------------------------------------------------------------

Requirements: 
    + Selenium
    + Google Chrome and chrome web driver executable in PATH (usr/bin/local)
    + Access to the Deltek Data Directory
"""

from selenium import webdriver
from bs4 import BeautifulSoup
from csv import reader
import pandas as pd
import yaml

with open("credentials.yaml", 'r') as ymlfile:
    creds = yaml.load(ymlfile, Loader=yaml.SafeLoader)

with open('DeltekTables.csv', 'r') as tables:
    # Open our csv file and store table names and row_counts

    read_tables = reader(tables)
    next(read_tables) # skip the header

    deltek_tables = {}
    deltek_tables['row_count'] = []
    deltek_tables['table'] = []

    for row in read_tables:
        # Only interested in definitions for non-zero row count tables
        if int(row[2]) > 0:
            deltek_tables['row_count'].append(int(row[2]))
            deltek_tables['table'].append(row[1].strip())


options = webdriver.ChromeOptions()
# Prevent the browser window from physically popping up
options.add_argument("headless")
driver = webdriver.Chrome(options=options)

url = (r'http://{}:{}@deltek.epic.local/Vision/Help/en-US/DataDictionary/Content'
        .format(creds['username'],creds['password']))

driver.get(url+r'/Sub_a8182cc5c96e4756bd906973f837465a_EntList.htm')

soup = BeautifulSoup(driver.page_source, 'lxml')

# Initialize the dict for the final data
data = {'Table':[], 'Definition':[], 'RowCount': [], 'ColumnName':[], 
        'DataType':[], 'NULL':[], 'ColDescription':[]}

for tr in soup.find_all('tr'):
    if tr.b.text.strip() in deltek_tables['table']:
        table_name = tr.b.text.strip()
        
        # In the following line, get the list of tables from the dictionary
        # (deltek_tables['table']) and return the index of table_name
        # and use this to index the row counts list to get the row count of the
        # respective table
        row_count = deltek_tables['row_count'][deltek_tables['table'].index(table_name)]
        
        driver.get(url+r'/{}'.format(tr.find('a', href=True).get('href')))
        soup = BeautifulSoup(driver.page_source, 'lxml')
        
        table_definition = soup.select('body > table:nth-of-type(2) > tbody > \
                                        tr:nth-of-type(2) > td:nth-of-type(2)')
        table_definition = table_definition[0].text.strip()
        
        for index, tr in enumerate(soup.find_all('table')[3].find_all('tr')):
            if index == 0:
                continue
            for i, td in enumerate(tr.find_all('td')):
                if i == 0:
                    data['ColumnName'].append(td.text.strip())
                elif i == 2:
                    data['DataType'].append(td.text.strip())
                elif i == 3:
                    data['NULL'].append(td.text.strip())
                elif i == 4:
                    data['ColDescription'].append(td.text.strip())
        
            data['Table'].append(table_name)
            data['Definition'].append(table_definition)
            data['RowCount'].append(row_count)

print(data)

df = pd.DataFrame(data) 

# Print the output. 
print(df) 

df.to_csv('DeltekDataDirectory.csv')