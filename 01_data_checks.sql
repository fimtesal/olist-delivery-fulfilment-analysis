-- ============================================
-- 01_data_checks.sql
-- Data Quality Checks: orders, order_items, customers
-- ============================================

-- ORDERS TABLE CHECKS
-- --------------------

-- Order status distribution
SELECT order_status, COUNT(*)
FROM orders
GROUP BY order_status
ORDER BY COUNT(*) DESC;

-- Missing dates count
SELECT
    SUM(CASE WHEN order_delivered_carrier_date IS NULL OR order_delivered_carrier_date = '' THEN 1 ELSE 0 END) AS missing_carrier_date,
    SUM(CASE WHEN order_delivered_customer_date IS NULL OR order_delivered_customer_date = '' THEN 1 ELSE 0 END) AS missing_delivered_date
FROM orders;

-- Date range confirmation
SELECT MIN(order_purchase_timestamp), MAX(order_purchase_timestamp) FROM orders;

-- Invalid date logic check: carrier-handoff date before purchase date
SELECT COUNT(*) FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_carrier_date != ''
  AND order_delivered_carrier_date < order_purchase_timestamp;
-- Result: 165

-- Invalid date logic check: delivery date before carrier-handoff date
SELECT COUNT(*) FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date != ''
  AND order_delivered_customer_date < order_delivered_carrier_date;
-- Result: 23


-- ORDER_ITEMS TABLE CHECKS
-- --------------------

-- Missing values check
SELECT
    SUM(CASE WHEN price IS NULL OR price = '' THEN 1 ELSE 0 END) AS missing_price,
    SUM(CASE WHEN seller_id IS NULL OR seller_id = '' THEN 1 ELSE 0 END) AS missing_seller
FROM order_items;

-- Invalid price check (zero or negative)
SELECT COUNT(*) FROM order_items WHERE CAST(price AS REAL) <= 0;

-- Orphan rows check: order_items referencing a non-existent order
SELECT COUNT(*) FROM order_items oi
LEFT JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;


-- CUSTOMERS TABLE CHECKS
-- --------------------

-- Distinct state values (checking for inconsistent naming)
SELECT DISTINCT customer_state FROM customers ORDER BY customer_state;

-- Duplicate customer_id check
SELECT customer_id, COUNT(*) FROM customers GROUP BY customer_id HAVING COUNT(*) > 1;

-- Orphan check: orders with no matching customer record
SELECT COUNT(*) FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;
