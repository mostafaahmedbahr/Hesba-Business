import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:hesba/core/services/shop_id_resolver.dart';
import 'package:hesba/core/services/user_role_service.dart';
import 'package:hesba/features/dashboard/data/repos_impl/dashboard_repo_impl.dart';
import 'package:hesba/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:hesba/features/dashboard/presentation/states/dashboard_state.dart';

import '../helpers/test_auth.dart';

/// Counts `users` collection access. With the role cache loaded, resolving
/// the shopId must cost ZERO Firestore reads.
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
  const uid = 'owner-1';
  const shopId = 'shop-1';

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    await firestore.collection('users').doc(uid).set({
      'shopId': shopId,
      'shopName': 'محلي',
    });
    counting = _CountingFirestore(firestore);
  });

  tearDown(() {
    if (GetIt.instance.isRegistered<UserRoleService>()) {
      GetIt.instance.unregister<UserRoleService>();
    }
  });

  /// يحاكي اللي بيحصل في main.dart: قراءة واحدة عند الدخول ثم كاش.
  Future<UserRoleService> loadRole() async {
    final role = UserRoleService(auth: signedInAuth(uid), firestore: firestore);
    await role.load();
    GetIt.instance.registerSingleton<UserRoleService>(role);
    return role;
  }

  test('cached shopId is used with zero Firestore reads', () async {
    await loadRole();

    final id = await resolveCachedShopId(
      firestore: counting,
      auth: signedInAuth(uid),
    );

    expect(id, shopId);
    expect(counting.callsFor('users'), 0);
  });

  test('cached shopName is reused without a user doc read', () async {
    await loadRole();

    final identity = await resolveCachedShopIdentity(
      firestore: counting,
      auth: signedInAuth(uid),
    );

    expect(identity.shopId, shopId);
    expect(identity.shopName, 'محلي');
    expect(counting.callsFor('users'), 0);
  });

  test('stale cache from another account is ignored', () async {
    await loadRole(); // كاش لـ owner-1
    await firestore.collection('users').doc('owner-2').set({'shopId': 'shop-2'});

    final id = await resolveCachedShopId(
      firestore: counting,
      auth: signedInAuth('owner-2'),
    );

    expect(id, 'shop-2');
    expect(counting.callsFor('users'), 1);
  });

  test('fallback reads the user doc when no cache is registered', () async {
    final id = await resolveCachedShopId(
      firestore: counting,
      auth: signedInAuth(uid),
    );

    expect(id, shopId);
    expect(counting.callsFor('users'), 1);
  });

  test('dashboard load reads users/{uid} zero times with the cache', () async {
    await loadRole();
    final cubit = DashboardCubit(
      repo: DashboardRepoImpl(auth: signedInAuth(uid), firestore: counting),
    );

    await cubit.loadDashboardData();

    expect(cubit.state.status, DashboardStatus.success);
    expect(counting.callsFor('users'), 0);
    await cubit.close();
  });
}
