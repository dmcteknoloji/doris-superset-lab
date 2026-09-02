# Apache Doris + Apache Superset laboratuvarı

Tek makinede ayağa kalkan, üç veritabanı motorunu aynı veriyle karşılaştıran bir
Docker laboratuvarı. 20 milyon satırlık sentetik satış tablosu üretiliyor, aynı
CSV **Apache Doris**, **PostgreSQL** ve **SQL Server 2025**'e yükleniyor, altı
tipik rapor sorgusu üçer kez ölçülüyor. Üstüne Apache Superset kuruluyor ve
Doris'e bağlanıp dashboard açılıyor.

Amaç bir motoru kazandırmak değil. Kendi donanımınızda kendi sayınızı üretmeniz.

## Ölçtüğüm sonuçlar

MacBook, Apple Silicon, 16 GB RAM. Docker sanal makinesine 12 GB bellek ve 8 CPU.
Doris 4.0.8 (1 FE + 1 BE), PostgreSQL 16, SQL Server 2025 CU8, Superset 6.1.0.
Üç koşunun en iyisi, Doris'in SQL önbelleği kapalı.

| Sorgu | Doris | PostgreSQL | SQL Server |
|---|---|---|---|
| Aylık ciro, tam tablo agregasyon | **1,40 sn** | 2,79 sn | 7,95 sn |
| Kategori x marka, join + group by | **1,11 sn** | 2,53 sn | 6,42 sn |
| Bölge x kanal, join + tarih filtresi | **0,45 sn** | 1,02 sn | 5,39 sn |
| Aylık tekil müşteri, count distinct | **1,72 sn** | 9,08 sn | 6,28 sn |
| Filtreli top-100, sıralama | **0,15 sn** | 1,24 sn | 5,67 sn |
| Tek gün nokta sorgusu | **0,02 sn** | 0,03 sn | 0,12 sn |
| **Toplam** | **4,85 sn** | **16,68 sn** | **31,83 sn** |

Depolama tarafı:

| Motor | Tablo | İndeksler | Toplam |
|---|---|---|---|
| SQL Server 2025 | 1.646 MB | 1.027 MB | 2.673 MB |
| PostgreSQL 16 | 1.863 MB | 399 MB | 2.263 MB |
| Apache Doris 4.0.8 | 367 MB | yok | 367 MB |

Yükleme tarafı:

| Adım | Doris | PostgreSQL | SQL Server |
|---|---|---|---|
| Ham yükleme | 71,3 sn | 30,8 sn | 112,1 sn |
| İndeks oluşturma | yok | 16,5 sn | 119,8 sn |
| İstatistik | otomatik | 1,9 sn | 47,0 sn |
| Sorgulanabilir olana kadar | 71,3 sn | 49,2 sn | 278,9 sn |

### SQL Server sayılarını okurken

Microsoft'un imajı yalnızca amd64 yayınlanıyor. Apple Silicon üzerinde emülasyonla
dönüyor, Doris ve PostgreSQL ise native arm64 çalışıyor. Emülasyon cezasını aynı
makinede ölçtüm: birebir aynı CPU işi amd64 konteynerde 0,29 saniye, arm64'te 0,17
saniye. Kabaca 1,7 kat. Bölünce SQL Server'ın toplamı 19 saniye civarına iniyor,
yani PostgreSQL ile aynı kulvara. x86 bir sunucuda çalıştırırsanız üç motor da
native olur ve tablo değişir. Zaten bu depoyu yayınlama sebebi de o.

## Gereksinimler

- Docker ve Docker Compose
- Python 3.9 veya üstü (veri üreteci için, ek paket gerekmiyor)
- Docker sanal makinesine en az 10 GB bellek ve 60 GB boş disk
- İlk çalıştırmada yaklaşık 9 GB imaj indirilir (Doris BE tek başına 5,4 GB)

Linux ve macOS'ta test edildi. Windows'ta WSL2 üzerinden çalışması beklenir.

## Hızlı başlangıç

```bash
git clone https://github.com/dmcteknoloji/doris-superset-lab.git
cd doris-superset-lab
bash kur.sh
```

Varsayılan 20 milyon satır. Daha küçük bir denemede:

```bash
bash kur.sh 2000000
```

Kurulum bittiğinde erişim bilgileri ekrana yazılır:

| Servis | Adres | Kimlik |
|---|---|---|
| Superset | http://localhost:8088 | admin / labadmin123 |
| Doris | localhost:9030 (MySQL protokolü) | root, parola yok |
| PostgreSQL | localhost:55432 | lab / labpass, veritabanı dwh |
| SQL Server | localhost:11433 | sa / Lab_Parola_2026!, veritabanı dwh |

