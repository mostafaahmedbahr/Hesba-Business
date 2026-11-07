// Firestore security rules tests — Hesba subscription pricing.
//
// Runs ONLY against the local emulator (firebase emulators:exec), never
// against production, and never deploys anything.
//
//   firebase emulators:exec --only firestore --project hesba-business "node --test rules_tests/rules.test.js"
//
// Covered required scenarios:
//   1-4  monthly / 3-months / 6-months / yearly accepted at configured price
//   5    admin changes the monthly price
//   6    customer submits with the updated price
//   7    customer tampers with the amount
//   8    customer tampers with the plan id
//   9    unauthorized approval attempt
//   10   pending request created before a price change stays reviewable,
//        and activation always requires an admin-approved request

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
  doc,
  setDoc,
  updateDoc,
  getDoc,
} from 'firebase/firestore';

const rulesPath = path.join(
  path.dirname(fileURLToPath(import.meta.url)),
  '..',
  'firestore.rules',
);

let env;

const DEFAULT_SETTINGS = {
  monthlyPrice: 99,
  threeMonthsPrice: 249,
  sixMonthsPrice: 449,
  yearlyPrice: 799,
  trialDays: 7,
  paymentMethods: [
    { id: 'instapay', label: 'InstaPay', number: '01110690299' },
  ],
};

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
  return env.withSecurityRulesDisabled(async (ctx) => {
    await fn(ctx.firestore());
  });
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
  // Trusted server-side state: the admin-configured prices + the two users
  // referenced by the rules (isAdmin() reads users/{uid}.role).
  await seed(async (db) => {
    await setDoc(doc(db, 'admin_settings/settings'), DEFAULT_SETTINGS);
    await setDoc(doc(db, 'users/u1'), { role: 'owner', shopId: 'shop1' });
    await setDoc(doc(db, 'users/u2'), { role: 'owner', shopId: 'shop2' });
    await setDoc(doc(db, 'users/admin1'), { role: 'admin' });
  });
});

// ── 1-4: the four plans at their configured prices ──────────────────────
test('1. monthly plan accepted at the configured 99', async () => {
  const alice = env.authenticatedContext('u1');
  await assertSucceeds(
    setDoc(doc(alice.firestore(), 'subscription_requests/r1'),
      requestPayload('u1', 'monthly', 99)),
  );
});

test('2. 3-months plan accepted at the configured 249', async () => {
  const alice = env.authenticatedContext('u1');
  await assertSucceeds(
    setDoc(doc(alice.firestore(), 'subscription_requests/r1'),
      requestPayload('u1', 'threeMonths', 249)),
  );
});

test('3. 6-months plan accepted at the configured 449', async () => {
  const alice = env.authenticatedContext('u1');
  await assertSucceeds(
    setDoc(doc(alice.firestore(), 'subscription_requests/r1'),
      requestPayload('u1', 'sixMonths', 449)),
  );
});

test('4. yearly plan accepted at the configured 799', async () => {
  const alice = env.authenticatedContext('u1');
  await assertSucceeds(
    setDoc(doc(alice.firestore(), 'subscription_requests/r1'),
      requestPayload('u1', 'yearly', 799)),
  );
});

// ── 5-6: admin changes the price, customer pays the new price ──────────
test('5+6. after the admin raises monthly to 149: 149 accepted, old 99 rejected', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'admin_settings/settings'),
      { ...DEFAULT_SETTINGS, monthlyPrice: 149 });
  });

  const alice = env.authenticatedContext('u1');
  // Customer sees the new price and pays it → accepted.
  await assertSucceeds(
    setDoc(doc(alice.firestore(), 'subscription_requests/r1'),
      requestPayload('u1', 'monthly', 149)),
  );
  // A stale/tampered amount from before the change → rejected.
  await assertFails(
    setDoc(doc(alice.firestore(), 'subscription_requests/r2'),
      requestPayload('u1', 'monthly', 99)),
  );
});

// ── 7: amount tampering ────────────────────────────────────────────────
test('7. tampered amount is rejected for every plan', async () => {
  const alice = env.authenticatedContext('u1');
  const cases = [
    ['monthly', 1],
    ['monthly', 0],
    ['monthly', -99],
    ['monthly', '99'], // string instead of int
    ['threeMonths', 99],
    ['sixMonths', 249],
    ['yearly', 249],
    ['yearly', 999999],
  ];
  for (const [plan, amount] of cases) {
    await assertFails(
      setDoc(doc(alice.firestore(), `subscription_requests/t_${plan}_${amount}`),
        requestPayload('u1', plan, amount)),
    );
  }
});

