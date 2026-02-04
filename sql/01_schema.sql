-- ============================================================
-- E-commerce SQL Case Study
-- Schema Creation
-- ============================================================
-- This script creates the necessary tables for the e-commerce analysis
-- Compatible with: MySQL, PostgreSQL, SQL Server

-- Create main transactions table
CREATE TABLE IF NOT EXISTS transactions (
    InvoiceNo VARCHAR(20) NOT NULL,
    StockCode VARCHAR(20) NOT NULL,
    Description VARCHAR(255),
    Quantity INT,
    InvoiceDate DATETIME,
    UnitPrice DECIMAL(10, 2),
    CustomerID INT,
    Country VARCHAR(50),
    -- Derived columns for analysis
    TransactionID VARCHAR(50) UNIQUE,
    TransactionDate DATE,
    TotalAmount DECIMAL(12, 2)
);

-- Create indexes for performance optimization
CREATE INDEX idx_invoice_no ON transactions(InvoiceNo);
CREATE INDEX idx_customer_id ON transactions(CustomerID);
CREATE INDEX idx_stock_code ON transactions(StockCode);
CREATE INDEX idx_invoice_date ON transactions(InvoiceDate);
CREATE INDEX idx_country ON transactions(Country);

-- Create customers dimension table (derived from transactions)
CREATE TABLE IF NOT EXISTS customers (
    CustomerID INT PRIMARY KEY,
    Country VARCHAR(50),
    FirstPurchaseDate DATETIME,
    LastPurchaseDate DATETIME,
    TotalPurchases INT,
    TotalSpent DECIMAL(12, 2)
);

-- Create products dimension table (derived from transactions)
CREATE TABLE IF NOT EXISTS products (
    StockCode VARCHAR(20) PRIMARY KEY,
    Description VARCHAR(255),
    AvgUnitPrice DECIMAL(10, 2),
    TotalQuantitySold INT,
    TotalRevenue DECIMAL(12, 2),
    ProductStatus VARCHAR(20)
);

-- Create date dimension table for time-based analysis
CREATE TABLE IF NOT EXISTS date_dimension (
    DateKey INT PRIMARY KEY,
    FullDate DATE,
    Year INT,
    Month INT,
    MonthName VARCHAR(20),
    Day INT,
    Quarter INT,
    DayOfWeek INT,
    DayName VARCHAR(20),
    IsWeekend BOOLEAN,
    IsHoliday BOOLEAN
);

-- Create sales summary fact table (aggregated)
CREATE TABLE IF NOT EXISTS sales_summary (
    SummarySalesKey INT AUTO_INCREMENT PRIMARY KEY,
    DateKey INT,
    CustomerID INT,
    StockCode VARCHAR(20),
    Country VARCHAR(50),
    TotalQuantity INT,
    TotalRevenue DECIMAL(12, 2),
    TransactionCount INT,
    FOREIGN KEY (DateKey) REFERENCES date_dimension(DateKey)
);

-- Create data quality logs table
CREATE TABLE IF NOT EXISTS data_quality_logs (
    LogID INT AUTO_INCREMENT PRIMARY KEY,
    CheckName VARCHAR(100),
    CheckDateTime DATETIME,
    IssueCount INT,
    Description TEXT,
    Status VARCHAR(20)
);

-- ============================================================
-- End of Schema Creation
-- ============================================================
