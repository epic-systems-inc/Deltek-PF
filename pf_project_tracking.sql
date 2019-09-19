SELECT pr.WBS1 AS ProjectNumber,
	   REPLACE(pr.WBS2, ' ', '') AS PhaseName,
	   SUM(pr.Fee) AS ApprovedPOAmount,
	   expense.Amount AS MaterialsSpent,
	   po_commit.Amount AS CommittedExpense,
	   total_spent.Amount AS TotalSpent,
	   CASE WHEN pr.RevType = 'TM' THEN pr.Fee
	        ELSE ROUND((pr.Fee * pr.PctComp * 0.01), 2) 
	   END AS GAAPRevenue,
	   pr.RevType AS BillingType,
	   billed.Amount AS BilledInvoiceAmount,
	   received.Amount AS ReceivedInvoiceAmount
FROM [epicsysacct].[dbo].[PR] pr
LEFT JOIN
(
	SELECT WBS1,
		   SUM(Amount) Amount
	FROM 
	(
		 SELECT WBS1, 
				Amount
		 FROM   [epicsysacct].[dbo].[LedgerAP] -- Expense Detail Table - Accounts Payable
		 UNION ALL
		 SELECT WBS1,
				Amount
		 FROM   ekDetail -- Expense Table - Data Entry Detail
		 UNION ALL
		 SELECT WBS1, 
				CostAmount AS Amount
		 FROM   billExpDetail bill
		 WHERE  NOT EXISTS
			(
				SELECT  NULL
				FROM    LedgerAP lap
				WHERE   lap.PKey = bill.OriginalPKey
			)
		 AND OriginalTable NOT IN ('LedgerAP', 'LedgerEX')
	) MaterialExpense
	GROUP BY WBS1
) expense
ON expense.WBS1 = pr.WBS1
LEFT JOIN
(
	SELECT WBS1,
		   SUM(Amount) Amount
	FROM 
	(
		 SELECT WBS1, 
				Amount
		 FROM   [epicsysacct].[dbo].[LedgerAP] -- Expense Detail Table - Accounts Payable
		 UNION ALL
		 SELECT WBS1,
				Amount
		 FROM   ekDetail -- Expense Table - Data Entry Detail
		 UNION ALL
		 SELECT WBS1,
				RegAmt+OvtAmt AS Amount
		 FROM   LD -- Labor Detail Table
		 UNION ALL
		 SELECT WBS1, 
				CostAmount AS Amount
		 FROM   billExpDetail bill  -- Invoice Detail Table - Expense Detail for Prior Billings
		 WHERE  NOT EXISTS
			(
				SELECT  NULL
				FROM    LedgerAP lap
				WHERE   lap.PKey = bill.OriginalPKey
			)
		 AND OriginalTable NOT IN ('LedgerAP', 'LedgerEX')
	) TotalSpent
	GROUP BY WBS1
) total_spent
ON total_spent.WBS1 = pr.WBS1
LEFT JOIN
(
	SELECT WBS1,
		   SUM(Amount) AS Amount
	FROM [epicsysacct].[dbo].[billINDetail]
	GROUP BY WBS1
) billed
ON billed.WBS1 = pr.WBS1
LEFT JOIN
(
	SELECT WBS1,
	       SUM(Amount) Amount
	FROM [epicsysacct].[dbo].[crDetail]
	WHERE Account = 111.00
	GROUP BY WBS1
) received
ON received.WBS1 = pr.WBS1
LEFT JOIN
(
	SELECT WBS1,
           SUM(Amount) Amount,
	       SUM(TransactionAmount) TransAmt
	FROM POCommitment
	GROUP BY WBS1
) po_commit
ON po_commit.WBS1 = pr.WBS1
WHERE pr.WBS1 IS NOT NULL AND TRY_CONVERT(INT, pr.WBS1) IS NULL 
AND pr.WBS1+' ; '+pr.WBS2 IN {}
GROUP BY pr.WBS1, 
		 RevType, 
		 WBS2, 
		 pr.PctComp,
		 pr.Fee,
		 expense.Amount,
	     total_spent.Amount,
	     billed.Amount,
	     received.Amount,
	     po_commit.Amount
ORDER BY pr.WBS1

