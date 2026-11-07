import 'package:flutter_test/flutter_test.dart';
import 'package:hesba/features/expenses/data/models/expense_model.dart';
import 'package:hesba/features/reports/data/report_metrics.dart';
import 'package:hesba/features/reports/data/reports_calculator.dart';
import 'package:hesba/features/returns/data/models/return_model.dart';
import 'package:hesba/features/sales/data/models/sale_model.dart';

/// اختبارات الحسابات المالية للتقارير (ReportsCalculator).
///
/// المعادلات المُتحقَّق منها:
///   netSales   = grossRevenue − returnsTotal
///   cogs       = تكلفة المبيعات − تكلفة المرتجعات (لقطة costPrice)
///   grossProfit = netSales − cogs
///   netProfit  = grossProfit − expensesTotal
///
/// والفترة: [start, end) — الحد الأعلى حصري فلا يُحسب سجل مرتين على الحدود.
void main() {
  final rangeStart = DateTime(2026, 1, 1);
  final rangeEnd = DateTime(2026, 2, 1); // حصري

  SaleItemModel line({
    String productId = 'p1',
    String name = 'منتج',
    double qty = 1,
    double price = 100,
    double cost = 40,
  }) =>
      SaleItemModel(
        productId: productId,
        productName: name,
        quantity: qty,
        unitPrice: price,
        costPrice: cost,
      );

  SaleModel sale({
    String id = 's1',
    List<SaleItemModel>? items,
    double? total,
    double? subtotal,
    double discount = 0,
    DateTime? at,
  }) {
    final it = items ?? [line()];
    final sub = subtotal ?? it.fold<double>(0, (a, e) => a + e.total);
    return SaleModel(
      saleId: id,
      ownerId: 'o1',
      shopId: 'sh1',
      items: it,
      subtotal: sub,
      discount: discount,
      total: total ?? (sub - discount),
      paymentMethod: 'cash',
      note: '',
      createdAt: at ?? DateTime(2026, 1, 10),
    );
  }

  ReturnModel ret({
    String id = 'r1',
    String saleId = 's1',
    List<ReturnItemModel>? items,
    double? total,
    DateTime? at,
  }) {
    final it = items ??
        [ReturnItemModel(productId: 'p1', productName: 'منتج', quantity: 1, unitPrice: 100)];
    final sub = it.fold<double>(0, (a, e) => a + e.total);
    return ReturnModel(
      returnId: id,
      ownerId: 'o1',
      shopId: 'sh1',
      originalSaleId: saleId,
      items: it,
      subtotal: sub,
      total: total ?? sub,
      reason: 'عيب',
      note: '',
      createdAt: at ?? DateTime(2026, 1, 12),
    );
  }

  ExpenseModel expense({String id = 'e1', double amount = 60, DateTime? date}) =>
      ExpenseModel(
        expenseId: id,
        ownerId: 'o1',
        shopId: 'sh1',
        shopName: 'محل',
        title: 'إيجار',
        category: 'تشغيل',
        amount: amount,
        note: '',
        date: date ?? DateTime(2026, 1, 15),
        createdAt: date ?? DateTime(2026, 1, 15),
      );

  ReportMetrics calc({
    List<SaleModel> sales = const [],
    List<ReturnModel> returns = const [],
    List<ExpenseModel> expenses = const [],
    DateTime? start,
    DateTime? end,
  }) =>
      ReportsCalculator.calculate(
        sales: sales,
        returns: returns,
        expenses: expenses,
        start: start ?? rangeStart,
        end: end ?? rangeEnd,
      );

  // ── مبيعات طبيعية ──────────────────────────────────────────────

  test('بيع عادي بتكلفة معروفة: إيراد + تكلفة + ربح', () {
    final m = calc(sales: [sale(total: 100)]);
    expect(m.grossRevenue, 100);
    expect(m.returnsTotal, 0);
    expect(m.netSales, 100);
    expect(m.cogs, 40); // qty 1 × cost 40
    expect(m.grossProfit, 60);
    expect(m.expensesTotal, 0);
    expect(m.netProfit, 60);
    expect(m.isProfitEstimated, isFalse);
    expect(m.costCoverage, 1);
    expect(m.netMargin, closeTo(0.6, 1e-9));
  });

  test('منتجات متعددة بتكاليف مختلفة تُجمع بدقة', () {
    final m = calc(sales: [
      sale(
        items: [
          line(productId: 'a', qty: 2, price: 50, cost: 20),
          line(productId: 'b', qty: 1, price: 30, cost: 10),
        ],
        subtotal: 130,
        total: 130,
      ),
    ]);
    expect(m.grossRevenue, 130);
    expect(m.cogs, 2 * 20 + 1 * 10); // 50
    expect(m.grossProfit, 80);
    expect(m.saleLinesTotal, 2);
    expect(m.saleLinesWithCost, 2);
  });

  // ── المرتجعات ──────────────────────────────────────────────────

  test('مرتجع كلي: صافي المبيعات والتكلفة يصفران معاً', () {
    final s = sale(items: [line(qty: 1, price: 100, cost: 40)], total: 100);
    final m = calc(
      sales: [s],
      returns: [ret(items: [
        ReturnItemModel(productId: 'p1', productName: 'منتج', quantity: 1, unitPrice: 100)
      ], total: 100)],
    );
    expect(m.grossRevenue, 100);
    expect(m.returnsTotal, 100);
    expect(m.netSales, 0);
    expect(m.cogs, 0); // 40 − 40
    expect(m.grossProfit, 0);
    expect(m.isProfitEstimated, isFalse);
  });

  test('مرتجع جزئي: يُخصم استرداده وتكلفته المنعكسة فقط', () {
    final s = sale(items: [line(qty: 2, price: 50, cost: 20)], total: 100);
    final m = calc(
      sales: [s],
      returns: [ret(items: [
        ReturnItemModel(productId: 'p1', productName: 'منتج', quantity: 1, unitPrice: 50)
      ], total: 50)],
    );
    expect(m.grossRevenue, 100);
    expect(m.returnsTotal, 50);
    expect(m.netSales, 50);
    expect(m.cogs, 40 - 20); // بيعنا قطعتين ورجعنا واحدة
    expect(m.grossProfit, 30);
  });

  test('أكثر من مرتجع لنفس الفاتورة: كل مرتجع يُحسب مرة واحدة فقط', () {
    final s = sale(items: [line(qty: 3, price: 50, cost: 20)], total: 150);
    final m = calc(
      sales: [s],
      returns: [
        ret(id: 'r1', items: [
          ReturnItemModel(productId: 'p1', productName: 'منتج', quantity: 1, unitPrice: 50)
        ], total: 50),
        ret(id: 'r2', items: [
          ReturnItemModel(productId: 'p1', productName: 'منتج', quantity: 2, unitPrice: 50)
        ], total: 100),
      ],
    );
    // لا تكرار: 50 + 100 = 150 (وليس 300 أو أضعافها).
    expect(m.returnsTotal, 150);
    expect(m.netSales, 0);
    expect(m.cogs, 60 - 20 - 40); // 0
    expect(m.grossProfit, 0);
  });

  test('مرتجع لفاتورة خارج الفترة: الاسترداد والتكلفة يدخلان الفترة الحالية', () {
    // فاتورة يناير (خارج الفترة) ومرتجعها فبراير (داخل الفترة).
    final oldSale = sale(
      id: 'old',
      items: [line(qty: 1, price: 100, cost: 40)],
      total: 100,
      at: DateTime(2026, 1, 5),
    );
    final m = calc(
      sales: [oldSale], // القائمة الكاملة تُمرَّر للاقتباس
      returns: [ret(saleId: 'old', total: 100, at: DateTime(2026, 2, 3))],
      start: DateTime(2026, 2, 1),
      end: DateTime(2026, 3, 1),
    );
    expect(m.grossRevenue, 0); // الفاتورة خارج الفترة
    expect(m.returnsTotal, 100);
    expect(m.netSales, -100);
    expect(m.cogs, -40); // 0 − تكلفة المرتجع المأخوذة من فاتورته الأصلية
    expect(m.grossProfit, -60);
    expect(m.isProfitEstimated, isFalse); // التكلفة معروفة رغم خروج الفاتورة
  });

  test('مرتجع بلا originalSaleId يُعلَّم غير معروف ولا يُخمَّن', () {
    final s = sale(total: 100);
    final orphan = ReturnModel(
      returnId: 'rx',
      ownerId: 'o1',
      shopId: 'sh1',
      items: [ReturnItemModel(productId: 'p1', productName: 'منتج', quantity: 1, unitPrice: 100)],
      subtotal: 100,
      total: 100,
      reason: 'عيب',
      note: '',
      createdAt: DateTime(2026, 1, 12),
    );
    final m = calc(sales: [s], returns: [orphan]);
    expect(m.returnsTotal, 100);
    expect(m.cogs, 40); // لم يُخصم شيء من التكلفة
    expect(m.returnLinesTotal, 1);
    expect(m.returnLinesWithCost, 0);
    expect(m.isProfitEstimated, isTrue);
    expect(m.netMargin, isNull); // لا نسبة هامش فوق بيانات ناقصة
  });

  test('مرتجع بفاتورة أصلية غير موجودة يُعلَّم غير معروف', () {
    final m = calc(
      returns: [ret(saleId: 'غير-موجودة', total: 50)],
    );
    expect(m.returnLinesWithCost, 0);
    expect(m.isProfitEstimated, isTrue);
    expect(m.cogs, 0);
  });

  test('مطابقة تكلفة المرتجع بالاسم عندما يختلف productId', () {
    final s = sale(items: [
      line(productId: 'p-legacy', name: 'قميص', qty: 1, price: 100, cost: 55),
    ], total: 100);
    final m = calc(
      sales: [s],
      returns: [ret(items: [
        ReturnItemModel(productId: '', productName: 'قميص', quantity: 1, unitPrice: 100)
      ], total: 100)],
    );
    expect(m.returnLinesWithCost, 1);
    expect(m.cogs, 55 - 55);
  });

  // ── المصروفات والفترة ──────────────────────────────────────────

  test('المصروفات تُخصم من صافي الربح', () {
    final m = calc(
      sales: [sale(total: 100)],
      expenses: [expense(amount: 60)],
    );
    expect(m.grossProfit, 60);
    expect(m.expensesTotal, 60);
    expect(m.netProfit, 0);
  });

  test('فلترة التاريخ: ما قبل البداية أو بعد النهاية (حصراً) لا يُحسب', () {
    final m = calc(
      sales: [
        sale(id: 'before', total: 10, at: DateTime(2025, 12, 31, 23, 59)),
        sale(id: 'inside-start', total: 20, at: rangeStart), // على حد البداية
        sale(id: 'inside', total: 30, at: DateTime(2026, 1, 20)),
        sale(id: 'at-end', total: 40, at: rangeEnd), // على الحد العلوي = مستبعد
        sale(id: 'after', total: 50, at: DateTime(2026, 2, 2)),
      ],
      expenses: [
        expense(id: 'out', amount: 999, date: DateTime(2025, 12, 1)),
        expense(id: 'in', amount: 60, date: DateTime(2026, 1, 15)),
      ],
      returns: [
        ret(id: 'out', total: 777, at: DateTime(2025, 6, 1)),
        ret(id: 'in', total: 25, at: DateTime(2026, 1, 25)),
      ],
    );
    expect(m.grossRevenue, 20 + 30); // بداية داخلة، حدود النهاية وخارجها مستبعدة
    expect(m.returnsTotal, 25);
    expect(m.expensesTotal, 60);
    expect(m.saleLinesTotal, 2);
  });

  test('مصروف خارج الفترة لا يُخصم (تاريخ `date` وليس `createdAt`)', () {
    final m = calc(
      expenses: [
        // تاريخ المصروف داخل الفترة لكن أُنشئ بعدها (createdAt خارج).
        ExpenseModel(
          expenseId: 'e1',
          ownerId: 'o1',
          shopId: 'sh1',
          shopName: 'محل',
          title: 'فاتورة',
          category: 'تشغيل',
          amount: 45,
          note: '',
          date: DateTime(2026, 1, 20),
          createdAt: DateTime(2026, 3, 1),
        ),
      ],
    );
    expect(m.expensesTotal, 45);
  });

  test('فترة بلا داتة: كل المؤشرات صفراً وبدون تقدير', () {
    final m = calc();
    expect(m.grossRevenue, 0);
    expect(m.netSales, 0);
    expect(m.cogs, 0);
    expect(m.netProfit, 0);
    expect(m.isProfitEstimated, isFalse);
    expect(m.costCoverage, 1);
    expect(m.netMargin, isNull);
  });

  // ── التكاليف المفقودة (الفواتير القديمة) ───────────────────────

  SaleModel legacySaleFromJson(Map<String, dynamic> json) =>
      SaleModel.fromJson(json);

  Map<String, dynamic> saleJson({Object? costPrice = _missing, double total = 100}) {
    return {
      'saleId': 'legacy',
      'ownerId': 'o1',
      'shopId': 'sh1',
      'items': [
        {
          'productId': 'p1',
          'productName': 'منتج قديم',
          'quantity': 1,
          'unitPrice': total,
          'total': total,
          if (!identical(costPrice, _missing)) 'costPrice': costPrice,
        },
      ],
      'subtotal': total,
      'discount': 0,
      'total': total,
      'paymentMethod': 'cash',
      'note': '',
      'createdAt': DateTime(2026, 1, 10),
    };
  }

  test('costPrice مفقود (فاتورة قديمة): لا يُعامل كتكلفة صفري مؤكدة', () {
    final legacy = legacySaleFromJson(saleJson()); // الحقل غير موجود أصلاً
    expect(legacy.items.single.costPrice, 0); // يُقرأ 0 افتراضياً

    final m = calc(sales: [legacy], expenses: [expense(amount: 30)]);
    expect(m.grossRevenue, 100); // الإيراد متاح دائماً
    expect(m.expensesTotal, 30);
    expect(m.cogs, 0); // لا نضيف تكلفة مخترعة…
    expect(m.saleLinesTotal, 1);
    expect(m.saleLinesWithCost, 0); // …بل نعلّمه غير معروف
    expect(m.isProfitEstimated, isTrue);
    expect(m.costCoverage, 0);
    expect(m.netMargin, isNull);
    expect(m.netProfit, 70); // 100 − 0 − 30 (تقديري — أعلى من الحقيقة)
  });

  test('costPrice = 0 صراحةً يُعامل كغير معروف (تحفّظ دفاعي)', () {
    final zero = legacySaleFromJson(saleJson(costPrice: 0));
    final m = calc(sales: [zero]);
    expect(m.saleLinesWithCost, 0);
    expect(m.isProfitEstimated, isTrue);
    expect(m.cogs, 0);
  });

  test('costPrice سالب/تالف يُعامل كغير معروف', () {
    final negative = legacySaleFromJson(saleJson(costPrice: -12.5));
    final m = calc(sales: [negative]);
    expect(m.saleLinesWithCost, 0);
    expect(m.isProfitEstimated, isTrue);
    expect(m.cogs, 0);
    expect(m.grossRevenue, 100);
  });

  test('مزيج سجلات مكتملة وناقصة: الإيراد دقيق والتغطية مرئية', () {
    final known = sale(id: 'k', total: 200, items: [line(qty: 1, price: 200, cost: 80)]);
    final legacy = legacySaleFromJson(saleJson(total: 100));
    final m = calc(
      sales: [known, legacy],
      returns: [
        ret(id: 'r1', total: 50, items: [
          ReturnItemModel(productId: 'p1', productName: 'منتج', quantity: 1, unitPrice: 50)
        ]),
      ],
      expenses: [expense(amount: 40)],
    );

    // الإيراد والمصروفات مؤكدة بغض النظر عن نقص التكلفة.
    expect(m.grossRevenue, 300);
    expect(m.returnsTotal, 50);
    expect(m.netSales, 250);
    expect(m.expensesTotal, 40);

    // التكلفة: 80 من الفاتورة المعروفة فقط؛ المرتجع غير مطابق لفاتورة
    // أصلية في هذه الحالة → سطره غير معروف أيضاً.
    expect(m.cogs, 80);
    expect(m.saleLinesTotal, 2);
    expect(m.saleLinesWithCost, 1);
    expect(m.returnLinesTotal, 1);
    expect(m.returnLinesWithCost, 0);
    expect(m.unknownCostLines, 2);
    expect(m.isProfitEstimated, isTrue);
    expect(m.costCoverage, closeTo(1 / 3, 1e-9));
    expect(m.netMargin, isNull);
  });

  test('معادلة العرض تبقى مطابقة تماماً (تقريب المكوّنات ثم الاشتقاق)', () {
    final m = calc(
      sales: [
        sale(id: 'a', total: 10.15, items: [line(qty: 1, price: 10.15, cost: 4.05)]),
        sale(id: 'b', total: 3.07, items: [line(qty: 3, price: 1.0233, cost: 0.7)]),
      ],
      returns: [ret(id: 'r', total: 2.11)],
      expenses: [expense(amount: 1.99)],
    );
    // معادلة العرض تكاد تكون مطابقة حرفياً — نتسامح ±0.01 (فرق التقريب
    // العشري فقط) مع التأكد أن كل قيمة بمنزلتين عشريتين بالضبط.
    expect(m.netSales, closeTo(m.grossRevenue - m.returnsTotal, 0.01));
    expect(m.grossProfit, closeTo(m.netSales - m.cogs, 0.01));
    expect(m.netProfit, closeTo(m.grossProfit - m.expensesTotal, 0.01));
    // وجميع القيم بمنزلتين عشريتين.
    for (final v in [
      m.grossRevenue,
      m.returnsTotal,
      m.netSales,
      m.cogs,
      m.grossProfit,
      m.expensesTotal,
      m.netProfit,
    ]) {
      expect(double.parse(v.toStringAsFixed(2)), v);
    }
  });

  // ── أهلية المبيعات ─────────────────────────────────────────────

  test('أهلية المبيعات: لا يوجد مفهوم إلغاء في الموديل — النطاق التاريخي وحده يحدد', () {
    // SaleModel لا يحمل أي حقل status/cancel؛ أي مبيعات في الفترة تُحتسب.
    final s = sale(total: 100);
    expect(s.toJson().containsKey('status'), isFalse);
    final m = calc(sales: [s]);
    expect(m.grossRevenue, 100);
    expect(m.saleLinesTotal, 1);
  });
}

/// علامة تمييز "الحقل غير موجود" في `saleJson`.
const Object _missing = Object();
