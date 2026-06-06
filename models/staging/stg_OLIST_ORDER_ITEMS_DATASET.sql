with source as (
    select * from {{ source('olist_raw', 'OLIST_ORDER_ITEMS_DATASET') }}
),
renamed as (
    select
        order_id,
        order_item_id,
        product_id,
        seller_id,
        shipping_limit_date,
        price,
        freight_value
    from source
)
select * from renamed