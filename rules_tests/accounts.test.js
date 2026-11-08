// Firestore emulator tests — الحسابات (persons / debts / debts/*/payments).
//
// Runs ONLY against the local emulator (firebase emulators:exec), never
// against production, and never deploys anything.
//
//   firebase emulators:exec --only firestore --project hesba-business \
//     "node --test --test-concurrency=1 rules_tests/accounts.test.js"
//
// Covered:
//   A. persons — unified contacts (customer/supplier/both): create/read/
//      update/delete, structure validation, shop isolation, subscription
//      gating, admin-only delete.
//   B. debts   — ذمم العملاء والموردين: create (valid structure, person
//      must live in the same shop), amounts sane, customer always
//      receivable, payment-update-only writes (paidAmount monotonic and
//      bounded by amount), no client delete, cross-shop isolation.
//   C. payments — debts/{id}/payments: immutable ledger (no update/
//      delete), amount bounded by the debt's remaining balance, creator-
//      only recording, full transaction flow (set payment + increment
//      paidAmount) as the app does it.

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
  updateDoc,
  deleteDoc,
  getDoc,
  getDocs,
  query,
  where,
  serverTimestamp,
  runTransaction,
} from 'firebase/firestore';

const rulesPath = path.join(
  path.dirname(fileURLToPath(import.meta.url)),
  '..',
  'firestore.rules',
);

let env;

async function seed(fn) {
  return env.withSecurityRulesDisabled(async (ctx) => {
    await fn(ctx.firestore());
  });
}

function activeSubscription() {
  return {
    status: 'active',
    suspended: false,
    startDate: new Date(Date.now() - 24 * 3600 * 1000),
    endDate: new Date(Date.now() + 30 * 24 * 3600 * 1000),
    isTrial: false,
  };
}

// ما تكتبه `AccountsRepoImpl.addDebt` عند إنشاء شخص جديد.
function personPayload(docId, ownerId, shopId, extra = {}) {
  return {
    id: docId,
    ownerId,
    shopId,
    name: 'عميل تجريبي',
    phone: '01001112223',
    normalizedPhone: '01001112223',
    type: 'customer',
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    ...extra,
  };
}

// ما تكتبه `AccountsRepoImpl.addDebt` للذمة.
function debtPayload(docId, ownerId, shopId, personId, extra = {}) {
  return {
    id: docId,
    ownerId,
    shopId,
    personId,
    personName: 'عميل تجريبي',
    personPhone: '01001112223',
    partyType: 'customer',
    direction: 'receivable',
    amount: 1000,
    paidAmount: 0,
    note: '',
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    ...extra,
  };
}

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
    // u1/shop1 + u1b/shop1: اشتراكات فعالة.
    await setDoc(doc(db, 'users/u1'), { role: 'owner', shopId: 'shop1' });
    await setDoc(doc(db, 'users/u1/subscription/current'), activeSubscription());
    await setDoc(doc(db, 'users/u1b'), { role: 'owner', shopId: 'shop1' });
    await setDoc(doc(db, 'users/u1b/subscription/current'), activeSubscription());
    // u2/shop2.
    await setDoc(doc(db, 'users/u2'), { role: 'owner', shopId: 'shop2' });
    await setDoc(doc(db, 'users/u2/subscription/current'), activeSubscription());
    // u3/shop3: بدون اشتراك.
    await setDoc(doc(db, 'users/u3'), { role: 'owner', shopId: 'shop3' });
    await setDoc(doc(db, 'users/admin1'), { role: 'admin' });

    // ── persons ─────────────────────────────────
    await setDoc(doc(db, 'persons/p1'),
      personPayload('p1', 'u1', 'shop1', {
        name: 'عميل 1', type: 'customer', createdAt: new Date(), updatedAt: new Date(),
      }));
    await setDoc(doc(db, 'persons/p2'),
      personPayload('p2', 'u2', 'shop2', {
        name: 'مورد 2', type: 'supplier', createdAt: new Date(), updatedAt: new Date(),
      }));
    // شخص مورد عند shop1 (للذمم عليّ/ليّا).
    await setDoc(doc(db, 'persons/psup'),
      personPayload('psup', 'u1', 'shop1', {
        name: 'مورد الجملة', type: 'supplier', createdAt: new Date(), updatedAt: new Date(),
      }));

    // ── debts ───────────────────────────────────
    await setDoc(doc(db, 'debts/d1'),
      debtPayload('d1', 'u1', 'shop1', 'p1', {
        amount: 1000, paidAmount: 0, createdAt: new Date(), updatedAt: new Date(),
      }));
    await setDoc(doc(db, 'debts/d2'),
      debtPayload('d2', 'u1', 'shop1', 'psup', {
        partyType: 'supplier', direction: 'payable',
        personName: 'مورد الجملة', amount: 5000, paidAmount: 1500,
        createdAt: new Date(), updatedAt: new Date(),
      }));
    await setDoc(doc(db, 'debts/d3'),
      debtPayload('d3', 'u2', 'shop2', 'p2', {
        personName: 'مورد 2', partyType: 'supplier', direction: 'receivable',
        amount: 800, paidAmount: 0, createdAt: new Date(), updatedAt: new Date(),
      }));
  });
});

