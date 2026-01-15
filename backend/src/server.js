'use strict';

// Load environment variables
require('dotenv').config();

const express = require('express');
const cors = require('cors');
const { initDb, getDb } = require('./db');

const app = express();

function envInt(name, fallback) {
  const raw = process.env[name];
  if (raw == null || String(raw).trim() === '') return fallback;
  const n = parseInt(String(raw), 10);
  return Number.isFinite(n) ? n : fallback;
}

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

async function readRawCount(url) {
  // Node.js 18+ has global fetch.
  if (typeof fetch !== 'function') {
    throw new Error(
      'Global fetch is not available. Please use Node.js 18+ (LTS) or add a fetch polyfill.'
    );
  }

  const resp = await fetch(url, {
    method: 'GET',
    headers: { 'Accept': 'text/plain, */*' },
  });
  if (!resp.ok) {
    const body = await resp.text().catch(() => '');
    throw new Error(`RAW_COUNT_URL HTTP ${resp.status}: ${body}`);
  }
  const rawText = (await resp.text()).trim();
  const count = parseInt(rawText, 10);
  if (!Number.isFinite(count)) {
    throw new Error(`RAW_COUNT_URL invalid body: "${rawText}"`);
  }
  return count;
}

function startStablePoller() {
  const RAW_COUNT_URL =
    process.env.RAW_COUNT_URL || 'http://192.248.154.28/carcount';
  const POLL_INTERVAL_MS = envInt('POLL_INTERVAL_MS', 1000);
  const STABLE_SECONDS = envInt('STABLE_SECONDS', 5);
  const CAMERA_ID = envInt('CAMERA_ID', 1);

  const db = getDb();

  let lastRawCount = null;
  let sameCountStreak = 0;
  let lastStableCount = null;
  let pollInFlight = false;
  let consecutiveErrors = 0;

  const tick = async () => {
    if (pollInFlight) return;
    pollInFlight = true;
    try {
      const rawCount = await readRawCount(RAW_COUNT_URL);

      if (lastRawCount === rawCount) {
        sameCountStreak += 1;
      } else {
        lastRawCount = rawCount;
        sameCountStreak = 1;
      }

      // "stabil": aynı değer 1 saniyelik örneklerle en az STABLE_SECONDS sürsün
      if (sameCountStreak >= STABLE_SECONDS && lastStableCount !== rawCount) {
        const timestamp = new Date().toISOString();
        const sql =
          'INSERT INTO vehicle_logs (camera_id, count, timestamp) VALUES (?, ?, ?)';
        db.run(sql, [CAMERA_ID, rawCount, timestamp], (err) => {
          if (err) {
            console.error('[poller] DB insert error:', err.message);
            return;
          }
          lastStableCount = rawCount;
          console.log(
            `[poller] stable=${rawCount} camera_id=${CAMERA_ID} ts=${timestamp}`
          );
        });
      }

      if (consecutiveErrors > 0) {
        console.warn('[poller] recovered after errors:', consecutiveErrors);
      }
      consecutiveErrors = 0;
    } catch (e) {
      consecutiveErrors += 1;
      // Hata log spam'ini azalt: ilk hatayı ve her 10. hatayı logla
      if (consecutiveErrors === 1 || consecutiveErrors % 10 === 0) {
        console.error('[poller] error:', e && e.message ? e.message : e);
      }
    } finally {
      pollInFlight = false;
    }
  };

  // Küçük bir jitter ile başlat (sunucu açılışıyla aynı anda dış servise yüklenmesin)
  sleep(150).then(tick).catch(() => {});
  const intervalId = setInterval(tick, POLL_INTERVAL_MS);

  console.log(
    `[poller] started: url=${RAW_COUNT_URL} interval=${POLL_INTERVAL_MS}ms stable_seconds=${STABLE_SECONDS} camera_id=${CAMERA_ID}`
  );

  return () => clearInterval(intervalId);
}

