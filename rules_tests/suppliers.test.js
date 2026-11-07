// Firestore emulator tests — suppliers (الموردون) + product↔supplier refs.
//
// Runs ONLY against the local emulator (firebase emulators:exec), never
// against production, and never deploys anything.
//
//   firebase emulators:exec --only firestore --project hesba-business \
//     "node --test --test-concurrency=1 rules_tests/suppliers.test.js"
//
// Covered:
//   A. suppliers — own-shop create/read/update/delete, structure validation
//      (name/phone required + bounded, ids immutable), cross-shop isolation,
//      no-subscription write gating, admin override, list queries scoped by
//      shopId.
//   B. products  — supplier references must point at an existing supplier of
//      the SAME shop, supplierId/supplierName clear together, legacy docs
//      without supplier fields still work.
//
// Notes on rules behaviour these tests rely on:
//   - a regular user CANNOT read a missing doc (resource.data is null →
//     denied), so absence is asserted through shop-scoped queries;
//   - list queries must constrain `shopId` (the read rule only proves
//     sameShop when the query pins it down);
//   - `createdAt`/`updatedAt` on create are client `serverTimestamp()`s,
//     which the rules compare against `request.time`.

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

// Exactly what `SuppliersRepoImpl.addSupplier` writes for a new supplier.
function supplierPayload(docId, ownerId, shopId, extra = {}) {
  return {
    id: docId,
    ownerId,
    shopId,
    name: 'مورد الاختبار',
    phone: '01001112223',
    companyName: '',
    secondaryPhone: '',
    email: '',
    address: '',
    city: '',
    notes: '',
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    ...extra,
  };
}

// Exactly what `SuppliersRepoImpl.updateSupplier` writes (partial fields
// + server updatedAt — ownership fields are never in the payload).
function supplierUpdate(extra = {}) {
  return { ...extra, updatedAt: serverTimestamp() };
}

// A minimal product that satisfies `validProduct()` (price > 0, no
// negative numbers). `supplierId`/`supplierName` default to null, which
// is how `Product.toJson()` writes "no supplier".
function productPayload(ownerId, shopId, extra = {}) {
  return {
    ownerId,
    shopId,
    name: 'منتج الاختبار',
    code: '',
    category: '',
    price: 50,
    costPrice: 10,
    stock: 5,
    lowStockThreshold: 2,
    isActive: true,
    size: '',
    color: '',
    notes: '',
    imageUrl: '',
    supplierId: null,
    supplierName: null,
    createdAt: new Date(),
    updatedAt: new Date(),
    ...extra,
  };
}

// Clone `obj` without the given keys (for "required field missing" cases,
// where `undefined` would be rejected by the SDK before rules ever run).
function without(obj, ...keys) {
  const copy = { ...obj };
  for (const k of keys) delete copy[k];
  return copy;
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
    // u1/shop1 + u2/shop2: live subscriptions (writes allowed).
    // u3/shop3: deliberately NO subscription (gating test).
    // u1b/shop1: coworker of the same shop (reads ok, creator-writes no).
    await setDoc(doc(db, 'users/u1'), { role: 'owner', shopId: 'shop1' });
    await setDoc(doc(db, 'users/u1/subscription/current'), activeSubscription());
    await setDoc(doc(db, 'users/u1b'), { role: 'owner', shopId: 'shop1' });
    await setDoc(doc(db, 'users/u1b/subscription/current'), activeSubscription());
    await setDoc(doc(db, 'users/u2'), { role: 'owner', shopId: 'shop2' });
    await setDoc(doc(db, 'users/u2/subscription/current'), activeSubscription());
    await setDoc(doc(db, 'users/u3'), { role: 'owner', shopId: 'shop3' });
    await setDoc(doc(db, 'users/admin1'), { role: 'admin' });

    // ── suppliers ────────────────────────────────────────────
    await setDoc(doc(db, 'suppliers/s1'),
      supplierPayload('s1', 'u1', 'shop1', { name: 'مورد 1', phone: '01001112223' }));
    await setDoc(doc(db, 'suppliers/s2'),
      supplierPayload('s2', 'u2', 'shop2', { name: 'مورد 2', phone: '01111112222' }));

    // ── products ─────────────────────────────────────────────
    // p1: no supplier at all (legacy shape has no supplier keys).
    await setDoc(doc(db, 'products/p1'),
      productPayload('u1', 'shop1', { name: 'منتج بدون مورد' }));
    // p2: linked to s1 (same shop).
    await setDoc(doc(db, 'products/p2'), productPayload('u1', 'shop1', {
      name: 'منتج بمرتبط',
      supplierId: 's1',
      supplierName: 'مورد 1',
    }));
    // p3: another shop's product (isolation checks).
    await setDoc(doc(db, 'products/p3'),
      productPayload('u2', 'shop2', { name: 'منتج محل آخر' }));
  });
});

