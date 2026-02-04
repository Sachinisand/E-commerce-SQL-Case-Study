-- ============================================================
-- E-commerce SQL Case Study
-- Exploratory Data Analysis Queries
-- ============================================================

-- ============================================================
-- QUERY 1: Dataset Overview
-- ============================================================
-- Purpose: Get high-level understanding of the dataset

SELECT 
    COUNT(*) AS TotalTransactions,
    COUNT(DISTINCT InvoiceNo) AS UniqueInvoices,
    COUNT(DISTINCT CustomerID) AS UniqueCustomers,
    COUNT(DISTINCT StockCode) AS UniqueProducts,
    COUNT(DISTINCT Country) AS UniqueCountries,
    MIN(InvoiceDate) AS EarliestTransaction,
    MAX(InvoiceDate) AS LatestTransaction,
    ROUND(SUM(TotalAmount), 2) AS TotalRevenue,
    ROUND(AVG(TotalAmount), 2) AS AvgOrderValue,
    ROUND(SUM(Quantity), 0) AS TotalQuantitySold
FROM transactions
WHERE Quantity > 0 AND UnitPrice > 0;

-- ============================================================
-- QUERY 2: Transaction Value Distribution
-- ============================================================
-- Purpose: Understand the distribution of transaction amounts

SELECT 
    CASE 
        WHEN TotalAmount < 10 THEN 'Under £10'
        WHEN TotalAmount < 25 THEN '£10-£25'
        WHEN TotalAmount < 50 THEN '£25-£50'
        WHEN TotalAmount < 100 THEN '£50-£100'
        ELSE 'Over £100'
    END AS ValueRange,
    COUNT(*) AS TransactionCount,
    ROUND(AVG(TotalAmount), 2) AS AvgValue,
    ROUND(SUM(TotalAmount), 2) AS TotalValue,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS PercentageOfTransactions
FROM transactions
WHERE Quantity > 0 AND UnitPrice > 0
GROUP BY 
    CASE 
        WHEN TotalAmount < 10 THEN 'Under £10'
        WHEN TotalAmount < 25 THEN '£10-£25'
        WHEN TotalAmount < 50 THEN '£25-£50'
        WHEN TotalAmount < 100 THEN '£50-£100'
        ELSE 'Over £100'
    END
ORDER BY 
    CASE 
        WHEN TotalAmount < 10 THEN 1
        WHEN TotalAmount < 25 THEN 2
        WHEN TotalAmount < 50 THEN 3
        WHEN TotalAmount < 100 THEN 4
        ELSE 5
    END;

-- ============================================================
-- QUERY 3: Top 10 Countries by Revenue
-- ============================================================
-- Purpose: Identify geographic concentration of revenue

SELECT TOP 10
    Country,
    COUNT(DISTINCT InvoiceNo) AS OrderCount,
    COUNT(DISTINCT CustomerID) AS CustomerCount,
    ROUND(SUM(Quantity), 0) AS TotalQuantity,
    ROUND(SUM(TotalAmount), 2) AS TotalRevenue,
    ROUND(AVG(TotalAmount), 2) AS AvgOrderValue,
    ROUND(100.0 * SUM(TotalAmount) / SUM(SUM(TotalAmount)) OVER(), 2) AS RevenuePercentage
FROM transactions
WHERE Quantity > 0 AND UnitPrice > 0
GROUP BY Country
ORDER BY TotalRevenue DESC;

-- ============================================================
-- QUERY 4: Top 20 Products by Revenue
-- ============================================================
-- Purpose: Identify best-performing products

SELECT TOP 20
    StockCode,
    Description,
    COUNT(DISTINCT InvoiceNo) AS TimesPurchased,
    SUM(Quantity) AS TotalQuantity,
    ROUND(AVG(UnitPrice), 2) AS AvgPrice,
    ROUND(SUM(TotalAmount), 2) AS TotalRevenue,
    ROUND(100.0 * SUM(TotalAmount) / SUM(SUM(TotalAmount)) OVER(), 2) AS RevenuePercentage
FROM transactions
WHERE Quantity > 0 AND UnitPrice > 0
GROUP BY StockCode, Description
ORDER BY TotalRevenue DESC;

-- ============================================================
-- QUERY 5: Monthly Revenue Trend
-- ============================================================
-- Purpose: Identify seasonal patterns

SELECT 
    YEAR(InvoiceDate) AS Year,
    MONTH(InvoiceDate) AS Month,
    DATEFROMPARTS(YEAR(InvoiceDate), MONTH(InvoiceDate), 1) AS MonthStart,
    COUNT(DISTINCT InvoiceNo) AS OrderCount,
    COUNT(DISTINCT CustomerID) AS ActiveCustomers,
    ROUND(SUM(Quantity), 0) AS TotalQuantity,
    ROUND(SUM(TotalAmount), 2) AS MonthlyRevenue,
    ROUND(AVG(TotalAmount), 2) AS AvgOrderValue,
    ROUND(LAG(SUM(TotalAmount)) OVER(ORDER BY YEAR(InvoiceDate), MONTH(InvoiceDate)), 2) AS PrevMonthRevenue,
    ROUND(
        100.0 * (SUM(TotalAmount) - LAG(SUM(TotalAmount)) OVER(ORDER BY YEAR(InvoiceDate), MONTH(InvoiceDate))) 
        / LAG(SUM(TotalAmount)) OVER(ORDER BY YEAR(InvoiceDate), MONTH(InvoiceDate)), 
        2
    ) AS MoMGrowthPercent
FROM transactions
WHERE Quantity > 0 AND UnitPrice > 0
GROUP BY YEAR(InvoiceDate), MONTH(InvoiceDate)
ORDER BY Year, Month;

