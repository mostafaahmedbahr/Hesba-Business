// Firestore emulator tests — ملاحظات "تواصل معنا" (feedback) وشاشة إدارتها.
//
// Runs ONLY against the local emulator (never production, never deploys):
//  firebase emulators:exec --only firestore --project hesba-business \
//    "node --test --test-concurrency=1 rules_tests/feedback.test.js"
//
// يغطي: إنشاء الملاحظة بأي مستخدم مسجّل، القراءة/الحذف للأدمن فقط،
// وتعليم "تم التعامل معها" محصورًا في handled/handledAt.

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

function feedbackDoc(extra = {}) {
  return {
    id: 'fb1',
    userId: 'u1',
    userEmail: 'owner@hesba.test',
    type: 'feedbackComplaint',
    title: 'مشكلة في التطبيق',
    description: 'الوصف بالتفصيل',
    createdAt: new Date(),
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
    await setDoc(doc(db, 'users/u1'), { role: 'owner', shopId: 'shop1', shopName: 'Hesba Shop' });
    await setDoc(doc(db, 'users/u2'), { role: 'owner', shopId: 'shop2' });
    await setDoc(doc(db, 'users/admin1'), { role: 'admin' });
    await setDoc(doc(db, 'feedback/fb1'), feedbackDoc());
  });
});

test('1. signed-in user can submit valid feedback', async () => {
  const u1 = env.authenticatedContext('u1');
  await assertSucceeds(
    setDoc(doc(u1.firestore(), 'feedback/fb_new'), feedbackDoc({ id: 'fb_new' })),
  );
});

test('2. guests cannot submit feedback', async () => {
  const guest = env.unauthenticatedContext();
  await assertFails(
    setDoc(doc(guest.firestore(), 'feedback/fb_guest'), feedbackDoc({ id: 'fb_guest' })),
  );
});

test('3. oversized title (>200) or description (>2000) is rejected', async () => {
  const u1 = env.authenticatedContext('u1');
  await assertFails(
    setDoc(doc(u1.firestore(), 'feedback/fb_big1'),
      feedbackDoc({ id: 'fb_big1', title: 'x'.repeat(201) })),
  );
  await assertFails(
    setDoc(doc(u1.firestore(), 'feedback/fb_big2'),
      feedbackDoc({ id: 'fb_big2', description: 'x'.repeat(2001) })),
  );
});

test('4. owners cannot read feedback (admin-only inbox)', async () => {
  const u1 = env.authenticatedContext('u1');
  const u2 = env.authenticatedContext('u2');
  await assertFails(getDoc(doc(u1.firestore(), 'feedback/fb1')));
  await assertFails(getDoc(doc(u2.firestore(), 'feedback/fb1')));
  await assertFails(getDocs(collection(u1.firestore(), 'feedback')));
});

test('5. admin can read individual docs and list the inbox', async () => {
  const admin = env.authenticatedContext('admin1');
  await assertSucceeds(getDoc(doc(admin.firestore(), 'feedback/fb1')));
  await assertSucceeds(getDocs(collection(admin.firestore(), 'feedback')));
});

test('6. non-admin cannot mark feedback as handled', async () => {
  const u1 = env.authenticatedContext('u1');
  await assertFails(updateDoc(doc(u1.firestore(), 'feedback/fb1'), { handled: true }));
});

test('7. admin can toggle handled / add handledAt', async () => {
  const admin = env.authenticatedContext('admin1');
  await assertSucceeds(updateDoc(doc(admin.firestore(), 'feedback/fb1'),
    { handled: true, handledAt: new Date() }));
  await assertSucceeds(updateDoc(doc(admin.firestore(), 'feedback/fb1'),
    { handled: false, handledAt: null }));
});

test('8. admin cannot edit the user\'s words (title/description/...)', async () => {
  const admin = env.authenticatedContext('admin1');
  await assertFails(updateDoc(doc(admin.firestore(), 'feedback/fb1'), { title: 'معدل' }));
  await assertFails(updateDoc(doc(admin.firestore(), 'feedback/fb1'), { description: 'معدل' }));
  await assertFails(updateDoc(doc(admin.firestore(), 'feedback/fb1'), { userId: 'u2' }));
  // ولا حتى handled + أي حقل تاني مع بعض
  await assertFails(updateDoc(doc(admin.firestore(), 'feedback/fb1'),
    { handled: true, title: 'معدل' }));
});

test('9. admin can delete feedback; regular users cannot', async () => {
  const u1 = env.authenticatedContext('u1');
  await assertFails(deleteDoc(doc(u1.firestore(), 'feedback/fb1')));
  const admin = env.authenticatedContext('admin1');
  await assertSucceeds(deleteDoc(doc(admin.firestore(), 'feedback/fb1')));
});
