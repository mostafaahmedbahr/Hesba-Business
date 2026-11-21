# تقرير الحالة الشامل — تطبيق حسبة (HESBA Business)

> **التاريخ:** 21 نوفمبر 2026 · **الإصدار:** `1.0.0+1` · **الفرع:** `main` @ `3900a19`
> **منهج التقرير:** فحص مباشر للمستودع + تشغيل فعلي للأوامر (وليس نقلًا عن التقارير القديمة).
> **البيئة:** Flutter 3.47.1 / Dart 3.13.1 · Windows · Firebase (`hesba-business`) + Cloudinary.

---

## 1. الخلاصة التنفيذية (الحكم النهائي)

| البند | التقييم |
|---|---|
| **نضج الكود وهندسته** | قوي جدًا — **8.5/10** |
| **السلامة المالية** | قوية جدًا — **9/10** |
| **الكفاءة والأداء** | قوي — **8.5/10** (بعد تحسين القراءات) |
| **الأمان وعزل البيانات** | جيد — **8.5/10** (القواعد والفهارس منشورة ومُتحقَّق منها؛ إعادة تعيين مفتاح الرفع في Play Console ما زالت مطلوبة) |
| **الاختبارات** | جيدة — **8/10** |
| **اكتمال المزايا** | شبه مكتمل — **9/10** |
| **الجاهزية للنشر الفعلي (Play)** | **5/10** — لا يزال هناك عمل تشغيلي إلزامي |
| **التقييم الكلي (مرجّح)** | **≈ 79 / 100** |

**الخلاصة:** التطبيق من الناحية **البرمجية** في حالة ممتازة ومستقرة: معمارية نظيفة، مسارات مالية مغلقة بمعاملات Firestore، اختبارات آلية واسعة، وتحسين كبير في قراءات Firestore. **لكنه ليس جاهزًا للإنتاج التجاري بعد** — المتبقي أعمال تشغيل ومتجر خارجية (إعادة تعيين مفتاح الرفع، إدخال نماذج Play Console، اختبار دخان للـ AAB). تم: إصلاح `C3` (154/154)، تدوير المفتاح + بناء AAB، نشر قواعد Firestore وفهارسها، backfill 28 مستندًا، و**تجهيز حزمة النشر كاملة (السياسة، Data Safety، التقييم، النصوص، 4 لقطات + feature graphic)** (انظر §7، §11–§14).

---

## 2. الحالة المُتحقَّق منها الآن (Verified State)

| الفحص | النتيجة | ملاحظة |
|---|---|---|
| `git status` | ✅ نظيف | لا تعديلات غير ملتزمة، متزامن مع `origin/main` |
| `flutter test` | ✅ **227 / 227 ناجح** | 39 ملف اختبار (~6,000 سطر) — شُغّل الآن |
| `flutter analyze` | ✅ **No issues found!** | 0 أخطاء / 0 تحذيرات / 0 ملاحظات — نظيف تمامًا |
| اختبارات قواعد Firestore (Emulator) | ✅ **156 / 156** | بعد `C3` + اختباري FCM الجديدين (التفاصيل §7، §16) |
| حجم الكود | 430 ملف Dart في `lib/` (~67,269 سطر) + 19 ميزة + 34 Cubit | — |
| قواعد الأمان | 921 سطرًا + 21 فهرس مركّب | 8 ملفات اختبار قواعد |
| ملفات الترجمة | `ar.json` / `en.json` صالحة | عربي أولًا + RTL |
| أثر البناء | ✅ `app-release.aab` (72.5MB) أُعيد بناؤه بعد إضافة الحزم الجديدة | موقّع بالمفتاح الجديد — البصمة مطابقة |
| مفتاح التوقيع | ✅ دُوِّر محليًا / ⚠️ إعادة التعيين في Play Console مطلوبة | القديم حُذف من القرص و`git rm --cached` (مرحَّل)، `*.keystore`/`*.jks` في `.gitignore` |

---

## 3. جودة الكود والمعمارية

**إيجابيات مؤكدة:**
- معمارية **Feature-based** واضحة (19 ميزة: مبيعات، مرتجعات، مصروفات، ديون، منتجات، موردون، اشتراكات، أدمن، إلخ) بطبقات `data / presentation` وواجهات repo + `get_it` للحقن.
- إدارة حالة **Cubit** فقط — **صفر استخدام لـ `setState`** داخل ملفات Cubit (تم التحقق).
- **صفر أخطاء تحليل**، و **227 اختبار وحدة** تغطي مسارات المال والتحسينات والموثوقية.
- فصل الـ god-views إلى مجلدات widgets، ووجود `AppLogger` مركزي + شاشة تشخيص للأدمن.
- معالجة أخطاء مُودّة (`friendlyError`) بدل رسائل Firebase الخام.

