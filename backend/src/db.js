'use strict';

const fs = require('fs');
const path = require('path');
const sqlite3 = require('sqlite3').verbose();

const DEFAULT_DB_FILE = process.env.DATABASE_FILE || path.join(__dirname, '..', 'data', 'vehicle_counter.db');

let dbInstance = null;

function ensureDataDir(dbFilePath) {
  const dir = path.dirname(dbFilePath);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
}

/**
 * Returns a singleton sqlite3 Database connection.
 */
function getDb() {
  if (dbInstance) return dbInstance;
  ensureDataDir(DEFAULT_DB_FILE);
  dbInstance = new sqlite3.Database(DEFAULT_DB_FILE);
  return dbInstance;
}

/**
 * Initializes database schema if it does not exist.
 * Creates the vehicle_logs table based on PRD.
 */
function initDb() {
  return new Promise((resolve, reject) => {
    const db = getDb();
    db.serialize(() => {
      db.run(
        `CREATE TABLE IF NOT EXISTS vehicle_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          camera_id INTEGER NOT NULL,
          count INTEGER NOT NULL,
          timestamp TEXT NOT NULL
        );`,
        (err) => {
          if (err) return reject(err);
          resolve();
        }
      );
    });
  });
}

module.exports = {
  getDb,
  initDb,
};


