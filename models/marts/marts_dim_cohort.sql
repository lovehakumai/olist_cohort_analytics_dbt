WITH 
int_cus_first_payment AS (SELECT * FROM {{ref('dim_customers__first_payment')}})
, int_cus_purchase_summary AS ( SELECT * FROM {{ref('dim_customers__purchase_summary')}})
, result_mart AS (
    SELECT 
        customer_unique_id
        , first_purchase_month
        , first_purchase_at
        , last_purchase_month
        , last_purchase_at
        , customer_city
        , customer_state
        , first_purchase_order_id
        , customer_status
        , total_orders
    FROM int_cus_first_payment
    LEFT JOIN int_cus_purchase_summary
    USING(customer_unique_id)
)
SELECT * FROM result_mart