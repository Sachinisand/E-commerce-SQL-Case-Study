-- ============================================================
-- E-commerce SQL Case Study
-- Data Loading & Quality Checks
-- ============================================================
-- This script loads data and performs initial quality checks

-- ============================================================
-- SECTION 1: Data Import (Uncomment for your database)
-- ============================================================

-- For MySQL:
/*
LOAD DATA LOCAL INFILE '/path/to/data.csv'
INTO TABLE transactions
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(InvoiceNo, StockCode, Description, Quantity, InvoiceDate, 
 UnitPrice, CustomerID, Country);
*/

-- For SQL Server:
/*
BULK INSERT transactions
FROM '/path/to/data.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FIRSTROW = 2
);
*/

-- For PostgreSQL:
/*
\COPY transactions(InvoiceNo, StockCode, Description, Quantity, 
                   InvoiceDate, UnitPrice, CustomerID, Country) 
FROM '/path/to/data.csv' DELIMITER ',' CSV HEADER;
*/

-- ============================================================
-- SECTION 2: Calculate Derived Columns
-- ============================================================

-- Update TotalAmount
UPDATE transactions 
SET TotalAmount = Quantity * UnitPrice 
WHERE TotalAmount IS NULL;

-- Update TransactionDate from InvoiceDate
UPDATE transactions 
SET TransactionDate = CAST(InvoiceDate AS DATE) 
WHERE TransactionDate IS NULL;

-- Generate TransactionID (Invoice + Line number)
UPDATE transactions 
SET TransactionID = CONCAT(InvoiceNo, '_', StockCode) 
WHERE TransactionID IS NULL;

-- ============================================================
-- SECTION 3: Data Quality Checks
-- ============================================================

-- Check 1: Identify records with NULL values
SELECT 
    'NULL_CHECK' AS CheckName,
    SUM(CASE WHEN InvoiceNo IS NULL THEN 1 ELSE 0 END) AS NullInvoiceNo,
    SUM(CASE WHEN CustomerID IS NULL THEN 1 ELSE 0 END) AS NullCustomerID,
    SUM(CASE WHEN Quantity IS NULL THEN 1 ELSE 0 END) AS NullQuantity,
    SUM(CASE WHEN UnitPrice IS NULL THEN 1 ELSE 0 END) AS NullUnitPrice
FROM transactions;

-- Check 2: Identify negative quantities (returns/cancellations)
SELECT 
    'NEGATIVE_QUANTITY' AS CheckName,
    COUNT(*) AS NegativeQtyRecords,
    SUM(Quantity) AS TotalQty
FROM transactions
WHERE Quantity < 0;

-- Check 3: Identify zero or negative prices
SELECT 
    'INVALID_PRICE' AS CheckName,
    COUNT(*) AS InvalidPriceRecords
FROM transactions
WHERE UnitPrice <= 0;

-- Check 4: Identify invoices with 'C' prefix (cancellations/returns)
SELECT 
    'CANCELLATION_CHECK' AS CheckName,
    COUNT(*) AS CancellationRecords
FROM transactions
WHERE InvoiceNo LIKE 'C%';

-- Check 5: Date range verification
SELECT 
    'DATE_RANGE' AS CheckName,
    MIN(InvoiceDate) AS EarliestDate,
    MAX(InvoiceDate) AS LatestDate,
    DATEDIFF(DAY, MIN(InvoiceDate), MAX(InvoiceDate)) AS DaysSpanned
FROM transactions;

-- Check 6: Duplicate records
SELECT 
    'DUPLICATE_CHECK' AS CheckName,
    COUNT(*) AS TotalRecords,
    COUNT(DISTINCT TransactionID) AS UniqueTransactions
FROM transactions;

-- Check 7: Country coverage
SELECT 
    'COUNTRY_DISTRIBUTION' AS CheckName,
    COUNT(DISTINCT Country) AS UniqueCountries,
    COUNT(DISTINCT CustomerID) AS UniqueCustomers
FROM transactions;

-- ============================================================
-- SECTION 4: Data Cleansing Recommendations
-- ============================================================

-- Flag test/fraudulent records
SELECT 
    InvoiceNo,
    COUNT(*) AS RecordCount,
    SUM(Quantity) AS TotalQty,
    SUM(TotalAmount) AS TotalValue
FROM transactions
WHERE Description LIKE '%test%' 
   OR Description LIKE '%sample%'
   OR Quantity > 10000
GROUP BY InvoiceNo;

-- Identify unusual customer IDs
SELECT 
    'UNUSUAL_CUSTOMER_ID' AS Issue,
    COUNT(DISTINCT CustomerID) AS Count
FROM transactions
WHERE CustomerID IS NULL 
   OR CAST(CustomerID AS VARCHAR) = '0';

-- ============================================================
-- SECTION 5: Summary Statistics
-- ============================================================

SELECT 
    'DATA_SUMMARY' AS Category,
    COUNT(*) AS TotalRecords,
    COUNT(DISTINCT InvoiceNo) AS UniqueInvoices,
    COUNT(DISTINCT CustomerID) AS UniqueCustomers,
    COUNT(DISTINCT StockCode) AS UniqueProducts,
    COUNT(DISTINCT Country) AS UniqueCountries,
    SUM(Quantity) AS TotalQuantity,
    SUM(TotalAmount) AS TotalRevenue,
    ROUND(AVG(TotalAmount), 2) AS AvgTransactionValue,
    ROUND(AVG(Quantity), 2) AS AvgQuantityPerLine
FROM transactions
WHERE Quantity > 0 AND UnitPrice > 0;

-- ============================================================
-- End of Data Loading & Quality Checks
-- ============================================================
