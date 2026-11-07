// Firestore emulator tests — stock replenishment (زيادة المخزون).
//
// Runs ONLY against the local emulator (firebase emulators:exec), never
// against production, and never deploys anything.
//
//   firebase emulators:exec --only firestore --project hesba-business \
//     "node --test --test-concurrency=1 rules_tests/stock_purchase.test.js"
//
// Two layers:
//   A. security rules — own create/read, cross-shop/guest/no-subscription
//      denied, purchases are an immutable audit trail (admin may fix),
//      movement shape validation, list queries scoped by shopId.
//   B. transaction mirror of `StockPurchaseRepoImpl.addPurchase` in JS
//      (pre-check query → reads-before-writes transaction → calculator →
//      atomic writes): weighted-average updates, no partial writes on any
//      failure, duplicate purchaseId never doubles stock, historical sale/
//      return cost snapshots stay untouched, a new sale snapshots the
//      updated average, and a purchase never writes to `expenses`.
//
// Notes on rules behaviour these tests rely on:
//   - a regular user CANNOT read a missing doc (resource.data is null →
//     denied), so absence is asserted through shop-scoped queries;
//   - list queries must constrain `shopId` (the read rule only proves
//     sameShop when the query pins it down).

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
  limit,
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

function productDoc(ownerId, shopId, name, { price, costPrice, stock }) {
  return {
    ownerId,
    shopId,
    name,
    code: '',
    category: '',
    price,
    costPrice,
    stock,
    lowStockThreshold: 2,
    isActive: true,
    size: '',
    color: '',
    notes: '',
    imageUrl: '',
    createdAt: new Date(),
    updatedAt: new Date(),
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
    // ── users ────────────────────────────────────────────────
    // u1/shop1 + u2/shop2: live subscriptions (writes allowed).
    // u3/shop3: deliberately NO subscription (gating test).
    await setDoc(doc(db, 'users/u1'), { role: 'owner', shopId: 'shop1' });
    await setDoc(doc(db, 'users/u1/subscription/current'), activeSubscription());
    await setDoc(doc(db, 'users/u2'), { role: 'owner', shopId: 'shop2' });
    await setDoc(doc(db, 'users/u2/subscription/current'), activeSubscription());
    await setDoc(doc(db, 'users/u3'), { role: 'owner', shopId: 'shop3' });
    await setDoc(doc(db, 'users/admin1'), { role: 'admin' });

    // ── products ─────────────────────────────────────────────
    await setDoc(doc(db, 'products/p1'),
      productDoc('u1', 'shop1', 'منتج 1', { price: 50, costPrice: 10, stock: 5 }));
    await setDoc(doc(db, 'products/p2'),
      productDoc('u1', 'shop1', 'منتج 2', { price: 80, costPrice: 20, stock: 8 }));
    await setDoc(doc(db, 'products/p3'),
      productDoc('u2', 'shop2', 'منتج 3', { price: 30, costPrice: 15, stock: 4 }));
    await setDoc(doc(db, 'products/p4'),
      productDoc('u3', 'shop3', 'منتج 4', { price: 12, costPrice: 6, stock: 3 }));

    // ── historical sale + return (cost snapshot = 7) ─────────
    // These documents must remain byte-identical after purchases.
    await setDoc(doc(db, 'sales/s1'), {
      saleId: 's1',
      ownerId: 'u1',
      shopId: 'shop1',
      items: [
        { productId: 'p1', productName: 'منتج 1', quantity: 2, unitPrice: 50,
          total: 100, costPrice: 7 },
      ],
      subtotal: 100,
      discount: 0,
      total: 100,
      paymentMethod: 'cash',
      note: '',
      createdAt: new Date(Date.now() - 7 * 24 * 3600 * 1000),
    });
    await setDoc(doc(db, 'returns/r1'), {
      returnId: 'r1',
      ownerId: 'u1',
      shopId: 'shop1',
      items: [
        { productId: 'p1', productName: 'منتج 1', quantity: 1, unitPrice: 50,
          total: 50, costPrice: 7 },
      ],
      total: 50,
      reason: '',
      createdAt: new Date(Date.now() - 5 * 24 * 3600 * 1000),
    });
  });
});

