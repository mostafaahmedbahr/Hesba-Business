import '../../../../core/models/product.dart';

/// Operations for the products & inventory feature.
abstract class ProductsRepo {
  /// Live list of the current shop's products (newest first).
  Stream<List<Product>> watchProducts();

  /// The shop business type chosen during registration (e.g. 'محل ملابس').
  /// Used to pick the relevant product sub-categories dropdown.
  Future<String?> getShopBusinessType();

  /// Creates a new product document under the current shop.
  Future<void> addProduct(Product product);

  /// Updates an existing product document.
  Future<void> updateProduct(Product product);

  /// Deletes a product document permanently.
  Future<void> deleteProduct(String productId);
}