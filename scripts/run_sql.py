"""
run_sql.py
----------
Menjalankan file-file SQL project secara berurutan ke database olist.duckdb.

Cara pakai (dari folder utama project):
    python scripts/run_sql.py

Urutan yang dijalankan:
    1. sql/01_staging.sql            -> bersihkan data mentah
    2. sql/02_star_schema.sql        -> bangun tabel dim_ dan fact_
    3. sql/03_export_for_powerbi.sql -> ekspor CSV untuk Power BI
    4. semua file di sql/04_analysis -> query analisis, hasilnya disimpan
                                        sebagai CSV di folder outputs/
"""

import os
import duckdb


# ------------------------------------------------------------
# 1. Lokasi folder
# ------------------------------------------------------------
folder_script = os.path.dirname(os.path.abspath(__file__))
folder_project = os.path.dirname(folder_script)
folder_sql = os.path.join(folder_project, "sql")
folder_analisis = os.path.join(folder_sql, "04_analysis")
folder_output = os.path.join(folder_project, "outputs")
lokasi_database = os.path.join(folder_project, "olist.duckdb")

# Pindah ke folder project supaya path relatif di SQL (data/model/...) benar
os.chdir(folder_project)

# Pastikan folder tujuan ekspor ada
os.makedirs(os.path.join(folder_project, "data", "model"), exist_ok=True)
os.makedirs(folder_output, exist_ok=True)


# ------------------------------------------------------------
# 2. Fungsi kecil untuk membaca isi file SQL
# ------------------------------------------------------------
def baca_file_sql(lokasi_file):
    with open(lokasi_file, "r", encoding="utf-8") as file_sql:
        isi_file = file_sql.read()
    return isi_file


# ------------------------------------------------------------
# 3. Jalankan file SQL pembangun model (01, 02, 03)
# ------------------------------------------------------------
koneksi_database = duckdb.connect(lokasi_database)

daftar_file_model = [
    "01_staging.sql",
    "02_star_schema.sql",
    "03_export_for_powerbi.sql",
]

for nama_file in daftar_file_model:
    lokasi_file = os.path.join(folder_sql, nama_file)
    isi_sql = baca_file_sql(lokasi_file)
    koneksi_database.execute(isi_sql)
    print("OK  dijalankan:", nama_file)


# ------------------------------------------------------------
# 4. Jalankan query analisis, simpan hasilnya ke outputs/
# ------------------------------------------------------------
# Setiap file analisis berisi SATU query SELECT.
daftar_file_analisis = sorted(os.listdir(folder_analisis))

for nama_file in daftar_file_analisis:
    if not nama_file.endswith(".sql"):
        continue

    lokasi_file = os.path.join(folder_analisis, nama_file)
    isi_sql = baca_file_sql(lokasi_file)

    # Ambil hasil query sebagai tabel pandas
    hasil_query = koneksi_database.execute(isi_sql).df()

    # Simpan ke CSV dengan nama yang sama (contoh: 01_monthly_trend.csv)
    nama_file_output = nama_file.replace(".sql", ".csv")
    lokasi_output = os.path.join(folder_output, nama_file_output)
    hasil_query.to_csv(lokasi_output, index=False)

    print(f"OK  analisis: {nama_file:<35} -> {len(hasil_query):>4} baris")


koneksi_database.close()
print("Selesai.")
