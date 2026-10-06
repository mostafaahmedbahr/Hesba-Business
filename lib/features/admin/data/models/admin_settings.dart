import 'package:cloud_firestore/cloud_firestore.dart';

/// One payable channel shown to customers at checkout.
class AdminPaymentMethod {
  const AdminPaymentMethod({required this.id, required this.label, required this.number});

  final String id;
  final String label;
  final String number;

  Map<String, dynamic> toJson() => {'id': id, 'label': label, 'number': number};

  factory AdminPaymentMethod.fromJson(Map<String, dynamic> json) => AdminPaymentMethod(
        id: json['id'] as String? ?? '',
        label: json['label'] as String? ?? '',
        number: json['number'] as String? ?? '',
      );
}

/// Live system configuration the customer app reads. Stored at
/// `admin_settings/settings` so it can be edited from the dashboard without
/// shipping a build.
class AdminSettings {
  const AdminSettings({
    required this.monthlyPrice,
    required this.threeMonthsPrice,
    required this.sixMonthsPrice,
    required this.yearlyPrice,
    required this.trialDays,
    required this.paymentMethods,
  });

  final int monthlyPrice;
  final int threeMonthsPrice;
  final int sixMonthsPrice;
  final int yearlyPrice;
  final int trialDays;
  final List<AdminPaymentMethod> paymentMethods;

  static const defaults = AdminSettings(
    monthlyPrice: 99,
    threeMonthsPrice: 249,
    sixMonthsPrice: 449,
    yearlyPrice: 799,
    trialDays: 7,
    paymentMethods: [
      AdminPaymentMethod(id: 'instapay', label: 'إنستاباي', number: '01110690299'),
      AdminPaymentMethod(id: 'vodafone_cash', label: 'فودافون كاش', number: '01093312802'),
      AdminPaymentMethod(id: 'etisalat_cash', label: 'اتصالات كاش', number: '01145049298'),
    ],
  );

  factory AdminSettings.fromJson(Map<String, dynamic> json) => AdminSettings(
        monthlyPrice: (json['monthlyPrice'] as num?)?.toInt() ?? defaults.monthlyPrice,
        threeMonthsPrice: (json['threeMonthsPrice'] as num?)?.toInt() ?? defaults.threeMonthsPrice,
        sixMonthsPrice: (json['sixMonthsPrice'] as num?)?.toInt() ?? defaults.sixMonthsPrice,
        yearlyPrice: (json['yearlyPrice'] as num?)?.toInt() ?? defaults.yearlyPrice,
        trialDays: (json['trialDays'] as num?)?.toInt() ?? defaults.trialDays,
        paymentMethods: (json['paymentMethods'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(AdminPaymentMethod.fromJson)
            .toList()
            .isEmpty
                ? defaults.paymentMethods
                : (json['paymentMethods'] as List<dynamic>)
                    .whereType<Map<String, dynamic>>()
                    .map(AdminPaymentMethod.fromJson)
                    .toList(),
      );

  Map<String, dynamic> toJson() => {
        'monthlyPrice': monthlyPrice,
        'threeMonthsPrice': threeMonthsPrice,
        'sixMonthsPrice': sixMonthsPrice,
        'yearlyPrice': yearlyPrice,
        'trialDays': trialDays,
        'paymentMethods': paymentMethods.map((m) => m.toJson()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  AdminSettings copyWith({
    int? monthlyPrice,
    int? threeMonthsPrice,
    int? sixMonthsPrice,
    int? yearlyPrice,
    int? trialDays,
    List<AdminPaymentMethod>? paymentMethods,
  }) =>
      AdminSettings(
        monthlyPrice: monthlyPrice ?? this.monthlyPrice,
        threeMonthsPrice: threeMonthsPrice ?? this.threeMonthsPrice,
        sixMonthsPrice: sixMonthsPrice ?? this.sixMonthsPrice,
        yearlyPrice: yearlyPrice ?? this.yearlyPrice,
        trialDays: trialDays ?? this.trialDays,
        paymentMethods: paymentMethods ?? this.paymentMethods,
      );
}