**نقاط ضعف / دين تقني:**
- ✅ **الـ 66 ملاحظة analyzer اتنظّفت بالكامل** — انظر §15.
- ✅ **لا توجد TODO/FIXME في كود Dart أصلًا** — الرقم «89» في نسخة سابقة من هذا التقرير كان خطأ عدّ (مطابقة `toDouble` مع `TODO` بحالة غير حساسة). فحص حساس للحالة يثبت 0 في `lib/` و `test/` و `tool/`؛ TODO قالبي واحد فقط كان في `build.gradle.kts` واُزيل.
- بعض الملفات لا تزال ضخمة (مثل `admin_ds.dart`, `admin_dashboard`, `sales_view`) لكنها design-system/عروض تجميعية مقبولة نسبيًا.
- `print()` متبقٍ في 3 مواضع (يفترض استبداله بـ `AppLogger`).
- ✅ أُضيفت اختبارات **Integration** للتدفق المالي الكامل + **Widget** لمتحكم الفترات (انظر §17).

---

## 4. الكفاءة والأداء (أكبر تحسين في هذه المرحلة)

بناءً على `docs/FIRESTORE_READS_MAP.md` (21 نوفمبر) والاختبارات المؤكدة:

| المؤشر | قبل | بعد |
|---|---|---|
| مواضع `.snapshots()` | 28 | **15** |
| مستمعات لحظية فعلية | ~31 | **~15** |
| قراءة `users/{uid}` لكل عملية بيع/مرتجع/مصروف | 1+ | **0** (كاش) |
| بحث الأدمن (أسوأ حالة) | ~30,000 قراءة | **قراءة واحدة لكل نتيجة** (فهارس + `searchTokens`) |
| قراءات يومية تقديرية لمحل متوسط | ~46,500/يوم (تكسر الحد المجاني) | **< 1,000/يوم** |
| اختبارات ناجحة | 201 | **227** |

**ما تحقق:** إزالة مستمعات الداشبashboard والتقارير غير الضرورية، الاعتماد على `AppEvents` + تحديث عند الطلب، كاش موحّد لـ `shopId` (`ShopResolver`/`UserRoleService`)، pagination حقيقي في بحث الأدمن (لا سقف صامت عند 1,000 مستند)، وترقية `count()` بدل جلب المستندات.

**المقايضة الواعية:** التحديث اللحظي **من جهاز آخر** (موظف يسجّل بيعًا والصاحب فاتح الرئيسية) لم يعد فوريًا في الداشبورد/التقارير — يحتاج سحب للتحديث أو إعادة فتح الشاشة. داخل نفس الجهاز يبقى فوريًا عبر `AppEvents`.

**متبقٍ اختياري:** دمج استعلامات `getToday*` الستة، تحويل `watchActivityLogs()` لـ `get()`، تقليل تحديثات `AppSettingsService`/`FeatureFlagsService`.

---

## 5. السلامة المالية وسلامة البيانات

| المسار | الحالة | الدليل |
|---|---|---|
| البيع (خصم مخزون + فاتورة + دين آجل في معاملة واحدة) | ✅ | اختبارات `sales_integrity_test.dart` + `idempotency_test.dart` |
| **منع التكرار (Idempotency)** | ✅ **مُنفَّذ الآن** | `request_id.dart` + `requestId` في `addSale/addReturn/addExpense/addPayment` — إعادة المحاولة بعد فقدان الاستجابة تُعيد نفس معرّف المستند |
| المرتجعات (استرداد المخزون + تسوية الدين بحد الأقصى المتبقي) | ✅ | `returns_integrity_test.dart` |
| الديون والمدفوعات (سجل غير قابل للتعديل، `paidAmount` لا ينقص) | ✅ | `payment_integrity_test.dart` + قواعد `onlyDebtPaymentFields()` |
| الربح/التكلفة (لقطات تكلفة تاريخية، استبعاد التكلفة المجهولة، خصم المرتجعات) | ✅ | `reports_calculator_test.dart` + `admin_profit_test.dart` |
| مطابقة ربح الداشبورد مع التقارير | ✅ | اختبار `Scenario 13` |
| الاشتراكات (طلب واحد معلّق، منع تقديم طلب قديم، رفض لا يُلغي فترة مدفوعة) | ✅ | `subscription_integrity_test.dart` |
| إضافات المخزون (معاملة + متوسط مرجّح + ثبات السعر التاريخي) | ✅ | اختبارات المحاكي `stock_purchase.test.js` |

**الخلاصة المالية:** مسارات الأموال مغطّاة آليًا ومحمية على مستوى العميل **والقواعد**، وليس فقط بالمراجعة البشرية.

---

## 6. الأمان وعزل البيانات

**نقاط القوة:**
- عزل صارم لكل محل (`sameShop`, `ownerId`) — اختبارات المحاكي تثبت رفض الوصول عبر المحلات (153/154 ناجح).
- الأدمن فقط يكتب في الإعدادات/السجلات، مع تحقق من صحة القيم (`validAdminSettings()`).
- منع تصعيد الصلاحيات (الموظف لا يغيّر دوره، المالك لا يرقّي موظفًا) — اختبارات `authorization.test.js`, `staff.test.js`.
- الموظفون يستطيعون بيع/إضافة مصروف ضمن محلهم فقط، ويُمنعون من تعديل/حذف ما أنشأوه.
- تفعيل الاشتراك مشروط بطلب **موافق عليه من الأدمن** بربط `lastRequestId` ونافذة زمنية (`planDays`/`laterTimestamp`).
- الحسابات الموقوفة لا تكتب في ملفها/محلها/المرآة.

