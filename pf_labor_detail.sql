/*	This is the query for the labor expended on a project.
	The query looks back over a 14 day rolling window.
	ProjectNumbers like 100 (general overhead) are excluded. */
SELECT WBS1 ProjectNumber,
       Employee,
	   Name,
	   LaborCode,
	   RegHrs,
	   OvtHrs,
	   BillExt,
	   TransDate
FROM [epicsysacct].[dbo].[LD]
WHERE TransDate >= DATEADD(DAY, -14, GETDATE()) AND TRY_CONVERT(INT, WBS1) IS NULL