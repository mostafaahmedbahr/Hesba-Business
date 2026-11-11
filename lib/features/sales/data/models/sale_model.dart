import 'package:cloud_firestore/cloud_firestore.dart';

class SaleItemModel {
  final String productId;
  final String productName;
  final double quantity;
  final double unitPrice;

  /// Purchase price snapshot at the moment of the sale (سعر الشراء وقت البيع).
  /// Stored so historical profit stays accurate even when the product price
  /// changes later. Legacy sales have no value here (0).
  final double costPrice;

  const SaleItemModel({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.costPrice = 0,
  });

  double get total => quantity * unitPrice;

  /// Profit of this line: (sale price − cost price) × quantity.
  double get profit => (unitPrice - costPrice) * quantity;

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'total': total,
      'costPrice': costPrice,
      'profit': profit,
    };
  }

  factory SaleItemModel.fromJson(Map<String, dynamic> json) {
    return SaleItemModel(
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      costPrice: (json['costPrice'] as num?)?.toDouble() ?? 0,
    );
  }
}

class SaleModel {
  final String saleId;
  final String ownerId;
  final String shopId;

  /// اسم المحل وقت البيع — يُحفظ مع الفاتورة حتى تبقى البيانات مكتملة
  /// ولو تغيّر اسم المحل لاحقاً. الفواتير القديمة بلا قيمة ('').
  final String shopName;

  final List<SaleItemModel> items;

  final double subtotal;
  final double discount;
  final double total;

  final String paymentMethod;
  final String note;

  /// رابط جهة الاتصال (persons) المرتبطة بالفاتورة — '' = بدون عميل
  /// (بيع عابر أو فاتورة قديمة).
  final String personId;

  /// لقطة الاسم والرقم وقت البيع — تبقى مع الفاتورة حتى لو تغيّرت
  /// بيانات جهة الاتصال لاحقًا. الفواتير القديمة بلا قيمة ('').
  final String personName;
  final String personPhone;

  final DateTime createdAt;

  const SaleModel({
    required this.saleId,
    required this.ownerId,
    required this.shopId,
    this.shopName = '',
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.paymentMethod,
    required this.note,
    this.personId = '',
    this.personName = '',
    this.personPhone = '',
    required this.createdAt,
  });

  /// هل الفاتورة مرتبطة بجهة اتصال (عميل)؟
  bool get hasCustomer => personName.trim().isNotEmpty || personId.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'saleId': saleId,
      'ownerId': ownerId,
      'shopId': shopId,
      'shopName': shopName,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'total': total,
      'paymentMethod': paymentMethod,
      'note': note,
      'personId': personId,
      'personName': personName,
      'personPhone': personPhone,
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
      shopName: json['shopName'] ?? '',
      items: items,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      paymentMethod: json['paymentMethod'] ?? '',
      note: json['note'] ?? '',
      personId: json['personId'] ?? '',
      personName: json['personName'] ?? '',
      personPhone: json['personPhone'] ?? '',
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