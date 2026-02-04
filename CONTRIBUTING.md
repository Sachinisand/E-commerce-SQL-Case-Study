# Contributing Guidelines

## Project Structure

This E-commerce SQL Case Study is organized as follows:

```
├── README.md              # Project overview and getting started
├── CONTRIBUTING.md        # This file
├── .gitignore            # Git ignore patterns
├── data/
│   └── data.csv          # Raw dataset (not committed)
├── sql/
│   ├── 01_schema.sql     # Table creation
│   ├── 02_data_loading.sql
│   ├── 03_exploratory_analysis.sql
│   ├── 04_customer_analysis.sql
│   ├── 05_sales_analysis.sql
│   └── 06_product_analysis.sql
└── analysis/
    └── key_findings.md   # Analysis insights and recommendations
```

## Query Development Guidelines

### 1. Naming Conventions
- **CTEs (Common Table Expressions):** Use descriptive names in `snake_case`
  - Example: `customer_metrics`, `monthly_sales`, `revenue_by_region`
- **Aliases:** Keep aliases concise but meaningful
  - Example: `t` for transactions table, `p` for products table
- **Variables:** Use descriptive names with context
  - Example: `TotalRevenue`, `ActiveCustomers`, `RetentionRate`

### 2. Code Organization
- Group related queries together with clear section headers
- Use comments to explain complex logic
- Include the purpose of each query at the top
- Maintain consistent formatting and indentation

### 3. Performance Best Practices
- Use appropriate indexes on frequently queried columns
- Avoid SELECT * - specify only needed columns
- Use WHERE clauses to filter early
- Consider data volume when using window functions
- Test on full dataset before optimizing

### 4. Query Commenting
```sql
-- ============================================================
-- QUERY 1: Clear Descriptive Name
-- ============================================================
-- Purpose: Explain what business question this answers
-- Business Use: Where this insight is used
-- Performance: Expected runtime and rows returned

SELECT ...
```

## Query Examples

### Good Query
```sql
-- Calculate monthly revenue with growth metrics
SELECT 
    FORMAT(InvoiceDate, 'yyyy-MM') AS YearMonth,
    COUNT(DISTINCT InvoiceNo) AS OrderCount,
    ROUND(SUM(TotalAmount), 2) AS MonthlyRevenue,
    ROUND(SUM(TotalAmount) / COUNT(DISTINCT InvoiceNo), 2) AS AvgOrderValue
FROM transactions
WHERE Quantity > 0 AND UnitPrice > 0
GROUP BY FORMAT(InvoiceDate, 'yyyy-MM')
ORDER BY YearMonth;
```

### Query Structure Template
```sql
-- ============================================================
-- [PURPOSE]
-- ============================================================

WITH cte_name AS (
    -- Step 1: Prepare data
    SELECT ...
),
second_cte AS (
    -- Step 2: Transform
    SELECT ...
)
-- Step 3: Final result
SELECT ...
FROM cte_name
WHERE [conditions]
ORDER BY [columns];
```

## Data Quality Standards

When adding new analyses:
1. **Always filter out invalid data:**
   - `WHERE Quantity > 0 AND UnitPrice > 0`
   - `WHERE CustomerID IS NOT NULL`

2. **Validate edge cases:**
   - Zero or negative values
   - NULL values
   - Outliers (extreme values)

3. **Document assumptions:**
   - Comment on any data quality assumptions
   - Note any records excluded and why

## SQL Dialects

This project supports multiple SQL databases:
- **MySQL 8.0+**
- **PostgreSQL 12+**
- **SQL Server 2016+**

When writing queries:
1. Use **ANSI SQL** where possible (portable across databases)
2. If database-specific functions needed, **add comments** noting the dialect
3. Provide alternative syntax for different databases

### Dialect-Specific Syntax Examples

**SQL Server:**
```sql
SELECT TOP 10 ... ORDER BY TotalRevenue DESC;
DATEDIFF(DAY, date1, date2)
FORMAT(date, 'yyyy-MM-dd')
```

**PostgreSQL:**
```sql
SELECT ... ORDER BY TotalRevenue DESC LIMIT 10;
date2 - date1 AS days
TO_CHAR(date, 'YYYY-MM-DD')
```

**MySQL:**
```sql
SELECT ... ORDER BY TotalRevenue DESC LIMIT 10;
DATEDIFF(date2, date1)
DATE_FORMAT(date, '%Y-%m-%d')
```

## Adding New Analyses

### When proposing new analysis:

1. **Create a new query file** if for a new analysis area
2. **Follow the naming convention:** `XX_topic_name.sql`
3. **Start with exploratory queries** before advanced analysis
4. **Document findings** in key_findings.md
5. **Add business context** - why does this matter?

### Example: Adding Customer Churn Analysis

1. Create `07_churn_analysis.sql`
2. Include queries for:
   - Churn definition (no purchases in X days)
   - Churn rate by cohort
   - Churn prediction indicators
   - Retention cohort analysis
3. Update README.md to reference new analysis
4. Add findings to analysis/key_findings.md
5. Commit and push: `git push origin main`
6. View at: https://github.com/Sachinisand/E-commerce-SQL-Case-Study

## Testing Your Queries

Before committing:
1. **Run on full dataset** - ensure it completes
2. **Validate results** - do numbers make sense?
3. **Check for edge cases** - NULL values, outliers
4. **Document runtime** - very slow queries need optimization
5. **Add sample output** - comment with example results
