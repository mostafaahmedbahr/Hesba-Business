import 'package:cloud_firestore/cloud_firestore.dart';

class ReturnItemModel {
  final String productId;
  final String productName;
  final double quantity;
  final double unitPrice;

  const ReturnItemModel({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  double get total => quantity * unitPrice;

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'total': total,
    };
  }

  factory ReturnItemModel.fromJson(Map<String, dynamic> json) {
    return ReturnItemModel(
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ReturnModel {
  final String returnId;
  final String ownerId;
  final String shopId;
  final String? originalSaleId;

  final List<ReturnItemModel> items;

  /// Gross total before discount allocation (sum qty*price)
  final double subtotal;

  /// Discount portion allocated from original sale
  final double discount;

  /// Net refund actually returned to customer (subtotal - discount)
  /// This is what affects cash / net sales.
  final double total;

  final String reason;
  final String note;

  final DateTime createdAt;

  const ReturnModel({
    required this.returnId,
    required this.ownerId,
    required this.shopId,
    this.originalSaleId,
    required this.items,
    required this.subtotal,
    this.discount = 0,
    required this.total,
    required this.reason,
    required this.note,
    required this.createdAt,
  });

  double get discountRatio => subtotal > 0 ? discount / subtotal : 0;

  Map<String, dynamic> toJson() {
    return {
      'returnId': returnId,
      'ownerId': ownerId,
      'shopId': shopId,
      if (originalSaleId != null) 'originalSaleId': originalSaleId,
      'items': items.map((e) => e.toJson()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'total': total,
      'reason': reason,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ReturnModel.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? [])
        .map((e) => ReturnItemModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    final sub = (json['subtotal'] as num?)?.toDouble() ?? 0;
    final disc = (json['discount'] as num?)?.toDouble() ?? 0;
    var tot = (json['total'] as num?)?.toDouble();
    // Backward compat: old docs had total == subtotal (no discount field)
    tot ??= sub - disc;
    if (tot == 0 && disc == 0 && sub > 0) {
      // old doc without discount: total == subtotal
      tot = (json['total'] as num?)?.toDouble() ?? sub;
    }

    return ReturnModel(
      returnId: json['returnId'] ?? '',
      ownerId: json['ownerId'] ?? '',
      shopId: json['shopId'] ?? '',
      originalSaleId: json['originalSaleId'] as String?,
      items: items,
      subtotal: sub,
      discount: disc,
      total: tot ?? sub,
      reason: json['reason'] ?? '',
      note: json['note'] ?? '',
      createdAt: _parseDate(json['createdAt']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
