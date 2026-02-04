-- ============================================================
-- E-commerce SQL Case Study
-- Sales Analysis
-- ============================================================

-- ============================================================
-- QUERY 1: Monthly Revenue Trends with Year-over-Year Comparison
-- ============================================================
-- Purpose: Identify seasonal patterns and growth trends

SELECT 
    FORMAT(InvoiceDate, 'yyyy-MM') AS YearMonth,
    YEAR(InvoiceDate) AS Year,
    MONTH(InvoiceDate) AS Month,
    COUNT(DISTINCT InvoiceNo) AS OrderCount,
    COUNT(DISTINCT CustomerID) AS ActiveCustomers,
    SUM(Quantity) AS TotalQuantity,
    ROUND(SUM(TotalAmount), 2) AS MonthlyRevenue,
    ROUND(AVG(TotalAmount), 2) AS AvgOrderValue,
    ROUND(SUM(TotalAmount) / NULLIF(COUNT(DISTINCT CustomerID), 0), 2) AS RevenuePerCustomer,
    ROUND(
        100.0 * (SUM(TotalAmount) - LAG(SUM(TotalAmount)) OVER(ORDER BY YEAR(InvoiceDate), MONTH(InvoiceDate)))
        / LAG(SUM(TotalAmount)) OVER(ORDER BY YEAR(InvoiceDate), MONTH(InvoiceDate)),
        2
    ) AS MoMGrowthPercent
FROM transactions
WHERE Quantity > 0 AND UnitPrice > 0
GROUP BY FORMAT(InvoiceDate, 'yyyy-MM'), YEAR(InvoiceDate), MONTH(InvoiceDate)
ORDER BY Year, Month;

-- ============================================================
-- QUERY 2: Weekly Sales Performance
-- ============================================================
-- Purpose: Identify best performing days and weekly patterns

SELECT 
    CAST(InvoiceDate AS DATE) AS SalesDate,
    DATENAME(WEEKDAY, InvoiceDate) AS DayOfWeek,
    DATEPART(WEEKDAY, InvoiceDate) AS DayOfWeekNumber,
    COUNT(DISTINCT InvoiceNo) AS OrderCount,
    COUNT(DISTINCT CustomerID) AS CustomerCount,
    SUM(Quantity) AS TotalQuantity,
    ROUND(SUM(TotalAmount), 2) AS DailyRevenue,
    ROUND(AVG(TotalAmount), 2) AS AvgOrderValue,
    ROUND(SUM(TotalAmount) / NULLIF(COUNT(DISTINCT InvoiceNo), 0), 2) AS RevenuePerOrder
FROM transactions
WHERE Quantity > 0 AND UnitPrice > 0
GROUP BY CAST(InvoiceDate AS DATE), DATENAME(WEEKDAY, InvoiceDate), DATEPART(WEEKDAY, InvoiceDate)
ORDER BY SalesDate DESC;

-- ============================================================
-- QUERY 3: Hourly Sales Pattern
-- ============================================================
-- Purpose: Understand intra-day buying patterns

SELECT 
    DATEPART(HOUR, InvoiceDate) AS HourOfDay,
    COUNT(DISTINCT InvoiceNo) AS OrderCount,
    COUNT(DISTINCT CustomerID) AS UniqueCustomers,
    SUM(Quantity) AS TotalQuantity,
    ROUND(SUM(TotalAmount), 2) AS HourlyRevenue,
    ROUND(AVG(TotalAmount), 2) AS AvgOrderValue,
    ROUND(100.0 * SUM(TotalAmount) / SUM(SUM(TotalAmount)) OVER(), 2) AS PercentageOfDailyRevenue
FROM transactions
WHERE Quantity > 0 AND UnitPrice > 0
GROUP BY DATEPART(HOUR, InvoiceDate)
ORDER BY HourOfDay;

-- ============================================================
-- QUERY 4: Top Revenue Generating Days
-- ============================================================
-- Purpose: Identify peak sales dates

