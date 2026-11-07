import 'package:flutter_test/flutter_test.dart';
import 'package:hesba/features/purchases/data/stock_purchase_calculator.dart';

/// اختبارات معادلات زيادة المخزون (نقية بلا Firestore):
/// المخزون الجديد، المتوسط المرجح، التحقق من القيم، والفاتورة المتعددة.
void main() {
  ProductSnapshot snap({
    String id = 'p1',
    String name = 'منتج',
    String shopId = 'shop1',
    double stock = 0,
    double costPrice = 0,
  }) =>
      ProductSnapshot(
        id: id,
        name: name,
        shopId: shopId,
        stock: stock,
        costPrice: costPrice,
      );

  PurchaseLineInput line({
    String productId = 'p1',
    required double qty,
    required double cost,
  }) =>
      PurchaseLineInput(
        productId: productId,
        quantity: qty,
        purchaseUnitCost: cost,
      );

  String messageOf(Object error) => error.toString().replaceAll('Exception: ', '');

  Matcher throwsWith(String fragment) => throwsA(
        isA<Exception>().having(messageOf, 'message', contains(fragment)),
      );

  // ── newStock ────────────────────────────────────────────────
  group('المخزون الجديد (newStock = الحالي + الوارد)', () {
    test('مخزون صفري: المخزون الجديد = الكمية الواردة', () {
      expect(
        StockPurchaseCalculator.computeNewStock(
          currentStock: 0,
          receivedQuantity: 10,
        ),
        10,
      );
    });

    test('مخزون قائم: يُجمع على الكمية', () {
      expect(
        StockPurchaseCalculator.computeNewStock(
          currentStock: 5,
          receivedQuantity: 3,
        ),
        8,
      );
    });

    test('الكميات الكسرية مسموحة (نظام الكيلو/اللتر)', () {
      expect(
        StockPurchaseCalculator.computeNewStock(
          currentStock: 2.5,
          receivedQuantity: 0.5,
        ),
        3.0,
      );
    });

    test('قيمة غير منتهية (overflow) تُرفض', () {
      expect(
        () => StockPurchaseCalculator.computeNewStock(
          currentStock: double.maxFinite,
          receivedQuantity: double.maxFinite,
        ),
        throwsException,
      );
    });
  });

  // ── weighted average cost ───────────────────────────────────
  group('متوسط سعر الشراء المرجح', () {
    test('مخزون صفري: التكلفة الجديدة = سعر الشراء مباشرة', () {
      expect(
        StockPurchaseCalculator.computeAverageCost(
          currentStock: 0,
          currentCost: 0,
          receivedQuantity: 5,
          purchaseUnitCost: 20,
        ),
        20,
      );
    });

    test('مخزون قائم بسعر آخر: متوسط مرجح صحيح', () {
      // ((5×10) + (5×20)) / 10 = 15
      expect(
        StockPurchaseCalculator.computeAverageCost(
          currentStock: 5,
          currentCost: 10,
          receivedQuantity: 5,
          purchaseUnitCost: 20,
        ),
        15,
      );
    });

    test('أوزان غير متساوية', () {
      // ((8×10) + (2×20)) / 10 = 12
      expect(
        StockPurchaseCalculator.computeAverageCost(
          currentStock: 8,
          currentCost: 10,
          receivedQuantity: 2,
          purchaseUnitCost: 20,
        ),
        12,
      );
    });

    test('كسور في الكميات والأسعار', () {
      // ((3×10.5) + (2×12.75)) / 5 = 11.4
      expect(
        StockPurchaseCalculator.computeAverageCost(
          currentStock: 3,
          currentCost: 10.5,
          receivedQuantity: 2,
          purchaseUnitCost: 12.75,
        ),
        closeTo(11.4, 1e-9),
      );
    });

    test('التكلفة الحالية صفر تدخل في المتوسط', () {
      // ((5×0) + (5×20)) / 10 = 10
      expect(
        StockPurchaseCalculator.computeAverageCost(
          currentStock: 5,
          currentCost: 0,
          receivedQuantity: 5,
          purchaseUnitCost: 20,
        ),
        10,
      );
    });

    test('لا قسمة على صفر إطلاقاً (currentStock = 0)', () {
      // الفرع الصفري يعيد سعر الشراء بدون قسمة.
      final avg = StockPurchaseCalculator.computeAverageCost(
        currentStock: 0,
        currentCost: 999,
        receivedQuantity: 1,
        purchaseUnitCost: 42,
      );
      expect(avg, 42);
    });

    test('التقريب لخانتين عشريتين', () {
      // (10.333 + 10.334) / 2 = 10.3335 → 10.33
      expect(
        StockPurchaseCalculator.computeAverageCost(
          currentStock: 1,
          currentCost: 10.333,
          receivedQuantity: 1,
          purchaseUnitCost: 10.334,
        ),
        10.33,
      );
    });

    test('كمية صفر أو سالبة تُرفض', () {
      for (final qty in [0.0, -1.0, double.nan, double.infinity]) {
        expect(
          () => StockPurchaseCalculator.computeAverageCost(
            currentStock: 5,
            currentCost: 10,
            receivedQuantity: qty,
            purchaseUnitCost: 10,
          ),
          throwsException,
          reason: 'qty=$qty',
        );
      }
    });

    test('تكلفة شراء سالبة أو غير منتهية تُرفض', () {
      for (final cost in [-0.01, double.nan, double.infinity]) {
        expect(
          () => StockPurchaseCalculator.computeAverageCost(
            currentStock: 5,
            currentCost: 10,
            receivedQuantity: 1,
            purchaseUnitCost: cost,
          ),
          throwsException,
          reason: 'cost=$cost',
        );
      }
    });

    test('مخزون حالي سالب أو تكلفة حالية سالبة/NaN تُرفض', () {
      expect(
        () => StockPurchaseCalculator.computeAverageCost(
          currentStock: -1,
          currentCost: 10,
          receivedQuantity: 1,
          purchaseUnitCost: 10,
        ),
        throwsException,
      );
      expect(
        () => StockPurchaseCalculator.computeAverageCost(
          currentStock: 5,
          currentCost: double.nan,
          receivedQuantity: 1,
          purchaseUnitCost: 10,
        ),
        throwsException,
      );
    });
  });

  // ── rounding ────────────────────────────────────────────────
  group('التقريب المالي (لخانتين)', () {
    test('12.346 ← 12.35', () {
      expect(StockPurchaseCalculator.roundMoney(12.346), 12.35);
    });

    test('12.341 ← 12.34', () {
      expect(StockPurchaseCalculator.roundMoney(12.341), 12.34);
    });

    test('الأعداد الصحيحة لا تتغير', () {
      expect(StockPurchaseCalculator.roundMoney(7), 7);
      expect(StockPurchaseCalculator.roundMoney(7.0), 7);
    });
  });

  // ── full invoice processing ─────────────────────────────────
  group('معالجة الفاتورة الكاملة (compute)', () {
    test('فاتورة بمنتج واحد: كل الحقول محسوبة', () {
      final computed = StockPurchaseCalculator.compute(
        shopId: 'shop1',
        lines: [line(qty: 5, cost: 20)],
        products: {'p1': snap(stock: 5, costPrice: 10)},
      );

      expect(computed.items, hasLength(1));
      expect(computed.productUpdates, hasLength(1));
      expect(computed.totalAmount, 100); // 5 × 20

      final item = computed.items.single;
      expect(item.productId, 'p1');
      expect(item.productName, 'منتج');
      expect(item.previousStock, 5);
      expect(item.newStock, 10);
      expect(item.previousCost, 10);
      expect(item.purchaseUnitCost, 20);
      expect(item.newAverageCost, 15); // ((5×10)+(5×20))/10
      expect(item.lineTotal, 100);

      final update = computed.productUpdates['p1']!;
      expect(update.newStock, 10);
      expect(update.newAverageCost, 15);
    });

    test('فاتورة متعددة المنتجات: الإجمالي = مجموع الأسطر', () {
      final computed = StockPurchaseCalculator.compute(
        shopId: 'shop1',
        lines: [
          line(productId: 'p1', qty: 2, cost: 10), // 20
          line(productId: 'p2', qty: 4, cost: 15.5), // 62
          line(productId: 'p3', qty: 1, cost: 0), // 0
        ],
        products: {
          'p1': snap(id: 'p1', stock: 5, costPrice: 8),
          'p2': snap(id: 'p2', name: 'آخر', stock: 0, costPrice: 12),
          'p3': snap(id: 'p3', stock: 3, costPrice: 4),
        },
      );

      expect(computed.items, hasLength(3));
      expect(computed.productUpdates, hasLength(3));
      expect(computed.totalAmount, 82); // 20 + 62 + 0
      expect(computed.productUpdates['p1']!.newStock, 7);
      expect(computed.productUpdates['p2']!.newStock, 4);
      expect(computed.productUpdates['p2']!.newAverageCost, 15.5); // صفر → الجديد
      expect(computed.productUpdates['p3']!.newStock, 4);
    });

    test('إجمالي الفاتورة يُقرَّب لخانتين بعد الجمع', () {
      // 3 أسطر × (0.333 × 10 = 3.33) = 9.99
      final computed = StockPurchaseCalculator.compute(
        shopId: 'shop1',
        lines: [
          line(productId: 'p1', qty: 0.333, cost: 10),
          line(productId: 'p2', qty: 0.333, cost: 10),
          line(productId: 'p3', qty: 0.333, cost: 10),
        ],
        products: {
          'p1': snap(id: 'p1', stock: 1, costPrice: 10),
          'p2': snap(id: 'p2', stock: 1, costPrice: 10),
          'p3': snap(id: 'p3', stock: 1, costPrice: 10),
        },
      );
      expect(computed.totalAmount, 9.99);
      expect(computed.items.first.lineTotal, 3.33);
    });

    test('مخزون صفري في الفاتورة: التكلفة الجديدة = سعر الشراء', () {
      final computed = StockPurchaseCalculator.compute(
        shopId: 'shop1',
        lines: [line(qty: 6, cost: 12.5)],
        products: {'p1': snap(stock: 0, costPrice: 99)},
      );
      expect(computed.items.single.newAverageCost, 12.5);
      expect(computed.items.single.newStock, 6);
    });

    test('فاتورة فاضية تُرفض', () {
      expect(
        () => StockPurchaseCalculator.compute(
          shopId: 'shop1',
          lines: const [],
          products: const {},
        ),
        throwsWith('منتج واحد على الأقل'),
      );
    });

    test('سطر بلا منتج يُرفض', () {
      expect(
        () => StockPurchaseCalculator.compute(
          shopId: 'shop1',
          lines: [line(productId: '  ', qty: 1, cost: 5)],
          products: const {},
        ),
        throwsWith('اختيار المنتج'),
      );
    });

    test('المنتج المكرر في الفاتورة الواحدة يُرفض', () {
      expect(
        () => StockPurchaseCalculator.compute(
          shopId: 'shop1',
          lines: [
            line(qty: 1, cost: 5),
            line(qty: 2, cost: 5),
          ],
          products: {'p1': snap(stock: 1, costPrice: 5)},
        ),
        throwsWith('مكرر'),
      );
    });

    test('منتج من محل آخر يُرفض (عدم تجاوز الملكية)', () {
      expect(
        () => StockPurchaseCalculator.compute(
          shopId: 'shop1',
          lines: [line(productId: 'p9', qty: 1, cost: 5)],
          products: {'p9': snap(id: 'p9', shopId: 'shop2', stock: 3)},
        ),
        throwsWith('لا يتبع هذا المحل'),
      );
    });

    test('منتج غير موجود (حُذف بين الفتح والحفظ) يُرفض', () {
      expect(
        () => StockPurchaseCalculator.compute(
          shopId: 'shop1',
          lines: [line(qty: 1, cost: 5)],
          products: const {},
        ),
        throwsWith('غير موجود'),
      );
    });

    test('محل فارغ يُرفض', () {
      expect(
        () => StockPurchaseCalculator.compute(
          shopId: '  ',
          lines: [line(qty: 1, cost: 5)],
          products: {'p1': snap()},
        ),
        throwsWith('المتجر'),
      );
    });

    test('كمية صفر أو سالبة في الفاتورة تُرفض', () {
      for (final qty in [0.0, -3.0]) {
        expect(
          () => StockPurchaseCalculator.compute(
            shopId: 'shop1',
            lines: [line(qty: qty, cost: 5)],
            products: {'p1': snap(stock: 1, costPrice: 5)},
          ),
          throwsWith('الكمية'),
          reason: 'qty=$qty',
        );
      }
    });

    test('تكلفة شراء سالبة في الفاتورة تُرفض', () {
      expect(
        () => StockPurchaseCalculator.compute(
          shopId: 'shop1',
          lines: [line(qty: 1, cost: -0.5)],
          products: {'p1': snap(stock: 1, costPrice: 5)},
        ),
        throwsWith('سعر شراء غير صالح'),
      );
    });

    test('بيانات منتج تالفة (مخزون سالب/تكلفة NaN) تُرفض', () {
      expect(
        () => StockPurchaseCalculator.compute(
          shopId: 'shop1',
          lines: [line(qty: 1, cost: 5)],
          products: {'p1': snap(stock: -2, costPrice: 5)},
        ),
        throwsWith('غير صالحة'),
      );
      expect(
        () => StockPurchaseCalculator.compute(
          shopId: 'shop1',
          lines: [line(qty: 1, cost: 5)],
          products: {'p1': snap(stock: 5, costPrice: double.nan)},
        ),
        throwsWith('غير صالحة'),
      );
    });

    test('قيمة سطر تتجاوز الحد (غير منتهية) تُرفض', () {
      expect(
        () => StockPurchaseCalculator.compute(
          shopId: 'shop1',
          lines: [line(qty: 1e308, cost: 1e308)],
          products: {'p1': snap(stock: 1, costPrice: 5)},
        ),
        throwsA(anything),
      );
    });

    test('فشل أي سطر يمنع أي نتائج (لا معالجة جزئية)', () {
      // السطر الأول صالح والثاني غير موجود → الاستثناء يُرمى قبل الإرجاع.
      expect(
        () => StockPurchaseCalculator.compute(
          shopId: 'shop1',
          lines: [
            line(productId: 'p1', qty: 1, cost: 5),
            line(productId: 'ghost', qty: 1, cost: 5),
          ],
          products: {'p1': snap(stock: 1, costPrice: 5)},
        ),
        throwsWith('غير موجود'),
      );
    });
  });
}