-- ============================================================
-- QUERY 6: Customer Purchase Frequency
-- ============================================================
-- Purpose: Identify customer engagement levels

SELECT 
    PurchaseFrequency,
    COUNT(DISTINCT CustomerID) AS CustomerCount,
    ROUND(100.0 * COUNT(DISTINCT CustomerID) / SUM(COUNT(DISTINCT CustomerID)) OVER(), 2) AS PercentageOfCustomers,
    ROUND(AVG(AvgOrderValue), 2) AS AvgOrderValue,
    ROUND(SUM(TotalSpent), 2) AS TotalRevenue
FROM (
    SELECT 
        CustomerID,
        COUNT(DISTINCT InvoiceNo) AS PurchaseFrequency,
        ROUND(AVG(TotalAmount), 2) AS AvgOrderValue,
        ROUND(SUM(TotalAmount), 2) AS TotalSpent,
        CASE 
            WHEN COUNT(DISTINCT InvoiceNo) = 1 THEN 'One-time'
            WHEN COUNT(DISTINCT InvoiceNo) BETWEEN 2 AND 5 THEN '2-5 purchases'
            WHEN COUNT(DISTINCT InvoiceNo) BETWEEN 6 AND 20 THEN '6-20 purchases'
            ELSE '20+ purchases'
        END AS PurchaseFrequency
    FROM transactions
    WHERE Quantity > 0 AND UnitPrice > 0 AND CustomerID IS NOT NULL
    GROUP BY CustomerID
) freq_analysis
GROUP BY PurchaseFrequency
ORDER BY CustomerCount DESC;

-- ============================================================
-- QUERY 7: Product Category Analysis (by description patterns)
-- ============================================================
-- Purpose: Analyze product categories based on description patterns

SELECT 
    CASE 
        WHEN Description LIKE '%POSTAGE%' THEN 'Postage'
        WHEN Description LIKE '%COAT%' OR Description LIKE '%JUMPER%' THEN 'Apparel'
        WHEN Description LIKE '%LIGHT%' OR Description LIKE '%LAMP%' THEN 'Lighting'
        WHEN Description LIKE '%PLATE%' OR Description LIKE '%BOWL%' OR Description LIKE '%MUG%' THEN 'Dinnerware'
        WHEN Description LIKE '%TOY%' OR Description LIKE '%DOLL%' OR Description LIKE '%PLAYHOUSE%' THEN 'Toys'
        WHEN Description LIKE '%DECORATION%' OR Description LIKE '%ORNAMENT%' THEN 'Decorations'
        WHEN Description LIKE '%BOX%' OR Description LIKE '%STORAGE%' THEN 'Storage'
        WHEN Description LIKE '%BATH%' OR Description LIKE '%TOWEL%' THEN 'Bath'
        ELSE 'Other'
    END AS ProductCategory,
    COUNT(DISTINCT StockCode) AS UniqueProducts,
    COUNT(DISTINCT InvoiceNo) AS PurchaseCount,
    SUM(Quantity) AS TotalQuantity,
    ROUND(SUM(TotalAmount), 2) AS CategoryRevenue,
    ROUND(AVG(UnitPrice), 2) AS AvgPrice,
    ROUND(100.0 * SUM(TotalAmount) / SUM(SUM(TotalAmount)) OVER(), 2) AS RevenuePercentage
FROM transactions
WHERE Quantity > 0 AND UnitPrice > 0
GROUP BY 
    CASE 
        WHEN Description LIKE '%POSTAGE%' THEN 'Postage'
        WHEN Description LIKE '%COAT%' OR Description LIKE '%JUMPER%' THEN 'Apparel'
        WHEN Description LIKE '%LIGHT%' OR Description LIKE '%LAMP%' THEN 'Lighting'
        WHEN Description LIKE '%PLATE%' OR Description LIKE '%BOWL%' OR Description LIKE '%MUG%' THEN 'Dinnerware'
        WHEN Description LIKE '%TOY%' OR Description LIKE '%DOLL%' OR Description LIKE '%PLAYHOUSE%' THEN 'Toys'
        WHEN Description LIKE '%DECORATION%' OR Description LIKE '%ORNAMENT%' THEN 'Decorations'
        WHEN Description LIKE '%BOX%' OR Description LIKE '%STORAGE%' THEN 'Storage'
        WHEN Description LIKE '%BATH%' OR Description LIKE '%TOWEL%' THEN 'Bath'
        ELSE 'Other'
    END
ORDER BY CategoryRevenue DESC;

-- ============================================================
-- QUERY 8: Data Quality Summary
-- ============================================================
-- Purpose: Overall data quality assessment

SELECT 
    'Total Records' AS Metric,
    COUNT(*) AS Value
FROM transactions
UNION ALL
SELECT 'Records with NULL CustomerID', COUNT(*) FROM transactions WHERE CustomerID IS NULL
UNION ALL
SELECT 'Negative Quantity Records', COUNT(*) FROM transactions WHERE Quantity < 0
UNION ALL
SELECT 'Zero/Negative Price Records', COUNT(*) FROM transactions WHERE UnitPrice <= 0
UNION ALL
SELECT 'Cancellation Records (C prefix)', COUNT(*) FROM transactions WHERE InvoiceNo LIKE 'C%'
UNION ALL
SELECT 'Valid Records (for analysis)', COUNT(*) FROM transactions WHERE Quantity > 0 AND UnitPrice > 0 AND CustomerID IS NOT NULL;

-- ============================================================
-- End of Exploratory Analysis
-- ============================================================
