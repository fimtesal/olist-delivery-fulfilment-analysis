# olist-delivery-fulfilment-analysis
SQL analysis of delivery delay: seller vs. courier bottleneck diagnosis (Olist dataset)
# Milestone 1 Report
## E-Commerce Fulfilment Bottleneck & Delivery Performance Analysis

**Team:** Atikaa Abbas · Imtesal Fatima · Maria Noor
**Dataset:** Brazilian E-Commerce Public Dataset by Olist (Kaggle)
**Tool Used:** SQLite
**Submission Date:** September 6, 2026

---

## 1. Executive Summary

This project analyzes approximately 99,000 real, anonymized e-commerce orders from Olist, a Brazilian online marketplace, to determine where delivery time is actually being spent — with the seller during order preparation, or with the carrier during transit. After cleaning and validating the dataset, 96,281 delivered orders were analyzed to separate total fulfilment time into a pre-shipment (seller) stage and a post-shipment (carrier) stage.

The analysis finds that carrier transit time (9.3 days on average) is roughly three times longer than seller processing time (3.2 days), meaning approximately 75% of total fulfilment time occurs after the order has already left the seller. This pattern holds consistently across nearly all Brazilian states — seller performance is stable nationwide (2.8–3.7 days), while carrier performance varies dramatically, with several North-region states (RR, AP, AM, AL, PA) experiencing average transit times exceeding three weeks.

These findings indicate that delivery delay in this dataset is overwhelmingly a logistics and carrier-side issue rather than a seller-processing issue, and that any operational response to delivery complaints should be directed accordingly — particularly given that revenue is heavily concentrated in São Paulo (~42% of the total), making fulfilment reliability in high-volume regions especially consequential.

---

## 2. Problem Statement

An e-commerce marketplace wants to understand where time is being spent across the order-fulfilment process. This project separates fulfilment time into pre-shipment processing time and post-shipment delivery time, compares these components across sellers and regions, and identifies patterns where delays or unusually long processing times are concentrated. The purpose is to highlight areas that may warrant further operational investigation.

**Main Analytical Question:** Is delay in the order-fulfilment process more attributable to the pre-shipment (seller-side) stage or the post-shipment (carrier/delivery) stage, and does this differ by region?

**Supporting Questions:**
- What is the average total fulfilment time, and how much of it is pre-shipment vs. post-shipment time?
- How does this split vary across states?
- Which states show the largest pre-shipment (seller-side) delay?
- Which states show the largest post-shipment (carrier-side) delay?
- How does delivered revenue vary by state, and does it relate to fulfilment performance?
- What percentage of orders are late relative to Olist's own estimated delivery date?

---

## 3. Dataset & Methodology

**Source:** Brazilian E-Commerce Public Dataset by Olist, Kaggle. Anonymized, licensed for reuse and analysis.
**Tables used:** `orders`, `order_items`, `customers`

**Raw Row Counts:**

| Table | Row Count |
|---|---|
| orders | 99,441 |
| order_items | 112,650 |
| customers | 99,441 |

### 3.1 Metric Definitions

| Metric | Formula | Represents |
|---|---|---|
| Pre-shipment processing time | carrier_date − purchase_timestamp | How long the seller took to hand the order to the carrier |
| Post-shipment delivery time | delivered_date − carrier_date | How long the carrier took to deliver the order |
| Total fulfilment time | delivered_date − purchase_timestamp | The full time experienced by the customer |

### 3.2 Data-Handling Rules

- Only orders with `order_status = 'delivered'` are included in delivery-time calculations, since other statuses lack complete date fields.
- Orders with missing carrier-handoff or customer-delivery dates are excluded from calculations, not deleted from the source table.
- Revenue is calculated using `SUM(price)` at the item level; order counts use `COUNT(DISTINCT order_id)` to avoid double-counting orders with multiple items.
- "On-time" is defined as `delivered_date <= estimated_delivery_date`. This is a supporting metric only, since Olist's estimated delivery dates include a built-in buffer (demonstrated in Section 7.2).

