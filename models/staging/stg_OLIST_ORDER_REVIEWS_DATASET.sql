with source as (
    select * from {{ source('olist_raw', 'OLIST_ORDER_REVIEWS_DATASET') }}
),
renamed as (
    select
        review_id,
        order_id,
        review_score,
        review_comment_title,
        review_comment_message,
        TO_TIMESTAMP(review_creation_date) AS review_creation_date,
        TO_TIMESTAMP(review_answer_timestamp) AS review_answer_timestamp
    from source
)
select * from renamed