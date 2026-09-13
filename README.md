# Seller vs. Courier: Diagnosing Delivery Delay in a Brazilian E-Commerce Marketplace

**Team:** Atikaa Abbas · Imtesal Fatima · Maria Noor
**Dataset:** Brazilian E-Commerce Public Dataset by Olist (Kaggle)
**Tool Used:** SQLite
**Track:** AuratTech Data Analyst Track

---

## Project Summary

When a delivery is late, it could be the seller's fault (slow to prepare and ship the order) or the courier's fault (slow to deliver it once shipped) — and each requires a completely different operational response. This project analyzes ~99,000 real, anonymized orders from Olist to diagnose where fulfilment delay actually originates: seller processing time or courier transit time. Milestone 1 established the regional pattern; Milestone 2 dug deeper into individual sellers, product categories, and customer reviews.

**Headline finding:** Courier transit time (9.3 days average) is roughly 3x longer than seller processing time (3.2 days) — meaning ~75% of total delivery time occurs after the order leaves the seller. This pattern holds at the order level too: courier delay is the bigger factor in 82.1% of all orders.

---

# Milestone 1 — Regional Delivery Performance Baseline

## Problem Statement

An e-commerce marketplace wants to understand where time is being spent across the order-fulfilment process. This project separates fulfilment time into pre-shipment processing time and post-shipment delivery time, compares these components across sellers and regions, and identifies patterns where delays are concentrated.

**Main Question:** Is delay in the order-fulfilment process more attributable to the pre-shipment (seller-side) stage or the post-shipment (courier/delivery) stage, and does this differ by region?

## Dataset & Methodology

**Tables:** `orders`, `order_items`, `customers` (96,281 orders after cleaning)

**Metric Definitions:**
| Metric | Formula |
|---|---|
| Pre-shipment processing time | carrier_date − purchase_timestamp |
| Post-shipment delivery time | delivered_date − carrier_date |
| Total fulfilment time | delivered_date − purchase_timestamp |

**Data-Handling Rules:**
- Only `order_status = 'delivered'` orders included in delivery-time calculations
- Orders with missing/invalid dates excluded from calculations (not deleted from source)
- Revenue uses `SUM(price)`; order counts use `COUNT(DISTINCT order_id)` to avoid double-counting
- "On-time" is a supporting metric only, since Olist's estimated dates include a distance buffer

## Data Cleaning Summary

| Check | Result |
|---|---|
| Total raw orders | 99,441 |
| Delivered-status orders | 96,478 |
| Missing carrier/delivery dates | 1,783 / 2,965 |
| Invalid date-sequence orders excluded | 188 (165 + 23) |
| Final clean dataset | 96,281 |
| order_items / customers integrity issues | 0 |

## Key Results — Overall Metrics

| Metric | Value |
|---|---|
| Average total fulfilment time | 12.6 days |
| Average pre-shipment (seller) time | **3.2 days** |
| Average post-shipment (courier) time | **9.3 days** |

## Key Results — Regional Patterns

**Top 5 states by courier (post-shipment) time:**

| State | Orders | Seller Time | Courier Time |
|---|---|---|---|
| RR | 41 | 3.7 | 25.6 |
| AP | 67 | 3.5 | 23.7 |
| AM | 145 | 2.9 | 23.5 |
| AL | 397 | 3.5 | 21.1 |
| PA | 945 | 3.5 | 20.3 |

Seller time stays within 2.8–3.7 days nationwide; courier time varies from near-zero to 25.6 days, concentrated in North-region states. Every top-affected state classifies as `courier_side_larger`.

## Key Results — Revenue & On-Time Delivery

- São Paulo (SP) generates ~42% of total delivered revenue (R$5.06M, 40,427 orders)
- Highest late-delivery-rate states: AL (23.9%), MA (19.7%), PI (16.1%)
- Roraima (RR) had the *worst raw courier time* (25.6 days) but only a 12.2% late rate — because Olist's estimate already buffers for distance. Raw time metrics are more reliable than "on-time %" for identifying real delay.

## Milestone 1 Consolidated Findings

1. Fulfilment delay is overwhelmingly a carrier/logistics issue, not a seller-processing issue — 75% of total time occurs after the order leaves the seller.
2. Seller performance is consistent nationwide; carrier performance is not, with North-region states most affected.
3. Revenue is heavily concentrated in São Paulo, making its fulfilment performance disproportionately important.
4. The on-time/late metric alone can be misleading in remote regions — raw post-shipment time is the more honest measure.

## Milestone 1 Limitations

- Historical (2016–2018) data; no live business impact — a demonstration of method, not a live diagnostic
- 188 orders (~0.2%) excluded for invalid date sequences
- Extreme outliers (up to ~205 days) retained in averages
- Shows patterns/associations, not root causes

---

# Milestone 2 — Seller, Category & Review-Level Analysis

## Problem Statement (Extended)

Milestone 1 established that courier delay dominates seller delay and is regionally concentrated. Milestone 2 extends this to a finer level: which individual sellers and product categories drive delay, and whether it's associated with customer satisfaction.

**Main Question:** Which individual sellers and product-category segments show the largest fulfilment delay, and is that delay more associated with seller processing time or courier transit time?

