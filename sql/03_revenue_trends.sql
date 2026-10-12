-- =====================================================================
-- 03  Revenue over time
-- Note: December 2011 only covers 1-9 December, so it is flagged as partial.
-- =====================================================================

-- name: monthly_revenue
SELECT strftime(date_trunc('month', InvoiceDate), '%Y-%m')   AS month,
       ROUND(SUM(revenue))                                   AS revenue_gbp,
       COUNT(DISTINCT InvoiceNo)                             AS orders,
       COUNT(DISTINCT CustomerID)                            AS customers,
       ROUND(SUM(revenue) / COUNT(DISTINCT InvoiceNo), 2)    AS avg_order_value_gbp,
       date_trunc('month', InvoiceDate) = DATE '2011-12-01'  AS partial_month
FROM sales
GROUP BY date_trunc('month', InvoiceDate)
ORDER BY month;

-- name: revenue_by_hour
SELECT hour(InvoiceDate)                  AS hour,
       COUNT(DISTINCT InvoiceNo)          AS orders,
       ROUND(SUM(revenue))                AS revenue_gbp
FROM sales
GROUP BY 1
ORDER BY 1;

-- name: order_size
-- Order value and basket size per invoice (median is more honest than mean here).
WITH orders AS (
    SELECT InvoiceNo,
           SUM(revenue)                    AS order_value,
           COUNT(DISTINCT StockCode)       AS distinct_products
    FROM sales
    GROUP BY InvoiceNo
)
SELECT COUNT(*)                                              AS orders,
       ROUND(AVG(order_value), 2)                            AS mean_order_value_gbp,
       ROUND(MEDIAN(order_value), 2)                         AS median_order_value_gbp,
       ROUND(quantile_cont(order_value, 0.9), 2)             AS p90_order_value_gbp,
       MEDIAN(distinct_products)                             AS median_products_per_order
FROM orders;
