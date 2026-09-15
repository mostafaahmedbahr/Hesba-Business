enum DashboardStatus { initial, loading, success, failure }

class DashboardState {
  final DashboardStatus status;
  final String shopName;
  final double todaySalesTotal;
  final double todayReturnsTotal;
  final int todayReturnsCount;
  final double todayNetSales;
  final double todayExpensesTotal;
  final int productsCount;
  final int lowStockCount;
  final String? errorMessage;

  const DashboardState({
    this.status = DashboardStatus.initial,
    this.shopName = '',
    this.todaySalesTotal = 0,
    this.todayReturnsTotal = 0,
    this.todayReturnsCount = 0,
    this.todayNetSales = 0,
    this.todayExpensesTotal = 0,
    this.productsCount = 0,
    this.lowStockCount = 0,
    this.errorMessage,
  });

  DashboardState copyWith({
    DashboardStatus? status,
    String? shopName,
    double? todaySalesTotal,
    double? todayReturnsTotal,
    int? todayReturnsCount,
    double? todayNetSales,
    double? todayExpensesTotal,
    int? productsCount,
    int? lowStockCount,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DashboardState(
      status: status ?? this.status,
      shopName: shopName ?? this.shopName,
      todaySalesTotal: todaySalesTotal ?? this.todaySalesTotal,
      todayReturnsTotal: todayReturnsTotal ?? this.todayReturnsTotal,
      todayReturnsCount: todayReturnsCount ?? this.todayReturnsCount,
      todayNetSales: todayNetSales ?? this.todayNetSales,
      todayExpensesTotal: todayExpensesTotal ?? this.todayExpensesTotal,
      productsCount: productsCount ?? this.productsCount,
      lowStockCount: lowStockCount ?? this.lowStockCount,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
