with source as (
    select * from {{ source('olist_raw', 'OLIST_MARKETING_QUALIFIED_LEADS_DATASET') }}
),
renamed as (
    select
        mql_id,
        first_contact_date,
        landing_page_id,
        origin
    from source
)
select * from renamed