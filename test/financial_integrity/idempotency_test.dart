import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hesba/core/constants/app_constants.dart';
import 'package:hesba/features/accounts/data/repos_impl/accounts_repo_impl.dart';
import 'package:hesba/features/expenses/data/repos_impl/expenses_repo_impl.dart';
import 'package:hesba/features/returns/data/models/return_model.dart';
import 'package:hesba/features/returns/data/repos_impl/returns_repo_impl.dart';
import 'package:hesba/features/sales/data/models/sale_model.dart';
import 'package:hesba/features/sales/data/repos_impl/sales_repo_impl.dart';

import '../helpers/test_auth.dart';

/// Retries after a lost response must never duplicate a financial write.
void main() {
  late FakeFirebaseFirestore firestore;
  const uid = 'owner-1';
  const shop = 'shop-1';

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    await firestore.collection('users').doc(uid).set({
      'shopId': shop,
      'shopName': 'محل',
    });
    await firestore.collection(AppConstants.productsCollection).doc('p1').set({
      'id': 'p1',
      'name': 'منتج p1',
      'shopId': shop,
      'ownerId': uid,
      'stock': 10,
      'isActive': true,
      'price': 100,
      'costPrice': 60,
    });
  });

  group('sale idempotency', () {
    late SalesRepoImpl repo;
    setUp(() async {
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

    Future<SaleModel> sell(String? requestId) => repo.addSale(
          ownerId: uid,
          shopId: shop,
          items: [
            SaleItemModel(
              productId: 'p1',
              productName: 'منتج p1',
              quantity: 2,
              unitPrice: 100,
              costPrice: 60,
            )
          ],
          discount: 0,
          paymentMethod: 'cash',
          note: '',
          requestId: requestId,
        );

    test('same key twice: one sale and one stock decrement', () async {
      final first = await sell('req-1');
      final retry = await sell('req-1');

      expect(retry.saleId, first.saleId);
      final sales = await firestore.collection(AppConstants.salesCollection).get();
      expect(sales.docs, hasLength(1));
      final product =
          await firestore.collection(AppConstants.productsCollection).doc('p1').get();
      expect(product.data()!['stock'], 8);
    });

    test('different keys: two legitimate sales', () async {
      await sell('req-1');
      await sell('req-2');
      final sales = await firestore.collection(AppConstants.salesCollection).get();
      expect(sales.docs, hasLength(2));
    });
  });

  group('return idempotency', () {
    late ReturnsRepoImpl repo;
    setUp(() async {
      await firestore.collection(AppConstants.salesCollection).doc('s1').set({
        'saleId': 's1',
        'ownerId': uid,
        'shopId': shop,
        'items': [
          {
            'productId': 'p1',
            'productName': 'منتج p1',
            'quantity': 2,
            'unitPrice': 100,
            'costPrice': 60,
            'total': 200,
          }
        ],
        'subtotal': 200,
        'discount': 0,
        'total': 200,
        'paymentMethod': 'cash',
        'note': '',
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
      });
      repo = ReturnsRepoImpl(firestore: firestore, auth: signedInAuth(uid));
    });

    Future<ReturnModel> doReturn(String? requestId) => repo.addReturn(
          ownerId: uid,
          shopId: shop,
          originalSaleId: 's1',
          items: [
            ReturnItemModel(
              productId: 'p1',
              productName: 'منتج p1',
              quantity: 1,
              unitPrice: 100,
            )
          ],
          reason: 'عيب',
          note: '',
          requestId: requestId,
        );

    test('same key twice: one return and one stock restoration', () async {
      await firestore
          .collection(AppConstants.productsCollection)
          .doc('p1')
          .update({'stock': 0});
      final first = await doReturn('ret-1');
      final retry = await doReturn('ret-1');

      expect(retry.returnId, first.returnId);
      final returns =
          await firestore.collection(AppConstants.returnsCollection).get();
      expect(returns.docs, hasLength(1));
      final product =
          await firestore.collection(AppConstants.productsCollection).doc('p1').get();
      expect(product.data()!['stock'], 1);
    });
  });

  group('payment idempotency', () {
    late AccountsRepoImpl repo;
    setUp(() async {
      repo = AccountsRepoImpl(auth: signedInAuth(uid), firestore: firestore);
      await firestore.collection(AppConstants.debtsCollection).doc('d1').set({
        'id': 'd1',
        'ownerId': uid,
        'shopId': shop,
        'personId': 'p1',
        'personName': 'أحمد',
        'personPhone': '01000000001',
        'partyType': 'customer',
        'direction': 'receivable',
        'amount': 100,
        'paidAmount': 0,
        'note': '',
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
      });
    });

    Future<void> pay(String? requestId) => repo.addPayment(
          debtId: 'd1',
          amount: 40,
          requestId: requestId,
        );

    test('same key twice: one ledger row and one increment', () async {
      await pay('pay-1');
      await pay('pay-1');

      final debt =
          await firestore.collection(AppConstants.debtsCollection).doc('d1').get();
      expect(debt.data()!['paidAmount'], 40);
      final payments = await firestore
          .collection(AppConstants.debtsCollection)
          .doc('d1')
          .collection(AppConstants.debtPaymentsSubCollection)
          .get();
      expect(payments.docs, hasLength(1));
    });
  });

  test('expense idempotency: same key twice writes once', () async {
    final repo = ExpensesRepoImpl(firestore: firestore, auth: signedInAuth(uid));
    Future<void> add(String? requestId) => repo.addExpense(
          ownerId: uid,
          shopId: shop,
          shopName: 'محل',
          title: 'إيجار',
          category: 'عام',
          amount: 100,
          note: '',
          date: DateTime(2026, 1, 1),
          requestId: requestId,
        );

    await add('exp-1');
    await add('exp-1');
    final docs = await firestore.collection(AppConstants.expensesCollection).get();
    expect(docs.docs, hasLength(1));
  });
}
