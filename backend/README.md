# Backend (Express + SQLite) — AI Vehicle Counter

Bu klasör, projenin **backend API** kısmıdır. Express ile çalışır ve veriyi SQLite dosyasına yazar.

## Gereksinimler
- Node.js (LTS önerilir)
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

Örnek (değerleri kendinize göre yazın):

```bash
PORT=3001
DATABASE_FILE=/var/lib/ai-vehicle-counter/vehicle_counter.db
```

> Not: Uygulama, `DATABASE_FILE` içindeki dizin yoksa otomatik oluşturur.

## API Endpoint'leri
- `GET /health`
  - Sunucu ayakta mı kontrolü
- `POST /vehicle-count`
  - Body: `{ "camera_id": number, "count": number }`
  - DB'ye kayıt ekler
- `GET /vehicle-count`
  - En son kaydı döner (hiç kayıt yoksa `{ count: 0, camera_id: null, timestamp: null }`)
- `GET /history?limit=50`
  - Son N kaydı döner (varsayılan limit: 50)

## Çalıştırma (Local)
Geliştirme modunda (otomatik restart):

```bash
npm install
npm run dev
```

