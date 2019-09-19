SELECT PR.WBS1 AS ProjectNumber,
	   REPLACE(PR.WBS2, ' ', '') AS PhaseName,
	   SUM(PR.Fee) AS ApprovedPOAmount,
	   expense.Amount AS MaterialsSpent,
	   po_commit.Amount AS CommittedExpense,
	   total_spent.Amount AS TotalSpent,
	   CASE WHEN PR.RevType = 'TM' THEN PR.Fee
	        ELSE ROUND((PR.Fee * PR.PctComp * 0.01), 2) 
	   END AS GAAPRevenue,
	   PR.RevType AS BillingType,
	   invoiced.BilledAmount AS BilledInvoiceAmount,
	   invoiced.ReceivedAmount AS ReceivedInvoiceAmount
FROM PR
LEFT JOIN
(
	SELECT WBS1,
	       WBS2,
	       SUM(Amount) Amount
	FROM 
	(
		SELECT WBS1,
		       WBS2, 
			   Amount
		FROM [epicsysacct].[dbo].[LedgerAP] -- Expense Detail Table - Accounts Payable
		WHERE ProjectCost = 'Y' 
		UNION ALL
		SELECT WBS1,
		       WBS2,
			   Amount
		FROM LedgerMisc -- Expense Table - Data Entry Detail
		WHERE ProjectCost = 'Y' 
		UNION ALL
		SELECT WBS1,
		       WBS2, 
			   Amount
		FROM   LedgerEX
		WHERE ProjectCost = 'Y' 
		UNION ALL
		SELECT WBS1,
		       WBS2, 
			   Amount
		FROM   LedgerAR 
		WHERE ProjectCost = 'Y'
	) MaterialExpense
	GROUP BY WBS1, WBS2
) expense
ON expense.WBS1 = PR.WBS1 AND expense.WBS2 = PR.WBS2
LEFT JOIN
(
	SELECT WBS1,
	       WBS2,
		   SUM(Amount) Amount
	FROM 
	(
		 SELECT WBS1,
		        WBS2,
				RegAmt+OvtAmt AS Amount
		 FROM   LD -- Labor Detail Table
		 UNION ALL
		 SELECT WBS1,
		        WBS2,
				Amount
		FROM [epicsysacct].[dbo].[LedgerAP] -- Expense Detail Table - Accounts Payable
		WHERE ProjectCost = 'Y' 
		UNION ALL
		SELECT WBS1,
		       WBS2,
			   Amount
		FROM LedgerMisc -- Expense Table - Data Entry Detail
		WHERE ProjectCost = 'Y' 
		UNION ALL
		SELECT WBS1,
		       WBS2,
			   Amount
		FROM   LedgerEX
		WHERE ProjectCost = 'Y' 
		UNION ALL
		SELECT WBS1,
		       WBS2,
			   Amount
		FROM   LedgerAR 
		WHERE ProjectCost = 'Y'
	) TotalSpent
	GROUP BY WBS1, WBS2
) total_spent
ON total_spent.WBS1 = PR.WBS1 AND total_spent.WBS2 = PR.WBS2
LEFT JOIN
(
	SELECT WBS1,
           ABS(SUM(CASE WHEN Account IN (401.00, 422.00, 421.00) THEN Amount END)) BilledAmount,
	       ABS(SUM(CASE WHEN Account = 111.00 THEN Amount END)) ReceivedAmount
	FROM LedgerAR
	GROUP BY WBS1
) invoiced
ON invoiced.WBS1 = PR.WBS1
LEFT JOIN
(
	SELECT WBS1,
           SUM(Amount) Amount,
	       SUM(TransactionAmount) TransAmt
	FROM POCommitment
	GROUP BY WBS1
) po_commit
ON po_commit.WBS1 = PR.WBS1
WHERE PR.WBS1 IS NOT NULL AND TRY_CONVERT(INT, PR.WBS1) IS NULL 
AND PR.WBS1+' ; '+PR.WBS2 IN {}
GROUP BY PR.WBS1, 
		 RevType, 
		 PR.WBS2, 
		 PR.PctComp,
		 PR.Fee,
		 expense.Amount,
	     total_spent.Amount,
	     invoiced.ReceivedAmount,
	     invoiced.BilledAmount,
	     po_commit.Amount
ORDER BY PR.WBS1

