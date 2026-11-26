-- Pertanyaan 1: Bagaimana tren GMV, jumlah order, dan AOV per bulan?
-- GMV = harga produk + ongkir dari order yang valid (bukan canceled/unavailable).
WITH per_bulan AS (
    SELECT
        CAST(date_trunc('month', purchase_date) AS DATE) AS month_start,
        COUNT(*)                                         AS orders,
        COUNT(DISTINCT customer_unique_id)               AS customers,
        SUM(order_value)                                 AS gmv
    FROM fact_orders
    WHERE is_valid_sale AND in_analysis_period
    GROUP BY 1
)
SELECT
    strftime(month_start, '%Y-%m')                   AS year_month,
    orders,
    customers,
    ROUND(gmv, 2)                                    AS gmv,
    ROUND(gmv / orders, 2)                           AS aov,
    ROUND(100.0 * (gmv / LAG(gmv) OVER (ORDER BY month_start) - 1), 1) AS gmv_mom_growth_pct
FROM per_bulan
ORDER BY month_start;
