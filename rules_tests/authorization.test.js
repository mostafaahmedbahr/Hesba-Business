// AUTHORIZATION regression tests for the security-rule audit.
// Local emulator only — never deploys, never touches production.
//
//   firebase emulators:exec --only firestore --project hesba-business \
//     "cd rules_tests && node --test --test-concurrency=1 authorization.test.js"

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
import { doc, setDoc, updateDoc, getDoc } from 'firebase/firestore';

const rulesPath = path.join(
  path.dirname(fileURLToPath(import.meta.url)),
  '..',
  'firestore.rules',
);

const SETTINGS = {
  monthlyPrice: 99,
  threeMonthsPrice: 249,
  sixMonthsPrice: 449,
  yearlyPrice: 799,
  trialDays: 7,
  paymentMethods: [{ id: 'instapay', label: 'InstaPay', number: '01110690299' }],
};

const DAY = 24 * 3600 * 1000;

let env;

function requestPayload(uid, plan, amount, extra = {}) {
  return {
    userId: uid,
    ownerName: 'Owner',
    shopName: 'Shop',
    phone: '01000000000',
    selectedPlan: plan,
    amount,
    paymentMethod: 'instapay',
    paymentProofUrl: 'https://res.cloudinary.com/demo/image/upload/r.jpg',
    status: 'pending',
    createdAt: new Date(),
    ...extra,
  };
}

async function seed(fn) {
  return env.withSecurityRulesDisabled(async (ctx) => fn(ctx.firestore()));
}

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'hesba-business',
    firestore: { rules: fs.readFileSync(rulesPath, 'utf8') },
  });
});

after(async () => env.cleanup());

beforeEach(async () => {
  await env.clearFirestore();
  await seed(async (db) => {
    await setDoc(doc(db, 'admin_settings/settings'), SETTINGS);
    await setDoc(doc(db, 'users/u1'), { role: 'owner', shopId: 'shop1' });
    await setDoc(doc(db, 'users/u2'), { role: 'owner', shopId: 'shop2' });
    await setDoc(doc(db, 'users/staff1'), {
      role: 'staff', ownerId: 'u1', shopId: 'shop1',
    });
    await setDoc(doc(db, 'users/admin1'), { role: 'admin' });
  });
});

// ── V1: client activation cannot be weaponised ─────────────────────────
test('V1a. owner cannot activate using another user\'s approved request', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'subscription_requests/other'),
      requestPayload('u2', 'monthly', 99, { status: 'approved' }));
    await setDoc(doc(db, 'users/u1/subscription/current'), {
      status: 'pending',
      lastRequestId: 'own',
      endDate: new Date(Date.now() + 6 * DAY),
      isTrial: true,
    });
  });
  const alice = env.authenticatedContext('u1');
  await assertFails(
    updateDoc(doc(alice.firestore(), 'users/u1/subscription/current'), {
      status: 'active',
      lastRequestId: 'other',
      endDate: new Date(Date.now() + 30 * DAY),
    }),
  );
  const snap = await getDoc(doc(alice.firestore(), 'users/u1/subscription/current'));
  assert.equal(snap.data().status, 'pending');
});

test('V1b. owner cannot write an endDate beyond the approved plan length', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'subscription_requests/own'),
      requestPayload('u1', 'monthly', 99, { status: 'approved' }));
    await setDoc(doc(db, 'users/u1/subscription/current'), {
      status: 'pending',
      lastRequestId: 'own',
      startDate: new Date(),
      endDate: new Date(Date.now() + 6 * DAY),
      isTrial: true,
    });
  });
  const alice = env.authenticatedContext('u1');
  // Monthly plan = 30 days; ten years must be rejected.
  await assertFails(
    updateDoc(doc(alice.firestore(), 'users/u1/subscription/current'), {
      status: 'active',
      endDate: new Date(Date.now() + 3650 * DAY),
    }),
  );
});

test('V1c. legitimate activation within plan length still succeeds', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'subscription_requests/own'),
      requestPayload('u1', 'monthly', 99, { status: 'approved' }));
    await setDoc(doc(db, 'users/u1/subscription/current'), {
      status: 'pending',
      lastRequestId: 'own',
      startDate: new Date(),
      endDate: new Date(Date.now() + 6 * DAY),
      isTrial: true,
    });
  });
  const alice = env.authenticatedContext('u1');
  await assertSucceeds(
    updateDoc(doc(alice.firestore(), 'users/u1/subscription/current'), {
      status: 'active',
      endDate: new Date(Date.now() + 20 * DAY),
    }),
  );
});

// ── V2 / V3: suspended accounts are read-only ───────────────────────────
test('V2. suspended owner cannot edit their own profile', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'users/u1'), {
      role: 'owner', shopId: 'shop1', isActive: false,
    });
  });
  const alice = env.authenticatedContext('u1');
  await assertFails(
    updateDoc(doc(alice.firestore(), 'users/u1'), { phone: '01000000009' }),
  );
});

// ── FCM token hygiene ──────────────────────────────────────────────────
test('F1. owner can store a bounded FCM token list', async () => {
  const alice = env.authenticatedContext('u1');
  await assertSucceeds(
    updateDoc(doc(alice.firestore(), 'users/u1'), {
      fcmTokens: ['token-a', 'token-b'],
      fcmTokensUpdatedAt: new Date(),
    }),
  );
});

test('F2. FCM token list larger than 50 is rejected', async () => {
  const alice = env.authenticatedContext('u1');
  await assertFails(
    updateDoc(doc(alice.firestore(), 'users/u1'), {
      fcmTokens: Array.from({ length: 51 }, (_, i) => 'token-' + i),
    }),
  );
});

test('V3a. suspended owner cannot edit the shop document', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'users/u1'), {
      role: 'owner', shopId: 'shop1', isActive: false,
    });
    await setDoc(doc(db, 'shops/shop1'), { ownerId: 'u1', shopId: 'shop1', shopName: 'old' });
  });
  const alice = env.authenticatedContext('u1');
  await assertFails(
    updateDoc(doc(alice.firestore(), 'shops/shop1'), { shopName: 'new' }),
  );
});

test('V3b. suspended owner cannot change their subscription status', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'users/u1'), {
      role: 'owner', shopId: 'shop1', isActive: false,
    });
    await setDoc(doc(db, 'users/u1/subscription/current'), {
      status: 'active', endDate: new Date(Date.now() + 30 * DAY), isTrial: false,
    });
  });
  const alice = env.authenticatedContext('u1');
  await assertFails(
    updateDoc(doc(alice.firestore(), 'users/u1/subscription/current'), {
      status: 'expired',
    }),
  );
});

// ── V4: staff cannot submit subscription requests ───────────────────────
test('V4. staff account cannot create a subscription request', async () => {
  const staff = env.authenticatedContext('staff1');
  await assertFails(
    setDoc(doc(staff.firestore(), 'subscription_requests/by-staff'),
      requestPayload('staff1', 'monthly', 99)),
  );
});

test('sanity. owner can still submit a subscription request', async () => {
  const alice = env.authenticatedContext('u1');
  await assertSucceeds(
    setDoc(doc(alice.firestore(), 'subscription_requests/by-owner'),
      requestPayload('u1', 'monthly', 99)),
  );
});
