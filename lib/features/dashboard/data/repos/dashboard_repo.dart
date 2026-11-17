import '../../../expenses/data/models/expense_model.dart';
import '../../../returns/data/models/return_model.dart';
import '../../../sales/data/models/sale_model.dart';

abstract class DashboardRepo {
  /// Returns total sales amount for today.
  ///
  /// [shopId] is optional: callers that already resolved it pass it in so a
  /// dashboard load does not re-read `users/{uid}` once per metric.
  Future<double> getTodaySalesTotal({String? shopId});

  /// Returns today's sales totals grouped by payment method
  /// (`{'cash': 120, 'mobile_wallet': 50}`) — powers the balance breakdown
  /// dialog on the home screen.
  Future<Map<String, double>> getTodaySalesByMethod({String? shopId});

  /// Returns total returns amount for today.
  Future<double> getTodayReturnsTotal({String? shopId});

  /// Returns number of returns for today.
  Future<int> getTodayReturnsCount({String? shopId});

  /// Returns total expenses for today.
  Future<double> getTodayExpensesTotal({String? shopId});

  /// Returns the total number of active products.
  Future<int> getProductsCount({String? shopId});

  /// Returns the number of products with stock <= lowStockThreshold.
  Future<int> getLowStockProductsCount({String? shopId});

/// Streams the shop name and photo from the current user's profile.
Stream<({String? name, String? imageUrl})> watchShopIdentity();

  /// Returns the current user's shopId.
  Future<String?> getShopId();

  /// Watches any change in sales/products/returns/expenses for the current shop.
  /// Emits whenever any of those collections changes - used for auto-refresh.
  Stream<void> watchDashboardChanges();

  /// Streams the latest sale of [shopId] (`null` when there is none) for the
  /// home recent-activity card.
  Stream<SaleModel?> watchLastSale(String shopId);

  /// Streams the latest return of [shopId] (`null` when there is none).
  Stream<ReturnModel?> watchLastReturn(String shopId);

  /// Streams the latest expense of [shopId] (`null` when there is none).
  Stream<ExpenseModel?> watchLastExpense(String shopId);
}
