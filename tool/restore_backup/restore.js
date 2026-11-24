#!/usr/bin/env node
'use strict';

/**
 * استعادة نسخة احتياطية لتطبيق حسبة إلى Firestore بصلاحيات Admin.
 *
 * لازم يعمل بـ Admin SDK (مش من التطبيق العادي) لأن قواعد Firestore تمنع
 * كتابة `createdAt` قديم، وتمنع تعديل الفواتير/المصروفات/المرتجعات لغير الأدمن.
 * السكربت مجاني 100% — مش محتاج Cloud Functions ولا خطة Blaze.
 *
 * الاستخدام:
 *   node restore.js <backup.json|backup.json.gz> --dry-run
 *   node restore.js <backup.json|backup.json.gz> --yes
 *   node restore.js <backup.json> --yes --skip=admin_settings,subscription_requests
 *   node restore.js <backup.json> --yes --emulator   (اختبار بدون لمس الإنتاج)
 *
 * البيانات تُكتب بنفس معرّف المستند الأصلي + merge، فإعادة التشغيل لا تكرّر
 * أي سجل ولا تلمس الحقول اللي اضيفت بعد التصدير.
 */

const fs = require('fs');
const path = require('path');
const readline = require('readline');
const { readBackup, makeDecoder } = require('./transformer');

const args = process.argv.slice(2);
const input = args.find((a) => !a.startsWith('--'));
const dryRun = args.includes('--dry-run');
const yes = args.includes('--yes');
const projectArg = args.find((a) => a.startsWith('--project='));
const skipArg = args.find((a) => a.startsWith('--skip='));
const emulator = args.includes('--emulator');

// لازم يتحدد قبل إنشاء عميل Firestore. Admin SDK يقرأ المتغير ده تلقائياً.
if (emulator) {
  process.env.FIRESTORE_EMULATOR_HOST =
    process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080';
}

function usage(message) {
  if (message) console.error(`خطأ: ${message}\n`);
  console.error(
    'الاستخدام: node restore.js <backup.json|backup.json.gz> [--dry-run] [--yes] ' +
      '[--project=ID] [--skip=root1,root2] [--emulator]',
  );
  process.exit(1);
}

if (!input) usage('لم تحدد ملف النسخة الاحتياطية');

let admin;
try {
  admin = require('firebase-admin');
} catch (e) {
  console.error('firebase-admin غير مثبّت. شغّل: npm install');
  process.exit(1);
}

const skipRoots = new Set(
  skipArg
    ? skipArg.slice('--skip='.length).split(',').map((s) => s.trim()).filter(Boolean)
    : [],
);
const projectId = projectArg ? projectArg.slice('--project='.length) : undefined;

async function confirm(backup, docs) {
  if (yes || dryRun) return true;
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });
  const answer = await new Promise((resolve) => {
    rl.question(
      `سيتم استعادة ${docs.length} مستند إلى ${emulator ? 'الإموليتر' : 'مشروع ' + (projectId || '(ADC default)')} ` +
        `للمحل ${backup.shopId}. اكتب RESTORE للتأكيد: `,
      resolve,
    );
  });
  rl.close();
  return answer.trim() === 'RESTORE';
}

async function main() {
  const backup = readBackup(input);

  const options = {};
  if (projectId) options.projectId = projectId;
  const serviceAccount = path.join(__dirname, 'serviceAccount.json');
  // الإموليتر لا يحتاج مفتاح خدمة ولا اتصال بالإنترنت.
  if (!emulator && fs.existsSync(serviceAccount)) {
    options.credential = admin.credential.cert(require(serviceAccount));
  }
  // نُهيّئ التطبيق حتى في المعاينة: فك المراجع (DocumentReference) يحتاجه،
  // لكن المعاينة نفسها لا تكتب أي شيء.
  if (!admin.apps.length) admin.initializeApp(options);

  const docs = makeDecoder(admin, { skipRoots }).decodeDocs(backup);

  if (dryRun) {
    console.log('وضع المعاينة (dry-run) — لا توجد كتابة.');
  } else if (!(await confirm(backup, docs))) {
    console.log('تم الإلغاء.');
    return;
  }

  const db = admin.firestore();
  const counters = {};
  for (const doc of docs) {
    const root = doc.path.split('/')[0];
    counters[root] = (counters[root] || 0) + 1;
  }
  console.log(`المجموع: ${docs.length} مستند`);
  for (const [root, count] of Object.entries(counters)) {
    console.log(`  ${root}: ${count}`);
  }

  const BATCH = 450;
  for (let i = 0; i < docs.length; i += BATCH) {
    const chunk = docs.slice(i, i + BATCH);
    if (!dryRun) {
      const batch = db.batch();
      for (const doc of chunk) {
        batch.set(db.doc(doc.path), doc.data, { merge: true });
      }
      await batch.commit();
    }
    const done = Math.min(i + BATCH, docs.length);
    process.stdout.write(`\r${done}/${docs.length}`);
  }
  process.stdout.write('\n');

  console.log(dryRun ? 'المعاينة اكتملت.' : 'تمت الاستعادة بنجاح.');
}

main().catch((error) => {
  console.error('فشلت الاستعادة:', error);
  process.exit(1);
});
