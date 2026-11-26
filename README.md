# Olist E-commerce: Business Analysis & BI Dashboard

> **Pertanyaan bisnis:** Olist tumbuh pesat sepanjang 2017. Kenapa pertumbuhan itu tidak diikuti loyalitas pelanggan, dan apa yang bisa diperbaiki?

Proyek ini menganalisis ±98 ribu order dari marketplace Brasil Olist (Jan 2017 – Agu 2018) dengan alur kerja seorang Data Analyst: data mentah relasional dimuat ke database, dibersihkan dan dimodelkan sebagai **star schema dengan SQL**, dianalisis, lalu disajikan dalam **dashboard Power BI** dan **laporan insight** berisi rekomendasi.

<!-- Ganti dengan screenshot dashboard setelah jadi -->
<!-- ![Dashboard](dashboard/screenshots/01_overview.png) -->

## Temuan utama

| | Temuan |
|---|---|
| 📈 | GMV Jan–Agu 2018 = **2,4×** periode yang sama 2017, tapi mendatar sejak awal 2018 |
| 🔁 | Hanya **3,04%** pelanggan yang belanja lebih dari sekali; retensi bulan ke-1 < 1% di semua cohort |
| 🚚 | Review order tepat waktu **4,29** vs telat **2,27**. Order telat (6,7%) menyumbang **32,6%** review bintang 1–2 |
| 📍 | Rio de Janeiro: volume terbesar ke-2 dengan **12,1%** order telat, hampir 3× São Paulo |
| 🏷️ | 17 dari 74 kategori = ~80% revenue; 20% seller teratas = **82,5%** revenue |

Detail lengkap dan rekomendasi: **[report/insight_report.md](report/insight_report.md)**

## Tech stack

| Tahap | Tools |
|---|---|
| Load data | Python + DuckDB |
| Cleaning & modeling | SQL (CTE, window function, star schema) |
| Analisis | SQL: cohort retention, segmentasi RFM, Pareto, analisis keterlambatan |
| Visualisasi | Power BI (DAX measures), matplotlib untuk grafik laporan |

## Data model (star schema)

```
                 dim_date
                    │
dim_customer ── fact_orders            (1 baris = 1 order)
     │
     └──────── fact_order_items ── dim_product
                    │               (1 baris = 1 item)
                dim_seller
```

Keputusan cleaning penting:
- Pelanggan diidentifikasi dengan `customer_unique_id`. `customer_id` asli berbeda di setiap order, jadi kalau itu yang dipakai, semua pelanggan akan terlihat "baru".
- Order dengan lebih dari 1 review: diambil review terbaru.
- 610 produk tanpa kategori dimasukkan ke `unknown`; 13 kategori yang tidak punya terjemahan memakai nama aslinya.
- Order `canceled` dan `unavailable` tidak dihitung sebagai penjualan.
- Periode analisis dibatasi ke bulan yang datanya lengkap (Jan 2017 – Agu 2018).

## Struktur repo

```
├── scripts/
│   ├── load_to_db.py           # CSV → DuckDB
│   ├── run_sql.py              # jalankan semua SQL + simpan hasil analisis
│   └── make_charts.py          # grafik untuk laporan
├── sql/
│   ├── 01_staging.sql          # cleaning
│   ├── 02_star_schema.sql      # dim_ & fact_ + segmentasi RFM
│   ├── 03_export_for_powerbi.sql
│   └── 04_analysis/            # 8 query analisis (1 file = 1 pertanyaan)
├── outputs/                    # hasil query analisis (CSV)
├── dashboard/
│   ├── measures.dax            # semua DAX measure + angka target validasi
│   └── dashboard_guide.md      # langkah membangun dashboard
└── report/
    ├── insight_report.md
    └── figures/
```

## Cara menjalankan

1. Download dataset dari [Kaggle – Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce), lalu taruh semua CSV di `data/raw/`
2. Jalankan:
   ```bash
   pip install -r requirements.txt
   python scripts/load_to_db.py
   python scripts/run_sql.py
   python scripts/make_charts.py
   ```
3. Import CSV di `data/model/` ke Power BI. Ikuti [dashboard/dashboard_guide.md](dashboard/dashboard_guide.md).

## Lisensi data

Dataset dirilis Olist di Kaggle dengan lisensi CC BY-NC-SA 4.0.
