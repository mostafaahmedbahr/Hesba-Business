import 'package:cloud_firestore/cloud_firestore.dart';

/// دفعة واحدة على مديونية — تُخزَّن في subcollection‏ `debts/{debtId}/payments`.
///
/// الدفعات غير قابلة للتعديل أو الحذف من العميل (immutable ledger)،
/// ولا يمكن حذف السجل الأصلي بعد السداد — كل حركة مالية محفوظة.
class PaymentModel {
  final String id;
  final String ownerId;
  final String shopId;

  /// المبلغ المدفوع في هذه الحركة.
  final double amount;

  final String note;
  final DateTime? createdAt;

  const PaymentModel({
    required this.id,
    required this.ownerId,
    required this.shopId,
    required this.amount,
    this.note = '',
    this.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return PaymentModel(
      id: docId ?? _str(json['id']),
      ownerId: _str(json['ownerId']),
      shopId: _str(json['shopId']),
      amount: _num(json['amount']),
      note: _str(json['note']),
      createdAt: _toDate(json['createdAt']),
    );
  }

  static String _str(Object? value) => value is String ? value : '';

  static double _num(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime? _toDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