---

## 4. Data Cleaning & Quality Assurance

### 4.1 Order Status Breakdown

```sql
SELECT order_status, COUNT(*)
FROM orders
GROUP BY order_status
ORDER BY COUNT(*) DESC;
```

| Status | Count |
|---|---|
| delivered | 96,478 |
| shipped | 1,107 |
| canceled | 625 |
| unavailable | 609 |
| invoiced | 314 |
| processing | 301 |
| created | 5 |
| approved | 2 |

**Interpretation:** ~97.0% of orders reached "delivered" status. Only delivered orders were used for delivery-time analysis, since other statuses lack the timestamps needed for calculation.

### 4.2 Missing Values Check

```sql
SELECT
    SUM(CASE WHEN order_delivered_carrier_date IS NULL OR order_delivered_carrier_date = '' THEN 1 ELSE 0 END) AS missing_carrier_date,
    SUM(CASE WHEN order_delivered_customer_date IS NULL OR order_delivered_customer_date = '' THEN 1 ELSE 0 END) AS missing_delivered_date
FROM orders;
```

| missing_carrier_date | missing_delivered_date |
|---|---|
| 1,783 | 2,965 |

**Interpretation:** About 2% to 3% of orders didn't have delivery times, probably because they were never delivered. We didn't include them in our time calculations.

### 4.3 Date Range and Integrity Checks

```sql
SELECT MIN(order_purchase_timestamp), MAX(order_purchase_timestamp) FROM orders;
```
**Result:** matches the documented dataset range (2016–2018)

```sql
SELECT COUNT(*) FROM orders 
WHERE order_status = 'delivered' 
  AND order_delivered_carrier_date != ''
  AND order_delivered_carrier_date < order_purchase_timestamp;

SELECT COUNT(*) FROM orders 
WHERE order_status = 'delivered' 
  AND order_delivered_customer_date != ''
  AND order_delivered_customer_date < order_delivered_carrier_date;
```
**Result:** 165 and 23

**Interpretation:** We found 188 invalid orders during a detailed check: 165 had handoff dates before the purchase date, and 23 had delivery dates before the handoff date. Since these timelines are logically impossible, we removed them as data errors to make our dataset cleaner.

### 4.4 Table Integrity Checks (order_items, customers)

| Check | Result |
|---|---|
| Missing price values | 0 |
| Missing seller_id values | 0 |
| Invalid (≤0) prices | 0 |
| order_items rows with no matching order | 0 |
| Duplicate customer_id values | 0 |
| Orders with no matching customer record | 0 |

**Interpretation:** `order_items` and `customers` required no exclusions — both tables were fully clean on import.

### 4.5 Final Clean Dataset

```sql
CREATE VIEW clean_orders AS
SELECT *
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_carrier_date IS NOT NULL AND order_delivered_carrier_date != ''
  AND order_delivered_customer_date IS NOT NULL AND order_delivered_customer_date != ''
  AND order_delivered_customer_date >= order_purchase_timestamp
  AND order_delivered_carrier_date >= order_purchase_timestamp
  AND order_delivered_customer_date >= order_delivered_carrier_date;

SELECT COUNT(*) FROM clean_orders;
```
**Result:** 96,281 orders remain in the final clean dataset (96,478 delivered orders, minus 197 excluded for missing or logically invalid dates).

---

## 5. Analysis — Overall Fulfilment Metrics

```sql
SELECT
    COUNT(*) AS total_delivered_orders,
    ROUND(AVG(JULIANDAY(order_delivered_customer_date) - JULIANDAY(order_purchase_timestamp)), 1) AS avg_total_days,
    ROUND(AVG(JULIANDAY(order_delivered_carrier_date) - JULIANDAY(order_purchase_timestamp)), 1) AS avg_pre_shipment_days,
    ROUND(AVG(JULIANDAY(order_delivered_customer_date) - JULIANDAY(order_delivered_carrier_date)), 1) AS avg_post_shipment_days
FROM clean_orders;
```

