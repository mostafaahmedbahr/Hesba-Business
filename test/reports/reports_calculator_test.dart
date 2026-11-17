import 'package:flutter_test/flutter_test.dart';

import 'package:hesba/features/expenses/data/models/expense_model.dart';
import 'package:hesba/features/reports/data/report_metrics.dart';
import 'package:hesba/features/reports/data/reports_calculator.dart';
import 'package:hesba/features/returns/data/models/return_model.dart';
import 'package:hesba/features/sales/data/models/sale_model.dart';

/// اختبارات وحدة نقية لكل المعادلات المالية — بلا Firestore ولا مكتبات خارجية.
/// تغطي السيناريوهات 1..12 من نطاق التدقيق، وScenario 13 في admin_profit_test.
void main() {
  final start = DateTime(2026, 1, 1);
  final end = DateTime(2026, 2, 1); // حصري
  final jan5 = DateTime(2026, 1, 5, 10);
  final jan10 = DateTime(2026, 1, 10, 10);
  final jan12 = DateTime(2026, 1, 12, 10);
  final jan20 = DateTime(2026, 1, 20, 10);
  final jan21 = DateTime(2026, 1, 21, 10);
  final feb10 = DateTime(2026, 2, 10, 10);

  SaleItemModel item(
    String id, {
    double qty = 1,
    double price = 100,
    double cost = 50,
    String? name,
  }) =>
      SaleItemModel(
        productId: id,
        productName: name ?? 'منتج $id',
        quantity: qty,
        unitPrice: price,
        costPrice: cost,
      );

  SaleModel sale(
    String id,
    DateTime date,
    List<SaleItemModel> items, {
    double? subtotal,
    double discount = 0,
    double? total,
  }) {
    final sub = subtotal ?? items.fold<double>(0, (s, i) => s + i.total);
    return SaleModel(
      saleId: id,
      ownerId: 'owner-1',
      shopId: 'shop-1',
      items: items,
      subtotal: sub,
      discount: discount,
      total: total ?? sub - discount,
      paymentMethod: 'cash',
      note: '',
      createdAt: date,
    );
  }

  ReturnItemModel ritem(
    String id, {
    double qty = 1,
    double price = 100,
    String? name,
  }) =>
      ReturnItemModel(
        productId: id,
        productName: name ?? 'منتج $id',
        quantity: qty,
        unitPrice: price,
      );

  ReturnModel ret(
    String id,
    DateTime date,
    String? originalSaleId,
    List<ReturnItemModel> items, {
    double? subtotal,
    double discount = 0,
    double? total,
  }) {
    final sub = subtotal ?? items.fold<double>(0, (s, i) => s + i.total);
    return ReturnModel(
      returnId: id,
      ownerId: 'owner-1',
      shopId: 'shop-1',
      originalSaleId: originalSaleId,
      items: items,
      subtotal: sub,
      discount: discount,
      total: total ?? sub - discount,
      reason: 'عيب',
      note: '',
      createdAt: date,
    );
  }

  ExpenseModel expense(String id, DateTime date, double amount,
          {bool template = false}) =>
      ExpenseModel(
        expenseId: id,
        ownerId: 'owner-1',
        shopId: 'shop-1',
        shopName: 'محل',
        title: 'مصروف',
        category: 'عام',
        amount: amount,
        note: '',
        date: date,
        createdAt: date.add(const Duration(days: 3)),
        recurrence: template ? ExpenseModel.recurrenceMonthly : 'none',
      );

  ReportMetrics calc({
    List<SaleModel> sales = const [],
    List<ReturnModel> returns = const [],
    List<ExpenseModel> expenses = const [],
    DateTime? from,
    DateTime? to,
  }) =>
      ReportsCalculator.calculate(
        sales: sales,
        returns: returns,
        expenses: expenses,
        start: from ?? start,
        end: to ?? end,
      );

  group('Scenario 1 — normal sale with known costPrice', () {
    test('ربح = الإيراد − التكلفة من اللقطة، بيانات مكتملة', () {
      final s = sale('s1', jan5, [item('p1', qty: 2, price: 100, cost: 60)]);
      final m = calc(sales: [s]);

      expect(m.grossRevenue, 200);
      expect(m.returnsTotal, 0);
      expect(m.netSales, 200);
      expect(m.cogs, 120);
      expect(m.grossProfit, 80);
      expect(m.netProfit, 80);
      expect(m.isProfitEstimated, isFalse);
      expect(m.costCoverage, 1);
      expect(m.netMargin, closeTo(0.4, 0.0001));
      expect(ReportsCalculator.netProfitForSale(s), 80);
    });
  });

  group('Scenario 2 — multiple products with different cost prices', () {
    test('تُجمع تكلفة كل صنف من لقطته الخاصة', () {
      final s = sale('s1', jan5, [
        item('p1', qty: 2, price: 100, cost: 60), // 120
        item('p2', qty: 1, price: 50, cost: 30), // 30
      ]);
      final m = calc(sales: [s]);

      expect(m.grossRevenue, 250);
      expect(m.cogs, 150);
      expect(m.grossProfit, 100);
      expect(m.saleLinesTotal, 2);
      expect(m.saleLinesWithCost, 2);
      expect(m.unknownCostLines, 0);
    });
  });

  group('Scenario 3 — sale with percentage discount', () {
    test('الربح يُحسب من total بعد الخصم لا من مجموع أرباح الأسطر', () {
      // subtotal 250، خصم 20% = 50، total 200، تكلفة 150 ⇒ ربح 50.
      final s = sale('s1', jan5, [
        item('p1', qty: 2, price: 100, cost: 60),
        item('p2', qty: 1, price: 50, cost: 30),
      ], discount: 50);
      final m = calc(sales: [s]);

      expect(s.discount, 50);
      expect(m.grossRevenue, 200); // بعد الخصم
      expect(m.cogs, 150);
      expect(m.grossProfit, 50);
      // انحدار Bug 1: مجموع SaleItemModel.profit = 100 (قبل الخصم) — لا يُستخدم.
      expect(ReportsCalculator.netProfitForSale(s), 50);
      expect(
        s.items.fold<double>(0, (acc, i) => acc + i.profit),
        isNot(ReportsCalculator.netProfitForSale(s)),
      );
    });
  });

  group('Scenario 4 — sale with fixed discount', () {
    test('خصم ثابت يُخصم مرة واحدة من الإيراد', () {
      final s = sale('s1', jan5, [
        item('p1', qty: 2, price: 100, cost: 60),
      ], discount: 30); // subtotal 200 → total 170، تكلفة 120
      final m = calc(sales: [s]);

      expect(m.grossRevenue, 170);
      expect(m.cogs, 120);
      expect(m.grossProfit, 50);
      expect(ReportsCalculator.netProfitForSale(s), 50);
    });
  });

  group('Scenario 5 — partial product return', () {
    test('استرداد صافي + إلغاء تكلفة الكمية المرجعة فقط', () {
      final s = sale('s1', jan5, [
        item('p1', qty: 2, price: 100, cost: 60),
      ]); // total 200، cogs 120
      final r = ret('r1', jan20, 's1', [
        ritem('p1', qty: 1, price: 100),
      ], subtotal: 100, discount: 20, total: 80); // خصم 20% من الفاتورة
      final m = calc(sales: [s], returns: [r]);

      expect(m.returnsTotal, 80);
      expect(m.netSales, 120);
      expect(m.cogs, 60); // 120 − 60
      expect(m.grossProfit, 60);
      expect(m.returnLinesTotal, 1);
      expect(m.returnLinesWithCost, 1);
      expect(m.isProfitEstimated, isFalse);
    });
  });

  group('Scenario 6 — full sale return', () {
    test('الإيراد والتكلفة يعودان إلى صفر ولا تُحتسب تكلفة مرتجع مرتين', () {
      final s = sale('s1', jan5, [
        item('p1', qty: 2, price: 100, cost: 60),
        item('p2', qty: 1, price: 50, cost: 30),
      ]); // total 250، cogs 150
      final r = ret('r1', jan20, 's1', [
        ritem('p1', qty: 2, price: 100),
        ritem('p2', qty: 1, price: 50),
      ]); // subtotal 250، total 250
      final m = calc(sales: [s], returns: [r]);

      expect(m.grossRevenue, 250);
      expect(m.returnsTotal, 250);
      expect(m.netSales, 0);
      expect(m.cogs, 0);
      expect(m.grossProfit, 0);
    });
  });

  group('Scenario 7 — return after a previous partial return', () {
    test('مرتجعان متتاليان على نفس الفاتورة يُخصمان مرة لكل منهما', () {
      final s = sale('s1', jan5, [
        item('p1', qty: 3, price: 100, cost: 40),
      ]); // total 300، cogs 120
      final r1 = ret('r1', jan10, 's1', [ritem('p1', qty: 1, price: 100)]);
      final r2 = ret('r2', jan20, 's1', [ritem('p1', qty: 1, price: 100)]);
      final m = calc(sales: [s], returns: [r1, r2]);

      expect(m.returnsTotal, 200);
      expect(m.netSales, 100);
      expect(m.cogs, 40); // 120 − 40 − 40
      expect(m.grossProfit, 60);
      expect(m.returnLinesTotal, 2);
      expect(m.returnLinesWithCost, 2);
      expect(m.unknownCostLines, 0);
    });
  });

  group('Scenario 8 — legacy sale with missing costPrice', () {
    test('تكلفة مجهولة لا تُعامل كتكلفة صفرية مؤكدة — الربح يُعلَّم تقديرياً', () {
      // fromJson لفاتورة قديمة بلا حقل costPrice → 0
      final legacy = SaleModel.fromJson({
        'saleId': 'legacy',
        'ownerId': 'owner-1',
        'shopId': 'shop-1',
        'items': [
          {
            'productId': 'p1',
            'productName': 'منتج p1',
            'quantity': 2,
            'unitPrice': 100,
            'total': 200,
            // لا يوجد costPrice
          }
        ],
        'subtotal': 200,
        'discount': 0,
        'total': 200,
        'paymentMethod': 'cash',
        'note': '',
        'createdAt': null, // سيُ parses إلى DateTime.now — نستبدل أدناه
      });
      final s = legacy.copyWithDate(jan5);
      final m = calc(sales: [s]);

      expect(m.grossRevenue, 200);
      expect(m.cogs, 0);
      expect(m.grossProfit, 200);
      expect(m.unknownCostLines, 1);
      expect(m.isProfitEstimated, isTrue);
      expect(m.costCoverage, 0);
      expect(m.netMargin, isNull);
    });
  });

  group('Scenario 9 — product with zero costPrice', () {
    test('costPrice = 0 صريح يُعامل كمجهول أيضاً', () {
      final s = sale('s1', jan5, [item('p1', qty: 2, price: 100, cost: 0)]);
      final m = calc(sales: [s]);

      expect(m.cogs, 0);
      expect(m.unknownCostLines, 1);
      expect(m.isProfitEstimated, isTrue);
      expect(m.netMargin, isNull);
      expect(ReportsCalculator.netProfitForSale(s), 200);
    });
  });

  group('Scenario 10 — decimal quantities where supported', () {
    test('الكسور العشرية تُضرب في التكلفة والاسترداد بدقة', () {
      final s = sale('s1', jan5, [
        item('p1', qty: 2.5, price: 40, cost: 12),
      ]); // subtotal 100، cogs 30
      final r = ret('r1', jan20, 's1', [ritem('p1', qty: 0.5, price: 40)]);
      final m = calc(sales: [s], returns: [r]);

      expect(m.grossRevenue, 100);
      expect(m.cogs, closeTo(24, 0.0001)); // 30 − 6
      expect(m.returnsTotal, 20);
      expect(m.netSales, 80);
      expect(m.grossProfit, closeTo(56, 0.0001));
    });
  });

  group('Scenario 11 — multiple sales on different dates', () {
    test('الفترة [start, end) تفصل المبيعات بلا ازدواج ولا سقوط', () {
      final jan = sale('s1', jan5, [item('p1', qty: 1, price: 100, cost: 40)]);
      final janLate = sale('s2', jan20, [item('p2', qty: 2, price: 100, cost: 40)]);
      final feb = sale('s3', feb10, [item('p3', qty: 3, price: 100, cost: 100 / 3)]);
      final janMetrics = calc(sales: [jan, janLate, feb]);
      final febMetrics = calc(sales: [jan, janLate, feb], from: end, to: DateTime(2026, 3, 1));

      expect(janMetrics.grossRevenue, 300);
      expect(janMetrics.cogs, closeTo(120, 0.001));
      expect(janMetrics.grossProfit, closeTo(180, 0.001));
      expect(febMetrics.grossRevenue, 300);
      expect(febMetrics.cogs, closeTo(100, 0.001));
      expect(febMetrics.grossProfit, closeTo(200, 0.001));

      // سجل على الحد end بالضرف لا يُحسب في الفترة الأولى.
      final onEdge = sale('edge', end, [item('p4', qty: 1, price: 999, cost: 1)]);
      expect(calc(sales: [jan, onEdge]).grossRevenue, 100);
      expect(calc(sales: [jan, onEdge]).cogs, 40);
    });
  });

  group('Scenario 12 — returned quantities/costs not counted twice', () {
    test('مرتجعان جزئيان يغطيان الكمية كاملة ⇒ صافي الربح صفر', () {
      final s = sale('s1', jan5, [item('p1', qty: 2, price: 100, cost: 50)]);
      final r1 = ret('r1', jan10, 's1', [ritem('p1', qty: 1, price: 100)]);
      final r2 = ret('r2', jan20, 's1', [ritem('p1', qty: 1, price: 100)]);
      final m = calc(sales: [s], returns: [r1, r2]);

      expect(m.returnsTotal, 200);
      expect(m.netSales, 0);
      expect(m.cogs, 0); // 100 − 50 − 50، لا خصم مزدوج
      expect(m.grossProfit, 0);
      expect(m.returnLinesTotal, 2);
      expect(m.returnLinesWithCost, 2);
    });

    test('مرتجع لفاتورة خارج الفترة: التكلفة تُقرأ من اللقطة الأصلية', () {
      // الفاتورة في ديسمبر (خارج الفترة) والمرتجع في يناير.
      final old = sale('old', DateTime(2025, 12, 10), [
        item('p1', qty: 2, price: 100, cost: 40),
      ]);
      final r = ret('r1', jan10, 'old', [ritem('p1', qty: 1, price: 100)]);
      final m = calc(sales: [old], returns: [r]);

      expect(m.grossRevenue, 0);
      expect(m.returnsTotal, 100);
      expect(m.cogs, -40); // تكلفة مرتجعة من فاتورة خارج الفترة
      // صافي المبيعات −100 والتكلفة −40 ⇒ الربح −60 (ربح سالب للفترة).
      expect(m.grossProfit, -60);
      expect(m.returnLinesWithCost, 1); // وُجدت التكلفة رغم غياب الفاتورة من الفترة
      expect(m.isProfitEstimated, isFalse);
    });
  });

  group('cost coverage & resilience', () {
    test('مرتجع بلا فاتورة أصلية: لا تُخترع تكلفة ويُعلَّم السطر مجهولاً', () {
      final r = ret('orphan', jan5, null, [ritem('p1', qty: 1, price: 100)]);
      final m = calc(returns: [r]);

      expect(m.returnsTotal, 100);
      expect(m.cogs, 0);
      expect(m.grossProfit, -100);
      expect(m.returnLinesTotal, 1);
      expect(m.returnLinesWithCost, 0);
      expect(m.unknownCostLines, 1);
      expect(m.isProfitEstimated, isTrue);
    });

    test('مرتجع بفاتورة مفقودة من القائمة: لا يُعوَّض بسعر منتج حالي', () {
      final r = ret('r1', jan5, 'missing-sale', [ritem('p1', qty: 1, price: 100)]);
      final m = calc(returns: [r]);

      expect(m.returnLinesWithCost, 0);
      expect(m.cogs, 0);
      expect(m.isProfitEstimated, isTrue);
    });

    test('مطابقة المرتجع بالاسم عند اختلاف productId', () {
      final s = sale('s1', jan5, [item('old-id', qty: 1, price: 100, cost: 25, name: 'منتج مشترك')]);
      final r = ret('r1', jan20, 's1', [ritem('new-id', qty: 1, price: 100, name: 'منتج مشترك')]);
      final m = calc(sales: [s], returns: [r]);

      expect(m.returnLinesWithCost, 1);
      expect(m.cogs, 0); // 25 − 25
      expect(m.grossProfit, 0); // (100 − 100) − 0 — الفاتورة أُرجعت بالكامل
    });

    test('costCoverage و netMargin يتصرفان مع البيانات الناقصة', () {
      final known = sale('s1', jan5, [item('p1', qty: 1, price: 100, cost: 40)]);
      final unknown = sale('s2', jan5, [item('p2', qty: 1, price: 100, cost: 0)]);
      final m = calc(sales: [known, unknown]);

      expect(m.saleLinesTotal, 2);
      expect(m.saleLinesWithCost, 1);
      expect(m.unknownCostLines, 1);
      expect(m.costCoverage, closeTo(0.5, 0.0001));
      expect(m.isProfitEstimated, isTrue);
      expect(m.netMargin, isNull);
    });
  });

  group('expenses & equation identity', () {
    test('المصروف يُحتسب بحقل date لا createdAt، والقوالب مستثناة', () {
      final s = sale('s1', jan5, [item('p1', qty: 1, price: 100, cost: 40)]);
      final inRange = expense('e1', jan10, 15); // createdAt في فبراير
      final template = expense('e2', jan12, 500, template: true);
      final outOfRange = expense('e3', feb10, 999);
      final m = calc(sales: [s], expenses: [inRange, template, outOfRange]);

      expect(m.expensesTotal, 15);
      expect(m.netProfit, 45); // 60 ربح إجمالي − 15
    });

    test('معادلة العرض متطابقة بعد التقريب: مبيعات − مرتجعات − تكلفة − مصروفات', () {
      final s = sale('s1', jan5, [
        item('p1', qty: 3, price: 33.33, cost: 11.11),
      ]);
      final r = ret('r1', jan20, 's1', [ritem('p1', qty: 1, price: 33.33)],
          discount: 3.33, total: 30);
      final e = expense('e1', jan21, 2.22);
      final m = calc(sales: [s], returns: [r], expenses: [e]);

      expect(
        double.parse((m.grossRevenue -
                m.returnsTotal -
                m.cogs -
                m.expensesTotal)
            .toStringAsFixed(2)),
        m.netProfit,
      );
      expect(m.netSales, double.parse((m.grossRevenue - m.returnsTotal).toStringAsFixed(2)));
      expect(m.grossProfit, double.parse((m.netSales - m.cogs).toStringAsFixed(2)));
    });

    test('بدون بيانات ⇒ مؤشرات فارغة وتغطية كاملة', () {
      final m = calc();
      expect(m, ReportMetrics.empty);
      expect(m.costCoverage, 1);
      expect(m.netMargin, isNull);
    });
  });
}

/// امتداد اختباري صغير: SaleModel لا يحتوي copyWith للتاريخ، نبني نسخة يدوياً.
extension _SaleDateExt on SaleModel {
  SaleModel copyWithDate(DateTime date) => SaleModel(
        saleId: saleId,
        ownerId: ownerId,
        shopId: shopId,
        shopName: shopName,
        items: items,
        subtotal: subtotal,
        discount: discount,
        total: total,
        paymentMethod: paymentMethod,
        note: note,
        personId: personId,
        personName: personName,
        personPhone: personPhone,
        createdAt: date,
      );
}