// CORS (relaxed for education; explicit methods)
const corsOptions = {
  origin: '*',
  methods: ['GET', 'POST', 'OPTIONS'],
};
app.use(cors(corsOptions));
app.options('*', cors(corsOptions));

// Body parser
app.use(express.json());

// Health endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

// POST /vehicle-count
// Body: { "camera_id": number, "count": number }
app.post('/vehicle-count', (req, res) => {
  const { camera_id, count } = req.body || {};

  // Basic validation
  if (
    camera_id === undefined ||
    count === undefined ||
    typeof camera_id !== 'number' ||
    typeof count !== 'number' ||
    Number.isNaN(camera_id) ||
    Number.isNaN(count)
  ) {
    return res.status(400).json({
      success: false,
      error: 'Invalid body. Expecting numeric camera_id and count.',
    });
  }

  const timestamp = new Date().toISOString();
  const db = getDb();
  const sql =
    'INSERT INTO vehicle_logs (camera_id, count, timestamp) VALUES (?, ?, ?)';
  const params = [camera_id, count, timestamp];

  db.run(sql, params, function (err) {
    if (err) {
      return res.status(500).json({
        success: false,
        error: 'Database error: ' + err.message,
      });
    }
    return res.status(201).json({
      success: true,
      id: this.lastID,
    });
  });
});

// GET /vehicle-count
// Returns latest record by timestamp, or defaults if none
app.get('/vehicle-count', (req, res) => {
  const db = getDb();
  const sql =
    'SELECT camera_id, count, timestamp FROM vehicle_logs ORDER BY timestamp DESC LIMIT 1';
  db.get(sql, [], (err, row) => {
    if (err) {
      return res.status(500).json({ error: 'Internal server error' });
    }
    if (!row) {
      return res.json({ count: 0, camera_id: null, timestamp: null });
    }
    return res.json({
      count: row.count,
      camera_id: row.camera_id,
      timestamp: row.timestamp,
    });
  });
});

// GET /history?limit=50
// Returns latest N rows ordered by timestamp DESC
app.get('/history', (req, res) => {
  const db = getDb();
  const rawLimit = parseInt(String(req.query.limit ?? ''), 10);
  const limit = Number.isFinite(rawLimit) && rawLimit > 0 ? rawLimit : 50;
  const sql =
    'SELECT id, camera_id, count, timestamp FROM vehicle_logs ORDER BY timestamp DESC LIMIT ?';
  db.all(sql, [limit], (err, rows) => {
    if (err) {
      return res.status(500).json({ error: 'Internal server error' });
    }
    return res.json({ history: rows ?? [] });
  });
});

// DELETE /history
// Clears all history rows (vehicle_logs)
app.delete('/history', (req, res) => {
  const db = getDb();
  db.serialize(() => {
    db.run('DELETE FROM vehicle_logs', [], function (err) {
      if (err) {
        return res.status(500).json({ error: 'Internal server error' });
      }
      // Optional: reset autoincrement counter (best-effort)
      db.run("DELETE FROM sqlite_sequence WHERE name='vehicle_logs'", [], () => {
        return res.json({ success: true, deleted: this.changes ?? 0 });
      });
    });
  });
});

// Global error handler (unexpected errors)
// eslint-disable-next-line no-unused-vars
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ error: 'Internal server error' });
});

const PORT = process.env.PORT || 3001;

// Initialize DB, then start server
initDb()
  .then(() => {
    // Start jitter filter + stable poller
    const stopPoller = startStablePoller();
    process.on('SIGINT', () => {
      try {
        stopPoller();
      } catch (_) {}
      process.exit(0);
    });
    process.on('SIGTERM', () => {
      try {
        stopPoller();
      } catch (_) {}
      process.exit(0);
    });

    app.listen(PORT, () => {
      console.log(`Backend API listening on http://localhost:${PORT}`);
    });
  })
  .catch((err) => {
    console.error('Failed to initialize database:', err);
    process.exit(1);
  });


