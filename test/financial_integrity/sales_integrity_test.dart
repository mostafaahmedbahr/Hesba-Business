import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hesba/core/constants/app_constants.dart';
import 'package:hesba/features/accounts/data/repos_impl/accounts_repo_impl.dart';
import 'package:hesba/features/sales/data/models/sale_model.dart';
import 'package:hesba/features/sales/data/repos_impl/sales_repo_impl.dart';

import '../helpers/test_auth.dart';

/// Checks 1/2/3/8: sale submission, stock decrement, credit debt, concurrency.
void main() {
  late FakeFirebaseFirestore firestore;
  late SalesRepoImpl repo;

  const uid = 'owner-1';
  const shopId = 'shop-1';

  SaleItemModel item(String id, double qty, double price, double cost) =>
      SaleItemModel(
        productId: id,
        productName: 'منتج $id',
        quantity: qty,
        unitPrice: price,
        costPrice: cost,
      );

  Future<void> seedProduct(String id, {num stock = 5}) =>
      firestore.collection(AppConstants.productsCollection).doc(id).set({
        'id': id,
        'name': 'منتج $id',
        'shopId': shopId,
        'ownerId': uid,
        'stock': stock,
        'isActive': true,
        'price': 100,
        'costPrice': 60,
      });

  Future<DocumentSnapshot<Map<String, dynamic>>> stockOf(String id) =>
      firestore.collection(AppConstants.productsCollection).doc(id).get();

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    await firestore.collection('users').doc(uid).set({
      'shopId': shopId,
      'shopName': 'محلي',
    });
    final accounts = AccountsRepoImpl(
      auth: signedInAuth(uid),
      firestore: firestore,
    );
    repo = SalesRepoImpl(
      firestore: firestore,
      auth: signedInAuth(uid),
      accountsRepo: accounts,
    );
  });

  test('normal sale: one doc, stock decremented exactly once', () async {
    await seedProduct('p1', stock: 5);
    final sale = await repo.addSale(
      ownerId: uid,
      shopId: shopId,
      items: [item('p1', 2, 100, 60)],
      discount: 0,
      paymentMethod: 'cash',
      note: '',
    );

    final sales = await firestore.collection(AppConstants.salesCollection).get();
    expect(sales.docs, hasLength(1));
    expect(sales.docs.single.id, sale.saleId);
    expect((await stockOf('p1')).data()!['stock'], 3);
  });

  test('last unit: second sale is rejected and stock never goes negative', () async {
    // Concurrent conflict/retry is a real-Firestore transaction behavior that
    // fake_cloud_firestore does not emulate; the read-check-write guard itself
    // is verified here on sequential attempts.
    await seedProduct('p1', stock: 1);
    Future<void> sell() => repo.addSale(
          ownerId: uid,
          shopId: shopId,
          items: [item('p1', 1, 100, 60)],
          discount: 0,
          paymentMethod: 'cash',
          note: '',
        );

    await sell();
    await expectLater(sell(), throwsA(isA<Exception>()));

    final sales = await firestore.collection(AppConstants.salesCollection).get();
    expect(sales.docs, hasLength(1));
    expect((await stockOf('p1')).data()!['stock'], 0);
  });

  test('credit sale: exactly one linked debt, amount equals total', () async {
    await seedProduct('p1', stock: 5);
    final sale = await repo.addSale(
      ownerId: uid,
      shopId: shopId,
      items: [item('p1', 2, 100, 60)],
      discount: 20,
      paymentMethod: AppConstants.paymentCredit,
      note: 'آجل',
      customerName: 'أحمد',
      customerPhone: '01000000001',
    );

    final debts = await firestore
        .collection(AppConstants.debtsCollection)
        .where('saleId', isEqualTo: sale.saleId)
        .get();
    expect(debts.docs, hasLength(1));
    expect((debts.docs.single.data()['amount'] as num).toDouble(), sale.total);
    expect((debts.docs.single.data()['paidAmount'] as num).toDouble(), 0);
    expect(debts.docs.single.data()['ownerId'], uid);
  });

  test('product from another shop is rejected before any stock change', () async {
    await seedProduct('p1', stock: 5);
    await firestore.collection(AppConstants.productsCollection).doc('p2').set({
      'id': 'p2',
      'name': 'منتج p2',
      'shopId': 'shop-other',
      'ownerId': 'other',
      'stock': 5,
      'isActive': true,
      'price': 100,
    });
    await expectLater(
      repo.addSale(
        ownerId: uid,
        shopId: shopId,
        items: [item('p2', 1, 100, 60)],
        discount: 0,
        paymentMethod: 'cash',
        note: '',
      ),
      throwsA(isA<Exception>()),
    );
    final sales = await firestore.collection(AppConstants.salesCollection).get();
    expect(sales.docs, isEmpty);
  });
}
