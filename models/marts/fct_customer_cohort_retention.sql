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
;
{# , customer_cohort_retention AS (
    SELECT 
        first_purchase_month
        , months_after_first_purchase
        , COUNT(DISTINCT customer_unique_id) AS ucnt_retained
        , SUM(monthly_orders) AS order_cnt_retained
        , SUM(monthly_revenue) AS revenue_retained
    FROM customer_cohort_retention_raw
    GROUP BY 
        first_purchase_month
        , months_after_first_purchase
)
{# months_after_first_purchaseは実績ベースだと歯抜けになる可能性があるのでデータスパインを行う #}
, cohort_months_master AS (
    SELECT DISTINCT 
        first_purchase_month
    FROM dim_customer_lifecycle
    WHERE first_purchase_month IS NOT NULL
)
, lags_master AS (
    SELECT 
        {# ORDER BY NULL, テーブルは値なしの25行だけ生成されるので 順番指定ができないためNULLと記載する。 #}
        ROW_NUMBER() OVER (ORDER BY NULL) - 1 AS months_after_first_purchase
    FROM TABLE(GENERATOR(ROWCOUNT => 25))
)
, cohort_months_lags_master AS (
    SELECT 
        first_purchase_month
        , months_after_first_purchase
    FROM cohort_months_master
    CROSS JOIN lags_master
)
, cohort_retantion_spined AS (
    SELECT 
        first_purchase_month
        , months_after_first_purchase
        , NVL(ucnt_retained, 0) AS ucnt_retained
        , NVL(order_cnt_retained, 0) AS order_cnt_retained
        , NVL(revenue_retained, 0) AS revenue_retained
        {# FULL JOINだと実績ベースで範囲外(初月から25ヶ月)以上の月が現れる可能性があるため以下のJOIN #}
    FROM cohort_months_lags_master
    LEFT JOIN customer_cohort_retention
    USING ( first_purchase_month, months_after_first_purchase )
)
SELECT 
    * 
FROM cohort_retantion_spined 
ORDER BY 
    first_purchase_month
    , months_after_first_purchase #}