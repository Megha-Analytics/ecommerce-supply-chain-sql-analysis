-- =====================================================
-- E-COMMERCE SUPPLY CHAIN ANALYSIS
-- 02_business_analysis.sql
-- =====================================================

-- =====================================================
-- SECTION 1: ORDER STATUS & DELIVERY PERFORMANCE
-- =====================================================

-- Q1: How many orders were successfully delivered?
SELECT
    COUNT(*) AS delivered_orders
FROM orders
WHERE order_status = 'delivered';


-- Q2: What are the total number of orders and delivered orders?
SELECT
    COUNT(*) AS total_orders,

    SUM(
        CASE
            WHEN order_status = 'delivered' THEN 1
            ELSE 0
        END
    ) AS delivered_orders

FROM orders;


-- Q3: What percentage of orders fall into each order status?
SELECT
    order_status,
    COUNT(*) AS order_count,

    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_of_orders

FROM orders
GROUP BY order_status
ORDER BY order_count DESC;


-- =====================================================
-- SECTION 2: DELIVERY SPEED & ON-TIME PERFORMANCE
-- =====================================================

-- Q4: What is the average delivery time in days?
SELECT
    ROUND(
        AVG(
            EXTRACT(
                EPOCH FROM
                (order_delivered_timestamp - order_purchase_timestamp)
            ) / 86400
        )::numeric,
        2
    ) AS avg_delivery_days

FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_timestamp IS NOT NULL;


-- Q5: What percentage of delivered orders were On Time, Late,
-- or missing a delivery date?
SELECT
    CASE
        WHEN order_delivered_timestamp IS NULL
            THEN 'Missing Delivery Date'

        WHEN order_delivered_timestamp::date <=
             order_estimated_delivery_date
            THEN 'On Time'

        ELSE 'Late'
    END AS delivery_status,

    COUNT(*) AS order_count,

    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage

FROM orders
WHERE order_status = 'delivered'
GROUP BY delivery_status
ORDER BY order_count DESC;


-- =====================================================
-- SECTION 3: GEOGRAPHIC DELIVERY PERFORMANCE
-- =====================================================

-- Q6: Which customer states have the highest late-delivery rates?
SELECT
    c.customer_state,
    COUNT(*) AS delivered_orders,

    SUM(
        CASE
            WHEN o.order_delivered_timestamp::date >
                 o.order_estimated_delivery_date
            THEN 1
            ELSE 0
        END
    ) AS late_orders,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN o.order_delivered_timestamp::date >
                     o.order_estimated_delivery_date
                THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS late_delivery_rate_pct

FROM orders o

JOIN customers c
    ON o.customer_id = c.customer_id

WHERE o.order_status = 'delivered'
  AND o.order_delivered_timestamp IS NOT NULL

GROUP BY c.customer_state
ORDER BY late_delivery_rate_pct DESC;


-- =====================================================
-- SECTION 4: SHIPPING COST & DELIVERY PERFORMANCE
-- =====================================================

-- Q7: Do late deliveries have higher average shipping charges
-- than on-time deliveries?
SELECT
    CASE
        WHEN o.order_delivered_timestamp IS NULL
            THEN 'Missing Delivery Date'

        WHEN o.order_delivered_timestamp::date <=
             o.order_estimated_delivery_date
            THEN 'On Time'

        ELSE 'Late'
    END AS delivery_status,

    COUNT(*) AS order_count,

    ROUND(
        AVG(oi.shipping_charges),
        2
    ) AS avg_shipping_charge

FROM orders o

JOIN order_items oi
    ON o.order_id = oi.order_id

WHERE o.order_status = 'delivered'
GROUP BY delivery_status
ORDER BY order_count DESC;


-- =====================================================
-- SECTION 5: PRODUCT CHARACTERISTICS & DELIVERY PERFORMANCE
-- =====================================================

-- Q8: Are late deliveries associated with heavier products?
SELECT
    CASE
        WHEN o.order_delivered_timestamp IS NULL
            THEN 'Missing Delivery Date'

        WHEN o.order_delivered_timestamp::date <=
             o.order_estimated_delivery_date
            THEN 'On Time'

        ELSE 'Late'
    END AS delivery_status,

    COUNT(*) AS order_count,

    ROUND(
        AVG(p.product_weight_g),
        2
    ) AS avg_product_weight_g

FROM orders o

JOIN order_items oi
    ON o.order_id = oi.order_id

