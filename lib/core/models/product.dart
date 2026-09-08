import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;

  /// Sale price (سعر البيع).
  final double price;

  /// Purchase price (سعر الشراء).
  final double costPrice;

  /// Available quantity in stock.
  final int stock;
  final int lowStockThreshold;
  final String category;

  /// Optional product code (كود المنتج).
  final String code;

  /// Optional single size value (IPv4 of the MVP: one size field, no
  /// variants yet).
  final String size;

  /// Optional single color value.
  final String color;

  /// Optional short notes.
  final String notes;

  /// Optional image URL (the app stores images as links, not files).
  final String imageUrl;

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
    this.code = '',
    this.size = '',
    this.color = '',
    this.notes = '',
    this.imageUrl = '',
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
      code: json['code'] as String? ?? '',
      size: json['size'] as String? ?? '',
      color: json['color'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      shopId: json['shopId'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'costPrice': costPrice,
      'stock': stock,
      'lowStockThreshold': lowStockThreshold,
      'category': category,
      'code': code,
      'size': size,
      'color': color,
      'notes': notes,
      'imageUrl': imageUrl,
      'isActive': isActive,
    };
  }

  Product copyWith({
    String? name,
    double? price,
    double? costPrice,
    int? stock,
    int? lowStockThreshold,
    String? category,
    String? code,
    String? size,
    String? color,
    String? notes,
    String? imageUrl,
    bool? isActive,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      stock: stock ?? this.stock,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      category: category ?? this.category,
      code: code ?? this.code,
      size: size ?? this.size,
      color: color ?? this.color,
      notes: notes ?? this.notes,
      imageUrl: imageUrl ?? this.imageUrl,
      shopId: shopId,
      ownerId: ownerId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  bool get isLowStock => stock <= lowStockThreshold;

  bool get isOutOfStock => stock <= 0;

  /// Profit margin percentage on the sale price.
  double get marginPercent =>
      price <= 0 ? 0 : ((price - costPrice) / price * 100);
}