**التحفظات:**
- 🟡 **مفتاح رفع Play — دُوِّر محليًا، والخطوة الخارجية معلّقة:** مفتاح جديد (SHA-256 `62:7E:E2:F4...EE`) في `android/app/`، القديم حُذف من القرص والـ index، و`.gitignore` يمنع `*.keystore`/`*.jks`. **لكن الرفع لن يعمل حتى تُطلب إعادة تعيين مفتاح الرفع (Request upload key reset) في Play Console وتُسجَّل شهادة المفتاح الجديد** (`docs/PLAY_UPLOAD_KEY_ROTATION.md`). مفتاح توقيع التطبيق عند Google لا يتغيّر، فالمستخدمون الحاليون لا يتأثرون. تنظيف تاريخ Git اختياري ولا يُنفَّذ إلا بموافقة (force-push).
- ✅ **قواعد وفهارس Firestore منشورة ومُتحقَّق منها** على `hesba-business` (انظر §12). الحساب `hesbabusiness1@gmail.com` يملك صلاحية النشر الآن (403 القديمة انتهت). ✅ **backfill الـ `searchTokens` اتنفّذ** على 28 مستندًا قديمًا (انظر §13).
- 🟡 **App Check و Crashlytics جاهزان في العميل**، لكن تفعيلهما في Firebase Console خارجي؛ لم يُفرض App Check في القواعد بعد (انظر §16).
- 🟡 **preset الإيصالات منفصل في الكود**، لكن إنشاء preset جديد في Cloudinary وتمريره بـ `--dart-define` خارجي (افتراضيًا يبقى Shared لتفادي كسر الرفع).
- ✅ **FCM مُقلَّم**: حذف الرمز القديم عند التجديد والخروج + سقف 50 في القواعد + تقليم 18 رمزًا في الإنتاج.
- ⚠️ إشعارات iOS لا تزال `aps-environment=development`.
- ⚠️ قائمة «لوحة التحكم» تظهر لكل مستخدم (محمية بالقواعد لكنها سطح هجوم/UX غير مرغوب).

---

## 7. اختبار القاعدة `C3` — تم إصلاحه ✅

**الاختبار الأصلي:** `C3. coworker of the shop cannot record a payment on someone else's debt` — `rules_tests/accounts.test.js:442`
**العرض الأصلي:** `Expected request to fail, but it succeeded.`

**التشخيص:** المستخدم `u1b` في بيانات الاختبار ليس موظفًا غريبًا، بل **مالك ثانٍ داخل نفس المحل** (`role: 'owner', shopId: 'shop1'` — سطر 123). وقاعدة `debts/{debtId}/payments` (سطر 839) تسمح صراحةً لملاك/موظفي **نفس المحل** بتسوية ديونه، لأن مرتجع البيع الآجل يقلّل الذمة عبر نفس مسار الدفع (التعليق سطر 823 + الاختبار الناجح `9c` في `staff.test.js`). إذن **الاختبار كان قديم التوقّع، والقاعدة صحيحة مقصودًا** — وليست ثغرة عبر المحلات (`sameShop` مفروض، والسجل غير قابل للتعديل).

**الإصلاح المطبَّق:** أُعيد صياغة C3 ليختبر الثابت الحقيقي بدل السلوك القديم:
- ✅ مالك نفس المحل **يسمح له** بتسجيل دفعة على دين المحل (`ownerId` = uid الخاص به).
- ❌ **تزوير `ownerId`** لينسب الدفعة لصاحب ذمة آخر يُرفض (القاعدة سطر 841: `ownerId == myUid()`).
- حُدِّث أيضًا التعليق التمهيدي للقسم C في الملف (كان يقول "creator-only recording").

**التحقق:** `firebase emulators:exec --only firestore --project hesba-business "npm test"` → **tests 154 · pass 154 · fail 0**. القاعدة نفسها **لم تُغيَّر** — تغيّر الاختبار فقط ليعكس التصميم الموثّق.

---

## 8. المزايا الوظيفية (اكتمال)

19 ميزة رئيسية تعمل: المصادقة والتسجيل (بما فيها تجربة 7 أيام)، المنتجات (متغيرات/فئات/صور)، المبيعات (نقد/بطاقة/آجل + فاتورة)، المرتجعات، المصروفات (متكررة/تذكيرات)، الديون والعملاء، الموردون، التقارير والرسوم البيانية، لوحة التحكم، الإشعارات والتذكيرات، الاشتراكات والطلبات، الأدمن (إدارة المحلات/الطلبات/الإعدادات/سجل النشاط/التشخيص)، الملف الشخصي، حذف الحساب، سياسة الخصوصية، الدعم/التواصل، تعدد اللغات والثيم.

**فجوة وظيفية واحدة:** لا يوجد خادم إرسال إشعارات (Cloud Functions) — كل الإشعارات محلية/ذاتية. لا يؤثر على العمل داخل التطبيق لكنه يحدّ من الإشعارات بين الأجهزة.

---

