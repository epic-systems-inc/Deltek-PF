"""
This script queries our Deltek DB to pull data and then it runs a QA test on 
that data.

There is a canned report that comes striaght from the Deltek application and is
manually run and uploaded to an internal application that uses that data for 
reporting. In order to automate that process, I am using our Deltek DB, but 
these are unchartered waters and the database design is ugly, so it's unclear 
if my query is going to return the expected result set - the purpose of this 
script is to make sure it does.

The script takes one of the reports (everything is to-date) and checks the 
values in each relevant field against the values of the corresponding fields 
in the query result set. It writes a csv file which contains differences.
"""

import pyodbc
from csv import reader
import pandas as pd
from itertools import islice
import re
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

with open('pf_upload_billings.sql') as sql:
    query = sql.read()

wbs = []
with open('PF - Project Tracking Data Export Cost - 2017 to 9-16-19.csv') as deltek_report:
    projects = reader(deltek_report)
    
    for project in islice(projects, 4, None):
        try:
            wbs1 = re.search('(?<=: )([^\s]+)',project[1]).group()  # WBS1s (project numbers)
            wbs2 = "".join(re.findall('(?<=: )([^\s]+)',project[2])) # WBS2s (phases)
            #wbs2 = (lambda s: '' if s is None else str(s))(wbs2)
            unique_together = wbs1 + ' ; ' + wbs2
            if unique_together == 'ZOH-G001 ; ':     # one particular exception to the general WBS1 format
                unique_together = 'ZOH-G001 INC ; '  # easier to include manually rather than change the re
            wbs.append(unique_together)
        except IndexError:
            pass

cursor.execute(query.format(tuple(wbs)))
rows = cursor.fetchall() 

wbs_dict = {}
for row in rows:
    # The key will be in the form of WBS1 ; WBS2
    # and the value is a tuple of length 8 representing fields 2-9
    wbs_dict.update({row[0]+' ; '+row[1] : (row[2:10])})

# [My index] field name [report index]:
    # [0] WBS1 [1]
    # [1] WBS2 [2]
    # [2] ApprovedPOAmount [5]
    # [3] MaterialsSpent [6]
    # [4] CommittedExpense [7]
    # [5] TotalSpent [8]
    # [6] GAAPRevenue [9]
    # [7] BillingType [20]
    # [8] BilledInvoiceAmount [11]
    # [9] ReceivedInvoiceAmount [12]
report_index_list = [5, 6, 7, 8, 9, 20, 11, 12]
differences = { 'WBS':[], 
                'ApprovedPOAmount': [],
                'MaterialsSpent':[],
                'CommittedExpense':[],
                'TotalSpent':[],
                'GAAPRevenue':[],
                'BillingType':[],
                'BilledInvoiceAmount':[],
                'ReceivedInvoiceAmount':[] }

def to_float(x): 
    if x is None or x == '':
        x = 0
    return float(x)

with open('PF - Project Tracking Data Export Cost - 2017 to 9-16-19.csv') as deltek_report:
    projects = reader(deltek_report)
    for index, project in enumerate(islice(projects, 4, None)):
        try:
            # First we get the value (a tuple) from the dictionary corresponding to 
            # the keys we stored in the wbs list
            wbs_key = wbs[index]
            print(wbs_key)
            record = wbs_dict.get(wbs_key) # record holds values for fields 2-9
                                           # so that ApprovedPOAmount (field 2) is at index 0
            differences_list = []
            for i in range(len(record)):
                # Get the difference between the values we retreived via query and the
                # values returned in the report for each relevant field
                if i != 5: # this is the index of BillingType (a string)
                    differences_list.append(to_float(record[i]) - to_float(project[report_index_list[i]]))
                else:
                    differences_list.append(record[i] == project[report_index_list[i]])
            
            differences['WBS'].append(wbs_key)
            differences['ApprovedPOAmount'].append(differences_list[0])
            differences['MaterialsSpent'].append(differences_list[1])
            differences['CommittedExpense'].append(differences_list[2])
            differences['TotalSpent'].append(differences_list[3])
            differences['GAAPRevenue'].append(differences_list[4])
            differences['BillingType'].append(differences_list[5])
            differences['BilledInvoiceAmount'].append(differences_list[6])
            differences['ReceivedInvoiceAmount'].append(differences_list[7])

        except IndexError:
            pass

print(differences)
differences_df = pd.DataFrame(differences)

differences_df.to_csv('QA_testing.csv')
