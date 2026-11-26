-- Pertanyaan 3a: Apakah keterlambatan pengiriman menurunkan review score?
-- Hanya order delivered yang punya tanggal terima dan punya review.
SELECT
    CASE
        WHEN days_vs_estimate <= -10 THEN '1. Lebih cepat >= 10 hari'
        WHEN days_vs_estimate <= -1  THEN '2. Lebih cepat 1-9 hari'
        WHEN days_vs_estimate = 0    THEN '3. Tepat di hari estimasi'
        WHEN days_vs_estimate <= 7   THEN '4. Telat 1-7 hari'
        ELSE                              '5. Telat > 7 hari'
    END                                                   AS delivery_bucket,
    COUNT(*)                                              AS orders,
    ROUND(AVG(review_score), 2)                           AS avg_review,
    ROUND(100.0 * AVG(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END), 1) AS low_review_pct
FROM fact_orders
WHERE order_status = 'delivered'
  AND in_analysis_period
  AND days_vs_estimate IS NOT NULL
  AND review_score IS NOT NULL
GROUP BY 1
ORDER BY 1;
