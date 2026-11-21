# التحصين التشغيلي — App Check + FCM + presets

> **التاريخ:** 21 نوفمبر 2026 · الجزء المحلي منفَّذ ومُختبَر؛ خطوات الـ Console خارجية وموضّحة أدناه.

---

## 1. Firebase App Check (عميل جاهز — التفعيل خارجي)

**محليًا ✅**
- أُضيف `firebase_app_check: ^0.3.2+10` (متوافق مع `firebase_core ^3.12.1`).
- في `main.dart` → `_initAppCheck()`:
  - release: `AndroidProvider.playIntegrity` / `AppleProvider.appAttest`.
  - debug: `AndroidProvider.debug` / `AppleProvider.debug`.
  - best-effort داخل try/catch — فشل التفعيل لا يمنع فتح التطبيق.
- **لم نُفعّل تحقق App Check في قواعد Firestore عمدًا** — تفعيله قبل إتمام إعداد الـ Console يمنع كل الكتابات. يبقى خطوة لاحقة بعد التأكد.

**خارجي (مطلوب من مالك المشروع):**
1. Firebase Console → **App Check** → سجّل التطبيق وفعّل **Play Integrity** (Android) و **App Attest** (iOS إن وُجد).
2. أضف بصمة **SHA-256 لشهادة الرفع/النشر** في إعدادات Play Integrity (available من Play Console → App signing).
3. سجّل **debug providers** لبصمات أجهزة التطوير حتى يعمل `flutter run`.
4. بعد تأكد الدفع من سجل App Check → يمكن إضافة شرط `request.app` في القواعد (لا يُنفَّذ الآن).

> ملاحظة: Cloudinary لا يتحقق من App Check؛ حمايته تعتمد على إعدادات الـ preset في لوحة Cloudinary.

---

## 2. تقليم FCM (محلي + بيانات الإنتاج) ✅

| البند | الحالة |
|---|---|
| `NotificationService.saveToken` | يحذف رمز الجهاز القديم (`arrayRemove`) قبل إضافة الجديد |
| `NotificationService.clearToken` | يحذف الرمز من Firestore **ويبطلّه** على الجهاز عند الخروج |
| `AccountRepoImpl.logout` | يستدعي `clearToken()` قبل `signOut()` (كل مسارات الخروج تمرّ عليه) |
| حفظ الرمز محليًا | SharedPreferences (`fcm_saved_token`) ليعرف القديم بعد إعادة تشغيل التطبيق |
| قاعدة `validFcmTokens()` | سقف 50 رمزًا/مستخدمًا — مُطبَّقة على تحديثات المالك، منشورة على الإنتاج |
| بيانات الإنتاج | **18 رمزًا زائدًا أُزيلوا**: مستخدمان كانا يحملان 9 و19 رمزًا → أصبح الحد الأقصى 5 |

اختبارات القواعد الجديدة: `F1` (قائمة صالحة), `F2` (أكثر من 50 مرفوض). المجموعة: **156/156**.

---

## 3. فصل preset الإيصالات (مُهيّأ — التفعيل بـ dart-define)

**محليًا ✅**
- `cloudinaryReceiptUploadPreset` مستقل أصلًا عن `cloudinaryUploadPreset`، مع folder منفصل `hesba/payment-proofs`.
- أضفنا `AppConstants.hasDedicatedReceiptPreset` + توثيقBuild flag.
- **القيمة الافتراضية ما زالت `hesba_images`** عمدًا — تغييرها الآن يكسر رفع الإيصالات قبل إنشاء الـ preset.

**خارجي ثم تفعيل:**
1. Cloudinary Dashboard → Upload presets → أنشئ unsigned preset باسم `hesba_receipts`.
2. قيوده: folder `hesba/payment-proofs`، صيغ `png/jpg` فقط، حد 10MB، `unique_filename = true`، فعّل `use_filename`، **بدون أي transformation** (الإيصال لازم يفضل مقروء).
3. أضف إلى أمر البناء:
   ```
   flutter build appbundle --release \
     --dart-define=CLOUDINARY_RECEIPT_PRESET=hesba_receipts
   ```
4. اختبر إرسال طلب اشتراك بإيصال، وتأكد أن الرابط ضمن `hesba/payment-proofs` وأن الدفع يظهر للأدمن.

---

## 4. ملخص التحقق المحلي

| الفحص | النتيجة |
|---|---|
| `flutter analyze` | No issues found! |
| `flutter test` | انظر التقرير الرئيسي (محدَّث) |
| اختبارات القواعد (emulator) | **156/156** |
| `firebase deploy --only firestore:rules` | ✅ Deploy complete |
| فحص FCM في الإنتاج | max 5 رموز/مستخدم (كان 19) |
