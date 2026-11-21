# تدوير مفتاح رفع Play (Upload Key Rotation)

## الحالة

**الوضع قبل الإصلاح:** ملف `hesba-upload-key.keystore` كان مودعاً في Git
(الالتزامات `cfe650b "key store"` و `c446db6`)، ومطابقاً بايت-ببايت
(MD5 `a7d3724c8e4956479c41f0e6cef4d59b`) لمفتاح التوقيع المستخدم فعلياً في
`app-release.aab`. أي شخص يملك نسخة من المستودع يملك مفتاح الرفع.

**ما تم تنفيذه محلياً:**

- ✅ توليد مفتاح رفع **جديد بالكامل** (RSA 2048, SHA384withRSA,
  صالح حتى 2054) في `android/app/hesba-upload-key.keystore`.
- ✅ إنشاء `android/key.properties` بالبيانات الجديدة (مُتجاهل في Git).
- ✅ إلغاء تتبع النسخة المسرَّبة (`git rm --cached`) وحذفها من القرص.
- ✅ إضافة `*.keystore` و `*.jks` إلى `.gitignore` الجذري (النسخة الجذرية
  كانت تتجاوز `android/.gitignore`).
- ✅ `git ls-files` لا يُظهر أي keystore بعد الآن.

## ⚠️ خطوة إلزامية لم تُنفَّذ — يجب أن تقوم بها في Play Console

المفتاح الجديد **لن يعمل للرفع** حتى تُسجّل شهادته لدى Google. مفتاح توقيع
التطبيق (App Signing key) الذي تحتفظ به Google **لا يتغير**، لذا المستخدمون
الحاليون لا يتأثرون. خطواتPlay Console:

1. افتح **Play Console → التطبيق → Setup → App integrity (App Signing)**.
2. اضغط **Request upload key reset** (أو "Reset upload key") واتبع الإرشادات.
3. عند الطلب، أرفع ملف الشهادة العامة للمفتاح الجديد. لتوليده:

   ```powershell
   keytool -export -rfc -alias hesba-upload `
     -keystore android\app\hesba-upload-key.keystore `
     -file upload-key-cert.pem
   ```

   (أو الصق بصمة SHA-256 أدناه إذا طلبت Console هذه المعلومة).

4. بعد الموافقة، أعد بناء الحزمة وارفعها:

   ```powershell
   flutter clean
   flutter pub get
   flutter build appbundle --release
   ```

5. تأكد أن الرفع نجح وأن بصمة شهادة الرفع في Console تطابق الأدناه.

### بصمة الشهادة الجديدة (للتحقق في Play Console)

- **SHA-256:**
  `62:7E:E2:F4:DF:F1:A6:DD:D8:39:2B:63:15:D2:E5:71:9D:59:A5:10:02:F4:00:32:F3:C1:B1:27:EE:71:D1:EE`
- **SHA-1:**
  `AE:76:87:97:CC:65:81:9C:E8:BD:25:35:E3:B6:C3:FB:52:71:F1:15`
- **DN:** `CN=Hesba Upload, OU=Hesba, O=Hesba, L=Cairo, ST=Cairo, C=EG`
- **Alias:** `hesba-upload`

## بيانات الاعتماد (للاستخدام المحلي / CI)

موجودة في `android/key.properties` (غير مودعة). انسخها إلى أسرار CI لديك
كملف `android/key.properties` + ملف `android/app/hesba-upload-key.keystore`
(أو كأسرار منفصلة تُكتب أثناء البناء). **لا ترفعها إلى أي مستودع.**

## تنظيف اختياري لتاريخ Git ( defense in depth )

بما أن المفتاح تم تدويره، المفتاح المسرب لم يعد صالحاً للرفع بعد إعادة التعيين
في Play Console، لذا بقاءه في التاريخ غير القديم لا يُمكّن أحداً من النشر.
ومع ذلك، لإزالته من التاريخ تماماً (يتطلب تنسيقاً مع الفريق و **force push**):

```powershell
# بعد تثبيت git-filter-repo
git filter-repo --path hesba-upload-key.keystore --invert-paths
git push origin --force --all
git push origin --force --tags
```

> ⚠️ لا تنفّذ هذا إلا بالتنسيق مع كل من لديه clone، لأنه يعيد كتابة التاريخ
> ويحتاج force-push. كما أن المستودع عام، فالتاريخ المنشور ربما تم نسخه بالفعل
> بواسطة روبوتات — التدوير (الذي تم) هو الإجراء الحاسم، وليس تنظيف التاريخ.

## قائمة تحقق قبل النشر

- [ ] تمت إعادة تعيين مفتاح الرفع في Play Console وتسجيل الشهادة الجديدة.
- [ ] بصمة SHA-256 في Console تطابق المذكورة أعلاه.
- [ ] `git ls-files` لا يُظهر أي `.keystore` / `.jks`.
- [ ] `git check-ignore -v android/app/hesba-upload-key.keystore` يُظهر تجاهلاً.
- [ ] `flutter build appbundle --release` ينجح ويُوقَّع بالمفتاح الجديد.
- [ ] تم رفع AAB بنجاح إلى Play Console.
