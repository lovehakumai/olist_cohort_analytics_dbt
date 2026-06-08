WITH 
fact_base AS (
    SELECT * 
    FROM {{ref('fct_customer_retention_raw')}}
)
, calender AS (
    SELECT 
        DATE_TRUNC("month", cl_date) AS year_month
    FROM {{ref('stg_COMMON_CALENDER')}}
    GROUP BY 
        DATE_TRUNC("month", cl_date)
)
, tmp_fact_full AS (
    SELECT 
        NVL(customer_unique_id, NULL) AS customer_unique_id
        , NVL(order_purchase_month, cal.year_month) AS year_month
        , NVL(monthly_orders, NULL) AS monthly_orders
        , NVL(monthly_revenue, NULL) AS monthly_revenue
        {# dimension要素 #}
        , NVL(first_purchase_month, NULL) AS first_purchase_month
        , NVL(first_purchase_at, NULL) AS first_purchase_at
        , NVL(last_purchase_at, NULL) AS last_purchase_at
        , NVL(total_orders, NULL) AS total_orders
        , NVL(customer_city, NULL) AS customer_city
        , NVL(customer_state, NULL) AS customer_state
        , NVL(first_payment_type, NULL) AS first_payment_type
        , NVL(customer_status, NULL) AS customer_status
    FROM fact_base AS base 
    FULL JOIN calender AS cal 
        ON base.order_purchase_month = cal.year_month 
)
SELECT * FROM tmp_fact_full
{# , customer_cohort_retention AS ( #}
    {# SELECT  #}
        {# first_purchase_month #}
        {# , months_after_first_purchase #}
        {# , COUNT(DISTINCT customer_unique_id) AS ucnt_retained #}
        {# , SUM(monthly_orders) AS order_cnt_retained #}
        {# , SUM(monthly_revenue) AS revenue_retained #}
    {# FROM customer_cohort_retention_raw #}
    {# GROUP BY  #}
        {# first_purchase_month #}
        {# , months_after_first_purchase #}
{# ) #}
{# months_after_first_purchaseは実績ベースだと歯抜けになる可能性があるのでデータスパインを行う #}
{# , cohort_months_master AS ( #}
    {# SELECT DISTINCT  #}
        {# first_purchase_month #}
    {# FROM dim_customer_lifecycle #}
    {# WHERE first_purchase_month IS NOT NULL #}
{# ) #}
{# , lags_master AS ( #}
    {# SELECT  #}
        {# ORDER BY NULL, テーブルは値なしの25行だけ生成されるので 順番指定ができないためNULLと記載する。 #}
        {# ROW_NUMBER() OVER (ORDER BY NULL) - 1 AS months_after_first_purchase
    FROM TABLE(GENERATOR(ROWCOUNT => 25)) #}
{# ) #}
{# , cohort_months_lags_master AS ( #}
    {# SELECT  #}
        {# first_purchase_month #}
        {# , months_after_first_purchase #}
    {# FROM cohort_months_master #}
    {# CROSS JOIN lags_master #}
{# ) #}
{# , cohort_retantion_spined AS ( #}
    {# SELECT  #}
        {# first_purchase_month #}
        {# , months_after_first_purchase #}
        {# , NVL(ucnt_retained, 0) AS ucnt_retained #}
        {# , NVL(order_cnt_retained, 0) AS order_cnt_retained #}
        {# , NVL(revenue_retained, 0) AS revenue_retained #}
        {# FULL JOINだと実績ベースで範囲外(初月から25ヶ月)以上の月が現れる可能性があるため以下のJOIN #}
    {# FROM cohort_months_lags_master #}
    {# LEFT JOIN customer_cohort_retention #}
    {# USING ( first_purchase_month, months_after_first_purchase ) #}
{# ) #}
{# SELECT  #}
    {# *  #}
{# FROM cohort_retantion_spined  #}
{# ORDER BY  #}
    {# first_purchase_month #}
    {# , months_after_first_purchase #}