// ═══════════════════════════════════════════════════════════
// A. security rules
// ═══════════════════════════════════════════════════════════

function purchasePayload(ownerId, shopId, extra = {}) {
  return {
    purchaseId: 'pp1',
    ownerId,
    shopId,
    supplierName: 'مورد 1',
    supplierPhone: '',
    invoiceNumber: 'INV-1',
    purchaseDate: new Date(),
    totalAmount: 160,
    notes: '',
    items: [
      { productId: 'p1', productName: 'منتج 1', quantity: 5, previousStock: 5,
        newStock: 10, previousCost: 10, purchaseUnitCost: 20,
        newAverageCost: 15, lineTotal: 100 },
    ],
    createdAt: new Date(),
    ...extra,
  };
}

function movementPayload(ownerId, shopId, extra = {}) {
  return {
    movementId: 'mv1',
    ownerId,
    shopId,
    productId: 'p1',
    productName: 'منتج 1',
    movementType: 'purchase',
    quantity: 5,
    previousStock: 5,
    newStock: 10,
    unitCost: 20,
    referenceId: 'pp1',
    createdAt: new Date(),
    ...extra,
  };
}

test('rules: the shop owner can create and read their own purchase', async () => {
  const alice = env.authenticatedContext('u1');
  await assertSucceeds(
    setDoc(doc(alice.firestore(), 'stock_purchases/pp1'), purchasePayload('u1', 'shop1')),
  );
  const snap = await getDoc(doc(alice.firestore(), 'stock_purchases/pp1'));
  assert.equal(snap.exists(), true);
  assert.equal(snap.data().totalAmount, 160);
  assert.equal(snap.data().items.length, 1);
});

test('rules: another shop can neither create nor read (shop isolation)', async () => {
  const alice = env.authenticatedContext('u1');
  const mallory = env.authenticatedContext('u2');
  await assertSucceeds(
    setDoc(doc(alice.firestore(), 'stock_purchases/pp1'), purchasePayload('u1', 'shop1')),
  );
  // u2 writing into shop1 → denied.
  await assertFails(
    setDoc(doc(mallory.firestore(), 'stock_purchases/pp2'),
      purchasePayload('u2', 'shop1')),
  );
  // u2 reading / tampering with shop1's invoice → denied.
  await assertFails(getDoc(doc(mallory.firestore(), 'stock_purchases/pp1')));
  await assertFails(
    setDoc(doc(mallory.firestore(), 'stock_purchases/pp1'),
      purchasePayload('u1', 'shop1', { totalAmount: 1 })),
  );
  await assertFails(deleteDoc(doc(mallory.firestore(), 'stock_purchases/pp1')));
});

test('rules: guests can neither create nor read purchases', async () => {
  const guest = env.unauthenticatedContext();
  await assertFails(
    setDoc(doc(guest.firestore(), 'stock_purchases/pp1'), purchasePayload('u1', 'shop1')),
  );
  await assertFails(getDoc(doc(guest.firestore(), 'stock_purchases/pp1')));
});

test('rules: an invoice with zero items or a negative total is rejected', async () => {
  const alice = env.authenticatedContext('u1');
  await assertFails(
    setDoc(doc(alice.firestore(), 'stock_purchases/empty'),
      purchasePayload('u1', 'shop1', { items: [] })),
  );
  await assertFails(
    setDoc(doc(alice.firestore(), 'stock_purchases/neg'),
      purchasePayload('u1', 'shop1', { totalAmount: -5 })),
  );
});

test('rules: writing shop data without a live subscription is denied', async () => {
  // u3 owns shop3 and its own product, but has no subscription document.
  const u3 = env.authenticatedContext('u3');
  await assertFails(
    setDoc(doc(u3.firestore(), 'stock_purchases/pp3'),
      purchasePayload('u3', 'shop3')),
  );
  await assertFails(
    setDoc(doc(u3.firestore(), 'stock_movements/mv3'),
      movementPayload('u3', 'shop3')),
  );
});

