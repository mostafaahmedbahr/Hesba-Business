import '../../expenses/data/models/expense_model.dart';
import '../../returns/data/models/return_model.dart';
import '../../sales/data/models/sale_model.dart';
import 'report_metrics.dart';

/// الحسابات المالية للتقارير — دوال نقية (بدون Firestore) قابلة للاختبار.
///
/// مصادر الداتا (كلها تُمرَّر كاملة من الـ Cubit، والفلترة بالفترة هنا):
///  - `sales`     تاريخ البيع = `createdAt`، الإيراد = `total` (بعد الخصم)
///  - `returns`   تاريخ المرتجع = `createdAt`، الاسترداد = `total` (صافي بعد
///                توزيع الخصم من الفاتورة الأصلية)
///  - `expenses`  تاريخ المصروف = `date` (ليس createdAt — نفس عرف التطبيق)
///
/// قواعد مالية مؤكدة:
///  - التكلفة تُحسب من لقطة `costPrice` المحفوظة وقت البيع فقط؛ لا يُستخدم
///    سعر الشراء الحالي أبداً لإعادة حساب مبيعات تاريخية.
///  - المرتجع يُخصم مرة واحدة فقط (كل مستند مرتجع يُقرأ مرة واحدة)، وتكلفته
///    تُشتق من فاتورته الأصلية عبر `originalSaleId` فتُلغى من "التكلفة المباعة".
///  - سطر بلا تكلفة معروفة (ناقصة أو ≤ 0) لا يُعامل كتكلفة صفري مؤكَّد:
///    يُستثنى من التكلفة ويُعلَّم عبر `unknownCostLines` فيظهر الربح تقديرياً.
class ReportsCalculator {
  ReportsCalculator._();

  /// حساب مؤشرات الفترة.
  ///
  /// [start] الحد الأدنى (شامل)، [end] الحد الأعلى **حصراً** (غير شامل) —
  /// نفس حدود الاستعلام في Firestore فلا يوجد سجل على الحدود يُحسب مرتين
  /// أو يسقط بينهما.
  static ReportMetrics calculate({
    required List<SaleModel> sales,
    required List<ReturnModel> returns,
    required List<ExpenseModel> expenses,
    required DateTime start,
    required DateTime end,
  }) {
    bool inRange(DateTime dt) => !dt.isBefore(start) && dt.isBefore(end);

    // فهرس كل الفواتير (قبل الفلترة) حتى يجد مرتجع فترة حالية تكلفة فاتورة
    // أصلية حتّى لو كانت خارج الفترة المختارة.
    final salesById = <String, SaleModel>{};
    for (final sale in sales) {
      if (sale.saleId.isNotEmpty) salesById[sale.saleId] = sale;
    }

    var rawGross = 0.0;
    var rawReturns = 0.0;
    var rawCogsSold = 0.0;
    var rawCogsReturned = 0.0;
    var rawExpenses = 0.0;

    var saleLinesTotal = 0;
    var saleLinesWithCost = 0;
    var returnLinesTotal = 0;
    var returnLinesWithCost = 0;

    // ── المبيعات: إيراد + تكلفة اللقطة ──
    for (final sale in sales) {
      if (!inRange(sale.createdAt)) continue;
      rawGross += sale.total;
      for (final item in sale.items) {
        saleLinesTotal++;
        // costPrice > 0 فقط تُعتبر تكلفة مؤكدة؛ الفواتير القديمة تحفظ 0
        // كعنصر ناقص فلا تُعامل كتكلفة صفريّة.
        if (item.costPrice > 0) {
          saleLinesWithCost++;
          rawCogsSold += item.costPrice * item.quantity;
        }
      }
    }

    // ── المرتجعات: استرداد + إلغاء تكلفة البضاعة المرجعة ──
    for (final ret in returns) {
      if (!inRange(ret.createdAt)) continue;
      rawReturns += ret.total;

      final saleId = ret.originalSaleId ?? '';
      final original = saleId.isEmpty ? null : salesById[saleId];

      for (final item in ret.items) {
        returnLinesTotal++;
        final cost = original == null
            ? null
            : _lineCost(original, item.productId, item.productName);
        if (cost != null && cost > 0) {
          returnLinesWithCost++;
          rawCogsReturned += cost * item.quantity;
        }
        // لم نجد التكلفة → السطر يُعلَّم غير معروف ولا يُخصم شيء (لا نخترع
        // تكلفة صفرياً ولا نخمّن).
      }
    }

    // ── المصروفات (بحقل `date` — عرف التطبيق) ──
    // القوالب المتكررة ليست مصروفات فعلية — لا تُخصم.
    for (final expense in expenses) {
      if (expense.isTemplate) continue;
      if (!inRange(expense.date)) continue;
      rawExpenses += expense.amount;
    }

    // تقريب المكوّنات أولاً ثم اشتقاق باقي المؤشرات منها، فتبقى معادلة
    // العرض (مبيعات − مرتجعات − تكلفة − مصروفات = صافي ربح) مطابقة تماماً.
    final grossRevenue = _r2(rawGross);
    final returnsTotal = _r2(rawReturns);
    final cogs = _r2(rawCogsSold - rawCogsReturned);
    final expensesTotal = _r2(rawExpenses);
    final netSales = _r2(grossRevenue - returnsTotal);
    final grossProfit = _r2(netSales - cogs);
    final netProfit = _r2(grossProfit - expensesTotal);

    return ReportMetrics(
      grossRevenue: grossRevenue,
      returnsTotal: returnsTotal,
      netSales: netSales,
      cogs: cogs,
      grossProfit: grossProfit,
      expensesTotal: expensesTotal,
      netProfit: netProfit,
      saleLinesTotal: saleLinesTotal,
      saleLinesWithCost: saleLinesWithCost,
      returnLinesTotal: returnLinesTotal,
      returnLinesWithCost: returnLinesWithCost,
    );
  }

  /// تكلفة سطر المرتجع من فاتورته الأصلية: مطابقة بالـ productId ثم بالاسم
  /// (نفس منطق التحقق في ReturnsRepoImpl).
  static double? _lineCost(SaleModel sale, String productId, String productName) {
    if (productId.isNotEmpty) {
      for (final item in sale.items) {
        if (item.productId == productId) return item.costPrice;
      }
    }
    if (productName.isNotEmpty) {
      for (final item in sale.items) {
        if (item.productName == productName) return item.costPrice;
      }
    }
    return null;
  }

  static double _r2(double v) => double.parse(v.toStringAsFixed(2));
}
