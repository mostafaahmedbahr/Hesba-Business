import '../../../../core/models/product.dart';

enum ProductsStatus { loading, success, failure }

class ProductsState {
  final ProductsStatus status;
  final List<Product> products;
  final String? errorMessage;

  /// Shop business type (e.g. 'محل ملابس') - selects which product
  /// sub-categories the user can pick from.
  final String? shopType;

  /// نص البحث.
  final String searchQuery;

  /// فلتر القسم (الكل + الأقسام).
  final String categoryFilter;

  const ProductsState({
    this.status = ProductsStatus.loading,
    this.products = const [],
    this.errorMessage,
    this.shopType,
    this.searchQuery = '',
    this.categoryFilter = 'الكل',
  });

  /// المنتجات بعد البحث + الفلتر.
  List<Product> get filtered {
    final q = searchQuery.trim().toLowerCase();
    return products.where((p) {
      final matchesSearch = q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.code.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q);
      final matchesCat = categoryFilter == 'الكل' || p.category == categoryFilter;
      return matchesSearch && matchesCat;
    }).toList();
  }

  /// قيمة المخزون (سعر الشراء × الكمية).
  double get inventoryValue =>
      products.fold<double>(0, (s, p) => s + p.costPrice * p.stock);

  /// عدد المنتجات قليلة المخزون.
  int get lowStockCount => products.where((p) => p.isLowStock).length;

  /// الأقسام الموجودة (للفلتر).
  List<String> get categories {
    final set = <String>{'الكل'};
    for (final p in products) {
      if (p.category.trim().isNotEmpty) set.add(p.category);
    }
    return set.toList();
  }

  ProductsState copyWith({
    ProductsStatus? status,
    List<Product>? products,
    String? errorMessage,
    String? shopType,
    String? searchQuery,
    String? categoryFilter,
    bool clearError = false,
  }) {
    return ProductsState(
      status: status ?? this.status,
      products: products ?? this.products,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      shopType: shopType ?? this.shopType,
      searchQuery: searchQuery ?? this.searchQuery,
      categoryFilter: categoryFilter ?? this.categoryFilter,
    );
  }
}

/// تنسيق سعر (صحيح من غير كسور).
String fmtProduct(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);