import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hesba/features/accounts/data/repos/accounts_repo.dart';
import 'package:hesba/features/expenses/data/repos_impl/expenses_repo_impl.dart';
import 'package:hesba/features/sales/data/repos_impl/sales_repo_impl.dart';

import '../helpers/test_auth.dart';

/// Reports must bound reads server-side while keeping totals identical for
/// the selected period.
void main() {
  late FakeFirebaseFirestore firestore;
  const uid = 'owner-1';
  const shop = 'shop-1';

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    await firestore.collection('users').doc(uid).set({'shopId': shop});
  });

  Future<void> seedSale(String id, DateTime createdAt) => firestore
      .collection('sales')
      .doc(id)
      .set({
        'saleId': id,
        'ownerId': uid,
        'shopId': shop,
        'items': [],
        'subtotal': 100,
        'discount': 0,
        'total': 100,
        'paymentMethod': 'cash',
        'note': '',
        'createdAt': Timestamp.fromDate(createdAt),
      });

  test('fetchAllSales with from returns only recent docs', () async {
    final repo = SalesRepoImpl(
      firestore: firestore,
      auth: signedInAuth(uid),
      accountsRepo: _DummyAccounts(),
    );
    final now = DateTime.now();
    await seedSale('old', now.subtract(const Duration(days: 90)));
    await seedSale('recent', now.subtract(const Duration(days: 2)));

    final all = await repo.fetchAllSales(shopId: shop);
    final bounded = await repo.fetchAllSales(
      shopId: shop,
      from: now.subtract(const Duration(days: 30)),
    );

    expect(all.items.length, 2);
    expect(bounded.items.map((s) => s.saleId), ['recent']);
    expect(bounded.isComplete, isTrue);
  });

  test('fetchAllExpenses bounds on date (the field reports filter on)',
      () async {
    final repo = ExpensesRepoImpl(firestore: firestore, auth: signedInAuth(uid));
    final now = DateTime.now();
    for (final entry in {
      'old': now.subtract(const Duration(days: 90)),
      'recent': now.subtract(const Duration(days: 2)),
    }.entries) {
      await firestore.collection('expenses').doc(entry.key).set({
        'expenseId': entry.key,
        'ownerId': uid,
        'shopId': shop,
        'title': 'x',
        'category': 'x',
        'amount': 10,
        'note': '',
        'date': Timestamp.fromDate(entry.value),
        'createdAt': Timestamp.fromDate(entry.value),
        'recurrence': 'none',
        'dueTime': '',
        'generatedFrom': '',
      });
    }

    final bounded = await repo.fetchAllExpenses(
      shopId: shop,
      from: now.subtract(const Duration(days: 30)),
    );
    expect(bounded.items.map((e) => e.expenseId), ['recent']);
  });
}

/// Only used by SalesRepoImpl for customer linking; no sales here need it.
class _DummyAccounts extends AccountsRepo {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
