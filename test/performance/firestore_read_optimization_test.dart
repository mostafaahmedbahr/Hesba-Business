import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hesba/features/admin/data/repos_impl/admin_repo_impl.dart';
import 'package:hesba/features/dashboard/data/repos_impl/dashboard_repo_impl.dart';
import 'package:hesba/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:hesba/features/dashboard/presentation/states/dashboard_state.dart';
import 'package:hesba/core/services/shop_resolver.dart';

import '../helpers/test_auth.dart';

/// Wraps a FakeFirebaseFirestore and counts how often each collection is
/// requested, so we can assert the "one user-doc read per load" optimization.
class CountingFirestore extends Fake implements FirebaseFirestore {
  CountingFirestore(this.inner);
  final FirebaseFirestore inner;

  final Map<String, int> collectionCalls = {};

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    collectionCalls[path] = (collectionCalls[path] ?? 0) + 1;
    return inner.collection(path);
  }

  int get userReads => collectionCalls['users'] ?? 0;
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

  test('dashboard load reads users/{uid} exactly once', () async {
    final counting = CountingFirestore(firestore);
    final repo = DashboardRepoImpl(
      auth: signedInAuth(uid),
      firestore: counting,
    );
    final cubit = DashboardCubit(repo: repo);

    await cubit.loadDashboardData();

    expect(cubit.state.status, DashboardStatus.success);
    // 1 for getShopId + 0 for the six metrics (they receive the resolved id).
    expect(counting.userReads, 1);
    await cubit.close();
  });

  test('getShopName reuses the user doc instead of re-reading it', () async {
    final counting = CountingFirestore(firestore);
    final resolver = ShopResolver(
      auth: signedInAuth(uid),
      firestore: counting,
    );

    final name = await resolver.getShopName();
    expect(name, 'محلي');
    expect(counting.userReads, 1);
  });

  test('countShopDocs counts all matching docs, not just the first 100',
      () async {
    for (var i = 0; i < 150; i++) {
      await firestore.collection('expenses').doc('e$i').set({
        'shopId': shopId,
        'amount': 10,
      });
    }
    final admin = AdminRepoImpl(
      auth: signedInAuth(uid),
      firestore: firestore,
    );

    final count = await admin.countShopDocs(
      collection: 'expenses',
      shopId: shopId,
    );
    expect(count, 150);
  });
}
