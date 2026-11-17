/// Aggregated profit across every shop on the platform.
///
/// Profit uses the SAME rules as the per-shop Reports calculator:
///  - Revenue is `sale.total` (after discount), net of `returns.total`.
///  - COGS comes from the per-line `costPrice` snapshot stored at sale
///    time ONLY. A legacy line without a snapshot is excluded from COGS
///    and counted in [unknownCostLines] — it never falls back to the
///    product's current cost price.
///  - Returns cancel the cost of the returned goods from COGS, looked up
///    from the original sale (same rule as Reports).
class ProfitSummary {
  const ProfitSummary({
    required this.revenue,
    required this.cost,
    required this.profit,
    required this.salesCounted,
    required this.capped,
    required this.profitByMonth,
    required this.revenueByMonth,
    this.returnsTotal = 0,
    this.returnsCounted = 0,
    this.unknownCostLines = 0,
  });

  /// Net sales: gross sales revenue after discounts minus refunded returns
  /// (i.e. `metrics.grossRevenue - metrics.returnsTotal`). Equals the
  /// Reports screen's netSales — the monthly chart sums to exactly this.
  final double revenue;

  /// Total of all returned goods at the refunded amount.
  final double returnsTotal;

  /// Net COGS after reversing the cost of returned goods, snapshot-only.
  final double cost;

  /// Net sales ([revenue] − [returnsTotal]) − [cost].
  /// Equals the Reports screen's gross profit for the same data set.
  final double profit;

  /// Number of sale documents included in the calculation.
  final int salesCounted;

  /// Number of return documents included in the calculation.
  final int returnsCounted;

  /// True when the scan hit its safety cap, so the numbers are partial.
  final bool capped;

  /// Sale/return lines whose cost is unknown (no snapshot). When > 0 the
  /// profit figure is an optimistic estimate and the UI must say so.
  final int unknownCostLines;

  /// `yyyy-MM` → profit for that month (net of returns, snapshot cost).
  final Map<String, int> profitByMonth;

  /// `yyyy-MM` → net revenue for that month (sales − returns).
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
