# Error Handling & Logging — نظرة عامة

## المشكلة قبل التعديل
- ~150 catch صامت أو `debugPrint` مبعثر، بلا استثناءات مسجلة، بلا مكدسات، ولا سجل مركزي.

## ما تم
- **`AppLogger`** (`lib/core/services/app_logger.dart`) — سجل مركزي داخلي:
  - `AppLogger.nonFatal(context, error, stackTrace, {severity})` — نقطة موحّدة تُستدعى من كل catch غير قاتل في المشروع.
  - `debug/info/warning/error` — مستويات عادية.
  - حلقة ذاكرة (Ring Buffer) بحد أقصى **300 حدث** — الأحدث يحتفظ، الأقدم يُسقط.
  - في **debug** تُطبع كل المستويات؛ في **release** تُطبع `warning`/`error` فقط (الحلقة تتسجل دائمًا).
  - **`installGlobalHandlers()`** في `main.dart` — يلتقط `FlutterError.onError` و`PlatformDispatcher.onError`، و`runZonedGuarded` يلتقط أخطاء الـ zone غير المتزامنة.
- كل catch في `lib/` (161 موقعًا) أصبح يمر عبر `AppLogger.nonFatal` بسياق المسار الكامل للملف — الأخطاء اللي فيها `AppToast.error` أو `rethrow` اتسجّلت بشدة `error`، والباقي `warning`.
- `logError/logSuccess/logWarning` (`core/extensions/log_util.dart`) أصبحت غلافات توافقية فوق `AppLogger` — الاستخدامات القديمة الـ37 شغالة كما هي وتوجّه للسجل المركزي.
- **شاشة التشخيص** (`DiagnosticsView`) — من إعدادات المنصة (الأدمن) → زر «سجل التشخيص»: تعرض آخر الأحداث (الأحدث أولًا) مع الرسالة والسياق وstackTrace، مع نسخ الكل ومسح السجل.
- **لا شيء يُخزَّن على القرص ولا يُرسل لأي خدمة خارجية** — الحلقة في الذاكرة فقط وتُمسح بإغلاق التطبيق.

## قواعد الاستخدام
1. أي catch جديد **لا** يكون صامتًا: ضع `AppLogger.nonFatal('مسار/الملف', err, st)` فيه كأول سطر.
2. severity: `error` للأخطاء التي تؤثر في العملية أو تُعرض للمستخدم (toast أحمر / rethrow)، `warning` لكل شيء آخر (fallbacks, best-effort).
3. لا ترمي استثناءات من مسارات جاهزة "تعمل بشكل أفضل" (e.g. best-effort) — فقط سجّلها.
4. لو الخطأ يتطلب إيقاف العملية → `rethrow`/ارجع حالة خطأ واضحة (كما تفعل الـ cubits حاليًا) — `nonFatal` للتسجيل فقط ولا تغيّر التحكم في التدفق.

## حدود معروفة
- لا يوجد crash reporting خارجي (Crashlytics/Sentry) — القرار الحالي داخلي فقط.
- الحلقة تُمسح مع إغلاق التطبيق (لا حفظ دائم). لإضافة إرسال خارجي لاحقًا: أضف `ErrorSink` مخصص داخل `AppLogger._record` بدون تغيير النداءات الـ161.
