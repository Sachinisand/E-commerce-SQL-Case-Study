-- =====================================================================
-- 06  Products, cancellations and countries
-- =====================================================================

-- name: top_products
SELECT StockCode,
       any_value(Description)            AS description,
       ROUND(SUM(revenue))               AS revenue_gbp,
       SUM(Quantity)                     AS units,
       COUNT(DISTINCT InvoiceNo)         AS orders
FROM sales
GROUP BY StockCode
ORDER BY revenue_gbp DESC
LIMIT 10;

-- name: product_concentration
WITH p AS (SELECT StockCode, SUM(revenue) AS rev FROM sales GROUP BY StockCode),
r AS (SELECT rev, ROW_NUMBER() OVER (ORDER BY rev DESC) AS k, COUNT(*) OVER () AS n FROM p)
SELECT COUNT(*)                                                                   AS products,
       ROUND(100.0 * SUM(rev) FILTER (WHERE k <= n * 0.20) / SUM(rev), 1)         AS top_20pct_products_share,
       MIN(k) FILTER (WHERE running >= 0.5 * total)                               AS products_for_half_of_revenue
FROM (SELECT *, SUM(rev) OVER (ORDER BY k) AS running, SUM(rev) OVER () AS total FROM r);

-- name: cancellations_summary
SELECT COUNT(DISTINCT InvoiceNo)                                              AS cancelled_invoices,
       ROUND(SUM(cancelled_value))                                            AS cancelled_value_gbp,
       ROUND(100.0 * SUM(cancelled_value) / (SELECT SUM(revenue) FROM sales), 1) AS pct_of_sales_value
FROM cancellations;

-- name: most_cancelled_products
SELECT c.StockCode,
       any_value(c.Description)                                  AS description,
       ROUND(SUM(c.cancelled_value))                             AS cancelled_value_gbp,
       ROUND(100.0 * SUM(c.cancelled_value) / MAX(s.rev), 1)     AS pct_of_product_sales
FROM cancellations c
JOIN (SELECT StockCode, SUM(revenue) AS rev FROM sales GROUP BY StockCode) s USING (StockCode)
GROUP BY c.StockCode
ORDER BY cancelled_value_gbp DESC
LIMIT 10;

-- name: countries
SELECT Country,
       ROUND(SUM(revenue))                                         AS revenue_gbp,
       ROUND(100.0 * SUM(revenue) / SUM(SUM(revenue)) OVER (), 1)  AS pct_revenue,
       COUNT(DISTINCT CustomerID)                                  AS customers,
       ROUND(SUM(revenue) / COUNT(DISTINCT InvoiceNo), 2)          AS avg_order_value_gbp
FROM sales
GROUP BY Country
ORDER BY revenue_gbp DESC
LIMIT 10;