test('rules: purchases are immutable from clients, admin may fix them', async () => {
  const alice = env.authenticatedContext('u1');
  const admin = env.authenticatedContext('admin1');
  await assertSucceeds(
    setDoc(doc(alice.firestore(), 'stock_purchases/pp1'), purchasePayload('u1', 'shop1')),
  );
  // Owner tampering with their own audit record → denied.
  await assertFails(
    setDoc(doc(alice.firestore(), 'stock_purchases/pp1'),
      purchasePayload('u1', 'shop1', { totalAmount: 999 })),
  );
  await assertFails(deleteDoc(doc(alice.firestore(), 'stock_purchases/pp1')));
  // Admin correcting a record → allowed.
  await assertSucceeds(
    setDoc(doc(admin.firestore(), 'stock_purchases/pp1'),
      purchasePayload('u1', 'shop1', { totalAmount: 150 })),
  );
});

test('rules: movement creation validates shape (type, qty, stocks)', async () => {
  const alice = env.authenticatedContext('u1');
  // Valid purchase movement → allowed.
  await assertSucceeds(
    setDoc(doc(alice.firestore(), 'stock_movements/mv1'), movementPayload('u1', 'shop1')),
  );
  // Wrong movement type → denied.
  await assertFails(
    setDoc(doc(alice.firestore(), 'stock_movements/badType'),
      movementPayload('u1', 'shop1', { movementType: 'sale' })),
  );
  // Quantity must be a number > 0.
  await assertFails(
    setDoc(doc(alice.firestore(), 'stock_movements/zeroQty'),
      movementPayload('u1', 'shop1', { quantity: 0 })),
  );
  await assertFails(
    setDoc(doc(alice.firestore(), 'stock_movements/negQty'),
      movementPayload('u1', 'shop1', { quantity: -2 })),
  );
  // previousStock / newStock must be non-negative.
  await assertFails(
    setDoc(doc(alice.firestore(), 'stock_movements/negPrev'),
      movementPayload('u1', 'shop1', { previousStock: -1 })),
  );
  await assertFails(
    setDoc(doc(alice.firestore(), 'stock_movements/negNew'),
      movementPayload('u1', 'shop1', { newStock: -1 })),
  );
  // Another shop writing shop1's movement → denied.
  const mallory = env.authenticatedContext('u2');
  await assertFails(
    setDoc(doc(mallory.firestore(), 'stock_movements/cross'),
      movementPayload('u2', 'shop1')),
  );
  // Guest → denied.
  const guest = env.unauthenticatedContext();
  await assertFails(
    setDoc(doc(guest.firestore(), 'stock_movements/guest'),
      movementPayload('u1', 'shop1')),
  );
});

test('rules: movements are immutable from clients, admin may fix them', async () => {
  const alice = env.authenticatedContext('u1');
  const admin = env.authenticatedContext('admin1');
  await assertSucceeds(
    setDoc(doc(alice.firestore(), 'stock_movements/mv1'), movementPayload('u1', 'shop1')),
  );
  await assertFails(
    updateDoc(doc(alice.firestore(), 'stock_movements/mv1'), { quantity: 99 }),
  );
  await assertFails(deleteDoc(doc(alice.firestore(), 'stock_movements/mv1')));
  await assertSucceeds(
    updateDoc(doc(admin.firestore(), 'stock_movements/mv1'), { unitCost: 21 }),
  );
});

test('rules: purchase list queries are scoped by shopId', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'stock_purchases/a1'), purchasePayload('u1', 'shop1', { purchaseId: 'a1' }));
    await setDoc(doc(db, 'stock_purchases/a2'), purchasePayload('u1', 'shop1', { purchaseId: 'a2' }));
    await setDoc(doc(db, 'stock_purchases/b1'), purchasePayload('u2', 'shop2', { purchaseId: 'b1' }));
  });

  const alice = env.authenticatedContext('u1');
  const mallory = env.authenticatedContext('u2');
  const admin = env.authenticatedContext('admin1');

  // Own shop query → allowed and correctly scoped.
  const mine = await getDocs(
    query(collection(alice.firestore(), 'stock_purchases'), where('shopId', '==', 'shop1')),
  );
  assert.equal(mine.size, 2);
  mine.forEach((d) => assert.equal(d.data().shopId, 'shop1'));

  // Another shop's query → denied (no cross-shop listing).
  await assertFails(getDocs(
    query(collection(alice.firestore(), 'stock_purchases'), where('shopId', '==', 'shop2')),
  ));
  await assertFails(getDocs(
    query(collection(mallory.firestore(), 'stock_purchases'), where('shopId', '==', 'shop1')),
  ));

  // Unconstrained listing → denied for regular users (admin allowed).
  await assertFails(getDocs(collection(alice.firestore(), 'stock_purchases')));
  const all = await getDocs(collection(admin.firestore(), 'stock_purchases'));
  assert.equal(all.size, 3);
});