// ── 8: plan id tampering ───────────────────────────────────────────────
test('8. unknown or swapped plan ids are rejected', async () => {
  const alice = env.authenticatedContext('u1');
  // Unknown plan id at a "valid" price.
  await assertFails(
    setDoc(doc(alice.firestore(), 'subscription_requests/p1'),
      requestPayload('u1', 'lifetime', 99)),
  );
  // Plan id swapped to a cheaper one while paying the yearly amount.
  await assertFails(
    setDoc(doc(alice.firestore(), 'subscription_requests/p2'),
      requestPayload('u1', 'monthly', 799)),
  );
  // Plan id swapped to a pricier one while paying the monthly amount.
  await assertFails(
    setDoc(doc(alice.firestore(), 'subscription_requests/p3'),
      requestPayload('u1', 'yearly', 99)),
  );
});

// ── 9: nobody approves their own request ───────────────────────────────
test('9. customers cannot approve; only admins can review requests', async () => {
  const alice = env.authenticatedContext('u1');
  const mallory = env.authenticatedContext('u2');
  const admin = env.authenticatedContext('admin1');
  const ref = 'subscription_requests/r1';

  await setDoc(doc(alice.firestore(), ref), requestPayload('u1', 'monthly', 99));

  // The requester flips their own row to approved → rejected.
  await assertFails(
    updateDoc(doc(alice.firestore(), ref),
      { status: 'approved', reviewedAt: new Date() }),
  );
  // A stranger flips someone else's row → rejected.
  await assertFails(
    updateDoc(doc(mallory.firestore(), ref),
      { status: 'approved', reviewedAt: new Date() }),
  );
  // Rejection by a stranger is equally impossible.
  await assertFails(updateDoc(doc(mallory.firestore(), ref), { status: 'rejected' }));

  // A seeded admin can both approve and reject → allowed.
  await assertSucceeds(
    updateDoc(doc(admin.firestore(), ref),
      { status: 'approved', reviewedAt: new Date() }),
  );
});

test('9b. a request can never be born approved, and guests cannot submit', async () => {
  const alice = env.authenticatedContext('u1');
  const guest = env.unauthenticatedContext();

  await assertFails(
    setDoc(doc(alice.firestore(), 'subscription_requests/born'),
      requestPayload('u1', 'monthly', 99, { status: 'approved' })),
  );
  await assertFails(
    setDoc(doc(guest.firestore(), 'subscription_requests/guest'),
      requestPayload('u1', 'monthly', 99)),
  );
});

// ── 10: pending requests across a price change + activation gate ───────
test('10. old pending request stays reviewable; activation needs admin approval', async () => {
  const alice = env.authenticatedContext('u1');
  const admin = env.authenticatedContext('admin1');

  // The customer submitted at the OLD price (99) while it was valid.
  await setDoc(doc(alice.firestore(), 'subscription_requests/old'),
    requestPayload('u1', 'monthly', 99));
  await seed(async (db) => {
    await setDoc(doc(db, 'users/u1/subscription/current'), {
      status: 'pending',
      startDate: new Date(),
      endDate: new Date(Date.now() + 6 * 24 * 3600 * 1000),
      isTrial: true,
    });
    // Admin raises the price afterwards.
    await setDoc(doc(db, 'admin_settings/settings'),
      { ...DEFAULT_SETTINGS, monthlyPrice: 149 });
  });

  // Activation with the still-pending request → impossible for the customer.
  await assertFails(
    updateDoc(doc(alice.firestore(), 'users/u1/subscription/current'), {
      status: 'active',
      lastRequestId: 'old',
    }),
  );

  // The admin can still review the OLD request after the price change
  // (amount is frozen at submission time; approval grants plan duration).
  await assertSucceeds(
    updateDoc(doc(admin.firestore(), 'subscription_requests/old'), {
      status: 'approved',
      reviewedAt: new Date(),
    }),
  );

  // Now the customer's own subscription can reach `active`.
  await assertSucceeds(
    updateDoc(doc(alice.firestore(), 'users/u1/subscription/current'), {
      status: 'active',
      lastRequestId: 'old',
    }),
  );

  // But a NEW submission at the old price is rejected right away.
  await assertFails(
    setDoc(doc(alice.firestore(), 'subscription_requests/new'),
      requestPayload('u1', 'monthly', 99)),
  );
});

// ── sanity: the settings doc itself is the trusted source ──────────────
test('settings document reads work for signed-in customers (live prices)', async () => {
  const alice = env.authenticatedContext('u1');
  const snap = await getDoc(doc(alice.firestore(), 'admin_settings/settings'));
  assert.equal(snap.exists(), true);
  assert.equal(snap.data().monthlyPrice, 99);
});