JOIN products_clean p
    ON oi.product_id = p.product_id

WHERE o.order_status = 'delivered'
GROUP BY delivery_status
ORDER BY order_count DESC;


-- Q9: Which product categories have the highest late-delivery rates?
SELECT
    p.product_category_name,
    COUNT(*) AS delivered_orders,

    SUM(
        CASE
            WHEN o.order_delivered_timestamp::date >
                 o.order_estimated_delivery_date
            THEN 1
            ELSE 0
        END
    ) AS late_orders,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN o.order_delivered_timestamp::date >
                     o.order_estimated_delivery_date
                THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS late_delivery_percent

FROM orders o

JOIN order_items oi
    ON o.order_id = oi.order_id

JOIN products_clean p
    ON oi.product_id = p.product_id

WHERE o.order_status = 'delivered'
  AND o.order_delivered_timestamp IS NOT NULL

GROUP BY p.product_category_name
ORDER BY late_delivery_percent DESC;


-- =====================================================
-- SECTION 6: SALES & PRODUCT PERFORMANCE
-- =====================================================

-- Q10: Which product categories generate the most sales,
-- and what percentage of total sales does each category contribute?
SELECT
    p.product_category_name,

    ROUND(
        SUM(oi.price),
        2
    ) AS total_sales,

    ROUND(
        100.0 *
        SUM(oi.price) /
        SUM(SUM(oi.price)) OVER (),
        2
    ) AS percentage_of_total_sales

FROM order_items oi

JOIN products_clean p
    ON oi.product_id = p.product_id

GROUP BY p.product_category_name
ORDER BY total_sales DESC;


-- =====================================================
-- SECTION 7: PAYMENT BEHAVIOR
-- =====================================================

-- Q11: Which payment methods are most commonly used by customers?
SELECT
    payment_type,
    COUNT(*) AS payment_count,

    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_of_payments

FROM payments
GROUP BY payment_type
ORDER BY payment_count DESC;


-- Q12: Which payment methods generate the highest total
-- and average payment values?
SELECT
    payment_type,
    COUNT(*) AS payment_count,

    ROUND(
        SUM(payment_value),
        2
    ) AS total_payment_value,

    ROUND(
        AVG(payment_value),
        2
    ) AS avg_payment_value

FROM payments
GROUP BY payment_type
ORDER BY total_payment_value DESC;


-- Q13: How does payment value vary by number of installments?
SELECT
    payment_installments,
    COUNT(*) AS payment_count,

    ROUND(
        AVG(payment_value),
        2
    ) AS avg_payment_value,

    ROUND(
        SUM(payment_value),
        2
    ) AS total_payment_value

FROM payments
GROUP BY payment_installments
ORDER BY payment_installments;


-- =====================================================
-- SECTION 8: GEOGRAPHIC SALES PERFORMANCE
-- =====================================================

-- Q14: Which customer states generate the most sales?
SELECT
    c.customer_state,
    COUNT(*) AS order_count,

    ROUND(
        SUM(oi.price),
        2
    ) AS total_sales,

    ROUND(
        100.0 *
        SUM(oi.price) /
        SUM(SUM(oi.price)) OVER (),
        2
    ) AS percentage_of_total_sales

FROM orders o

JOIN order_items oi
    ON o.order_id = oi.order_id

JOIN customers c
    ON o.customer_id = c.customer_id

GROUP BY c.customer_state
ORDER BY total_sales DESC;


-- =====================================================
-- SECTION 9: SALES + FULFILLMENT PRIORITIZATION
-- =====================================================

-- Q15: Which states combine high sales with poor delivery performance?
SELECT
    c.customer_state,
    COUNT(*) AS delivered_orders,

    ROUND(
        SUM(oi.price),
        2
    ) AS total_sales,

    SUM(
        CASE
            WHEN o.order_delivered_timestamp::date >
                 o.order_estimated_delivery_date
            THEN 1
            ELSE 0
        END
    ) AS late_orders,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN o.order_delivered_timestamp::date >
                     o.order_estimated_delivery_date
                THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS late_delivery_rate_pct

FROM orders o

JOIN customers c
    ON o.customer_id = c.customer_id

JOIN order_items oi
    ON o.order_id = oi.order_id

WHERE o.order_status = 'delivered'
  AND o.order_delivered_timestamp IS NOT NULL

GROUP BY c.customer_state
ORDER BY total_sales DESC;