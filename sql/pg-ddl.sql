DROP TABLE IF EXISTS fact_satis;
CREATE TABLE fact_satis (
    satis_id     BIGINT       NOT NULL,
    tarih        DATE         NOT NULL,
    musteri_id   INTEGER,
    urun_id      INTEGER,
    sube_id      INTEGER,
    kanal        VARCHAR(20),
    adet         INTEGER,
    birim_fiyat  NUMERIC(10,2),
    tutar        NUMERIC(12,2),
    indirim      NUMERIC(10,2),
    durum        VARCHAR(20)
);

DROP TABLE IF EXISTS dim_urun;
CREATE TABLE dim_urun (
    urun_id   INTEGER PRIMARY KEY,
    urun_adi  VARCHAR(80),
    kategori  VARCHAR(40),
    marka     VARCHAR(40)
);

DROP TABLE IF EXISTS dim_sube;
CREATE TABLE dim_sube (
    sube_id   INTEGER PRIMARY KEY,
    sube_adi  VARCHAR(80),
    sehir     VARCHAR(40),
    bolge     VARCHAR(40)
);