## 9. قائمة المهام المتبقية مرتبة بالأولوية

| الأولوية | المهمة | الأثر |
|---|---|---|
| ~~🔴 P0~~ ✅ محليًا | ~~تدوير `hesba-upload-key.keystore` + حذفه من Git + `.gitignore`~~ | **تم محليًا**: مفتاح جديد + `git rm --cached` + `.gitignore` + AAB موقّع به. ⚠️ **خارجي**: طلب إعادة التعيين في Play Console (بقيادة مالك الحساب) |
| ~~🔴 P1~~ ✅ | ~~حل اختبار القاعدة الفاشل `C3` وإعادة تشغيل مجموعة القواعد إلى 154/154~~ | **تم — 154/154 (21 نوفمبر)** |
| ~~🔴 P1~~ ✅ | ~~تأكيد نشر `firestore.rules` و `firestore.indexes.json` على `hesba-business`~~ | **تم**: القواعد مطابقة للمنشورة + الفهارس نُشرت (18/18) وتحقّقنا منها (§12) |
| ~~🟠 P1~~ ✅ | ~~تشغيل `AdminSearchRepo.backfillSearchTokens()` مرة واحدة للمستندات القديمة~~ | **تم**: 28/28 مستندًا (10 محلات + 13 منتج + 5 طلبات)، إعادة الفحص 0 متبقٍ (§13) |
| ~~🟠 P1~~ ✅ | ~~إعادة بناء `flutter build appbundle --release`~~ | **تم**: AAB 72.3MB موقّع بالمفتاح الجديد — يبقى اختبار الدخان على جهاز حقيقي |
| 🟠 P1 | Play Console: رابط سياسة الخصوصية، Data Safety، تقييم المحتوى، لقطات شاشة | ✅ **جُهّزت كلها** في `docs/PLAY_CONSOLE_SUBMISSION_KIT.md` + أصول `store/` — الإدخال الفعلي في Console خارجي (لا جلسة مصادقة هنا) |
| ~~🟡 P2~~ ✅ | ~~تنظيف 66 ملاحظة analyzer + TODOs~~ | **تم**: `dart fix --apply` (57 إصلاحًا في 34 ملفًا) + 9 إصلاحات يدوية ⇒ `No issues found!`، و0 TODO حقيقي (§15) |
| ~~🟡 P2~~ ✅ محليًا | ~~App Check + Crashlytics + تقليم FCM + فصل preset الإيصالات~~ | **تم محليًا** + تقليم بيانات الإنتاج + نشر القواعد (§16). خارجي: تفعيل Console لـ App Check/Crashlytics وإنشاء preset Cloudinary |
| ~~🟡 P2~~ ✅ | ~~اختبارات Widget/Integration لتدفق كامل + تقليلالاعتماد على المسح الكامل للتقارير~~ | **تم**: تدفق مالي كامل (بيع آجل → مرتجع → تسوية → تجديد → رفض) + widget chips + كاش فترات يمنع إعادة المسح الكامل (§17) |
| ~~⚪ P3~~ ✅ | ~~تحسينات اختيارية في `FIRESTORE_READS_MAP.md` §6، إغلاق S-19، iOS APNs~~ | **تم**: gating درج الأدمن، دمج `getToday*` في استعلام واحد/كوليكشن، `getActivityLogs()` بدل live listener، تحميل الإعدادات مرة واحدة في الـ splash، iOS APNs=production، وتنظيف آخر debugPrint (§18) |

---

## 10. سجل التحقق (ما الذي نُفّذ فعلًا لهذا التقرير)

| الأمر | النتيجة |
|---|---|
| `git status --short --branch` | نظيف — `main...origin/main` @ `3900a19` |
| `flutter --version` | Flutter 3.47.1 / Dart 3.13.1 |
| `flutter analyze` | ✅ **No issues found!** (كان 0 errors · 66 issues) |
| `dart fix --apply` | ✅ 57 إصلاحًا في 34 ملفًا + 9 إصلاحات يدوية |
| `flutter test --reporter compact` | **All tests passed — 236/236** |
| `firebase emulators:exec --only firestore --project hesba-business "npm test"` (من `rules_tests/`) | **tests 154 · pass 154 · fail 0** (بعد إصلاح `C3`) |
| `git ls-files` | ✅ لا أي `.keystore`/`.jks` مُتتبَع (القديم مُرحَّل للحذف) |
| `git check-ignore -v` | ✅ `android/app/*.keystore` و `android/key.properties` مُتجاهَلان |
| `keytool -list -v` (المفتاح الجديد) | ✅ الاسم/BN/SHA-256/SHA-1 مطابقة لـ `docs/PLAY_UPLOAD_KEY_ROTATION.md` |
| `flutter build appbundle --release` | ✅ 72.5MB — بنجاح (بعد الحزم الجديدة) |
| `keytool -printcert -jarfile app-release.aab` | ✅ بصمة SHA-256 `62:7E:E2:F4…EE` = المفتاح الجديد |
| `firebase login:list` / `projects:list` | ✅ `hesbabusiness1@gmail.com` / `hesba-business` (current) |
| `firebase deploy --only firestore:rules,firestore:indexes --project hesba-business` | ✅ `rules compiled` + `already up to date` + `released rules` + `deployed indexes` + `Deploy complete!` |
| `firebase firestore:indexes --project hesba-business` | ✅ 18 منشورة = 18 محلية (بعد حذف 3 فهارس زائدة) |
| backfill dry-run (قبل) | 28 مستندًا بلا `searchTokens` (10 / 13 / 5) |
| مقارنة منطق التوكينز JS مقابل Dart | ✅ EXACT MATCH على عيّنات عربية/فارسية/لاتينية |
| backfill run + dry-run (بعد) | ✅ 28/28 محدَّثة، **0 متبقٍ** |
| `runQuery` بـ `arrayContains` + `orderBy(__name__)` | ✅ نتائج في الثلاثة كوليكشنز بدون أخطاء فهرس |
| تحقق رابط السياسة (`webfetch`) | ✅ حي — `Privacy Policy for حسبة`، 17 نوفمبر 2026 |
| فحص PNG header (`colorType`) | ✅ كل أصول `store/` = 2 (24-bit RGB بلا alpha) |
| أبعاد الأصول | ✅ 4 لقطات 1080×1920 + feature graphic 1024×500 + أيقونة 512×512 |
| عدّ الملفات/الأسطر | 430 ملف Dart / 67,269 سطر `lib` · 39 ملف اختبار / 5,990 سطر |
| فحص الترجمة | `ar.json` و `en.json` صالحان |

