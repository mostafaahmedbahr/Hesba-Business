import 'package:equatable/equatable.dart';

/// نتائج الحسابات المالية لفترة تقرير واحدة — المصدر الوحيد للحسابات
/// (لا تُعاد كتابتها في أي ودجت).
///
/// القواعد المالية:
///  - إجمالي المبيعات      = مجموع `sale.total` (بعد الخصم) في الفترة
///  - إجمالي المرتجعات     = مجموع `return.total` (صافي الاسترداد) في الفترة
///  - صافي المبيعات        = إجمالي المبيعات − إجمالي المرتجعات
///  - تكلفة البضاعة المباعة = تكلفة المبيعات (لقطة `costPrice`)
///                            − تكلفة المرتجعات (من الفاتورة الأصلية)
///  - إجمالي الربح         = صافي المبيعات − تكلفة البضاعة المباعة
///  - صافي الربح           = إجمالي الربح − إجمالي المصروفات
class ReportMetrics extends Equatable {
  const ReportMetrics({
    required this.grossRevenue,
    required this.returnsTotal,
    required this.netSales,
    required this.cogs,
    required this.grossProfit,
    required this.expensesTotal,
    required this.netProfit,
    required this.saleLinesTotal,
    required this.saleLinesWithCost,
    required this.returnLinesTotal,
    required this.returnLinesWithCost,
  });

  /// إجمالي المبيعات (بعد الخصم، قبل المرتجعات).
  final double grossRevenue;

  /// إجمالي المرتجعات (صافي المبلغ المسترد).
  final double returnsTotal;

  /// صافي المبيعات = grossRevenue − returnsTotal.
  final double netSales;

  /// تكلفة البضاعة المباعة (صافية من المرتجعات) — من لقطة `costPrice`
  /// التاريخية فقط، ولا تعتمد على سعر الشراء الحالي إطلاقاً.
  final double cogs;

  /// إجمالي الربح = netSales − cogs.
  final double grossProfit;

  /// إجمالي المصروفات في الفترة.
  final double expensesTotal;

  /// صافي الربح = grossProfit − expensesTotal.
  final double netProfit;

  /// عدد أسطر المبيعات في الفترة (لحساب تغطية التكلفة).
  final int saleLinesTotal;

  /// الأسطر التي تحمل تكلفة شرائية معروفة (costPrice > 0).
  final int saleLinesWithCost;

  /// عدد أسطر المرتجعات في الفترة.
  final int returnLinesTotal;

  /// أسطر المرتجعات التي عُثر على تكلفتها في فاتورتها الأصلية.
  final int returnLinesWithCost;

  static const empty = ReportMetrics(
    grossRevenue: 0,
    returnsTotal: 0,
    netSales: 0,
    cogs: 0,
    grossProfit: 0,
    expensesTotal: 0,
    netProfit: 0,
    saleLinesTotal: 0,
    saleLinesWithCost: 0,
    returnLinesTotal: 0,
    returnLinesWithCost: 0,
  );

  /// أسطر بلا تكلفة معروفة (مبيعات + مرتجعات).
  int get unknownCostLines =>
      (saleLinesTotal - saleLinesWithCost) +
      (returnLinesTotal - returnLinesWithCost);

  /// هل الربح تقديري لوجود فواتير قديمة بلا تكلفة شرائية؟
  bool get isProfitEstimated => unknownCostLines > 0;

  /// نسبة الأسطر التي عُرفت تكلفتها (1.0 = كامل).
  double get costCoverage {
    final total = saleLinesTotal + returnLinesTotal;
    if (total == 0) return 1;
    return (saleLinesWithCost + returnLinesWithCost) / total;
  }

  /// هامش صافي الربح — `null` عندما يكون الربح تقديرياً أو المبيعات صفراً
  /// (لا نعرض نسباً مضللة فوق بيانات ناقصة).
  double? get netMargin {
    if (isProfitEstimated || netSales == 0) return null;
    return netProfit / netSales;
  }

  @override
  List<Object?> get props => [
        grossRevenue,
        returnsTotal,
        netSales,
        cogs,
        grossProfit,
        expensesTotal,
        netProfit,
        saleLinesTotal,
        saleLinesWithCost,
        returnLinesTotal,
        returnLinesWithCost,
      ];
}
