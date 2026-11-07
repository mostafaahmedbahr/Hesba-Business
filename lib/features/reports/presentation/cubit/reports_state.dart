import 'package:equatable/equatable.dart';

import '../../../expenses/data/models/expense_model.dart';
import '../../../returns/data/models/return_model.dart';
import '../../../sales/data/models/sale_model.dart';
import '../../data/report_metrics.dart';

/// فترة التقرير.
enum ReportPeriod { today, week, month, all }

/// لابل وحدود كل فترة.
extension ReportPeriodX on ReportPeriod {
  String get label {
    switch (this) {
      case ReportPeriod.today:
        return 'اليوم';
      case ReportPeriod.week:
        return '7 أيام';
      case ReportPeriod.month:
        return '30 يوم';
      case ReportPeriod.all:
        return 'الكل';
    }
  }

  DateTime get start {
    final now = DateTime.now();
    switch (this) {
      case ReportPeriod.today:
        return DateTime(now.year, now.month, now.day);
      case ReportPeriod.week:
        return DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
      case ReportPeriod.month:
        return DateTime(now.year, now.month, now.day).subtract(const Duration(days: 29));
      case ReportPeriod.all:
        return DateTime(2020, 1, 1);
    }
  }

  DateTime get end => DateTime.now();

  /// الحد الأعلى **حصراً** (غير شامل) — نفس حدود `ReportsCalculator`
  /// والاستعلام حتى لا يُحسب سجل على حد الفترتين أو يسقط بينهما.
  DateTime get endExclusive => end.add(const Duration(days: 1));
}

/// حالة التقارير.
enum ReportsStatus { initial, loading, success, failure }

/// داتا التقارير (الـ Cubit يملاها — الفلاتر هنا والحسابات في `ReportsCalculator`).
///
/// القوائم هنا **كاملة بلا قيود 300** (جلب بترقيم cursor) وتُصفّى محلياً
/// حسب الفترة، فالإجماليات لا تعتمد على أي صفحة عرض.
class ReportsState extends Equatable {
  final ReportsStatus status;
  final String shopId;
  final ReportPeriod period;

  /// كل سجلات المحل (بلا حد صامت) — أساس كل الحسابات.
  final List<SaleModel> allSales;
  final List<ReturnModel> allReturns;
  final List<ExpenseModel> allExpenses;

  /// مؤشرات الفترة الحالية — يحسبها `ReportsCalculator` مرة واحدة لكل
  /// (داتا × فترة) فلا تُعاد الحسابات في الودجتات.
  final ReportMetrics metrics;

  /// هل الجلب وصل لنهاية كل مجموعات الثلاث؟ false = ظهّر تحذير
  /// "بيانات غير مكتملة" ولا تقدّم الإجماليات كأرقام نهائية.
  final bool dataComplete;

  final String? errorMessage;

  const ReportsState({
    this.status = ReportsStatus.initial,
    this.shopId = '',
    this.period = ReportPeriod.week,
    this.allSales = const [],
    this.allReturns = const [],
    this.allExpenses = const [],
    this.metrics = ReportMetrics.empty,
    this.dataComplete = true,
    this.errorMessage,
  });

  /// في محل؟
  bool get hasShop => shopId.isNotEmpty;

  /// هل بيحمل أول مرة؟
  bool get isFirstLoading =>
      status == ReportsStatus.initial || status == ReportsStatus.loading;

  bool _inPeriod(DateTime dt) =>
      !dt.isBefore(period.start) && dt.isBefore(period.endExclusive);

  /// القوائم بعد فلتر الفترة.
  List<SaleModel> get sales => allSales.where((s) => _inPeriod(s.createdAt)).toList();
  List<ReturnModel> get returns => allReturns.where((r) => _inPeriod(r.createdAt)).toList();
  List<ExpenseModel> get expenses => allExpenses.where((e) => _inPeriod(e.date)).toList();

  /// الإجماليات (كلها من `ReportsCalculator` — لا حسابات مكررة هنا).
  double get totalSales => metrics.grossRevenue;
  double get totalReturns => metrics.returnsTotal;
  double get netSales => metrics.netSales;
  double get totalExpenses => metrics.expensesTotal;

  /// صافي الربح (الbottom line) = إجمالي الربح − المصروفات.
  double get balance => metrics.netProfit;

  /// مبيعات الفترة (للرسم — نفس حدود الفترة مع بقية المؤشرات).
  Map<String, double> salesByDay(List<DateTime> days, String Function(DateTime) keyOf) {
    final map = {for (final d in days) keyOf(d): 0.0};
    for (final s in sales) {
      final key = keyOf(s.createdAt);
      if (map.containsKey(key)) map[key] = (map[key] ?? 0) + s.total;
    }
    return map;
  }

  /// المصروفات حسب التصنيف (للدائرة).
  Map<String, double> get expensesByCategory {
    final map = <String, double>{};
    for (final e in expenses) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }

  /// أكثر المنتجات مبيعاً (top 5: اسم → كمية + إيراد).
  List<({String name, double qty, double revenue})> get topProducts {
    final qty = <String, double>{};
    final revenue = <String, double>{};
    for (final s in sales) {
      for (final it in s.items) {
        qty[it.productName] = (qty[it.productName] ?? 0) + it.quantity;
        revenue[it.productName] = (revenue[it.productName] ?? 0) + it.total;
      }
    }
    final sorted = qty.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).map((e) => (name: e.key, qty: e.value, revenue: revenue[e.key] ?? 0)).toList();
  }

  /// آخر الحركات (3 بيع + 2 مرتجع + 2 مصروف مرتبة).
  List<Map<String, dynamic>> get recentActivity {
    final all = <Map<String, dynamic>>[];
    for (final s in sales.take(3)) {
      all.add({'title': s.items.isEmpty ? 'فاتورة' : s.items.first.productName, 'amount': s.total, 'date': s.createdAt, 'kind': 0});
    }
    for (final r in returns.take(2)) {
      all.add({'title': r.items.isEmpty ? r.reason : r.items.first.productName, 'amount': -r.total, 'date': r.createdAt, 'kind': 1});
    }
    for (final e in expenses.take(2)) {
      all.add({'title': e.title, 'amount': -e.amount, 'date': e.date, 'kind': 2});
    }
    all.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    return all.take(5).toList();
  }

  /// نسخ مع تعديل.
  ReportsState copyWith({
    ReportsStatus? status,
    String? shopId,
    ReportPeriod? period,
    List<SaleModel>? allSales,
    List<ReturnModel>? allReturns,
    List<ExpenseModel>? allExpenses,
    ReportMetrics? metrics,
    bool? dataComplete,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ReportsState(
      status: status ?? this.status,
      shopId: shopId ?? this.shopId,
      period: period ?? this.period,
      allSales: allSales ?? this.allSales,
      allReturns: allReturns ?? this.allReturns,
      allExpenses: allExpenses ?? this.allExpenses,
      metrics: metrics ?? this.metrics,
      dataComplete: dataComplete ?? this.dataComplete,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        shopId,
        period,
        allSales,
        allReturns,
        allExpenses,
        metrics,
        dataComplete,
        errorMessage,
      ];
}

/// تنسيق رقم (صحيح من غير كسور).
String fmtReport(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

/// تنسيق مختصر للمحاور (1k).
String fmtCompact(double v) {
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(v >= 10000 ? 0 : 1)}k';
  return v.toInt().toString();
}

/// آخر 7 أيام.
List<DateTime> last7Days() =>
    List.generate(7, (i) => DateTime.now().subtract(Duration(days: 6 - i)));
