// Firestore emulator tests — report pagination, isolation, period filtering.
//
// Runs ONLY against the local emulator (firebase emulators:exec), never
// against production, and never deploys anything.
//
//   firebase emulators:exec --only firestore --project hesba-business \
//     "node --test --test-concurrency=1 rules_tests/rules.test.js rules_tests/pagination.test.js"
//
// Mirrors the Dart report fetch in `sales_repo_impl/returns_repo_impl/
// expenses_repo_impl` (where shopId == + orderBy createdAt DESC + limit(300)
// + startAfterDocument) and the period filter in `ReportsState`:
//   inRange(dt) = !dt.isBefore(start) && dt.isBefore(endExclusive)

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { test, before, after, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} from '@firebase/rules-unit-testing';
import {
  collection,
  doc,
  setDoc,
  query,
  where,
  orderBy,
  limit,
  startAfter,
  getDocs,
  writeBatch,
} from 'firebase/firestore';

const rulesPath = path.join(
  path.dirname(fileURLToPath(import.meta.url)),
  '..',
  'firestore.rules',
);

const PAGE_SIZE = 300; // kReportPageSize in lib/core/utils/paged_fetch.dart

let env;

function dbOf(ctx) {
  return ctx.firestore();
}

async function seed(fn) {
  return env.withSecurityRulesDisabled(async (ctx) => fn(ctx.firestore()));
}

function saleDoc(i, shopId, createdAt, extra = {}) {
  return {
    saleId: `sale-${shopId}-${i}`,
    ownerId: shopId === 'shop1' ? 'u1' : 'u2',
    shopId,
    items: [
      {
        productId: `p${i % 7}`,
        productName: `منتج ${i % 7}`,
        quantity: 1,
        unitPrice: 50,
        total: 50,
        costPrice: 20,
      },
    ],
    subtotal: 50,
    discount: 0,
    total: 50,
    paymentMethod: 'cash',
    note: '',
    createdAt,
    ...extra,
  };
}

function expenseDoc(i, shopId, date, createdAt = date) {
  return {
    expenseId: `exp-${shopId}-${i}`,
    ownerId: shopId === 'shop1' ? 'u1' : 'u2',
    shopId,
    shopName: 'Shop',
    title: `مصروف ${i}`,
    category: 'تشغيل',
    amount: 10,
    note: '',
    date,
    createdAt,
    ...{},
  };
}

/** Writes docs in batches of 400 (under Firestore's 500/batch limit). */
async function seedCollection(db, colName, docs) {
  for (let i = 0; i < docs.length; i += 400) {
    const batch = writeBatch(db);
    for (const d of docs.slice(i, i + 400)) {
      batch.set(doc(db, colName, d.id), d.data);
    }
    await batch.commit();
  }
}

/** The exact paged fetch the Dart repos perform. */
async function fetchAllPaged(db, colName, shopId, pageSize = PAGE_SIZE) {
  const all = [];
  const cursors = [];
  let cursor = null;
  for (;;) {
    cursors.push(cursor);
    let q = query(
      collection(db, colName),
      where('shopId', '==', shopId),
      orderBy('createdAt', 'desc'),
      limit(pageSize),
    );
    if (cursor) q = query(q, startAfter(cursor));
    const snap = await getDocs(q);
    all.push(...snap.docs);
    if (snap.docs.length < pageSize) break;
    cursor = snap.docs[snap.docs.length - 1];
  }
  return { docs: all, cursors };
}

const JAN_START = new Date('2026-01-01T00:00:00Z');
const FEB_START = new Date('2026-02-01T00:00:00Z');

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'hesba-business',
    firestore: { rules: fs.readFileSync(rulesPath, 'utf8') },
  });
});

after(async () => {
  await env.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
  await seed(async (db) => {
    await setDoc(doc(db, 'users/u1'), { role: 'owner', shopId: 'shop1' });
    await setDoc(doc(db, 'users/u2'), { role: 'owner', shopId: 'shop2' });

    // 350 sales for shop1: 100 inside Jan 2026, 250 outside it.
    const sales1 = [];
    for (let i = 0; i < 350; i++) {
      const inJan = i < 100;
      const createdAt = inJan
        ? new Date(Date.UTC(2026, 0, 1 + (i % 28), 12, 0, 0))
        : new Date(Date.UTC(2025, 5 + (i % 6), 1 + (i % 28), 12, 0, 0));
      sales1.push({ id: `sale-shop1-${i}`, data: saleDoc(i, 'shop1', createdAt) });
    }
    await seedCollection(db, 'sales', sales1);

    // 40 sales for shop2 (different owner — must never leak into shop1).
    const sales2 = [];
    for (let i = 0; i < 40; i++) {
      sales2.push({
        id: `sale-shop2-${i}`,
        data: saleDoc(i, 'shop2', new Date(Date.UTC(2026, 0, 5, 12, 0, 0))),
      });
    }
    await seedCollection(db, 'sales', sales2);

    // 320 expenses for shop1: 40 inside Jan 2026 (by `date`), 280 outside.
    const expenses = [];
    for (let i = 0; i < 320; i++) {
      const inJan = i < 40;
      const date = inJan
        ? new Date(Date.UTC(2026, 0, 2 + (i % 20), 12, 0, 0))
        : new Date(Date.UTC(2025, 3 + (i % 8), 1 + (i % 28), 12, 0, 0));
      // createdAt can differ from `date` (expense entered late) — pushed
      // 40 days later so it falls OUTSIDE January for the filter test.
      const createdAt = new Date(date.getTime() + 40 * 86400000);
      expenses.push({
        id: `exp-shop1-${i}`,
        data: expenseDoc(i, 'shop1', date, createdAt),
      });
    }
    await seedCollection(db, 'expenses', expenses);
  });
});

