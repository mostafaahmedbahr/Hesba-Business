// Firestore emulator tests — الحساب الفرعي (staff).
//
// Runs ONLY against the local emulator (never production, never deploys):
//  firebase emulators:exec --only firestore --project hesba-business \
//    "node --test --test-concurrency=1 rules_tests/staff.test.js"
//
// يغطي: إنشاء الحساب الفرعي بصلاحية محدودة، منع تصعيد الصلاحية،
// منع قراءة أي بيانات مالية، والسماح بأربع عمليات إدخال فقط،
// واشتراك المحل (لا اشتراك للموظف)، وإيقاف الحساب.

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
  getDoc,
  getDocs,
  query,
  where,
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

function expiredSubscription() {
  return {
    status: 'expired',
    suspended: false,
    startDate: new Date(Date.now() - 60 * 24 * 3600 * 1000),
    endDate: new Date(Date.now() - 30 * 24 * 3600 * 1000),
    isTrial: false,
  };
}

function staffDoc(uid, ownerId, shopId, isActive = true) {
  return {
    uid,
    role: 'staff',
    ownerId,
    shopId,
    shopName: 'Hesba Shop',
    name: 'Employee',
    email: 'staff@hesba.test',
    phone: '01000000000',
    isActive,
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
    await setDoc(doc(db, 'users/u1'), { role: 'owner', shopId: 'shop1', shopName: 'Hesba Shop' });
    await setDoc(doc(db, 'users/u1/subscription/current'), activeSubscription());
    await setDoc(doc(db, 'users/u2'), { role: 'owner', shopId: 'shop2' });
    await setDoc(doc(db, 'users/u2/subscription/current'), activeSubscription());
    await setDoc(doc(db, 'users/s1'), staffDoc('s1', 'u1', 'shop1'));
    await setDoc(doc(db, 'users/s2'), staffDoc('s2', 'u2', 'shop2'));
    await setDoc(doc(db, 'users/admin1'), { role: 'admin' });

    await setDoc(doc(db, 'products/p1'), {
      id: 'p1', ownerId: 'u1', shopId: 'shop1', name: 'Product 1',
      price: 10, costPrice: 6, stock: 20, isActive: true,
      createdAt: new Date(), updatedAt: new Date(),
    });
    await setDoc(doc(db, 'sales/sale1'), {
      id: 'sale1', ownerId: 'u1', shopId: 'shop1', total: 100,
      subtotal: 100, items: [], createdAt: new Date(),
    });
    await setDoc(doc(db, 'expenses/e1'), {
      id: 'e1', ownerId: 'u1', shopId: 'shop1', amount: 50,
      title: 'Rent', createdAt: new Date(),
    });
    await setDoc(doc(db, 'persons/per1'), {
      id: 'per1', ownerId: 'u1', shopId: 'shop1',
      name: 'Customer', phone: '01000000000', type: 'customer',
      createdAt: new Date(), updatedAt: new Date(),
    });
  });
});

// ── 1. صاحب المحل ينشئ حسابًا فرعيًا ────────────────────────────────────
test('1. owner can create a staff account in their own shop', async () => {
  const owner = env.authenticatedContext('u1');
  await assertSucceeds(
    setDoc(doc(owner.firestore(), 'users/s3'), staffDoc('s3', 'u1', 'shop1')),
  );
});

test('2. owner cannot create a staff account in another shop', async () => {
  const owner = env.authenticatedContext('u1');
  await assertFails(
    setDoc(doc(owner.firestore(), 'users/s4'), staffDoc('s4', 'u1', 'shop2')),
  );
});

test('3. nobody can self-grant owner/admin through a new user doc', async () => {
  const other = env.authenticatedContext('s1');
  await assertFails(
    setDoc(doc(other.firestore(), 'users/x1'), {
      ...staffDoc('x1', 'u1', 'shop1'), role: 'admin',
    }),
  );
});

test('4. staff cannot change its own role', async () => {
  const staff = env.authenticatedContext('s1');
  await assertFails(
    updateDoc(doc(staff.firestore(), 'users/s1'), { role: 'owner' }),
  );
});

test('5. owner cannot escalate a staff doc to owner', async () => {
  const owner = env.authenticatedContext('u1');
  await assertFails(
    updateDoc(doc(owner.firestore(), 'users/s1'), { role: 'owner' }),
  );
});

test('6. owner can deactivate a staff account', async () => {
  const owner = env.authenticatedContext('u1');
  await assertSucceeds(
    updateDoc(doc(owner.firestore(), 'users/s1'), { isActive: false }),
  );
});

