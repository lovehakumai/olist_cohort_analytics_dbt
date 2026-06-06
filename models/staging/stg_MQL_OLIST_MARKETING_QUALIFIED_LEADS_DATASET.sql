with source as (
    select * from {{ source('olist_raw', 'MQL_OLIST_MARKETING_QUALIFIED_LEADS_DATASET') }}
),
renamed as (
    select
        mql_id,
        TO_TIMESTAMP(first_contact_date) AS first_contact_date,
        landing_page_id,
        origin
    from source
)
select * from renamed