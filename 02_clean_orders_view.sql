-- ============================================
-- 02_clean_orders_view.sql
-- Builds the shared clean_orders view used by all subsequent analysis
-- ============================================

CREATE VIEW clean_orders AS
SELECT *
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_carrier_date IS NOT NULL AND order_delivered_carrier_date != ''
  AND order_delivered_customer_date IS NOT NULL AND order_delivered_customer_date != ''
  AND order_delivered_customer_date >= order_purchase_timestamp
  AND order_delivered_carrier_date >= order_purchase_timestamp
  AND order_delivered_customer_date >= order_delivered_carrier_date;

-- Confirm row count
SELECT COUNT(*) FROM clean_orders;
-- Result: 96,281 (from 96,478 delivered orders; 197 excluded for missing/invalid dates)
