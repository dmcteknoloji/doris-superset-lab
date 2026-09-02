import json, time, urllib.request, urllib.error
BASE="http://localhost:8088"
def cagir(yol, veri=None, tok=None):
    r=urllib.request.Request(BASE+yol, data=json.dumps(veri).encode() if veri else None,
                             method="POST" if veri else "GET")
    r.add_header("Content-Type","application/json")
    if tok: r.add_header("Authorization","Bearer "+tok)
    try:
        with urllib.request.urlopen(r, timeout=300) as f: return json.loads(f.read().decode())
    except urllib.error.HTTPError as e:
        return {"_hata": e.code, "_govde": e.read().decode()[:200]}

tok=cagir("/api/v1/security/login",{"username":"admin","password":"labadmin123","provider":"db","refresh":True})["access_token"]
CIRO={"expressionType":"SIMPLE","column":{"column_name":"tutar","type":"DECIMAL"},"aggregate":"SUM","label":"Ciro"}

SORGULAR = {
 "Toplam ciro (big number)": {"columns":[],"metrics":[CIRO],"row_limit":1},
 "Aylik ciro trendi": {"columns":[{"timeGrain":"P1M","columnType":"BASE_AXIS","sqlExpression":"tarih","label":"ay","expressionType":"SQL"}],
                       "metrics":[CIRO],"row_limit":1000},
 "Kanal kirilimi": {"columns":["kanal"],"metrics":[CIRO],"row_limit":10},
 "Durum x kanal": {"columns":["kanal","durum"],"metrics":[CIRO],"row_limit":50},
}
print(f"{'Superset grafigi':28} {'1.':>8} {'2.':>8} {'3.':>8}  satir")
print("-"*62)
for ad,q in SORGULAR.items():
    sureler=[]; n=0
    for i in range(3):
        qc={"datasource":{"id":1,"type":"table"},"force":True,"queries":[q],
            "result_format":"json","result_type":"full"}
        t0=time.time(); d=cagir("/api/v1/chart/data",qc,tok); dt=time.time()-t0
        if "_hata" in d: sureler.append(None); print("  hata:", d["_govde"][:120]); break
        n=len(d["result"][0].get("data",[])); sureler.append(dt)
    s=" ".join(f"{x:7.2f}s" if x else "   HATA" for x in sureler)
    print(f"{ad:28} {s}  {n}")
