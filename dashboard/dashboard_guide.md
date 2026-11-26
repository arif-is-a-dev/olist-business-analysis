# Panduan Membangun Dashboard Power BI

Target akhirnya: `dashboard/olist_dashboard.pbix` dengan 4 halaman, plus screenshot setiap halaman di `dashboard/screenshots/`.

---

## 0. Siapkan data

Dari folder utama project, jalankan:

```bash
pip install duckdb pandas
python scripts/load_to_db.py
python scripts/run_sql.py
```

Hasilnya adalah 6 file CSV di `data/model/`. File-file inilah yang di-import ke Power BI.

---

## 1. Import data

1. Buka Power BI Desktop, pilih **Get Data → Text/CSV**, lalu import keenam file dari `data/model/`.
2. Pilih **Transform Data**, bukan langsung Load.
3. **PENTING (laptop dengan locale Indonesia):** di CSV, titik dipakai sebagai pemisah desimal. Kalau tipe datanya diubah dengan cara biasa, angka `160.23` bisa terbaca sebagai 16023. Cara amannya: klik kanan header kolom angka, pilih **Change Type → Using Locale…**, lalu pilih Decimal Number dengan locale **English (United States)**. Lakukan untuk semua kolom desimal: `order_value`, `product_value`, `freight_value`, `payment_value`, `price`, `item_value`, `monetary`, `weight_g`.
4. Pastikan kolom `date`, `purchase_date`, `first_purchase_date`, `cohort_month`, `month_start` bertipe **Date**, dan kolom `is_...` bertipe **True/False**.
5. Close & Apply.

## 2. Relasi (Model view)

| Dari (many) | Ke (one) | Arah filter |
|---|---|---|
| fact_orders[purchase_date] | dim_date[date] | Single |
| fact_order_items[purchase_date] | dim_date[date] | Single |
| fact_orders[customer_unique_id] | dim_customer[customer_unique_id] | Single |
| fact_order_items[customer_unique_id] | dim_customer[customer_unique_id] | Single |
| fact_order_items[product_id] | dim_product[product_id] | Single |
| fact_order_items[seller_id] | dim_seller[seller_id] | Single |

Lalu tandai `dim_date` sebagai date table: klik kanan, pilih **Mark as date table**, kolom `date`.
Atur juga `dim_date[month_name]` supaya **Sort by column** memakai `month_number`.

## 3. Measures

Buat tabel kosong `_Measures`, lalu salin semua measure dari `measures.dax`. Setiap measure punya angka **Target** di komentarnya. Taruh beberapa measure di Card dan cocokkan angkanya dengan target. Kalau sudah sama, berarti model sudah benar.

## 4. Filter level report

Di panel Filters, bagian **Filters on all pages**, set `dim_date[in_analysis_period] = True`.

---

## 5. Halaman dashboard

Gaya: latar terang, satu warna utama (misalnya biru tua) ditambah satu warna aksen merah khusus untuk hal yang "buruk" (telat, review rendah). Judul setiap visual ditulis sebagai **kalimat insight**, bukan sekadar nama metrik. Contoh: "Order yang telat mendapat review 2 poin lebih rendah", bukan "Review by Delivery".

### Halaman 1 – Executive Overview
- **Card KPI (baris atas):** GMV, Total Orders, AOV, Total Customers, Avg Review Score, Late Delivery %
- **Line + column chart:** sumbu `dim_date[month_start]`, kolom = GMV, garis = Total Orders
  - Judul: *"GMV Jan–Agu 2018 2,4× periode yang sama 2017; puncak di Black Friday Nov 2017"*
- **Bar chart:** GMV per `fact_orders[customer_state]`, top 10
- **Slicer:** `dim_date[year]`

### Halaman 2 – Customer & Retention
- **Card:** Repeat Customer % (≈3%). Ini angka utama halaman ini.
- **Bar chart:** jumlah pelanggan dan Segment Spend per `dim_customer[rfm_segment]`
- **Tabel cohort:** paling gampang import `outputs/02_repeat_rate_and_cohort.csv` sebagai tabel tambahan (tanpa relasi), lalu tampilkan dengan **Matrix + conditional formatting (background color scale)**
- **Teks penjelas:** "97% pelanggan hanya belanja sekali; 30% dari 'pembelian kedua' terjadi di hari yang sama (kemungkinan order dipecah)"

### Halaman 3 – Logistics & Satisfaction
- **Card:** Avg Delivery Days, Late Delivery %, Avg Review (On Time), Avg Review (Late)
- **Column chart:** Avg Review Score per delivery bucket. Import `outputs/04_delivery_vs_review.csv`, atau buat kolom kalkulasi bucket dari `days_vs_estimate`.
- **Filled map / Shape map:** Late Delivery % per `customer_state`. Isi kategori data di Column tools dengan *State or Province*, karena kode negara bagian Brasil 2 huruf kadang perlu ditambah ", Brazil".
- **Scatter:** sumbu X Late Delivery %, sumbu Y Avg Review Score, titik per state

### Halaman 4 – Product & Seller
- **Pareto chart (line & clustered column):** sumbu `dim_product[category_name]` diurutkan berdasarkan Product Revenue; kolom = Product Revenue, garis = Category Cumulative %. Tambahkan constant line di 80%.
- **Tabel seller:** seller_id, Product Revenue, Total Orders, Avg Review Score, Late Delivery %, dengan conditional formatting
- **Card:** Active Sellers

---

## 6. (Opsional) Pakai AI untuk Power BI

Microsoft sudah merilis **Power BI Modeling MCP Server** (public preview). Dengan server ini, Claude Desktop atau GitHub Copilot di VS Code bisa langsung mengubah semantic model yang sedang terbuka di Power BI Desktop: menambah measure, mengatur relasi, mengganti nama kolom, dan menjalankan query DAX untuk validasi.

- Repo resmi: https://github.com/microsoft/powerbi-modeling-mcp (petunjuk instalasi ada di README-nya)
- Contoh pemakaian: buka file .pbix, lalu minta AI *"buat semua measure dari dashboard/measures.dax dan cocokkan hasilnya dengan target di komentar"*
- Batasan: server ini hanya mengurus **model**, bukan layout visual. Halaman dan chart tetap dibuat manual. Bagian visual ini justru bagus untuk kamu kuasai sendiri karena sering ditanya di interview.

Kalau mau project-nya lebih ramah Git dan AI, simpan sebagai **Power BI Project (.pbip)**: File, pilih Save As, lalu Power BI Project. Model akan tersimpan sebagai file teks (TMDL) yang bisa di-diff dan dibaca AI.

## 7. Selesai

- Export setiap halaman sebagai PNG ke `dashboard/screenshots/` (nama: `01_overview.png`, `02_customer.png`, `03_logistics.png`, `04_product_seller.png`)
- Export juga PDF (File → Export → PDF) ke `dashboard/olist_dashboard.pdf`
- Screenshot inilah yang ditampilkan di README
