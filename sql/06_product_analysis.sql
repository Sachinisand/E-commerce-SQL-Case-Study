-- ============================================================
-- E-commerce SQL Case Study
-- Product Analysis
-- ============================================================

-- ============================================================
-- QUERY 1: Top 30 Products by Revenue
-- ============================================================
-- Purpose: Identify best-selling products

SELECT 
    TOP 30
    StockCode,
    Description,
    COUNT(DISTINCT InvoiceNo) AS TimesPurchased,
    SUM(Quantity) AS TotalQuantitySold,
    ROUND(AVG(UnitPrice), 2) AS AvgUnitPrice,
    ROUND(MIN(UnitPrice), 2) AS MinPrice,
    ROUND(MAX(UnitPrice), 2) AS MaxPrice,
    ROUND(SUM(TotalAmount), 2) AS TotalRevenue,
    ROUND(100.0 * SUM(TotalAmount) / SUM(SUM(TotalAmount)) OVER(), 2) AS PercentageOfRevenue,
    ROUND(SUM(TotalAmount) / COUNT(DISTINCT InvoiceNo), 2) AS AvgRevenuePerPurchase
FROM transactions
WHERE Quantity > 0 AND UnitPrice > 0
GROUP BY StockCode, Description
ORDER BY TotalRevenue DESC;

-- ============================================================
-- QUERY 2: Product Popularity by Purchase Frequency
-- ============================================================
-- Purpose: Identify most frequently purchased items

SELECT 
    TOP 30
    StockCode,
    Description,
    COUNT(DISTINCT InvoiceNo) AS PurchaseFrequency,
    ROUND(SUM(Quantity), 0) AS TotalQuantity,
    ROUND(AVG(Quantity), 2) AS AvgQuantityPerPurchase,
    ROUND(SUM(TotalAmount), 2) AS TotalRevenue,
    ROUND(100.0 * COUNT(DISTINCT InvoiceNo) / SUM(COUNT(DISTINCT InvoiceNo)) OVER(), 2) AS PercentageOfOrders
FROM transactions
WHERE Quantity > 0 AND UnitPrice > 0
GROUP BY StockCode, Description
ORDER BY PurchaseFrequency DESC;

-- ============================================================
-- QUERY 3: Product Price Analysis
-- ============================================================
-- Purpose: Analyze pricing patterns and distribution

SELECT 
    CASE 
        WHEN UnitPrice < 1 THEN 'Under £1'
        WHEN UnitPrice < 3 THEN '£1-£3'
        WHEN UnitPrice < 5 THEN '£3-£5'
        WHEN UnitPrice < 10 THEN '£5-£10'
        ELSE 'Over £10'
    END AS PriceRange,
    COUNT(DISTINCT StockCode) AS UniqueProducts,
    COUNT(DISTINCT InvoiceNo) AS PurchaseCount,
    SUM(Quantity) AS QuantitySold,
    ROUND(SUM(TotalAmount), 2) AS TotalRevenue,
    ROUND(100.0 * SUM(TotalAmount) / SUM(SUM(TotalAmount)) OVER(), 2) AS PercentageOfRevenue,
    ROUND(AVG(UnitPrice), 2) AS AvgPrice,
    ROUND(AVG(Quantity), 2) AS AvgQuantity
FROM transactions
WHERE Quantity > 0 AND UnitPrice > 0
GROUP BY 
    CASE 
        WHEN UnitPrice < 1 THEN 'Under £1'
        WHEN UnitPrice < 3 THEN '£1-£3'
        WHEN UnitPrice < 5 THEN '£3-£5'
        WHEN UnitPrice < 10 THEN '£5-£10'
        ELSE 'Over £10'
    END
ORDER BY CASE 
    WHEN UnitPrice < 1 THEN 1
    WHEN UnitPrice < 3 THEN 2
    WHEN UnitPrice < 5 THEN 3
    WHEN UnitPrice < 10 THEN 4
    ELSE 5
END;

-- ============================================================
-- QUERY 4: Product Lifecycle Analysis
-- ============================================================
-- Purpose: Identify product trends (growing, stable, declining)

