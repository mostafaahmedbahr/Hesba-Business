import '../../../../core/models/product.dart';

enum ProductsStatus { loading, success, failure }

class ProductsState {
  final ProductsStatus status;
  final List<Product> products;
  final String? errorMessage;

  /// Shop business type (e.g. 'محل ملابس') - selects which product
  /// sub-categories the user can pick from.
  final String? shopType;

  const ProductsState({
    this.status = ProductsStatus.loading,
    this.products = const [],
    this.errorMessage,
    this.shopType,
  });

  ProductsState copyWith({
    ProductsStatus? status,
    List<Product>? products,
    String? errorMessage,
    String? shopType,
    bool clearError = false,
  }) {
    return ProductsState(
      status: status ?? this.status,
      products: products ?? this.products,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      shopType: shopType ?? this.shopType,
    );
  }
}