import 'package:cloud_firestore/cloud_firestore.dart';

/// صنف داخل فاتورة شراء — يحتفظ بالقيم قبل وبعد التحديث للتدقيق الكامل.
class StockPurchaseItem {
  final String productId;

  /// لقطة اسم المنتج وقت الشراء (لو اسم المنتج اتغيّر بعدين يفضل التاريخ صحيح).
  final String productName;
  final double quantity;

  /// المخزون قبل الزيادة.
  final double previousStock;

  /// المخزون بعد الزيادة.
  final double newStock;

  /// متوسط سعر الشراء الحالي قبل الفاتورة.
  final double previousCost;

  /// سعر شراء الوحدة في هذه الفاتورة.
  final double purchaseUnitCost;

  /// متوسط سعر الشراء الجديد بعد المعادلة المرجحة.
  final double newAverageCost;

  /// إجمالي السطر = الكمية × سعر شراء الوحدة (مقرَّب لخانتين).
  final double lineTotal;

  const StockPurchaseItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.previousStock,
    required this.newStock,
    required this.previousCost,
    required this.purchaseUnitCost,
    required this.newAverageCost,
    required this.lineTotal,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'previousStock': previousStock,
      'newStock': newStock,
      'previousCost': previousCost,
      'purchaseUnitCost': purchaseUnitCost,
      'newAverageCost': newAverageCost,
      'lineTotal': lineTotal,
    };
  }

  factory StockPurchaseItem.fromJson(Map<String, dynamic> json) {
    return StockPurchaseItem(
      productId: json['productId'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      previousStock: (json['previousStock'] as num?)?.toDouble() ?? 0,
      newStock: (json['newStock'] as num?)?.toDouble() ?? 0,
      previousCost: (json['previousCost'] as num?)?.toDouble() ?? 0,
      purchaseUnitCost: (json['purchaseUnitCost'] as num?)?.toDouble() ?? 0,
      newAverageCost: (json['newAverageCost'] as num?)?.toDouble() ?? 0,
      lineTotal: (json['lineTotal'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Timestamp آمن لقراءة تواريخ Firestore (مطابق لـ ExpenseModel).
DateTime parseFirestoreDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.now();
}
