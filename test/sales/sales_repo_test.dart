import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:hesba/core/constants/app_constants.dart';
import 'package:hesba/features/accounts/data/models/person_model.dart';
import 'package:hesba/features/accounts/data/repos/accounts_repo.dart';
import 'package:hesba/features/sales/data/models/sale_model.dart';
import 'package:hesba/features/sales/data/repos_impl/sales_repo_impl.dart';

import '../helpers/test_auth.dart';

class MockAccountsRepo extends Mock implements AccountsRepo {}

void main() {
  late FakeFirebaseFirestore firestore;
  late MockAccountsRepo accountsRepo;
  late SalesRepoImpl repo;

  const uid = 'owner-1';
  const shopId = 'shop-1';

  final person = PersonModel(
    id: 'person-1',
    ownerId: uid,
    shopId: shopId,
    name: 'أحمد',
    phone: '01000000001',
  );

  SaleItemModel item(String id, double qty, double price,
          {String name = 'منتج'}) =>
      SaleItemModel(
        productId: id,
        productName: name,
        quantity: qty,
        unitPrice: price,
      );

  Future<void> seedProduct({
    required String id,
    String shop = shopId,
    num stock = 10,
    bool isActive = true,
    String name = 'منتج',
  }) {
    return firestore.collection(AppConstants.productsCollection).doc(id).set({
      'name': name,
      'shopId': shop,
      'stock': stock,
      'isActive': isActive,
    });
  }

  setUp(() {
    firestore = FakeFirebaseFirestore();
    accountsRepo = MockAccountsRepo();
    when(
      () => accountsRepo.findOrCreatePerson(
        name: any(named: 'name'),
        phone: any(named: 'phone'),
        partyType: any(named: 'partyType'),
      ),
    ).thenAnswer((_) async => person);
    repo = SalesRepoImpl(
      firestore: firestore,
      auth: signedInAuth(uid),
      accountsRepo: accountsRepo,
    );
  });

  group('validation', () {
    test('يرفض قائمة أصناف فاضية', () async {
      await expectLater(
        repo.addSale(
          ownerId: uid,
          shopId: shopId,
          items: const [],
          discount: 0,
          paymentMethod: 'cash',
          note: '',
        ),
        throwsException,
      );
    });

    test('يرفض كمية صفرية أو سالبة', () async {
      await expectLater(
        repo.addSale(
          ownerId: uid,
          shopId: shopId,
          items: [item('p1', 0, 50)],
          discount: 0,
          paymentMethod: 'cash',
          note: '',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('يرفض سعرًا صفريًا', () async {
      await expectLater(
        repo.addSale(
          ownerId: uid,
          shopId: shopId,
          items: [item('p1', 1, 0)],
          discount: 0,
          paymentMethod: 'cash',
          note: '',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('يرفض اسم منتج فاضي', () async {
      await expectLater(
        repo.addSale(
          ownerId: uid,
          shopId: shopId,
          items: [item('p1', 1, 25, name: '  ')],
          discount: 0,
          paymentMethod: 'cash',
          note: '',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('totals & discount clamping', () {
    test('يحسب الإجمالي بعد الخصم بشكل صحيح', () async {
      await seedProduct(id: 'p1');
      final sale = await repo.addSale(
        ownerId: uid,
        shopId: shopId,
        items: [item('p1', 2, 100)], // subtotal 200
        discount: 50,
        paymentMethod: 'cash',
        note: '',
      );
      expect(sale.subtotal, 200);
      expect(sale.discount, 50);
      expect(sale.total, 150);

      final saved = await firestore
          .collection(AppConstants.salesCollection)
          .doc(sale.saleId)
          .get();
      expect(saved.exists, isTrue);
      expect((saved.data()!['total'] as num).toDouble(), 150);
    });

    test('الخصم السالب يُقلَّم إلى صفر', () async {
      await seedProduct(id: 'p1');
      final sale = await repo.addSale(
        ownerId: uid,
        shopId: shopId,
        items: [item('p1', 1, 100)],
        discount: -25,
        paymentMethod: 'cash',
        note: '',
      );
      expect(sale.discount, 0);
      expect(sale.total, 100);
    });

    test('الخصم أكبر من subtotal يُقلَّم للإجمالي بالكامل', () async {
      await seedProduct(id: 'p1');
      final sale = await repo.addSale(
        ownerId: uid,
        shopId: shopId,
        items: [item('p1', 1, 100)],
        discount: 500,
        paymentMethod: 'cash',
        note: '',
      );
      expect(sale.discount, 100);
      expect(sale.total, 0);
    });
  });

  group('stock transaction', () {
    test('يخصم الكمية من المخزون', () async {
      await seedProduct(id: 'p1', stock: 10);
      await repo.addSale(
        ownerId: uid,
        shopId: shopId,
        items: [item('p1', 3, 50)],
        discount: 0,
        paymentMethod: 'cash',
        note: '',
      );
      final doc = await firestore
          .collection(AppConstants.productsCollection)
          .doc('p1')
          .get();
      expect((doc.data()!['stock'] as num).toDouble(), 7);
    });

    test('يرفض البيع عند نقص المخزون ولا تُكتب فاتورة', () async {
      await seedProduct(id: 'p1', stock: 2);
      await expectLater(
        repo.addSale(
          ownerId: uid,
          shopId: shopId,
          items: [item('p1', 5, 50)],
          discount: 0,
          paymentMethod: 'cash',
          note: '',
        ),
        throwsA(isA<Exception>()),
      );
      final sales = await firestore.collection(AppConstants.salesCollection).get();
      expect(sales.docs, isEmpty);
      final doc = await firestore
          .collection(AppConstants.productsCollection)
          .doc('p1')
          .get();
      expect((doc.data()!['stock'] as num).toDouble(), 2);
    });

    test('يرفض منتج يتبع محلًا آخر', () async {
      await seedProduct(id: 'p1', shop: 'shop-other');
      await expectLater(
        repo.addSale(
          ownerId: uid,
          shopId: shopId,
          items: [item('p1', 1, 50)],
          discount: 0,
          paymentMethod: 'cash',
          note: '',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('يرفض منتجًا غير متاح (isActive = false)', () async {
      await seedProduct(id: 'p1', isActive: false);
      await expectLater(
        repo.addSale(
          ownerId: uid,
          shopId: shopId,
          items: [item('p1', 1, 50)],
          discount: 0,
          paymentMethod: 'cash',
          note: '',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('credit sales (آجل)', () {
    test('البيع الآجل بدون عميل يُرفض', () async {
      await seedProduct(id: 'p1');
      await expectLater(
        repo.addSale(
          ownerId: uid,
          shopId: shopId,
          items: [item('p1', 1, 100)],
          discount: 0,
          paymentMethod: AppConstants.paymentCredit,
          note: '',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('البيع الآجل باسم العميل فقط بدون هاتف يُرفض', () async {
      await seedProduct(id: 'p1');
      await expectLater(
        repo.addSale(
          ownerId: uid,
          shopId: shopId,
          items: [item('p1', 1, 100)],
          discount: 0,
          paymentMethod: AppConstants.paymentCredit,
          note: '',
          customerName: 'أحمد',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('البيع الآجل يسجل ذمة بنفس الإجمالي ويستدعي findOrCreatePerson', () async {
      await seedProduct(id: 'p1');
      final sale = await repo.addSale(
        ownerId: uid,
        shopId: shopId,
        items: [item('p1', 2, 100)], // subtotal 200, خصم 40 → total 160
        discount: 40,
        paymentMethod: AppConstants.paymentCredit,
        note: 'دفعة بعد أسبوع',
        customerName: 'أحمد',
        customerPhone: '01000000001',
      );

      verify(
        () => accountsRepo.findOrCreatePerson(
          name: 'أحمد',
          phone: '01000000001',
          partyType: PersonModel.typeCustomer,
        ),
      ).called(1);

      // الفاتورة مرتبطة بجهة الاتصال.
      expect(sale.personId, 'person-1');

      final debts = await firestore.collection(AppConstants.debtsCollection).get();
      expect(debts.docs, hasLength(1));
      final debt = debts.docs.first.data();
      expect((debt['amount'] as num).toDouble(), 160);
      expect((debt['paidAmount'] as num).toDouble(), 0);
      expect(debt['personId'], 'person-1');
      expect(debt['saleId'], sale.saleId);
      expect(debt['shopId'], shopId);
      expect(debt['partyType'], 'customer');
      expect(debt['direction'], 'receivable');
    });

    test('البيع الآجل بإجمالي صفر يُرفض ولا تُكتب ذمة', () async {
      await seedProduct(id: 'p1');
      await expectLater(
        repo.addSale(
          ownerId: uid,
          shopId: shopId,
          items: [item('p1', 1, 100)],
          discount: 100, // total = 0
          paymentMethod: AppConstants.paymentCredit,
          note: '',
          customerName: 'أحمد',
          customerPhone: '01000000001',
        ),
        throwsA(isA<Exception>()),
      );
      final debts = await firestore.collection(AppConstants.debtsCollection).get();
      expect(debts.docs, isEmpty);
    });
  });

  group('reading', () {
    test('getSales يرجع فواتير المحل فقط', () async {
      await seedProduct(id: 'p1');
      await repo.addSale(
        ownerId: uid,
        shopId: shopId,
        items: [item('p1', 1, 10)],
        discount: 0,
        paymentMethod: 'cash',
        note: '',
      );
      // تسريب فاتورة من محل آخر مباشرة في الـ fake.
      await firestore.collection(AppConstants.salesCollection).doc('sale-other').set({
        'saleId': 'sale-other',
        'ownerId': 'someone-else',
        'shopId': 'shop-other',
        'items': <Map<String, dynamic>>[],
        'subtotal': 1,
        'discount': 0,
        'total': 1,
        'paymentMethod': 'cash',
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });
      final sales = await repo.getSales(shopId: shopId);
      expect(sales.every((s) => s.shopId == shopId), isTrue);
      expect(sales, hasLength(1));
    });
  });
}
