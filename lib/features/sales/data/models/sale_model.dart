import 'package:cloud_firestore/cloud_firestore.dart';

class SaleItemModel {
  final String productId;
  final String productName;
  final double quantity;
  final double unitPrice;

  const SaleItemModel({
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

  factory SaleItemModel.fromJson(Map<String, dynamic> json) {
    return SaleItemModel(
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
    );
  }
}

class SaleModel {
  final String saleId;
  final String ownerId;
  final String shopId;

  final List<SaleItemModel> items;

  final double subtotal;
  final double discount;
  final double total;

  final String paymentMethod;
  final String note;

  final DateTime createdAt;

  const SaleModel({
    required this.saleId,
    required this.ownerId,
    required this.shopId,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.paymentMethod,
    required this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'saleId': saleId,
      'ownerId': ownerId,
      'shopId': shopId,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'total': total,
      'paymentMethod': paymentMethod,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory SaleModel.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? [])
        .map(
          (item) => SaleItemModel.fromJson(
        Map<String, dynamic>.from(item),
      ),
    )
        .toList();

    return SaleModel(
      saleId: json['saleId'] ?? '',
      ownerId: json['ownerId'] ?? '',
      shopId: json['shopId'] ?? '',
      items: items,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      paymentMethod: json['paymentMethod'] ?? '',
      note: json['note'] ?? '',
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
}