| total_delivered_orders | avg_total_days | avg_pre_shipment_days | avg_post_shipment_days |
|---|---|---|---|
| 96,281 | 12.6 | 3.2 | 9.3 |

**Interpretation:** On average, an order takes 12.6 days from purchase to delivery. Of this, only 3.2 days (25%) are spent on the seller side preparing and handing off the order; the remaining 9.3 days (75%) are spent in carrier transit. This is the project's central finding: the majority of fulfilment time is consumed after the order leaves the seller.

**Min/Max (Outlier Check):**

| min_pre_shipment | max_pre_shipment | min_post_shipment | max_post_shipment |
|---|---|---|---|
| ~0.0004 | 125.8 | 0 | 205.2 |

**Interpretation:** While typical values are low, a small number of extreme outliers exist (up to ~126 days pre-shipment, ~205 days post-shipment). These were retained in the average since no evidence indicates they are data errors, but they are noted here for transparency.

---

## 6. Analysis — Regional Fulfilment Patterns

### 6.1 Pre-Shipment vs. Post-Shipment Time by State

**Top 5 states by post-shipment (courier) time:**

| State | Orders | Pre-shipment (days) | Post-shipment (days) |
|---|---|---|---|
| RR | 41 | 3.7 | 25.6 |
| AP | 67 | 3.5 | 23.7 |
| AM | 145 | 2.9 | 23.5 |
| AL | 397 | 3.5 | 21.1 |
| PA | 945 | 3.5 | 20.3 |

**Top 5 states by pre-shipment (seller) time:**

| State | Orders | Pre-shipment (days) | Post-shipment (days) |
|---|---|---|---|
| RR | 41 | 3.7 | 25.6 |
| SE | 334 | 3.6 | 18.0 |
| RN | 474 | 3.6 | 15.7 |
| MA | 714 | 3.6 | 18.0 |
| PB | 517 | 3.5 | 16.9 |

**Interpretation:** Pre-shipment time is steady across all states (2.8 to 3.7 days), but post-shipment time varies widely, from almost zero to 25.6 days. The slowest states (RR, AP, AM, AL, PA) are all in Brazil's North region, showing that location and logistics infrastructure are the main issues, not seller quality. Note that RR and AP have very few orders (41 and 67), so these specific averages carry more uncertainty than higher-volume states.

### 6.2 "Bigger Contributor" Classification

**Result:** Every state classifies as `courier_side_larger`, with no exceptions.

**Interpretation:** This confirms Section 6.1's finding is not an isolated pattern — carrier time dominates seller time consistently across the states where delay is most severe.

---

## 7. Analysis — Revenue and On-Time Delivery

### 7.1 Delivered Revenue by State

| State | Total Revenue (R$) | Orders |
|---|---|---|
| SP | 5,059,138.64 | 40,427 |
| RJ | 1,757,845.45 | 12,330 |
| MG | 1,548,587.00 | 11,327 |
| RS | 726,671.73 | 5,327 |
| PR | 664,311.94 | 4,912 |

**Interpretation:** São Paulo (SP) makes up roughly 42% of all delivered orders and revenue. Because of this high concentration, SP's delivery performance has a much bigger impact on the overall business than smaller states.

### 7.2 On-Time vs. Late Delivery by State (Supporting Metric)

| State | Orders | % Late |
|---|---|---|
| AL | 397 | 23.9% |
| MA | 714 | 19.7% |
| PI | 473 | 16.1% |
| SE | 334 | 15.3% |
| CE | 1,278 | 15.3% |

**Interpretation:** Alagoas (AL) struggles with both high late-delivery rates and long post-shipment delays, confirming it is a major problem area. Interestingly, Roraima (RR) had the longest post-shipment time (25.6 days), but its late-delivery rate was low (12.2%). This is because Olist gives distant areas longer delivery estimates by default. As a result, relying only on on-time/late rates hides the true delivery cost in remote regions, making raw shipping times a more reliable metric.