// ═══════════════════════════════════════════════════════════
// B. purchase transaction (JS mirror of StockPurchaseRepoImpl)
// ═══════════════════════════════════════════════════════════

function roundMoney(value) {
  return Math.round(value * 100) / 100;
}

function computeAverageCost({ currentStock, currentCost, receivedQuantity, purchaseUnitCost }) {
  if (!Number.isFinite(receivedQuantity) || receivedQuantity <= 0) {
    throw new Error('الكمية يجب أن تكون أكبر من صفر');
  }
  if (!Number.isFinite(purchaseUnitCost) || purchaseUnitCost < 0) {
    throw new Error('سعر الشراء غير صالح');
  }
  if (!Number.isFinite(currentStock) || currentStock < 0) {
    throw new Error('المخزون الحالي غير صالح');
  }
  if (!Number.isFinite(currentCost) || currentCost < 0) {
    throw new Error('تكلفة الشراء الحالية غير صالحة');
  }
  if (currentStock === 0) return roundMoney(purchaseUnitCost);
  const totalQuantity = currentStock + receivedQuantity;
  const totalValue = currentStock * currentCost + receivedQuantity * purchaseUnitCost;
  const average = totalValue / totalQuantity;
  if (!Number.isFinite(average)) throw new Error('متوسط سعر الشراء غير صالح');
  return roundMoney(average);
}

function computePurchase(shopId, lines, products) {
  if (!shopId.trim()) throw new Error('لم يتم العثور على المتجر');
  if (lines.length === 0) throw new Error('يجب إضافة منتج واحد على الأقل');

  const seen = new Set();
  const items = [];
  const productUpdates = new Map();
  let totalAmount = 0;

  for (const line of lines) {
    const product = products.get(line.productId);
    const label = product && product.name.trim() ? product.name : line.productId;

    if (!line.productId.trim()) throw new Error('يجب اختيار المنتج');
    if (seen.has(line.productId)) throw new Error(`المنتج مكرر في الفاتورة: ${label}`);
    seen.add(line.productId);
    if (!Number.isFinite(line.quantity) || line.quantity <= 0) {
      throw new Error(`الكمية يجب أن تكون أكبر من صفر: ${label}`);
    }
    if (!Number.isFinite(line.purchaseUnitCost) || line.purchaseUnitCost < 0) {
      throw new Error(`سعر شراء غير صالح: ${label}`);
    }
    if (!product) throw new Error(`المنتج غير موجود: ${label}`);
    if (product.shopId !== shopId) {
      throw new Error(`المنتج لا يتبع هذا المحل: ${product.name}`);
    }
    if (!Number.isFinite(product.stock) || product.stock < 0 ||
        !Number.isFinite(product.costPrice) || product.costPrice < 0) {
      throw new Error(`بيانات المنتج غير صالحة: ${product.name}`);
    }

    const newStock = product.stock + line.quantity;
    if (!Number.isFinite(newStock)) throw new Error('قيمة المخزون الجديد غير صالحة');
    const newAverageCost = computeAverageCost({
      currentStock: product.stock,
      currentCost: product.costPrice,
      receivedQuantity: line.quantity,
      purchaseUnitCost: line.purchaseUnitCost,
    });
    const lineTotal = roundMoney(line.quantity * line.purchaseUnitCost);
    if (!Number.isFinite(lineTotal)) throw new Error(`قيمة السطر غير صالحة: ${product.name}`);

    items.push({
      productId: line.productId,
      productName: product.name,
      quantity: line.quantity,
      previousStock: product.stock,
      newStock,
      previousCost: product.costPrice,
      purchaseUnitCost: line.purchaseUnitCost,
      newAverageCost,
      lineTotal,
    });
    productUpdates.set(line.productId, { productId: line.productId, newStock, newAverageCost });
    totalAmount += lineTotal;
  }

  const total = roundMoney(totalAmount);
  if (!Number.isFinite(total)) throw new Error('إجمالي الفاتورة غير صالح');
  return { items, productUpdates, totalAmount: total };
}

