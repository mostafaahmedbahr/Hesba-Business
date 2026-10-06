import 'package:flutter_test/flutter_test.dart';

import 'package:hesba/features/subscription/data/models/subscription_plan.dart';

void main() {
  group('plans', () {
    test('are priced and lengthened once, in one place', () {
      const expected = {
        SubscriptionPlan.monthly: (30, 99, null),
        SubscriptionPlan.threeMonths: (90, 249, 297),
        SubscriptionPlan.sixMonths: (180, 449, 594),
        SubscriptionPlan.yearly: (365, 799, 1188),
      };

      expect(SubscriptionPlan.values, hasLength(expected.length));
      expected.forEach((plan, values) {
        expect(plan.days, values.$1, reason: plan.id);
        expect(plan.price, values.$2, reason: plan.id);
        expect(plan.normalPrice, values.$3, reason: plan.id);
      });
    });

    test('reports what buying month by month would cost', () {
      expect(SubscriptionPlan.monthly.savedAmount, isNull);
      expect(SubscriptionPlan.threeMonths.savedAmount, 48);
      expect(SubscriptionPlan.sixMonths.savedAmount, 145);
      expect(SubscriptionPlan.yearly.savedAmount, 389);
    });

    test('highlights exactly one plan as the best value', () {
      final best = [
        for (final plan in SubscriptionPlan.values)
          if (plan.isBestValue) plan,
      ];
      expect(best, [SubscriptionPlan.threeMonths]);
    });

    test('every plan and channel has UI keys and an id that survives a trip', () {
      for (final plan in SubscriptionPlan.values) {
        expect(plan.id, isNotEmpty);
        expect(plan.labelKey, isNotEmpty);
        expect(plan.durationKey, isNotEmpty);
        expect(SubscriptionPlan.fromId(plan.id), plan);
      }

      expect(SubscriptionPaymentMethod.values, hasLength(3));
      for (final method in SubscriptionPaymentMethod.values) {
        expect(method.id, isNotEmpty);
        expect(method.labelKey, isNotEmpty);
        expect(method.number, matches(RegExp(r'^0\d{10}$')));
        expect(SubscriptionPaymentMethod.fromId(method.id), method);
      }
    });
  });
}
