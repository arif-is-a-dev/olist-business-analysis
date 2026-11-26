-- Pertanyaan 3b: Di negara bagian mana keterlambatan paling parah?
-- Minimal 500 order supaya persentasenya stabil.
SELECT
    customer_state,
    COUNT(*)                                          AS delivered_orders,
    ROUND(AVG(delivery_days), 1)                      AS avg_delivery_days,
    ROUND(100.0 * AVG(CASE WHEN is_late THEN 1 ELSE 0 END), 1) AS late_pct,
    ROUND(AVG(review_score), 2)                       AS avg_review
FROM fact_orders
WHERE order_status = 'delivered'
  AND in_analysis_period
  AND is_late IS NOT NULL
GROUP BY customer_state
HAVING COUNT(*) >= 500
ORDER BY late_pct DESC;
