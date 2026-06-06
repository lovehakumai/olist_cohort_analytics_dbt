with source as (
    select * from {{ source('olist_raw', 'OLIST_ORDERS_DATASET') }}
),
renamed as (
    select
        order_id,
        customer_id,
        order_status,
        TO_TIMESTAMP(order_purchase_timestamp) order_purchase_timestamp,
        TO_TIMESTAMP(order_approved_at) order_approved_at,
        TO_TIMESTAMP(order_delivered_carrier_date) AS order_delivered_carrier_date,
        TO_TIMESTAMP(order_delivered_customer_date) AS order_delivered_customer_date,
        TO_TIMESTAMP(order_estimated_delivery_date) AS order_estimated_delivery_date
    from source
)
select * from renamed