SELECT 
    TOP 20
    CAST(InvoiceDate AS DATE) AS SalesDate,
    DATENAME(WEEKDAY, InvoiceDate) AS DayOfWeek,
    COUNT(DISTINCT InvoiceNo) AS OrderCount,
    COUNT(DISTINCT CustomerID) AS CustomerCount,
    SUM(Quantity) AS QuantitySold,
    ROUND(SUM(TotalAmount), 2) AS DailyRevenue,
    ROUND(AVG(TotalAmount), 2) AS AvgOrderValue,
    ROUND(100.0 * SUM(TotalAmount) / SUM(SUM(TotalAmount)) OVER(), 2) AS PercentageOfTotalRevenue
FROM transactions
WHERE Quantity > 0 AND UnitPrice > 0
GROUP BY CAST(InvoiceDate AS DATE), DATENAME(WEEKDAY, InvoiceDate)
ORDER BY DailyRevenue DESC;

-- ============================================================
-- QUERY 5: Average Order Value Trend
-- ============================================================
-- Purpose: Track AOV changes over time

SELECT 
    FORMAT(InvoiceDate, 'yyyy-MM') AS YearMonth,
    ROUND(AVG(TotalAmount), 2) AS AvgOrderValue,
    ROUND(STDEV(TotalAmount), 2) AS StdDevOrderValue,
    MIN(TotalAmount) AS MinOrderValue,
    MAX(TotalAmount) AS MaxOrderValue,
    PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY TotalAmount) OVER() AS MedianOrderValue,
    COUNT(DISTINCT InvoiceNo) AS OrderCount
FROM transactions
WHERE Quantity > 0 AND UnitPrice > 0
GROUP BY FORMAT(InvoiceDate, 'yyyy-MM')
ORDER BY YearMonth;

-- ============================================================
-- QUERY 6: Sales Performance by Geographic Region
-- ============================================================
-- Purpose: Compare revenue performance across countries

SELECT 
    Country,
    ROUND(SUM(TotalAmount), 2) AS TotalRevenue,
    COUNT(DISTINCT InvoiceNo) AS OrderCount,
    COUNT(DISTINCT CustomerID) AS UniqueCustomers,
    ROUND(SUM(TotalAmount) / COUNT(DISTINCT InvoiceNo), 2) AS AvgOrderValue,
    ROUND(SUM(Quantity), 0) AS TotalQuantity,
    ROUND(SUM(TotalAmount) / COUNT(DISTINCT CustomerID), 2) AS RevenuePerCustomer,
    ROUND(100.0 * COUNT(DISTINCT InvoiceNo) / SUM(COUNT(DISTINCT InvoiceNo)) OVER(), 2) AS PercentageOfOrders,
    ROUND(100.0 * SUM(TotalAmount) / SUM(SUM(TotalAmount)) OVER(), 2) AS PercentageOfRevenue
FROM transactions
WHERE Quantity > 0 AND UnitPrice > 0
GROUP BY Country
ORDER BY TotalRevenue DESC;

-- ============================================================
-- QUERY 7: Cumulative Revenue (Running Total)
-- ============================================================
-- Purpose: Track cumulative revenue growth

