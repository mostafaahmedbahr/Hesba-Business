import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hesba/features/reports/data/report_metrics.dart';
import 'package:hesba/features/reports/data/reports_calculator.dart';
import 'package:hesba/features/returns/data/models/return_model.dart';
import 'package:hesba/features/returns/data/repos_impl/returns_repo_impl.dart';
import 'package:hesba/features/sales/data/models/sale_model.dart';

import '../helpers/test_auth.dart';

/// رحلة كاملة: بيع بـ costPrice لقطة → مرتجع(ات) عبر ReturnsRepoImpl
/// → إعادة قراءة المستندات → ReportsCalculator. يثبت أن المرتجع لا يُخصم مرتين
/// وأن تكلفته تُشتق من لقطة الفاتورة الأصلية.
void main() {
  late FakeFirebaseFirestore firestore;
  late ReturnsRepoImpl repo;

  const uid = 'owner-1';
  const shop = 'shop-1';
  final date = DateTime(2026, 1, 5, 10);

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = ReturnsRepoImpl(firestore: firestore, auth: signedInAuth(uid));
  });

  Future<void> seedProduct(String id, {num stock = 10}) => firestore
      .collection('products')
      .doc(id)
      .set({
        'name': 'منتج $id',
        'shopId': shop,
        'stock': stock,
        'isActive': true,
      });

  Future<void> seedSale(
    String id,
    List<Map<String, dynamic>> items, {
    required double subtotal,
    double discount = 0,
  }) =>
      firestore.collection('sales').doc(id).set({
        'saleId': id,
        'ownerId': uid,
        'shopId': shop,
        'items': items,
        'subtotal': subtotal,
        'discount': discount,
        'total': subtotal - discount,
        'paymentMethod': 'cash',
        'note': '',
        'createdAt': Timestamp.fromDate(date),
      });

  Map<String, dynamic> si(
    String pid,
    double qty,
    double price,
    double cost,
  ) =>
      {
        'productId': pid,
        'productName': 'منتج $pid',
        'quantity': qty,
        'unitPrice': price,
        'costPrice': cost,
        'total': qty * price,
      };

  ReturnItemModel ri(String pid, double qty, double price) => ReturnItemModel(
        productId: pid,
        productName: 'منتج $pid',
        quantity: qty,
        unitPrice: price,
      );

  Future<({ReportMetrics metrics, int returnsCount})> currentMetrics() async {
    final sales = await firestore.collection('sales').get();
    final returns = await firestore.collection('returns').get();
    final m = ReportsCalculator.calculate(
      sales: sales.docs.map((d) => SaleModel.fromJson(d.data())).toList(),
      returns: returns.docs.map((d) => ReturnModel.fromJson(d.data())).toList(),
      expenses: const [],
      // المرتجعات تُكتب بتاريخ اليوم (DateTime.now())، لذا نوسّع النافذة.
      start: DateTime(2026, 1, 1),
      end: DateTime(2027, 1, 1),
    );
    return (metrics: m, returnsCount: returns.docs.length);
  }

  group('partial & cumulative returns', () {
    test('مرتجع جزئي: الاسترداد الصافي وتكلفة الكمية المرجعة فقط', () async {
      await seedProduct('p1');
      await seedSale('s1', [si('p1', 2, 100, 60)], subtotal: 200, discount: 40);
      // خصم 20% ⇒ استرداد 80 لكمية واحدة، تكلفتها 60.
      final ret = await repo.addReturn(
        ownerId: uid,
        shopId: shop,
        originalSaleId: 's1',
        items: [ri('p1', 1, 100)],
        reason: 'عيب',
        note: '',
      );
      expect(ret.total, closeTo(80, 0.001));
      expect(ret.discount, closeTo(20, 0.001));

      final data = await currentMetrics();
      expect(data.metrics.grossRevenue, 160);
      expect(data.metrics.returnsTotal, closeTo(80, 0.001));
      expect(data.metrics.cogs, 60);
      expect(data.metrics.grossProfit, closeTo(20, 0.001));
      expect(data.returnsCount, 1);
    });

    test('مرتجع جزئي ثم كامل: صافي الربح صفر بلا خصم مزدوج', () async {
      await seedProduct('p1');
      await seedSale('s1', [si('p1', 3, 100, 40)], subtotal: 300);
      await repo.addReturn(
        ownerId: uid,
        shopId: shop,
        originalSaleId: 's1',
        items: [ri('p1', 1, 100)],
        reason: 'عيب',
        note: '',
      );
      await repo.addReturn(
        ownerId: uid,
        shopId: shop,
        originalSaleId: 's1',
        items: [ri('p1', 2, 100)],
        reason: 'عدم مطابقة',
        note: '',
      );

      final data = await currentMetrics();
      final m = data.metrics;
      expect(data.returnsCount, 2);
      expect(m.returnsTotal, 300);
      expect(m.netSales, 0);
      expect(m.cogs, 0);
      expect(m.grossProfit, 0);
      expect(m.returnLinesTotal, 2);
      expect(m.returnLinesWithCost, 2);
      expect(m.isProfitEstimated, isFalse);
    });

    test('بعد استنفاد الكمية يُرفض مرتجع إضافي', () async {
      await seedProduct('p1');
      await seedSale('s1', [si('p1', 2, 100, 40)], subtotal: 200);
      await repo.addReturn(
        ownerId: uid,
        shopId: shop,
        originalSaleId: 's1',
        items: [ri('p1', 2, 100)],
        reason: 'عيب',
        note: '',
      );
      await expectLater(
        repo.addReturn(
          ownerId: uid,
          shopId: shop,
          originalSaleId: 's1',
          items: [ri('p1', 1, 100)],
          reason: 'عيب',
          note: '',
        ),
        throwsA(isA<Exception>()),
      );

      final data = await currentMetrics();
      expect(data.returnsCount, 1);
      expect(data.metrics.netSales, 0);
      expect(data.metrics.cogs, 0);
      expect(data.metrics.grossProfit, 0);
    });
  });

  group('snapshot & quantity edge cases', () {
    test('كميات عشرية: التكلفة والاسترداد يُحتسبان بنفس الدقة', () async {
      await seedProduct('p1');
      await seedSale('s1', [si('p1', 2.5, 40, 12)], subtotal: 100);
      await repo.addReturn(
        ownerId: uid,
        shopId: shop,
        originalSaleId: 's1',
        items: [ri('p1', 0.5, 40)],
        reason: 'عيب',
        note: '',
      );

      final data = await currentMetrics();
      expect(data.metrics.cogs, closeTo(24, 0.001));
      expect(data.metrics.netSales, 80);
      expect(data.metrics.grossProfit, closeTo(56, 0.001));
    });

    test('نفس المنتج في سطرين: يُسمح برد الكمية الكاملة (Bug 3)', () async {
      // الفاتورة تحتوي p1 مرتين (1+1). الكمية القابلة للإرجاع 2 وليست 1.
      await seedProduct('p1');
      await seedSale('s1', [
        si('p1', 1, 100, 60),
        si('p1', 1, 100, 70),
      ], subtotal: 200);

      final ret = await repo.addReturn(
        ownerId: uid,
        shopId: shop,
        originalSaleId: 's1',
        items: [ri('p1', 2, 100)],
        reason: 'عيب',
        note: '',
      );

      expect(ret.items.single.quantity, 2);
      final data = await currentMetrics();
      expect(data.metrics.returnsTotal, 200);
      expect(data.metrics.netSales, 0);
      expect(data.metrics.unknownCostLines, 0);
    });
  });
}
