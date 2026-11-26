-- =====================================================================
-- 02_star_schema.sql
-- Membangun model star schema untuk Power BI.
--
--   dim_date ─┐
--   dim_customer ─┼── fact_orders        (1 baris = 1 order)
--               └── fact_order_items   (1 baris = 1 item dalam order)
--   dim_product ──── fact_order_items
--   dim_seller  ──── fact_order_items
--
-- Periode analisis: 2017-01-01 s/d 2018-08-31 (bulan yang datanya lengkap).
-- Data 2016 dan Sep–Okt 2018 sangat sedikit, jadi ditandai di luar periode.
-- =====================================================================


-- ---------------------------------------------------------------------
-- dim_date : satu baris per tanggal
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE dim_date AS
SELECT
    CAST(tanggal AS DATE)                          AS date,
    year(tanggal)                                  AS year,
    quarter(tanggal)                               AS quarter,
    month(tanggal)                                 AS month_number,
    strftime(tanggal, '%b')                        AS month_name,
    strftime(tanggal, '%Y-%m')                     AS year_month,
    CAST(date_trunc('month', tanggal) AS DATE)     AS month_start,
    isodow(tanggal)                                AS weekday_number,   -- 1 = Senin
    strftime(tanggal, '%a')                        AS weekday_name,
    tanggal BETWEEN DATE '2017-01-01' AND DATE '2018-08-31' AS in_analysis_period
FROM range(DATE '2016-09-01', DATE '2018-11-01', INTERVAL 1 DAY) AS t(tanggal);


-- ---------------------------------------------------------------------
-- dim_product
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE dim_product AS
SELECT product_id, category_name, category_name_pt, photos_qty, weight_g
FROM stg_products;


-- ---------------------------------------------------------------------
-- dim_seller
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE dim_seller AS
SELECT seller_id, seller_city, seller_state
FROM stg_sellers;


-- ---------------------------------------------------------------------
-- fact_orders : 1 baris = 1 order
-- Pelanggan memakai customer_unique_id (orang yang sebenarnya).
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE fact_orders AS
WITH ringkasan_item AS (
    SELECT
        order_id,
        COUNT(*)                 AS items_count,
        COUNT(DISTINCT seller_id) AS sellers_count,
        SUM(price)               AS product_value,
        SUM(freight_value)       AS freight_value
    FROM stg_order_items
    GROUP BY order_id
)
SELECT
    o.order_id,
    c.customer_unique_id,
    o.purchase_date,
    o.order_status,
    o.is_valid_sale,
    o.purchase_date BETWEEN DATE '2017-01-01' AND DATE '2018-08-31' AS in_analysis_period,
    c.customer_state,
    COALESCE(i.items_count, 0)                         AS items_count,
    COALESCE(i.product_value, 0)                       AS product_value,
    COALESCE(i.freight_value, 0)                       AS freight_value,
    COALESCE(i.product_value, 0) + COALESCE(i.freight_value, 0) AS order_value,
    p.payment_value,
    p.main_payment_type,
    p.max_installments,
    o.delivery_days,
    o.days_vs_estimate,
    o.is_late,
    r.review_score,
    r.has_comment
FROM stg_orders            AS o
JOIN stg_customers         AS c ON o.customer_id = c.customer_id
LEFT JOIN ringkasan_item   AS i ON o.order_id = i.order_id
LEFT JOIN stg_order_payments AS p ON o.order_id = p.order_id
LEFT JOIN stg_order_reviews  AS r ON o.order_id = r.order_id;


-- ---------------------------------------------------------------------
-- fact_order_items : 1 baris = 1 item
-- Membawa beberapa atribut order (tanggal, status, telat, review)
-- supaya analisis kategori & seller tidak perlu join ke fact_orders.
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE fact_order_items AS
SELECT
    i.order_id,
    i.order_item_id,
    f.customer_unique_id,
    f.purchase_date,
    f.is_valid_sale,
    f.in_analysis_period,
    i.product_id,
    i.seller_id,
    i.price,
    i.freight_value,
    i.price + i.freight_value AS item_value,
    f.is_late,
    f.review_score
FROM stg_order_items AS i
JOIN fact_orders     AS f ON i.order_id = f.order_id;


-- ---------------------------------------------------------------------
-- dim_customer : 1 baris = 1 pelanggan unik, lengkap dengan segmen RFM
--
-- RFM dihitung dari penjualan valid di periode analisis.
-- Tanggal acuan = 2018-09-01 (sehari setelah periode berakhir).
-- Karena ±97% pelanggan hanya belanja sekali, skor kuintil F tidak
-- berguna. Jadi segmen dibuat dengan aturan bisnis sederhana:
--   Loyal Aktif      : >= 2 order, terakhir belanja <= 180 hari
--   Loyal Tertidur   : >= 2 order, terakhir belanja  > 180 hari
--   Baru             : 1 order, <= 90 hari
--   Potensial Tinggi : 1 order, 91–270 hari, nilai belanja >= persentil 75
--   Perlu Diaktifkan : 1 order, 91–270 hari, nilai belanja < persentil 75
--   Hilang           : 1 order, > 270 hari
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE dim_customer AS
WITH order_valid AS (
    SELECT *
    FROM fact_orders
    WHERE is_valid_sale AND in_analysis_period
),
rfm_dasar AS (
    SELECT
        customer_unique_id,
        MIN(purchase_date)                                   AS first_purchase_date,
        MAX(purchase_date)                                   AS last_purchase_date,
        date_diff('day', MAX(purchase_date), DATE '2018-09-01') AS recency_days,
        COUNT(*)                                             AS frequency,
        SUM(order_value)                                     AS monetary
    FROM order_valid
    GROUP BY customer_unique_id
),
batas_nilai AS (
    SELECT quantile_cont(monetary, 0.75) AS p75_monetary FROM rfm_dasar
),
-- Lokasi pelanggan diambil dari order PERTAMA-nya
lokasi_pertama AS (
    SELECT
        f.customer_unique_id,
        arg_min(f.customer_state, f.purchase_date) AS customer_state
    FROM fact_orders AS f
    GROUP BY f.customer_unique_id
)
SELECT
    l.customer_unique_id,
    l.customer_state,
    r.first_purchase_date,
    CAST(date_trunc('month', r.first_purchase_date) AS DATE) AS cohort_month,
    r.last_purchase_date,
    r.recency_days,
    COALESCE(r.frequency, 0)  AS frequency,
    COALESCE(r.monetary, 0)   AS monetary,
    COALESCE(r.frequency, 0) >= 2 AS is_repeat_customer,
    CASE
        WHEN r.customer_unique_id IS NULL                     THEN 'Di luar periode'
        WHEN r.frequency >= 2 AND r.recency_days <= 180       THEN 'Loyal Aktif'
        WHEN r.frequency >= 2                                 THEN 'Loyal Tertidur'
        WHEN r.recency_days <= 90                             THEN 'Baru'
        WHEN r.recency_days <= 270 AND r.monetary >= b.p75_monetary THEN 'Potensial Tinggi'
        WHEN r.recency_days <= 270                            THEN 'Perlu Diaktifkan'
        ELSE 'Hilang'
    END AS rfm_segment
FROM lokasi_pertama AS l
LEFT JOIN rfm_dasar AS r ON l.customer_unique_id = r.customer_unique_id
CROSS JOIN batas_nilai AS b;
