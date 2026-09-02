#!/bin/bash
set -u
OUT=out/olcum-ham.txt
: > "$OUT"
mapfile -t DORIS < <(grep -v '^--' sql/sorgular-doris.sql | grep -v '^$')
mapfile -t PGQ   < <(grep -v '^--' sql/sorgular-pg.sql    | grep -v '^$')
for q in 0 1 2 3 4 5; do
  n=$((q+1))
  for r in 1 2 3; do
    raw=$(docker exec lab-doris-fe bash -lc "mysql -vvv -h127.0.0.1 -P9030 -uroot -e \"USE dwh; SET enable_sql_cache=false; ${DORIS[$q]}\"" 2>&1)
    if echo "$raw" | grep -q "^ERROR"; then
      t="HATA"
    else
      t=$(echo "$raw" | grep -oE '[0-9]+ rows? in set \([0-9]+\.[0-9]+ sec\)' | tail -1 | grep -oE '[0-9]+\.[0-9]+')
    fi
    echo "doris Q$n run$r ${t:-NA}" | tee -a "$OUT"
    praw=$(printf '\\timing on\n%s\n' "${PGQ[$q]}" | docker exec -i lab-postgres psql -U lab -d dwh 2>&1)
    if echo "$praw" | grep -qi "error"; then p="HATA"; else
      p=$(echo "$praw" | grep -oE 'Time: [0-9.]+ ms' | tail -1 | grep -oE '[0-9.]+')
    fi
    echo "pg Q$n run$r ${p:-NA}" | tee -a "$OUT"
  done
done
