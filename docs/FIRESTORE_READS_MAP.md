# تقرير تحسين قراءات Firestore — النسخة النهائية

> **التاريخ:** 21 Nov 2026 · **نوع التحليل:** فحص كود + اختبارات آلية (مش قياس فاتورة فعلي — الـ CLI هنا بيرجع 403 على `hesba-business`).
> **الحالة:** كل التعديلات المذكورة هنا **منفّذة ومختبرة** في الـ working tree. التغييرات لسه **مش commit**.

---

## 1. الملخص التنفيذي

| المؤشر | قبل | بعد |
|---|---|---|
| مواضع `.snapshots()` في الكود | 28 | **15** |
| مستمعات لحظية تعمل فعلياً (وقت التشغيل) | ~31 | **~15** |
| قراءة `users/{uid}` لكل عملية بيع/مرتجع/مصروف | 1+ | **0** (من الكاش) |
| بحث الأدمن في أسوأ حالة | ~30,000 قراءة | **قراءة واحدة لكل نتيجة** |
| اختبارات ناجحة | 201 | **226** |
| `flutter analyze` | 0 أخطاء / 67 info | **0 أخطاء / 66 info** |

**التقدير التقريبي** لمحل متوسط (2,000 فاتورة + 500 منتج + 300 مرتجع + 300 مصروف، يفتح الرئيسية 15 مرة/يوم):
كان ~46,500 قراءة/يوم (تكسر حد الـ 50k المجاني في يوم واحد) → **أقل من 1,000 قراءة/يوم**.

**القاعدة اللي اتبعناها:** `.snapshots()` يقرأ كل مستند في نطاق الاستعلام عند الفتح ويعيد القراءة مع أي تغيير؛ `.get()` يقرأ مرة واحدة عند الطلب. فكل حاجة مش محتاجة لحظية اتحوّلت لقراءة عند الطلب + تحديث بعد العمليات.

---

## 2. اللي اتعمل (6 مسارات)

### 2.1 الداشبورد
- **شيلنا** الـ 4 listeners غير المحدودين على `sales/products/returns/expenses` (`watchDashboardChanges()`). كانوا بيقرأوا كل المستندات عند كل فتح ويعيدوا القراءة مع أي كتابة — والـ `AppEvents` أصلاً بيعمل refresh بعد العمليات المحلية.
- **شيلنا** 3 listeners لكرت «آخر حركة» وحوّلناهم لـ `getLastSale/Return/Expense` بـ `.get()`.
- الكروت بقت `FutureBuilder` بتعيد القراءة لما `DashboardState.refreshRevision` يتغير — والـ revision بيتزود مع كل تحميل ناجح. يعني `AppEvents` والسحب للتحديث و`refresh()` كلهم بيحدّثوا الأرقام والكروت من نفس المصدر.
- ملفات: `dashboard_repo.dart`, `dashboard_repo_impl.dart`, `dashboard_cubit.dart`, `dashboard_state.dart`, `home_recent_movements.dart`, `home_view.dart`.

### 2.2 التقارير
- **شيلنا** الـ 3 triggers (`watchLatestSale/Return/Expense`) اللي كانوا بيعملوا جلب كامل للتاريخ عند كل إضافة — وحذفنا الدوال من الـ 3 repos.
- التقارير بقت بتتحمل مرة واحدة عند فتح الشاشة، وبتتجدد عبر `AppEvents` مع **debounce 500ms** (عشان أكتر من حدث في نفس اللحظة ما يعملوش جلبين)، وبالسحب للتحديث عبر `refresh()` (من غير إعادة قراءة `users/{uid}`).
- تحسين جانبي: تعديل/حذف مصروف قديم دلوقتي بيظهر في التقارير — الـ trigger القديم كان بيراقب أحدث مستند بس.
- ملفات: `reports_cubit.dart`, `reports_view.dart` + حذف الدوال من `sales/returns/expenses` repo واجهة وتنفيذ.

### 2.3 كاش الـ shopId
- ملف جديد `lib/core/services/shop_id_resolver.dart` — مصدر موحّد: `provided` → كاش `UserRoleService` (بشرط `cachedUid == uid`) → قراءة واحدة كـ fallback.
- أضفنا `cachedUid` و `cachedShopName` في `UserRoleService` (اتقرأوا من نفس مستند المستخدم — مفيش قراءة زيادة) واتصفّوا في `clear()` عند تبديل الحساب.
- الـ 11 ملف في القائمة بقت تستخدم المصدر ده، بما فيها `ShopResolver`.
- استثناء مقصود: `category_repo_impl.getShopContext()` لسه بيقرأ المستند لأنه محتاج `businessType` مش shopId بس.

