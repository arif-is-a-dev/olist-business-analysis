-- Pertanyaan 4a: Kategori mana yang menyumbang paling banyak revenue?
-- Kolom cumulative_pct dipakai untuk melihat pola Pareto (80/20).
WITH per_kategori AS (
    SELECT
        p.category_name,
        COUNT(DISTINCT i.order_id)   AS orders,
        SUM(i.price)                 AS revenue,
        ROUND(AVG(i.review_score), 2) AS avg_review
    FROM fact_order_items AS i
    JOIN dim_product      AS p USING (product_id)
    WHERE i.is_valid_sale AND i.in_analysis_period
    GROUP BY p.category_name
)
SELECT
    ROW_NUMBER() OVER (ORDER BY revenue DESC)                     AS rank,
    category_name,
    orders,
    ROUND(revenue, 2)                                             AS revenue,
    ROUND(100.0 * revenue / SUM(revenue) OVER (), 2)              AS revenue_pct,
    ROUND(100.0 * SUM(revenue) OVER (ORDER BY revenue DESC)
          / SUM(revenue) OVER (), 2)                              AS cumulative_pct,
    avg_review
FROM per_kategori
ORDER BY revenue DESC;
