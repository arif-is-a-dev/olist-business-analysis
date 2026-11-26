-- Pertanyaan 5: Seperti apa komposisi segmen pelanggan (RFM)?
SELECT
    rfm_segment,
    COUNT(*)                                              AS customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)    AS customers_pct,
    ROUND(SUM(monetary), 2)                               AS total_spend,
    ROUND(100.0 * SUM(monetary) / SUM(SUM(monetary)) OVER (), 1) AS spend_pct,
    ROUND(AVG(monetary), 2)                               AS avg_spend,
    ROUND(AVG(recency_days), 0)                           AS avg_recency_days
FROM dim_customer
WHERE rfm_segment <> 'Di luar periode'
GROUP BY rfm_segment
ORDER BY total_spend DESC;