WITH ProductTimeline AS (
    SELECT 
        StockCode,
        Description,
        YEAR(InvoiceDate) AS Year,
        MONTH(InvoiceDate) AS Month,
        SUM(Quantity) AS MonthlyQuantity,
        SUM(TotalAmount) AS MonthlyRevenue,
        COUNT(DISTINCT InvoiceNo) AS MonthlySales
    FROM transactions
    WHERE Quantity > 0 AND UnitPrice > 0
    GROUP BY StockCode, Description, YEAR(InvoiceDate), MONTH(InvoiceDate)
)
SELECT 
    StockCode,
    Description,
    COUNT(DISTINCT CONCAT(Year, '-', Month)) AS MonthsActive,
    SUM(MonthlyQuantity) AS TotalQuantity,
    ROUND(SUM(MonthlyRevenue), 2) AS TotalRevenue,
    SUM(MonthlySales) AS TotalSales,
    ROUND(AVG(MonthlyQuantity), 2) AS AvgMonthlyQuantity,
    CASE 
        WHEN COUNT(DISTINCT CONCAT(Year, '-', Month)) <= 3 THEN 'New Product'
        WHEN COUNT(DISTINCT CONCAT(Year, '-', Month)) > 9 THEN 'Mature Product'
        ELSE 'Growing Product'
    END AS ProductPhase
FROM ProductTimeline
GROUP BY StockCode, Description
ORDER BY TotalRevenue DESC;

-- ============================================================
-- QUERY 5: Top SKUs by Country
-- ============================================================
-- Purpose: Identify regional product preferences

SELECT 
    Country,
    StockCode,
    Description,
    COUNT(DISTINCT InvoiceNo) AS PurchaseCount,
    SUM(Quantity) AS QuantitySold,
    ROUND(SUM(TotalAmount), 2) AS CountryProductRevenue,
    RANK() OVER(PARTITION BY Country ORDER BY SUM(TotalAmount) DESC) AS CountryProductRank
FROM transactions
WHERE Quantity > 0 AND UnitPrice > 0
GROUP BY Country, StockCode, Description
HAVING RANK() OVER(PARTITION BY Country ORDER BY SUM(TotalAmount) DESC) <= 5
ORDER BY Country, CountryProductRank;

-- ============================================================
-- QUERY 6: Product Performance Matrix (High Revenue, High Frequency)
-- ============================================================
-- Purpose: Segment products by revenue and popularity

WITH ProductMetrics AS (
    SELECT 
        StockCode,
        Description,
        COUNT(DISTINCT InvoiceNo) AS PurchaseFrequency,
        ROUND(SUM(TotalAmount), 2) AS TotalRevenue,
        ROW_NUMBER() OVER(ORDER BY COUNT(DISTINCT InvoiceNo) DESC) AS FrequencyRank,
        ROW_NUMBER() OVER(ORDER BY SUM(TotalAmount) DESC) AS RevenueRank
    FROM transactions
    WHERE Quantity > 0 AND UnitPrice > 0
    GROUP BY StockCode, Description
),
MedianMetrics AS (
    SELECT 
        PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY PurchaseFrequency) OVER() AS MedianFrequency,
        PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY TotalRevenue) OVER() AS MedianRevenue
    FROM ProductMetrics
)
SELECT 
    pm.StockCode,
    pm.Description,
    pm.PurchaseFrequency,
    pm.TotalRevenue,
    CASE 
        WHEN pm.PurchaseFrequency >= (SELECT MedianFrequency FROM MedianMetrics) 
         AND pm.TotalRevenue >= (SELECT MedianRevenue FROM MedianMetrics) THEN 'Star Products'
        WHEN pm.PurchaseFrequency >= (SELECT MedianFrequency FROM MedianMetrics) 
         AND pm.TotalRevenue < (SELECT MedianRevenue FROM MedianMetrics) THEN 'Workhorse Products'
        WHEN pm.PurchaseFrequency < (SELECT MedianFrequency FROM MedianMetrics) 
         AND pm.TotalRevenue >= (SELECT MedianRevenue FROM MedianMetrics) THEN 'Niche Products'
        ELSE 'Underperformers'
    END AS ProductCategory
FROM ProductMetrics pm
ORDER BY pm.TotalRevenue DESC;

-- ============================================================
-- QUERY 7: Product Diversification Analysis
-- ============================================================
-- Purpose: Analyze customer product purchase patterns

