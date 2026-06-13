WITH
int_fst_payment AS (SELECT * FROM {{ref('dim_customers__first_payment')}})
, int_purchase_summary AS (SELECT * FROM {{ref('dim_customers__purchase_summary')}})

{# Test : validate if both views have same customer_unique_id #}

SELECT 
    *
FROM int_fst_payment
FULL JOIN int_purchase_summary
USING(customer_unique_id)
WHERE 
    int_fst_payment.customer_unique_id IS NULL 
    OR int_purchase_summary.customer_unique_id IS NULL 

