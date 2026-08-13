-- =====================================================
-- E-COMMERCE SUPPLY CHAIN ANALYSIS
-- 01_data_quality.sql
-- =====================================================


-- =====================================================
-- SECTION 1: TABLE ROW COUNT VALIDATION
-- =====================================================

-- Validation: Compare row counts across all raw tables
SELECT
    (SELECT COUNT(*) FROM customers) AS customers,
    (SELECT COUNT(*) FROM orders) AS orders,
    (SELECT COUNT(*) FROM order_items) AS order_items,
    (SELECT COUNT(*) FROM products) AS products,
    (SELECT COUNT(*) FROM payments) AS payments;


-- =====================================================
-- SECTION 2: KEY UNIQUENESS CHECKS
-- =====================================================

-- Validation: Confirm customer_id is unique in customers
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS unique_customers
FROM customers;


-- Validation: Confirm order_id is unique in orders
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_orders
FROM orders;


-- Validation: Check whether product_id is unique in products
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT product_id) AS unique_products
FROM products;


-- =====================================================
-- SECTION 3: PRODUCT DUPLICATE INVESTIGATION
-- =====================================================

-- Validation: Identify duplicated product IDs and their occurrence counts
SELECT
    product_id,
    COUNT(*) AS occurrences
FROM products
GROUP BY product_id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;


-- Exploration: Inspect the most frequently duplicated product ID
SELECT *
FROM products
WHERE product_id = (
    SELECT product_id
    FROM products
    GROUP BY product_id
    ORDER BY COUNT(*) DESC
    LIMIT 1
);


-- Validation: Check whether duplicate product IDs contain conflicting attributes
SELECT
    product_id,
    COUNT(*) AS row_count,

    COUNT(DISTINCT (
        product_category_name,
        product_weight_g,
        product_length_cm,
        product_height_cm,
        product_width_cm
    )) AS distinct_versions

FROM products

GROUP BY product_id

HAVING COUNT(DISTINCT (
    product_category_name,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
)) > 1;


-- =====================================================
-- SECTION 4: CREATE CLEAN PRODUCT DIMENSION
-- =====================================================

-- Cleaning: Create a deduplicated product table with one row per unique product
CREATE TABLE products_clean AS
SELECT DISTINCT
    product_id,
    product_category_name,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
FROM products;


-- Cleaning: Enforce product_id uniqueness in the cleaned product table
ALTER TABLE products_clean
ADD PRIMARY KEY (product_id);


-- Validation: Confirm products_clean contains one row per unique product
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT product_id) AS unique_products
FROM products_clean;


-- =====================================================
-- SECTION 5: REFERENTIAL INTEGRITY CHECKS
-- =====================================================

-- Validation: Check whether every order item matches a valid order
SELECT
    COUNT(*) AS unmatched_order_items
FROM order_items oi

LEFT JOIN orders o
    ON oi.order_id = o.order_id

WHERE o.order_id IS NULL;


-- Validation: Check whether every order item matches a valid cleaned product
SELECT
    COUNT(*) AS unmatched_products
FROM order_items oi

LEFT JOIN products_clean p
    ON oi.product_id = p.product_id

WHERE p.product_id IS NULL;


-- Validation: Check whether every payment matches a valid order
SELECT
    COUNT(*) AS unmatched_payments
FROM payments p

LEFT JOIN orders o
    ON p.order_id = o.order_id

WHERE o.order_id IS NULL;