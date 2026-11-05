import 'package:flutter/material.dart';

import '../../../../core/models/admin_settings.dart';
import '../../../../core/services/app_settings_service.dart';

/// Every purchasable plan and payment channel in one file, so durations and
/// labels are written once and never repeated across widgets.
///
/// Prices and wallet numbers are NOT stored here anymore: they are read live
/// from `admin_settings/settings` (edited from the dashboard) through
/// [AppSettingsService], so changing them in the dashboard applies instantly.
enum SubscriptionPlan {
  monthly('monthly', 30, 1),
  threeMonths('threeMonths', 90, 3),
  sixMonths('sixMonths', 180, 6),
  yearly('yearly', 365, 12);

  const SubscriptionPlan(this.id, this.days, this.months);

  /// Stored in Firestore / the subscription request.
  final String id;

  /// How long the period lasts once it starts.
  final int days;

  /// Plan length in months — used to derive the "bought monthly" comparison
  /// price (monthly price × months).
  final int months;

  /// Latest settings loaded from the dashboard (defaults before first fetch).
  static AdminSettings get _settings => AppSettingsService.current;

  /// What the customer actually pays — from the dashboard settings.
  int get price => switch (this) {
        SubscriptionPlan.monthly => _settings.monthlyPrice,
        SubscriptionPlan.threeMonths => _settings.threeMonthsPrice,
        SubscriptionPlan.sixMonths => _settings.sixMonthsPrice,
        SubscriptionPlan.yearly => _settings.yearlyPrice,
      };

  /// What the same period costs bought month by month (null when no saving).
  int? get normalPrice =>
      months == 1 ? null : _settings.monthlyPrice * months;

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
///
/// The visible wallet [number] is read live from the dashboard settings
/// ([AppSettingsService]); the constructor value is only a fallback used
/// before the settings are fetched.
enum SubscriptionPaymentMethod {
  instapay('instapay', '01110690299'),
  vodafoneCash('vodafone_cash', '01093312802'),
  etisalatCash('etisalat_cash', '01145049298');

  const SubscriptionPaymentMethod(this.id, this.fallbackNumber);

  final String id;

  /// Default number, used only when the dashboard settings are unavailable.
  final String fallbackNumber;

  /// Wallet number shown to the customer — from the dashboard settings.
  String get number {
    for (final method in AppSettingsService.current.paymentMethods) {
      if (method.id == id && method.number.trim().isNotEmpty) {
        return method.number;
      }
    }
    return fallbackNumber;
  }

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
