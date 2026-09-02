#!/usr/bin/env bash
# Doris'ten SQL Server'a JDBC katalogu kurar. Veri kopyalanmaz, yerinde sorgulanir.
set -euo pipefail
MSSQL_SA_PASSWORD="${MSSQL_SA_PASSWORD:-Lab_Parola_2026!}"
SURUM="${MSSQL_JDBC_SURUM:-12.8.1.jre11}"
mkdir -p jdbc

if [ ! -f jdbc/mssql-jdbc.jar ]; then
  echo "SQL Server JDBC surucusu indiriliyor ($SURUM)"
  curl -sL -o jdbc/mssql-jdbc.jar \
    "https://repo1.maven.org/maven2/com/microsoft/sqlserver/mssql-jdbc/${SURUM}/mssql-jdbc-${SURUM}.jar"
fi

# Surucu HEM FE HEM BE konteynerinde olmali, tek tarafa koymak yetmez.
for c in lab-doris-fe lab-doris-be; do
  docker exec "$c" mkdir -p /opt/apache-doris/plugins/jdbc_drivers
  docker cp jdbc/mssql-jdbc.jar "$c":/opt/apache-doris/plugins/jdbc_drivers/mssql-jdbc.jar
done

docker exec lab-doris-fe mysql -h127.0.0.1 -P9030 -uroot -e "
DROP CATALOG IF EXISTS sqlserver_kaynak;
CREATE CATALOG sqlserver_kaynak PROPERTIES (
  'type'='jdbc',
  'user'='sa',
  'password'='${MSSQL_SA_PASSWORD}',
  'jdbc_url'='jdbc:sqlserver://172.28.10.7:1433;DataBaseName=dwh;encrypt=false;trustServerCertificate=true',
  'driver_url'='file:///opt/apache-doris/plugins/jdbc_drivers/mssql-jdbc.jar',
  'driver_class'='com.microsoft.sqlserver.jdbc.SQLServerDriver'
);
SHOW CATALOGS;"

echo
echo "Federe sorgu: SQL Server'daki olgu tablosu, veri kopyalanmadan"
docker exec lab-doris-fe mysql -vvv -h127.0.0.1 -P9030 -uroot -e "
SET enable_sql_cache=false;
SELECT kanal, count(*) AS adet, sum(tutar) AS ciro
FROM sqlserver_kaynak.dbo.fact_satis WHERE tarih >= '2026-06-01'
GROUP BY kanal ORDER BY ciro DESC;" | tail -12

echo
echo "Capraz katalog JOIN: Doris'teki boyut + SQL Server'daki olgu"
docker exec lab-doris-fe mysql -vvv -h127.0.0.1 -P9030 -uroot -e "
SET enable_sql_cache=false;
SELECT u.kategori, count(*) AS adet, round(sum(f.tutar)/1000000,1) AS ciro_milyon
FROM sqlserver_kaynak.dbo.fact_satis f
JOIN dwh.dim_urun u ON f.urun_id = u.urun_id
WHERE f.tarih >= '2026-07-01'
GROUP BY u.kategori ORDER BY ciro_milyon DESC;" | tail -16