SELECT 
    'Product Diversity Metrics' AS Metric,
    COUNT(DISTINCT StockCode) AS TotalUniqueProducts,
    COUNT(DISTINCT InvoiceNo) AS TotalOrders,
    ROUND(CAST(COUNT(DISTINCT StockCode) AS FLOAT) / COUNT(DISTINCT InvoiceNo), 2) AS AvgProductsPerOrder,
    COUNT(DISTINCT CASE WHEN InvoiceNo IN 
        (SELECT InvoiceNo FROM transactions GROUP BY InvoiceNo HAVING COUNT(DISTINCT StockCode) = 1)
    THEN InvoiceNo END) AS SingleProductOrders,
    COUNT(DISTINCT CASE WHEN InvoiceNo IN 
        (SELECT InvoiceNo FROM transactions GROUP BY InvoiceNo HAVING COUNT(DISTINCT StockCode) > 1)
    THEN InvoiceNo END) AS MultiProductOrders
FROM transactions
WHERE Quantity > 0 AND UnitPrice > 0;

-- ============================================================
-- QUERY 8: Product Return/Cancellation Analysis
-- ============================================================
-- Purpose: Identify problematic or returned products

SELECT 
    StockCode,
    Description,
    SUM(CASE WHEN Quantity < 0 THEN 1 ELSE 0 END) AS ReturnCount,
    SUM(CASE WHEN Quantity < 0 THEN ABS(Quantity) ELSE 0 END) AS QuantityReturned,
    ROUND(SUM(CASE WHEN Quantity < 0 THEN TotalAmount ELSE 0 END), 2) AS ReturnValue,
    COUNT(DISTINCT CASE WHEN Quantity > 0 THEN InvoiceNo END) AS SalesCount,
    ROUND(
        100.0 * SUM(CASE WHEN Quantity < 0 THEN 1 ELSE 0 END) 
        / (SUM(CASE WHEN Quantity < 0 THEN 1 ELSE 0 END) + COUNT(DISTINCT CASE WHEN Quantity > 0 THEN InvoiceNo END)),
        2
    ) AS ReturnRate
FROM transactions
WHERE (Quantity < 0 OR Quantity > 0) AND StockCode NOT LIKE 'POST%'
GROUP BY StockCode, Description
HAVING SUM(CASE WHEN Quantity < 0 THEN 1 ELSE 0 END) > 0
ORDER BY ReturnCount DESC;

-- ============================================================
-- QUERY 9: Product Seasonality Analysis
-- ============================================================
-- Purpose: Identify seasonal products

SELECT 
    StockCode,
    Description,
    MONTH(InvoiceDate) AS Month,
    DATENAME(MONTH, DATEFROMPARTS(2010, MONTH(InvoiceDate), 1)) AS MonthName,
    COUNT(DISTINCT InvoiceNo) AS MonthlyPurchases,
    SUM(Quantity) AS MonthlyQuantity,
    ROUND(SUM(TotalAmount), 2) AS MonthlyRevenue
FROM transactions
WHERE Quantity > 0 AND UnitPrice > 0
GROUP BY StockCode, Description, MONTH(InvoiceDate), DATENAME(MONTH, DATEFROMPARTS(2010, MONTH(InvoiceDate), 1))
HAVING COUNT(DISTINCT InvoiceNo) > 5
ORDER BY StockCode, MONTH(InvoiceDate);

-- ============================================================
-- QUERY 10: Cross-Selling Opportunity Analysis
-- ============================================================
-- Purpose: Identify products frequently bought together

WITH ProductCombinations AS (
    SELECT 
        t1.StockCode AS Product1,
        t1.Description AS Product1Desc,
        t2.StockCode AS Product2,
        t2.Description AS Product2Desc,
        COUNT(DISTINCT t1.InvoiceNo) AS CoBuyCount
    FROM transactions t1
    INNER JOIN transactions t2 
        ON t1.InvoiceNo = t2.InvoiceNo 
        AND t1.StockCode < t2.StockCode
        AND t1.Quantity > 0 AND t2.Quantity > 0
        AND t1.UnitPrice > 0 AND t2.UnitPrice > 0
    GROUP BY t1.StockCode, t1.Description, t2.StockCode, t2.Description
)
SELECT 
    TOP 20
    Product1,
    Product1Desc,
    Product2,
    Product2Desc,
    CoBuyCount
FROM ProductCombinations
ORDER BY CoBuyCount DESC;

-- ============================================================
-- End of Product Analysis
-- ============================================================