// ── 2. القراءة: لا بيانات مالية للموظف ──────────────────────────────────
test('7. staff can read the products needed by the entry forms', async () => {
  const staff = env.authenticatedContext('s1');
  await assertSucceeds(getDoc(doc(staff.firestore(), 'products/p1')));
});

test('8. staff can read its own user doc but NOT the owner doc', async () => {
  const staff = env.authenticatedContext('s1');
  await assertSucceeds(getDoc(doc(staff.firestore(), 'users/s1')));
  await assertFails(getDoc(doc(staff.firestore(), 'users/u1')));
});

test('9. staff cannot read expenses / persons / suppliers / debts', async () => {
  const staff = env.authenticatedContext('s1');
  await assertFails(getDoc(doc(staff.firestore(), 'expenses/e1')));
  await assertFails(getDoc(doc(staff.firestore(), 'persons/per1')));
  await assertFails(
    getDocs(query(collection(staff.firestore(), 'suppliers'), where('shopId', '==', 'shop1'))),
  );
  await assertFails(
    getDocs(query(collection(staff.firestore(), 'debts'), where('shopId', '==', 'shop1'))),
  );
});

test('10. staff cannot list stock purchases or movements', async () => {
  const staff = env.authenticatedContext('s1');
  await assertFails(
    getDocs(query(collection(staff.firestore(), 'stock_purchases'), where('shopId', '==', 'shop1'))),
  );
  await assertFails(
    getDocs(query(collection(staff.firestore(), 'stock_movements'), where('shopId', '==', 'shop1'))),
  );
});

test('11. owner can read their staff accounts', async () => {
  const owner = env.authenticatedContext('u1');
  await assertSucceeds(
    getDocs(query(collection(owner.firestore(), 'users'),
      where('ownerId', '==', 'u1'), where('role', '==', 'staff'))),
  );
});

// ── 3. الكتابة: أربع عمليات فقط ────────────────────────────────────────
test('12. staff can create a sale (billed to the owner subscription)', async () => {
  const staff = env.authenticatedContext('s1');
  await assertSucceeds(
    setDoc(doc(staff.firestore(), 'sales/new1'), {
      id: 'new1', ownerId: 's1', shopId: 'shop1', total: 10,
      subtotal: 10, items: [], createdAt: new Date(),
    }),
  );
});

test('13. staff can create an expense but cannot edit/delete it', async () => {
  const staff = env.authenticatedContext('s1');
  await assertSucceeds(
    setDoc(doc(staff.firestore(), 'expenses/new1'), {
      id: 'new1', ownerId: 's1', shopId: 'shop1', amount: 5,
      title: 'Coffee', createdAt: new Date(),
    }),
  );
  await assertFails(
    updateDoc(doc(staff.firestore(), 'expenses/new1'), { amount: 500 }),
  );
});

test('14. staff can write stock purchase + movement', async () => {
  const staff = env.authenticatedContext('s1');
  await assertSucceeds(
    setDoc(doc(staff.firestore(), 'stock_purchases/pur1'), {
      id: 'pur1', ownerId: 's1', shopId: 'shop1',
      items: [{ productId: 'p1', quantity: 2 }], totalAmount: 12,
      createdAt: new Date(),
    }),
  );
  await assertSucceeds(
    setDoc(doc(staff.firestore(), 'stock_movements/m1'), {
      id: 'm1', ownerId: 's1', shopId: 'shop1', productId: 'p1',
      movementType: 'purchase', quantity: 2,
      previousStock: 20, newStock: 22, createdAt: new Date(),
    }),
  );
});

test('15. staff can only touch stock fields on a product', async () => {
  const staff = env.authenticatedContext('s1');
  await assertSucceeds(
    updateDoc(doc(staff.firestore(), 'products/p1'), { stock: 21 }),
  );
  await assertFails(
    updateDoc(doc(staff.firestore(), 'products/p1'), { price: 1 }),
  );
  await assertFails(
    setDoc(doc(staff.firestore(), 'products/newp'), {
      id: 'newp', ownerId: 's1', shopId: 'shop1',
      price: 10, stock: 5, name: 'Smuggled',
    }),
  );
});

