-- ============================================
-- 08_mp2_category_analysis.sql
-- Product category and high-delay segment analysis
-- ============================================

-- Average pre/post-shipment time by product category (minimum 30 orders)
SELECT
    t.product_category_name_english,
    COUNT(DISTINCT o.order_id) AS order_count,
    ROUND(AVG(JULIANDAY(o.order_delivered_carrier_date) - JULIANDAY(o.order_purchase_timestamp)), 1) AS avg_pre_shipment_days,
    ROUND(AVG(JULIANDAY(o.order_delivered_customer_date) - JULIANDAY(o.order_delivered_carrier_date)), 1) AS avg_post_shipment_days
FROM clean_orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN product_category_name_translation t ON p.product_category_name = t.product_category_name
GROUP BY t.product_category_name_english
HAVING COUNT(DISTINCT o.order_id) >= 30
ORDER BY avg_pre_shipment_days DESC;
-- Result: "office_furniture" sellers take 10.9 days on average (1,253 orders) --
-- over 3x the platform average of 3.2 days. Fashion categories (shoes, clothing) also rank
-- high on seller time. This is a genuinely new pattern vs. Milestone 1, where seller time
-- was uniform across all regions.

-- High-delay segments: state + category combinations (minimum 15 orders)
SELECT
    c.customer_state,
    t.product_category_name_english,
    COUNT(DISTINCT o.order_id) AS order_count,
    ROUND(AVG(JULIANDAY(o.order_delivered_customer_date) - JULIANDAY(o.order_purchase_timestamp)), 1) AS avg_total_days
FROM clean_orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN product_category_name_translation t ON p.product_category_name = t.product_category_name
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_state, t.product_category_name_english
HAVING COUNT(DISTINCT o.order_id) >= 15
ORDER BY avg_total_days DESC
LIMIT 15;
-- Result: "office_furniture" appears 3 times in the worst 12 segments (CE, BA, PE) --
-- a consistently slow category regardless of region. AL (Alagoas) also appears 3 times
-- with different categories (telephony, furniture_decor, health_beauty), showing AL's
-- problem is regional/logistics-based, not tied to any specific product.
