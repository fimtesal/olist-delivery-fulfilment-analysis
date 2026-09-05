-- ============================================
-- 05_revenue_ontime_analysis.sql
-- Revenue by state and on-time/late delivery analysis
-- ============================================

-- Delivered revenue by state
SELECT
    c.customer_state,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    COUNT(DISTINCT o.order_id) AS delivered_orders
FROM clean_orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY total_revenue DESC;
-- Top 5 by revenue: SP (5,059,138.64 / 40,427 orders), RJ (1,757,845.45 / 12,330),
-- MG (1,548,587.00 / 11,327), RS (726,671.73 / 5,327), PR (664,311.94 / 4,912)

-- On-time vs. late delivery rate by state (supporting metric only)
SELECT
    c.customer_state,
    ROUND(100.0 * SUM(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
                       THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_late
FROM clean_orders o
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY pct_late DESC;
-- Top 5 worst late-delivery states: AL (23.9%), MA (19.7%), PI (16.1%), SE (15.3%), CE (15.3%)

-- Note: Roraima (RR) — the worst state for raw post-shipment time (25.6 days, see 04_delay_split_analysis.sql)
-- has only a 12.2% late rate, since Olist's own estimated delivery dates already build in a large buffer
-- for distant regions. This demonstrates why raw time metrics are more informative than the on-time/late flag alone.