/// Mirrors StockPurchaseRepoImpl.addPurchase:
/// duplicate pre-check query → transaction (all reads first) → calculator →
/// atomic writes (products + purchase + movements).
async function runPurchase(ctx, { purchaseId, shopId, ownerId, lines }) {
  const db = ctx.firestore();

  // 1) duplicate pre-check (query scoped to the shop → allowed by rules).
  const dup = await getDocs(
    query(
      collection(db, 'stock_purchases'),
      where('purchaseId', '==', purchaseId),
      where('shopId', '==', shopId),
      limit(1),
    ),
  );
  if (!dup.empty) {
    throw new Error('الفاتورة محفوظة مسبقاً — لم يتم تكرارها');
  }

  const movementRefs = lines.map(() => doc(collection(db, 'stock_movements')));

  // 2) one atomic transaction.
  return runTransaction(db, async (tx) => {
    const snapshots = new Map();
    for (const line of lines) {
      if (snapshots.has(line.productId)) continue;
      const snap = await tx.get(doc(db, 'products', line.productId));
      // NOTE: in production the rules deny reads of missing docs, so this
      // branch never runs — the whole transaction simply fails (atomic).
      if (!snap.exists()) continue;
      const data = snap.data();
      snapshots.set(line.productId, {
        id: line.productId,
        name: data.name ?? '',
        shopId: data.shopId ?? '',
        stock: data.stock ?? 0,
        costPrice: data.costPrice ?? 0,
      });
    }

    const computed = computePurchase(shopId, lines, snapshots);
    const now = new Date();

    for (const item of computed.items) {
      const upd = computed.productUpdates.get(item.productId);
      tx.update(doc(db, 'products', item.productId), {
        stock: upd.newStock,
        costPrice: upd.newAverageCost,
        updatedAt: now,
      });
    }

    tx.set(doc(db, 'stock_purchases', purchaseId), {
      purchaseId,
      ownerId,
      shopId,
      supplierName: '',
      supplierPhone: '',
      invoiceNumber: '',
      purchaseDate: now,
      totalAmount: computed.totalAmount,
      notes: '',
      items: computed.items,
      createdAt: now,
    });

    computed.items.forEach((item, i) => {
      tx.set(movementRefs[i], {
        movementId: movementRefs[i].id,
        shopId,
        ownerId,
        productId: item.productId,
        productName: item.productName,
        movementType: 'purchase',
        quantity: item.quantity,
        previousStock: item.previousStock,
        newStock: item.newStock,
        unitCost: item.purchaseUnitCost,
        referenceId: purchaseId,
        createdAt: now,
      });
    });

    return computed;
  });
}

async function expectPurchaseDuplicate(promise) {
  let error = null;
  try {
    await promise;
  } catch (e) {
    error = e;
  }
  assert.ok(error, 'كان لازم الإرسال يترفض (فاتورة مكررة)');
  assert.match(String(error?.message ?? error), /محفوظة مسبقاً/);
}

async function snapshotDoc(db, pathStr) {
  const snap = await getDoc(doc(db, pathStr));
  assert.equal(snap.exists(), true, `السجل ناقص: ${pathStr}`);
  return JSON.parse(JSON.stringify(snap.data()));
}

async function countPurchases(db, shopId, purchaseId) {
  const snap = await getDocs(query(
    collection(db, 'stock_purchases'),
    where('shopId', '==', shopId),
    where('purchaseId', '==', purchaseId),
    limit(5),
  ));
  return snap.size;
}

async function countMovements(db, shopId, referenceId = null) {
  const constraints = [where('shopId', '==', shopId)];
  if (referenceId !== null) constraints.push(where('referenceId', '==', referenceId));
  const snap = await getDocs(query(collection(db, 'stock_movements'), ...constraints));
  return snap.size;
}

