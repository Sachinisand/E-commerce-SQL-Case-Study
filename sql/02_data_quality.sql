-- =====================================================================
-- 02  Data quality: what was removed, and why
-- =====================================================================

-- name: data_quality
SELECT 'all rows'                                    AS check_name, COUNT(*) AS rows FROM raw
UNION ALL SELECT 'missing CustomerID',             COUNT(*) FROM raw WHERE CustomerID IS NULL
UNION ALL SELECT 'cancellation lines (C...)',      COUNT(*) FROM raw WHERE InvoiceNo LIKE 'C%'
UNION ALL SELECT 'quantity <= 0',                  COUNT(*) FROM raw WHERE Quantity <= 0
UNION ALL SELECT 'price <= 0',                     COUNT(*) FROM raw WHERE UnitPrice <= 0
UNION ALL SELECT 'service / accounting lines',     COUNT(*) FROM raw
          WHERE StockCode IN (SELECT StockCode FROM non_product_codes) OR StockCode LIKE 'gift\_%' ESCAPE '\'
UNION ALL SELECT 'sales reversed by a matching cancellation', COUNT(*) FROM reversed_lines
UNION ALL SELECT 'exact duplicate rows (kept, see README)',           COUNT(*) - (SELECT COUNT(*) FROM (SELECT DISTINCT * FROM raw)) FROM raw
UNION ALL SELECT 'rows kept as product sales',     COUNT(*) FROM sales
UNION ALL SELECT 'of which with CustomerID',       COUNT(*) FROM customer_sales;

-- name: days_with_sales
-- The shop records no sales on Saturdays.
SELECT dayname(InvoiceDate)                          AS weekday,
       isodow(InvoiceDate)                           AS day_no,
       COUNT(DISTINCT InvoiceNo)                     AS orders,
       ROUND(SUM(revenue))                           AS revenue_gbp
FROM sales
GROUP BY 1, 2
ORDER BY day_no;