### 2.4 قوائم الموردين/الموظفين/الأقسام/البروفايل
- `watchStaff` → `getStaff`، وحذف `watchSuppliers` و`watchCustomCategories` و`watchProfile` (النسخ الـ `get*` كانت موجودة أصلاً).
- `watchLinkedProductCounts` → `getLinkedProductCounts`.
- الـ cubits بقت بتحمل عند فتح الشاشة وبتعيد التحميل بعد كل عملية كتابة (إضافة/تعديل موظف، حذف مورد، إضافة/حذف قسم، تعديل بروفايل).
- `product_form_view.dart`: `_catSub` listener → `getCustomCategories()` مرة واحدة.
- **تنبيه:** `account_repo_impl.dart` في الطلب كان المقصود به ملف البروفايل (`features/profile/...`)؛ أما `features/accounts/...` فعنده 4 listeners لسه (ديون/أشخاص/مدفوعات) ومش ضمن النطاق.

### 2.5 بحث الأدمن — `searchTokens` + فهارس
- **ما اتخفضش السقف** (كان هيخفي المستندات اللي بعده). اتشال المسح أصلاً واتاستبدل باستعلام مفهرس.
- ملف جديد `lib/core/utils/search_tokens.dart`: بيولّد كل مقاطع النص الموحّد (أرقام عربية/فارسية → لاتينية + lowercase) + مقاطع التليفون.
- الـ tokens بتتكتب وقت الحفظ في: `shops` (عند التسجيل وعند تعديل البروفايل)، `products` (إضافة/تعديل)، `subscription_requests` (إرسال الطلب).
- البحث بقى `where('searchTokens', arrayContains: q)` + `orderBy(__name__)` + pagination بنفس الـ cursor API — قراءة لكل نتيجة بدل مسح 10k مستند/كوليكشن.
- 3 فهارس جديدة في `firestore.indexes.json`. القواعد اتُراجعت: مفيش `hasOnly` تعترض الحقل الجديد.

### 2.6 pagination في البحث
- `AdminSearchPage` + `AdminSearchCursor` + `loadMore()` + زر «تحميل المزيد».
- المستند رقم 3000 (وأي رقم بعده) بيتوصل له — مفيش سقف إجمالي صامت.

---

## 3. اللي لسه لحظي (مقصود)

| الملف | العدد | السبب |
|---|---|---|
| `dashboard_repo_impl.dart` | 1 | هوية المحل (اسم/صورة) — مستند واحد |
| `subscription_repo_impl.dart` | 1 | الـ `SubscriptionGate` لازم يفتح فور موافقة الأدمن |
| `admin_repo_impl.dart` | 2 | طلبات الاشتراك الجديدة (لازم تظهر فوراً) + سجل النشاط |
| `products_repo_impl.dart` | 1 | المخزون بيتغير كتير |
| `sales_repo_impl.dart` | 2 | قوائم المبيعات الحيّة |
| `returns_repo_impl.dart` | 2 | قوائم المرتجعات الحيّة |
| `expenses_repo_impl.dart` | 2 | قوائم المصروفات الحيّة |
| `accounts_repo_impl.dart` | 4 | الديون/الأشخاص/المدفوعات |

**مقايضة مهمة:** التحديث اللي كان بيجي من **جهاز تاني** (موظف سجّل بيعة والصاحب فاتح الرئيسية) لم يعد لحظياً في الداشبورد والتقارير — المطلوب سحب للأسفل أو إعادة فتح الشاشة. داخل نفس الجهاز الـ `AppEvents` بيحدّث كل حاجة فوراً.

---

## 4. التحقق اللي اتعمل

| الفحص | النتيجة |
|---|---|
| `flutter test` | **226/226 نجحوا** (من 201) |
| `flutter analyze` | **0 أخطاء**، 66 info (أقل من الـ baseline بواحدة) |
| `firestore.indexes.json` | صالح JSON |
| اختبارات جديدة | 25 — في `test/dashboard/`, `test/reports/`, `test/performance/`, `test/admin/` |

