import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:hesba/core/constants/app_constants.dart';
import 'package:hesba/core/services/user_role_service.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}

/// Firestore whose reads always fail — models an offline/rules-denied role read.
class ThrowingFirestore extends Fake implements FirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      throw Exception('offline');
}

/// First read succeeds, later ones fail — models a transient outage after a
/// role was already cached for this session.
class _FailingAfterFirstRead extends Fake implements FirebaseFirestore {
  _FailingAfterFirstRead({required this.good});
  final FirebaseFirestore good;
  int _calls = 0;

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    _calls++;
    if (_calls > 1) throw Exception('offline');
    return good.collection(path);
  }
}

void main() {
  late FakeFirebaseFirestore firestore;
  late MockFirebaseAuth auth;
  late MockUser user;
  late UserRoleService service;

  const uid = 'u1';

  void signInAs(String id) {
    final u = MockUser();
    when(() => u.uid).thenReturn(id);
    when(() => auth.currentUser).thenReturn(u);
  }

  Future<void> seedUser(String id, Map<String, dynamic> data) =>
      firestore.collection('users').doc(id).set(data);

  setUp(() {
    firestore = FakeFirebaseFirestore();
    auth = MockFirebaseAuth();
    user = MockUser();
    when(() => user.uid).thenReturn(uid);
    when(() => auth.currentUser).thenReturn(user);
    service = UserRoleService(auth: auth, firestore: firestore);
  });

  test('legacy user doc without role is treated as owner', () async {
    await seedUser(uid, {'shopId': 'shop1'});
    await service.load();

    expect(service.isLoaded, isTrue);
    expect(service.isOwner, isTrue);
    expect(service.loadFailed, isFalse);
    expect(service.ownerId, uid);
    expect(service.cachedShopId, 'shop1');
  });

  test('explicit staff role is honored', () async {
    await seedUser(uid, {
      'role': AppConstants.roleStaff,
      'ownerId': 'owner-1',
      'shopId': 'shop1',
    });
    await service.load();
    expect(service.isStaff, isTrue);
    expect(service.isOwner, isFalse);
    expect(service.ownerId, 'owner-1');
  });

  test('read failure with no cached role fails closed', () async {
    final failed = UserRoleService(auth: auth, firestore: ThrowingFirestore());
    await failed.load();

    expect(failed.isLoaded, isFalse);
    expect(failed.role, isNull);
    expect(failed.loadFailed, isTrue);
    expect(failed.isOwner, isFalse);
    expect(failed.isStaff, isFalse);
  });

  test('transient read failure keeps the cached role but flags loadFailed',
      () async {
    await seedUser(uid, {'role': AppConstants.roleStaff, 'ownerId': 'owner-1'});
    await service.load();
    expect(service.isStaff, isTrue);

    final failed = UserRoleService(auth: auth, firestore: ThrowingFirestore());
    await failed.load(); // different service instance = no cache
    expect(failed.isLoaded, isFalse);

    // Same uid + cached role on the original service: keep it, flag staleness.
    // Simulate by reloading through a service that first read successfully.
    await service.load(refresh: false);
    expect(service.isStaff, isTrue);
    expect(service.loadFailed, isFalse);

    final cachedThenFailed = UserRoleService(
      auth: auth,
      firestore: _FailingAfterFirstRead(good: firestore),
    );
    await cachedThenFailed.load();
    await cachedThenFailed.reload();
    expect(cachedThenFailed.isStaff, isTrue); // cached value still usable
    expect(cachedThenFailed.loadFailed, isTrue);
  });

  test('account switch reloads the new account role, never reuses the old',
      () async {
    await seedUser('u1', {'role': AppConstants.roleStaff, 'ownerId': 'owner-1'});
    await seedUser('u2', {'role': 'owner', 'shopId': 'shop2'});
    await service.load();
    expect(service.isStaff, isTrue);

    signInAs('u2');
    await service.reload();

    expect(service.isOwner, isTrue);
    expect(service.isStaff, isFalse);
    expect(service.cachedShopId, 'shop2');
  });

  test('clear() removes all cached authorization state', () async {
    await seedUser(uid, {'role': AppConstants.roleStaff, 'ownerId': 'owner-1'});
    await service.load();
    expect(service.isLoaded, isTrue);

    service.clear();
    expect(service.isLoaded, isFalse);
    expect(service.isStaff, isFalse);
    expect(service.ownerId, isNull);
    expect(service.cachedShopId, isNull);
    expect(service.loadFailed, isFalse);
  });
}
