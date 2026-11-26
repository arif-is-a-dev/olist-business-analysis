-- Pertanyaan 2: Berapa persen pelanggan yang kembali belanja?
-- Cohort = bulan pembelian pertama. Untuk setiap cohort, dihitung
-- persentase pelanggan yang belanja lagi di bulan ke-1, ke-3, ke-6
-- setelah bulan pertama, dan kapan pun dalam periode analisis.
WITH order_valid AS (
    SELECT f.customer_unique_id,
           CAST(date_trunc('month', f.purchase_date) AS DATE) AS order_month,
           d.cohort_month
    FROM fact_orders AS f
    JOIN dim_customer AS d USING (customer_unique_id)
    WHERE f.is_valid_sale AND f.in_analysis_period
),
selisih AS (
    SELECT DISTINCT
        customer_unique_id,
        cohort_month,
        date_diff('month', cohort_month, order_month) AS month_offset
    FROM order_valid
)
SELECT
    strftime(cohort_month, '%Y-%m')                                       AS cohort,
    COUNT(DISTINCT customer_unique_id)                                    AS cohort_size,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN month_offset = 1 THEN customer_unique_id END)
          / COUNT(DISTINCT customer_unique_id), 2)                        AS retained_m1_pct,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN month_offset = 3 THEN customer_unique_id END)
          / COUNT(DISTINCT customer_unique_id), 2)                        AS retained_m3_pct,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN month_offset = 6 THEN customer_unique_id END)
          / COUNT(DISTINCT customer_unique_id), 2)                        AS retained_m6_pct,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN month_offset >= 1 THEN customer_unique_id END)
          / COUNT(DISTINCT customer_unique_id), 2)                        AS ever_returned_pct
FROM selisih
GROUP BY cohort_month
ORDER BY cohort_month;
