WITH 
cus_mst AS ( 
    SELECT * 
    FROM {{ ref('stg_OLIST_CUSTOMERS_DATASET') }}
)
, ord_mst AS ( 
    SELECT *
    FROM {{ ref('stg_OLIST_ORDERS_DATASET') }} 
)
, ord_payments AS (
    SELECT * 
    FROM {{ref('stg_OLIST_ORDER_PAYMENTS_DATASET')}}
)
, get_criteria AS (
    SELECT 
        MAX(order_purchase_timestamp) AS grand_last_purchased_at
    FROM ord_mst 
)
, int_cus_orders AS (
    SELECT 
        customer_unique_id
        , customer_city
        , customer_state
        , order_id
        , order_purchase_timestamp
    FROM cus_mst 
    LEFT JOIN ord_mst 
        USING(customer_id)
)
, cus_dim_base AS (
    SELECT 
        customer_unique_id
        , customer_city
        , customer_state
    FROM int_cus_orders
    GROUP BY 
        customer_unique_id
        , customer_city
        , customer_state
)
, cus_dim_purchase_at AS (
    SELECT 
        customer_unique_id
        , MIN(order_purchase_timestamp) AS first_purchase_at
        , MAX(order_purchase_timestamp) AS last_purchase_at
        , COUNT(DISTINCT order_id) AS total_orders
    FROM int_cus_orders
    GROUP BY 
        customer_unique_id
)
, cus_dim_fst_order AS (
    SELECT 
        customer_unique_id
        , order_id AS first_purchase_order_id
        , customer_city
        , customer_state
    FROM int_cus_orders
    QUALIFY ROW_NUMBER() OVER (PARTITION BY customer_unique_id ORDER BY order_purchase_timestamp) = 1
)
, cus_dim_payments AS (
    SELECT 
        order_id
        , payment_type
    FROM ord_payments AS base 
    QUALIFY ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY payment_value DESC) = 1
)
, cus_dim_add_attr AS (
    SELECT 
        customer_unique_id
        , DATE_TRUNC('month', first_purchase_at) AS first_purchase_month
        , first_purchase_at
        , last_purchase_at
        , total_orders
        , customer_city
        , customer_state
        , first_purchase_order_id
        , payment_type AS first_payment_type
        , CASE 
            WHEN total_orders = 1 AND DATEDIFF('day', last_purchase_at, grand_last_purchased_at) > 90 THEN 'One Time'
            WHEN DATEDIFF('day', last_purchase_at, grand_last_purchased_at) <= 30 THEN 'Active'
            WHEN DATEDIFF('day', last_purchase_at, grand_last_purchased_at) <= 90 THEN 'At Risk'
            ELSE 'Churned'
        END AS customer_status
    FROM cus_dim_base AS base 
    LEFT JOIN cus_dim_purchase_at
        USING(customer_unique_id)
    LEFT JOIN cus_dim_fst_order
        USING(customer_unique_id)
    LEFT JOIN cus_dim_payments
        ON cus_dim_fst_order.first_purchase_order_id = cus_dim_payments.order_id
    CROSS JOIN get_criteria
)

SELECT * FROM cus_dim_add_attr