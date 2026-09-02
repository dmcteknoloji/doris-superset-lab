CREATE DATABASE IF NOT EXISTS dwh;

DROP TABLE IF EXISTS dwh.fact_satis;
CREATE TABLE dwh.fact_satis (
    tarih        DATE            NOT NULL,
    satis_id     BIGINT          NOT NULL,
    musteri_id   INT             NULL,
    urun_id      INT             NULL,
    sube_id      INT             NULL,
    kanal        VARCHAR(20)     NULL,
    adet         INT             NULL,
    birim_fiyat  DECIMAL(10,2)   NULL,
    tutar        DECIMAL(12,2)   NULL,
    indirim      DECIMAL(10,2)   NULL,
    durum        VARCHAR(20)     NULL
)
DUPLICATE KEY(tarih, satis_id)
AUTO PARTITION BY RANGE (date_trunc(tarih, 'month')) ()
DISTRIBUTED BY HASH(satis_id) BUCKETS 8
PROPERTIES ("replication_num" = "1");

DROP TABLE IF EXISTS dwh.dim_urun;
CREATE TABLE dwh.dim_urun (
    urun_id   INT          NOT NULL,
    urun_adi  VARCHAR(80)  NULL,
    kategori  VARCHAR(40)  NULL,
    marka     VARCHAR(40)  NULL
)
DUPLICATE KEY(urun_id)
DISTRIBUTED BY HASH(urun_id) BUCKETS 2
PROPERTIES ("replication_num" = "1");

DROP TABLE IF EXISTS dwh.dim_sube;
CREATE TABLE dwh.dim_sube (
    sube_id   INT          NOT NULL,
    sube_adi  VARCHAR(80)  NULL,
    sehir     VARCHAR(40)  NULL,
    bolge     VARCHAR(40)  NULL
)
DUPLICATE KEY(sube_id)
DISTRIBUTED BY HASH(sube_id) BUCKETS 1
PROPERTIES ("replication_num" = "1");
