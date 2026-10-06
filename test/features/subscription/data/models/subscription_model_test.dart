import 'package:flutter_test/flutter_test.dart';

import 'package:hesba/features/subscription/data/models/subscription_model.dart';
import 'package:hesba/features/subscription/data/models/subscription_plan.dart';

void main() {
  // Dates are relative to the real clock: the model derives status and
  // remaining days from DateTime.now().
  final now = DateTime.now();

  group('trial', () {
    test('runs for exactly 7 days from the given moment', () {
      final trial = SubscriptionModel.trialFor(createdAt: now);

      expect(trial.status, SubscriptionStatus.trial);
      expect(trial.isTrial, isTrue);
      expect(trial.startDate, now);
      expect(trial.trialStartDate, now);
      expect(trial.endDate, now.add(const Duration(days: 7)));
      expect(trial.trialEndDate, now.add(const Duration(days: 7)));
      expect(trial.lastRequestId, isNull);
    });
  });

  group('effectiveStatus', () {
    test('is trial while the free period is still running', () {
      final trial = SubscriptionModel.trialFor(createdAt: now);
      expect(trial.effectiveStatus, SubscriptionStatus.trial);
    });

    test('rolls a finished trial over to expired', () {
      final trial = SubscriptionModel.trialFor(
        createdAt: now.subtract(const Duration(days: 8)),
      );
      expect(trial.effectiveStatus, SubscriptionStatus.expired);
    });

    test('rolls a finished paid period over to expired', () {
      final sub = SubscriptionModel(
        status: SubscriptionStatus.active,
        plan: SubscriptionPlan.monthly,
        startDate: now.subtract(const Duration(days: 31)),
        endDate: now.subtract(const Duration(days: 1)),
      );
      expect(sub.effectiveStatus, SubscriptionStatus.expired);
    });

    test('keeps pending and rejected whatever the dates say', () {
      final pending = SubscriptionModel(
        status: SubscriptionStatus.pending,
        endDate: now.subtract(const Duration(days: 40)),
      );
      final rejected = SubscriptionModel(
        status: SubscriptionStatus.rejected,
        endDate: now.add(const Duration(days: 40)),
      );

      expect(pending.effectiveStatus, SubscriptionStatus.pending);
      expect(rejected.effectiveStatus, SubscriptionStatus.rejected);
    });

    test('treats a missing end date as expired', () {
      const sub = SubscriptionModel(status: SubscriptionStatus.active);
      expect(sub.effectiveStatus, SubscriptionStatus.expired);
    });
  });

  group('canModifyData', () {
    test('is true only for a running trial or paid period', () {
      final trial = SubscriptionModel.trialFor(createdAt: now);
      final active = SubscriptionModel(
        status: SubscriptionStatus.active,
        endDate: now.add(const Duration(days: 30)),
      );
      final expired = SubscriptionModel.trialFor(
        createdAt: now.subtract(const Duration(days: 30)),
      );
      const pending = SubscriptionModel(status: SubscriptionStatus.pending);
      const rejected = SubscriptionModel(status: SubscriptionStatus.rejected);

      expect(trial.canModifyData, isTrue);
      expect(active.canModifyData, isTrue);
      expect(expired.canModifyData, isFalse);
      expect(pending.canModifyData, isFalse);
      expect(rejected.canModifyData, isFalse);
    });
  });

  group('blockedMessageKey', () {
    test('says the right thing for each blocking state', () {
      const pending = SubscriptionModel(status: SubscriptionStatus.pending);
      const rejected = SubscriptionModel(status: SubscriptionStatus.rejected);
      final expired = SubscriptionModel.trialFor(
        createdAt: now.subtract(const Duration(days: 30)),
      );

      expect(pending.blockedMessageKey, 'subscriptionPendingBlocked');
      expect(rejected.blockedMessageKey, 'subscriptionRejectedBlocked');
      expect(expired.blockedMessageKey, 'subscriptionExpiredBlocked');
    });
  });

  group('remainingDays', () {
    test('counts whole days left and never goes negative', () {
      final sub = SubscriptionModel(
        status: SubscriptionStatus.active,
        endDate: now.add(const Duration(days: 3, hours: 5)),
      );
      final past = SubscriptionModel(
        status: SubscriptionStatus.expired,
        endDate: now.subtract(const Duration(days: 4)),
      );

      expect(sub.remainingDays, 3);
      expect(past.remainingDays, 0);
    });
  });

  group('json', () {
    test('round trips every field the app relies on', () {
      final original = SubscriptionModel.trialFor(createdAt: now).copyWith(
        status: SubscriptionStatus.pending,
        plan: SubscriptionPlan.threeMonths,
        lastRequestId: 'req_42',
      );

      final restored = SubscriptionModel.fromJson(original.toJson());

      expect(restored.status, original.status);
      expect(restored.plan, original.plan);
      expect(restored.startDate, original.startDate);
      expect(restored.endDate, original.endDate);
      expect(restored.isTrial, original.isTrial);
      expect(restored.trialStartDate, original.trialStartDate);
      expect(restored.trialEndDate, original.trialEndDate);
      expect(restored.lastRequestId, original.lastRequestId);
    });

    test('reads an unknown status as expired instead of throwing', () {
      final sub = SubscriptionModel.fromJson(const {'status': 'something'});
      expect(sub.status, SubscriptionStatus.expired);
    });

    test('reads an unknown plan id as monthly instead of throwing', () {
      final sub = SubscriptionModel.fromJson(const {'plan': 'nope'});
      expect(sub.plan, SubscriptionPlan.monthly);
    });
  });

  group('reminderOffsetsOn', () {
    test('returns the offsets whose reminder lands on the given day', () {
      final sub = SubscriptionModel(
        status: SubscriptionStatus.active,
        endDate: DateTime(2026, 6, 20),
      );

      expect(sub.reminderOffsetsOn(DateTime(2026, 6, 13)), [7]);
      expect(sub.reminderOffsetsOn(DateTime(2026, 6, 17)), [3]);
      expect(sub.reminderOffsetsOn(DateTime(2026, 6, 19)), [1]);
      expect(sub.reminderOffsetsOn(DateTime(2026, 6, 18)), isEmpty);
    });

    test('has nothing to count down from without a period', () {
      const sub = SubscriptionModel(status: SubscriptionStatus.expired);
      expect(sub.reminderOffsetsOn(DateTime(2026, 6, 13)), isEmpty);
    });
  });
}
