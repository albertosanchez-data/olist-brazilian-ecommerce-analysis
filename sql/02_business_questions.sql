/*
Project: Olist Brazilian E-Commerce Analysis
File: 02_business_questions.sql
Purpose: Business analysis queries and reproducible metrics
Database: OlistDB
Schema: public
*/
/*
Project: Olist Brazilian E-Commerce Analysis
File: 02_business_questions.sql
Business Question: What was the overall sales performance?
*/

-- ============================================================
-- BQ01 — OVERALL SALES PERFORMANCE
-- ============================================================

SELECT
    COUNT(DISTINCT oi.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS total_sales,
    ROUND(
        SUM(oi.price) / COUNT(DISTINCT oi.order_id),
        2
    ) AS average_order_value
FROM public.order_items oi;

-- ============================================================
-- BQ01 — SALES PERFORMANCE BY YEAR
-- ============================================================

SELECT
    EXTRACT(YEAR FROM o.order_purchase_timestamp)::INT AS order_year,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS total_sales,
    ROUND(
        SUM(oi.price) / COUNT(DISTINCT oi.order_id),
        2
    ) AS average_order_value
FROM public.orders o
JOIN public.order_items oi
    ON o.order_id = oi.order_id
GROUP BY EXTRACT(YEAR FROM o.order_purchase_timestamp)
ORDER BY order_year;

-- ============================================================
-- BQ02 — REVENUE AND ORDERS BY YEAR
-- ============================================================

SELECT
    EXTRACT(YEAR FROM o.order_purchase_timestamp)::INT AS order_year,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(op.payment_value), 2) AS total_payment_value
FROM public.orders o
JOIN public.order_payments op
    ON o.order_id = op.order_id
GROUP BY EXTRACT(YEAR FROM o.order_purchase_timestamp)
ORDER BY order_year;

-- ============================================================
-- BQ02 — PAYMENT METHOD ANALYSIS
-- ============================================================

SELECT
    payment_type,
    COUNT(*) AS payment_transactions,
    ROUND(SUM(payment_value), 2) AS total_payment_value,
    ROUND(AVG(payment_value), 2) AS average_payment_value
FROM public.order_payments
GROUP BY payment_type
ORDER BY total_payment_value DESC;

-- ============================================================
-- BQ03 — CUSTOMER PURCHASE FREQUENCY
-- ============================================================

WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM public.orders o
    JOIN public.customers c
        ON o.customer_id = c.customer_id
    GROUP BY c.customer_unique_id
)
SELECT
    CASE
        WHEN order_count = 1 THEN 'One-time customer'
        ELSE 'Repeat customer'
    END AS customer_type,
    COUNT(*) AS customers,
    SUM(order_count) AS total_orders
FROM customer_orders
GROUP BY
    CASE
        WHEN order_count = 1 THEN 'One-time customer'
        ELSE 'Repeat customer'
    END
ORDER BY customers DESC;

-- ============================================================
-- BQ03 — REVENUE BY CUSTOMER TYPE
-- ============================================================

WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        o.order_id,
        CASE
            WHEN COUNT(o.order_id) OVER (
                PARTITION BY c.customer_unique_id
            ) = 1
            THEN 'One-time customer'
            ELSE 'Repeat customer'
        END AS customer_type
    FROM public.orders o
    JOIN public.customers c
        ON o.customer_id = c.customer_id
),
customer_revenue AS (
    SELECT
        co.customer_unique_id,
        co.customer_type,
        co.order_id,
        SUM(op.payment_value) AS order_value
    FROM customer_orders co
    JOIN public.order_payments op
        ON co.order_id = op.order_id
    GROUP BY
        co.customer_unique_id,
        co.customer_type,
        co.order_id
)
SELECT
    customer_type,
    COUNT(DISTINCT customer_unique_id) AS customers,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(order_value), 2) AS total_revenue,
    ROUND(AVG(order_value), 2) AS average_order_value
FROM customer_revenue
GROUP BY customer_type
ORDER BY total_revenue DESC;

-- ============================================================
-- BQ04 — SALES BY CUSTOMER STATE
-- ============================================================

SELECT
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS total_sales,
    ROUND(
        SUM(oi.price) / COUNT(DISTINCT o.order_id),
        2
    ) AS average_order_value
FROM public.orders o
JOIN public.customers c
    ON o.customer_id = c.customer_id
JOIN public.order_items oi
    ON o.order_id = oi.order_id
GROUP BY c.customer_state
ORDER BY total_sales DESC;

-- ============================================================
-- BQ04 — SALES BY PRODUCT CATEGORY
-- ============================================================

SELECT
    COALESCE(
        pct.product_category_name_english,
        'Unknown'
    ) AS product_category,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    COUNT(oi.order_item_id) AS total_items,
    ROUND(SUM(oi.price), 2) AS total_sales,
    ROUND(AVG(oi.price), 2) AS average_item_price
FROM public.order_items oi
JOIN public.products p
    ON oi.product_id = p.product_id
