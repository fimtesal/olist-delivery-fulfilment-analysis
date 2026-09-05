-- ============================================
-- 04_delay_split_analysis.sql
-- Regional delay analysis: pre-shipment (seller) vs post-shipment (courier) time by state
-- ============================================

-- Pre-shipment and post-shipment time, by state
SELECT
    c.customer_state,
    COUNT(*) AS delivered_orders,
    ROUND(AVG(JULIANDAY(o.order_delivered_carrier_date) - JULIANDAY(o.order_purchase_timestamp)), 1) AS avg_pre_shipment_days,
    ROUND(AVG(JULIANDAY(o.order_delivered_customer_date) - JULIANDAY(o.order_delivered_carrier_date)), 1) AS avg_post_shipment_days
FROM clean_orders o
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY avg_post_shipment_days DESC;
-- Top 5 worst courier (post-shipment) states: RR (25.6), AP (23.7), AM (23.5), AL (21.1), PA (20.3)

-- Same query, sorted to find worst seller (pre-shipment) states
SELECT
    c.customer_state,
    COUNT(*) AS delivered_orders,
    ROUND(AVG(JULIANDAY(o.order_delivered_carrier_date) - JULIANDAY(o.order_purchase_timestamp)), 1) AS avg_pre_shipment_days,
    ROUND(AVG(JULIANDAY(o.order_delivered_customer_date) - JULIANDAY(o.order_delivered_carrier_date)), 1) AS avg_post_shipment_days
FROM clean_orders o
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY avg_pre_shipment_days DESC
LIMIT 5;
-- Top 5 worst seller (pre-shipment) states: RR (3.7), SE (3.6), RN (3.6), MA (3.6), PB (3.5)

-- "Bigger Contributor" classification: is seller or courier the larger delay factor, per state?
SELECT
    c.customer_state,
    ROUND(AVG(JULIANDAY(o.order_delivered_carrier_date) - JULIANDAY(o.order_purchase_timestamp)), 1) AS avg_pre_shipment_days,
    ROUND(AVG(JULIANDAY(o.order_delivered_customer_date) - JULIANDAY(o.order_delivered_carrier_date)), 1) AS avg_post_shipment_days,
    CASE
        WHEN AVG(JULIANDAY(o.order_delivered_carrier_date) - JULIANDAY(o.order_purchase_timestamp)) >
             AVG(JULIANDAY(o.order_delivered_customer_date) - JULIANDAY(o.order_delivered_carrier_date))
        THEN 'seller_side_larger'
        ELSE 'courier_side_larger'
    END AS bigger_contributor
FROM clean_orders o
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY avg_post_shipment_days DESC;
-- Result: all top-affected states classify as 'courier_side_larger', with no exceptions
