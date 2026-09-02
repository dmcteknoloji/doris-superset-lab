SELECT DATETRUNC(month, tarih) AS ay, COUNT(*) AS satis_adedi, SUM(tutar) AS ciro, SUM(indirim) AS indirim FROM fact_satis WHERE durum='tamamlandi' GROUP BY DATETRUNC(month, tarih) ORDER BY 1;
SELECT TOP 20 u.kategori, u.marka, SUM(f.tutar) AS ciro FROM fact_satis f JOIN dim_urun u ON f.urun_id=u.urun_id WHERE f.tarih >= '2025-01-01' AND f.durum='tamamlandi' GROUP BY u.kategori, u.marka ORDER BY ciro DESC;
SELECT s.bolge, f.kanal, COUNT(*) AS adet, SUM(f.tutar) AS ciro FROM fact_satis f JOIN dim_sube s ON f.sube_id=s.sube_id WHERE f.tarih >= '2025-09-01' GROUP BY s.bolge, f.kanal ORDER BY ciro DESC;
SELECT DATETRUNC(month, tarih) AS ay, COUNT(DISTINCT musteri_id) AS tekil_musteri FROM fact_satis GROUP BY DATETRUNC(month, tarih) ORDER BY 1;
SELECT TOP 100 satis_id, tarih, musteri_id, tutar FROM fact_satis WHERE durum='tamamlandi' AND tarih BETWEEN '2026-01-01' AND '2026-06-30' ORDER BY tutar DESC;
SELECT COUNT(*) AS adet, SUM(tutar) AS ciro FROM fact_satis WHERE tarih='2026-03-15';
