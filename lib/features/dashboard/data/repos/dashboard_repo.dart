abstract class DashboardRepo {
  /// Returns total sales amount for today.
  Future<double> getTodaySalesTotal();

  /// Returns total returns amount for today.
  Future<double> getTodayReturnsTotal();

  /// Returns total expenses for today.
  Future<double> getTodayExpensesTotal();

  /// Returns the total number of active products.
  Future<int> getProductsCount();

  /// Returns the number of products with stock <= lowStockThreshold.
  Future<int> getLowStockProductsCount();

  /// Streams the shop name from the current user's profile.
  Stream<String?> watchShopName();
}
