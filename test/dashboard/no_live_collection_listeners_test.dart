import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hesba/core/services/app_events.dart';
import 'package:hesba/features/dashboard/data/repos_impl/dashboard_repo_impl.dart';
import 'package:hesba/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:hesba/features/dashboard/presentation/states/dashboard_state.dart';

import '../helpers/test_auth.dart';

/// Counts how many times each collection is asked for. Used as a guard so
/// nobody re-introduces the four unbounded `.snapshots()` listeners on the
/// dashboard collections (sales/products/returns/expenses).
class _CountingFirestore extends Fake implements FirebaseFirestore {
  _CountingFirestore(this.inner);
  final FirebaseFirestore inner;
  final Map<String, int> collectionCalls = {};

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    collectionCalls[path] = (collectionCalls[path] ?? 0) + 1;
    return inner.collection(path);
  }

  int callsFor(String path) => collectionCalls[path] ?? 0;
}

void main() {
  late FakeFirebaseFirestore firestore;
  const uid = 'owner-1';
  const shopId = 'shop-1';

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    await firestore.collection('users').doc(uid).set({
      'shopId': shopId,
      'shopName': 'محلي',
    });
  });

  DashboardRepoImpl makeRepo([FirebaseFirestore? fs]) => DashboardRepoImpl(
        auth: signedInAuth(uid),
        firestore: fs ?? firestore,
      );

  test('getLastSale returns the newest sale with a one-shot read', () async {
    await firestore.collection('sales').doc('s1').set({
      'shopId': shopId,
      'saleId': 's1',
      'total': 10,
      'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
    });
    await firestore.collection('sales').doc('s2').set({
      'shopId': shopId,
      'saleId': 's2',
      'total': 20,
      'createdAt': Timestamp.fromDate(DateTime(2026, 1, 2)),
    });

    final sale = await makeRepo().getLastSale(shopId);

    expect(sale?.saleId, 's2');
    expect(sale?.total, 20);
  });

  test('getLastExpense skips recurring templates', () async {
    await firestore.collection('expenses').doc('template').set({
      'shopId': shopId,
      'expenseId': 'template',
      'amount': 999,
      'recurrence': 'daily',
      'date': Timestamp.fromDate(DateTime(2026, 1, 3)),
    });
    await firestore.collection('expenses').doc('real').set({
      'shopId': shopId,
      'expenseId': 'real',
      'amount': 50,
      'recurrence': 'none',
      'date': Timestamp.fromDate(DateTime(2026, 1, 2)),
    });

    final expense = await makeRepo().getLastExpense(shopId);

    expect(expense?.expenseId, 'real');
    expect(expense?.amount, 50);
  });

  test('init() opens no collection-wide snapshot listeners', () async {
    final counting = _CountingFirestore(firestore);
    final cubit = DashboardCubit(repo: makeRepo(counting));

    cubit.init();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(cubit.state.status, DashboardStatus.success);
    // Exactly the six metric queries + one users doc read each for the shop
    // identity listener and getShopId(). The removed watchDashboardChanges()
    // used to add one extra collection call to each of the four collections.
    expect(counting.callsFor('sales'), 1);
    expect(counting.callsFor('returns'), 2);
    expect(counting.callsFor('expenses'), 1);
    expect(counting.callsFor('products'), 2);
    expect(counting.callsFor('users'), 2);

    await cubit.close();
  });

  test('AppEvents.saleCreated reloads the dashboard', () async {
    final counting = _CountingFirestore(firestore);
    final cubit = DashboardCubit(repo: makeRepo(counting));

    cubit.init();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final readsBefore = counting.callsFor('users');

    AppEvents.instance.saleCreated();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(counting.callsFor('users'), greaterThan(readsBefore));
    await cubit.close();
  });

  test('refreshRevision bumps on every successful load', () async {
    final cubit = DashboardCubit(repo: makeRepo());

    await cubit.loadDashboardData();
    final first = cubit.state.refreshRevision;
    expect(first, 1);

    await cubit.loadDashboardData();
    expect(cubit.state.refreshRevision, first + 1);

    await cubit.close();
  });
}
