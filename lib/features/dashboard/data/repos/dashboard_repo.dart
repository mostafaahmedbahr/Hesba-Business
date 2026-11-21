import '../../../expenses/data/models/expense_model.dart';
import '../../../returns/data/models/return_model.dart';
import '../../../sales/data/models/sale_model.dart';

/// Combined today summary returned by [DashboardRepo.getTodaySummary].
class TodaySummary {
  const TodaySummary({
    required this.salesByMethod,
    required this.returnsTotal,
    required this.returnsCount,
    required this.expensesTotal,
  });

  final Map<String, double> salesByMethod;
  final double returnsTotal;
  final int returnsCount;
  final double expensesTotal;
}

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

  /// Reads today's sales/returns/expenses in ONE pass per collection instead
  /// of running separate queries for total + by-method + count. Returns
  /// `(salesByMethod, returnsTotal, returnsCount, expensesTotal)`.
  Future<TodaySummary> getTodaySummary({required String shopId});

  /// Returns the current user's shopId.
  Future<String?> getShopId();

  /// Reads the latest sale of [shopId] once (`null` when there is none) for
  /// the home recent-activity card.
  ///
  /// These cards are deliberately one-shot reads: the home screen re-fetches
  /// them through `AppEvents` after a write. No Firestore snapshot listener
  /// is kept open just to watch whole collections.
  Future<SaleModel?> getLastSale(String shopId);

  /// Reads the latest return of [shopId] once (`null` when there is none).
  Future<ReturnModel?> getLastReturn(String shopId);

  /// Reads the latest expense of [shopId] once (`null` when there is none).
  Future<ExpenseModel?> getLastExpense(String shopId);
}
