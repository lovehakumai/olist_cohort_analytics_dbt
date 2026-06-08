WITH 
fct_customer_monthly_summary AS (
    SELECT * 
    FROM {{ref('fct_customer_monthly_summary')}}
)
, dim_customer_lifecycle AS (
    SELECT * 
    FROM {{ref('dim_customer_lifecycle')}}
)
, customer_cohort_retention_raw AS (
    SELECT 
        customer_unique_id
        {# fact要素 #}
        , order_purchase_month
        , monthly_orders
        , monthly_revenue
        {# dimension要素 #}
        , first_purchase_month
        , first_purchase_at
        , last_purchase_at
        , total_orders
        , customer_city
        , customer_state
        , first_payment_type
        , customer_status
        {# 初回から何ヶ月目の購入かを示すカラムを作成 #}
        , DATEDIFF('month', first_purchase_month, order_purchase_month) AS months_after_first_purchase
    FROM fct_customer_monthly_summary
    LEFT JOIN dim_customer_lifecycle
        USING(customer_unique_id)
)
SELECT * FROM customer_cohort_retention_raw