test('15b. staff cannot write negative or exaggerated stock', async () => {
  const staff = env.authenticatedContext('s1');
  // قيم سالبة مرفوضة
  await assertFails(updateDoc(doc(staff.firestore(), 'products/p1'), { stock: -1 }));
  await assertFails(updateDoc(doc(staff.firestore(), 'products/p1'), { stock: -1000 }));
  // قيم مبالغ فيها مرفوضة (سقف مطلق مليون وحدة)
  await assertFails(updateDoc(doc(staff.firestore(), 'products/p1'), { stock: 1000001 }));
  await assertFails(updateDoc(doc(staff.firestore(), 'products/p1'), { stock: 1e12 }));
  // زيادة عن الحالي (20) بأكثر من 10,000 وحدة مرفوضة حتى تحت السقف المطلق
  await assertFails(updateDoc(doc(staff.firestore(), 'products/p1'), { stock: 20 + 10001 }));
  // أي نوع غير رقم مرفوض
  await assertFails(updateDoc(doc(staff.firestore(), 'products/p1'), { stock: 'كثير' }));
  // زيادة مشروعة تحت الحدين تُقبل
  await assertSucceeds(updateDoc(doc(staff.firestore(), 'products/p1'), { stock: 35 }));
  // نقص المخزون (بيع) مرفوض لو بقى سالب، مقبول وهي فوق الصفر
  await assertFails(updateDoc(doc(staff.firestore(), 'products/p1'), { stock: -0.5 }));
  await assertSucceeds(updateDoc(doc(staff.firestore(), 'products/p1'), { stock: 0 }));
});

test('16. staff cannot create person / supplier / debt', async () => {
  const staff = env.authenticatedContext('s1');
  await assertFails(
    setDoc(doc(staff.firestore(), 'persons/new'), {
      id: 'new', ownerId: 's1', shopId: 'shop1',
      name: 'Someone', phone: '01000000000', type: 'customer',
      createdAt: new Date(), updatedAt: new Date(),
    }),
  );
  await assertFails(
    setDoc(doc(staff.firestore(), 'suppliers/new'), {
      id: 'new', ownerId: 's1', shopId: 'shop1',
      name: 'Someone', phone: '01000000000',
      createdAt: new Date(), updatedAt: new Date(),
    }),
  );
  await assertFails(
    setDoc(doc(staff.firestore(), 'debts/new'), {
      id: 'new', ownerId: 's1', shopId: 'shop1',
      personId: 'per1', personName: 'Customer', partyType: 'customer',
      direction: 'receivable', amount: 10, paidAmount: 0,
      createdAt: new Date(), updatedAt: new Date(),
    }),
  );
});

test('17. another shop staff cannot write into this shop', async () => {
  const otherStaff = env.authenticatedContext('s2');
  await assertFails(
    setDoc(doc(otherStaff.firestore(), 'sales/bad'), {
      id: 'bad', ownerId: 's2', shopId: 'shop1', total: 10,
      subtotal: 10, items: [], createdAt: new Date(),
    }),
  );
});

// ── 4. الاشتراك والإيقاف ────────────────────────────────────────────────
test('18. staff cannot write when the OWNER subscription expired', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'users/u1/subscription/current'), expiredSubscription());
  });
  const staff = env.authenticatedContext('s1');
  await assertFails(
    setDoc(doc(staff.firestore(), 'sales/expired'), {
      id: 'expired', ownerId: 's1', shopId: 'shop1', total: 10,
      subtotal: 10, items: [], createdAt: new Date(),
    }),
  );
});

test('20. staff without ownerId falls back to the shop owner', async () => {
  await seed(async (db) => {
    // محاكاة مستند موظف أُنشئ يدويًا بدون حقل ownerId.
    const { ownerId, ...withoutOwner } = staffDoc('s1', 'u1', 'shop1');
    await setDoc(doc(db, 'users/s1'), withoutOwner);
    await setDoc(doc(db, 'shops/shop1'), { ownerId: 'u1', shopId: 'shop1' });
  });
  const staff = env.authenticatedContext('s1');
  await assertSucceeds(
    setDoc(doc(staff.firestore(), 'sales/fallback'), {
      id: 'fallback', ownerId: 's1', shopId: 'shop1', total: 10,
      subtotal: 10, items: [], createdAt: new Date(),
    }),
  );
});

test('19. deactivated staff is denied immediately', async () => {
  await seed(async (db) => {
    await updateDoc(doc(db, 'users/s1'), { isActive: false });
  });
  const staff = env.authenticatedContext('s1');
  await assertFails(getDoc(doc(staff.firestore(), 'products/p1')));
  await assertFails(
    setDoc(doc(staff.firestore(), 'sales/blocked'), {
      id: 'blocked', ownerId: 's1', shopId: 'shop1', total: 10,
      subtotal: 10, items: [], createdAt: new Date(),
    }),
  );
});
