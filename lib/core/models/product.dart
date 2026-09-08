import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final double price;
  final double costPrice;
  final int stock;
  final int lowStockThreshold;
  final String category;
  final String shopId;
  final String ownerId;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.costPrice,
    required this.stock,
    this.lowStockThreshold = 5,
    required this.category,
    required this.shopId,
    required this.ownerId,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json, {String? docId}) {
    return Product(
      id: docId ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      costPrice: (json['costPrice'] as num?)?.toDouble() ?? 0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      lowStockThreshold: (json['lowStockThreshold'] as num?)?.toInt() ?? 5,
      category: json['category'] as String? ?? '',
      shopId: json['shopId'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  bool get isLowStock => stock <= lowStockThreshold;
}