// ═══════════════════════════════════════════════════════════
// A. suppliers
// ═══════════════════════════════════════════════════════════

test('1. owner creates a valid supplier in their own shop', async () => {
  const u1 = env.authenticatedContext('u1');
  await assertSucceeds(
    setDoc(doc(u1.firestore(), 'suppliers/new1'),
      supplierPayload('new1', 'u1', 'shop1')),
  );
});

test('2. guest cannot create a supplier', async () => {
  const guest = env.unauthenticatedContext();
  await assertFails(
    setDoc(doc(guest.firestore(), 'suppliers/new1'),
      supplierPayload('new1', 'u1', 'shop1')),
  );
});

test('3. required fields are enforced (name + phone)', async () => {
  const u1 = env.authenticatedContext('u1');
  const base = supplierPayload('new1', 'u1', 'shop1');
  // Missing key entirely.
  await assertFails(setDoc(doc(u1.firestore(), 'suppliers/a'), without(base, 'name')));
  await assertFails(setDoc(doc(u1.firestore(), 'suppliers/b'), without(base, 'phone')));
  // Empty / whitespace-only name.
  await assertFails(
    setDoc(doc(u1.firestore(), 'suppliers/c'), { ...base, name: '' }),
  );
  await assertFails(
    setDoc(doc(u1.firestore(), 'suppliers/d'), { ...base, name: '   ' }),
  );
  // Empty phone, too-short phone, non-dialable phone.
  await assertFails(
    setDoc(doc(u1.firestore(), 'suppliers/e'), { ...base, phone: '' }),
  );
  await assertFails(
    setDoc(doc(u1.firestore(), 'suppliers/f'), { ...base, phone: '12345' }),
  );
  await assertFails(
    setDoc(doc(u1.firestore(), 'suppliers/g'), { ...base, phone: 'not-a-phone' }),
  );
  // Wrong types for optional fields.
  await assertFails(
    setDoc(doc(u1.firestore(), 'suppliers/h'), { ...base, notes: 42 }),
  );
});

test('4. ownership fields must match the caller and the document id', async () => {
  const u1 = env.authenticatedContext('u1');
  // shopId of another shop.
  await assertFails(
    setDoc(doc(u1.firestore(), 'suppliers/a'),
      supplierPayload('a', 'u1', 'shop2')),
  );
  // ownerId of another user.
  await assertFails(
    setDoc(doc(u1.firestore(), 'suppliers/b'),
      supplierPayload('b', 'u2', 'shop1')),
  );
  // id that does not match the document id.
  await assertFails(
    setDoc(doc(u1.firestore(), 'suppliers/c'),
      supplierPayload('c', 'u1', 'shop1', { id: 'some-other-id' })),
  );
  // No shop at all on the account (u3 has shop3 but no subscription;
  // use a forged shopId that does not belong to u1).
  await assertFails(
    setDoc(doc(u1.firestore(), 'suppliers/d'),
      supplierPayload('d', 'u1', 'shop3')),
  );
});

test('5. timestamps are server-owned (back-dating is rejected)', async () => {
  const u1 = env.authenticatedContext('u1');
  await assertFails(
    setDoc(doc(u1.firestore(), 'suppliers/a'), {
      ...supplierPayload('a', 'u1', 'shop1'),
      createdAt: new Date(Date.now() - 365 * 24 * 3600 * 1000),
    }),
  );
});

test('6. write requires a live subscription (u3 has none)', async () => {
  const u3 = env.authenticatedContext('u3');
  await assertFails(
    setDoc(doc(u3.firestore(), 'suppliers/new1'),
      supplierPayload('new1', 'u3', 'shop3')),
  );
  // Reads stay open for expired/no-subscription shops.
  const u1 = env.authenticatedContext('u1');
  await assertSucceeds(getDoc(doc(u1.firestore(), 'suppliers/s1')));
});

test('7. owner reads own supplier; cross-shop single read is denied', async () => {
  const u1 = env.authenticatedContext('u1');
  const u2 = env.authenticatedContext('u2');
  await assertSucceeds(getDoc(doc(u1.firestore(), 'suppliers/s1')));
  // u2 belongs to shop2 → cannot read shop1's supplier directly.
  await assertFails(getDoc(doc(u2.firestore(), 'suppliers/s1')));
  // Guest cannot read either.
  const guest = env.unauthenticatedContext();
  await assertFails(getDoc(doc(guest.firestore(), 'suppliers/s1')));
});

