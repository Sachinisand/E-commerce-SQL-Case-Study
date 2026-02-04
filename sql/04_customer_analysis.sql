-- ============================================================
-- E-commerce SQL Case Study
-- Customer Analysis & Segmentation
-- ============================================================

-- ============================================================
-- QUERY 1: RFM Analysis (Recency, Frequency, Monetary)
-- ============================================================
-- Purpose: Customer segmentation based on purchase behavior
-- RFM is a powerful technique to identify valuable customers

WITH CustomerMetrics AS (
    SELECT 
        CustomerID,
        COUNT(DISTINCT InvoiceNo) AS PurchaseFrequency,
        SUM(TotalAmount) AS MonetaryValue,
        DATEDIFF(DAY, MAX(InvoiceDate), GETDATE()) AS DaysSinceLastPurchase,
        MIN(InvoiceDate) AS FirstPurchaseDate,
        MAX(InvoiceDate) AS LastPurchaseDate,
        DATEDIFF(DAY, MIN(InvoiceDate), MAX(InvoiceDate)) AS CustomerLifespanDays
    FROM transactions
    WHERE Quantity > 0 AND UnitPrice > 0 AND CustomerID IS NOT NULL
    GROUP BY CustomerID
),
RFMScored AS (
    SELECT 
        CustomerID,
        PurchaseFrequency,
        MonetaryValue,
        DaysSinceLastPurchase,
        FirstPurchaseDate,
        LastPurchaseDate,
        CustomerLifespanDays,
        NTILE(5) OVER(ORDER BY DaysSinceLastPurchase DESC) AS RecencyScore,
        NTILE(5) OVER(ORDER BY PurchaseFrequency ASC) AS FrequencyScore,
        NTILE(5) OVER(ORDER BY MonetaryValue ASC) AS MonetaryScore
    FROM CustomerMetrics
)
SELECT 
    CustomerID,
    PurchaseFrequency,
    ROUND(MonetaryValue, 2) AS MonetaryValue,
    DaysSinceLastPurchase,
    FirstPurchaseDate,
    LastPurchaseDate,
    CustomerLifespanDays,
    (RecencyScore + FrequencyScore + MonetaryScore) / 3 AS RFMScore,
    CASE 
        WHEN (RecencyScore + FrequencyScore + MonetaryScore) >= 12 THEN 'Champions'
        WHEN (RecencyScore + FrequencyScore + MonetaryScore) >= 10 THEN 'Loyal Customers'
        WHEN (RecencyScore + FrequencyScore + MonetaryScore) >= 8 THEN 'Potential Loyalists'
        WHEN (RecencyScore + FrequencyScore + MonetaryScore) >= 6 THEN 'At Risk'
        ELSE 'Lost'
    END AS CustomerSegment
FROM RFMScored
WHERE DaysSinceLastPurchase IS NOT NULL
ORDER BY RFMScore DESC;

-- ============================================================
-- QUERY 2: Customer Lifetime Value (CLV) Analysis
-- ============================================================
-- Purpose: Calculate and rank customers by lifetime value

SELECT 
    TOP 50
    CustomerID,
    COUNT(DISTINCT InvoiceNo) AS TotalOrders,
    SUM(Quantity) AS TotalQuantityBought,
    ROUND(SUM(TotalAmount), 2) AS LifetimeValue,
    ROUND(SUM(TotalAmount) / COUNT(DISTINCT InvoiceNo), 2) AS AvgOrderValue,
    ROUND(SUM(TotalAmount) / COUNT(DISTINCT TransactionDate), 2) AS AvgDailySpend,
    MIN(InvoiceDate) AS FirstPurchaseDate,
    MAX(InvoiceDate) AS LastPurchaseDate,
    DATEDIFF(DAY, MIN(InvoiceDate), MAX(InvoiceDate)) AS CustomerLifespanDays,
    (SELECT COUNT(DISTINCT t2.InvoiceDate)
     FROM transactions t2 
     WHERE t2.CustomerID = transactions.CustomerID AND t2.Quantity > 0 AND t2.UnitPrice > 0) 
     AS PurchaseDaysCount,
    ROUND(100.0 * SUM(TotalAmount) / SUM(SUM(TotalAmount)) OVER(), 2) AS PercentageOfTotalRevenue
