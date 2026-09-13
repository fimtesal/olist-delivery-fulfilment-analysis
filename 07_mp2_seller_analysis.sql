-- ============================================
-- 07_mp2_seller_analysis.sql
-- Seller-level and seller-state vs customer-state analysis
-- ============================================

-- Top 10 slowest individual sellers by pre-shipment time (minimum 10 orders)
SELECT
    oi.seller_id,
    COUNT(DISTINCT oi.order_id) AS order_count,
    ROUND(AVG(JULIANDAY(o.order_delivered_carrier_date) - JULIANDAY(o.order_purchase_timestamp)), 1) AS avg_pre_shipment_days
FROM clean_orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY oi.seller_id
HAVING COUNT(DISTINCT oi.order_id) >= 10
ORDER BY avg_pre_shipment_days DESC
LIMIT 10;
-- Result: slowest seller averages 26.2 days (12 orders) vs. platform average of 3.2 days;
-- top 10 sellers range 12.4-26.2 days, showing seller-side delay is concentrated
-- in a small group, not the whole seller base.

-- Seller-state vs. customer-state combinations, worst post-shipment time (minimum 10 orders)
SELECT
    s.seller_state,
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS order_count,
    ROUND(AVG(JULIANDAY(o.order_delivered_customer_date) - JULIANDAY(o.order_delivered_carrier_date)), 1) AS avg_post_shipment_days
FROM clean_orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN sellers s ON oi.seller_id = s.seller_id
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY s.seller_state, c.customer_state
HAVING COUNT(DISTINCT o.order_id) >= 10
ORDER BY avg_post_shipment_days DESC
LIMIT 10;
-- Result: all top 10 worst combinations involve a South/Southeast seller (SP, PR, RJ, MG, SC)
-- shipping to a North/Northeast customer (RR, AL, AP, RO, PA, AM, CE, PB) -- e.g. SP->RR: 26.4 days,
-- PR->AL: 26.3 days. Confirms the delay is route/distance-based, not seller-quality-based.
