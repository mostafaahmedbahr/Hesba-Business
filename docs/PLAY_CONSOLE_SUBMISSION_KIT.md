# حزمة نشر Play Console — حسبة (HESBA)

> **التاريخ:** 21 نوفمبر 2026 · كل ما أدناه جاهز للقص/اللصق أو الرفع مباشرة في Play Console.
> **تنبيه:** لا توجد جلسة مصادقة لـ Play Console في المتصفح الخاص بهذه الجلسة، لذا لم أملأ النماذج فعليًا — هذه الحزمة هي كل المطلوب لتفعلها أنت/مالك الحساب.

---

## 1. رابط سياسة الخصوصية (Store listing)

**الرابط (انسخه كما هو):**
```
https://www.freeprivacypolicy.com/live/b331026f-9deb-428d-8ad5-614ede1fdec5
```
- ✅ تم التحقق: الصفحة حية بعنوان `Privacy Policy for حسبة`، آخر تحديث 17 نوفمبر 2026.
- ✅ الرابط موجود داخل التطبيق في مكانين: درج «سياسة الخصوصية» + موافقة التسجيل.
- ضعه في: **Grow users → Store presence → Main store listing → Privacy policy**.

---

## 2. Data Safety — الإجابات المقترحة

القاعدة: ما يجمعه التطبيق فعليًا (من الكود + sepolicy المنشورة). اختر **Yes** واربط الغرض بـ **App functionality / Account management** غالبًا.

| البيانات | Collected? | الغرض (Purpose) | Shared? | ملاحظة من الكود |
|---|---|---|---|---|
| Email address | ✅ Yes | App functionality + Account management | No* | Firebase Auth (`firebase_auth`) |
| Name (اسم المالك واسم المحل) | ✅ Yes | App functionality + Account management | No* | `users/{uid}`, `shops/{id}` |
| Phone number | ✅ Yes | App functionality + Account management | No* | أرقام العملاء/الموردين والهاتف |
| Physical address (عنوان المحل) | ✅ Yes | App functionality | No* | تسجيل المحل/الملف الشخصي |
| Location (تقريبة/دقيقة) | ✅ Yes | App functionality | No* | `geolocator` + `geocoding` — بإذن المستخدم |
| Photos / Camera | ✅ Yes | App functionality | No* | صور المنتجات + إيصالات الدفع → Cloudinary |
| Device or other IDs | ✅ Yes | App functionality | No* | رموز FCM في `users/{uid}.fcmTokens` |
| App activity / Usage data | ✅ Yes | App functionality | No* | `activity_logs` + سجل تشخيص داخلي (`AppLogger`) |
| Crash logs / Diagnostics | ✅ Yes | App functionality + Security | No* | `firebase_crashlytics` — أخطاء non-fatal في release فقط |
| App integrity / device info | ✅ Yes | Security | No* | `firebase_app_check` (Play Integrity / App Attest) |
| IP address / device info | ✅ Yes | App functionality + Security | No* | Firestore/Firebase تلقائيًا |

> *****_shared_: هذه البيانات تُرسل إلى مزوّدي الخدمة (Google Firebase و Cloudinary) لمعالجتها نيابةً عنّا. إذا كان نموذج Play يصنّف ذلك كـ "Shared with third parties"، فعّل **Shared** واذكر: `Google Firebase (Auth, Firestore, Cloud Messaging, Crashlytics, App Check)` و `Cloudinary`. وإلا اتركها **Collected only** — كلا الخيارين شائعان، الأهم هو الاتساق مع سياسة الخصوصية.

- **Encrypted in transit:** ✅ Yes (HTTPS لكل Firestore/Cloudinary).
- **Data deletion:** ✅ **Yes** — التطبيق فيه «حذف الحساب» (إعادة مصادقة بكلمة المرور + طلب مُتتبَع في `account_deletion_requests`)، وتُنفَّذ يدويًا خلال المدة في السياسة. يجب أن يتطابق هذا مع إجابة Play.
- **No ads, no sale of data, no third-party ad/tracking SDK** (لا يوجد AdMob ولا Analytics للإعلانات). التقارير داخلية + Crashlytics مخصصة للتشخيص الأمني فقط.

**أسئلة إضافية متوقعة:**
- "Does your app collect any personal data?" → **Yes**.
- "Is data processed ephemerally?" → **No** (مخزّنة في Firestore).
- "Target audience under 16?" → **No** (السياسة: 16+، والتطبيق للأعمال).

---

## 3. تقييم المحتوى (Content rating questionnaire)

| السؤال | الإجابة المقترحة |
|---|---|
| Target age group | 16+ / Adults (تطبيق أعمال) |
| Violence / gore | None |
| Sexual content / nudity | None |
| Bad language | None |
| Gambling / alcohol / tobacco / drugs | None |
| Ads | No ads |
| In-app purchases (digital) | الاشتراكات digital — نعم، اشتراكات رقمية داخل التطبيق (خطط 30/90/180/365 يومًا). فعّل "In-app purchases" إن ظهر السؤال. |
| Users interact / chat | No (لا دردشة ولا تفاعل بين المستخدمين) |
| User-generated content | الإجابة الأدق: **No public UGC** — أسماء المحلات/المنتجات ورسائل التواصل تُرى داخل حساب المحل وللأدمن فقط، وليست منشورة للعامة. إن أجبر النموذج على اختيار: اختر `Yes → Unmoderated` وانتظر تقييم أعلى (Teen) — لا يوجد/moderation حاليًا. |
| Asked for personal info? | Yes — عند التسجيل (بموافقة المستخدم) |