---

## 11. تدوير مفتاح رفع Play — الحالة التفصيلية

**محليًا (مكتمل ومُتحقَّق منه):**
- مفتاح جديد RSA-2048 في `android/app/hesba-upload-key.keystore`، الاسم `CN=Hesba Upload, … C=EG`، صالح حتى 2054.
- بصمة SHA-256: `62:7E:E2:F4:DF:F1:A6:DD:D8:39:2B:63:15:D2:E5:71:9D:59:A5:10:02:F4:00:32:F3:C1:B1:27:EE:71:D1:EE`.
- `android/key.properties` (غير مودع) يشير إلى `storeFile=hesba-upload-key.keystore` + `keyAlias=hesba-upload`؛ `build.gradle.kts` يقرأ منه عند بناء release.
- النسخة القديمة `hesba-upload-key.keystore` حُذفت من القرص وتم `git rm --cached` (**مرحَّلة في الـ index، تحتاج commit**).
- `.gitignore` الجذري يمنع الآن `*.keystore` و `*.jks`؛ `git ls-files` نظيف من أي مفتاح.
- `app-release.aab` أُعيد بناؤه وتأكد أن توقيعه بالمفتاح الجديد (البصمة مطابقة).

**خارجي (لا يمكن تنفيذه من هذه الآلة):**
- ⚠️ **طلب `Request upload key reset` في Play Console** ورفع شهادة المفتاح الجديد. بدونه يُرفض رفع الـ AAB. مفتاح توقيع التطبيق الذي تحتفظ به Google لا يتغيّر ⇒ لا تأثير على المستخدمين الحاليين.
- الدليل الكامل: `docs/PLAY_UPLOAD_KEY_ROTATION.md` (فيه أمر `keytool -export` لتوليد `.pem`).

**القرارات المتّخذة (21 نوفمبر):**
- ✅ **لا تنظيف لتاريخ Git** — بعد إعادة التعيين في Play Console يصبح المفتاح القديم بلا قيمة للنشر؛ التدوير وحده هو الإجراء الحاسم. لم يُنفَّذ `filter-repo` ولا أي `force push`.
- ✅ **لا commit الآن** — التغييرات تُترك للمراجعة: حذف المفتاح **مُرحَّل في الـ index**، وبقية التعديلات (`.gitignore`, `key.properties.example`, `accounts.test.js`, التقارير، `upload-key-cert.pem`) غير مُرحَّلة.
- 📄 شهادة الرفع العامة جاهزة في `upload-key-cert.pem` (1270 بايت) لرفعها في Play Console عند طلب إعادة التعيين.

---

## 12. نشر قواعد وفهارس Firestore — تم التحقق ✅

**الصلاحية:** Firebase CLI مسجّل الدخول بـ `hesbabusiness1@gmail.com` والمشروع `hesba-business` هو الحالي؛ خطأ `403` القديم لم يعد يظهر (قراءة الفهارس نجحت).

**القواعد (`firestore.rules`):**
- `firebase deploy --only firestore:rules,firestore:indexes --project hesba-business` قال: `rules file compiled successfully` ثم `latest version of firestore.rules already up to date, skipping upload`، وفي الختام `released rules firestore.rules to cloud.firestore` ⇒ **الملف المحلي هو نفسه المنشور في الإنتاج** (كل إصلاحات الأمان الأخيرة سارية الآن).