FROM transactions
WHERE Quantity > 0 AND UnitPrice > 0 AND CustomerID IS NOT NULL
GROUP BY CustomerID
ORDER BY LifetimeValue DESC;

-- ============================================================
-- QUERY 3: Customer Segmentation by Value Tiers
-- ============================================================
-- Purpose: Segment customers into value tiers for targeted marketing

WITH CustomerRevenue AS (
    SELECT 
        CustomerID,
        ROUND(SUM(TotalAmount), 2) AS TotalRevenue,
        COUNT(DISTINCT InvoiceNo) AS OrderCount,
        ROUND(AVG(TotalAmount), 2) AS AvgOrderValue
    FROM transactions
    WHERE Quantity > 0 AND UnitPrice > 0 AND CustomerID IS NOT NULL
    GROUP BY CustomerID
),
RevenueQuartiles AS (
    SELECT 
        CustomerID,
        TotalRevenue,
        OrderCount,
        AvgOrderValue,
        PERCENT_RANK() OVER(ORDER BY TotalRevenue) AS RevenuePercentile
    FROM CustomerRevenue
)
SELECT 
    CASE 
        WHEN RevenuePercentile >= 0.75 THEN 'Top Tier (VIP)'
        WHEN RevenuePercentile >= 0.50 THEN 'Mid-High Tier'
        WHEN RevenuePercentile >= 0.25 THEN 'Mid Tier'
        ELSE 'Entry Tier'
    END AS CustomerTier,
    COUNT(DISTINCT CustomerID) AS CustomerCount,
    ROUND(AVG(TotalRevenue), 2) AS AvgCustomerValue,
    ROUND(MIN(TotalRevenue), 2) AS MinValue,
    ROUND(MAX(TotalRevenue), 2) AS MaxValue,
    ROUND(SUM(TotalRevenue), 2) AS TierTotalRevenue,
    ROUND(100.0 * SUM(TotalRevenue) / SUM(SUM(TotalRevenue)) OVER(), 2) AS PercentageOfRevenue,
    ROUND(AVG(OrderCount), 1) AS AvgOrdersPerCustomer
FROM RevenueQuartiles
GROUP BY 
    CASE 
        WHEN RevenuePercentile >= 0.75 THEN 'Top Tier (VIP)'
        WHEN RevenuePercentile >= 0.50 THEN 'Mid-High Tier'
        WHEN RevenuePercentile >= 0.25 THEN 'Mid Tier'
        ELSE 'Entry Tier'
    END
ORDER BY PercentageOfRevenue DESC;

-- ============================================================
-- QUERY 4: Geographic Customer Analysis
-- ============================================================
-- Purpose: Identify customer patterns by country

SELECT 
    Country,
    COUNT(DISTINCT CustomerID) AS UniqueCustomers,
    COUNT(DISTINCT InvoiceNo) AS TotalOrders,
    ROUND(AVG(TotalAmount), 2) AS AvgOrderValue,
    ROUND(SUM(TotalAmount), 2) AS CountryRevenue,
    ROUND(SUM(Quantity), 0) AS TotalQuantity,
    ROUND(SUM(TotalAmount) / COUNT(DISTINCT CustomerID), 2) AS RevenuePerCustomer,
    ROUND(100.0 * SUM(TotalAmount) / SUM(SUM(TotalAmount)) OVER(), 2) AS PercentageOfRevenue,
    ROUND(100.0 * COUNT(DISTINCT CustomerID) / SUM(COUNT(DISTINCT CustomerID)) OVER(), 2) AS PercentageOfCustomers
FROM transactions
WHERE Quantity > 0 AND UnitPrice > 0 AND CustomerID IS NOT NULL
GROUP BY Country
ORDER BY CountryRevenue DESC;

-- ============================================================
-- QUERY 5: Customer Retention Analysis
-- ============================================================
-- Purpose: Measure customer retention rates

