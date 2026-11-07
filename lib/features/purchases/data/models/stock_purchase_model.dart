import 'package:cloud_firestore/cloud_firestore.dart';

import 'stock_purchase_item.dart';

/// فاتورة زيادة مخزون (شراء) — سجل قابل للتدقيق.
///
/// ملاحظة محاسبية: الفاتورة تسجيل ملكية بضاعة (inventory)، وليست مصروفاً
/// تشغيلياً — لا تُضاف قيمتها أبداً لمجموعة `expenses` (التكاليف تُحتسب
/// لاحقاً من لقطات costPrice في البيع عبر COGS).
class StockPurchase {
  final String purchaseId;
  final String ownerId;
  final String shopId;

  /// بيانات المورد اختيارية (اسم/تليفون) — بدون وحدة إدارة موردين.
  final String supplierName;
  final String supplierPhone;

  /// رقم فاتورة المورد المرجعي (اختياري).
  final String invoiceNumber;

  /// تاريخ الشراء كما اختاره صاحب المحل.
  final DateTime purchaseDate;

  /// إجمالي الفاتورة (مُعاد حسابه داخل المعاملة من القيم الموثوقة).
  final double totalAmount;
  final String notes;
  final List<StockPurchaseItem> items;
  final DateTime createdAt;

  const StockPurchase({
    required this.purchaseId,
    required this.ownerId,
    required this.shopId,
    this.supplierName = '',
    this.supplierPhone = '',
    this.invoiceNumber = '',
    required this.purchaseDate,
    required this.totalAmount,
    this.notes = '',
    required this.items,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'purchaseId': purchaseId,
      'ownerId': ownerId,
      'shopId': shopId,
      'supplierName': supplierName,
      'supplierPhone': supplierPhone,
      'invoiceNumber': invoiceNumber,
      'purchaseDate': Timestamp.fromDate(purchaseDate),
      'totalAmount': totalAmount,
      'notes': notes,
      'items': items.map((item) => item.toJson()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory StockPurchase.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? [])
        .map(
          (item) => StockPurchaseItem.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
    return StockPurchase(
      purchaseId: json['purchaseId'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      shopId: json['shopId'] as String? ?? '',
      supplierName: json['supplierName'] as String? ?? '',
      supplierPhone: json['supplierPhone'] as String? ?? '',
      invoiceNumber: json['invoiceNumber'] as String? ?? '',
      purchaseDate: parseFirestoreDate(json['purchaseDate']),
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      notes: json['notes'] as String? ?? '',
      items: items,
      createdAt: parseFirestoreDate(json['createdAt']),
    );
  }
}
