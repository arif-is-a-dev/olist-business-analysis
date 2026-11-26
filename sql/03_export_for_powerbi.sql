-- =====================================================================
-- 03_export_for_powerbi.sql
-- Ekspor tabel star schema ke CSV di folder data/model/.
-- File-file ini yang di-import ke Power BI (Get Data > Text/CSV).
-- Path relatif terhadap folder utama project.
-- =====================================================================

COPY dim_date         TO 'data/model/dim_date.csv'         (HEADER, DELIMITER ',');
COPY dim_customer     TO 'data/model/dim_customer.csv'     (HEADER, DELIMITER ',');
COPY dim_product      TO 'data/model/dim_product.csv'      (HEADER, DELIMITER ',');
COPY dim_seller       TO 'data/model/dim_seller.csv'       (HEADER, DELIMITER ',');
COPY fact_orders      TO 'data/model/fact_orders.csv'      (HEADER, DELIMITER ',');
COPY fact_order_items TO 'data/model/fact_order_items.csv' (HEADER, DELIMITER ',');
