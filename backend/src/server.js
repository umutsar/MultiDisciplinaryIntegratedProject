'use strict';

// Load environment variables
require('dotenv').config();

const express = require('express');
const cors = require('cors');
const { initDb, getDb } = require('./db');

const app = express();

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
    app.listen(PORT, () => {
      console.log(`Backend API listening on http://localhost:${PORT}`);
    });
  })
  .catch((err) => {
    console.error('Failed to initialize database:', err);
    process.exit(1);
  });