SELECT 
    FORMAT(InvoiceDate, 'yyyy-MM') AS YearMonth,
    ROUND(SUM(TotalAmount), 2) AS MonthlyRevenue,
    ROUND(SUM(SUM(TotalAmount)) OVER(ORDER BY YEAR(InvoiceDate), MONTH(InvoiceDate) ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 2) AS CumulativeRevenue
FROM transactions
WHERE Quantity > 0 AND UnitPrice > 0
GROUP BY FORMAT(InvoiceDate, 'yyyy-MM'), YEAR(InvoiceDate), MONTH(InvoiceDate)
ORDER BY YearMonth;

-- ============================================================
-- QUERY 8: Revenue Distribution (Pareto Analysis)
-- ============================================================
-- Purpose: Identify which orders drive 80% of revenue (80/20 rule)

WITH OrderedRevenue AS (
    SELECT 
        ROW_NUMBER() OVER(ORDER BY TotalAmount DESC) AS OrderRank,
        TotalAmount,
        SUM(TotalAmount) OVER(ORDER BY TotalAmount DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS CumulativeRevenue,
        SUM(SUM(TotalAmount)) OVER() AS TotalRevenue
    FROM transactions
    WHERE Quantity > 0 AND UnitPrice > 0
)
SELECT 
    CASE 
        WHEN CumulativeRevenue / TotalRevenue <= 0.20 THEN 'Top 20% - High Value'
        WHEN CumulativeRevenue / TotalRevenue <= 0.50 THEN 'Next 30% - Medium Value'
        ELSE 'Bottom 50% - Low Value'
    END AS RevenueSegment,
    COUNT(*) AS OrderCount,
    ROUND(SUM(TotalAmount), 2) AS SegmentRevenue,
    ROUND(100.0 * SUM(TotalAmount) / SUM(SUM(TotalAmount)) OVER(), 2) AS PercentageOfTotal,
    ROUND(AVG(TotalAmount), 2) AS AvgOrderValue
FROM OrderedRevenue
GROUP BY 
    CASE 
        WHEN CumulativeRevenue / TotalRevenue <= 0.20 THEN 'Top 20% - High Value'
        WHEN CumulativeRevenue / TotalRevenue <= 0.50 THEN 'Next 30% - Medium Value'
        ELSE 'Bottom 50% - Low Value'
    END
ORDER BY SegmentRevenue DESC;

-- ============================================================
-- QUERY 9: Sales Velocity - Orders Per Day
-- ============================================================
-- Purpose: Measure sales momentum

SELECT 
    FORMAT(InvoiceDate, 'yyyy-MM') AS YearMonth,
    COUNT(DISTINCT CAST(InvoiceDate AS DATE)) AS ActiveSalesDays,
    COUNT(DISTINCT InvoiceNo) AS TotalOrders,
    ROUND(CAST(COUNT(DISTINCT InvoiceNo) AS FLOAT) / COUNT(DISTINCT CAST(InvoiceDate AS DATE)), 2) AS OrdersPerDay,
    ROUND(SUM(TotalAmount), 2) AS MonthlyRevenue,
    ROUND(SUM(TotalAmount) / COUNT(DISTINCT CAST(InvoiceDate AS DATE)), 2) AS RevenuePerDay
FROM transactions
WHERE Quantity > 0 AND UnitPrice > 0
GROUP BY FORMAT(InvoiceDate, 'yyyy-MM'), YEAR(InvoiceDate), MONTH(InvoiceDate)
ORDER BY YearMonth;

-- ============================================================
-- QUERY 10: Basket Size Analysis
-- ============================================================
-- Purpose: Analyze average items per transaction

SELECT 
    FORMAT(InvoiceDate, 'yyyy-MM') AS YearMonth,
    COUNT(DISTINCT InvoiceNo) AS OrderCount,
    ROUND(SUM(Quantity) / CAST(COUNT(DISTINCT InvoiceNo) AS FLOAT), 2) AS AvgItemsPerOrder,
    ROUND(SUM(TotalAmount) / CAST(COUNT(DISTINCT InvoiceNo) AS FLOAT), 2) AS AvgOrderValue,
    MIN(Quantity) AS MinItemsPerOrder,
    MAX(Quantity) AS MaxItemsPerOrder,
    PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY Quantity) OVER() AS MedianItemsPerOrder
FROM transactions
WHERE Quantity > 0 AND UnitPrice > 0
GROUP BY FORMAT(InvoiceDate, 'yyyy-MM'), YEAR(InvoiceDate), MONTH(InvoiceDate)
ORDER BY YearMonth;

-- ============================================================
-- End of Sales Analysis
-- ============================================================
