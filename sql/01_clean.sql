-- =====================================================================
-- 01  Load and clean
-- Source: UCI Online Retail (UK online gift retailer, 01.12.2010 - 09.12.2011)
-- Engine: DuckDB (standard SQL; runs without a database server)
--
-- Cleaning rules (every later query uses these views, so the rules live in one place):
--   sales          = real product sales: quantity > 0, price > 0, not a cancellation,
--                    not a service / accounting line (postage, fees, discounts, vouchers ...),
--                    and not reversed by an exact matching cancellation (same customer,
--                    product and quantity). Without that last rule, two single orders of
--                    80,995 and 74,215 units that were cancelled straight away would rank
--                    as the shop's top products.
--   customer_sales = sales with a known CustomerID (needed for customer-level analysis)
--   cancellations  = invoices starting with 'C'
-- Revenue = Quantity * UnitPrice, in GBP.
-- =====================================================================

-- name: load
CREATE OR REPLACE TABLE raw AS
SELECT *
FROM read_csv('data/online_retail.csv', header = true,
              types = {'InvoiceNo': 'VARCHAR', 'StockCode': 'VARCHAR', 'CustomerID': 'VARCHAR'},
              timestampformat = '%m/%d/%Y %H:%M');

-- name: non_product_codes
CREATE OR REPLACE TABLE non_product_codes AS
SELECT * FROM (VALUES
    ('POST'), ('DOT'), ('M'), ('m'), ('C2'), ('D'), ('S'), ('BANK CHARGES'),
    ('AMAZONFEE'), ('CRUK'), ('PADS'), ('B')
) AS t(StockCode);

-- name: reversed_lines
-- Sale lines that a later cancellation reverses exactly.
CREATE OR REPLACE TABLE reversed_lines AS
SELECT DISTINCT s.InvoiceNo, s.StockCode, s.Quantity
FROM raw s
JOIN raw c
  ON  c.InvoiceNo LIKE 'C%'
  AND c.CustomerID = s.CustomerID
  AND c.StockCode  = s.StockCode
  AND c.Quantity   = -s.Quantity
  AND c.InvoiceDate >= s.InvoiceDate
WHERE s.InvoiceNo NOT LIKE 'C%' AND s.Quantity > 0;

-- name: sales_view
CREATE OR REPLACE VIEW sales AS
SELECT
    InvoiceNo,
    StockCode,
    Description,
    Quantity,
    InvoiceDate,
    UnitPrice,
    Quantity * UnitPrice           AS revenue,
    CustomerID,
    Country
FROM raw
WHERE Quantity > 0
  AND UnitPrice > 0
  AND InvoiceNo NOT LIKE 'C%'
  AND InvoiceNo NOT LIKE 'A%'                                   -- 'adjust bad debt' entries
  AND StockCode NOT IN (SELECT StockCode FROM non_product_codes)
  AND StockCode NOT LIKE 'gift\_%' ESCAPE '\'                   -- gift vouchers
  AND (InvoiceNo, StockCode, Quantity) NOT IN (SELECT InvoiceNo, StockCode, Quantity FROM reversed_lines);

-- name: customer_sales_view
CREATE OR REPLACE VIEW customer_sales AS
SELECT * FROM sales WHERE CustomerID IS NOT NULL;

-- name: cancellations_view
CREATE OR REPLACE VIEW cancellations AS
SELECT *, -Quantity * UnitPrice AS cancelled_value
FROM raw
WHERE InvoiceNo LIKE 'C%'
  AND StockCode NOT IN (SELECT StockCode FROM non_product_codes);