**الفهارس (`firestore.indexes.json`):**
- قبل النشر: **18 منشورة** مقابل **21 محلية** (ناقص 3: `shops`, `products`, `subscription_requests` الخاصة بـ `searchTokens`).
- أثناء النشر رفض Firestore الفهارس الثلاثة برسالة: `this index is not necessary, configure using single field index controls` — أي أن `array-contains` على `searchTokens` مع `orderBy(__name__)` يكفيه الـ **single-field index التلقائي**، فالمركّب زائد.
- **أزلنا الثلاثة من الملف المحلي**، ثم أعيد النشر ⇒ `deployed indexes in firestore.indexes.json successfully` + `Deploy complete!`.
- تحقق بعد النشر: **18 منشورة = 18 محلية**، ولا أي فهرس مركّب `searchTokens` متبقٍ، و`fieldOverrides` فارغ. استعلام بحث الأدمن (`arrayContains` + `orderBy(__name__)`) يعتمد على الفهرس التلقائي.

**الـ backfill:** نُفّذ بعد النشر — انظر §13. استعلام `arrayContains('a') + orderBy(__name__)` اختُبر على الثلاثة كوليكشنز في الإنتاج وأعاد نتائج بدون أخطاء فهرس، مما يثبت أن الفهرس التلقائي كافٍ فعلًا.

> ملاحظة: `firestore.indexes.json` فيه الآن 18 فهرسًا بدل 21 (تغيير على الملف المُتتبَع، لم يُعمل له commit — ضمن قرار «اتركها للمراجعة»).

---

## 13. تشغيل `backfillSearchTokens()` على الإنتاج — تم ✅

**الطريقة:** سكربت مؤقت خارج المستودع (`%TEMP%\opencode\hesba_backfill.js`) يُطابق منطق `SearchTokens` في `lib/core/utils/search_tokens.dart` و`AdminSearchRepoImpl.backfillSearchTokens()` — يقرأ كل المستندات عبر Firestore REST، ويضيف `searchTokens` للمستندات التي تفتقده عبر `PATCH ...?updateMask.fieldPaths=searchTokens` على دفعات.

**الصلاحية:** access token الخاص بـ Firebase CLI (`hesbabusiness1@gmail.com`) يتجاوز قواعد Firestore عبر IAM (تأكدنا بقراءة `feedback` — المحصورة بالأدمن — كانت 200). لذلك لم نحتاج كلمة مرور أدمن ولا service account.

**ضمان التطابق:** عرّفنا عيّنات عربية/فارسية/لاتينية وأرقامًا هندية، وقارنا مخرجات JS بمخرجات الدوال الأصلية عبر `dart` ⇒ **تطابق حرفي (EXACT MATCH)**.

**النتائج:**

| الكوليكشن | المستندات | التي افتقدت `searchTokens` | بعد التنفيذ |
|---|---|---|---|
| `shops` | 10 | 10 | ✅ 0 متبقٍ |
| `products` | 13 | 13 | ✅ 0 متبقٍ |
| `subscription_requests` | 5 | 5 | ✅ 0 متبقٍ |
| **المجموع** | **28** | **28** | **0 متبقٍ — 28/28 محدَّثة** |

**تحقق إضافي:** استعلام بحث الأدمن الفعلي (`where('searchTokens', arrayContains: token)` + `orderBy(FieldPath.documentId)`) أُجري على الثلاثة كوليكشنز عبر `runQuery` ⇒ نتائج بدون أي خطأ فهرس. لا توجد حاجة لإعادة التشغيل؛ المستندات الجديدة تكتب الحقل تلقائيًا وقت الحفظ.

---

## 14. حزمة نشر Play Console — جاهزة ✅

**الدليل الكامل:** `docs/PLAY_CONSOLE_SUBMISSION_KIT.md` — فيه رابط السياسة (مُتحقَّق أنه حي)، إجابات Data Safety، إجابات تقييم المحتوى، Short/Full description بالعربية والإنجليزية، وخطوات الإدخال في Console.

**الأصول المُنتَجة:**

| الأصل | المسار | الأبعاد | التنسيق |
|---|---|---|---|
| Feature graphic | `store/feature-graphic.png` | 1024×500 | PNG 24-bit بلا alpha |
| لقطة الرئيسية | `store/screenshots/01_home.png` | 1080×1920 | PNG 24-bit |
| لقطة المبيعات | `store/screenshots/02_sales.png` | 1080×1920 | PNG 24-bit (شريط debug أُزيل) |
| لقطة التقارير | `store/screenshots/03_reports.png` | 1080×1920 | PNG 24-bit |
| لقطة المنتجات | `store/screenshots/04_products.png` | 1080×1920 | PNG 24-bit |
| أيقونة 512 | `assets/images/playstore.png` | 512×512 | PNG (جاهزة أصلًا) |

اللقطات التُقطت من التطبيق على محاكي أندرويد حقيقي (بيانات اختبار)؛ الأبعاد 9:16 المؤهلة لتوصيات Play، وكلها `colorType=2` (24-bit RGB بلا شفافية) كما يشترط المتجر.

**خارجي فقط:** لا توجد جلسة Play Console مصادَّقة في متصفح هذه الجلسة، لذا لم تُملأ النماذج فعليًا — الإدخال يتم من مالك الحساب.

---

## 15. تنظيف Analyzer — صفر ملاحظات ✅

