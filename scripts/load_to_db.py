"""
load_to_db.py
-------------
Langkah 1 project P2: memasukkan semua file CSV Olist ke database DuckDB.

Cara pakai (dari folder utama project):
    python scripts/load_to_db.py

Hasilnya: file database "olist.duckdb" di folder utama project.
Setiap CSV jadi satu tabel dengan awalan "raw_" (contoh: raw_orders).
"""

import os
import duckdb


# ------------------------------------------------------------
# 1. Tentukan lokasi folder dan file
# ------------------------------------------------------------
# Folder tempat script ini berada (folder "scripts")
folder_script = os.path.dirname(os.path.abspath(__file__))

# Folder utama project = satu tingkat di atas folder "scripts"
folder_project = os.path.dirname(folder_script)

# Folder tempat CSV mentah disimpan
folder_data_mentah = os.path.join(folder_project, "data", "raw")

# Lokasi file database DuckDB yang akan dibuat
lokasi_database = os.path.join(folder_project, "olist.duckdb")


# ------------------------------------------------------------
# 2. Daftar file CSV dan nama tabel tujuannya
# ------------------------------------------------------------
# Kiri: nama file CSV, kanan: nama tabel di database
daftar_file_dan_tabel = {
    "olist_customers_dataset.csv": "raw_customers",
    "olist_geolocation_dataset.csv": "raw_geolocation",
    "olist_order_items_dataset.csv": "raw_order_items",
    "olist_order_payments_dataset.csv": "raw_order_payments",
    "olist_order_reviews_dataset.csv": "raw_order_reviews",
    "olist_orders_dataset.csv": "raw_orders",
    "olist_products_dataset.csv": "raw_products",
    "olist_sellers_dataset.csv": "raw_sellers",
    "product_category_name_translation.csv": "raw_category_translation",
}


# Kolom kode pos yang harus dibaca sebagai teks (supaya angka 0 di depan
# tidak hilang, contoh "01037" jangan jadi 1037).
# Tabel yang tidak punya kolom kode pos tidak perlu dicantumkan.
kolom_kode_pos_per_file = {
    "olist_customers_dataset.csv": "customer_zip_code_prefix",
    "olist_geolocation_dataset.csv": "geolocation_zip_code_prefix",
    "olist_sellers_dataset.csv": "seller_zip_code_prefix",
}


# ------------------------------------------------------------
# 3. Buka koneksi ke database
# ------------------------------------------------------------
# Kalau file database belum ada, DuckDB otomatis membuatnya
koneksi_database = duckdb.connect(lokasi_database)
print("Terhubung ke database:", lokasi_database)


# ------------------------------------------------------------
# 4. Load setiap CSV menjadi tabel
# ------------------------------------------------------------
for nama_file_csv, nama_tabel in daftar_file_dan_tabel.items():

    lokasi_file_csv = os.path.join(folder_data_mentah, nama_file_csv)

    # Cek dulu apakah file CSV-nya ada
    if not os.path.exists(lokasi_file_csv):
        print("PERINGATAN: file tidak ditemukan ->", lokasi_file_csv)
        continue

    # Ganti tanda "\" (Windows) jadi "/" supaya aman dipakai di SQL
    lokasi_file_untuk_sql = lokasi_file_csv.replace("\\", "/")

    # Siapkan pengaturan tipe kolom kode pos (kalau file ini punya)
    if nama_file_csv in kolom_kode_pos_per_file:
        nama_kolom_kode_pos = kolom_kode_pos_per_file[nama_file_csv]
        pengaturan_tipe = f", types = {{'{nama_kolom_kode_pos}': 'VARCHAR'}}"
    else:
        pengaturan_tipe = ""

    # Buat ulang tabel dari CSV.
    # DuckDB otomatis menebak tipe data (angka, tanggal, teks).
    perintah_sql = f"""
        CREATE OR REPLACE TABLE {nama_tabel} AS
        SELECT *
        FROM read_csv_auto('{lokasi_file_untuk_sql}', header = true{pengaturan_tipe})
    """
    koneksi_database.execute(perintah_sql)

    # Hitung jumlah baris supaya kita tahu loadnya berhasil
    jumlah_baris = koneksi_database.execute(
        f"SELECT COUNT(*) FROM {nama_tabel}"
    ).fetchone()[0]

    print(f"OK  {nama_tabel:<28} {jumlah_baris:>10,} baris")


# ------------------------------------------------------------
# 5. Tutup koneksi
# ------------------------------------------------------------
koneksi_database.close()
print("Selesai. Semua CSV sudah masuk ke database.")
