import csv, random
random.seed(7)
KATEGORI = ["beyaz-esya", "elektronik", "mobilya", "tekstil", "gida", "kozmetik", "oyuncak", "kirtasiye"]
MARKA = ["Anadolu", "Marmara", "Ege", "Toros", "Firat", "Meric", "Kizilirmak", "Sakarya", "Yesilirmak", "Dicle"]
SEHIR = ["Istanbul", "Ankara", "Izmir", "Bursa", "Antalya", "Adana", "Konya", "Gaziantep", "Kayseri", "Trabzon", "Duzce", "Samsun"]
BOLGE = {"Istanbul": "Marmara", "Bursa": "Marmara", "Duzce": "Marmara", "Ankara": "Ic Anadolu",
         "Konya": "Ic Anadolu", "Kayseri": "Ic Anadolu", "Izmir": "Ege", "Antalya": "Akdeniz",
         "Adana": "Akdeniz", "Gaziantep": "Guneydogu", "Trabzon": "Karadeniz", "Samsun": "Karadeniz"}
with open("csv/dim_urun.csv", "w", newline="") as f:
    w = csv.writer(f)
    for i in range(1, 5001):
        k = random.choice(KATEGORI)
        w.writerow([i, f"{k}-urun-{i:05d}", k, random.choice(MARKA)])
with open("csv/dim_sube.csv", "w", newline="") as f:
    w = csv.writer(f)
    for i in range(1, 121):
        s = random.choice(SEHIR)
        w.writerow([i, f"{s} Sube {i:03d}", s, BOLGE[s]])
print("boyut tablolari hazir")
