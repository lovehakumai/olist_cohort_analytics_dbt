WITH 
fact_base AS (
    SELECT * 
    FROM {{ref('fct_customer_monthly_summary')}}
)
, dim_base AS (
    SELECT * 
    FROM {{ref('dim_customer_lifecycle')}}
)
, calender_my AS (
    SELECT 
        DATE_TRUNC("month", cl_date) AS year_month
    FROM {{ref('stg_COMMON_CALENDER')}}
    GROUP BY 
        DATE_TRUNC("month", cl_date)
)
, customer_unique_id_mst AS (
    SELECT
        customer_unique_id
    FROM dim_base
    GROUP BY 
        customer_unique_id
)
, date_spine AS (
    SELECT 
        customer_unique_id
        , year_month
    FROM customer_unique_id_mst
    CROSS JOIN calender_my
)
, fact_table_full AS (
    SELECT 
        date_spine.customer_unique_id
        , date_spine.year_month
        , COALESCE(fact_base.monthly_orders, 0) AS monthly_orders
        , COALESCE(fact_base.monthly_revenue, 0) AS monthly_revenue
        , DATEDIFF(month, dim_base.first_purchase_month, date_spine.year_month) AS months_after_fst_purchase
        , dim_base.first_purchase_month
        , dim_base.first_purchase_at
        , dim_base.last_purchase_at
        , dim_base.total_orders
        , dim_base.customer_city
        , dim_base.customer_state
        , dim_base.first_purchase_order_id
        , dim_base.first_payment_type
        , dim_base.customer_status
    FROM date_spine
    LEFT JOIN dim_base 
    ON date_spine.customer_unique_id = dim_base.customer_unique_id
    LEFT JOIN fact_base
    ON  date_spine.year_month = fact_base.order_purchase_month
        AND date_spine.customer_unique_id = fact_base.customer_unique_id
    WHERE 
        dim_base.first_purchase_month <= date_spine.year_month
        AND DATEDIFF(month, dim_base.first_purchase_month, date_spine.year_month) <= 24
)
SELECT * FROM fact_table_full