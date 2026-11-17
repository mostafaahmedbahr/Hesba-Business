import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hesba/core/constants/app_constants.dart';
import 'package:hesba/features/returns/data/models/return_model.dart';
import 'package:hesba/features/returns/data/repos_impl/returns_repo_impl.dart';

import '../helpers/test_auth.dart';

/// Checks 4/5: stock restoration and debt settlement happen exactly once.
void main() {
  late FakeFirebaseFirestore firestore;
  late ReturnsRepoImpl repo;

  const uid = 'owner-1';
  const shopId = 'shop-1';

  ReturnItemModel ri(String id, double qty, double price) => ReturnItemModel(
        productId: id,
        productName: 'منتج $id',
        quantity: qty,
        unitPrice: price,
      );

  Future<void> seedProduct(String id, {num stock = 10}) =>
      firestore.collection(AppConstants.productsCollection).doc(id).set({
        'id': id,
        'name': 'منتج $id',
        'shopId': shopId,
        'ownerId': uid,
        'stock': stock,
        'isActive': true,
      });

  Future<void> seedSale({
    String saleId = 'sale-1',
    double qty = 2,
    double price = 100,
    double cost = 60,
    double discount = 0,
    String? personId,
  }) =>
      firestore.collection(AppConstants.salesCollection).doc(saleId).set({
        'saleId': saleId,
        'ownerId': uid,
        'shopId': shopId,
        'items': [
          {
            'productId': 'p1',
            'productName': 'منتج p1',
            'quantity': qty,
            'unitPrice': price,
            'costPrice': cost,
            'total': qty * price,
          }
        ],
        'subtotal': qty * price,
        'discount': discount,
        'total': qty * price - discount,
        'paymentMethod': personId == null ? 'cash' : 'credit',
        'note': '',
        'personId': personId ?? '',
        'personName': personId == null ? '' : 'أحمد',
        'personPhone': personId == null ? '' : '01000000001',
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 5)),
      });

  Future<void> seedDebt({double amount = 200, double paid = 0}) => firestore
      .collection(AppConstants.debtsCollection)
      .doc('debt-1')
      .set({
        'id': 'debt-1',
        'ownerId': uid,
        'shopId': shopId,
        'saleId': 'sale-1',
        'personId': 'person-1',
        'personName': 'أحمد',
        'personPhone': '01000000001',
        'partyType': 'customer',
        'direction': 'receivable',
        'amount': amount,
        'paidAmount': paid,
        'note': '',
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 5)),
      });

  Future<num> stockOf(String id) async {
    final snap = await firestore.collection(AppConstants.productsCollection).doc(id).get();
    return snap.data()!['stock'] as num;
  }

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    await firestore.collection('users').doc(uid).set({'shopId': shopId});
    repo = ReturnsRepoImpl(firestore: firestore, auth: signedInAuth(uid));
  });

  Future<ReturnModel> ret({double qty = 1, String saleId = 'sale-1'}) =>
      repo.addReturn(
        ownerId: uid,
        shopId: shopId,
        originalSaleId: saleId,
        items: [ri('p1', qty, 100)],
        reason: 'عيب',
        note: '',
      );

  test('partial return restores stock once and writes one return doc', () async {
    await seedProduct('p1', stock: 1);
    await seedSale();
    final r = await ret(qty: 1);

    expect(r.quantitySum, 1);
    expect(await stockOf('p1'), 2);
    final docs = await firestore.collection(AppConstants.returnsCollection).get();
    expect(docs.docs, hasLength(1));
  });

  test('second full return is rejected — stock cannot be restored twice', () async {
    await seedProduct('p1', stock: 0);
    await seedSale(qty: 2);
    await ret(qty: 2); // full return
    expect(await stockOf('p1'), 2);

    await expectLater(ret(qty: 1), throwsA(isA<Exception>()));
    final docs = await firestore.collection(AppConstants.returnsCollection).get();
    expect(docs.docs, hasLength(1));
    expect(await stockOf('p1'), 2);
  });

  test('two partial returns summing to full qty are each accepted once', () async {
    await seedProduct('p1', stock: 0);
    await seedSale(qty: 3);
    await ret(qty: 1);
    await ret(qty: 2);
    expect(await stockOf('p1'), 3);
    final docs = await firestore.collection(AppConstants.returnsCollection).get();
    expect(docs.docs, hasLength(2));

    await expectLater(ret(qty: 1), throwsA(isA<Exception>()));
  });

  test('credit return settles the linked debt at most by remaining amount',
      () async {
    await seedProduct('p1', stock: 0);
    await seedSale(discount: 0, personId: 'person-1');
    await seedDebt(amount: 200, paid: 0);

    final r = await ret(qty: 1); // net refund 100
    expect(r.total, 100);

    final debt = await firestore.collection(AppConstants.debtsCollection).doc('debt-1').get();
    expect((debt.data()!['paidAmount'] as num).toDouble(), 100);
    final payments = await firestore
        .collection(AppConstants.debtsCollection)
        .doc('debt-1')
        .collection(AppConstants.debtPaymentsSubCollection)
        .get();
    expect(payments.docs, hasLength(1));
  });

  test('settlement never exceeds the remaining debt', () async {
    await seedProduct('p1', stock: 0);
    await seedSale(discount: 0, personId: 'person-1');
    await seedDebt(amount: 200, paid: 180); // only 20 left

    await ret(qty: 1); // net refund 100 > remaining 20

    final debt = await firestore.collection(AppConstants.debtsCollection).doc('debt-1').get();
    expect((debt.data()!['paidAmount'] as num).toDouble(), 200);
    final payments = await firestore
        .collection(AppConstants.debtsCollection)
        .doc('debt-1')
        .collection(AppConstants.debtPaymentsSubCollection)
        .get();
    expect(payments.docs, hasLength(1));
    expect((payments.docs.single.data()['amount'] as num).toDouble(), 20);
  });
}

extension on ReturnModel {
  double get quantitySum => items.fold<double>(0, (s, i) => s + i.quantity);
}