الاختبارات بتثبت تحديداً: مفيش collection listeners في الداشبورد، الـ `AppEvents` بيعمل reload، الـ revision بيتزود مع كل تحميل، الكاش بيقرأ صفر مرات، كاش حساب قديم بيتتجاهل، الـ backfill بيشتغل مرة واحدة، والـ pagination بيوصل لمستند بعيد.

---

## 5. المطلوب منك بره الكود (قبل النشر)

1. **نشر الفهارس:** ✅ **تم في 21 Nov 2026** على `hesba-business` (`Deploy complete!`، 18 منشورة = 18 محلية).
   > أثناء النشر رفض Firestore الفهارس الثلاثة الخاصة بـ `searchTokens` (shops/products/subscription_requests) لأنها «غير ضرورية — تُضبط بـ single-field index controls»؛ حُذفت من `firestore.indexes.json` (21 → 18) لأن استعلام `arrayContains + orderBy(__name__)` يكفيه الفهرس التلقائي.
   ```
   firebase deploy --only firestore:rules,firestore:indexes --project hesba-business
   ```
2. **تشغيل الـ backfill مرة واحدة** ✅ **تم في 21 Nov 2026**: 28 مستندًا قديمًا (10 محلات + 13 منتج + 5 طلبات اشتراك) أخذت `searchTokens`؛ إعادة الفحص 0 متبقٍ، واستعلام البحث المفهرس اختُبر على الإنتاج بنجاح. (`AdminSearchRepo.backfillSearchTokens()`).
3. **إعادة بناء الـ AAB** من الـ HEAD الحالي بعد كل التعديلات.
4. ملاحظات قديمة من التدقيق لسه مفتوحة على حدة: تدوير الـ keystore، نشر/تحقق قواعد Firestore، ونماذج Play Console.

---

## 6. اللي قبل يتعمل اختيارياً

- خطوة 7: دمج استعلامات `getToday*` الستة في الداشبورد في استعلام مجمّع.
- تحويل `watchActivityLogs()` في الأدمن لـ `get()` + زر تحديث.
- تحويل قوائم المبيعات/المرتجعات/المصروفات لـ pull-to-refresh (توفير أكبر مقابل تغيير UX بسيط).
- تقليل استدعاءات `AppSettingsService.refresh()` / `FeatureFlagsService.refresh()` لتكون مرة واحدة عند الـ splash.

---

## 7. إصلاحات ما بعد الـ Audit (21 Nov 2026)

بناءً على مراجعة مستقلة، اتنفّذت 4 إصلاحات:

| # | الإصلاح | الملف |
|---|---|---|
| C2 | **تبديل التابات بقى ما يعيدش إنشاء الصفحات** — شيلنا الـ `KeyedSubtree(key: ValueKey(currentIndex))` من داخل `AnimatedSwitcher` ورجّعنا `IndexedStack` ثابت. الـ cubits والمستمعات والتقارير ما تتعملش من جديد عند كل تبديل. **المقايضة:** الأنيميشن (fade/scale 280ms) اختفى. | `main_layout.dart:161-175` |
| — | أضفنا `RefreshIndicator` لحالة «المبيعات الفاضية» عشان كل تاب له سحب للتحديث. | `sales_view.dart:65-87` |
| C1 | `watchPendingRequestsOnce()` بقى عليه `.limit(100)`، والشارة بتعرض «99+». القائمة الحقيقية أصلاً مقسّمة بـ `getRequestsPage(limit:20)`. | `admin_repo_impl.dart:78-86`، `admin_shell.dart:202` |
| D1 | tokens بتاعة المحل وقت تعديل البروفايل بقت تستخدم `shopPhone` (زي التسجيل والـ backfill) بدل هاتف المالك. | `account_repo_impl.dart:81-88` |
| D2 | بعد `updateProfile` بنادي `UserRoleService.reload()` عشان كاش اسم المحل ما يفضلش قديم. | `profile_cubit.dart:68-72` |

**التحقق:** `flutter test` → **227/227** (اختبار جديد في `test/profile/profile_cache_consistency_test.dart` بيثبت D1 وD2 مع بعض) · `flutter analyze` → 0 أخطاء، 66 info.

> **ملاحظة للaudit الأصلي:** الـ 4 إصلاحات دول بيغلقوا C1 وC2 وD1 وD2. الباقي من تقرير الـ audit (سقف 20 حرف، التطبيع العربي، تحقّق القواعد من `searchTokens`، الـ backfill، الفهرس الناقص `generatedFrom`) **لسه مفتوح** ولم أغيّره.

---

*نهاية التقرير.*
