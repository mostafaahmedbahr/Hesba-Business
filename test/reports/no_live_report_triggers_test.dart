import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:hesba/core/services/app_events.dart';
import 'package:hesba/features/accounts/data/repos/accounts_repo.dart';
import 'package:hesba/features/expenses/data/repos_impl/expenses_repo_impl.dart';
import 'package:hesba/features/returns/data/repos_impl/returns_repo_impl.dart';
import 'package:hesba/features/reports/presentation/cubit/reports_cubit.dart';
import 'package:hesba/features/reports/presentation/cubit/reports_state.dart';
import 'package:hesba/features/sales/data/repos_impl/sales_repo_impl.dart';

import '../helpers/test_auth.dart';

class MockAccountsRepo extends Mock implements AccountsRepo {}

/// Counts collection accesses so we can prove the report cubit holds no
/// Firestore `.snapshots()` listener: a direct write to Firestore must not
/// cause any extra collection access afterwards.
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
  late _CountingFirestore counting;
  late ReportsCubit cubit;
  const uid = 'owner-1';
  const shopId = 'shop-1';

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    await firestore.collection('users').doc(uid).set({'shopId': shopId});
    counting = _CountingFirestore(firestore);
    final auth = signedInAuth(uid);
    cubit = ReportsCubit(
      salesRepo: SalesRepoImpl(
        firestore: counting,
        auth: auth,
        accountsRepo: MockAccountsRepo(),
      ),
      returnsRepo: ReturnsRepoImpl(firestore: counting, auth: auth),
      expensesRepo: ExpensesRepoImpl(firestore: counting, auth: auth),
    );
  });

  tearDown(() async {
    await cubit.close();
  });

  test('bootstrap loads the history once and opens no live listeners',
      () async {
    await cubit.bootstrap();
    expect(cubit.state.status, ReportsStatus.success);
    expect(cubit.state.hasShop, isTrue);

    final afterLoad = Map<String, int>.from(counting.collectionCalls);

    // A write straight to Firestore must NOT trigger a report reload — the
    // old watchLatest* triggers used to do exactly that.
    await firestore.collection('sales').doc('s1').set({
      'shopId': shopId,
      'total': 10,
      'createdAt': Timestamp.now(),
    });
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(counting.collectionCalls, equals(afterLoad));
  });

  test('AppEvents.saleCreated refreshes reports once after the debounce',
      () async {
    await cubit.bootstrap();
    final before = counting.callsFor('sales');

    AppEvents.instance.saleCreated();
    // Several events in one burst must collapse into a single reload.
    AppEvents.instance.productChanged();
    await Future<void>.delayed(const Duration(milliseconds: 700));

    expect(counting.callsFor('sales'), greaterThan(before));
    expect(cubit.state.status, ReportsStatus.success);
  });

  test('refresh() re-fetches the history without re-reading users/{uid}',
      () async {
    await cubit.bootstrap();
    final userReads = counting.callsFor('users');
    final salesReads = counting.callsFor('sales');

    await cubit.refresh();

    expect(counting.callsFor('users'), userReads);
    expect(counting.callsFor('sales'), greaterThan(salesReads));
  });
}
