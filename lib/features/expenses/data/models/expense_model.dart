import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String expenseId;
  final String ownerId;
  final String shopId;
  final String title;
  final String category;
  final double amount;
  final String note;
  final DateTime date;
  final DateTime createdAt;

  const ExpenseModel({
    required this.expenseId,
    required this.ownerId,
    required this.shopId,
    required this.title,
    required this.category,
    required this.amount,
    required this.note,
    required this.date,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'expenseId': expenseId,
      'ownerId': ownerId,
      'shopId': shopId,
      'title': title,
      'category': category,
      'amount': amount,
      'note': note,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      expenseId: json['expenseId'] ?? '',
      ownerId: json['ownerId'] ?? '',
      shopId: json['shopId'] ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      note: json['note'] ?? '',
      date: _parseDate(json['date']),
      createdAt: _parseDate(json['createdAt']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return DateTime.now();
  }

  ExpenseModel copyWith({
    String? title,
    String? category,
    double? amount,
    String? note,
    DateTime? date,
  }) {
    return ExpenseModel(
      expenseId: expenseId,
      ownerId: ownerId,
      shopId: shopId,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      date: date ?? this.date,
      createdAt: createdAt,
    );
  }
}