// ────────────────────────────────────────────────
// A. persons
// ────────────────────────────────────────────────

test('A1. owner creates a valid person (customer)', async () => {
  const u1 = env.authenticatedContext('u1');
  await assertSucceeds(
    setDoc(doc(u1.firestore(), 'persons/new1'),
      personPayload('new1', 'u1', 'shop1', { type: 'customer' })),
  );
});

test('A2. guest cannot create a person', async () => {
  const guest = env.unauthenticatedContext();
  await assertFails(
    setDoc(doc(guest.firestore(), 'persons/new1'),
      personPayload('new1', 'u1', 'shop1')),
  );
});

test('A3. structure enforced (name/phone/type)', async () => {
  const u1 = env.authenticatedContext('u1');
  const base = personPayload('x', 'u1', 'shop1');
  await assertFails(setDoc(doc(u1.firestore(), 'persons/a'), { ...base, name: '' }));
  await assertFails(setDoc(doc(u1.firestore(), 'persons/b'), { ...base, name: '   ' }));
  await assertFails(setDoc(doc(u1.firestore(), 'persons/c'), { ...base, phone: '123' }));
  await assertFails(setDoc(doc(u1.firestore(), 'persons/d'), { ...base, phone: 'not-a-phone' }));
  // نوع غير معروف.
  await assertFails(setDoc(doc(u1.firestore(), 'persons/e'), { ...base, type: 'vip' }));
  await assertFails(setDoc(doc(u1.firestore(), 'persons/f'), { ...base, notes: 42 }));
});

test('A4. ownership fields must match the caller and document id', async () => {
  const u1 = env.authenticatedContext('u1');
  await assertFails(
    setDoc(doc(u1.firestore(), 'persons/a'), personPayload('a', 'u1', 'shop2')));
  await assertFails(
    setDoc(doc(u1.firestore(), 'persons/b'), personPayload('b', 'u2', 'shop1')));
  await assertFails(
    setDoc(doc(u1.firestore(), 'persons/c'),
      personPayload('c', 'u1', 'shop1', { id: 'other-id' })));
});

test('A5. timestamps are server-owned (back-dating rejected)', async () => {
  const u1 = env.authenticatedContext('u1');
  await assertFails(
    setDoc(doc(u1.firestore(), 'persons/a'), {
      ...personPayload('a', 'u1', 'shop1'),
      createdAt: new Date(Date.now() - 365 * 24 * 3600 * 1000),
    }),
  );
});

test('A6. no-subscription shop cannot create; reads stay open', async () => {
  const u3 = env.authenticatedContext('u3');
  await assertFails(
    setDoc(doc(u3.firestore(), 'persons/new1'),
      personPayload('new1', 'u3', 'shop3')),
  );
  const u1 = env.authenticatedContext('u1');
  await assertSucceeds(getDoc(doc(u1.firestore(), 'persons/p1')));
});

test('A7. cross-shop read denied; coworker of the shop can read', async () => {
  const u2 = env.authenticatedContext('u2');
  await assertFails(getDoc(doc(u2.firestore(), 'persons/p1')));
  const u1b = env.authenticatedContext('u1b');
  await assertSucceeds(getDoc(doc(u1b.firestore(), 'persons/p1')));
});