WITH FirstPurchase AS (
    SELECT 
        CustomerID,
        MIN(CAST(InvoiceDate AS DATE)) AS FirstPurchaseDate
    FROM transactions
    WHERE Quantity > 0 AND UnitPrice > 0 AND CustomerID IS NOT NULL
    GROUP BY CustomerID
),
MonthlyPurchases AS (
    SELECT 
        fp.CustomerID,
        YEAR(t.InvoiceDate) AS PurchaseYear,
        MONTH(t.InvoiceDate) AS PurchaseMonth,
        fp.FirstPurchaseDate,
        CAST(t.InvoiceDate AS DATE) AS PurchaseDate
    FROM transactions t
    INNER JOIN FirstPurchase fp ON t.CustomerID = fp.CustomerID
    WHERE t.Quantity > 0 AND t.UnitPrice > 0 AND t.CustomerID IS NOT NULL
)
SELECT 
    DATEFROMPARTS(PurchaseYear, PurchaseMonth, 1) AS CohortMonth,
    COUNT(DISTINCT CustomerID) AS CohortSize,
    SUM(CASE WHEN LAG(CustomerID) OVER(PARTITION BY CustomerID ORDER BY PurchaseYear, PurchaseMonth) IS NOT NULL 
             THEN 1 ELSE 0 END) AS RetainedCustomers,
    ROUND(100.0 * SUM(CASE WHEN LAG(CustomerID) OVER(PARTITION BY CustomerID ORDER BY PurchaseYear, PurchaseMonth) IS NOT NULL 
                           THEN 1 ELSE 0 END) / COUNT(DISTINCT CustomerID), 2) AS RetentionRate
FROM MonthlyPurchases
WHERE PurchaseDate = DATEFROMPARTS(PurchaseYear, PurchaseMonth, 1)
GROUP BY DATEFROMPARTS(PurchaseYear, PurchaseMonth, 1)
ORDER BY CohortMonth;

-- ============================================================
-- QUERY 6: Repeat Purchase Rate
-- ============================================================
-- Purpose: Identify percentage of repeat customers

WITH CustomerPurchases AS (
    SELECT 
        CustomerID,
        COUNT(DISTINCT InvoiceNo) AS PurchaseCount
    FROM transactions
    WHERE Quantity > 0 AND UnitPrice > 0 AND CustomerID IS NOT NULL
    GROUP BY CustomerID
)
SELECT 
    'Customer Repeat Analysis' AS Metric,
    COUNT(*) AS TotalCustomers,
    SUM(CASE WHEN PurchaseCount = 1 THEN 1 ELSE 0 END) AS OneTimeCustomers,
    SUM(CASE WHEN PurchaseCount > 1 THEN 1 ELSE 0 END) AS RepeatCustomers,
    ROUND(100.0 * SUM(CASE WHEN PurchaseCount > 1 THEN 1 ELSE 0 END) / COUNT(*), 2) AS RepeatCustomerPercentage,
    ROUND(AVG(CAST(PurchaseCount AS FLOAT)), 2) AS AvgPurchasesPerCustomer,
    MAX(PurchaseCount) AS MaxPurchasesByOneCustomer
FROM CustomerPurchases;

-- ============================================================
-- QUERY 7: Customer Acquisition Cost Insights
-- ============================================================
-- Purpose: Understand new customer acquisition patterns

SELECT 
    YEAR(FirstPurchaseDate) AS AcquisitionYear,
    MONTH(FirstPurchaseDate) AS AcquisitionMonth,
    COUNT(DISTINCT CustomerID) AS NewCustomers,
    ROUND(SUM(LifetimeValue), 2) AS TotalLTVNewCustomers,
    ROUND(AVG(LifetimeValue), 2) AS AvgLTVNewCustomers,
    ROUND(SUM(TotalOrders), 0) AS TotalOrdersNewCustomers
FROM (
    SELECT 
        CustomerID,
        MIN(InvoiceDate) AS FirstPurchaseDate,
        COUNT(DISTINCT InvoiceNo) AS TotalOrders,
        SUM(TotalAmount) AS LifetimeValue
    FROM transactions
    WHERE Quantity > 0 AND UnitPrice > 0 AND CustomerID IS NOT NULL
    GROUP BY CustomerID
) new_customers
GROUP BY YEAR(FirstPurchaseDate), MONTH(FirstPurchaseDate)
ORDER BY AcquisitionYear, AcquisitionMonth;

-- ============================================================
-- End of Customer Analysis
-- ============================================================
