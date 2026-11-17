import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hesba/features/admin/data/repos_impl/admin_repo_impl.dart';
import 'package:hesba/features/reports/data/reports_calculator.dart';
import 'package:hesba/features/returns/data/models/return_model.dart';
import 'package:hesba/features/sales/data/models/sale_model.dart';

import '../helpers/test_auth.dart';

/// لوحة الأدمن والتقارير يجب أن يستخدما نفس قواعد الربح بالضبط (Scenario 13).
/// يُبذر Firestore وهمي ثم تُقارن نتيجة AdminRepoImpl.profitSummary()
/// بنتيجة ReportsCalculator على نفس المستندات.
void main() {
  late FakeFirebaseFirestore firestore;
  late AdminRepoImpl repo;

  const uid = 'owner-1';

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = AdminRepoImpl(auth: signedInAuth(uid), firestore: firestore);
  });

  Map<String, dynamic> saleItem(
    String pid,
    double qty,
    double price, {
    double? cost,
    String? name,
  }) =>
      {
        'productId': pid,
        'productName': name ?? 'منتج $pid',
        'quantity': qty,
        'unitPrice': price,
        'total': qty * price,
        'costPrice': ?cost,
      };

  Map<String, dynamic> returnItem(
    String pid,
    double qty,
    double price, {
    String? name,
  }) =>
      {
        'productId': pid,
        'productName': name ?? 'منتج $pid',
        'quantity': qty,
        'unitPrice': price,
        'total': qty * price,
      };

  Future<void> seedSale(
    String id,
    DateTime date,
    List<Map<String, dynamic>> items, {
    required double subtotal,
    double discount = 0,
  }) =>
      firestore.collection('sales').doc(id).set({
        'saleId': id,
        'ownerId': uid,
        'shopId': 'shop-1',
        'items': items,
        'subtotal': subtotal,
        'discount': discount,
        'total': subtotal - discount,
        'paymentMethod': 'cash',
        'note': '',
        'createdAt': Timestamp.fromDate(date),
      });

  Future<void> seedReturn(
    String id,
    DateTime date,
    String saleId,
    List<Map<String, dynamic>> items, {
    required double subtotal,
    double discount = 0,
    required double total,
  }) =>
      firestore.collection('returns').doc(id).set({
        'returnId': id,
        'ownerId': uid,
        'shopId': 'shop-1',
        'originalSaleId': saleId,
        'items': items,
        'subtotal': subtotal,
        'discount': discount,
        'total': total,
        'reason': 'عيب',
        'note': '',
        'createdAt': Timestamp.fromDate(date),
      });

  Future<void> expectDashboardMatchesReports() async {
    final summary = await repo.profitSummary();
    final salesSnap = await firestore.collection('sales').get();
    final returnsSnap = await firestore.collection('returns').get();
    final metrics = ReportsCalculator.calculate(
      sales: salesSnap.docs.map((d) => SaleModel.fromJson(d.data())).toList(),
      returns: returnsSnap.docs.map((d) => ReturnModel.fromJson(d.data())).toList(),
      expenses: const [],
      start: DateTime(1970),
      end: DateTime(3000),
    );

    expect(summary.revenue, metrics.netSales);
    expect(summary.returnsTotal, metrics.returnsTotal);
    expect(summary.cost, metrics.cogs);
    expect(summary.profit, metrics.grossProfit);
    expect(summary.unknownCostLines, metrics.unknownCostLines);
    expect(summary.salesCounted, salesSnap.docs.length);
    expect(summary.returnsCounted, returnsSnap.docs.length);
    expect(summary.capped, isFalse);
  }

  group('Scenario 13 — dashboard profit matches Reports profit', () {
    test('نفس المستندات ⇒ نفس الإيراد/التكلفة/الربح/تغطية التكلفة', () async {
      await seedSale('s1', DateTime(2026, 1, 5), [
        saleItem('p1', 2, 100, cost: 60),
        saleItem('p2', 1, 50, cost: 30),
      ], subtotal: 250, discount: 50); // total 200، cogs 150
      await seedSale('s2', DateTime(2026, 2, 9), [
        saleItem('p3', 3, 40, cost: 10),
      ], subtotal: 120); // total 120، cogs 30
      await seedReturn('r1', DateTime(2026, 2, 10), 's1', [
        returnItem('p1', 1, 100),
      ], subtotal: 100, discount: 20, total: 80); // استرداد 80، تكلفة −60

      await expectDashboardMatchesReports();

      final summary = await repo.profitSummary();
      // (200+120−80) − (150+30−60) = 240 − 120 = 120
      expect(summary.profit, 120);
      expect(summary.cost, 120);
      expect(summary.unknownCostLines, 0);
      // بمبالغ صحيحة؛ السلسلة الشهرية تتطابق مع الرقم الرئيسي.
      expect(
        summary.profitByMonth.values.fold<int>(0, (a, b) => a + b),
        summary.profit.toInt(),
      );
      expect(
        summary.revenueByMonth.values.fold<int>(0, (a, b) => a + b),
        summary.revenue.toInt(),
      );
      expect(summary.profitByMonth['2026-01'], 50); // 200 − 150
      expect(summary.profitByMonth['2026-02'], 70); // (120 − 30) − (80 − 60)
    });

    test('بيانات فارغة ⇒ ملخص فارغ', () async {
      final summary = await repo.profitSummary();
      expect(summary.profit, 0);
      expect(summary.revenue, 0);
      expect(summary.cost, 0);
      expect(summary.salesCounted, 0);
      expect(summary.returnsCounted, 0);
    });
  });

  group('historical costPrice snapshots', () {
    test('فاتورة قديمة بلا costPrice لا تُعوَّض بسعر المنتج الحالي', () async {
      // سعر الشراء الحالي للمنتج p1 = 999 — يجب ألا يظهر في الحساب إطلاقاً.
      await firestore.collection('products').doc('p1').set({
        'name': 'منتج p1',
        'costPrice': 999,
        'shopId': 'shop-1',
        'stock': 5,
        'isActive': true,
      });
      await seedSale('legacy', DateTime(2026, 1, 5), [
        saleItem('p1', 2, 100), // بلا costPrice
      ], subtotal: 200);
      await seedSale('new', DateTime(2026, 1, 6), [
        saleItem('p2', 1, 100, cost: 40),
      ], subtotal: 100);

      await expectDashboardMatchesReports();

      final summary = await repo.profitSummary();
      expect(summary.cost, 40); // لا 999 ولا 2×999 — اللقطة المعروفة فقط
      expect(summary.profit, 260); // 300 − 40 (تقديري)
      expect(summary.unknownCostLines, 1);
    });

    test('costPrice = 0 صريح يُعدّ تكلفة مجهولة', () async {
      await seedSale('zero', DateTime(2026, 1, 5), [
        saleItem('p1', 2, 100, cost: 0),
      ], subtotal: 200);

      await expectDashboardMatchesReports();

      final summary = await repo.profitSummary();
      expect(summary.cost, 0);
      expect(summary.profit, 200);
      expect(summary.unknownCostLines, 1);
    });
  });

  group('returns & discount allocation', () {
    test('مرتجعان جزئيان يُلغيان تكلفة الكمية مرة واحدة لكل مرتجع', () async {
      await seedSale('s1', DateTime(2026, 1, 5), [
        saleItem('p1', 2, 100, cost: 50),
      ], subtotal: 200);
      await seedReturn('r1', DateTime(2026, 1, 10), 's1', [
        returnItem('p1', 1, 100),
      ], subtotal: 100, discount: 0, total: 100);
      await seedReturn('r2', DateTime(2026, 1, 20), 's1', [
        returnItem('p1', 1, 100),
      ], subtotal: 100, discount: 0, total: 100);

      await expectDashboardMatchesReports();

      final summary = await repo.profitSummary();
      expect(summary.returnsCounted, 2);
      expect(summary.returnsTotal, 200);
      expect(summary.revenue, 0);
      expect(summary.cost, 0);
      expect(summary.profit, 0);
      expect(summary.profitByMonth['2026-01'], 0);
    });

    test('خصم الفاتورة ينعكس على الاسترداد الصافي', () async {
      await seedSale('s1', DateTime(2026, 1, 5), [
        saleItem('p1', 2, 100, cost: 60),
      ], subtotal: 200, discount: 40);
      await seedReturn('r1', DateTime(2026, 1, 10), 's1', [
        returnItem('p1', 1, 100),
      ], subtotal: 100, discount: 20, total: 80);

      await expectDashboardMatchesReports();

      final summary = await repo.profitSummary();
      expect(summary.revenue, 80); // 160 − 80
      expect(summary.cost, 60); // 120 − 60
      expect(summary.profit, 20);
    });

    test('مرتجع بلا فاتورة أصلية لا يخترع تكلفة', () async {
      await seedSale('s1', DateTime(2026, 1, 5), [
        saleItem('p1', 1, 100, cost: 50),
      ], subtotal: 100);
      await seedReturn('orphan', DateTime(2026, 1, 10), '', [
        returnItem('p1', 1, 100),
      ], subtotal: 100, discount: 0, total: 100);

      await expectDashboardMatchesReports();

      final summary = await repo.profitSummary();
      expect(summary.cost, 50); // تكلفة البيع باقية — لم تُلغَ
      expect(summary.profit, -50); // 0 net sales − 50 cost
      expect(summary.unknownCostLines, 1); // السطر المرتجع بلا تكلفة معروفة
    });

    test('مطابقة المرتجع بالاسم تعمل في لوحة الأدمن أيضاً', () async {
      await seedSale('s1', DateTime(2026, 1, 5), [
        saleItem('old-id', 1, 100, cost: 25, name: 'منتج مشترك'),
      ], subtotal: 100);
      await seedReturn('r1', DateTime(2026, 1, 10), 's1', [
        returnItem('new-id', 1, 100, name: 'منتج مشترك'),
      ], subtotal: 100, discount: 0, total: 100);

      await expectDashboardMatchesReports();

      final summary = await repo.profitSummary();
      expect(summary.cost, 0);
      expect(summary.profit, 0);
      expect(summary.unknownCostLines, 0);
    });
  });

}
