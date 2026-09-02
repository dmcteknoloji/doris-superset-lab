import json, time, urllib.request, urllib.error

BASE = "http://localhost:8088"
def istek(yol, veri=None, token=None, yontem=None):
    url = BASE + yol
    body = json.dumps(veri).encode() if veri is not None else None
    r = urllib.request.Request(url, data=body, method=yontem or ("POST" if veri else "GET"))
    r.add_header("Content-Type", "application/json")
    if token: r.add_header("Authorization", "Bearer " + token)
    try:
        with urllib.request.urlopen(r, timeout=120) as f:
            return json.loads(f.read().decode())
    except urllib.error.HTTPError as e:
        print("HTTP", e.code, yol, e.read().decode()[:400]); raise

t0 = time.time()
tok = istek("/api/v1/security/login", {"username":"admin","password":"labadmin123","provider":"db","refresh":True})["access_token"]
print("giris OK  %.2f sn" % (time.time()-t0))

db = istek("/api/v1/database/", {
    "database_name": "Apache Doris (dwh)",
    "sqlalchemy_uri": "doris://root:@172.28.10.2:9030/dwh",
    "expose_in_sqllab": True,
}, tok)
db_id = db["id"]
print("veritabani eklendi id=%d  %.2f sn" % (db_id, time.time()-t0))

ds = istek("/api/v1/dataset/", {"database": db_id, "schema": "dwh", "table_name": "fact_satis"}, tok)
ds_id = ds["id"]
print("dataset olustu id=%d  %.2f sn" % (ds_id, time.time()-t0))

dash = istek("/api/v1/dashboard/", {"dashboard_title": "Satis Analitigi (Doris)", "published": True}, tok)
dash_id = dash["id"]
print("dashboard olustu id=%d" % dash_id)

def grafik(ad, viz, params):
    p = dict(params); p.update({"datasource": f"{ds_id}__table", "viz_type": viz})
    c = istek("/api/v1/chart/", {
        "slice_name": ad, "viz_type": viz,
        "datasource_id": ds_id, "datasource_type": "table",
        "params": json.dumps(p), "dashboards": [dash_id],
    }, tok)
    print("  grafik:", ad, "id=", c["id"])
    return c["id"]

grafik("Toplam ciro", "big_number_total", {
    "metric": {"expressionType":"SIMPLE","column":{"column_name":"tutar"},"aggregate":"SUM","label":"Ciro"},
    "adhoc_filters": [], "subheader": "20M satir uzerinden"})

grafik("Aylik ciro trendi", "echarts_timeseries_line", {
    "x_axis": "tarih", "time_grain_sqla": "P1M",
    "metrics": [{"expressionType":"SIMPLE","column":{"column_name":"tutar"},"aggregate":"SUM","label":"Ciro"}],
    "groupby": [], "adhoc_filters": [], "row_limit": 1000})

grafik("Kanal kirilimi", "pie", {
    "groupby": ["kanal"],
    "metric": {"expressionType":"SIMPLE","column":{"column_name":"tutar"},"aggregate":"SUM","label":"Ciro"},
    "adhoc_filters": [], "row_limit": 10})

grafik("Sube bazli ciro", "echarts_timeseries_bar", {
    "x_axis": "kanal",
    "metrics": [{"expressionType":"SIMPLE","column":{"column_name":"tutar"},"aggregate":"SUM","label":"Ciro"}],
    "groupby": ["durum"], "adhoc_filters": [], "row_limit": 50})

print("TOPLAM: %.2f sn" % (time.time()-t0))
print("dashboard: %s/superset/dashboard/%d/" % (BASE, dash_id))
