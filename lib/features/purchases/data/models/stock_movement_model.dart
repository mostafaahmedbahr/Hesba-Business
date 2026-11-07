import 'package:cloud_firestore/cloud_firestore.dart';

import 'stock_purchase_item.dart';

/// حركة مخزون واحدة (audit trail) — تُنشأ مع كل عملية زيادة.
///
/// حالياً movementType = 'purchase' فقط؛ أي نوع مستقبلي (مرتجع، تسوية)
/// يُكتب بنفس المجموعة من الميزة الخاصة به.
class StockMovement {
  final String movementId;
  final String shopId;
  final String ownerId;
  final String productId;

  /// لقطة اسم المنتج وقت الحركة.
  final String productName;
  final String movementType;

  /// الكمية المضافة (موجبة دائماً).
  final double quantity;
  final double previousStock;
  final double newStock;

  /// سعر شراء الوحدة في هذه الحركة.
  final double unitCost;

  /// purchaseId المرتبط بالحركة.
  final String referenceId;
  final DateTime createdAt;

  const StockMovement({
    required this.movementId,
    required this.shopId,
    required this.ownerId,
    required this.productId,
    required this.productName,
    this.movementType = 'purchase',
    required this.quantity,
    required this.previousStock,
    required this.newStock,
    required this.unitCost,
    required this.referenceId,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'movementId': movementId,
      'shopId': shopId,
      'ownerId': ownerId,
      'productId': productId,
      'productName': productName,
      'movementType': movementType,
      'quantity': quantity,
      'previousStock': previousStock,
      'newStock': newStock,
      'unitCost': unitCost,
      'referenceId': referenceId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory StockMovement.fromJson(Map<String, dynamic> json) {
    return StockMovement(
      movementId: json['movementId'] as String? ?? '',
      shopId: json['shopId'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      productId: json['productId'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      movementType: json['movementType'] as String? ?? 'purchase',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      previousStock: (json['previousStock'] as num?)?.toDouble() ?? 0,
      newStock: (json['newStock'] as num?)?.toDouble() ?? 0,
      unitCost: (json['unitCost'] as num?)?.toDouble() ?? 0,
      referenceId: json['referenceId'] as String? ?? '',
      createdAt: parseFirestoreDate(json['createdAt']),
    );
  }
}
