/* 
   The following script returns the table names of the tables present in the 
   database as well as their row count.
   This script is not my own - credit to SO user rchacko
   See this SO question:
   https://stackoverflow.com/questions/1443704/query-to-list-number-of-records-in-each-table-in-a-database 
*/
SELECT  o.NAME TABLENAME,
        i.rowcnt 
FROM sysindexes AS i
INNER JOIN sysobjects AS o ON i.id = o.id 
WHERE i.indid < 2  AND OBJECTPROPERTY(o.id, 'IsMSShipped') = 0
ORDER BY i.rowcnt desc