WITH
cus_mst AS ( SELECT * FROM {{ ref('stg_OLIST_CUSTOMERS_DATASET') }})
, ord_amt AS (SELECT *FROM {{ ref('stg_OLIST_ORDER_PAYMENTS_DATASET') }})

, ord_mst AS ( 
    SELECT 
        *
        , DATE_TRUNC('month', order_purchase_timestamp) AS order_purchase_month
    FROM {{ ref('stg_OLIST_ORDERS_DATASET') }} 
)
, ord_amt_agg AS (
    SELECT 
        order_id
        , SUM(payment_value) AS order_amount
    FROM ord_amt 
    GROUP BY 
        order_id
)
, fact_result AS (
    SELECT 
        customer_unique_id
        , order_purchase_month
        , COUNT(DISTINCT order_id) AS monthly_orders
        , SUM(order_amount) AS monthly_revenue
    FROM cus_mst 
    LEFT JOIN ord_mst
        USING(customer_id)
    LEFT JOIN ord_amt_agg
        USING(order_id)
    GROUP BY 
        customer_unique_id
        , order_purchase_month
)
SELECT * FROM fact_result