test('tx: success updates stock + weighted average + invoice + movements', async () => {
  const alice = env.authenticatedContext('u1');
  await runPurchase(alice, {
    purchaseId: 'buy1',
    shopId: 'shop1',
    ownerId: 'u1',
    lines: [
      { productId: 'p1', quantity: 5, purchaseUnitCost: 20 },
      { productId: 'p2', quantity: 2, purchaseUnitCost: 30 },
    ],
  });

  const db = alice.firestore();
  // p1: ((5×10)+(5×20))/10 = 15 ; p2: ((8×20)+(2×30))/10 = 22
  const p1 = (await getDoc(doc(db, 'products/p1'))).data();
  const p2 = (await getDoc(doc(db, 'products/p2'))).data();
  assert.equal(p1.stock, 10);
  assert.equal(p1.costPrice, 15);
  assert.equal(p2.stock, 10);
  assert.equal(p2.costPrice, 22);

  // Invoice with per-item before/after snapshots.
  const invoice = (await getDoc(doc(db, 'stock_purchases/buy1'))).data();
  assert.equal(invoice.totalAmount, 160); // 5×20 + 2×30
  assert.equal(invoice.items.length, 2);
  assert.equal(invoice.items[0].previousStock, 5);
  assert.equal(invoice.items[0].newStock, 10);
  assert.equal(invoice.items[0].previousCost, 10);
  assert.equal(invoice.items[0].newAverageCost, 15);
  assert.equal(invoice.items[0].lineTotal, 100);

  // One movement per product, linked to the invoice.
  assert.equal(await countMovements(db, 'shop1', 'buy1'), 2);
  const movements = await getDocs(query(
    collection(db, 'stock_movements'),
    where('shopId', '==', 'shop1'),
    where('referenceId', '==', 'buy1'),
  ));
  const mvP1 = movements.docs.find((d) => d.data().productId === 'p1').data();
  assert.equal(mvP1.movementType, 'purchase');
  assert.equal(mvP1.previousStock, 5);
  assert.equal(mvP1.newStock, 10);
  assert.equal(mvP1.unitCost, 20);
});

test('tx: missing or foreign product fails the whole transaction (no partial writes)', async () => {
  const alice = env.authenticatedContext('u1');
  const mallory = env.authenticatedContext('u2');
  const db = alice.firestore();

  // (a) one valid line + one nonexistent product.
  await assertFails(runPurchase(alice, {
    purchaseId: 'buyGhost',
    shopId: 'shop1',
    ownerId: 'u1',
    lines: [
      { productId: 'p1', quantity: 5, purchaseUnitCost: 20 },
      { productId: 'ghost', quantity: 1, purchaseUnitCost: 5 },
    ],
  }));
  // (b) one valid line + a product belonging to another shop.
  await assertFails(runPurchase(alice, {
    purchaseId: 'buyForeign',
    shopId: 'shop1',
    ownerId: 'u1',
    lines: [
      { productId: 'p1', quantity: 5, purchaseUnitCost: 20 },
      { productId: 'p3', quantity: 1, purchaseUnitCost: 5 },
    ],
  }));

  // Nothing changed anywhere: products, invoices, movements.
  assert.equal((await getDoc(doc(db, 'products/p1'))).data().stock, 5);
  const p3 = (await getDoc(doc(mallory.firestore(), 'products/p3'))).data();
  assert.equal(p3.stock, 4);
  assert.equal(p3.costPrice, 15);
  assert.equal(await countPurchases(db, 'shop1', 'buyGhost'), 0);
  assert.equal(await countPurchases(db, 'shop1', 'buyForeign'), 0);
  assert.equal(await countMovements(db, 'shop1'), 0);
});

test('tx: a duplicate purchaseId never doubles the stock', async () => {
  const alice = env.authenticatedContext('u1');
  const db = alice.firestore();
  const lines = [{ productId: 'p1', quantity: 5, purchaseUnitCost: 20 }];

  await runPurchase(alice, { purchaseId: 'buy2', shopId: 'shop1', ownerId: 'u1', lines });
  assert.equal((await getDoc(doc(db, 'products/p1'))).data().stock, 10);

  // Same id again (double-tap / lost response) → friendly rejection, no write.
  await expectPurchaseDuplicate(
    runPurchase(alice, { purchaseId: 'buy2', shopId: 'shop1', ownerId: 'u1', lines }),
  );
  assert.equal((await getDoc(doc(db, 'products/p1'))).data().stock, 10); // not 15
  assert.equal(await countPurchases(db, 'shop1', 'buy2'), 1);
  // One line → one movement, still not doubled by the retry.
  assert.equal(await countMovements(db, 'shop1', 'buy2'), 1);
});

