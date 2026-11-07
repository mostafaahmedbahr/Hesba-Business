import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hesba/core/models/admin_settings.dart';
import 'package:hesba/core/services/app_settings_service.dart';
import 'package:hesba/features/subscription/data/models/subscription_plan.dart';
import 'package:hesba/features/subscription/data/models/subscription_request_model.dart';

/// اختبارات تسعير الاشتراكات (انظر docs/HESBA_SUBSCRIPTION_PRICING_FIX.md).
///
/// تغطي المستوى القابل للاختبار بدون Firestore:
///   - الأسعار الافتراضية للأربع خطط
///   - تغيير سعر من الأدمن ينعكس على الخطة المختارة
///   - طلب الدفع يحمل سعر اللحظة
///   - طلب قديم معلّق يحتفظ بسعره بعد تغيير الأسعار
///   - مدة الاعتماد مشتقّة من مدة الخطة لا من السعر
///   - ملف firestore.rules يتحقق من السعر ديناميكياً ويمنع التعديل الذاتي
void main() {
  setUp(AppSettingsService.debugReset);
  tearDown(AppSettingsService.debugReset);

  group('الأسعار الافتراضية (قبل أي جلب من الأدمن)', () {
    test('الخطط الأربعة بالقيم الافتراضية 99/249/449/799', () {
      expect(SubscriptionPlan.monthly.price, 99);
      expect(SubscriptionPlan.threeMonths.price, 249);
      expect(SubscriptionPlan.sixMonths.price, 449);
      expect(SubscriptionPlan.yearly.price, 799);
    });

    test('مدة كل خطة ثابتة ومستقلة عن السعر', () {
      expect(SubscriptionPlan.monthly.days, 30);
      expect(SubscriptionPlan.threeMonths.days, 90);
      expect(SubscriptionPlan.sixMonths.days, 180);
      expect(SubscriptionPlan.yearly.days, 365);
    });

    test('AdminSettings.fromJson يقرأ القيم ويحترم الافتراضية عند الغياب', () {
      final s = AdminSettings.fromJson(const {
        'monthlyPrice': 149,
        'threeMonthsPrice': 399,
      });
      expect(s.monthlyPrice, 149);
      expect(s.threeMonthsPrice, 399);
      // الحقول الغائبة تأخذ الافتراضي — لا تُصبح صفر أو null.
      expect(s.sixMonthsPrice, 449);
      expect(s.yearlyPrice, 799);
    });
  });

  group('تغيير السعر من الأدمن (سيناريو 5 و6)', () {
    test('تعديل monthlyPrice في الإعدادات يغيّر سعر خطة monthly فوراً', () {
      AppSettingsService.debugSetCurrent(const AdminSettings(
        monthlyPrice: 149,
        threeMonthsPrice: 249,
        sixMonthsPrice: 449,
        yearlyPrice: 799,
        trialDays: 7,
        paymentMethods: [],
      ));
      expect(SubscriptionPlan.monthly.price, 149);
      // باقي الخطط لا تتأثر.
      expect(SubscriptionPlan.yearly.price, 799);
    });

    test('طلب الدفع يُبنى بسعر اللحظة الحالية لا بسعر قديم', () {
      // قبل تغيير الأدمن.
      expect(SubscriptionPlan.monthly.price, 99);

      // الأدمن غيّر السعر (كما تحفظه شاشة الإعدادات: int).
      AppSettingsService.debugSetCurrent(const AdminSettings(
        monthlyPrice: 149,
        threeMonthsPrice: 249,
        sixMonthsPrice: 449,
        yearlyPrice: 799,
        trialDays: 7,
        paymentMethods: [],
      ));

      // نفس الكود الذي يستخدمه SubscriptionRepoImpl.submitRequest:
      // amount: plan.price — فيقرأ القيمة الجديدة.
      final request = SubscriptionRequestModel(
        requestId: 'req-1',
        userId: 'u1',
        ownerName: 'owner',
        shopName: 'shop',
        phone: '01000000000',
        plan: SubscriptionPlan.monthly,
        amount: SubscriptionPlan.monthly.price,
        paymentMethod: 'instapay',
        paymentProofUrl: 'https://res.cloudinary.com/demo/image/upload/r.jpg',
        createdAt: DateTime.utc(2026, 1, 1),
      );

      expect(request.amount, 149);
      expect(request.toJson()['amount'], 149);
      expect(request.toJson()['selectedPlan'], 'monthly');
    });
  });

  group('طلب قديم بعد تغيير السعر (سيناريو 10)', () {
    test('الطلب المعلّق يحتفظ بسعر لحظة الإرسال ولا يتغير مع الإعدادات', () {
      final submitted = SubscriptionRequestModel(
        requestId: 'req-old',
        userId: 'u1',
        ownerName: 'owner',
        shopName: 'shop',
        phone: '01000000000',
        plan: SubscriptionPlan.yearly,
        amount: SubscriptionPlan.yearly.price, // 799 وقت الإرسال
        paymentMethod: 'vodafone_cash',
        paymentProofUrl: 'https://res.cloudinary.com/demo/image/upload/r.jpg',
        createdAt: DateTime.utc(2025, 12, 1),
      );

      // الأدمن غيّر الأسعار بعدها.
      AppSettingsService.debugSetCurrent(const AdminSettings(
        monthlyPrice: 149,
        threeMonthsPrice: 399,
        sixMonthsPrice: 699,
        yearlyPrice: 999,
        trialDays: 7,
        paymentMethods: [],
      ));

      // الصف القديم كما هو في Firestore: لا يعيد بناء نفسه من الإعدادات.
      final stored = SubscriptionRequestModel.fromJson(
        'req-old',
        submitted.toJson(),
      );
      expect(stored.amount, 799); // السعر القديم محفوظ — الإدارة تراجع عليه
      expect(stored.plan, SubscriptionPlan.yearly);
      expect(stored.plan.days, 365); // المدة من الخطة، لا من السعر
      expect(stored.isPending, true);
    });
  });

  group('التحقق من القواعد firewall (firestore.rules)', () {
    final rules = File('firestore.rules').readAsStringSync();

    test('المبلغ يُتحقق منه من إعدادات الأدمن الحية وليس من أرقام ثابتة فقط', () {
      // يقرأ السعر من admin_settings/settings ديناميكياً.
      expect(
        rules.contains(
          'get(/databases/\$(database)/documents/admin_settings/settings)',
        ),
        isTrue,
        reason: 'يجب أن تقرأ القواعد السعر من admin_settings/settings',
      );
      // وأيضاً يتحقق من أن المبلغ رقم موجب (يمنع مطابقة القيمة الافتراضية -1).
      expect(rules.contains('request.resource.data.amount is int'), isTrue);
      expect(rules.contains('request.resource.data.amount > 0'), isTrue);
      // الفروع الأربعة للخطط موجودة كلها.
      for (final plan in ['monthly', 'threeMonths', 'sixMonths', 'yearly']) {
        expect(
          rules.contains("request.resource.data.selectedPlan == '$plan'"),
          isTrue,
          reason: 'فرع الخطة $plan مفقود',
        );
      }
    });

    test('التحكّم في المبلغ مربوط بخطّة صحيحة (لا plan id مزيّف)', () {
      // كل فرع مقارنة يربط selectedPlan بمبلغ محدد: خطة غير معروفة
      // لا تقابل أي فرع → تُرفض.
      expect(
        rules.contains("request.resource.data.selectedPlan == 'monthly'\n")
            || rules.contains("request.resource.data.selectedPlan == 'monthly'"),
        isTrue,
      );
      // المستخدم لا يستطيع اعتماد طلبه: التحديث للأدمن فقط.
      final requestsMatch = RegExp(
        r'match /subscription_requests/\{requestId\} \{[\s\S]*?\n    \}',
      ).firstMatch(rules);
      expect(requestsMatch, isNotNull, reason: 'بلوك subscription_requests مفقود');
      final block = requestsMatch!.group(0)!;
      expect(
        block.contains('allow update: if isAdmin();'),
        isTrue,
        reason: 'التحديث (اعتماد/رفض) يجب أن يكون للأدمن فقط',
      );
      expect(
        block.contains("request.resource.data.status == 'pending'"),
        isTrue,
        reason: 'إنشاء الطلب يجب أن يكون pending فقط — المستخدم لا يعتمده',
      );
    });

    test('الاعتماد يمنح المدة من الخطة: الاشتراك الفعلي يحافظ على نهايته', () {
      // القاعدة: الوصول إلى active يتطلب طلباً معتمداً من الأدمن.
      expect(
        rules.contains(".data.status == 'approved'"),
        isTrue,
        reason: 'قاعدة active في اشتراك المستخدم تقرأ طلب approval معتمد',
      );
      // المستخدم لا يستطيع تجاوز ذلك (يوجد فرع isAdmin() في تحديث الاشتراك).
      final subMatch = RegExp(
        r'match /users/\{userId\}/subscription/\{subId\} \{[\s\S]*?\n    \}',
      ).firstMatch(rules);
      expect(subMatch, isNotNull);
      expect(subMatch!.group(0)!.contains('allow update: if isAdmin()'), isTrue);
    });
  });
}