test('A8. list queries must pin shopId', async () => {
  const u1 = env.authenticatedContext('u1');
  await assertSucceeds(getDocs(
    query(collection(u1.firestore(), 'persons'), where('shopId', '==', 'shop1'))));
  await assertFails(getDocs(
    query(collection(u1.firestore(), 'persons'), where('shopId', '==', 'shop2'))));
});

test('A9. owner updates editable fields; ownership fields frozen', async () => {
  const u1 = env.authenticatedContext('u1');
  await assertSucceeds(
    updateDoc(doc(u1.firestore(), 'persons/p1'), { name: 'عميل معدّل' }));
  await assertFails(
    updateDoc(doc(u1.firestore(), 'persons/p1'), { ownerId: 'u2' }));
  await assertFails(
    updateDoc(doc(u1.firestore(), 'persons/p1'), { shopId: 'shop2' }));
  await assertFails(
    updateDoc(doc(u1.firestore(), 'persons/p1'), { id: 'other' }));
});

test('A10. delete is admin-only (owners cannot delete history)', async () => {
  const u1 = env.authenticatedContext('u1');
  await assertFails(deleteDoc(doc(u1.firestore(), 'persons/p1')));
  const admin = env.authenticatedContext('admin1');
  await assertSucceeds(deleteDoc(doc(admin.firestore(), 'persons/p1')));
});

// ────────────────────────────────────────────────
// B. debts
// ────────────────────────────────────────────────

test('B1. owner creates a valid customer debt (receivable)', async () => {
  const u1 = env.authenticatedContext('u1');
  await assertSucceeds(
    setDoc(doc(u1.firestore(), 'debts/new1'), debtPayload('new1', 'u1', 'shop1', 'p1')));
});

test('B2. guest cannot create a debt', async () => {
  const guest = env.unauthenticatedContext();
  await assertFails(
    setDoc(doc(guest.firestore(), 'debts/new1'), debtPayload('new1', 'u1', 'shop1', 'p1')));
});

test('B3. amount must be positive; paidAmount starts at 0', async () => {
  const u1 = env.authenticatedContext('u1');
  const base = debtPayload('x', 'u1', 'shop1', 'p1');
  await assertFails(setDoc(doc(u1.firestore(), 'debts/a'), { ...base, amount: 0 }));
  await assertFails(setDoc(doc(u1.firestore(), 'debts/b'), { ...base, amount: -50 }));
  await assertFails(setDoc(doc(u1.firestore(), 'debts/c'), { ...base, paidAmount: 10 }));
  await assertFails(setDoc(doc(u1.firestore(), 'debts/d'), { ...base, paidAmount: -1 }));
});

test('B4. customer debts are always receivable', async () => {
  const u1 = env.authenticatedContext('u1');
  await assertFails(
    setDoc(doc(u1.firestore(), 'debts/a'),
      debtPayload('a', 'u1', 'shop1', 'p1', { direction: 'payable' })));
  // مورد بأي اتجاه — مسموح.
  await assertSucceeds(
    setDoc(doc(u1.firestore(), 'debts/b'),
      debtPayload('b', 'u1', 'shop1', 'psup', {
        partyType: 'supplier', direction: 'payable',
        personName: 'مورد الجملة',
      })));
  await assertSucceeds(
    setDoc(doc(u1.firestore(), 'debts/c'),
      debtPayload('c', 'u1', 'shop1', 'psup', {
        partyType: 'supplier', direction: 'receivable',
        personName: 'مورد الجملة',
      })));
});

test('B5. personId must reference a person in the SAME shop', async () => {
  const u1 = env.authenticatedContext('u1');
  // شخص من محل آخر — مرفوض.
  await assertFails(
    setDoc(doc(u1.firestore(), 'debts/a'),
      debtPayload('a', 'u1', 'shop1', 'p2', { personName: 'مورد 2' })));
  // شخص غير موجود — مرفوض.
  await assertFails(
    setDoc(doc(u1.firestore(), 'debts/b'),
      debtPayload('b', 'u1', 'shop1', 'does-not-exist')));
});