LEFT JOIN public.product_category_name_translation pct
    ON p.product_category_name = pct.product_category_name
GROUP BY
    COALESCE(
        pct.product_category_name_english,
        'Unknown'
    )
ORDER BY total_sales DESC;

-- ============================================================
-- BQ05 — TOP SELLERS BY SALES
-- ============================================================

SELECT
    oi.seller_id,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    COUNT(oi.order_item_id) AS total_items,
    ROUND(SUM(oi.price), 2) AS total_sales,
    ROUND(AVG(oi.price), 2) AS average_item_price
FROM public.order_items oi
GROUP BY oi.seller_id
ORDER BY total_sales DESC
LIMIT 20;

-- ============================================================
-- BQ05 — SELLER PERFORMANCE WITH CUSTOMER REACH
-- ============================================================

SELECT
    oi.seller_id,
    COUNT(DISTINCT c.customer_unique_id) AS unique_customers,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    COUNT(oi.order_item_id) AS total_items,
    ROUND(SUM(oi.price), 2) AS total_sales,
    ROUND(
        SUM(oi.price) / COUNT(DISTINCT c.customer_unique_id),
        2
    ) AS sales_per_customer
FROM public.order_items oi
JOIN public.orders o
    ON oi.order_id = o.order_id
JOIN public.customers c
    ON o.customer_id = c.customer_id
GROUP BY oi.seller_id
ORDER BY total_sales DESC
LIMIT 20;

-- ============================================================
-- BQ06 — MONTHLY SALES TREND
-- ============================================================

SELECT
    DATE_TRUNC(
        'month',
        o.order_purchase_timestamp
    )::DATE AS sales_month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS total_sales,
    ROUND(
        SUM(oi.price) / COUNT(DISTINCT o.order_id),
        2
    ) AS average_order_value
FROM public.orders o
JOIN public.order_items oi
    ON o.order_id = oi.order_id
GROUP BY
    DATE_TRUNC(
        'month',
        o.order_purchase_timestamp
    )
ORDER BY sales_month;

-- ============================================================
-- BQ07 — ORDER STATUS ANALYSIS
-- ============================================================

SELECT
    order_status,
    COUNT(*) AS total_orders,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_of_orders
FROM public.orders
GROUP BY order_status
ORDER BY total_orders DESC;

-- ============================================================
-- BQ08 — REVIEW SCORE ANALYSIS
-- ============================================================

SELECT
    review_score,
    COUNT(*) AS total_reviews,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_of_reviews,
    ROUND(
        AVG(
            CASE
                WHEN review_comment_message IS NOT NULL
                     AND TRIM(review_comment_message) <> ''
                THEN 1
                ELSE 0
            END
        ) * 100,
        2
    ) AS comments_percentage
FROM public.order_reviews
GROUP BY review_score
ORDER BY review_score DESC;

-- ============================================================
-- BQ09 — DELIVERY PERFORMANCE
-- ============================================================

SELECT
    COUNT(*) AS delivered_orders,
    ROUND(
        AVG(
            EXTRACT(
                EPOCH FROM (
                    o.order_delivered_customer_date
                    - o.order_purchase_timestamp
                )
            ) / 86400
        ),
        2
    ) AS average_delivery_days,
    ROUND(
        MIN(
            EXTRACT(
                EPOCH FROM (
                    o.order_delivered_customer_date
                    - o.order_purchase_timestamp
                )
            ) / 86400
        ),
        2
    ) AS minimum_delivery_days,
    ROUND(
        MAX(
            EXTRACT(
                EPOCH FROM (
                    o.order_delivered_customer_date
                    - o.order_purchase_timestamp
                )
            ) / 86400
        ),
        2
    ) AS maximum_delivery_days
FROM public.orders o
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL;

-- ============================================================
-- BQ10 — ESTIMATED VS ACTUAL DELIVERY
-- ============================================================

SELECT
    CASE
        WHEN o.order_delivered_customer_date
             <= o.order_estimated_delivery_date
        THEN 'On time'
        ELSE 'Late'
    END AS delivery_performance,
    COUNT(*) AS total_orders,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_of_orders
FROM public.orders o
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY
    CASE
        WHEN o.order_delivered_customer_date
             <= o.order_estimated_delivery_date
        THEN 'On time'
        ELSE 'Late'
    END
ORDER BY total_orders DESC;

-- ============================================================
-- BQ11 — FREIGHT COST ANALYSIS
-- ============================================================

SELECT
    COUNT(*) AS total_items,
    ROUND(SUM(oi.price), 2) AS total_product_sales,
    ROUND(SUM(oi.freight_value), 2) AS total_freight,
    ROUND(
        SUM(oi.freight_value) /
        NULLIF(SUM(oi.price), 0) * 100,
        2
    ) AS freight_to_sales_percentage,
    ROUND(AVG(oi.freight_value), 2) AS average_freight_per_item
FROM public.order_items oi;

-- ============================================================
-- BQ12 — PRODUCT PRICE VS FREIGHT BY CATEGORY
-- ============================================================

