"""20M satirlik sentetik satis verisi uretir. Ayni CSV Doris ve PostgreSQL'e yuklenir."""
import csv, random, sys, time
from datetime import date, timedelta

N = int(sys.argv[1]) if len(sys.argv) > 1 else 20_000_000
OUT = sys.argv[2] if len(sys.argv) > 2 else "csv/fact_satis.csv"

random.seed(20260902)
BASLANGIC = date(2023, 1, 1)
GUN_SAYISI = (date(2026, 8, 31) - BASLANGIC).days
GUNLER = [(BASLANGIC + timedelta(days=i)).isoformat() for i in range(GUN_SAYISI + 1)]

KANALLAR = ["magaza", "web", "mobil", "cagri-merkezi"]
KANAL_AGIRLIK = [50, 28, 18, 4]
DURUMLAR = ["tamamlandi", "iade", "iptal"]
DURUM_AGIRLIK = [93, 4, 3]

t0 = time.time()
with open(OUT, "w", newline="") as f:
    w = csv.writer(f)
    parti = 200_000
    yazilan = 0
    while yazilan < N:
        adet_bu_parti = min(parti, N - yazilan)
        gunler = random.choices(GUNLER, k=adet_bu_parti)
        kanallar = random.choices(KANALLAR, weights=KANAL_AGIRLIK, k=adet_bu_parti)
        durumlar = random.choices(DURUMLAR, weights=DURUM_AGIRLIK, k=adet_bu_parti)
        satirlar = []
        for i in range(adet_bu_parti):
            sid = yazilan + i + 1
            adet = random.randint(1, 8)
            birim = round(random.uniform(9.9, 4999.0), 2)
            tutar = round(adet * birim, 2)
            indirim = round(tutar * random.choice([0, 0, 0, 0.05, 0.1, 0.15, 0.25]), 2)
            satirlar.append((
                sid, gunler[i],
                random.randint(1, 500_000),
                random.randint(1, 5_000),
                random.randint(1, 120),
                kanallar[i], adet, birim, tutar, indirim, durumlar[i],
            ))
        w.writerows(satirlar)
        yazilan += adet_bu_parti
        if yazilan % 2_000_000 == 0:
            print(f"  {yazilan:,} satir, {time.time()-t0:.1f} sn", flush=True)

print(f"BITTI {N:,} satir, {time.time()-t0:.1f} sn -> {OUT}", flush=True)
