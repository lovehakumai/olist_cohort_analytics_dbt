WITH 
cus_mst AS ( SELECT * FROM {{ ref('stg_OLIST_CUSTOMERS_DATASET') }})
, ord_mst AS ( SELECT * FROM {{ ref('stg_OLIST_ORDERS_DATASET') }} )
, ord_payments AS (SELECT * FROM {{ref('stg_OLIST_ORDER_PAYMENTS_DATASET')}})

, get_criteria AS (
    {# last purchased date in whole data #}
    SELECT 
        MAX(order_purchase_timestamp) AS grand_last_purchased_at
    FROM ord_mst 
)
, cus_mst_2 AS (
    SELECT 
        customer_unique_id
    FROM cus_mst
    GROUP BY 
        customer_unique_id
)
, cus_orders AS (
    SELECT 
        customer_unique_id
        , order_id
        , order_purchase_timestamp
    FROM cus_mst 
    LEFT JOIN ord_mst
    USING(customer_id)
)
, cus_purchase_at AS (
    SELECT 
        customer_unique_id
        , MIN(order_purchase_timestamp) AS first_purchase_at
        , MAX(order_purchase_timestamp) AS last_purchase_at
        , COUNT(DISTINCT order_id) AS total_orders
    FROM cus_orders
    GROUP BY 
        customer_unique_id
)
, cus_first_orders AS (
    SELECT 
        customer_unique_id
        , order_id AS first_purchase_order_id
        , DATE_TRUNC('month', order_purchase_timestamp) AS order_first_purchase_month
    FROM cus_orders
    QUALIFY ROW_NUMBER()OVER(PARTITION BY customer_unique_id ORDER BY order_purchase_timestamp) = 1
)
, cus_dim_add_attr AS (
    SELECT 
        customer_unique_id
        , DATE_TRUNC('month', first_purchase_at) AS first_purchase_month
        , first_purchase_at
        , DATE_TRUNC('month', last_purchase_at) AS last_purchase_month
        , last_purchase_at
        , total_orders
        , first_purchase_order_id
        , CASE 
            WHEN total_orders = 1 AND DATEDIFF('day', last_purchase_at, grand_last_purchased_at) > 90 THEN 'One Time'
            WHEN DATEDIFF('day', last_purchase_at, grand_last_purchased_at) <= 60 THEN 'Active'
            WHEN DATEDIFF('day', last_purchase_at, grand_last_purchased_at) <= 100 THEN 'At Risk'
            ELSE 'Churned'
        END AS customer_status
    FROM cus_mst_2
    LEFT JOIN cus_purchase_at
    USING(customer_unique_id)
    LEFT JOIN cus_first_orders
    USING(customer_unique_id)
    CROSS JOIN get_criteria

)

SELECT * FROM cus_dim_add_attr