import pyodbc
import pandas as pd
import yaml

# read the credentials from the yaml file
with open("credentials.yaml", 'r') as ymlfile:
    creds = yaml.load(ymlfile, Loader=yaml.SafeLoader)

# connect to the database
server = creds['deltek_server']
database = creds['deltek_db']
username = creds['deltek_user']
password = creds['deltek_pass']
cnxn = pyodbc.connect('DRIVER={SQL Server Native Client 11.0};SERVER='+server+';DATABASE='+database+';UID='+username+';PWD='+ password)
cursor = cnxn.cursor()

with open('DB_tables.sql') as sql:
    query = sql.read()

cursor.execute(query)
rows = cursor.fetchall() 

tables = {'Table':[], 'RowCount':[]}

for row in rows:
    tables['Table'].append(row[0])
    tables['RowCount'].append(row[1])

tables_df = pd.DataFrame(tables)

tables_df.to_csv("DeltekTables.csv")