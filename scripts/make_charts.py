"""
make_charts.py
--------------
Membuat 4 grafik pendukung insight report dari file CSV di folder outputs/.
Hasilnya disimpan di report/figures/.

Cara pakai (setelah run_sql.py):
    python scripts/make_charts.py
"""

import os
import pandas as pd
import matplotlib
matplotlib.use("Agg")  # supaya bisa jalan tanpa membuka jendela grafik
import matplotlib.pyplot as plt


# ------------------------------------------------------------
# 1. Lokasi folder
# ------------------------------------------------------------
folder_script = os.path.dirname(os.path.abspath(__file__))
folder_project = os.path.dirname(folder_script)
folder_output_sql = os.path.join(folder_project, "outputs")
folder_gambar = os.path.join(folder_project, "report", "figures")
os.makedirs(folder_gambar, exist_ok=True)

# Warna: satu warna utama, satu warna untuk hal yang "buruk"
warna_utama = "#1F3A5F"
warna_buruk = "#C0392B"
warna_abu = "#B0B7C3"

# Gaya umum grafik
plt.rcParams["font.size"] = 10
plt.rcParams["axes.spines.top"] = False
plt.rcParams["axes.spines.right"] = False


# ------------------------------------------------------------
# 2. Grafik 1: tren GMV bulanan
# ------------------------------------------------------------
data_tren = pd.read_csv(os.path.join(folder_output_sql, "01_monthly_trend.csv"))

gambar, sumbu = plt.subplots(figsize=(9, 4))
gmv_dalam_ribu = data_tren["gmv"] / 1000
sumbu.bar(data_tren["year_month"], gmv_dalam_ribu, color=warna_utama)

# Tandai bulan November 2017 (Black Friday) dengan warna berbeda
posisi_november = list(data_tren["year_month"]).index("2017-11")
sumbu.patches[posisi_november].set_color("#E67E22")
sumbu.annotate("Black Friday\n(24 Nov 2017)",
               xy=(posisi_november, gmv_dalam_ribu[posisi_november]),
               xytext=(posisi_november - 6, gmv_dalam_ribu[posisi_november] - 150),
               arrowprops={"arrowstyle": "->"})

sumbu.set_title("GMV bulanan tumbuh 2,4x (Jan-Agu 2018 vs Jan-Agu 2017), lalu mendatar di 2018",
                loc="left", fontweight="bold")
sumbu.set_ylabel("GMV (ribu BRL)")
plt.xticks(rotation=60)
plt.tight_layout()
plt.savefig(os.path.join(folder_gambar, "01_gmv_trend.png"), dpi=150)
plt.close()
print("OK  01_gmv_trend.png")


# ------------------------------------------------------------
# 3. Grafik 2: review score per kelompok ketepatan kirim
# ------------------------------------------------------------
data_kirim = pd.read_csv(os.path.join(folder_output_sql, "04_delivery_vs_review.csv"))

# Hapus angka urutan "1. " di depan label supaya rapi
label_kelompok = []
for label in data_kirim["delivery_bucket"]:
    label_bersih = label[3:]
    label_kelompok.append(label_bersih)

# Kelompok "Telat" diberi warna merah
daftar_warna = []
for label in label_kelompok:
    if label.startswith("Telat"):
        daftar_warna.append(warna_buruk)
    else:
        daftar_warna.append(warna_utama)

gambar, sumbu = plt.subplots(figsize=(8, 4))
batang = sumbu.bar(label_kelompok, data_kirim["avg_review"], color=daftar_warna)
sumbu.bar_label(batang, fmt="%.2f")
sumbu.set_ylim(0, 5)
sumbu.set_title("Begitu paket telat, rata-rata review anjlok dari 4,3 ke 2,3 bintang",
                loc="left", fontweight="bold")
sumbu.set_ylabel("Rata-rata review (1-5)")
plt.xticks(rotation=15)
plt.tight_layout()
plt.savefig(os.path.join(folder_gambar, "02_delivery_vs_review.png"), dpi=150)
plt.close()
print("OK  02_delivery_vs_review.png")


# ------------------------------------------------------------
# 4. Grafik 3: segmen pelanggan (RFM)
# ------------------------------------------------------------
data_rfm = pd.read_csv(os.path.join(folder_output_sql, "03_rfm_segments.csv"))
data_rfm = data_rfm.sort_values("customers", ascending=True)

gambar, sumbu = plt.subplots(figsize=(8, 4))
daftar_warna_rfm = []
for segmen in data_rfm["rfm_segment"]:
    if segmen.startswith("Loyal"):
        daftar_warna_rfm.append(warna_utama)
    else:
        daftar_warna_rfm.append(warna_abu)

batang = sumbu.barh(data_rfm["rfm_segment"], data_rfm["customers_pct"], color=daftar_warna_rfm)
sumbu.bar_label(batang, fmt="%.1f%%", padding=3)
sumbu.set_title("Hanya 3% pelanggan yang pernah belanja lebih dari sekali",
                loc="left", fontweight="bold")
sumbu.set_xlabel("% pelanggan")
plt.tight_layout()
plt.savefig(os.path.join(folder_gambar, "03_rfm_segments.png"), dpi=150)
plt.close()
print("OK  03_rfm_segments.png")


# ------------------------------------------------------------
# 5. Grafik 4: Pareto kategori produk
# ------------------------------------------------------------
data_kategori = pd.read_csv(os.path.join(folder_output_sql, "06_category_pareto.csv"))
data_top = data_kategori.head(20)

gambar, sumbu_kiri = plt.subplots(figsize=(10, 4.5))
sumbu_kiri.bar(data_top["category_name"], data_top["revenue"] / 1000, color=warna_utama)
sumbu_kiri.set_ylabel("Revenue (ribu BRL)")
plt.xticks(rotation=70, ha="right")

# Sumbu kanan untuk persentase kumulatif
sumbu_kanan = sumbu_kiri.twinx()
sumbu_kanan.plot(data_top["category_name"], data_top["cumulative_pct"],
                 color="#E67E22", marker="o")
sumbu_kanan.axhline(80, color=warna_abu, linestyle="--")
sumbu_kanan.set_ylim(0, 100)
sumbu_kanan.set_ylabel("% kumulatif")

sumbu_kiri.set_title("17 dari 74 kategori menyumbang ~80% revenue",
                     loc="left", fontweight="bold")
plt.tight_layout()
plt.savefig(os.path.join(folder_gambar, "04_category_pareto.png"), dpi=150)
plt.close()
print("OK  04_category_pareto.png")
