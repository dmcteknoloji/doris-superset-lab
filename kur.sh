#!/usr/bin/env bash
# Laboratuvari sifirdan ayaga kaldirir: konteynerler, semalar, veri, indeksler.
# Kullanim:  bash kur.sh [satir_sayisi]     ornek: bash kur.sh 20000000
set -euo pipefail
SATIR="${1:-20000000}"
MSSQL_SA_PASSWORD="${MSSQL_SA_PASSWORD:-Lab_Parola_2026!}"
export MSSQL_SA_PASSWORD

bekle() { printf "  %s" "$1"; }
tamam() { echo " tamam"; }

echo "== 1/8  Doris icin kernel ayari"
docker run --rm --privileged alpine sysctl -w vm.max_map_count=2000000 >/dev/null
tamam

echo "== 2/8  Superset imaji derleniyor (PostgreSQL + Doris + SQL Server surucululeri)"
docker build -q -f Dockerfile.superset -t lab-superset:6.1.0-doris . >/dev/null
tamam

echo "== 3/8  Konteynerler baslatiliyor"
docker compose up -d doris-fe postgres redis >/dev/null
sleep 30
docker compose up -d doris-be mssql superset >/dev/null
bekle "Doris BE kayit olana kadar bekleniyor"
for i in $(seq 1 40); do
  if docker exec lab-doris-fe mysql -h127.0.0.1 -P9030 -uroot -e 'SHOW BACKENDS\G' 2>/dev/null | grep -q "Alive: true"; then break; fi
  sleep 8
done
tamam

echo "== 4/8  Superset ilk kurulum"
docker exec lab-superset /app/.venv/bin/superset db upgrade >/dev/null 2>&1
docker exec lab-superset /app/.venv/bin/superset fab create-admin \
  --username admin --firstname Lab --lastname Admin \
  --email admin@lab.local --password labadmin123 >/dev/null 2>&1 || true
docker exec lab-superset /app/.venv/bin/superset init >/dev/null 2>&1
tamam

echo "== 5/8  Veri uretiliyor ($SATIR satir)"
mkdir -p csv out
python3 uret-veri.py "$SATIR" csv/fact_satis.csv
python3 uret-boyut.py

echo "== 6/8  Semalar"
docker cp sql/doris-ddl.sql lab-doris-fe:/tmp/ddl.sql >/dev/null
docker exec lab-doris-fe bash -lc "mysql -h127.0.0.1 -P9030 -uroot < /tmp/ddl.sql"
docker exec lab-postgres psql -U lab -d superset -c "CREATE DATABASE dwh OWNER lab;" >/dev/null 2>&1 || true
docker cp sql/pg-ddl.sql lab-postgres:/tmp/ddl.sql >/dev/null
docker exec lab-postgres psql -U lab -d dwh -f /tmp/ddl.sql >/dev/null
bekle "SQL Server acilana kadar bekleniyor"
for i in $(seq 1 40); do
  if docker exec lab-mssql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C -Q "SELECT 1" >/dev/null 2>&1; then break; fi
  sleep 10
done
tamam
docker cp sql/mssql-ddl.sql lab-mssql:/tmp/ddl.sql >/dev/null
docker exec lab-mssql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C -i /tmp/ddl.sql >/dev/null

echo "== 7/8  Veri yukleniyor"
echo "  Doris (Stream Load, BE portuna)"
for tablo in dim_urun dim_sube; do
  case $tablo in
    dim_urun) K="urun_id,urun_adi,kategori,marka" ;;
    dim_sube) K="sube_id,sube_adi,sehir,bolge" ;;
  esac
  curl -s --location-trusted -u root: -H "Expect:100-continue" -H "column_separator:," \
    -H "format:csv" -H "columns:$K" -T "csv/$tablo.csv" \
    "http://localhost:8040/api/dwh/$tablo/_stream_load" >/dev/null
done
curl -s --location-trusted -u root: -H "Expect:100-continue" -H "column_separator:," -H "format:csv" \
  -H "columns:satis_id,tarih,musteri_id,urun_id,sube_id,kanal,adet,birim_fiyat,tutar,indirim,durum" \
  -T csv/fact_satis.csv "http://localhost:8040/api/dwh/fact_satis/_stream_load" > out/doris-load.json
python3 -c "
import json; d=json.load(open('out/doris-load.json'))
print(f\"    {d['Status']}, {d['NumberLoadedRows']:,} satir, {d['LoadTimeMs']/1000:.1f} sn\")"

echo "  PostgreSQL (COPY)"
docker exec -i lab-postgres psql -U lab -d dwh -c "\copy dim_urun FROM STDIN WITH (FORMAT csv)" < csv/dim_urun.csv >/dev/null
docker exec -i lab-postgres psql -U lab -d dwh -c "\copy dim_sube FROM STDIN WITH (FORMAT csv)" < csv/dim_sube.csv >/dev/null
docker exec -i lab-postgres psql -U lab -d dwh -c "\copy fact_satis FROM STDIN WITH (FORMAT csv)" < csv/fact_satis.csv

echo "  SQL Server (BULK INSERT, ROWTERMINATOR 0x0d0a)"
docker exec lab-mssql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C -d dwh -Q "
BULK INSERT fact_satis FROM '/csv/fact_satis.csv' WITH (FIELDTERMINATOR=',', ROWTERMINATOR='0x0d0a', TABLOCK, BATCHSIZE=500000);
BULK INSERT dim_urun   FROM '/csv/dim_urun.csv'   WITH (FIELDTERMINATOR=',', ROWTERMINATOR='0x0d0a', TABLOCK);
BULK INSERT dim_sube   FROM '/csv/dim_sube.csv'   WITH (FIELDTERMINATOR=',', ROWTERMINATOR='0x0d0a', TABLOCK);" | tail -2

echo "== 8/8  Indeksler ve istatistikler"
for ix in "ix_fact_tarih ON fact_satis(tarih)" "ix_fact_urun ON fact_satis(urun_id)" "ix_fact_sube ON fact_satis(sube_id)"; do
  docker exec lab-postgres psql -U lab -d dwh -c "CREATE INDEX $ix;" >/dev/null
done
docker exec lab-postgres psql -U lab -d dwh -c "VACUUM ANALYZE fact_satis;" >/dev/null
docker exec lab-postgres psql -U lab -d dwh -c "ANALYZE dim_urun;" >/dev/null
docker exec lab-postgres psql -U lab -d dwh -c "ANALYZE dim_sube;" >/dev/null
docker exec lab-mssql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C -d dwh -Q "
CREATE INDEX ix_fact_tarih ON fact_satis(tarih);
CREATE INDEX ix_fact_urun  ON fact_satis(urun_id);
CREATE INDEX ix_fact_sube  ON fact_satis(sube_id);
UPDATE STATISTICS fact_satis WITH FULLSCAN;
UPDATE STATISTICS dim_urun; UPDATE STATISTICS dim_sube;" >/dev/null

cat <<'SON'

Laboratuvar hazir.

  Superset       http://localhost:8088     admin / labadmin123
  Doris (MySQL)  localhost:9030            kullanici root, parola yok
  PostgreSQL     localhost:55432           lab / labpass, veritabani dwh
  SQL Server     localhost:11433           sa / $MSSQL_SA_PASSWORD, veritabani dwh

Siradaki adimlar:
  bash olc.sh                 alti sorgu, Doris ve PostgreSQL
  bash olc-mssql.sh           ayni alti sorgu, SQL Server
  python3 superset-kur.py     Superset baglantisi, dataset, dort grafik, dashboard
  bash sqlserver-katalog.sh   Doris'ten SQL Server'a federasyon
SON