SELECT
    COALESCE(
        pct.product_category_name_english,
        'Unknown'
    ) AS product_category,
    COUNT(*) AS total_items,
    ROUND(AVG(oi.price), 2) AS average_product_price,
    ROUND(AVG(oi.freight_value), 2) AS average_freight,
    ROUND(
        AVG(oi.freight_value) /
        NULLIF(AVG(oi.price), 0) * 100,
        2
    ) AS freight_to_price_percentage
FROM public.order_items oi
JOIN public.products p
    ON oi.product_id = p.product_id
LEFT JOIN public.product_category_name_translation pct
    ON p.product_category_name = pct.product_category_name
GROUP BY
    COALESCE(
        pct.product_category_name_english,
        'Unknown'
    )
ORDER BY freight_to_price_percentage DESC;

-- ============================================================
-- BQ13 — MONTHLY ORDER VOLUME VS SALES
-- ============================================================

SELECT
    DATE_TRUNC(
        'month',
        o.order_purchase_timestamp
    )::DATE AS sales_month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS total_sales,
    ROUND(
        SUM(oi.price) / COUNT(DISTINCT o.order_id),
        2
    ) AS average_order_value
FROM public.orders o
JOIN public.order_items oi
    ON o.order_id = oi.order_id
GROUP BY
    DATE_TRUNC(
        'month',
        o.order_purchase_timestamp
    )
ORDER BY sales_month;

-- ============================================================
-- BQ14 — AVERAGE ORDER VALUE BY CUSTOMER STATE
-- ============================================================

WITH order_values AS (
    SELECT
        o.order_id,
        c.customer_state,
        SUM(oi.price) AS order_value
    FROM public.orders o
    JOIN public.customers c
        ON o.customer_id = c.customer_id
    JOIN public.order_items oi
        ON o.order_id = oi.order_id
    GROUP BY
        o.order_id,
        c.customer_state
)
SELECT
    customer_state,
    COUNT(*) AS total_orders,
    ROUND(SUM(order_value), 2) AS total_sales,
    ROUND(AVG(order_value), 2) AS average_order_value
FROM order_values
GROUP BY customer_state
ORDER BY average_order_value DESC;

-- ============================================================
-- BQ15 — REVIEW SCORE VS DELIVERY PERFORMANCE
-- ============================================================

SELECT
    CASE
        WHEN o.order_delivered_customer_date
             <= o.order_estimated_delivery_date
        THEN 'On time'
        ELSE 'Late'
    END AS delivery_performance,
    r.review_score,
    COUNT(*) AS total_reviews,
    ROUND(
        COUNT(*) * 100.0
        / SUM(COUNT(*)) OVER (
            PARTITION BY
                CASE
                    WHEN o.order_delivered_customer_date
                         <= o.order_estimated_delivery_date
                    THEN 'On time'
                    ELSE 'Late'
                END
        ),
        2
    ) AS percentage_within_delivery_group
FROM public.orders o
JOIN public.order_reviews r
    ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY
    CASE
        WHEN o.order_delivered_customer_date
             <= o.order_estimated_delivery_date
        THEN 'On time'
        ELSE 'Late'
    END,
    r.review_score
ORDER BY
    delivery_performance,
    r.review_score DESC;

-- ============================================================
-- BQ16 — CANCELLATION AND UNAVAILABILITY BY YEAR
-- ============================================================

SELECT
    EXTRACT(
        YEAR FROM o.order_purchase_timestamp
    )::INT AS order_year,
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (
        WHERE o.order_status = 'canceled'
    ) AS canceled_orders,
    COUNT(*) FILTER (
        WHERE o.order_status = 'unavailable'
    ) AS unavailable_orders,
    ROUND(
        COUNT(*) FILTER (
            WHERE o.order_status IN ('canceled', 'unavailable')
        ) * 100.0 / COUNT(*),
        2
    ) AS unsuccessful_order_percentage
FROM public.orders o
GROUP BY
    EXTRACT(
        YEAR FROM o.order_purchase_timestamp
    )
ORDER BY order_year;

-- ============================================================
-- BQ17 — MONTHLY SALES GROWTH
-- ============================================================

WITH monthly_sales AS (
    SELECT
        DATE_TRUNC(
            'month',
            o.order_purchase_timestamp
        )::DATE AS sales_month,
        ROUND(SUM(oi.price), 2) AS total_sales
    FROM public.orders o
    JOIN public.order_items oi
        ON o.order_id = oi.order_id
    GROUP BY
        DATE_TRUNC(
            'month',
            o.order_purchase_timestamp
        )
)
SELECT
    sales_month,
    total_sales,
    LAG(total_sales) OVER (
        ORDER BY sales_month
    ) AS previous_month_sales,
    ROUND(
        (
            total_sales
            - LAG(total_sales) OVER (
                ORDER BY sales_month
            )
        )
        / NULLIF(
            LAG(total_sales) OVER (
                ORDER BY sales_month
            ),
            0
        ) * 100,
        2
    ) AS month_over_month_growth
FROM monthly_sales
ORDER BY sales_month;
