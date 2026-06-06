with source as (
    select * from {{ source('olist_raw', 'PRODUCT_CATEGORY_NAME_TRANSLATION') }}
),
renamed as (
    select
        product_category_name,
        product_category_name_english
    from source
)
select * from renamed