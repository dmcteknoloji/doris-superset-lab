#!/usr/bin/env bash
# Alti sorguyu SQL Server'da ucer kez calistirir, sureyi ve donen satir sayisini yazar.
set -u
MSSQL_SA_PASSWORD="${MSSQL_SA_PASSWORD:-Lab_Parola_2026!}"
mkdir -p out; : > out/olcum-mssql.txt
n=0
while IFS= read -r q; do
  [ -z "$q" ] && continue
  n=$((n+1))
  for r in 1 2 3; do
    cikti=$(docker exec lab-mssql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa \
            -P "$MSSQL_SA_PASSWORD" -C -d dwh -Q "SET STATISTICS TIME ON; $q" 2>&1)
    ms=$(echo "$cikti"  | grep -oE "elapsed time = [0-9]+ ms" | tail -1 | grep -oE "[0-9]+")
    sat=$(echo "$cikti" | grep -oE "\([0-9]+ rows affected\)" | tail -1 | grep -oE "[0-9]+")
    echo "mssql Q$n run$r ${ms:-NA} satir=${sat:-?}" | tee -a out/olcum-mssql.txt
  done
done < sql/sorgular-mssql.sql