test('B6. timestamps are server-owned', async () => {
  const u1 = env.authenticatedContext('u1');
  await assertFails(
    setDoc(doc(u1.firestore(), 'debts/a'), {
      ...debtPayload('a', 'u1', 'shop1', 'p1'),
      createdAt: new Date(Date.now() - 365 * 24 * 3600 * 1000),
    }),
  );
});

test('B7. no-subscription shop cannot create; reads stay open', async () => {
  const u3 = env.authenticatedContext('u3');
  await assertFails(
    setDoc(doc(u3.firestore(), 'debts/new1'),
      debtPayload('new1', 'u3', 'shop3', 'x')));
  const u1 = env.authenticatedContext('u1');
  await assertSucceeds(getDoc(doc(u1.firestore(), 'debts/d1')));
});

test('B8. cross-shop read denied', async () => {
  const u2 = env.authenticatedContext('u2');
  await assertFails(getDoc(doc(u2.firestore(), 'debts/d1')));
});

test('B9. payment update: only paidAmount/updatedAt, monotonic, bounded', async () => {
  const u1 = env.authenticatedContext('u1');
  // سداد جزئي — مسموح.
  await assertSucceeds(
    updateDoc(doc(u1.firestore(), 'debts/d1'), { paidAmount: 400, updatedAt: serverTimestamp() }));
  // سداد كامل — مسموح.
  await assertSucceeds(
    updateDoc(doc(u1.firestore(), 'debts/d1'), { paidAmount: 1000, updatedAt: serverTimestamp() }));
  // تجاوز الأصل — مرفوض.
  await assertFails(
    updateDoc(doc(u1.firestore(), 'debts/d1'), { paidAmount: 1500, updatedAt: serverTimestamp() }));
  // نقص المدفوع — مرفوض (على d2 حيث paidAmount=1500).
  await assertFails(
    updateDoc(doc(u1.firestore(), 'debts/d2'), { paidAmount: 1000, updatedAt: serverTimestamp() }));
  // أي حقل آخر — مرفوض.
  await assertFails(
    updateDoc(doc(u1.firestore(), 'debts/d1'), { amount: 2000, updatedAt: serverTimestamp() }));
  await assertFails(
    updateDoc(doc(u1.firestore(), 'debts/d1'), { personName: 'اسم آخر', updatedAt: serverTimestamp() }));
});

test('B10. client cannot delete a debt; admin can', async () => {
  const u1 = env.authenticatedContext('u1');
  await assertFails(deleteDoc(doc(u1.firestore(), 'debts/d1')));
  const u2 = env.authenticatedContext('u2');
  await assertFails(deleteDoc(doc(u2.firestore(), 'debts/d1')));
  const admin = env.authenticatedContext('admin1');
  await assertSucceeds(deleteDoc(doc(admin.firestore(), 'debts/d1')));
});

test('B11. list queries must pin shopId', async () => {
  const u1 = env.authenticatedContext('u1');
  await assertSucceeds(getDocs(
    query(collection(u1.firestore(), 'debts'), where('shopId', '==', 'shop1'))));
  await assertFails(getDocs(
    query(collection(u1.firestore(), 'debts'), where('shopId', '==', 'shop2'))));
});

// ────────────────────────────────────────────────
// C. debts/{id}/payments
// ────────────────────────────────────────────────

test('C1. payment within remaining balance is allowed', async () => {
  const u1 = env.authenticatedContext('u1');
  await assertSucceeds(
    setDoc(doc(u1.firestore(), 'debts/d1/payments/pay1'), {
      id: 'pay1',
      ownerId: 'u1',
      shopId: 'shop1',
      amount: 400,
      note: 'دفعة أولى',
      createdAt: serverTimestamp(),
    }));
});

test('C2. payment above remaining balance is rejected', async () => {
  const u1 = env.authenticatedContext('u1');
  // d1 متبقي = 1000 → 1500 مرفوضة.
  await assertFails(
    setDoc(doc(u1.firestore(), 'debts/d1/payments/pay1'), {
      id: 'pay1', ownerId: 'u1', shopId: 'shop1',
      amount: 1500, note: '', createdAt: serverTimestamp(),
    }));
  // d2 متبقي = 3500 → 4000 مرفوضة.
  await assertFails(
    setDoc(doc(u1.firestore(), 'debts/d2/payments/pay2'), {
      id: 'pay2', ownerId: 'u1', shopId: 'shop1',
      amount: 4000, note: '', createdAt: serverTimestamp(),
    }));
});

