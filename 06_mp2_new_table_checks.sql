-- ============================================
-- 06_mp2_new_table_checks.sql
-- Data Quality Checks: sellers, products, category_translation, order_reviews
-- ============================================

-- Check for missing seller_state
SELECT COUNT(*) FROM sellers WHERE seller_state IS NULL OR seller_state = '';
-- Result: 0

-- Check for orphan seller_id in order_items
SELECT COUNT(*) FROM order_items oi
LEFT JOIN sellers s ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;
-- Result: 0

-- Check for orphan product_id
SELECT COUNT(*) FROM order_items oi
LEFT JOIN products p ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;
-- Result: 0

-- Check order_reviews coverage against clean_orders
SELECT COUNT(*) FROM clean_orders o
LEFT JOIN order_reviews r ON o.order_id = r.order_id
WHERE r.order_id IS NULL;
-- Result: 645 (~0.7% of clean_orders have no matching review, since leaving a review is optional;
-- these are naturally excluded when joining to order_reviews in review-score analysis)
