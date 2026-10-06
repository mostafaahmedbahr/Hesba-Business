import 'package:flutter/material.dart';

/// Every purchasable plan and payment channel in one file, so prices, durations
/// and wallet numbers are written once and never repeated across widgets.
///
/// Change a price here and the whole app follows.
enum SubscriptionPlan {
  monthly('monthly', 30, 99, null),
  threeMonths('threeMonths', 90, 249, 297),
  sixMonths('sixMonths', 180, 449, 594),
  yearly('yearly', 365, 799, 1188);

  const SubscriptionPlan(this.id, this.days, this.price, this.normalPrice);

  /// Stored in Firestore / the subscription request.
  final String id;

  /// How long the period lasts once it starts.
  final int days;

  /// What the customer actually pays.
  final int price;

  /// What the same period costs bought month by month (null when no saving).
  final int? normalPrice;

  /// Pounds saved compared with paying monthly.
  int? get savedAmount {
    final normal = normalPrice;
    return normal == null ? null : normal - price;
  }

  /// The plan highlighted as "الأفضل قيمة".
  bool get isBestValue => this == SubscriptionPlan.threeMonths;

  String get labelKey => switch (this) {
        SubscriptionPlan.monthly => 'planMonthly',
        SubscriptionPlan.threeMonths => 'planThreeMonths',
        SubscriptionPlan.sixMonths => 'planSixMonths',
        SubscriptionPlan.yearly => 'planYearly',
      };

  String get durationKey => switch (this) {
        SubscriptionPlan.monthly => 'planMonthlyDuration',
        SubscriptionPlan.threeMonths => 'planThreeMonthsDuration',
        SubscriptionPlan.sixMonths => 'planSixMonthsDuration',
        SubscriptionPlan.yearly => 'planYearlyDuration',
      };

  static SubscriptionPlan fromId(String? id) {
    return SubscriptionPlan.values.firstWhere(
      (plan) => plan.id == id,
      orElse: () => SubscriptionPlan.monthly,
    );
  }
}

/// Manual payment channels shown after the plan is picked.
enum SubscriptionPaymentMethod {
  instapay('instapay', '01110690299'),
  vodafoneCash('vodafone_cash', '01093312802'),
  etisalatCash('etisalat_cash', '01145049298');

  const SubscriptionPaymentMethod(this.id, this.number);

  final String id;
  final String number;

  String get labelKey => switch (this) {
        SubscriptionPaymentMethod.instapay => 'payInstapay',
        SubscriptionPaymentMethod.vodafoneCash => 'payVodafoneCash',
        SubscriptionPaymentMethod.etisalatCash => 'payEtisalatCash',
      };

  /// Short mark drawn inside the channel badge instead of a stock icon.
  String get brandMark => switch (this) {
        SubscriptionPaymentMethod.instapay => 'IP',
        SubscriptionPaymentMethod.vodafoneCash => 'V',
        SubscriptionPaymentMethod.etisalatCash => 'e',
      };

  /// Brand colour behind [brandMark], so the channel reads at a glance.
  Color get brandColor => switch (this) {
        SubscriptionPaymentMethod.instapay => const Color(0xFF1B3C87),
        SubscriptionPaymentMethod.vodafoneCash => const Color(0xFFE60000),
        SubscriptionPaymentMethod.etisalatCash => const Color(0xFF00A651),
      };

  static SubscriptionPaymentMethod? fromId(String? id) {
    for (final method in SubscriptionPaymentMethod.values) {
      if (method.id == id) return method;
    }
    return null;
  }
}