// ── Pagination: completeness, uniqueness, ordering ───────────────────────

test('350 sales fetch completely across 2 pages (>300, no silent cap)', async () => {
  const alice = env.authenticatedContext('u1');
  const { docs, cursors } = await fetchAllPaged(dbOf(alice), 'sales', 'shop1');

  assert.equal(docs.length, 350); // old code stopped at 300
  assert.equal(new Set(docs.map((d) => d.id)).size, 350); // no duplicates
  assert.equal(cursors[0], null); // first page starts at the beginning
  // Strictly descending createdAt across the page boundary.
  for (let i = 1; i < docs.length; i++) {
    assert.ok(
      toDate(docs[i - 1].data().createdAt) >= toDate(docs[i].data().createdAt),
      `order broken at ${i}`,
    );
  }
});

test('320 expenses fetch completely across 2 pages', async () => {
  const alice = env.authenticatedContext('u1');
  const { docs } = await fetchAllPaged(dbOf(alice), 'expenses', 'shop1');
  assert.equal(docs.length, 320);
  assert.equal(new Set(docs.map((d) => d.id)).size, 320);
});

test('totals over all pages equal ground truth (independent of paging)', async () => {
  const alice = env.authenticatedContext('u1');
  const { docs } = await fetchAllPaged(dbOf(alice), 'sales', 'shop1');
  const pagedTotal = docs.reduce((s, d) => s + d.data().total, 0);

  let truth = null;
  await seed(async (db) => {
    const snap = await getDocs(
      query(collection(db, 'sales'), where('shopId', '==', 'shop1')),
    );
    truth = snap.docs.reduce((s, d) => s + d.data().total, 0);
  });

  assert.equal(pagedTotal, truth);
  assert.equal(pagedTotal, 350 * 50); // 17 500 — nothing dropped
});

test('page size 100 still yields the same complete set (cursor robustness)', async () => {
  const alice = env.authenticatedContext('u1');
  const { docs } = await fetchAllPaged(dbOf(alice), 'sales', 'shop1', 100);
  assert.equal(docs.length, 350);
  assert.equal(new Set(docs.map((d) => d.id)).size, 350);
});

// ── Owner/shop isolation ─────────────────────────────────────────────────

test('u1 can page through own shop sales', async () => {
  const alice = env.authenticatedContext('u1');
  await assertSucceeds(fetchAllPaged(dbOf(alice), 'sales', 'shop1'));
});

test('u1 cannot read another shop sales (scoped query fails)', async () => {
  const alice = env.authenticatedContext('u1');
  await assertFails(fetchAllPaged(dbOf(alice), 'sales', 'shop2'));
});

test('u1 cannot run an unscoped sales query', async () => {
  const alice = env.authenticatedContext('u1');
  await assertFails(
    getDocs(query(collection(dbOf(alice), 'sales'), orderBy('createdAt', 'desc'))),
  );
});

test('u2 cannot page through shop1 expenses', async () => {
  const bob = env.authenticatedContext('u2');
  await assertFails(fetchAllPaged(dbOf(bob), 'expenses', 'shop1'));
});

test('signed-out user cannot read anything', async () => {
  const anon = env.unauthenticatedContext();
  await assertFails(fetchAllPaged(dbOf(anon), 'sales', 'shop1'));
});

// ── Client-side period filtering (mirrors ReportsState/Calculator) ───────

/** Firestore returns Timestamps — convert to JS Date like the Dart side. */
const toDate = (ts) => ts.toDate();

test('period filter [Jan 2026, Feb 2026) matches seeded counts exactly', async () => {
  const alice = env.authenticatedContext('u1');
  const { docs: sales } = await fetchAllPaged(dbOf(alice), 'sales', 'shop1');
  const { docs: expenses } = await fetchAllPaged(dbOf(alice), 'expenses', 'shop1');

  // Same boundary semantics as Dart: !dt.isBefore(start) && dt.isBefore(end).
  const inRange = (dt) => dt >= JAN_START && dt < FEB_START;

  const inRangeSales = sales.filter((d) => inRange(toDate(d.data().createdAt)));
  const inRangeExpenses = expenses.filter((d) => inRange(toDate(d.data().date)));

  assert.equal(inRangeSales.length, 100);
  assert.equal(inRangeExpenses.length, 40);

  // Revenue from the filtered set — complete, not page-local.
  assert.equal(
    inRangeSales.reduce((s, d) => s + d.data().total, 0),
    100 * 50,
  );
  assert.equal(
    inRangeExpenses.reduce((s, d) => s + d.data().amount, 0),
    40 * 10,
  );
});

test('expense period filter uses `date`, not `createdAt`', async () => {
  const alice = env.authenticatedContext('u1');
  const { docs: expenses } = await fetchAllPaged(dbOf(alice), 'expenses', 'shop1');

  const inRange = (dt) => dt >= JAN_START && dt < FEB_START;
  const byDate = expenses.filter((d) => inRange(toDate(d.data().date))).length;
  const byCreatedAt = expenses.filter((d) =>
    inRange(toDate(d.data().createdAt)),
  ).length;

  assert.equal(byDate, 40);
  // createdAt is shifted +1 day from `date`, so the two filters differ —
  // confirming the app must filter by `date` (its documented convention).
  assert.notEqual(byDate, byCreatedAt);
});
