-- ============================================================
-- OLIST E-COMMERCE SQL ANALYSIS
-- Author: Suvarna
-- Tool: MySQL
-- ============================================================

USE olist_store_project;


-- ============================================================
-- KPI 1: Weekday vs Weekend Payment Statistics
-- ============================================================

SELECT 
    kpi1.day_end,
    CONCAT(
        ROUND(
            kpi1.total_payment /
            (SELECT SUM(payment_value)
             FROM olist_order_payments_dataset) * 100,
            2
        ),
        '%'
    ) AS percentage_payment_values
FROM
(
    SELECT 
        ord.day_end,
        SUM(pmt.payment_value) AS total_payment
    FROM olist_order_payments_dataset AS pmt
    JOIN
    (
        SELECT DISTINCT
            order_id,
            CASE
                WHEN WEEKDAY(order_purchase_timestamp) IN (5, 6)
                    THEN 'Weekend'
                ELSE 'Weekday'
            END AS day_end
        FROM olist_orders_dataset
    ) AS ord
        ON ord.order_id = pmt.order_id
    GROUP BY ord.day_end
) AS kpi1;


-- ============================================================
-- KPI 2: 5-Star Orders Paid by Credit Card
-- ============================================================

SELECT
    COUNT(DISTINCT pmt.order_id) AS total_orders
FROM olist_order_payments_dataset AS pmt
INNER JOIN olist_order_reviews_dataset AS rev
    ON pmt.order_id = rev.order_id
WHERE rev.review_score = 5
  AND pmt.payment_type = 'credit_card';


-- ============================================================
-- KPI 3: Average Delivery Days for Pet Shop
-- ============================================================

SELECT
    prod.product_category_name,
    ROUND(
        AVG(
            DATEDIFF(
                ord.order_delivered_customer_date,
                ord.order_purchase_timestamp
            )
        ),
        0
    ) AS avg_days_delivery
FROM olist_orders_dataset AS ord
JOIN
(
    SELECT
        product_id,
        order_id,
        product_category_name
    FROM olist_products_dataset
    JOIN olist_order_items_dataset
        USING (product_id)
) AS prod
    ON ord.order_id = prod.order_id
WHERE prod.product_category_name = 'Pet_Shop'
GROUP BY prod.product_category_name;


-- ============================================================
-- KPI 4: Average Price and Payment Value - São Paulo
-- ============================================================

WITH avg_order_items AS
(
    SELECT
        ROUND(AVG(item.price), 2) AS avg_order_item_price
    FROM olist_order_items_dataset AS item
    JOIN olist_orders_dataset AS ord
        ON item.order_id = ord.order_id
    JOIN olist_customers_dataset AS cust
        ON cust.customer_id = ord.customer_id
    WHERE cust.customer_city = 'Sao Paulo'
)
SELECT
    (SELECT avg_order_item_price
     FROM avg_order_items) AS avg_order_item_price,
    ROUND(AVG(pmt.payment_value), 2) AS avg_payment_value
FROM olist_order_payments_dataset AS pmt
JOIN olist_orders_dataset AS ord
    ON pmt.order_id = ord.order_id
JOIN olist_customers_dataset AS cust
    ON cust.customer_id = ord.customer_id
WHERE cust.customer_city = 'Sao Paulo';


-- ============================================================
-- KPI 5: Shipping Days vs Review Scores
-- ============================================================

SELECT
    rew.review_score,
    ROUND(
        AVG(
            DATEDIFF(
                ord.order_delivered_customer_date,
                ord.order_purchase_timestamp
            )
        ),
        0
    ) AS avg_shipping_days
FROM olist_orders_dataset AS ord
JOIN olist_order_reviews_dataset AS rew
    ON rew.order_id = ord.order_id
GROUP BY rew.review_score
ORDER BY rew.review_score;