SQL Server parolasını değiştirmek için `MSSQL_SA_PASSWORD` ortam değişkenini
verin. Bu bir laboratuvar, parolalar bilerek basit ve dosyada açık duruyor.
İnternete açık bir makinede çalıştırmayın.

## Ne kuruluyor

```
                    Apache Superset 6.1.0
                    (Gunicorn + PostgreSQL metadata + Redis + Celery)
                              |
        +---------------------+---------------------+
        |                     |                     |
   Apache Doris          PostgreSQL 16        SQL Server 2025
   FE + BE                                    (JDBC kataloğuyla
   20M satır             20M satır             Doris'ten de okunur)
```

Doris tarafında tablo `DUPLICATE KEY(tarih, satis_id)`, aya göre otomatik aralık
bölümleme ve `satis_id` üzerinde 8 kova. PostgreSQL ve SQL Server tarafında aynı
kolonlar, üstüne `tarih`, `urun_id` ve `sube_id` için üç B-tree indeks. Her motora
kendi doğal kurulumunu verdim, karşılaştırmanın adil olmasının şartı bu.

## Ölçümü çalıştırmak

```bash
bash olc.sh          # alti sorgu x uc kosu, Doris ve PostgreSQL
bash olc-mssql.sh    # ayni alti sorgu, SQL Server
```

Sorgular `sql/sorgular-doris.sql`, `sql/sorgular-pg.sql` ve
`sql/sorgular-mssql.sql` dosyalarında. Kendi sorgunuzu eklemek isterseniz üç
dosyaya da aynı sırayla ekleyin, betikler satır satır okuyor.

Çıktı `out/olcum-ham.txt` ve `out/olcum-mssql.txt` dosyalarına yazılır. Süreyle
birlikte dönen satır sayısı da kaydedilir. Bunun neden önemli olduğu aşağıda,
yedinci tuzakta yazıyor.

## Superset ve dashboard

```bash
python3 superset-kur.py    # baglanti, dataset, dort grafik, bir dashboard
python3 olc-superset.py    # grafik veri sureleri
```

Bende bu adım 1,02 saniye sürdü. Ardından http://localhost:8088 adresinde
"Satis Analitigi (Doris)" dashboard'u hazır oluyor.

Superset'ten Doris'e bağlantı dizesi:

```
doris://root:@172.28.10.2:9030/dwh
```

Aynı Superset PostgreSQL ve SQL Server'a da bağlanıyor. İmaj `psycopg2-binary`,
`pydoris` ve `pymssql` ile derleniyor.

## SQL Server federasyonu

Doris, SQL Server'ı veri kopyalamadan sorgulayabiliyor. Göç sırasında işe yarıyor,
çünkü eski ambarı yerinde bırakıp üstünden okuyarak kademeli geçiş yapabiliyorsunuz.

```bash
bash sqlserver-katalog.sh
```

Betik JDBC sürücüsünü indiriyor, hem FE hem BE konteynerine kopyalıyor, kataloğu
kuruyor ve iki örnek sorgu çalıştırıyor. İkincisi çapraz katalog JOIN'i:
Doris'teki yerel boyut tablosu, SQL Server'daki olgu tablosuyla birleşiyor.

Bende federe kanal kırılımı 7,82 saniye, çapraz katalog JOIN 8,78 saniye sürdü.

## Kendi verinizle çalıştırmak

`uret-veri.py` sentetik satış verisi üretiyor: 11 kolon, 2023-01-01 ile 2026-08-31
arası tarih dağılımı, dört satış kanalı, üç sipariş durumu. Kendi CSV'nizi
kullanmak isterseniz aynı kolon sırasını koruyun ya da `sql/` altındaki üç DDL
dosyasını ve yükleme komutlarındaki kolon listelerini birlikte güncelleyin.

Ölçekle oynamak için satır sayısını parametre verin. 2 milyon satır dizüstünde
rahat çalışıyor, 20 milyon satır 12 GB bellekli bir Docker sanal makinesinde
sıkışmadan dönüyor.

## Yolda karşılaştığım yedi tuzak

Kurulumu iki katına çıkaran kısım burası. Betikler bunların hepsini baştan
çözülmüş halde içeriyor, ama neden öyle yazıldığını bilmek isterseniz:

