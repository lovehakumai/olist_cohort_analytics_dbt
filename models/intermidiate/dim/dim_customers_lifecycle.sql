WITH 
cus_mst AS ( 
    SELECT * 
    FROM {{ ref('stg_OLIST_CUSTOMERS_DATASET') }}
)
, ord_mst AS ( 
    SELECT *
        , DATE_TRUNC('month', order_purchase_timestamp) AS order_purchase_month
    FROM {{ ref('stg_OLIST_ORDERS_DATASET') }} 
)
, cus_address AS (
    SELECT *
    FROM {{ref('stg_OLIST_CUSTOMERS_DATASET')}}
)
, ord_payments AS (
    SELECT * 
    FROM {{ref('stg_OLIST_ORDER_PAYMENTS_DATASET')}}
)
, cus_dim_fst_purchase AS (
    SELECT 
        customer_unique_id
        , customer_city
        , customer_state
        , order_purchase_month AS first_purchase_month
        , order_id AS first_purchase_order_id
    FROM cus_mst 
    LEFT JOIN ord_mst 
        USING(customer_id)
    QUALIFY 
        ROW_NUMBER() OVER (PARTITION BY customer_unique_id ORDER BY order_purchase_timestamp) = 1
)
, cus_dim_add_payment AS (
    SELECT 
        customer_unique_id
        , customer_city
        , customer_state
        , first_purchase_month
        , first_purchase_order_id
        , payment_type AS first_payment_type
    FROM cus_dim_fst_purchase AS fst_purchase
    LEFT JOIN ord_payments
        ON fst_purchase.first_purchase_order_id = ord_payments.order_id
    QUALIFY 
        ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY payment_value DESC) = 1 
)
, get_criteria AS (
    SELECT 
        MAX(order_purchase_timestamp) AS grand_last_purchased_at
    FROM ord_mst 
)
, cus_dim_status_raw AS (
    SELECT 
        customer_unique_id
        , MIN(order_purchase_timestamp) AS first_purchased_at
        , MAX(order_purchase_timestamp) AS last_purchased_at
        , COUNT(DISTINCT order_id) AS total_orders
    FROM cus_mst
    LEFT JOIN ord_mst 
        USING(customer_id)
    GROUP BY 
        customer_unique_id
)
, cus_dim_status AS (
    SELECT 
        customer_unique_id
        , first_purchased_at
        , last_purchased_at
        , total_orders
        , CASE 
            WHEN total_orders = 1 AND DATEDIFF('day', last_purchased_at, grand_last_purchased_at) > 90 THEN 'One Time'
            WHEN DATEDIFF('day', last_purchased_at, grand_last_purchased_at) <= 30 THEN 'Active'
            WHEN DATEDIFF('day', last_purchased_at, grand_last_purchased_at) <= 90 THEN 'At Risk'
            ELSE 'Churned'
        END AS customer_status
    FROM cus_dim_status_raw
    CROSS JOIN get_criteria
)
, dim_customer_lifecycle AS (
    SELECT 
        customer_unique_id
        , customer_city
        , customer_state
        , first_purchase_month
        , first_purchase_order_id
        , first_payment_type
        , first_purchased_at
        , last_purchased_at
        , total_orders
        , customer_status
    FROM cus_dim_add_payment 
    INNER JOIN cus_dim_status
        USING(customer_unique_id)
)
SELECT * FROM dim_customer_lifecycle