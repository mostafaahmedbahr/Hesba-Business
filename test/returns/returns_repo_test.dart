import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hesba/core/constants/app_constants.dart';
import 'package:hesba/features/accounts/data/models/debt_model.dart';
import 'package:hesba/features/returns/data/models/return_model.dart';
import 'package:hesba/features/returns/data/repos_impl/returns_repo_impl.dart';

import '../helpers/test_auth.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late ReturnsRepoImpl repo;

  const uid = 'owner-1';
  const shopId = 'shop-1';

  ReturnItemModel retItem(String id, double qty, double price) =>
      ReturnItemModel(
        productId: id,
        productName: 'منتج $id',
        quantity: qty,
        unitPrice: price,
      );

  Future<void> seedProduct(String id,
      {String shop = shopId, num stock = 5}) {
    return firestore.collection(AppConstants.productsCollection).doc(id).set({
      'name': 'منتج $id',
      'shopId': shop,
      'stock': stock,
      'isActive': true,
    });
  }

  /// يبذر فاتورة أصلية: صنفان بسعر 100 ×2 و 50 ×1 = subtotal 250،
  /// خصم 50 (20%)، الإجمالي 200.
  Future<String> seedSale({
    String saleId = 'sale-1',
    String shop = shopId,
    double subtotal = 250,
    double discount = 50,
    List<Map<String, dynamic>>? items,
    Map<String, dynamic> person = const {},
  }) async {
    final saleItems = items ??
        [
          {
            'productId': 'p1',
            'productName': 'منتج p1',
            'quantity': 2,
            'unitPrice': 100,
            'total': 200,
          },
          {
            'productId': 'p2',
            'productName': 'منتج p2',
            'quantity': 1,
            'unitPrice': 50,
            'total': 50,
          },
        ];
    await firestore.collection(AppConstants.salesCollection).doc(saleId).set({
      'saleId': saleId,
      'ownerId': uid,
      'shopId': shop,
      'items': saleItems,
      'subtotal': subtotal,
      'discount': discount,
      'total': subtotal - discount,
      'paymentMethod': 'cash',
      'note': '',
      'createdAt': Timestamp.fromDate(DateTime.now()),
      ...person,
    });
    return saleId;
  }

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = ReturnsRepoImpl(firestore: firestore, auth: signedInAuth(uid));
  });

  group('validation', () {
    test('يرفض مرتجع بدون أصناف', () async {
      await expectLater(
        repo.addReturn(
          ownerId: uid,
          shopId: shopId,
          originalSaleId: 'sale-1',
          items: const [],
          reason: 'عيب',
          note: '',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('يرفض مرتجع بدون فاتورة أصلية', () async {
      await expectLater(
        repo.addReturn(
          ownerId: uid,
          shopId: shopId,
          items: [retItem('p1', 1, 100)],
          reason: 'عيب',
          note: '',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('يرفض مرتجع بدون سبب', () async {
      await seedSale();
      await expectLater(
        repo.addReturn(
          ownerId: uid,
          shopId: shopId,
          originalSaleId: 'sale-1',
          items: [retItem('p1', 1, 100)],
          reason: '  ',
          note: '',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('يرفض مرتجع لفاتورة محل آخر', () async {
      await seedSale(shop: 'shop-other');
      await expectLater(
        repo.addReturn(
          ownerId: uid,
          shopId: shopId,
          originalSaleId: 'sale-1',
          items: [retItem('p1', 1, 100)],
          reason: 'عيب',
          note: '',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('يرفض منتج غير موجود في الفاتورة الأصلية', () async {
      await seedSale();
      await expectLater(
        repo.addReturn(
          ownerId: uid,
          shopId: shopId,
          originalSaleId: 'sale-1',
          items: [retItem('p999', 1, 100)],
          reason: 'عيب',
          note: '',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('يرفض سعرًا مخالفًا لسعر البيع الأصلي', () async {
      await seedSale();
      await seedProduct('p1');
      await expectLater(
        repo.addReturn(
          ownerId: uid,
          shopId: shopId,
          originalSaleId: 'sale-1',
          items: [retItem('p1', 1, 90)], // الأصلي 100
          reason: 'عيب',
          note: '',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('discount allocation & totals', () {
    test('يخصص الخصم نسبيًا ويرجع المبلغ الصافي فقط', () async {
      await seedSale(); // subtotal 250, discount 50 → 20%
      await seedProduct('p1');
      final ret = await repo.addReturn(
        ownerId: uid,
        shopId: shopId,
        originalSaleId: 'sale-1',
        items: [retItem('p1', 1, 100)], // total item 100 → خصم مخصص 20
        reason: 'عيب',
        note: '',
      );
      expect(ret.subtotal, 100);
      expect(ret.discount, closeTo(20, 0.001));
      expect(ret.total, closeTo(80, 0.001));
    });

    test('مرتجع كل الفاتورة يرجع صافي المدفوع بالكامل', () async {
      await seedSale();
      await seedProduct('p1', stock: 0);
      await seedProduct('p2', stock: 0);
      final ret = await repo.addReturn(
        ownerId: uid,
        shopId: shopId,
        originalSaleId: 'sale-1',
        items: [retItem('p1', 2, 100), retItem('p2', 1, 50)],
        reason: 'عدم مطابقة',
        note: '',
      );
      expect(ret.total, closeTo(200, 0.001));
      expect(ret.discount, closeTo(50, 0.001));
    });

    test('مرتجع ثان لا يتجاوز الكمية المتبقية بعد المرتجع الأول', () async {
      await seedSale();
      await seedProduct('p1', stock: 0);
      await repo.addReturn(
        ownerId: uid,
        shopId: shopId,
        originalSaleId: 'sale-1',
        items: [retItem('p1', 2, 100)], // يرجع الـ 2 كاملة
        reason: 'عيب',
        note: '',
      );
      await expectLater(
        repo.addReturn(
          ownerId: uid,
          shopId: shopId,
          originalSaleId: 'sale-1',
          items: [retItem('p1', 1, 100)], // مفيش متبقي
          reason: 'عيب',
          note: '',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('stock & debt settlement', () {
    test('يسترجع المخزون عند تأكيد المرتجع', () async {
      await seedSale();
      await seedProduct('p1', stock: 1);
      await repo.addReturn(
        ownerId: uid,
        shopId: shopId,
        originalSaleId: 'sale-1',
        items: [retItem('p1', 2, 100)],
        reason: 'عيب',
        note: '',
      );
      final doc = await firestore
          .collection(AppConstants.productsCollection)
          .doc('p1')
          .get();
      expect((doc.data()!['stock'] as num).toDouble(), 3);
    });

    test('يسوّي الذمة الآجلة بمبلغ المرتجع الصافي ويقيّد دفعة تسوية', () async {
      await seedSale(person: {
        'personId': 'person-1',
        'personName': 'أحمد',
        'personPhone': '01000000001',
      });
      await seedProduct('p1', stock: 0);
      // ذمة آجل مرتبطة بالفاتورة: 200 على العميل، دفع 0.
      final debtRef = firestore.collection(AppConstants.debtsCollection).doc('debt-1');
      await debtRef.set({
        'id': 'debt-1',
        'ownerId': uid,
        'shopId': shopId,
        'personId': 'person-1',
        'personName': 'أحمد',
        'personPhone': '01000000001',
        'partyType': DebtParty.customer,
        'direction': DebtDirection.receivable,
        'amount': 200,
        'paidAmount': 0,
        'note': '',
        'saleId': 'sale-1',
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });

      final ret = await repo.addReturn(
        ownerId: uid,
        shopId: shopId,
        originalSaleId: 'sale-1',
        items: [retItem('p1', 1, 100)], // net 80
        reason: 'عيب',
        note: '',
      );
      expect(ret.total, closeTo(80, 0.001));

      final debt = await debtRef.get();
      expect((debt.data()!['paidAmount'] as num).toDouble(), closeTo(80, 0.001));

      final payments = await debtRef.collection('payments').get();
      expect(payments.docs, hasLength(1));
      expect((payments.docs.first.data()['amount'] as num).toDouble(),
          closeTo(80, 0.001));
      expect(payments.docs.first.data()['note'], contains('تسوية مرتجع'));
    });

    test('التسوية لا تتجاوز المتبقي من الذمة', () async {
      await seedSale();
      await seedProduct('p1', stock: 0);
      final debtRef = firestore.collection(AppConstants.debtsCollection).doc('debt-1');
      await debtRef.set({
        'id': 'debt-1',
        'ownerId': uid,
        'shopId': shopId,
        'personId': 'person-1',
        'personName': 'أحمد',
        'personPhone': '01000000001',
        'partyType': DebtParty.customer,
        'direction': DebtDirection.receivable,
        'amount': 200,
        'paidAmount': 150, // المتبقي 50 فقط
        'note': '',
        'saleId': 'sale-1',
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });

      await repo.addReturn(
        ownerId: uid,
        shopId: shopId,
        originalSaleId: 'sale-1',
        items: [retItem('p1', 1, 100)], // net 80 > المتبقي 50
        reason: 'عيب',
        note: '',
      );

      final debt = await debtRef.get();
      expect((debt.data()!['paidAmount'] as num).toDouble(), closeTo(200, 0.001));

      final payments = await debtRef.collection('payments').get();
      expect(payments.docs, hasLength(1));
      expect((payments.docs.first.data()['amount'] as num).toDouble(),
          closeTo(50, 0.001)); // لا تتجاوز المتبقي
    });

    test('يلتقط اسم ورقم العميل من فاتورة البيع', () async {
      await seedSale(person: {
        'personId': 'person-1',
        'personName': 'أحمد محمد',
        'personPhone': '01000000001',
      });
      await seedProduct('p1', stock: 0);
      final ret = await repo.addReturn(
        ownerId: uid,
        shopId: shopId,
        originalSaleId: 'sale-1',
        items: [retItem('p1', 1, 100)],
        reason: 'عيب',
        note: '',
      );
      expect(ret.personId, 'person-1');
      expect(ret.personName, 'أحمد محمد');
      expect(ret.personPhone, '01000000001');
    });
  });
}