النتيجة المتوقعة: **Everyone** أو **Teen** فقط في حال تصنيف المحتوى المُنشأ كـ unmoderated.

---

## 4. نصوص Store listing

### Short description (≤80 حرفًا)

**العربية:**
```
حسبة: مبيعاتك وديونك ومخزونك وتقاريرك في تطبيق واحد، بسهولة وسرعة.
```
**English:**
```
Hesba: sales, debts, stock and reports in one simple app for your shop.
```

### Full description (Arabic)

```
حسبة — تطبيق إدارة محلك من جوالك

حوّل دفترك الورقي إلى نظام متكامل: سجّل المبيعات نقدًا أو بالبطاقة أو آجلًا، وأصدر الفاتورة فورًا، وتابع المخزون والتكلفة والربح بدقة.

أهم المزايا:
• مبيعات ومرتجعات: فواتير، خصومات، تسوية ديون البيع الآجل، واسترداد المخزون تلقائيًا.
• ديون العملاء والموردين: سجل مدفوعات كامل وأرصدة محدثة.
• منتجات وموردون: أصناف، متغيرات، صور، أسعار شراء وبيع، وتنبيهات المخزون المنخفض.
• مصروفات وتذكيرات: مصروفات يومية ومتكررة مع تنبيهات.
• تقارير ورسوم بيانية: صافي المبيعات والتكلفة والربح حسب الفترة.
• لوحة تحكم للأدمن لإدارة المحلات والاشتراكات.
• تجربة مجانية، ثم باقات شهرية وربع سنوية ونصف سنوية وسنوية.
• عربي أولًا مع دعم كامل للغة الإنجليزية ووضع ليلي.

سياسة الخصوصية: https://www.freeprivacypolicy.com/live/b331026f-9deb-428d-8ad5-614ede1fdec5
للدعم: hesbabusiness1@gmail.com
```

### Full description (English)

```
Hesba — run your shop from your phone

Replace the paper notebook with one complete system: record cash, card or credit sales, print an invoice instantly, and track stock, cost and profit accurately.

Key features:
• Sales & returns: invoices, discounts, automatic stock reversal and credit-settlement.
• Customer & supplier debts with a full immutable payment ledger.
• Products & suppliers: categories, variants, photos, cost/sell prices and low-stock alerts.
• Expenses & reminders: daily and recurring expenses with notifications.
• Reports & charts: net sales, cost and profit for any period.
• Admin dashboard for shops and subscriptions.
• Free trial, then monthly / quarterly / semi-annual / annual plans.
• Arabic-first with full English support and dark mode.

Privacy policy: https://www.freeprivacypolicy.com/live/b331026f-9deb-428d-8ad5-614ede1fdec5
Support: hesbabusiness1@gmail.com
```

---

## 5. الأصول الجاهزة للرفع

| الأصل | المسار | الأبعاد | الحالة |
|---|---|---|---|
| أيقونة التطبيق | `assets/images/playstore.png` | 512×512 PNG | ✅ جاهز (452KB، ≤1MB) |
| Feature graphic (مطلوب للنشر) | `store/feature-graphic.png` | 1024×500 PNG | ✅ جُهّز من أيقونة التطبيق |
| لقطة 1 — الرئيسية | `store/screenshots/01_home.png` | 1080×1920 | ✅ |
| لقطة 2 — المبيعات | `store/screenshots/02_sales.png` | 1080×1920 | ✅ (شريط تحذير debug أُزيل) |
| لقطة 3 — التقارير | `store/screenshots/03_reports.png` | 1080×1920 | ✅ |
| لقطة 4 — المنتجات | `store/screenshots/04_products.png` | 1080×1920 | ✅ |

اللقطات التُقطت من التطبيق الفعلي على محاكي أندرويد (بيانات اختبار). 1080×1920 = 9:16 ⇒ مؤهلة لقوائم توصيات Play (4 لقطات بـ 1080+).

---

## 6. خطوات يدوية في Play Console (لم تُنفَّذ)

1. **Main store listing:** الصق رابط السياسة + الملف الشخصي/الوصف (§1، §4).
2. **Graphics:** ارفع الأيقونة + الـ feature graphic + اللقطات الأربع (§5).
3. **App content → Data safety:** أدخل إجابات §2، ثم احفظ وأرسل.
4. **App content → Content rating:** أجب حسب §3، ثم اطلب التقييم.
5. **App content → Data deletion:** فعّل رابط/تعليمات الحذف واربطها بالسياسة + البريد.
6. **Publishing overview:** تأكد أن «Store listing changes» جاهزة للمراجعة — لا تحتاج رفع AAB جديد لتغييرات القائمة.
7. بعد إعادة تعيين مفتاح الرفع (§11 من التقرير)، ارفع `build/app/outputs/bundle/release/app-release.aab` (72.3MB، 21 نوفمبر).

> هذه التغييرات **خارجية** ولا يمكن إجراؤها من الكود أو Firebase CLI؛ المتصفح في هذه الجلسة لا يحمل جلسة Play Console.
