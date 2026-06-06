with source as (
    select * from {{ source('olist_raw', 'OLIST_ORDER_PAYMENTS_DATASET') }}
),
renamed as (
    select
        order_id,
        payment_sequential,
        payment_type,
        payment_installments,
        payment_value
    from source
)
select * from renamed