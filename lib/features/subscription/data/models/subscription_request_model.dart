import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'subscription_plan.dart';

/// One row in `subscription_requests`.
///
/// The app writes it with `pending`; only the admin flips it to `approved` or
/// `rejected` from the Firebase console. Everything the admin needs to review
/// is denormalised here so no join is needed.
class SubscriptionRequestModel extends Equatable {
  const SubscriptionRequestModel({
    required this.requestId,
    required this.userId,
    required this.ownerName,
    required this.shopName,
    required this.phone,
    required this.plan,
    required this.amount,
    required this.paymentMethod,
    required this.paymentProofUrl,
    this.status = 'pending',
    required this.createdAt,
    this.reviewedAt,
    this.adminNote,
  });

  static const String statusPending = 'pending';
  static const String statusApproved = 'approved';
  static const String statusRejected = 'rejected';

  final String requestId;
  final String userId;
  final String ownerName;
  final String shopName;
  final String phone;
  final SubscriptionPlan plan;
  final int amount;

  /// The wallet / InstaPay channel the transfer was sent to.
  final String paymentMethod;

  /// Cloudinary secure URL of the receipt image. The bytes never reach
  /// Firestore.
  final String paymentProofUrl;
  final String status;
  final DateTime createdAt;

  /// Set by the admin when the request is reviewed.
  final DateTime? reviewedAt;
  final String? adminNote;

  bool get isPending => status == statusPending;
  bool get isApproved => status == statusApproved;
  bool get isRejected => status == statusRejected;

  factory SubscriptionRequestModel.fromJson(
    String requestId,
    Map<String, dynamic> json,
  ) {
    return SubscriptionRequestModel(
      requestId: requestId,
      userId: json['userId'] as String? ?? '',
      ownerName: json['ownerName'] as String? ?? '',
      shopName: json['shopName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      plan: SubscriptionPlan.fromId(json['selectedPlan'] as String?),
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      paymentMethod: json['paymentMethod'] as String? ?? '',
      paymentProofUrl: json['paymentProofUrl'] as String? ?? '',
      status: json['status'] as String? ?? statusPending,
      createdAt: _date(json['createdAt']) ?? DateTime.now(),
      reviewedAt: _date(json['reviewedAt']),
      adminNote: json['adminNote'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requestId': requestId,
      'userId': userId,
      'ownerName': ownerName,
      'shopName': shopName,
      'phone': phone,
      'selectedPlan': plan.id,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'paymentProofUrl': paymentProofUrl,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      if (reviewedAt != null)
        'reviewedAt': Timestamp.fromDate(reviewedAt!),
      if (adminNote != null && adminNote!.trim().isNotEmpty)
        'adminNote': adminNote!.trim(),
    };
  }

  static DateTime? _date(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  List<Object?> get props => [
        requestId,
        userId,
        ownerName,
        shopName,
        phone,
        plan,
        amount,
        paymentMethod,
        paymentProofUrl,
        status,
        createdAt,
        reviewedAt,
        adminNote,
      ];
}
