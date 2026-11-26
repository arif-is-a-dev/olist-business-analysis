-- Pertanyaan 4b: Seberapa terkonsentrasi revenue di seller, dan bagaimana
-- kualitas seller di tiap kelompok?
-- Seller dikelompokkan ke 5 kelompok (kuintil) berdasarkan revenue.
WITH per_seller AS (
    SELECT
        seller_id,
        COUNT(DISTINCT order_id)                                AS orders,
        SUM(price)                                              AS revenue,
        AVG(review_score)                                       AS avg_review,
        AVG(CASE WHEN is_late THEN 1.0 WHEN is_late = false THEN 0.0 END) AS late_rate
    FROM fact_order_items
    WHERE is_valid_sale AND in_analysis_period
    GROUP BY seller_id
),
berkelompok AS (
    SELECT *, NTILE(5) OVER (ORDER BY revenue DESC) AS revenue_quintile
    FROM per_seller
)
SELECT
    'Q' || revenue_quintile || CASE WHEN revenue_quintile = 1 THEN ' (top 20%)'
                                    WHEN revenue_quintile = 5 THEN ' (bottom 20%)'
                                    ELSE '' END            AS seller_group,
    COUNT(*)                                              AS sellers,
    ROUND(SUM(revenue), 2)                                AS revenue,
    ROUND(100.0 * SUM(revenue) / SUM(SUM(revenue)) OVER (), 1) AS revenue_pct,
    ROUND(AVG(orders), 1)                                 AS avg_orders_per_seller,
    ROUND(AVG(avg_review), 2)                             AS avg_review,
    ROUND(100.0 * AVG(late_rate), 1)                      AS avg_late_pct
FROM berkelompok
GROUP BY revenue_quintile
ORDER BY revenue_quintile;
