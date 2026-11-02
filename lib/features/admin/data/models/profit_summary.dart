/// Aggregated profit across every shop on the platform.
///
/// Profit is derived from sales: `(unit price − cost price) × quantity`,
/// after applying the sale discount. Cost comes from the sale item snapshot
/// when available, otherwise from the product's current `costPrice`.
class ProfitSummary {
  const ProfitSummary({
    required this.revenue,
    required this.cost,
    required this.profit,
    required this.salesCounted,
    required this.capped,
    required this.profitByMonth,
    required this.revenueByMonth,
  });

  /// Total revenue after discounts (إجمالي المبيعات).
  final double revenue;

  /// Total purchase cost of the sold quantities (إجمالي التكلفة).
  final double cost;

  /// Revenue − cost (صافي الأرباح).
  final double profit;

  /// Number of sale documents included in the calculation.
  final int salesCounted;

  /// True when the scan hit its safety cap, so the numbers are partial.
  final bool capped;

  /// `yyyy-MM` → profit for that month.
  final Map<String, int> profitByMonth;

  /// `yyyy-MM` → revenue for that month.
  final Map<String, int> revenueByMonth;

  static const ProfitSummary empty = ProfitSummary(
    revenue: 0,
    cost: 0,
    profit: 0,
    salesCounted: 0,
    capped: false,
    profitByMonth: {},
    revenueByMonth: {},
  );
}
