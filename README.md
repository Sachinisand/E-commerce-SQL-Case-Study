# E-commerce SQL Case Study

A comprehensive analysis of e-commerce transaction data using SQL. This project demonstrates advanced data analysis, query optimization, and business intelligence techniques on real-world retail data.

## 📊 Project Overview

This case study analyzes an e-commerce dataset containing transaction records from 2010-2011. The dataset includes invoice information, product details, customer locations, and pricing data across multiple countries.

**Dataset Size:** 541,911 transaction records

## 🗂️ Project Structure

```
├── data/
│   └── data.csv                    # Raw e-commerce transaction data
├── sql/
│   ├── 01_schema.sql               # Database schema and table creation
│   ├── 02_data_loading.sql         # Data import and data quality checks
│   ├── 03_exploratory_analysis.sql # Basic exploration queries
│   ├── 04_customer_analysis.sql    # Customer segmentation and behavior
│   ├── 05_sales_analysis.sql       # Revenue and sales metrics
│   └── 06_product_analysis.sql     # Product performance analysis
├── analysis/
│   └── key_findings.md             # Summary of insights and recommendations
├── .gitignore
└── README.md
```

## 📋 Dataset Description

### Columns
- **InvoiceNo:** Unique invoice identifier
- **StockCode:** Product identifier
- **Description:** Product description
- **Quantity:** Number of units purchased
- **InvoiceDate:** Date and time of transaction
- **UnitPrice:** Price per unit
- **CustomerID:** Unique customer identifier
- **Country:** Customer location

### Data Characteristics
- **Time Period:** 2010-2011
- **Geographic Scope:** Multiple countries (UK, France, USA, etc.)
- **Product Range:** Retail products (toys, household items, gifts)

## 🔍 Analysis Areas

### 1. Customer Analysis
- Customer segmentation by purchase frequency and value
- Repeat customer identification
- Geographic customer distribution
- Customer lifetime value (CLV)

### 2. Sales Analysis
- Revenue trends over time
- Average order value (AOV)
- Top-performing products and categories
- Sales by country and region

### 3. Product Analysis
- Best-selling products
- Product price analysis
- Inventory performance
- Product category insights

### 4. Data Quality
- Identification of anomalies
- Data validation checks
- Outlier analysis

## 🛠️ Technologies

- **SQL Database:** Compatible with MySQL, PostgreSQL, SQL Server
- **Query Analysis:** Advanced CTEs, window functions, aggregations
- **Tools:** SQL IDE (DBeaver, SQL Server Management Studio, pgAdmin)

## 📁 Getting Started

### Prerequisites
- SQL database management system installed (MySQL, PostgreSQL, or SQL Server)
- SQL IDE or command-line client
- The provided `data.csv` file

### Setup Instructions

1. **Create Database**
   ```sql
   CREATE DATABASE ecommerce_analysis;
   USE ecommerce_analysis;
   ```

2. **Run Schema Creation**
   - Execute `sql/01_schema.sql` to create tables

3. **Load Data**
   - Execute `sql/02_data_loading.sql` to import CSV data

4. **Run Analyses**
   - Execute queries in `sql/03_*` through `sql/06_*` for various analyses

## 💡 Key Queries Included

- Customer RFM (Recency, Frequency, Monetary) Analysis
- Monthly Revenue Trends
- Top Customers and Products
- Customer Segmentation
- Product Performance Metrics
- Geographic Sales Distribution
- Data Quality Validation

## 📈 Expected Insights

This analysis provides answers to:
- Who are the most valuable customers?
- Which products drive the most revenue?
- What are the geographic trends?
- How do sales vary by season?
- What data quality issues exist?

## 📝 Notes

- The dataset is from a UK-based online retailer
- Some transactions may have data quality issues that are identified in the analysis
- All queries are optimized for performance on the full dataset


## 📄 License

This project uses publicly available dataset for educational purposes.

---

**Author:** [Sachini Hewahattage]  
**Last Updated:** February 2026  
**Status:** Active Analysis
