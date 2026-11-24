'use strict';

/** فك ملف النسخة الاحتياطية إلى مستندات Firestore. منفصل عن restore.js
 *  عشان يتاختبر بـ stub بدون تثبيت firebase-admin. */

const fs = require('fs');
const zlib = require('zlib');

function readBackup(file) {
  const bytes = fs.readFileSync(file);
  const raw = file.endsWith('.gz') ? zlib.gunzipSync(bytes) : bytes;
  const backup = JSON.parse(raw.toString('utf8'));
  if (backup.format !== 'hesba-shop-backup') {
    throw new Error('الملف ليس نسخة احتياطية لتطبيق حسبة');
  }
  if (backup.schemaVersion !== 1) {
    throw new Error(`إصدار النسخة ${backup.schemaVersion} غير مدعوم (المتوقع 1)`);
  }
  if (!Array.isArray(backup.docs)) {
    throw new Error('النسخة لا تحتوي على قائمة docs');
  }
  return backup;
}

function makeDecoder(admin, { skipRoots = new Set() } = {}) {
  function decodeValue(value) {
    if (value === null || typeof value !== 'object') return value;
    if (Array.isArray(value)) return value.map(decodeValue);

    if (value.__type === 'timestamp') {
      return new admin.firestore.Timestamp(Number(value.s), Number(value.ns || 0));
    }
    if (value.__type === 'ref') {
      return admin.firestore().doc(String(value.path));
    }
    if (value.__type === 'geo') {
      return new admin.firestore.GeoPoint(Number(value.lat), Number(value.lng));
    }

    const out = {};
    for (const [key, child] of Object.entries(value)) {
      out[key] = decodeValue(child);
    }
    return out;
  }

  function decodeDocs(backup) {
    const docs = [];
    for (const entry of backup.docs) {
      const docPath = entry && entry.__doc && entry.__doc.path;
      if (typeof docPath !== 'string' || docPath.length === 0) {
        throw new Error('أحد المستندات ليس له __doc.path');
      }
      const segments = docPath.split('/');
      if (segments.length % 2 !== 0 || segments.some((s) => s.length === 0)) {
        throw new Error(`مسار مستند غير صالح: ${docPath}`);
      }
      if (skipRoots.has(segments[0])) continue;
      docs.push({ path: docPath, data: decodeValue(entry.data || {}) });
    }
    return docs;
  }

  return { decodeValue, decodeDocs };
}

module.exports = { readBackup, makeDecoder };
