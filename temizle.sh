#!/usr/bin/env bash
# Konteynerleri ve volume'leri kaldirir. Uretilen CSV dosyalarini da siler.
set -u
docker compose down -v
rm -rf csv out jdbc
echo "Laboratuvar kaldirildi. Imajlar duruyor, silmek icin:"
echo "  docker rmi apache/doris:fe-4.0.8 apache/doris:be-4.0.8 lab-superset:6.1.0-doris"
