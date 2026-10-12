# Key findings and recommendations

All numbers come from the query results in [`../results/`](../results/) (file names in brackets).
Period: 1 Dec 2010 – 9 Dec 2011. Revenue = product sales in GBP after the cleaning rules in [`sql/01_clean.sql`](../sql/01_clean.sql).

## 1. A small group of customers carries the business

- 4,324 customers with an ID. The **top 1 % bring 29.8 %** of revenue, the **top 10 % bring 59.8 %**, the top 20 % bring 73.5 % *(customer_concentration)*.
- RFM segments *(rfm_segments)*:

| Segment | Customers | % customers | Revenue | % revenue | Median days since last order | Median orders |
|---|---:|---:|---:|---:|---:|---:|
| Champions | 1,126 | 26.0 % | £5.68M | 68.6 % | 11 | 7 |
| Loyal | 839 | 19.4 % | £1.17M | 14.1 % | 41 | 3 |
| At risk | 629 | 14.5 % | £0.72M | 8.7 % | 144 | 3 |
| Lost / hibernating | 1,101 | 25.5 % | £0.45M | 5.5 % | 215 | 1 |
| New / promising | 329 | 7.6 % | £0.13M | 1.6 % | 19 | 1 |
| Needs attention | 300 | 6.9 % | £0.12M | 1.4 % | 53 | 1 |

**Recommendation:** treat Champions as key accounts (personal contact, early access to the Q4 range). Losing a handful of them costs more than losing hundreds of one-time buyers.

## 2. Revenue at risk is identifiable

- **629 "At risk" customers** ordered a median of 3 times but not for a median of **144 days**; together they were worth **£724k**.
- **Recommendation:** a win-back campaign aimed only at this group. Winning back a tenth of their past revenue (~£72k) would be worth about half of what the whole "New / promising" segment brought in (£133k from 329 customers). This is a hypothesis to test with a control group, not a forecast.

## 3. Customers come back, but slowly

- **65.2 %** of customers ordered at least twice; the median customer placed 2 orders *(repeat_customers)*.
- Of customers whose first order was in 2011, on average **~20 % ordered again in the following month** (14–24 % depending on the cohort) *(cohort_retention)*.
- The Dec 2010 cohort shows 32–40 % every month. This is not better onboarding: the data starts in Dec 2010, so this group includes long-time customers.
- **Recommendation:** a structured second-order offer within 30 days of the first order, measured on the next cohorts.

## 4. These are mostly business buyers

- Median order **£301**, mean £499, top 10 % of orders above £906, median **15 different products per order** *(order_size)*.
- Orders happen in office hours (peak at **12:00**, almost nothing after 18:00) and **never on Saturdays** *(revenue_by_hour, days_with_sales)*.
- **Recommendation:** plan campaigns, customer service and stock for weekday business hours; B2B tactics (volume pricing, reorder reminders) fit better than consumer tactics.

## 5. Strong Q4 seasonality

- **November 2011: £1.44M**, 2.9× February (£0.50M). September to November bring **37.7 %** of the revenue of the 12 full months *(monthly_revenue)*.
- December 2011 only covers 1–9 December and is shown as partial.
- **Recommendation:** secure stock for top products by August; the busiest month is November, not December, because these customers resell before Christmas.

## 6. A short list of products makes half of revenue

- **251 of 3,902 products (6 %) make half of all revenue**; the top 20 % make 78.1 % *(product_concentration)*.
- Top products: Regency Cakestand 3 Tier (£168k), Party Bunting (£98k), White Hanging Heart T-Light Holder (£98k), Jumbo Bag Red Retrospot (£90k) *(top_products)*.
- **Recommendation:** never let these 251 products run out of stock; review the long tail for range simplification.

## 7. A few very large international accounts

- The UK is **84.7 %** of revenue. The Netherlands (**9 customers, £282k**, average order £3,067) and Ireland (**3 customers, £256k**) are a few large accounts rather than markets *(countries)*.
- **Recommendation:** manage these accounts individually; a "Netherlands market strategy" would be built on nine customers.

## 8. Cancellations

- 3,422 cancelled invoices worth **£479k**, 4.9 % of product sales *(cancellations_summary)*.
- Two single orders (80,995 paper birdies, 74,215 storage jars) were cancelled straight after being placed. They are excluded from sales, otherwise they would rank as top products *(most_cancelled_products)*.
- **Recommendation:** a plausibility check on very large orders (for example a confirmation step above a quantity limit).

## Data quality notes

| Check | Rows *(data_quality)* |
|---|---:|
| All rows | 541,909 |
| Missing CustomerID | 135,080 |
| Cancellation lines | 9,288 |
| Quantity ≤ 0 | 10,624 |
| Price ≤ 0 | 2,517 |
| Postage / fees / discounts / vouchers | 2,950 |
| Sales reversed by an exact matching cancellation | 4,032 |
| Exact duplicate rows (kept) | 5,268 |
| **Product sale lines used** | **523,780** |
| of which with CustomerID | 392,359 |

25 % of lines have no customer ID, so customer-level results (sections 1–3) describe identified customers only.
