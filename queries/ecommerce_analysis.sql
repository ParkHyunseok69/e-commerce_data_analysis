/*DATA CLEANING*/
EXEC sp_help 'e-commerce_table'
SELECT 
COUNT (*) - COUNT(InvoiceNo) AS InvoiceNo_Nulls,
COUNT (*) - COUNT(StockCode) AS StockCode_Nulls,
COUNT (*) - COUNT(Description) AS Description_Nulls,
COUNT (*) - COUNT(Quantity) AS Quantity_Nulls,
COUNT (*) - COUNT(InvoiceDate) AS InvoiceDate_Nulls,
COUNT (*) - COUNT(UnitPrice) AS UnitPrice_Nulls,
COUNT (*) - COUNT(CustomerID) AS CustomerID_Nulls,
COUNT (*) - COUNT(Country) AS Country_Nulls
FROM [e-commerce_table]

SELECT * FROM [e-commerce_table]
WHERE Quantity < 0

SELECT * FROM [e-commerce_table]
WHERE CustomerID IS NULL AND Description IS NULL

DELETE FROM [e-commerce_table]
WHERE CustomerID IS NULL AND Description IS NULL

DELETE FROM [e-commerce_table]
WHERE UnitPrice IS NULL

UPDATE [e-commerce_table]
SET CustomerID = 'No ID'
WHERE CustomerID IS NULL

ALTER TABLE [e-commerce_table]
ADD PurchaseAmount decimal

UPDATE [e-commerce_table]
SET PurchaseAmount = CASE WHEN Quantity < 1 AND InvoiceNo LIKE '%C%'THEN 0 ELSE Quantity * ROUND(UnitPrice, 2) END

ALTER TABLE [e-commerce_table]
ADD ReturnedAmount decimal

UPDATE [e-commerce_table]
SET ReturnedAmount = CASE WHEN PurchaseAmount = 0 THEN ABS(Quantity) * ROUND(UnitPrice, 2) ELSE 0 END

DELETE FROM [e-commerce_table]
WHERE PurchaseAmount = 0 AND ReturnedAmount = 0

DELETE FROM [e-commerce_table]
WHERE Description IN ('Manual', 'POSTAGE', 'Discount', 'SAMPLES', 'CRUK Commission', 'Bank Charges', 'DOTCOM POSTAGE', 'AMAZON FEE')


/*Are there identifiable patterns in return orders across countries and months?*/
/*Country*/
SELECT Country, SUM(CASE  WHEN Quantity < 1 THEN 1 ELSE 0 END) AS ReturnedOrders_Count
FROM [e-commerce_table]
GROUP BY Country
ORDER BY ReturnedOrders_Count DESC

/*Date*/
SELECT MONTH(InvoiceDate) AS Months, YEAR(InvoiceDate) AS Years, SUM(CASE  WHEN Quantity < 1 THEN 1 ELSE 0 END) AS ReturnedOrders_Count
FROM [e-commerce_table]
GROUP BY MONTH(InvoiceDate), YEAR(InvoiceDate)
ORDER BY ReturnedOrders_Count DESC

/*Both*/
SELECT Country, MONTH(InvoiceDate) AS Months, YEAR(InvoiceDate) AS Years, SUM(CASE  WHEN Quantity < 1 THEN 1 ELSE 0 END) AS ReturnedOrders_Count
FROM [e-commerce_table]
GROUP BY Country, MONTH(InvoiceDate), YEAR(InvoiceDate)
ORDER BY ReturnedOrders_Count DESC

/*Product*/
SELECT Country, Description, MONTH(InvoiceDate) AS Months, YEAR(InvoiceDate) AS Years, SUM(CASE  WHEN Quantity < 1 THEN 1 ELSE 0 END) AS ReturnedOrders_Count
FROM [e-commerce_table]
GROUP BY Country, Description, MONTH(InvoiceDate), YEAR(InvoiceDate)
ORDER BY ReturnedOrders_Count DESC

/*Which countries and months contribute the most to total revenue?*/
/*Country*/
SELECT Country, SUM(PurchaseAmount) AS PurchaseAmount 
FROM [e-commerce_table]
GROUP BY Country
ORDER BY PurchaseAmount DESC

/*Date*/
SELECT MONTH(InvoiceDate) AS Months, YEAR(InvoiceDate) AS Years, SUM(PurchaseAmount) AS PurchaseAmount 
FROM [e-commerce_table]
GROUP BY MONTH(InvoiceDate), YEAR(InvoiceDate)
ORDER BY PurchaseAmount DESC

/*Both*/
SELECT Country, MONTH(InvoiceDate) AS Months, YEAR(InvoiceDate) AS Years, SUM(PurchaseAmount) AS PurchaseAmount 
FROM [e-commerce_table]
GROUP BY Country, MONTH(InvoiceDate), YEAR(InvoiceDate)
ORDER BY PurchaseAmount DESC


/*Which products have the highest purchase volume, and what is their contribution to total revenue?*/
/*Quantity*/
SELECT Description, SUM(PurchaseAmount) AS PurchaseAmount, SUM(Quantity) AS TotalQuantity
FROM [e-commerce_table]
WHERE PurchaseAmount > 0 AND Quantity > 0
GROUP BY Description
ORDER BY TotalQuantity DESC

/*Amount*/
SELECT Description, SUM(PurchaseAmount) AS PurchaseAmount, SUM(Quantity) AS TotalQuantity
FROM [e-commerce_table]
WHERE PurchaseAmount > 0 AND Quantity > 0
GROUP BY Description
ORDER BY PurchaseAmount DESC




