# Backend (Express + SQLite) — AI Vehicle Counter

Bu klasör, projenin **backend API** kısmıdır. Express ile çalışır ve veriyi SQLite dosyasına yazar.

Backend ayrıca dıştaki **ham araç sayısı** endpoint'ini periyodik olarak okur, **jitter filtresi (stabilite)** uygular ve stabil değer oluşunca DB'ye kaydeder.

## Gereksinimler
- Node.js (LTS önerilir, **Node 18+**)
- npm

## Kurulum (Sunucu / VM)
1. Bu klasörü sunucuya kopyalayın.
2. Bağımlılıkları kurun:

```bash
npm ci --omit=dev
```

3. Ortam değişkenlerini ayarlayın (aşağıya bakın).
4. Servisi başlatın:

```bash
npm start
```

## Ortam Değişkenleri (.env)
`.env` dosyası opsiyoneldir; yoksa varsayılanlar kullanılır.

- `PORT`: API'nin dinleyeceği port (varsayılan: `3001`)
- `DATABASE_FILE`: SQLite dosya yolu (varsayılan: `backend/data/vehicle_counter.db`)
- `RAW_COUNT_URL`: Ham sayı dönen dış endpoint (varsayılan: `http://192.248.154.28/carcount`)
- `POLL_INTERVAL_MS`: Ham veriyi okuma periyodu (varsayılan: `1000`)
- `STABLE_SECONDS`: Aynı sayının stabil kabul edilmesi için gereken süre (varsayılan: `5`)
- `CAMERA_ID`: Bu backend instance'ının kamera kimliği (varsayılan: `1`)

Örnek (değerleri kendinize göre yazın). Repo içinde örnek dosya: `backend/env.example`.

```bash
PORT=3001
DATABASE_FILE=/var/lib/ai-vehicle-counter/vehicle_counter.db
RAW_COUNT_URL=http://192.248.154.28/carcount
POLL_INTERVAL_MS=1000
STABLE_SECONDS=5
CAMERA_ID=1
```

> Not: Uygulama, `DATABASE_FILE` içindeki dizin yoksa otomatik oluşturur.

## Stabilite (Jitter Filtresi)
- Backend her **1 saniyede** bir `RAW_COUNT_URL`'i okur.
- Ham `count` değeri **en az `STABLE_SECONDS` saniye** boyunca aynı kalırsa **stabil** kabul edilir.
- Stabil kabul edilen değer `vehicle_logs(id, camera_id, count, timestamp)` tablosuna yazılır.

## API Endpoint'leri
- `GET /health`
  - Sunucu ayakta mı kontrolü
- `GET /vehicle-count`
  - En son kaydı döner (hiç kayıt yoksa `{ count: 0, camera_id: null, timestamp: null }`)
- `GET /history?limit=100`
  - Son N kaydı döner (varsayılan limit: 50, önerilen: 100)

> Not: `POST /vehicle-count` endpoint'i projede hâlâ mevcut olabilir (geriye dönük uyumluluk için), ancak bu tasarımda gerekli değildir.

## Çalıştırma (Local)
Geliştirme modunda (otomatik restart):

```bash
npm install
npm run dev
```

