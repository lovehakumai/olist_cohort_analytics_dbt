with source as (
    select * from {{ source('common', 'CMN_CALENDER') }}
),
renamed as (
    select
        cl_year,
        cl_month,
        cl_day,
        cl_date
    from source
)
select * from renamed