-- ============================================
-- 09_mp2_review_bottleneck_analysis.sql
-- Review score analysis and overall bottleneck classification
-- ============================================

-- Review score vs. total delivery time
SELECT
    r.review_score,
    COUNT(DISTINCT o.order_id) AS order_count,
    ROUND(AVG(JULIANDAY(o.order_delivered_customer_date) - JULIANDAY(o.order_purchase_timestamp)), 1) AS avg_total_days
FROM clean_orders o
JOIN order_reviews r ON o.order_id = r.order_id
GROUP BY r.review_score
ORDER BY r.review_score;
-- Result: 1-star orders average 21.3 days vs. 10.7 days for 5-star orders --
-- a clear, monotonic pattern: as review score drops, delivery time rises.

-- Review score vs. seller time vs. courier time (isolating which side matters more)
SELECT
    r.review_score,
    ROUND(AVG(JULIANDAY(o.order_delivered_carrier_date) - JULIANDAY(o.order_purchase_timestamp)), 1) AS avg_pre_shipment_days,
    ROUND(AVG(JULIANDAY(o.order_delivered_customer_date) - JULIANDAY(o.order_delivered_carrier_date)), 1) AS avg_post_shipment_days
FROM clean_orders o
JOIN order_reviews r ON o.order_id = r.order_id
GROUP BY r.review_score
ORDER BY r.review_score;
-- Result: from 5-star to 1-star, seller time rises only 1.8 days (2.9 -> 4.7),
-- while courier time rises 8.8 days (7.8 -> 16.6) -- roughly 5x more movement.
-- Courier delay is the stronger driver of poor reviews, not seller delay.

-- Overall bottleneck classification across all clean orders
SELECT
    bigger_contributor,
    COUNT(*) AS order_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM clean_orders), 1) AS pct_of_orders
FROM (
    SELECT
        CASE
            WHEN (JULIANDAY(order_delivered_carrier_date) - JULIANDAY(order_purchase_timestamp)) >
                 (JULIANDAY(order_delivered_customer_date) - JULIANDAY(order_delivered_carrier_date))
            THEN 'seller_side_larger'
            ELSE 'courier_side_larger'
        END AS bigger_contributor
    FROM clean_orders
)
GROUP BY bigger_contributor;
-- Result: courier_side_larger = 79,072 orders (82.1%); seller_side_larger = 17,209 orders (17.9%).
-- At the order level, courier delay is the bigger factor in the large majority of cases,
-- confirming the project's central finding from Milestone 1.
