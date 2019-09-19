/*  WANT:
		--Name (WBS1)
		--Phase (WBS2)
		--ApprovedPOAmount [ 6 ] (verified)
		--MaterialsSpent [ 7 ] low confidence - needs testing and further verification
		--CommittedExpense [ 8 ]
		--TotalSpent [ 9 ] low confidence - needs testing and further verification
		--GAAPRevenue [ 10 ]
		--BilledInvoiceAmount [ 12 ] 'Total Billed' (verified)
		--ReceivedInvoiceAmount [ 13 ] 'Received' (verified)
		--BillingType
*/
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
/*	Get the approved PO amount for real projects */
SELECT WBS1, -- Name
	   WBS2, -- Phase
       RevType, -- BillingType
	   SUM(Fee) AS ApprovedPOAmount -- ApprovedPOAmount
FROM [epicsysacct].[dbo].[PR]
WHERE WBS1 IS NOT NULL AND TRY_CONVERT(INT, WBS1) IS NULL 
      -- For testing purposes:
	  AND WBS1 IN ('GSK-1001', 
	               'CBD-1000', 
				   'DMT-1000', 
				   'NSU-1027', 
				   'KLI-1021',
				   'LCC-GREG', --ESG labor cross charge
				   'ZOH-G100', --ESG overhead variance
				   'APS-1001'
				   )
GROUP BY WBS1, RevType, WBS2
ORDER BY WBS1
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
/* Total billed */
SELECT WBS1,
	   SUM(Amount) AS Amount
FROM [epicsysacct].[dbo].[billINDetail]
WHERE WBS1 IS NOT NULL AND TRY_CONVERT(INT, WBS1) IS NULL 
      -- For testing purposes:
	  AND WBS1 IN ('GSK-1001', 
	               'CBD-1000', 
				   'DMT-1000', 
				   'NSU-1027', 
				   'KLI-1021',
				   'LCC-GREG', --ESG labor cross charge
				   'ZOH-G100', --ESG overhead variance
				   'APS-1001'
				   )
GROUP BY WBS1
ORDER BY WBS1
-- what's up with this ...
SELECT WBS1,
	   SUM(Amount) Amount
FROM LedgerAR -- Exepense detail table for accounts receivable
WHERE WBS1 IS NOT NULL AND TRY_CONVERT(INT, WBS1) IS NULL 
      -- For testing purposes:
	  AND WBS1 IN ('GSK-1001', 
	               'CBD-1000', 
				   'DMT-1000', 
				   'NSU-1027', 
				   'KLI-1021',
				   'LCC-GREG', --ESG labor cross charge
				   'ZOH-G100', --ESG overhead variance
				   'APS-1001'
				   )
GROUP BY WBS1
ORDER BY WBS1
/* Total invoiced... what's the difference between this and total billed? */
SELECT WBS1,
	   SUM(Amount) AS Invoiced
  FROM [epicsysacct].[dbo].[inDetail] -- Invoice Table - Data Entry Detail
WHERE WBS1 IS NOT NULL AND TRY_CONVERT(INT, WBS1) IS NULL 
      -- For testing purposes:
	  AND WBS1 IN ('GSK-1001', 
	               'CBD-1000', 
				   'DMT-1000', 
				   'NSU-1027', 
				   'KLI-1021',
				   'LCC-GREG', --ESG labor cross charge
				   'ZOH-G100', --ESG overhead variance
				   'APS-1001'
				   )
GROUP BY WBS1
ORDER BY WBS1
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
/* total received */
SELECT WBS1,
	   SUM(Amount) Amount
FROM [epicsysacct].[dbo].[crDetail] -- Cash Receipts Table - Data Entry Detail
WHERE WBS1 IS NOT NULL AND TRY_CONVERT(INT, WBS1) IS NULL 
      -- For testing purposes:
	  AND WBS1 IN ('GSK-1001', 
	               'CBD-1000', 
				   'DMT-1000', 
				   'NSU-1027', 
				   'KLI-1021',
				   'APS-1001',
				   'PGC-2122',
				   'MOB-1060'
				   )
AND Account = 111.00
GROUP BY WBS1, Account
ORDER BY WBS1
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
/* Materials Spent */
SELECT WBS1,
	   SUM(Amount) Amount
