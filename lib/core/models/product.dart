import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;

  /// Sale price (سعر البيع).
  final double price;

  /// Purchase price (سعر الشراء).
  final double costPrice;

  /// Available quantity in stock (double: pieces or kg/litre).
  final double stock;
  final double lowStockThreshold;
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

  /// مواصفات إضافية حسب النشاط (باركود، صلاحية، إضافات، مكونات، ماركة...).
  ///
  /// مفتاحها واحد من ProductFieldKeys. المنتجات القديمة بلا specs → {}.
  /// الحقول الأساسية (color/size/...) تبقى top-level للتوافق مع البيانات القديمة.
  final Map<String, dynamic> specs;

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
    this.specs = const {},
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
      stock: (json['stock'] as num?)?.toDouble() ?? 0,
      lowStockThreshold: (json['lowStockThreshold'] as num?)?.toDouble() ?? 5,
      category: json['category'] as String? ?? '',
      code: json['code'] as String? ?? '',
      size: json['size'] as String? ?? '',
      color: json['color'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      specs: _readSpecs(json['specs']),
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
      'specs': specs,
      'isActive': isActive,
    };
  }

  Product copyWith({
    String? name,
    double? price,
    double? costPrice,
    double? stock,
    double? lowStockThreshold,
    String? category,
    String? code,
    String? size,
    String? color,
    String? notes,
    String? imageUrl,
    Map<String, dynamic>? specs,
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
      specs: specs ?? this.specs,
      shopId: shopId,
      ownerId: ownerId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  bool get isLowStock => stock <= lowStockThreshold;

  bool get isOutOfStock => stock <= 0;

  /// عرض المخزون: عدد صحيح من غير كسور، وكسر برقم عشري واحد.
  String get stockLabel => stock == stock.roundToDouble() ? stock.toStringAsFixed(0) : stock.toStringAsFixed(1);

  String get lowStockLabel => lowStockThreshold == lowStockThreshold.roundToDouble() ? lowStockThreshold.toStringAsFixed(0) : lowStockThreshold.toStringAsFixed(1);

  /// Profit margin percentage on the sale price.
  double get marginPercent =>
      price <= 0 ? 0 : ((price - costPrice) / price * 100);

  /// قراءة آمنة لخريطة المواصفات: تتحمل المنتجات القديمة بلا specs
  /// وأي قيمة غير متوقعة من Firestore بدون إسقاط (throw).
  static Map<String, dynamic> _readSpecs(Object? raw) {
    if (raw is Map) {
      try {
        return Map<String, dynamic>.from(raw);
      } catch (_) {
        return const {};
      }
    }
    return const {};
  }
}