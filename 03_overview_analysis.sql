-- ============================================
-- 03_overview_analysis.sql
-- Overall fulfilment metrics (whole dataset)
-- ============================================

-- Overall average pre-shipment, post-shipment, and total fulfilment time
SELECT
    COUNT(*) AS total_delivered_orders,
    ROUND(AVG(JULIANDAY(order_delivered_customer_date) - JULIANDAY(order_purchase_timestamp)), 1) AS avg_total_days,
    ROUND(AVG(JULIANDAY(order_delivered_carrier_date) - JULIANDAY(order_purchase_timestamp)), 1) AS avg_pre_shipment_days,
    ROUND(AVG(JULIANDAY(order_delivered_customer_date) - JULIANDAY(order_delivered_carrier_date)), 1) AS avg_post_shipment_days
FROM clean_orders;
-- Result: 96,281 orders | avg_total 12.6 days | avg_pre_shipment 3.2 days | avg_post_shipment 9.3 days

-- Min/Max check (outlier detection)
SELECT
    MIN(JULIANDAY(order_delivered_carrier_date) - JULIANDAY(order_purchase_timestamp)) AS min_pre_shipment,
    MAX(JULIANDAY(order_delivered_carrier_date) - JULIANDAY(order_purchase_timestamp)) AS max_pre_shipment,
    MIN(JULIANDAY(order_delivered_customer_date) - JULIANDAY(order_delivered_carrier_date)) AS min_post_shipment,
    MAX(JULIANDAY(order_delivered_customer_date) - JULIANDAY(order_delivered_carrier_date)) AS max_post_shipment
FROM clean_orders;
-- Result: min_pre ~0.0004 | max_pre 125.8 | min_post 0 | max_post 205.2
