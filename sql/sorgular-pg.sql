-- Q1 aylik ciro (tam tablo agregasyon)
SELECT date_trunc('month', tarih) AS ay, count(*) AS satis_adedi, sum(tutar) AS ciro, sum(indirim) AS indirim FROM fact_satis WHERE durum='tamamlandi' GROUP BY 1 ORDER BY 1;
-- Q2 kategori x marka ciro (join, 2025+)
SELECT u.kategori, u.marka, sum(f.tutar) AS ciro FROM fact_satis f JOIN dim_urun u ON f.urun_id=u.urun_id WHERE f.tarih >= '2025-01-01' AND f.durum='tamamlandi' GROUP BY 1,2 ORDER BY ciro DESC LIMIT 20;
-- Q3 bolge x kanal (join, son 12 ay)
SELECT s.bolge, f.kanal, count(*) AS adet, sum(f.tutar) AS ciro FROM fact_satis f JOIN dim_sube s ON f.sube_id=s.sube_id WHERE f.tarih >= '2025-09-01' GROUP BY 1,2 ORDER BY ciro DESC;
-- Q4 aylik tekil musteri (count distinct, agir)
SELECT date_trunc('month', tarih) AS ay, count(DISTINCT musteri_id) AS tekil_musteri FROM fact_satis GROUP BY 1 ORDER BY 1;
-- Q5 filtreli top-100
SELECT satis_id, tarih, musteri_id, tutar FROM fact_satis WHERE durum='tamamlandi' AND tarih BETWEEN '2026-01-01' AND '2026-06-30' ORDER BY tutar DESC LIMIT 100;
-- Q6 tek gun nokta sorgusu
SELECT count(*) AS adet, sum(tutar) AS ciro FROM fact_satis WHERE tarih='2026-03-15';