**البداية:** 66 issue (5 warnings + 61 infos).
**المنهج:**
1. `dart fix --apply` ⇒ **57 إصلاحًا تلقائيًا في 34 ملفًا** (prefer_initializing_formals، unnecessary_import، unused_import، unnecessary_brace_in_string_interps، unnecessary_underscores، use_key_in_widget_constructors، use_null_aware_elements، curly_braces_in_flow_control_structures).
2. 9 إصلاحات يدوية:
   - حذف متغير غير مستخدم `h` في `activity_view.dart:390`.
   - إضافة `if (!context.mounted) return;` بعد بوابة الاشتراك قبل استخدام `context` في: `quick_actions_grid.dart` (4 مواضع)، `returns_view.dart`، `sales_view.dart`، و`staff_management_view.dart` (موضعان).
   - إزالة TODO قالبي وحيد في `android/app/build.gradle.kts` (`applicationId` مُعيَّن فعلًا).

**النتيجة:**
| الفحص | قبل | بعد |
|---|---|---|
| `flutter analyze` | 66 issues | ✅ **No issues found!** |
| `flutter test` | 227/227 | ✅ **236/236** (Crashlytics + تكامل التدفق + كاش الفترات + widget) |

**تصحيح خطأ سابق في هذا التقرير:** لم يكن هناك 89 TODO في كود Dart — العدّ كان case-insensitive فطابق `to**Do**uble`. فحص حساس للحالة: **0** في `lib/` و`test/` و`tool/` (`docs/HESBA_PROJECT_AUDIT.md` كان قد ذكر ذلك أصلًا).

---

## 16. التحصين التشغيلي — تم محليًا ✅

**الدليل:** `docs/OPERATIONAL_HARDENING.md` (فيه خطوات الـ Console الخارجية بالتفصيل).

| البند | المحلي | الخارجي المتبقي |
|---|---|---|
| **App Check** | `firebase_app_check ^0.3.2+10` + تفعيل عميل في `main.dart` (Play Integrity / App Attest في release، debug في التطوير) — best-effort | تسجيل التطبيق + Play Integrity + debug providers في Firebase Console. **لم يُفرض في القواعد عمدًا** حتى لا نكسر الإنتاج |
| **Crashlytics** | `firebase_crashlytics ^4.3.10` + `AppLogger.remoteReporter` يرسل warning/error كـ non-fatal، مفعّل في release فقط | تفعيل الخدمة في Console + اختبار حدث تجريبي |
| **FCM** | حذف الرمز القديم عند التجديد (`saveToken`)، حذف + إبطال عند الخروج (`clearToken`)، حفظ آخر رمز في SharedPreferences | لا شيء |
| **FCM في القواعد** | `validFcmTokens()` بسقف 50 — **منشورة على الإنتاج** | لا شيء |
| **بيانات FCM** | **18 رمزًا زائدًا أُزيلوا** (9 و19 → 5 و5)؛ الآن max 5/مستخدم | لا شيء |
| **preset الإيصالات** | `cloudinaryReceiptUploadPreset` مستقل + `hasDedicatedReceiptPreset` + توثيق؛ الافتراضي Shared عمدًا | إنشاء `hesba_receipts` في Cloudinary + `--dart-define=...` في بناء الرفع |

**التحقق:** `flutter analyze` نظيف · `flutter test` **236/236** · قواعد Emulator **156/156** (اختبارا `F1`/`F2` الجديدان) · `firebase deploy --only firestore:rules` ناجح · `flutter build apk --release` و `appbundle --release` ناجحان (AAB 72.5MB).

**تحديث مرتبط:** `docs/PLAY_CONSOLE_SUBMISSION_KIT.md` أُضيفت إليه بيانات Crash logs و App integrity في جدول Data Safety.

---

## 17. اختبارات التدفق الكامل + تقليل مسح التقارير ✅

**أ. تكامل التدفق المالي** — `test/integration/full_flow_test.dart` (Repo حقيقي + `fake_cloud_firestore` + auth وهمي):
- بيع آجل → مستند واحد + خصم مخزون + دين بقيمة 200.
- إعادة المحاولة بنفس `requestId` → نفس البيع، **لا خصم مخزون مرتين**.
- مرتجع جزئي → استرداد مخزون + تسوية 100 من الدين + سجل دفعة واحد.
- إعادة محاولة المرتجع → لا استرداد ولا تسوية مكررة.
- طلب تجديد → موافقة أدمن تُطيل الفترة الحية → رفض طلب أحدث **لا يُلغي الفترة المدفوعة** → منع إعادة القرار.

**ب. Widget** — `test/widgets/reports_period_chips_test.dart`: الضغط على شريحة «الكل» يُرسل `ReportPeriod.all`، والشريحة الحالية موسومة `selected`.

**ج. تقليل مسح التقارير** — `ReportsCubit`:
- يتتبّع نافذة البيانات المحمّلة (`_loadedFrom`) بدل إعادة الجلب عند كل تغيير فترة.
- أول اختيار لـ «الكل» فقط هو الذي يعمل مسحًا كاملًا؛ الرجوع لفترة قصيرة ثم العودة لـ «الكل» **بدون أي قراءة إضافية**.
- `refresh()` يحافظ على نفس النافذة (لا يتحول فجأة لمسح كامل).
- `test/reports/period_cache_test.dart` (4 اختبارات) يثبت: bootstrap بنافذة محدودة، مسح كامل واحد، تبديل بلا مسح متكرر، وتحديث بنفس النافذة.

