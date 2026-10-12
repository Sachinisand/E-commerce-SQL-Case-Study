-- =====================================================================
-- 05  Cohort retention
-- Customers are grouped by the month of their first purchase. For each later
-- month we count how many of them bought again.
-- Caveat: the data starts in Dec 2010, so the "Dec 2010" cohort also contains
-- older customers whose real first purchase is not in the data, and December 2011
-- only covers 1-9 December, so cells that fall in that month are flagged.
-- =====================================================================

-- name: cohort_retention
WITH first_month AS (
    SELECT CustomerID, MIN(date_trunc('month', InvoiceDate)) AS cohort
    FROM customer_sales
    GROUP BY CustomerID
),
activity AS (
    SELECT DISTINCT s.CustomerID,
           f.cohort,
           date_diff('month', f.cohort, date_trunc('month', s.InvoiceDate)) AS months_since_first
    FROM customer_sales s
    JOIN first_month f USING (CustomerID)
),
cohort_size AS (
    SELECT cohort, COUNT(*) AS customers FROM first_month GROUP BY cohort
)
SELECT strftime(a.cohort, '%Y-%m')                                          AS cohort,
       c.customers                                                          AS cohort_customers,
       a.months_since_first,
       COUNT(*)                                                             AS active_customers,
       ROUND(100.0 * COUNT(*) / c.customers, 1)                             AS retention_pct,
       a.cohort + to_months(a.months_since_first) = DATE '2011-12-01'      AS in_partial_month
FROM activity a
JOIN cohort_size c USING (cohort)
GROUP BY a.cohort, c.customers, a.months_since_first
ORDER BY a.cohort, a.months_since_first;