FROM 
(
	 SELECT WBS1, 
			Amount
	 FROM [epicsysacct].[dbo].[LedgerAP] -- Expense Detail Table - Accounts Payable
	 UNION ALL
	 SELECT WBS1,
			Amount
	 FROM ekDetail -- Expense Table - Data Entry Detail
	 UNION ALL
	 SELECT WBS1, 
	        CostAmount AS Amount
	 FROM    billExpDetail bill
	 WHERE   NOT EXISTS
        (
        SELECT  NULL
        FROM    LedgerAP lap
        WHERE   lap.PKey = bill.OriginalPKey
        )
     AND OriginalTable NOT IN ('LedgerAP', 'LedgerEX')
) MaterialExpense
WHERE WBS1 IS NOT NULL AND TRY_CONVERT(INT, WBS1) IS NULL 
      -- For testing purposes:
	  AND WBS1 IN ('GSK-1001', 
	               'CBD-1000', 
				   'DMT-1000', 
				   'NSU-1027', 
				   'KLI-1021',
				   'LCC-GREG', --ESG labor cross charge
				   'ZOH-G100', --ESG overhead variance
				   'APS-1001',
				   'PGC-2122',
				   'MOB-1060',
				   'DUR-1065')
GROUP BY WBS1
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
/* Comitted expensee */
SELECT WBS1,
       SUM(Amount) amt,
	   SUM(TransactionAmount) trans
FROM POCommitment
WHERE WBS1 IS NOT NULL AND TRY_CONVERT(INT, WBS1) IS NULL 
      -- For testing purposes:
	  AND WBS1 IN ('GSK-1001', 
	               'CBD-1000', 
				   'DMT-1000', 
				   'NSU-1027', 
				   'KLI-1021',
				   'LCC-GREG', --ESG labor cross charge
				   'ZOH-G100', --ESG overhead variance
				   'APS-1001',
				   'PGC-2122',
				   'MOB-1060'
				   )
GROUP BY WBS1
ORDER BY WBS1
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
/* Total Spent at Cost */
SELECT WBS1,
	   SUM(Amount) Amount
FROM 
(
	 SELECT WBS1, 
			Amount
	 FROM [epicsysacct].[dbo].[LedgerAP] -- Expense Detail Table - Accounts Payable
	 UNION ALL
	 SELECT WBS1,
			Amount
	 FROM ekDetail -- Expense Table - Data Entry Detail
	 UNION ALL
	 SELECT WBS1,
			RegAmt+OvtAmt AS Amount
	 FROM   LD -- Labor Detail Table
	 UNION ALL
	 SELECT WBS1, 
	        CostAmount AS Amount
	 FROM    billExpDetail bill  -- Invoice Detail Table - Expense Detail for Prior Billings
	 WHERE   NOT EXISTS
        (
        SELECT  NULL
        FROM    LedgerAP lap
        WHERE   lap.PKey = bill.OriginalPKey
        )
     AND OriginalTable NOT IN ('LedgerAP', 'LedgerEX')
) TotalSpent
WHERE WBS1 IS NOT NULL AND TRY_CONVERT(INT, WBS1) IS NULL 
      -- For testing purposes:
	  AND WBS1 IN ('GSK-1001', 
	               'CBD-1000', 
				   'DMT-1000', 
				   'NSU-1027', 
				   'KLI-1021',
				   'LCC-GREG', --ESG labor cross charge
				   'ZOH-G100', --ESG overhead variance
				   'APS-1001',
				   'PGC-2122',
				   'MOB-1060',
				   'DUR-1065')
GROUP BY WBS1
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
/* GAAP Revenue */
SELECT WBS1,
       Fee * PctComp * 0.01
FROM PR WHERE WBS1 IS NOT NULL AND TRY_CONVERT(INT, WBS1) IS NULL 
      -- For testing purposes:
	  AND WBS1 IN ('GSK-1001', 
	               'CBD-1000', 
				   'DMT-1000', 
				   'NSU-1027', 
				   'KLI-1021',
				   'APS-1001',
				   'PGC-2122',
				   'MOB-1060',
				   'DUR-1065')