test('8. list queries are shop-scoped (shopId pinned)', async () => {
  const u1 = env.authenticatedContext('u1');
  const u2 = env.authenticatedContext('u2');
  // Own shop: allowed.
  await assertSucceeds(getDocs(
    query(collection(u1.firestore(), 'suppliers'),
      where('shopId', '==', 'shop1'))));
  // Another shop's suppliers: denied (no proof of sameShop/ownerId).
  await assertFails(getDocs(
    query(collection(u1.firestore(), 'suppliers'),
      where('shopId', '==', 'shop2'))));
  // u2 querying shop1 is denied too.
  await assertFails(getDocs(
    query(collection(u2.firestore(), 'suppliers'),
      where('shopId', '==', 'shop1'))));
});

test('9. owner updates editable fields of their own supplier', async () => {
  const u1 = env.authenticatedContext('u1');
  await assertSucceeds(
    updateDoc(doc(u1.firestore(), 'suppliers/s1'), supplierUpdate({
      name: 'مورد 1 (محدّث)',
      notes: 'ملاحظة جديدة',
    })),
  );
  // A partial update (notes only — what the details screen saves).
  await assertSucceeds(
    updateDoc(doc(u1.firestore(), 'suppliers/s1'), supplierUpdate({
      notes: 'ملاحظات',
    })),
  );
});

test('10. ownership / id / createdAt can never be changed by a client', async () => {
  const u1 = env.authenticatedContext('u1');
  await assertFails(
    updateDoc(doc(u1.firestore(), 'suppliers/s1'), supplierUpdate({ ownerId: 'u2' })),
  );
  await assertFails(
    updateDoc(doc(u1.firestore(), 'suppliers/s1'), supplierUpdate({ shopId: 'shop2' })),
  );
  await assertFails(
    updateDoc(doc(u1.firestore(), 'suppliers/s1'), supplierUpdate({ id: 'other' })),
  );
  await assertFails(
    updateDoc(doc(u1.firestore(), 'suppliers/s1'),
      supplierUpdate({ createdAt: new Date() })),
  );
});

test('11. cross-shop update / delete are denied', async () => {
  const u2 = env.authenticatedContext('u2');
  await assertFails(
    updateDoc(doc(u2.firestore(), 'suppliers/s1'), supplierUpdate({ name: 'هكّاك' })),
  );
  await assertFails(deleteDoc(doc(u2.firestore(), 'suppliers/s1')));
});

test('12. same-shop coworker may READ but not modify another creator\'s supplier', async () => {
  const u1b = env.authenticatedContext('u1b');
  await assertSucceeds(getDoc(doc(u1b.firestore(), 'suppliers/s1')));
  await assertFails(
    updateDoc(doc(u1b.firestore(), 'suppliers/s1'), supplierUpdate({ name: 'X' })),
  );
  await assertFails(deleteDoc(doc(u1b.firestore(), 'suppliers/s1')));
});

test('13. owner deletes own supplier; guest cannot delete', async () => {
  const guest = env.unauthenticatedContext();
  await assertFails(deleteDoc(doc(guest.firestore(), 'suppliers/s1')));
  const u1 = env.authenticatedContext('u1');
  await assertSucceeds(deleteDoc(doc(u1.firestore(), 'suppliers/s1')));
  // Gone for everyone in the shop (query returns nothing).
  const ownQuery = query(collection(u1.firestore(), 'suppliers'),
    where('shopId', '==', 'shop1'));
  await assertSucceeds(getDocs(ownQuery));
  assert.equal((await getDocs(ownQuery)).size, 0);
});

test('14. no-subscription shop cannot update or delete', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'suppliers/s3'),
      supplierPayload('s3', 'u3', 'shop3', { name: 'مورد 3' }));
  });
  const u3 = env.authenticatedContext('u3');
  await assertFails(
    updateDoc(doc(u3.firestore(), 'suppliers/s3'), supplierUpdate({ name: 'X' })),
  );
  await assertFails(deleteDoc(doc(u3.firestore(), 'suppliers/s3')));
});

test('15. admin may update and delete any shop\'s supplier', async () => {
  const admin = env.authenticatedContext('admin1');
  await assertSucceeds(
    updateDoc(doc(admin.firestore(), 'suppliers/s1'),
      { name: 'تصحيح الإدارة', updatedAt: serverTimestamp() }),
  );
  await assertSucceeds(deleteDoc(doc(admin.firestore(), 'suppliers/s2')));
  // Admin reads are open too.
  await assertSucceeds(getDoc(doc(admin.firestore(), 'suppliers/s1')));
});