test('C3. coworker of the shop cannot record a payment on someone else’s debt', async () => {
  const u1b = env.authenticatedContext('u1b');
  await assertFails(
    setDoc(doc(u1b.firestore(), 'debts/d1/payments/pay1'), {
      id: 'pay1', ownerId: 'u1b', shopId: 'shop1',
      amount: 100, note: '', createdAt: serverTimestamp(),
    }));
});

test('C4. payment on another shop’s debt is rejected', async () => {
  const u2 = env.authenticatedContext('u2');
  await assertFails(
    setDoc(doc(u2.firestore(), 'debts/d1/payments/pay1'), {
      id: 'pay1', ownerId: 'u2', shopId: 'shop2',
      amount: 100, note: '', createdAt: serverTimestamp(),
    }));
});

test('C5. payments are an immutable ledger (no update, no delete)', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'debts/d1/payments/pay1'), {
      id: 'pay1', ownerId: 'u1', shopId: 'shop1',
      amount: 400, note: '', createdAt: new Date(),
    });
  });
  const u1 = env.authenticatedContext('u1');
  await assertFails(
    updateDoc(doc(u1.firestore(), 'debts/d1/payments/pay1'), { amount: 200 }));
  await assertFails(deleteDoc(doc(u1.firestore(), 'debts/d1/payments/pay1')));
  const admin = env.authenticatedContext('admin1');
  await assertFails(deleteDoc(doc(admin.firestore(), 'debts/d1/payments/pay1')));
});

test('C6. payment reads are shop-scoped', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'debts/d1/payments/pay1'), {
      id: 'pay1', ownerId: 'u1', shopId: 'shop1',
      amount: 400, note: '', createdAt: new Date(),
    });
  });
  const u1 = env.authenticatedContext('u1');
  const u1b = env.authenticatedContext('u1b');
  const u2 = env.authenticatedContext('u2');
  await assertSucceeds(getDocs(collection(u1.firestore(), 'debts/d1/payments')));
  await assertSucceeds(getDocs(collection(u1b.firestore(), 'debts/d1/payments')));
  await assertFails(getDocs(collection(u2.firestore(), 'debts/d1/payments')));
});

test('C7. full transaction: record payment + increment paidAmount', async () => {
  const u1 = env.authenticatedContext('u1');
  const db = u1.firestore();
  await assertSucceeds(runTransaction(db, async (txn) => {
    const debtRef = doc(db, 'debts/d1');
    const snap = await txn.get(debtRef);
    const data = snap.data();
    const remaining = data.amount - data.paidAmount;
    if (200 > remaining) throw new Error('too much');
    const payRef = doc(collection(db, 'debts/d1/payments'));
    txn.set(payRef, {
      id: payRef.id,
      ownerId: 'u1',
      shopId: 'shop1',
      amount: 200,
      note: 'دفعة جزئية',
      createdAt: serverTimestamp(),
    });
    txn.update(debtRef, {
      paidAmount: data.paidAmount + 200,
      updatedAt: serverTimestamp(),
    });
  }));
});

test('C8. over-payment transaction is rejected atomically', async () => {
  const u1 = env.authenticatedContext('u1');
  const db = u1.firestore();
  await assertFails(runTransaction(db, async (txn) => {
    const debtRef = doc(db, 'debts/d1');
    const snap = await txn.get(debtRef);
    const data = snap.data();
    const payRef = doc(collection(db, 'debts/d1/payments'));
    txn.set(payRef, {
      id: payRef.id,
      ownerId: 'u1',
      shopId: 'shop1',
      amount: 2000, // أكبر من المتبقي (1000)
      note: '',
      createdAt: serverTimestamp(),
    });
    txn.update(debtRef, {
      paidAmount: data.paidAmount + 2000,
      updatedAt: serverTimestamp(),
    });
  }));
});
