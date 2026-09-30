/*
Project: Olist Brazilian E-Commerce Analysis
File: 01_data_quality.sql
Purpose: Initial data quality assessment
Database: OlistDB
Schema: public
*/

-- ============================================================
-- 1. ROW COUNTS
-- ============================================================

SELECT 'customers' AS table_name, COUNT(*) AS row_count
FROM public.customers

UNION ALL

SELECT 'geolocation', COUNT(*)
FROM public.geolocation

UNION ALL

SELECT 'order_items', COUNT(*)
FROM public.order_items

UNION ALL

SELECT 'order_payments', COUNT(*)
FROM public.order_payments

UNION ALL

SELECT 'order_reviews', COUNT(*)
FROM public.order_reviews

UNION ALL

SELECT 'orders', COUNT(*)
FROM public.orders

UNION ALL

SELECT 'product_category_name_translation', COUNT(*)
FROM public.product_category_name_translation

UNION ALL

SELECT 'products', COUNT(*)
FROM public.products

UNION ALL

SELECT 'sellers', COUNT(*)
FROM public.sellers

ORDER BY table_name;


-- ============================================================
-- 2. DUPLICATE PRIMARY KEYS
-- ============================================================

-- Customers
SELECT customer_id, COUNT(*) AS duplicate_count
FROM public.customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- Orders
SELECT order_id, COUNT(*) AS duplicate_count
FROM public.orders
GROUP BY order_id
HAVING COUNT(*) > 1;

-- Products
SELECT product_id, COUNT(*) AS duplicate_count
FROM public.products
GROUP BY product_id
HAVING COUNT(*) > 1;

-- Sellers
SELECT seller_id, COUNT(*) AS duplicate_count
FROM public.sellers
GROUP BY seller_id
HAVING COUNT(*) > 1;


-- ============================================================
-- 3. MISSING VALUES — ORDERS
-- ============================================================

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS null_order_id,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS null_customer_id,
    COUNT(*) FILTER (WHERE order_status IS NULL) AS null_order_status,
    COUNT(*) FILTER (WHERE order_purchase_timestamp IS NULL) AS null_purchase_timestamp
FROM public.orders;


-- ============================================================
-- 4. MISSING VALUES — ORDER PAYMENTS
-- ============================================================

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS null_order_id,
    COUNT(*) FILTER (WHERE payment_sequential IS NULL) AS null_payment_sequential,
    COUNT(*) FILTER (WHERE payment_type IS NULL) AS null_payment_type,
    COUNT(*) FILTER (WHERE payment_installments IS NULL) AS null_payment_installments,
    COUNT(*) FILTER (WHERE payment_value IS NULL) AS null_payment_value
FROM public.order_payments;


-- ============================================================
-- 5. MISSING VALUES — PRODUCTS
-- ============================================================

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS null_product_id,
    COUNT(*) FILTER (WHERE product_category_name IS NULL) AS null_category,
    COUNT(*) FILTER (WHERE product_name_lenght IS NULL) AS null_name_length,
    COUNT(*) FILTER (WHERE product_description_lenght IS NULL) AS null_description_length,
    COUNT(*) FILTER (WHERE product_photos_qty IS NULL) AS null_photos_qty
FROM public.products;


-- ============================================================
-- 6. DATE RANGE — ORDERS
-- ============================================================

SELECT
    MIN(order_purchase_timestamp) AS first_order,
    MAX(order_purchase_timestamp) AS last_order
FROM public.orders;


-- ============================================================
-- 7. INVALID PAYMENT VALUES
-- ============================================================

SELECT
    COUNT(*) AS negative_payment_values
FROM public.order_payments
WHERE payment_value < 0;


-- ============================================================
-- 8. INVALID PAYMENT INSTALLMENTS
-- ============================================================

SELECT
    COUNT(*) AS invalid_installments
FROM public.order_payments
WHERE payment_installments <= 0;


-- ============================================================
-- 9. ORPHAN ORDER PAYMENTS
-- ============================================================

SELECT COUNT(*) AS orphan_payments
FROM public.order_payments p
LEFT JOIN public.orders o
    ON p.order_id = o.order_id
WHERE o.order_id IS NULL;


-- ============================================================
-- 10. ORPHAN ORDER ITEMS
-- ============================================================

SELECT COUNT(*) AS orphan_order_items
FROM public.order_items oi
LEFT JOIN public.orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;


-- ============================================================
-- 11. ORPHAN PRODUCTS
-- ============================================================

SELECT COUNT(*) AS orphan_products
FROM public.order_items oi
LEFT JOIN public.products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;


-- ============================================================
-- 12. ORPHAN SELLERS
-- ============================================================

SELECT COUNT(*) AS orphan_sellers
FROM public.order_items oi
LEFT JOIN public.sellers s
    ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;


-- ============================================================
-- 13. PAYMENT TYPE DISTRIBUTION
-- ============================================================

SELECT
    payment_type,
    COUNT(*) AS payment_count,
    ROUND(SUM(payment_value), 2) AS total_payment_value
FROM public.order_payments
GROUP BY payment_type
ORDER BY total_payment_value DESC;