**التحقق:** `flutter analyze` → No issues found · `flutter test` → **236/236** (كانت 228).

---

## 18. جولة P3 الأخيرة ✅

| # | التحسين | الملفات |
|---|---|---|
| S-19 | بطاقة «لوحة التحكم» صارت للأدمن فقط عبر `sl<UserRoleService>().isAdmin` — تقليل سطح الهجوم ومنع تضليل المستخدمين | `drawer_items_list.dart` |
| debugPrint | آخر `debugPrint` مباشر في `add_return_view.dart` أُزيل (الـ `AppLogger.nonFatal` موجود أصلًا) | `add_return_view.dart` |
| iOS APNs | `aps-environment` من `development` إلى `production` | `ios/Runner/Runner.entitlements` |
| دمج `getToday*` | `getTodaySummary()` جديد يقرأ sales/returns/expenses **مرة واحدة لكل كوليكشن** بدل استعلامين (الإجمالي + التقسيم/العدد) — الـ cubit يستخدمه | `dashboard_repo.dart`, `dashboard_repo_impl.dart`, `dashboard_cubit.dart` |
| Activity logs | `getActivityLogs()` (one-shot) + زر/سحب تحديث بدل `watchActivityLogs()` المستمر | `admin_repo.dart`, `admin_repo_impl.dart`, `activity_view.dart` |
| الإعدادات | `AppSettingsService.refresh()` + `FeatureFlagsService.refresh()` في الـ splash مرة واحدة؛ الـ banner يقرأ من الكاش | `splash_view.dart`, `subscription_banner.dart` |

**التحقق:** `flutter analyze` → No issues found · `flutter test` → **236/236** (تحديث اختبار `no_live_collection_listeners` ليعكس قراءة واحدة/كوليكشن).

---

## 19. استعداداً لـ 100 محل — تجميع أرباح الأدمن ✅

**المشكلة:** `profitSummary()` كانت تعمل مسح كامل (حتى 20 ألف فاتورة + 10 آلاف مرتجع) في كل فتح للوحة الأدمن — مع 100 محل كانت الأرقام هتكون `capped` وغير دقيقة.

**الحل:**
- مستند واحد `admin_rollups/platform` فيه الإجماليات + السلاسل الشهرية.
- `profitSummary()` تقرأ المستند ده (**قراءة واحدة**) وتعمل `fallback` للمسح القديم لو مش موجود (ترقية آمنة).
- `rebuildPlatformRollup()` تعمل المسح مرة واحدة وتكتب المستند — **قاعدة Firestore تسمح للأدمن فقط**.
- زر «إعادة حساب الإجماليات» (آلة حاسبة) في رأس لوحة التحكم يستدعيها.
- **مهم:** لازم تضغط الزر مرة واحدة بعد النشر (أو تجدول مهمة) عشان يتولد المستند الأول. بعدها اللوحة بتقرأ مستندًا واحدًا.

**التحقق:** `flutter analyze` نظيف · `flutter test` **243/243** (3 اختبارات جديدة للتجميع) · قواعد Emulator **156/156** · القواعد منشورة على الإنتاج.

---

## 20. تثبيت تابات الأدمن — قراءة واحدة لكل تاب ✅

**المشكلة:** `_page(index)` في `admin_shell` كان بينشئ `BlocProvider` + cubit جديد مع كل تبديل تاب، فبيحصل `..load()` / `..firstPage()` من جديد (قراءات Firestore متكررة + فقدان الـ pagination).

**الحل (ملف واحد `admin_shell.dart`):**
- `AdminShell` بقى `StatefulWidget` مع `_pages` محفوظة و **IndexedStack كسول** — كل صفحه بتتبنى مرة واحدة عند أول زيارة وبتفضل حية.
- تبديل التابات **صفر قراءة** — الـ cubit والبيانات محفوظة.
- **تحديث ذكي عند الرجوع**: لو التاب زارته قبل أكتر من 60 ثانية بيحصل `load()`/`firstPage()` تلقائي (عشان البيانات ما تقبلش)، غير كده بيُعاد استخدام المخزن.
- الـ pull-to-refresh الموجود في كل صفحة شغال كما هو للتحديث اليدوي الفوري.
- الجرس (الطلبات المعلقة) لسه `late final` — مستمع واحد مش more-at-all.

**النتيجة:** أفضل سيناريو — بيانات جاهزة فورًا عند التبديل + تحديث عند الحاجة + ريفرش يدوي + أقل قراءات ممكنة.

**التحقق:** `flutter analyze` نظيف · `flutter test` **244/244** (اختبار جديد يثبت إن الرجوع لتاب ما بينشئش صفحة جديدة).

---

*التقرير يعكس الحالة عند `3900a19` في 21 نوفمبر 2026. عند تنفيذ مهام §9 يُعاد تشغيل الأوامر في §10 وتُحدَّث الأرقام.*