**1. Superset'in resmi imajında PostgreSQL sürücüsü yok.** Konteyner açılıyor ve
`ModuleNotFoundError: No module named 'psycopg2'` deyip ölüyor. Kendi metadata
veritabanına bağlanamıyor. `Dockerfile.superset` bu yüzden var.

**2. Doris Stream Load, FE portuna gönderilirse çalışmıyor.** FE'nin 8030 portu
yüklemeyi BE'nin konteyner içi adresine HTTP 307 ile yönlendiriyor. Host o ağı
göremediği için istek sessizce başarısız oluyor, hata bile vermiyor. Yükleme
doğrudan BE'nin yayınlanmış portuna (8040) gidiyor.

**3. Docker'ın varsayılan 64 MB'lık `/dev/shm` boyutu PostgreSQL'i durduruyor.**
Paralel sorgu için gereken dinamik paylaşılan bellek sığmıyor ve
`could not resize shared memory segment` hatası geliyor. Compose'da
`shm_size: 1gb` tanımlı.

**4. `postgres:16-alpine` arm64'te büyük tabloda çöküyor.** Tam tarama yapan her
sorguda `server process was terminated by signal 7: Bus error` alıp kurtarma
moduna giriyor. Debian tabanlı `postgres:16` imajında tek bir sorun çıkmadı.

**5. Doris'in SQL önbelleği varsayılan açık.** `enable_sql_cache` değeri `true`
geliyor ve ısınmış koşular 0,00 saniye gösteriyor. 20 milyon satırlık bir
agregasyon 10 milisaniyede bitmiyor. Ölçüm betiği her sorgudan önce bu değişkeni
kapatıyor. Karşılaştırma yapan herkes kontrol etsin.

**6. Doris BE, 3 GB bellekle `count(DISTINCT)` sorgusunu iptal edebiliyor.**
`MEM_LIMIT_EXCEEDED` geliyor ve 4.0'ın spill-to-disk özelliğini açmak da
kurtarmıyor, çünkü süreç zaten limitteyken dökecek yer bulamıyor. BE'yi yeniden
başlatınca aynı sorgu 1,46 saniyede bitti. Üretimde BE başına önerilen 16 GB'ı
ciddiye alın.

**7. Ölçüm sessizce yanlış çıkabiliyor.** Veri üreteci CSV'yi `\r\n` satır sonuyla
yazıyor. PostgreSQL'in `COPY` komutu ve Doris'in Stream Load'u `\r` karakterini
temizliyor. SQL Server'ın `BULK INSERT` komutu `ROWTERMINATOR='0x0a'` verilirse
temizlemiyor ve `durum` alanı bir karakter uzun kalıyor. `durum='tamamlandi'`
filtresi kullanan sorgular boş küme dönüyor, üstelik hata vermeden. Süreler de
makul görünüyor. Yükleme `0x0d0a` ile yapılıyor ve ölçüm betikleri süreyle
birlikte dönen satır sayısını da yazıyor.

**Bonus.** PostgreSQL veri dizinini macOS bind mount'unda tutunca `COPY` 53,1
saniye sürüyor, Docker named volume'da aynı iş 30,8 saniye. Compose named volume
kullanıyor.

## Temizlik

```bash
bash temizle.sh
```

Konteynerleri, volume'leri ve üretilen CSV dosyalarını siler. İmajlar durur,
onları da silmek isterseniz komut ekranda yazıyor.

## Dosyalar

| Dosya | Ne yapar |
|---|---|
| `kur.sh` | Sıfırdan tam kurulum, sekiz adım |
| `docker-compose.yml` | Beş servis, ağ, volume ve bellek limitleri |
| `Dockerfile.superset` | Superset imajına üç veritabanı sürücüsü ekler |
| `uret-veri.py` | Sentetik satış verisi üretir |
| `uret-boyut.py` | Ürün ve şube boyut tablolarını üretir |
| `sql/` | Üç motor için DDL ve sorgu dosyaları |
| `olc.sh`, `olc-mssql.sh` | Sorgu ölçümü |
| `superset-kur.py` | Superset bağlantısı, dataset, grafikler, dashboard |
| `olc-superset.py` | Superset üzerinden grafik veri süreleri |
| `sqlserver-katalog.sh` | Doris'ten SQL Server'a JDBC kataloğu ve federe sorgular |
| `temizle.sh` | Her şeyi kaldırır |

## Lisans

MIT. Ölçümlerinizi paylaşırsanız memnun olurum, özellikle x86 sunucuda üç motorun
da native çalıştığı sayıları merak ediyorum.
