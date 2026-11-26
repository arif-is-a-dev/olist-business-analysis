-- =====================================================================
-- 01_staging.sql
-- Membersihkan tabel raw_ menjadi tabel stg_ (staging) yang siap dipakai.
-- Setiap blok menjelaskan masalah data yang diperbaiki.
-- =====================================================================


-- ---------------------------------------------------------------------
-- stg_orders
-- * Tambah kolom tanggal (tanpa jam) untuk relasi ke dim_date
-- * Hitung lama pengiriman & selisih dengan estimasi (hanya order delivered)
-- * Flag is_valid_sale: order canceled/unavailable tidak dihitung sebagai
--   penjualan
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE stg_orders AS
SELECT
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    CAST(order_purchase_timestamp AS DATE)        AS purchase_date,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    CAST(order_estimated_delivery_date AS DATE)   AS estimated_delivery_date,

    -- Lama pengiriman (hari) dari pembelian sampai diterima pelanggan
    CASE
        WHEN order_status = 'delivered' AND order_delivered_customer_date IS NOT NULL
        THEN date_diff('day', CAST(order_purchase_timestamp AS DATE),
                              CAST(order_delivered_customer_date AS DATE))
    END AS delivery_days,

    -- Selisih hari: positif = telat dari estimasi, negatif = lebih cepat
    CASE
        WHEN order_status = 'delivered' AND order_delivered_customer_date IS NOT NULL
        THEN date_diff('day', CAST(order_estimated_delivery_date AS DATE),
                              CAST(order_delivered_customer_date AS DATE))
    END AS days_vs_estimate,

    CASE
        WHEN order_status = 'delivered' AND order_delivered_customer_date IS NOT NULL
        THEN CAST(order_delivered_customer_date AS DATE)
             > CAST(order_estimated_delivery_date AS DATE)
    END AS is_late,

    order_status NOT IN ('canceled', 'unavailable') AS is_valid_sale
FROM raw_orders;


-- ---------------------------------------------------------------------
-- stg_customers
-- customer_id di Olist berbeda untuk SETIAP order. Orang yang sama
-- dikenali lewat customer_unique_id. Ini penting untuk analisis repeat.
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE stg_customers AS
SELECT
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    lower(trim(customer_city))  AS customer_city,
    upper(trim(customer_state)) AS customer_state
FROM raw_customers;


-- ---------------------------------------------------------------------
-- stg_products
-- * 610 produk tanpa kategori -> 'unknown'
-- * 13 produk kategorinya tidak ada di tabel terjemahan -> pakai nama asli
-- * Perbaiki typo nama kolom asli ("lenght")
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE stg_products AS
SELECT
    p.product_id,
    COALESCE(p.product_category_name, 'unknown')           AS category_name_pt,
    COALESCE(t.product_category_name_english,
             p.product_category_name, 'unknown')           AS category_name,
    p.product_photos_qty                                    AS photos_qty,
    p.product_weight_g                                      AS weight_g
FROM raw_products AS p
LEFT JOIN raw_category_translation AS t
       ON p.product_category_name = t.product_category_name;


-- ---------------------------------------------------------------------
-- stg_sellers
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE stg_sellers AS
SELECT
    seller_id,
    seller_zip_code_prefix,
    lower(trim(seller_city))  AS seller_city,
    upper(trim(seller_state)) AS seller_state
FROM raw_sellers;


-- ---------------------------------------------------------------------
-- stg_order_items
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE stg_order_items AS
SELECT
    order_id,
    order_item_id,
    product_id,
    seller_id,
    price,
    freight_value
FROM raw_order_items;


-- ---------------------------------------------------------------------
-- stg_order_reviews
-- Beberapa order punya lebih dari 1 review. Kita ambil review TERBARU
-- per order supaya 1 order = 1 skor.
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE stg_order_reviews AS
SELECT
    order_id,
    review_score,
    review_comment_message IS NOT NULL AS has_comment
FROM (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY order_id
            ORDER BY review_answer_timestamp DESC, review_creation_date DESC
        ) AS urutan
    FROM raw_order_reviews
)
WHERE urutan = 1;


-- ---------------------------------------------------------------------
-- stg_order_payments (diringkas per order)
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE stg_order_payments AS
SELECT
    order_id,
    SUM(payment_value)                      AS payment_value,
    MAX(payment_installments)               AS max_installments,
    -- Metode bayar utama = metode dengan nilai bayar terbesar
    arg_max(payment_type, payment_value)    AS main_payment_type
FROM raw_order_payments
GROUP BY order_id;