test('tx: rules backstop — overwriting an existing invoice as a client fails', async () => {
  const alice = env.authenticatedContext('u1');
  const db = alice.firestore();
  await runPurchase(alice, {
    purchaseId: 'buy3',
    shopId: 'shop1',
    ownerId: 'u1',
    lines: [{ productId: 'p1', quantity: 5, purchaseUnitCost: 20 }],
  });

  // set() on an existing doc = update → admin-only for purchases.
  await assertFails(setDoc(doc(db, 'stock_purchases/buy3'), {
    purchaseId: 'buy3',
    ownerId: 'u1',
    shopId: 'shop1',
    supplierName: '',
    supplierPhone: '',
    invoiceNumber: '',
    purchaseDate: new Date(),
    totalAmount: 999,
    notes: '',
    items: [{ productId: 'p1', quantity: 5 }],
    createdAt: new Date(),
  }));
  const invoice = (await getDoc(doc(db, 'stock_purchases/buy3'))).data();
  assert.equal(invoice.totalAmount, 100); // untouched
});

test('tx: historical sale and return keep their cost snapshots', async () => {
  const alice = env.authenticatedContext('u1');
  const db = alice.firestore();
  const saleBefore = await snapshotDoc(db, 'sales/s1');
  const returnBefore = await snapshotDoc(db, 'returns/r1');

  await runPurchase(alice, {
    purchaseId: 'buy4',
    shopId: 'shop1',
    ownerId: 'u1',
    lines: [{ productId: 'p1', quantity: 5, purchaseUnitCost: 20 }],
  });

  // The purchase changed the product, but never the old documents.
  assert.equal((await getDoc(doc(db, 'products/p1'))).data().costPrice, 15);
  assert.deepEqual(await snapshotDoc(db, 'sales/s1'), saleBefore);
  assert.deepEqual(await snapshotDoc(db, 'returns/r1'), returnBefore);
  assert.equal((await snapshotDoc(db, 'sales/s1')).items[0].costPrice, 7);
  assert.equal((await snapshotDoc(db, 'returns/r1')).items[0].costPrice, 7);
});

test('tx: new sale snapshots the updated average, later purchase never rewrites it', async () => {
  const alice = env.authenticatedContext('u1');
  const db = alice.firestore();
  const oldSale = await snapshotDoc(db, 'sales/s1');
  const oldReturn = await snapshotDoc(db, 'returns/r1');

  // Purchase A: 5 @ 20 on stock 5 @ 10 → average 15.
  await runPurchase(alice, {
    purchaseId: 'buyA',
    shopId: 'shop1',
    ownerId: 'u1',
    lines: [{ productId: 'p1', quantity: 5, purchaseUnitCost: 20 }],
  });

  // A NEW sale stores the updated average as its cost snapshot.
  await assertSucceeds(setDoc(doc(db, 'sales/s2'), {
    saleId: 's2',
    ownerId: 'u1',
    shopId: 'shop1',
    items: [
      { productId: 'p1', productName: 'منتج 1', quantity: 2, unitPrice: 50,
        total: 100, costPrice: 15 },
    ],
    subtotal: 100,
    discount: 0,
    total: 100,
    paymentMethod: 'cash',
    note: '',
    createdAt: new Date(),
  }));

  // Purchase B: 5 @ 25 on stock 10 @ 15 → ((10×15)+(5×25))/15 = 18.33.
  await runPurchase(alice, {
    purchaseId: 'buyB',
    shopId: 'shop1',
    ownerId: 'u1',
    lines: [{ productId: 'p1', quantity: 5, purchaseUnitCost: 25 }],
  });

  const p1 = (await getDoc(doc(db, 'products/p1'))).data();
  assert.equal(p1.stock, 15);
  assert.equal(p1.costPrice, 18.33);

  // Old sale keeps 7, the newer sale keeps 15 (historical COGS stays exact),
  // and the return keeps the original sale's cost.
  const sale1 = await snapshotDoc(db, 'sales/s1');
  const sale2 = await snapshotDoc(db, 'sales/s2');
  assert.equal(sale1.items[0].costPrice, 7);
  assert.equal(sale2.items[0].costPrice, 15);
  assert.deepEqual(sale1, oldSale);
  assert.equal((await snapshotDoc(db, 'returns/r1')).items[0].costPrice, 7);
  assert.deepEqual(await snapshotDoc(db, 'returns/r1'), oldReturn);

  // Reports COGS input: sale1 → 2×7 = 14 ; sale2 → 2×15 = 30 (unchanged).
  assert.equal(sale1.items[0].quantity * sale1.items[0].costPrice, 14);
  assert.equal(sale2.items[0].quantity * sale2.items[0].costPrice, 30);
});