---

## 8. Consolidated Findings

- Fulfilment delay is overwhelmingly a carrier/logistics issue, not a seller-processing issue. On average, 75% of total fulfilment time (9.3 of 12.6 days) occurs after the order leaves the seller.
- Seller performance is consistent nationwide (2.8–3.7 days); carrier performance is not. Post-shipment time ranges from near-zero to over 25 days depending on region, with North-region states (RR, AP, AM, AL, PA) most affected.
- Revenue is heavily concentrated in São Paulo, which generates ~42% of total delivered revenue — meaning fulfilment performance in SP carries outsized business importance.
- The on-time vs. late metric alone can be misleading in remote regions. Olist's estimated delivery dates already account for distance, so raw post-shipment time is a more honest measure of where delay actually occurs than the on-time/late flag.

---

## 9. Limitations

- The dataset spans September 2016 – October 2018 and does not reflect Olist's current operations; this is a demonstration of analytical method on historical, anonymized data rather than a live operational assessment.
- 188 orders (~0.2%) were excluded due to logically invalid date sequences, likely data-entry anomalies; this is a small proportion and unlikely to materially affect overall conclusions.
- A small number of extreme outliers (up to ~205 days post-shipment) were retained in average calculations; a future iteration could explore excluding or separately analyzing these.
- This analysis identifies patterns and associations, not root causes — e.g., a region's high post-shipment time may stem from distance, carrier capacity, or local infrastructure, none of which are directly captured in this dataset.
- Seller-specific performance and product-category effects are intentionally out of scope for Milestone 1 and will be addressed in Milestone 2.

---

## 10. Team Contributions

| Team Member | Role | Key Contributions |
|---|---|---|
| Atikaa Abbas | Data Setup & Quality | Loaded and cleaned all three tables; built and refined the `clean_orders` view; identified and resolved a stage-level date-logic issue; produced overall fulfilment metrics |
| Imtesal Fatima | Regional Delay Analysis | Calculated pre/post-shipment time by state; identified courier-driven vs. seller-driven delay patterns; confirmed findings after data-quality refinement |
| Maria Noor | Revenue & On-Time Analysis | Calculated delivered revenue by state; calculated on-time/late rates; identified the relationship between raw delay and Olist's estimate-based "on-time" metric |

---

## Milestone 2 — Seller, Category & Review-Level Analysis

Building on Milestone 1, Milestone 2 dug deeper into which individual sellers, product categories,
and customer-review patterns drive fulfilment delay.

**Key MP2 Findings:**
- A small group of sellers — not the whole seller base — drives most seller-side delay (worst seller: 26.2 days vs. 3.2 platform average)
- Every worst seller-to-customer route involves a South/Southeast seller shipping to a North/Northeast customer, confirming delay is route-based, not seller-quality-based
- "Office furniture" is a consistently slow category regardless of region
- Courier delay is ~5x more strongly associated with poor reviews than seller delay (8.8 vs. 1.8 day swing from 5-star to 1-star)
- Overall, courier delay is the bigger factor in 82.1% of all orders

See `MP2_Report.docx` for full methodology, queries, and findings, and `sql/06` through `sql/09` for the analysis queries.

**Next Steps (Capstone):** Incorporate geolocation-based distance metrics to isolate true distance effects from regional/infrastructure effects — a direction raised during our panel presentation.

---

## 11. Next Steps (Milestone 2 Preview)

Milestone 2 will extend this analysis to the seller and product-category level, identifying which individual sellers show the largest pre-shipment delay, whether seller-to-customer distance explains regional patterns, how product category relates to fulfilment time, and how review scores relate to the seller/courier delay split. This maintains the same core theme established in Milestone 1: separating fulfilment time into its component causes rather than treating "delivery time" as a single, undifferentiated number.