// ═══════════════════════════════════════════════════════════
// B. products ↔ suppliers
// ═══════════════════════════════════════════════════════════

test('16. product may reference a supplier of the SAME shop', async () => {
  const u1 = env.authenticatedContext('u1');
  await assertSucceeds(
    setDoc(doc(u1.firestore(), 'products/ok1'), productPayload('u1', 'shop1', {
      supplierId: 's1',
      supplierName: 'مورد 1',
    })),
  );
});

test('17. product may NOT reference another shop\'s supplier', async () => {
  const u1 = env.authenticatedContext('u1');
  await assertFails(
    setDoc(doc(u1.firestore(), 'products/bad1'), productPayload('u1', 'shop1', {
      supplierId: 's2', // lives in shop2
      supplierName: 'مورد 2',
    })),
  );
  // u2 referencing shop1's supplier is denied as well.
  const u2 = env.authenticatedContext('u2');
  await assertFails(
    setDoc(doc(u2.firestore(), 'products/bad2'), productPayload('u2', 'shop2', {
      supplierId: 's1',
      supplierName: 'مورد 1',
    })),
  );
});

test('18. product may NOT reference a non-existent supplier', async () => {
  const u1 = env.authenticatedContext('u1');
  await assertFails(
    setDoc(doc(u1.firestore(), 'products/bad3'), productPayload('u1', 'shop1', {
      supplierId: 'does-not-exist',
      supplierName: 'أشباح',
    })),
  );
});

test('19. supplierId and supplierName are cleared together', async () => {
  const u1 = env.authenticatedContext('u1');
  // id without name → rejected.
  await assertFails(
    setDoc(doc(u1.firestore(), 'products/bad4'), productPayload('u1', 'shop1', {
      supplierId: 's1',
      supplierName: null,
    })),
  );
  // name without id → rejected.
  await assertFails(
    setDoc(doc(u1.firestore(), 'products/bad5'), productPayload('u1', 'shop1', {
      supplierId: null,
      supplierName: 'مورد 1',
    })),
  );
  // both null → accepted (this is "no supplier").
  await assertSucceeds(
    setDoc(doc(u1.firestore(), 'products/ok2'), productPayload('u1', 'shop1')),
  );
});

test('20. legacy products without supplier fields can be updated', async () => {
  const u1 = env.authenticatedContext('u1');
  // p1 was seeded without supplierId/supplierName keys at all.
  await assertSucceeds(
    updateDoc(doc(u1.firestore(), 'products/p1'), { notes: 'تعديل' }),
  );
  // Linking it to a valid same-shop supplier afterwards works.
  await assertSucceeds(
    updateDoc(doc(u1.firestore(), 'products/p1'), {
      supplierId: 's1',
      supplierName: 'مورد 1',
    }),
  );
  // Clearing the supplier again works (both null).
  await assertSucceeds(
    updateDoc(doc(u1.firestore(), 'products/p1'), {
      supplierId: null,
      supplierName: null,
    }),
  );
  // Leaving one half behind is rejected.
  await assertFails(
    updateDoc(doc(u1.firestore(), 'products/p1'), { supplierId: 's1' }),
  );
});

test('21. linked-products query is shop-scoped', async () => {
  const u1 = env.authenticatedContext('u1');
  const u2 = env.authenticatedContext('u2');
  // where(shopId) + where(supplierId): provable → allowed.
  await assertSucceeds(getDocs(
    query(collection(u1.firestore(), 'products'),
      where('shopId', '==', 'shop1'),
      where('supplierId', '==', 's1'))));
  // Same shape against another shop: denied.
  await assertFails(getDocs(
    query(collection(u2.firestore(), 'products'),
      where('shopId', '==', 'shop1'),
      where('supplierId', '==', 's1'))));
  // supplierId alone (no shopId) cannot be proven → denied.
  await assertFails(getDocs(
    query(collection(u1.firestore(), 'products'),
      where('supplierId', '==', 's1'))));
});

test('22. another shop cannot update the linked product either', async () => {
  const u2 = env.authenticatedContext('u2');
  await assertFails(
    updateDoc(doc(u2.firestore(), 'products/p2'), { notes: 'X' }),
  );
  const u1 = env.authenticatedContext('u1');
  await assertSucceeds(
    updateDoc(doc(u1.firestore(), 'products/p2'), { notes: 'X' }),
  );
});
