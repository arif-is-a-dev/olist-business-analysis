-- Ringkasan KPI utama periode analisis (Jan 2017 - Agu 2018)
SELECT
    COUNT(*)                                        AS total_orders,
    COUNT(DISTINCT customer_unique_id)              AS total_customers,
    ROUND(SUM(order_value), 2)                      AS total_gmv,
    ROUND(SUM(order_value) / COUNT(*), 2)           AS aov,
    ROUND(100.0 * SUM(freight_value) / SUM(order_value), 1) AS freight_share_pct,
    ROUND(AVG(review_score), 2)                     AS avg_review,
    ROUND(100.0 * AVG(CASE WHEN is_late THEN 1.0 WHEN is_late = false THEN 0.0 END), 1) AS late_delivery_pct,
    ROUND(AVG(delivery_days), 1)                    AS avg_delivery_days,
    (SELECT ROUND(100.0 * AVG(CASE WHEN is_repeat_customer THEN 1 ELSE 0 END), 2)
       FROM dim_customer WHERE rfm_segment <> 'Di luar periode') AS repeat_customer_pct
FROM fact_orders
WHERE is_valid_sale AND in_analysis_period;