test('tx: a purchase is never written to the expenses collection', async () => {
  const alice = env.authenticatedContext('u1');
  const db = alice.firestore();

  await runPurchase(alice, {
    purchaseId: 'buy5',
    shopId: 'shop1',
    ownerId: 'u1',
    lines: [{ productId: 'p1', quantity: 5, purchaseUnitCost: 20 }],
  });

  // Inventory acquisition is not an operating expense.
  const expenses = await getDocs(
    query(collection(db, 'expenses'), where('shopId', '==', 'shop1')),
  );
  assert.equal(expenses.size, 0);

  // The old sale's cost snapshot is still the COGS source for reports.
  const sale = await snapshotDoc(db, 'sales/s1');
  assert.equal(sale.items[0].costPrice, 7);
});

test('tx: without a live subscription the transaction fails with no partial writes', async () => {
  const u3 = env.authenticatedContext('u3');
  const db = u3.firestore();

  await assertFails(runPurchase(u3, {
    purchaseId: 'buy6',
    shopId: 'shop3',
    ownerId: 'u3',
    lines: [{ productId: 'p4', quantity: 2, purchaseUnitCost: 10 }],
  }));

  assert.equal((await getDoc(doc(db, 'products/p4'))).data().stock, 3);
  assert.equal((await getDoc(doc(db, 'products/p4'))).data().costPrice, 6);
  assert.equal(await countPurchases(db, 'shop3', 'buy6'), 0);
  assert.equal(await countMovements(db, 'shop3'), 0);
});

test('tx: calculator edge cases — zero stock uses the purchase cost, fractional lines round to 2dp', async () => {
  const alice = env.authenticatedContext('u1');
  const db = alice.firestore();

  // A sold-out product (stock = 0) is seeded for the zero-stock branch.
  await seed(async (sdb) => {
    await setDoc(doc(sdb, 'products/p5'),
      productDoc('u1', 'shop1', 'منتج 5', { price: 40, costPrice: 99, stock: 0 }));
  });

  await runPurchase(alice, {
    purchaseId: 'buy7',
    shopId: 'shop1',
    ownerId: 'u1',
    lines: [
      { productId: 'p5', quantity: 6, purchaseUnitCost: 12.5 },
      { productId: 'p2', quantity: 0.5, purchaseUnitCost: 20 },
    ],
  });

  // Zero stock → new average = purchase unit cost (no division by zero).
  const p5 = (await getDoc(doc(db, 'products/p5'))).data();
  assert.equal(p5.stock, 6);
  assert.equal(p5.costPrice, 12.5);

  // Fractional quantities are allowed; line totals and the invoice total
  // round consistently to 2 decimals.
  const p2 = (await getDoc(doc(db, 'products/p2'))).data();
  assert.equal(p2.stock, 8.5);
  assert.equal(p2.costPrice, 20); // ((8×20)+(0.5×20))/8.5 = 20
  const invoice = (await getDoc(doc(db, 'stock_purchases/buy7'))).data();
  assert.equal(invoice.items[1].lineTotal, 10); // 0.5 × 20
  assert.equal(invoice.totalAmount, 85); // 75 + 10
});