/*Which products have the highest cancellation volume, and what is their estimated revenue loss contribution?*/
/*Quantity*/
SELECT Description, SUM(ReturnedAmount) AS ReturnedAmount, ABS(SUM(Quantity)) AS ReturnedQuantity
FROM [e-commerce_table]
WHERE Quantity < 0
GROUP BY Description
ORDER BY ReturnedQuantity DESC

/*Amount*/
SELECT Description, SUM(ReturnedAmount) AS ReturnedAmount, ABS(SUM(Quantity)) AS ReturnedQuantity
FROM [e-commerce_table]
WHERE Quantity < 0
GROUP BY Description
ORDER BY ReturnedAmount DESC


/*How have return rates trended over time, and does this vary significantly by country?*/
WITH total_orders AS (SELECT MONTH(InvoiceDate) AS Months, YEAR(InvoiceDate) AS Years, COUNT(Quantity) AS TotalOrders
FROM [e-commerce_table]
GROUP BY MONTH(InvoiceDate), YEAR(InvoiceDate)),
total_returns AS(SELECT MONTH(InvoiceDate) AS Months, YEAR(InvoiceDate) AS Years, COUNT(CASE WHEN Quantity < 0 THEN 1 END) AS TotalReturns
FROM [e-commerce_table]
GROUP BY MONTH(InvoiceDate), YEAR(InvoiceDate))
SELECT total_orders.Months, total_orders.Years, TotalReturns, TotalOrders, CAST(ROUND((TotalReturns*100.0) / TotalOrders, 2) AS DECIMAL(5, 2)) AS ReturnRate
FROM total_orders
JOIN total_returns ON total_orders.Months = total_returns.Months AND total_orders.Years = total_returns.Years
GROUP BY total_orders.Months, total_orders.Years, TotalReturns, TotalOrders
ORDER BY Years DESC, Months DESC

WITH total_orders AS (SELECT Country, MONTH(InvoiceDate) AS Months, YEAR(InvoiceDate) AS Years, COUNT(Quantity) AS TotalOrders
FROM [e-commerce_table]
GROUP BY Country, MONTH(InvoiceDate), YEAR(InvoiceDate)),
total_returns AS(SELECT Country, MONTH(InvoiceDate) AS Months, YEAR(InvoiceDate) AS Years, COUNT(CASE WHEN Quantity < 0 THEN 1 END) AS TotalReturns
FROM [e-commerce_table]
GROUP BY Country, MONTH(InvoiceDate), YEAR(InvoiceDate))
SELECT total_orders.Country, total_orders.Months, total_orders.Years, TotalReturns, TotalOrders, CAST(ROUND((TotalReturns*100.0) / TotalOrders, 2) AS DECIMAL(5, 2)) AS ReturnRate
FROM total_orders
JOIN total_returns ON total_orders.Country = total_returns.Country AND total_orders.Months = total_returns.Months AND total_orders.Years = total_returns.Years
GROUP BY total_orders.Country, total_orders.Months, total_orders.Years, TotalReturns, TotalOrders
ORDER BY TotalReturns DESC


/*Which customers account for the highest cancellation volume, and how does this compare to their overall purchase activity?*/
SELECT CustomerID, SUM(PurchaseAmount) AS PurchaseAmount, COUNT(CASE WHEN InvoiceNo LIKE '%C%' THEN 1 END) As Return_Count, COUNT(CASE WHEN InvoiceNo NOT LIKE '%C%' THEN 1 END) AS Purchase_Count
FROM [e-commerce_table]
WHERE CustomerID != 'No ID'
GROUP BY CustomerID
ORDER BY Return_Count DESC

SELECT CustomerID, SUM(PurchaseAmount) AS PurchaseAmount, COUNT(CASE WHEN InvoiceNo LIKE '%C%' THEN 1 END) As Return_Count, COUNT(CASE WHEN InvoiceNo NOT LIKE '%C%' THEN 1 END) AS Purchase_Count
FROM [e-commerce_table]
WHERE CustomerID != 'No ID'
GROUP BY CustomerID
ORDER BY PurchaseAmount DESC

/*"How does customer retention vary by acquisition cohort?"*/
WITH first_purchase_step AS(SELECT CustomerID, MIN(InvoiceDate) As FirstPurchaseDate 
FROM [e-commerce_table]
GROUP BY CustomerID),

join_step AS (SELECT t.CustomerID, t.InvoiceDate, f.FirstPurchaseDate, 
DATEFROMPARTS(YEAR(f.FirstPurchaseDate), MONTH(f.FirstPurchaseDate), 1) AS CohortMonth, 
DATEDIFF(MONTH, f.FirstPurchaseDate, t.InvoiceDate) AS Period
FROM [e-commerce_table] t
JOIN first_purchase_step f ON t.CustomerID = f.CustomerID),

cohort_data_step AS (SELECT CohortMonth, Period, COUNT(DISTINCT CustomerID) AS ActiveCustomers
FROM join_step
GROUP BY CohortMonth, Period),

cohort_size_step AS (SELECT CohortMonth, COUNT(DISTINCT CustomerID) AS TotalCustomers
FROM join_step
WHERE Period = 0
GROUP BY CohortMonth)

SELECT c.CohortMonth, c.Period, c.ActiveCustomers, s.TotalCustomers, 
CAST(ROUND((c.ActiveCustomers*100.0) / s.TotalCustomers, 2) AS DECIMAL(5, 2)) AS RetentionRate
FROM cohort_data_step c
JOIN cohort_size_step s ON c.CohortMonth = s.CohortMonth
ORDER BY c.CohortMonth, c.Period

