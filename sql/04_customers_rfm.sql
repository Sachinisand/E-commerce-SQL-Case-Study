-- =====================================================================
-- 04  Customers: RFM segmentation
-- Recency is measured from the day after the last invoice in the data
-- (2011-12-10), not from today's date.
-- =====================================================================

-- name: rfm_segments
WITH snapshot AS (
    SELECT MAX(InvoiceDate)::DATE + 1 AS snapshot_date FROM customer_sales
),
customer AS (
    SELECT CustomerID,
           (SELECT snapshot_date FROM snapshot) - MAX(InvoiceDate)::DATE  AS recency_days,
           COUNT(DISTINCT InvoiceNo)                                       AS frequency,
           SUM(revenue)                                                    AS monetary
    FROM customer_sales
    GROUP BY CustomerID
),
scored AS (
    SELECT *,
           NTILE(5) OVER (ORDER BY recency_days DESC) AS r,     -- 5 = bought most recently
           NTILE(5) OVER (ORDER BY frequency)         AS f,
           NTILE(5) OVER (ORDER BY monetary)          AS m
    FROM customer
),
segmented AS (
    SELECT *,
           CASE
               WHEN r >= 4 AND f >= 4             THEN 'Champions'
               WHEN r >= 3 AND f >= 3             THEN 'Loyal'
               WHEN r >= 4 AND f <= 2             THEN 'New / promising'
               WHEN r <= 2 AND f >= 3             THEN 'At risk'
               WHEN r <= 2 AND f <= 2             THEN 'Lost / hibernating'
               ELSE                                    'Needs attention'
           END AS segment
    FROM scored
)
SELECT segment,
       COUNT(*)                                                  AS customers,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)        AS pct_customers,
       ROUND(SUM(monetary))                                      AS revenue_gbp,
       ROUND(100.0 * SUM(monetary) / SUM(SUM(monetary)) OVER (), 1) AS pct_revenue,
       ROUND(MEDIAN(recency_days))                               AS median_recency_days,
       MEDIAN(frequency)                                         AS median_orders
FROM segmented
GROUP BY segment
ORDER BY revenue_gbp DESC;

-- name: customer_concentration
-- How much revenue comes from the top customers?
WITH customer AS (
    SELECT CustomerID, SUM(revenue) AS monetary FROM customer_sales GROUP BY CustomerID
),
ranked AS (
    SELECT monetary,
           ROW_NUMBER() OVER (ORDER BY monetary DESC) AS rank_no,
           COUNT(*) OVER ()                           AS n
    FROM customer
)
SELECT COUNT(*)                                                                       AS customers,
       ROUND(100.0 * SUM(monetary) FILTER (WHERE rank_no <= n * 0.01) / SUM(monetary), 1) AS top_1pct_share,
       ROUND(100.0 * SUM(monetary) FILTER (WHERE rank_no <= n * 0.10) / SUM(monetary), 1) AS top_10pct_share,
       ROUND(100.0 * SUM(monetary) FILTER (WHERE rank_no <= n * 0.20) / SUM(monetary), 1) AS top_20pct_share
FROM ranked;

-- name: repeat_customers
WITH c AS (
    SELECT CustomerID, COUNT(DISTINCT InvoiceNo) AS orders FROM customer_sales GROUP BY CustomerID
)
SELECT COUNT(*)                                                   AS customers,
       COUNT(*) FILTER (WHERE orders >= 2)                        AS repeat_customers,
       ROUND(100.0 * COUNT(*) FILTER (WHERE orders >= 2) / COUNT(*), 1) AS repeat_rate_pct,
       MEDIAN(orders)                                             AS median_orders_per_customer
FROM c;