## New Tables Added

`sellers`, `products`, `product_category_name_translation`, `order_reviews` — all joined to the same `clean_orders` view (96,281 orders) established in Milestone 1. Integrity checks found 0 issues in `sellers`/`products`; 645 orders (~0.7%) had no matching review, which is expected since reviews are optional.

## Key Results — Seller-Level Analysis

The slowest individual seller averages **26.2 days** for pre-shipment (vs. 3.2-day platform average) across 12 orders — over 8x the norm. The top 10 slowest sellers (minimum 10 orders each) cluster between 12.4–26.2 days, showing seller-side delay is driven by a **small group of sellers**, not the broader seller base.

## Key Results — Seller-State vs. Customer-State

Every one of the 10 worst seller-to-customer combinations involves a South/Southeast seller (SP, PR, RJ, MG, SC) shipping to a North/Northeast customer (RR, AL, AP, RO, PA, AM, CE, PB) — e.g., SP→RR averages 26.4 days, PR→AL averages 26.3 days. Even sellers from major hubs take this long on these routes, confirming the delay is **route/distance-based, not seller-quality-based**.

## Key Results — Product Category

| Category | Orders | Pre-Shipment Days | Post-Shipment Days |
|---|---|---|---|
| office_furniture | 1,253 | 10.9 | 10.0 |
| fashion_shoes | 235 | 5.6 | 9.9 |
| fashion_male_clothing | 106 | 4.9 | 8.1 |

"Office furniture" sellers take **3.4x longer** than the platform average to ship — a genuinely new pattern versus Milestone 1, where seller time was uniform across all regions. It also appears 3 times among the worst state+category "high-delay segments" (CE, BA, PE), confirming it's consistently slow regardless of region — a **category problem**, distinct from AL's **region problem** (which appears 3 times with different categories).

## Key Results — Review Scores

| Review Score | Seller Time (days) | Courier Time (days) |
|---|---|---|
| 1 ⭐ | 4.7 | 16.6 |
| 3 ⭐ | 3.6 | 10.7 |
| 5 ⭐ | 2.9 | 7.8 |

From 5-star to 1-star, courier time rises **8.8 days** vs. only **1.8 days** for seller time — roughly **5x more movement**. Courier delay is the stronger driver of poor reviews.

**Overall bottleneck classification (order level):** 82.1% of orders are courier-driven delays; 17.9% are seller-driven — directly confirming Milestone 1's central finding at the individual-order level.

## Milestone 2 Consolidated Findings

1. A small group of sellers — not the whole seller base — drives most seller-side delay.
2. Route (South→North), not seller identity, drives the worst regional delays.
3. Product category adds a new dimension: "office_furniture" is a consistently slow category.
4. Courier delay is the stronger driver of poor reviews, and is the bigger factor in 82% of all orders.

## Milestone 2 Limitations

- Seller/category rankings use a minimum order threshold to avoid small-sample bias
- Review scores may reflect factors unrelated to delivery; findings are associative, not causal
- Seller-state vs. customer-state comparisons use state pairs as a distance proxy, not exact geography
- 645 orders (~0.7%) excluded from review-specific analysis only (no matching review)

## Team Contributions

| Team Member | Role | Key Contributions |
|---|---|---|
| Atikaa Abbas | Data Setup & Seller Analysis | Built/refined `clean_orders`; identified and resolved a stage-level date-logic bug; seller-level and seller-state vs. customer-state analysis |
| Imtesal Fatima | Regional & Category Analysis | State-wise delay-split analysis (MP1); product-category and high-delay-segment analysis (MP2) |
| Maria Noor | Revenue, Reviews & Bottleneck Analysis | Revenue and on-time analysis (MP1); review-score and overall bottleneck classification (MP2) |

---

## Repository Structure

```
├── README.md (this file)
├── MP1_Report.docx
├── MP2_Report.docx
├── sql/
│   ├── 01_data_checks.sql
│   ├── 02_clean_orders_view.sql
│   ├── 03_overview_analysis.sql
│   ├── 04_delay_split_analysis.sql
│   ├── 05_revenue_ontime_analysis.sql
│   ├── 06_mp2_new_table_checks.sql
│   ├── 07_mp2_seller_analysis.sql
│   ├── 08_mp2_category_analysis.sql
│   └── 09_mp2_review_bottleneck_analysis.sql
├── docs/
│   └── data_dictionary.md
└── visuals/
    ├── courier_time_by_state.png
    └── revenue_by_state.png
```

---

## Next Steps (Capstone)

Based on external panel feedback, the Capstone will incorporate **geolocation-based distance data** to calculate actual seller-to-customer distance (via the Haversine formula), separating genuine distance effects from regional infrastructure effects — moving beyond the state-pair proxy used in Milestone 2. Additional next steps: validate patterns against more recent data, and build a formal seller/segment priority-scoring system for operational recommendations.

**A note on scope:** This analysis uses historical (2016–2018), anonymized data, so it demonstrates the diagnostic method rather than producing a live business outcome. It shows associations, not proven causation — findings point to where a business should investigate further (e.g., a targeted A/B test on courier partnerships), not a finished causal proof.
