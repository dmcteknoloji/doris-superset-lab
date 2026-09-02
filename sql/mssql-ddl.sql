IF DB_ID('dwh') IS NULL CREATE DATABASE dwh;
GO
USE dwh;
GO
IF OBJECT_ID('fact_satis') IS NOT NULL DROP TABLE fact_satis;
CREATE TABLE fact_satis (
    satis_id     BIGINT       NOT NULL,
    tarih        DATE         NOT NULL,
    musteri_id   INT,
    urun_id      INT,
    sube_id      INT,
    kanal        VARCHAR(20),
    adet         INT,
    birim_fiyat  DECIMAL(10,2),
    tutar        DECIMAL(12,2),
    indirim      DECIMAL(10,2),
    durum        VARCHAR(20)
);
IF OBJECT_ID('dim_urun') IS NOT NULL DROP TABLE dim_urun;
CREATE TABLE dim_urun (urun_id INT PRIMARY KEY, urun_adi VARCHAR(80), kategori VARCHAR(40), marka VARCHAR(40));
IF OBJECT_ID('dim_sube') IS NOT NULL DROP TABLE dim_sube;
CREATE TABLE dim_sube (sube_id INT PRIMARY KEY, sube_adi VARCHAR(80), sehir VARCHAR(40), bolge VARCHAR(40));
GO
