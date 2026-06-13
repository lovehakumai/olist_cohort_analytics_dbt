WITH 
cus_mst AS ( SELECT * FROM {{ ref('stg_OLIST_CUSTOMERS_DATASET') }})
, ord_mst AS ( SELECT * FROM {{ref('stg_OLIST_ORDERS_DATASET')}} )
, ord_payments AS (SELECT * FROM {{ref('stg_OLIST_ORDER_PAYMENTS_DATASET')}})
, cus_orders AS (
    {# Grain : customer_unique_id x order_id x order_purchase_timestamp #}
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
, order_payment AS (
    {# Get the records with the highest revenue so that order_id will be unique#}
    SELECT 
        order_id
        , payment_type 
    FROM ord_payments AS base 
    QUALIFY ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY payment_value DESC, payment_type ASC) = 1 
)
, cus_join_payments AS (
    SELECT 
        cus_orders.customer_unique_id
        , cus_orders.customer_city
        , cus_orders.customer_state
        , order_payment.payment_type AS main_payment_type
    FROM cus_orders 
    LEFT JOIN order_payment 
    ON cus_orders.order_id = order_payment.order_id
    {# Change Grain : customer_unique_id x orders_id to customer_unique_id by extracting the record with latest order_purchase_timestamp#}
    QUALIFY ROW_NUMBER() OVER (PARTITION BY cus_orders.customer_unique_id ORDER BY cus_orders.order_purchase_timestamp DESC) = 1
)
SELECT * FROM cus_join_payments
