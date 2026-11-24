'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const os = require('os');
const path = require('path');
const zlib = require('zlib');

const { readBackup, makeDecoder } = require('./transformer');

class FakeTimestamp {
  constructor(seconds, nanoseconds) {
    this.seconds = seconds;
    this.nanoseconds = nanoseconds;
  }
}
class FakeGeoPoint {
  constructor(latitude, longitude) {
    this.latitude = latitude;
    this.longitude = longitude;
  }
}

const firestoreFn = () => ({
  doc: (p) => ({ __ref: true, path: p }),
});
firestoreFn.Timestamp = FakeTimestamp;
firestoreFn.GeoPoint = FakeGeoPoint;
const fakeAdmin = { firestore: firestoreFn };

const fixture = {
  format: 'hesba-shop-backup',
  schemaVersion: 1,
  app: 'hesba',
  exportedAt: '2026-11-23T12:00:00.000Z',
  shopId: 'shop-1',
  ownerUid: 'uid-1',
  fromCache: false,
  counts: { sales: 1 },
  docs: [
    {
      __doc: { path: 'sales/sale-1' },
      data: {
        saleId: 'sale-1',
        total: 12.5,
        createdAt: { __type: 'timestamp', s: 1763904000, ns: 123000000 },
        items: [
          { name: 'x', price: 2 },
          { name: 'y', price: 3 },
        ],
        shop: { __type: 'ref', path: 'shops/shop-1' },
        location: { __type: 'geo', lat: 30.0, lng: 31.0 },
      },
    },
    {
      __doc: { path: 'debts/debt-1/payments/pay-1' },
      data: { amount: 5, createdAt: { __type: 'timestamp', s: 1, ns: 0 } },
    },
    {
      __doc: { path: 'admin_settings/settings' },
      data: { trialDays: 7 },
    },
  ],
};

function writeFixture(contents, gz) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'hesba-backup-'));
  const file = path.join(dir, gz ? 'backup.json.gz' : 'backup.json');
  const raw = Buffer.from(JSON.stringify(contents), 'utf8');
  fs.writeFileSync(file, gz ? zlib.gzipSync(raw) : raw);
  return file;
}

test('readBackup يقرأ الملف العادي والمضغوط بنفس النتيجة', () => {
  const plain = readBackup(writeFixture(fixture, false));
  const gz = readBackup(writeFixture(fixture, true));
  assert.deepEqual(plain, fixture);
  assert.deepEqual(gz, fixture);
});

test('readBackup يرفض صيغة غير صحيحة أو إصداراً غير مدعوم', () => {
  assert.throws(() => readBackup(writeFixture({ format: 'other' }, false)));
  assert.throws(() =>
    readBackup(writeFixture({ ...fixture, schemaVersion: 99 }, false)),
  );
});

test('decodeValue يحوّل الـ wrappers ويحفظ القيم العادية', () => {
  const { decodeValue } = makeDecoder(fakeAdmin);
  const value = decodeValue(fixture.docs[0].data);

  assert.equal(value.saleId, 'sale-1');
  assert.equal(value.total, 12.5);
  assert.ok(value.createdAt instanceof FakeTimestamp);
  assert.equal(value.createdAt.seconds, 1763904000);
  assert.equal(value.createdAt.nanoseconds, 123000000);
  assert.equal(value.items.length, 2);
  assert.equal(value.items[1].price, 3);
  assert.deepEqual(value.shop, { __ref: true, path: 'shops/shop-1' });
  assert.ok(value.location instanceof FakeGeoPoint);
  assert.equal(value.location.latitude, 30.0);
});

test('decodeDocs يحفظ المسارات الأصلية بما فيها الـ subcollections', () => {
  const { decodeDocs } = makeDecoder(fakeAdmin);
  const docs = decodeDocs(fixture);

  assert.deepEqual(
    docs.map((d) => d.path),
    ['sales/sale-1', 'debts/debt-1/payments/pay-1', 'admin_settings/settings'],
  );
  assert.equal(docs[0].data.saleId, 'sale-1');
});

test('skipRoots يستبعد المجموعات المطلوبة', () => {
  const { decodeDocs } = makeDecoder(fakeAdmin, {
    skipRoots: new Set(['admin_settings', 'debts']),
  });
  const docs = decodeDocs(fixture);
  assert.deepEqual(
    docs.map((d) => d.path),
    ['sales/sale-1'],
  );
});

test('decodeDocs يرفض مساراً غير صالح', () => {
  const { decodeDocs } = makeDecoder(fakeAdmin);
  assert.throws(() =>
    decodeDocs({
      docs: [{ __doc: { path: 'sales' }, data: {} }],
    }),
  );
});
