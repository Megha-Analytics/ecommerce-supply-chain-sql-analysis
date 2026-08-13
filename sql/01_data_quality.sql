-- =====================================================
-- E-COMMERCE SUPPLY CHAIN ANALYSIS
-- 01_data_quality.sql
-- =====================================================

-- =====================================================
-- SECTION 1: TABLE SIZE CHECKS
-- =====================================================

-- Check the number of rows in each core table
SELECT
    (SELECT COUNT(*) FROM customers) AS customers,
    (SELECT COUNT(*) FROM orders) AS orders,
    (SELECT COUNT(*) FROM order_items) AS order_items,
    (SELECT COUNT(*) FROM products) AS products,
    (SELECT COUNT(*) FROM payments) AS payments;


-- =====================================================
-- SECTION 2: PRIMARY KEY / DUPLICATE CHECKS
-- =====================================================

-- Check for duplicate customer IDs
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS unique_customers
FROM customers;

-- Check for duplicate order IDs
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_orders
FROM orders;

-- Check for duplicate product IDs
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT product_id) AS unique_products
FROM products;

-- Identify duplicated product IDs
SELECT
    product_id,
    COUNT(*) AS occurrences
FROM products
GROUP BY product_id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;


-- =====================================================
-- SECTION 3: PRODUCT DUPLICATE INVESTIGATION
-- =====================================================

-- Inspect the product ID with the highest number of duplicate rows
SELECT *
FROM products
WHERE product_id = (
    SELECT product_id
    FROM products
    GROUP BY product_id
    ORDER BY COUNT(*) DESC
    LIMIT 1
);

-- Determine whether duplicated product IDs contain
-- conflicting product attributes
SELECT
    product_id,
    COUNT(*) AS row_count,
    COUNT(
        DISTINCT (
            product_category_name,
            product_weight_g,
            product_length_cm,
            product_height_cm,
            product_width_cm
        )
    ) AS distinct_versions
FROM products
GROUP BY product_id
HAVING COUNT(
    DISTINCT (
        product_category_name,
        product_weight_g,
        product_length_cm,
        product_height_cm,
        product_width_cm
    )
) > 1;


-- =====================================================
-- SECTION 4: CREATE CLEAN PRODUCT TABLE
-- =====================================================

-- Create a deduplicated products table
CREATE TABLE products_clean AS
SELECT DISTINCT
    product_id,
    product_category_name,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
FROM products;

-- Enforce product_id uniqueness
ALTER TABLE products_clean
ADD PRIMARY KEY (product_id);

-- Verify that the cleaned table contains one row per product
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT product_id) AS unique_products
FROM products_clean;


-- =====================================================
-- SECTION 5: REFERENTIAL INTEGRITY CHECKS
-- =====================================================

-- Check whether every order item matches an order
SELECT
    COUNT(*) AS unmatched_order_items
FROM order_items oi
LEFT JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

-- Check whether every order item matches a cleaned product
SELECT
    COUNT(*) AS unmatched_products
FROM order_items oi
LEFT JOIN products_clean p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

-- Check whether every payment matches an order
SELECT
    COUNT(*) AS unmatched_payments
FROM payments p
LEFT JOIN orders o
    ON p.order_id = o.order_id
WHERE o.order_id IS NULL;


-- =====================================================
-- SECTION 6: DELIVERY DATE COMPLETENESS
-- =====================================================

-- Check delivery-date completeness for delivered orders
SELECT
    COUNT(*) AS delivered_orders,
    COUNT(order_delivered_timestamp) AS with_delivery_timestamp,
    COUNT(order_estimated_delivery_date) AS with_estimated_date
FROM orders
WHERE order_status = 'delivered';
